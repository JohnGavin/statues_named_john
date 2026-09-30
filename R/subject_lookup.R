# Subject lookup: the "X" in "Statue of X".
#
# Many OSM/GLHER records carry no Wikidata subject, only text such as
# "Statue of Sir John Millais in North Forecourt of Tate Gallery". The
# first-name rules cannot read that text, because its first word is
# "Statue". extract_subject() pulls out X; lookup_wikidata_people() asks
# Wikidata whether X is a person, and if so their sex, with a confidence.
# One threshold (inst/extdata/params.csv) decides which answers are used.

#' Read a project parameter from the single parameters file
#'
#' @description
#' Parameters live in one place, \code{inst/extdata/params.csv}
#' (columns \code{name}, \code{value}, \code{note}). The main one is
#' \code{classification_threshold}: the minimum confidence (0-1) needed to
#' accept a gender, whether it comes from a first-name prediction or a
#' Wikidata person match. Set it to 1 to accept only certain answers.
#'
#' @param name Parameter name.
#' @return The parameter value as a number. Aborts if the value is not a
#'   number, or if a threshold or confidence is outside 0-1.
#' @export
#' @examples
#' get_param("classification_threshold")
get_param <- function(name) {
  params <- load_params()
  idx <- match(name, params$name)
  if (is.na(idx)) {
    cli::cli_abort("Unknown parameter {.val {name}}; see inst/extdata/params.csv.", call = NULL)
  }
  value <- trimws(as.character(params$value[idx]))
  if (!grepl("^[0-9]*\\.?[0-9]+$", value)) {
    cli::cli_abort("Parameter {.val {name}} is {.val {value}}, not a number; see inst/extdata/params.csv.",
                   call = NULL)
  }
  num <- as.numeric(value)
  if (grepl("threshold|confidence", name) && num > 1) {
    cli::cli_abort("Parameter {.val {name}} is {num}; it must be between 0 and 1.", call = NULL)
  }
  num
}

#' Confidence scores for a Wikidata person match
#'
#' @return Named numeric vector: \code{exact} (label or alias equals the
#'   subject), \code{partial} (one contains the other) and \code{weak}
#'   (a human, but the names differ). Read from
#'   \code{inst/extdata/params.csv}, their single home.
#' @export
wikidata_confidence <- function() {
  c(exact = get_param("wikidata_exact_confidence"),
    partial = get_param("wikidata_partial_confidence"),
    weak = get_param("wikidata_weak_confidence"))
}

# Path to the parameters file (also a targets file input, so editing the
# threshold re-runs the analysis).
params_path <- function() {
  path <- system.file("extdata", "params.csv", package = "statuesnamedjohn")
  if (!nzchar(path)) {
    cli::cli_abort("inst/extdata/params.csv not found.", call = NULL)
  }
  path
}

load_params <- function() {
  if (is.null(.lookup_cache$params)) {
    .lookup_cache$params <- utils::read.csv(params_path(), stringsAsFactors = FALSE)
  }
  .lookup_cache$params
}

#' Extract the subject X from text such as "Statue of X"
#'
#' @description
#' Strips a leading object word ("Statue of", "Bust of", "Tomb of",
#' "Monument to", "Memorial of", ...) and then a trailing location
#' ("... in North Forecourt of Tate Gallery", "..., Trent Park"). Text
#' without such a prefix is returned unchanged: a trailing phrase is only
#' treated as a location once the prefix shows the text describes an
#' object ("Duke of Wellington on horse" is left alone).
#'
#' @param text Character vector.
#' @return Character vector of the same length.
#' @export
#' @examples
#' extract_subject("Statue of Sir John Millais in North Forecourt of Tate Gallery")
extract_subject <- function(text) {
  prefix <- paste0(
    "(?i)^(the )?(statues?|bust|sculpture|figure|effigy|tomb|grave|headstone|",
    "monument|memorial|plaque|tablet)( marker)? (of|to|for) "
  )
  has_prefix <- !is.na(text) & stringr::str_detect(text, prefix)
  out <- text
  x <- stringr::str_remove(text[has_prefix], prefix)
  x <- stringr::str_remove(x, "\\s+(in|at|on|outside|near) (the )?[A-Z].*$")
  x <- stringr::str_remove(x, ",.*$")
  # "Memorial to The Executed": "The" is not a first name
  x <- stringr::str_remove(x, "(?i)^the\\s+")
  out[has_prefix] <- stringr::str_trim(x)
  out
}

