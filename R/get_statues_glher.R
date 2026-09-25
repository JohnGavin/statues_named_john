#' Retrieve Statue Data from Greater London HER
#'
#' @description
#' Retrieves monuments classified as \emph{Statue} from the Greater London
#' Historic Environment Record (GLHER) via its public Arches search API
#' (\code{/search/resources}), paging through all results.
#'
#' The bulk CSV export (\code{/search/export_results}) requires an account
#' with export permission and returns HTTP 403 otherwise; the public search
#' API does not (#94). Any failure is an error with its reason: a non-200
#' response, a non-JSON body, fewer records than GLHER reports, or more
#' pages than \code{max_pages}.
#'
#' @param concept Arches concept filter for the monument type. Defaults to
#'   GLHER's "Statue" concept in the Gardens Parks And Urban Spaces
#'   thesaurus (302 records on 2026-09-25); "Equestrian Statue" maps to the
#'   same concept.
#' @param max_pages Safety cap on pages requested (10 records per page).
#' @param pause Seconds to wait between page requests.
#' @param cache_path Path to cache results (default: NULL)
#'
#' @return A tibble with columns: glher_id, name, description, type,
#'   lat, lon, period, url, source
#'
#' @examples
#' \dontrun{
#' glher_statues <- get_statues_glher()
#' }
#'
#' @export
get_statues_glher <- function(concept = list(
                                value = "f5a0bff9-b5fc-346f-814f-036d5d38bed6",
                                context = "e2100069-d1ec-3a4d-88e8-a2b4c5a5c536",
                                context_label = "Gardens Parks And Urban Spaces",
                                text = "Statue"
                              ),
                              max_pages = 100,
                              pause = 1,
                              cache_path = NULL) {

  # Check cache
  if (!is.null(cache_path) && file.exists(cache_path)) {
    message("Loading cached GLHER results from ", cache_path)
    return(readRDS(cache_path))
  }

  term_filter <- jsonlite::toJSON(list(list(
    inverted = FALSE, type = "concept",
    context = concept$context, context_label = concept$context_label,
    id = 1, text = concept$text, value = concept$value
  )), auto_unbox = TRUE)

  message("Querying GLHER public search API (concept: ", concept$text, ")...")

  pages <- list()
  reported_total <- NA_integer_
  page <- 1
  repeat {
    if (page > max_pages) {
      cli::cli_abort(
        "GLHER still reports more results after max_pages = {max_pages} pages; refusing to return a truncated dataset.",
        call = NULL
      )
    }
    j <- glher_get_page(page, term_filter)
    hits <- j$results$hits
    if (is.na(reported_total)) {
      if (!is.numeric(hits$total$value) || length(hits$total$value) != 1) {
        cli::cli_abort("GLHER search response has no results$hits$total$value; the API may have changed.",
                       call = NULL)
      }
      reported_total <- as.integer(hits$total$value)
    }
    pages[[page]] <- parse_glher_hits(hits$hits)
    if (!isTRUE(j$`paging-filter`$paginator$has_next)) break
    page <- page + 1
    if (pause > 0) Sys.sleep(pause)
  }

  statues_glher <- dplyr::bind_rows(pages)
  message("Retrieved ", nrow(statues_glher), " records from GLHER (", page, " pages)")

  if (nrow(statues_glher) != reported_total) {
    cli::cli_abort(
      "GLHER reported {reported_total} records but {nrow(statues_glher)} were retrieved.",
      call = NULL
    )
  }

  # Cache if requested
  if (!is.null(cache_path)) {
    saveRDS(statues_glher, cache_path)
    message("Cached results to ", cache_path)
  }

  statues_glher
}

#' Request one page of GLHER search results
#' @param page Page number (1-based).
#' @param term_filter JSON term-filter string.
#' @return Parsed JSON as a list.
#' @noRd
glher_get_page <- function(page, term_filter) {
  response <- httr::GET(
    "https://glher.historicengland.org.uk/search/resources",
    query = list("paging-filter" = page, tiles = "false", "term-filter" = term_filter),
    httr::timeout(60),
    httr::user_agent(
      "statuesnamedjohn R package (https://github.com/JohnGavin/statues_named_john)"
    )
  )
  status <- httr::status_code(response)
  if (status != 200) {
    cli::cli_abort("GLHER search request (page {page}) failed with HTTP {status}.", call = NULL)
  }
  ctype <- httr::headers(response)[["content-type"]]
  if (is.null(ctype)) ctype <- ""
  if (!grepl("json", ctype, fixed = TRUE)) {
    cli::cli_abort(
      "GLHER search response (page {page}) is not JSON (content-type: {ctype}).",
      call = NULL
    )
  }
  jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"),
                     simplifyVector = FALSE)
}

#' Convert GLHER search hits to the get_statues_glher() tibble
#'
#' \code{displayname} has the form "[149436] Name (Descriptor)": the
#' bracketed number is the GLHER monument ID and the final parenthetical is
#' the period/type descriptor.
#'
#' @param hits List of hits (\code{results$hits$hits}).
#' @return A tibble.
#' @noRd
parse_glher_hits <- function(hits) {
  if (length(hits) == 0) {
    return(tibble::tibble(
      glher_id = character(), name = character(), description = character(),
      type = character(), lat = numeric(), lon = numeric(),
      period = character(), url = character(), source = character()
    ))
  }
  purrr::map_dfr(hits, function(h) {
    s <- h$`_source`
    display <- if (is.null(s$displayname)) NA_character_ else s$displayname
    pt <- if (length(s$points) > 0) s$points[[1]]$point else NULL
    tibble::tibble(
      glher_id = stringr::str_match(display, "^\\[(\\d+)\\]")[, 2],
      name = stringr::str_trim(stringr::str_remove(
        stringr::str_remove(display, "^\\[\\d+\\]\\s*"), "\\s*\\([^()]*\\)\\s*$"
      )),
      description = if (is.null(s$displaydescription)) NA_character_ else s$displaydescription,
      type = stringr::str_match(display, "\\(([^()]*)\\)\\s*$")[, 2],
      lat = if (is.null(pt)) NA_real_ else as.numeric(pt$lat),
      lon = if (is.null(pt)) NA_real_ else as.numeric(pt$lon),
      period = NA_character_,
      url = paste0("https://glher.historicengland.org.uk/report/", s$resourceinstanceid),
      source = "glher"
    )
  })
}