#' Subjects worth looking up on Wikidata
#'
#' @param text Character vector of subject/name text.
#' @return Unique subjects X, in first-seen order, from text that starts
#'   with an object prefix (see [extract_subject()]); X of fewer than 3
#'   characters is dropped.
#' @export
candidate_subjects <- function(text) {
  text <- text[!is.na(text)]
  x <- extract_subject(text)
  x <- x[x != text & nchar(x) >= 3]
  unique(x)
}

# Wikidata API calls (internal, mocked in tests) ---------------------------

wd_api <- function(query) {
  resp <- httr::GET(
    "https://www.wikidata.org/w/api.php",
    query = c(query, format = "json"),
    httr::timeout(30), # fail fast (#90)
    httr::user_agent("statuesnamedjohn R package (https://github.com/JohnGavin/statues_named_john)")
  )
  httr::stop_for_status(resp, task = "query the Wikidata API")
  httr::content(resp, as = "parsed", type = "application/json")
}

wd_search <- function(x) {
  wd_api(list(action = "wbsearchentities", search = x, language = "en",
              type = "item", limit = 5))$search
}

wd_entities <- function(ids) {
  wd_api(list(action = "wbgetentities", ids = paste(ids, collapse = "|"),
              props = "claims"))$entities
}

# Item ids of a property's claims, e.g. P31 (instance of), P21 (sex).
claim_ids <- function(claims, property) {
  vapply(claims[[property]], function(s) {
    id <- s$mainsnak$datavalue$value$id
    if (is.null(id)) NA_character_ else id
  }, character(1))
}

# Lower case, drop titles and anything that is not a letter or a space.
normalise_person_name <- function(s) {
  s <- tolower(s)
  s <- sub(paste0("^(sir|dame|lord|lady|queen|king|prince|princess|mrs|mr|dr|",
                  "st|saint|president|captain|general|admiral) "), "", s)
  stringr::str_squish(gsub("[^a-z ]", "", s))
}

#' Look up subjects on Wikidata: is X a person, and of which sex?
#'
#' @description
#' For each X, searches Wikidata and takes the first result that is a human
#' (P31 = Q5), reading its sex (P21). Confidence comes from
#' [wikidata_confidence()]: \code{exact} when the result's label or the
#' matched alias equals X (ignoring titles and punctuation), \code{partial}
#' when one contains the other, \code{weak} otherwise, and 0 when no human
#' was found.
#' Errors are not caught, so an unreachable Wikidata fails fast; the
#' pipeline wraps this in [fetch_optional_source()].
#'
#' @param x Character vector of subjects (see [candidate_subjects()]).
#' @param pause Seconds to wait between searches (politeness to the API).
#' @return A tibble: \code{x}, \code{label}, \code{qid}, \code{sex}
#'   ("Male"/"Female"/NA), \code{confidence}.
#' @export
lookup_wikidata_people <- function(x, pause = 0.2) {
  rows <- lapply(x, function(xi) {
    if (pause > 0) Sys.sleep(pause)
    none <- tibble::tibble(x = xi, label = NA_character_, qid = NA_character_,
                           sex = NA_character_, confidence = 0)
    hits <- wd_search(xi)
    if (length(hits) == 0) return(none)
    ents <- wd_entities(vapply(hits, `[[`, character(1), "id"))
    for (h in hits) {
      claims <- ents[[h$id]]$claims
      if (!"Q5" %in% claim_ids(claims, "P31")) next
      sx <- claim_ids(claims, "P21")
      sex <- if ("Q6581072" %in% sx) "Female" else if ("Q6581097" %in% sx) "Male" else NA_character_
      label <- if (is.null(h$label)) "" else h$label
      nx <- normalise_person_name(xi)
      nl <- normalise_person_name(label)
      exact <- nl == nx ||
        (!is.null(h$match$text) && normalise_person_name(h$match$text) == nx)
      partial <- nzchar(nl) && nzchar(nx) &&
        (grepl(nl, nx, fixed = TRUE) || grepl(nx, nl, fixed = TRUE))
      conf <- wikidata_confidence()
      return(tibble::tibble(
        x = xi, label = label, qid = h$id, sex = sex,
        confidence = unname(if (exact) conf["exact"] else if (partial) conf["partial"] else conf["weak"])
      ))
    }
    none
  })
  if (length(rows) == 0) {
    return(tibble::tibble(x = character(0), label = character(0), qid = character(0),
                          sex = character(0), confidence = numeric(0)))
  }
  dplyr::bind_rows(rows)
}
