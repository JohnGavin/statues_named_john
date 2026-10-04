#' Analyze Statue Data by Gender
#'
#' @description
#' Performs gender analysis on statue subjects to compare representation
#' of men, women, and other subjects (animals, abstract concepts, etc.)
#'
#' @param statue_data Standardized statue data tibble
#' @param gender_mapping Optional named vector mapping subject names to genders
#' @param person_lookup Optional tibble from [lookup_wikidata_people()]
#'   (\code{x}, \code{sex}, \code{confidence}) used for text such as
#'   "Statue of X".
#' @param threshold Minimum confidence to accept a gender; defaults to the
#'   single project setting \code{get_param("classification_threshold")}.
#'
#' @return A list containing:
#'   - summary: tibble with gender counts and percentages
#'   - by_source: gender breakdown by data source
#'   - top_subjects: most frequently commemorated subjects
#'   - top_names_by_gender: top 5 first names for each gender
#'   - data: original data with 'inferred_gender' column
#'
#' @importFrom stats setNames
#' @export
analyze_by_gender <- function(statue_data, gender_mapping = NULL, person_lookup = NULL,
                              threshold = get_param("classification_threshold")) {

  # Attempt to classify gender
  # Priority: 1. Existing subject_gender (from Wikidata), 2. Heuristic from subject, 3. Heuristic from name
  classified <- statue_data %>%
    dplyr::mutate(
      heuristic_gender = classify_gender_from_subject(subject, name, gender_mapping,
                                                      person_lookup, threshold),
      inferred_gender = dplyr::case_when(
        !is.na(subject_gender) & tolower(subject_gender) %in% c("male", "female") ~ stringr::str_to_title(subject_gender),
        !is.na(subject_gender) ~ "Other", # Transgender, non-binary, etc. mapped to Other for high-level summary
        type == "animal" | stringr::str_detect(type, "(?i)animal") ~ "Animal",
        # No name, no subject: nothing identifies whom it honours (#117)
        is.na(name) & is.na(subject) ~ "Unnamed",
        TRUE ~ heuristic_gender
      )
    )

  # Overall summary
  # Stored percentages keep 2 dp; percent_label is the whole-percent text
  # shown to readers (format_percent(), #102). Shares are of identifiable
  # records: Unnamed rows are counted but left out of every share (#117).
  summary <- classified %>%
    dplyr::count(inferred_gender) %>%
    share_of_identifiable() %>%
    dplyr::arrange(desc(n))

  # By source
  by_source <- classified %>%
    dplyr::count(source, inferred_gender) %>%
    dplyr::group_by(source) %>%
    share_of_identifiable() %>%
    dplyr::ungroup()

  # Top subjects
  top_subjects <- classified %>%
    dplyr::filter(!is.na(subject)) %>%
    dplyr::count(subject, inferred_gender, sort = TRUE) %>%
    head(20)

  # Top Names by Gender
  # Extract all valid first names from the dataset
  name_tokens <- classified %>%
    dplyr::filter(!is.na(name) | !is.na(subject)) %>%
    dplyr::mutate(
      extracted_names = purrr::map(dplyr::coalesce(subject, name), extract_first_names)
    ) %>%
    tidyr::unnest(extracted_names) %>%
    dplyr::filter(!is.na(extracted_names))

  top_names_by_gender <- name_tokens %>%
    dplyr::group_by(inferred_gender, extracted_names) %>%
    dplyr::count(sort = TRUE) %>%
    dplyr::group_by(inferred_gender) %>%
    dplyr::mutate(
      total_gender = sum(n),
      percent = round(100 * n / total_gender, 2),
      percent_label = format_percent(n, total_gender)
    ) %>%
    dplyr::slice_head(n = 5) %>%
    dplyr::ungroup()

  return(list(
    summary = summary,
    by_source = by_source,
    top_subjects = top_subjects,
    top_names_by_gender = top_names_by_gender,
    data = classified
  ))
}

# Helper function: Extract likely first names from a string
# Handles "Johnson and Boswell" -> "Boswell" (if Johnson is deemed surname)
extract_first_names <- function(text) {
  if (is.na(text)) return(character(0))

  # Read X in "Statue of X in ..." (not "Statue"). One person per segment
  # (same rule as classification); segments that name a church/school
  # dedication or a site are not people (#98).
  parts <- split_into_person_parts(extract_subject(text))
  parts <- parts[!is_non_person_part(parts)]

  first_names <- c()

  for (part in parts) {
    # Remove clean
    clean_part <- stringr::str_trim(part)
    words <- stringr::str_split(clean_part, "\\s+")[[1]]
    
    if (length(words) >= 2) {
      # Multi-word: "John Smith" -> "John"
      first_name <- words[1]
      # Filter out titles
      if (stringr::str_detect(first_name, "(?i)^(sir|king|queen|prince|duke|lady|dame|saint|st\\.?|dr|mr|mrs)$")) {
        if (length(words) >= 2) first_name <- words[2] # "Sir John" -> "John"
      }
      first_names <- c(first_names, first_name)
    } else if (length(words) == 1) {
      # Single word: "Johnson" vs "Madonna"
      # Heuristic: Assume single word is surname UNLESS it's a known common first name
      # For "Johns comparison", we strictly need first names.
      # We can keep it if it looks like a first name, but "Johnson" is risky.
      # Safer: Ignore single words unless they are explicitly "John", "Mary", etc.
      word <- words[1]
      # Allow specific single names if we want, but for "Johnson and Boswell", "Johnson" is likely surname.
      # EXCEPT: "Cher", "Madonna".
      # For this specific "John" task, we are safer ignoring singletons unless they match our target "John" list.
      if (stringr::str_detect(word, "(?i)^(john|jon|jean|jonathan|jonny|mary|elizabeth|victoria|anne)$")) {
        first_names <- c(first_names, word)
      }
    }
  }
  
  # Clean up (remove punctuation). A first name must be capitalised and must
  # not be a known non-name word: the genderdata lists resolve ordinary words
  # ("Site", "Parish", "Corpus") as names (#98).
  first_names <- stringr::str_remove_all(first_names, "[^a-zA-Z-]")
  keep <- first_names != "" &
    stringr::str_detect(first_names, "^[A-Z]") &
    !tolower(first_names) %in% load_non_name_words()
  first_names[keep]
}

# Helper: add percent / percent_label to counted rows (per group, if
# grouped), as shares of identifiable records. "Unnamed" rows keep their
# count, with percent NA and the label "not counted" (#117).
share_of_identifiable <- function(counts) {
  counts %>%
    dplyr::mutate(
      identifiable = sum(n[inferred_gender != "Unnamed"]),
      percent = dplyr::if_else(inferred_gender == "Unnamed", NA_real_,
                               round(100 * n / identifiable, 2)),
      percent_label = dplyr::if_else(inferred_gender == "Unnamed", "not counted",
                                     format_percent(n, identifiable))
    ) %>%
    dplyr::select(-identifiable)
}

# Cache for the small lookup tables in inst/extdata, so per-row callers
# (e.g. classify_gender()) do not re-read them from disk (#98 item 9).
.lookup_cache <- new.env(parent = emptyenv())

# Helper: words that must never be treated as first names. See
# inst/extdata/non_name_words.csv (each entry states why).
load_non_name_words <- function() {
  if (is.null(.lookup_cache$non_name_words)) {
    path <- system.file("extdata", "non_name_words.csv", package = "statuesnamedjohn")
    .lookup_cache$non_name_words <- if (nzchar(path)) {
      tolower(utils::read.csv(path, stringsAsFactors = FALSE)$word)
    } else {
      warning("non_name_words.csv not found; ordinary words may be looked up as names.")
      character(0)
    }
  }
  .lookup_cache$non_name_words
}

# Helper: is a person-segment really a dedication or a place? True when it
# starts with "St"/"Saint"/"Site" AND names a church-type institution, e.g.
# "St Mary Abbot's Church of England Primary School" or "Site of Laurence
# Pountney Church". "St George" (no institution word) stays a person.
is_non_person_part <- function(parts) {
  starts <- stringr::str_detect(parts, "(?i)^(st\\.?|saint|site)\\b")
  institution <- stringr::str_detect(
    parts, "(?i)\\b(church|chapel|school|college|abbey|cathedral|parish|priory)\\b"
  )
  starts & institution
}

# Helper: load the small, documented table of gendered titles/terms used to
# resolve subjects that carry an explicit honorific or generic descriptor
# (e.g. "Queen Victoria", "Unknown Woman") without ever needing a name-based
# lookup. See inst/extdata/gender_overrides.csv.
load_gender_overrides <- function() {
  if (is.null(.lookup_cache$gender_overrides)) {
    path <- system.file("extdata", "gender_overrides.csv", package = "statuesnamedjohn")
    .lookup_cache$gender_overrides <- if (nzchar(path)) {
      utils::read.csv(path, stringsAsFactors = FALSE)
    } else {
      warning("gender_overrides.csv not found; no title/term overrides will be applied.")
      data.frame(term = character(0), gender = character(0), stringsAsFactors = FALSE)
    }
  }
  .lookup_cache$gender_overrides
}

# Helper: split a subject string into one segment per person, on "and"/"&"
# in any case (#98 item 3). Commas are deliberately NOT separators: in this
# dataset a comma almost always introduces a location ("Statue of Hercules,
# Trent Park"), and splitting there turned place names into people.
split_into_person_parts <- function(text) {
  parts <- stringr::str_split(text, "(?i)\\s+(?:and|&)\\s+")[[1]]
  parts <- stringr::str_trim(parts)
  parts[nzchar(parts)]
}

# Helper: does this person-segment START with a documented gendered title/term?
# Matched as a whole word against the FIRST token only (never a substring
# match anywhere in the text) so "Manchester dog" can never match "man".
match_gender_override <- function(part, overrides) {
  first_word <- tolower(stringr::word(part, 1))
  if (is.na(first_word) || nrow(overrides) == 0) return(NA_character_)
  idx <- match(first_word, tolower(overrides$term))
  if (is.na(idx)) NA_character_ else overrides$gender[idx]
}

#' Look up gender for first names via the genderdata cascade
#'
#' Internal helper (mockable in tests). Tries, in order, the "napp"
#' (North Atlantic Population Project historical census data, covering the
#' UK among other countries), "ipums" (US census 1789-1930), and "ssa"
#' (US Social Security data 1880-2012) methods provided by the `gender`
#' package. A prediction is only accepted when its confidence
#' (`max(proportion_male, 1 - proportion_male)`) is at least `threshold`.
#' A name whose prediction from one method is missing OR below the
#' threshold falls through to the next method, so a name that is ambiguous
#' in the UK historical data (napp) can still be resolved from US data
#' (ipums, ssa) if it is unambiguous there. Names with no confident
#' prediction from any method are left unresolved (`NA`) so the caller
#' reports them as "Unknown" rather than guessing.
#'
#' Never fails silently: if the `gender` package is unavailable, or every
#' lookup method errors, a `warning()` names how many lookups could not be
#' attempted and why; the affected names are returned as `NA`.
#'
#' @param names Character vector of first names (NA/"" are ignored).
#' @param threshold Numeric, minimum acceptable prediction confidence.
#' @return A character vector named by the unique, non-missing input names,
#'   valued "Male", "Female", or `NA_character_` when unresolved.
#' @keywords internal
#' @importFrom stats setNames
lookup_first_name_gender <- function(names, threshold = get_param("classification_threshold")) {
  unique_names <- unique(names[!is.na(names) & nzchar(names)])
  if (length(unique_names) == 0) {
    return(stats::setNames(character(0), character(0)))
  }

  result <- stats::setNames(rep(NA_character_, length(unique_names)), unique_names)

  if (!requireNamespace("gender", quietly = TRUE)) {
    warning(sprintf(
      "The 'gender' package is not available: %d name(s) could not be looked up and remain Unknown.",
      length(unique_names)
    ))
    return(result)
  }

  methods <- list(
    list(method = "napp", years = c(1758, 1997)),
    list(method = "ipums", years = c(1789, 1930)),
    list(method = "ssa", years = c(1880, 2012))
  )

  for (m in methods) {
    remaining <- names(result)[is.na(result)]
    if (length(remaining) == 0) break

    # The whole per-method block is wrapped in suppressWarnings(): the
    # `gender` package's own "year range ... trimmed" advisory is not an
    # error in our lookup and is expected whenever our (deliberately wide)
    # cascade years exceed a given method's calibrated range. Wrapping only
    # the gender::gender() call left this warning able to surface later,
    # e.g. when dplyr re-signals a warning captured while evaluating this
    # function inside a mutate() column expression.
    # A lookup error is recorded here and re-signalled AFTER this block:
    # a warning() raised inside suppressWarnings() would itself be muffled,
    # silently turning a failed lookup into "Unknown" (#84).
    lookup_error <- NULL
    suppressWarnings({
      preds <- tryCatch(
        gender::gender(remaining, years = m$years, method = m$method),
        error = function(e) {
          lookup_error <<- conditionMessage(e)
          NULL
        }
      )

      if (!is.null(preds) && nrow(preds) > 0) {
        preds <- preds[preds$gender %in% c("male", "female"), , drop = FALSE]
        if (nrow(preds) > 0) {
          confidence <- pmax(preds$proportion_male, 1 - preds$proportion_male)
          accepted <- confidence >= threshold
          result[preds$name[accepted]] <- stringr::str_to_title(preds$gender[accepted])
        }
      }
    })

    if (!is.null(lookup_error)) {
      warning(sprintf(
        "gender lookup via method '%s' failed for %d name(s): %s",
        m$method, length(remaining), lookup_error
      ))
    }
  }

  result
}

# Helper function: Classify gender
#
# The text is first reduced to its subject X ("Statue of X in ..." -> X, see
# extract_subject()). Priority order: (1) an explicit gender_mapping always
# wins, (1b) a Wikidata person match for X (person_lookup) whose confidence
# is at least `threshold`, (2) a
# documented title/term override at the start of a person-segment, which
# also beats an animal word, so "Duke of Wellington on horse" is Male (#98
# item 2), (3) animal detection, (4) a genderdata name lookup (see
# lookup_first_name_gender()), (5) "Unknown". Segments that are church/school dedications or
# sites are not people (see is_non_person_part()). A subject naming more
# than one person returns "Mixed" when the resolved people disagree, or
# that shared gender when they agree.
classify_gender_from_subject <- function(subjects, names = NULL, gender_mapping = NULL,
                                         person_lookup = NULL,
                                         threshold = get_param("classification_threshold")) {
  if (!is.null(gender_mapping)) {
    return(gender_mapping[subjects])
  }

  text_to_check <- extract_subject(dplyr::coalesce(subjects, names))
  n <- length(text_to_check)
  classified <- rep(NA_character_, n)

  is_missing <- is.na(text_to_check) | !nzchar(stringr::str_trim(dplyr::coalesce(text_to_check, "")))
  classified[is_missing] <- "Unknown"

  # A Wikidata person match for X at or above the threshold decides it.
  if (!is.null(person_lookup) && nrow(person_lookup) > 0) {
    accepted <- person_lookup[!is.na(person_lookup$sex) &
                                person_lookup$confidence >= threshold, , drop = FALSE]
    wd_sex <- accepted$sex[match(text_to_check, accepted$x)]
    use <- is.na(classified) & !is.na(wd_sex)
    classified[use] <- wd_sex[use]
  }

  animal_regex <- "(?i)\\b(dog|horse|lion|animal|cat|bear|pigeon|dolphin|elephant|donkey|camel|animals? in war)\\b"
  is_animal <- !is_missing & stringr::str_detect(text_to_check, animal_regex)

  remaining_idx <- which(is.na(classified))
  if (length(remaining_idx) == 0) return(classified)

  overrides <- load_gender_overrides()

  parts_list <- purrr::map(text_to_check[remaining_idx], function(x) {
    parts <- split_into_person_parts(x)
    parts[!is_non_person_part(parts)]
  })
  override_list <- purrr::map(parts_list, function(parts) {
    purrr::map_chr(parts, match_gender_override, overrides = overrides)
  })

  extract_candidate_name <- function(part) {
    tokens <- extract_first_names(part)
    if (length(tokens) > 0) tokens[1] else NA_character_
  }

  candidate_names <- purrr::map2(parts_list, override_list, function(parts, og) {
    unresolved <- parts[is.na(og)]
    if (length(unresolved) == 0) return(character(0))
    purrr::map_chr(unresolved, extract_candidate_name)
  })

  all_candidates <- unique(unlist(candidate_names, use.names = FALSE))
  all_candidates <- all_candidates[!is.na(all_candidates) & nzchar(all_candidates)]

  name_gender_map <- if (length(all_candidates) > 0) {
    lookup_first_name_gender(all_candidates, threshold = threshold)
  } else {
    stats::setNames(character(0), character(0))
  }

  for (i in seq_along(remaining_idx)) {
    resolved <- override_list[[i]]

    unresolved_mask <- is.na(resolved)
    if (any(unresolved_mask)) {
      # Reuse the candidates computed above (same order as the unresolved
      # parts) rather than extracting them again (#98 item 10).
      looked_up_names <- candidate_names[[i]]
      looked_up <- ifelse(
        !is.na(looked_up_names) & looked_up_names %in% names(name_gender_map),
        name_gender_map[looked_up_names],
        NA_character_
      )
      resolved[unresolved_mask] <- looked_up
    }

    resolved <- resolved[!is.na(resolved)]
    j <- remaining_idx[i]
    # An animal word loses only to an explicit title ("Duke of Wellington on
    # horse"), not to a name lookup: the lookup also resolves animals' names
    # ("Hodge the Cat" -> Male), as seen in the real data (#98 item 2).
    has_title <- any(!is.na(override_list[[i]]))
    classified[j] <- if (is_animal[j] && !has_title) {
      "Animal"
    } else if (length(resolved) == 0) {
      "Unknown"
    } else if (length(unique(resolved)) > 1) {
      "Mixed"
    } else {
      unique(resolved)
    }
  }

  classified
}

#' Compare John Statues vs Women Statues
#'
#' @description
#' Validates the "Statues for Equality" claim that there are more statues
#' named John than women in the UK.
#'
#' @param statue_data Standardized statue data tibble
#' @inheritParams analyze_by_gender
#'
#' @return A list with comparison results:
#'   - total_statues: identifiable statues (with a name or subject), the
#'     denominator of every share; unnamed_statues: records with neither,
#'     which are not counted (#117)
#'   - john_statues, woman_statues, john_percent, woman_percent,
#'     claim_validated, message. \code{woman_statues} counts every statue
#'     that depicts a woman: \code{woman_only_statues} (only women) plus
#'     \code{mixed_statues} (a woman together with a man, e.g. "Queen
#'     Victoria and Prince Albert").
#'   - unknown_statues, unknown_percent: statues whose gender could not be
#'     confidently classified (see classify_gender_from_subject())
#'   - john_percent_label, woman_percent_label, unknown_percent_label:
#'     whole-percent display text from format_percent(). The numeric
#'     *_percent fields keep 2 decimal places.
#'   - gender_method: which classification sources were used, in priority
#'     order (Wikidata P21, title/term overrides, then the genderdata lookup
#'     cascade when the gender and genderdata packages are available)
#'
#' @export
compare_johns_vs_women <- function(statue_data, person_lookup = NULL,
                                   threshold = get_param("classification_threshold")) {
  classified <- analyze_by_gender(statue_data, person_lookup = person_lookup,
                                  threshold = threshold)$data

  # Extract all names using the robust logic
  all_names <- classified %>%
    dplyr::filter(!is.na(name) | !is.na(subject)) %>%
    dplyr::mutate(
      extracted_names = purrr::map(dplyr::coalesce(subject, name), extract_first_names)
    ) %>%
    tidyr::unnest(extracted_names)

  # Count Johns
  johns <- all_names %>%
    dplyr::filter(stringr::str_detect(extracted_names, "(?i)^(john|jon|jonathan|jean|jonny)$")) %>%
    nrow()

  # Count statues of women (row-level classification). The claim is about
  # *number of statues*, not *number of people*, so a statue with 2 women
  # counts once. A "Mixed" statue is one whose resolved people include both
  # a woman and a man (e.g. "Queen Victoria and Prince Albert"); it depicts
  # a woman, so it counts as a statue of a woman (#98). Johns are counted
  # independently, so such a statue can also count as a John statue.
  woman_only <- classified %>%
    dplyr::filter(inferred_gender == "Female") %>%
    nrow()
  mixed <- classified %>%
    dplyr::filter(inferred_gender == "Mixed") %>%
    nrow()
  women <- woman_only + mixed

  # Count statues whose gender could not be confidently classified at all.
  unknown_statues <- classified %>%
    dplyr::filter(inferred_gender == "Unknown") %>%
    nrow()

  # Shares are of identifiable statues: records with no name and no subject
  # cannot be about John or a woman, so they would only dilute them (#117).
  unnamed <- sum(classified$inferred_gender == "Unnamed")
  total <- nrow(classified) - unnamed
  unknown_percent <- round(100 * unknown_statues / total, 2)

  results <- list(
    total_statues = total,
    unnamed_statues = unnamed,
    john_statues = johns,
    woman_statues = women,
    woman_only_statues = woman_only,
    mixed_statues = mixed,
    john_percent = round(100 * johns / total, 2),
    woman_percent = round(100 * women / total, 2),
    # Whole-percent display text, formatted from the raw counts (#102)
    john_percent_label = format_percent(johns, total),
    woman_percent_label = format_percent(women, total),
    unknown_percent_label = format_percent(unknown_statues, total),
    unknown_statues = unknown_statues,
    unknown_percent = unknown_percent,
    claim_validated = johns > women,
    # Records what actually ran, not what was intended (#98 item 4)
    gender_method = paste0(
      "wikidata_p21",
      if (!is.null(person_lookup) && nrow(person_lookup) > 0) "+wikidata_subject_lookup" else "",
      "+overrides",
      if (genderdata_available()) "+genderdata_napp_ipums_ssa" else " (genderdata lookup unavailable)"
    ),
    classification_threshold = threshold,
    wikidata_confidence = wikidata_confidence(),
    message = sprintf(
      "Found %d statues named John/Jon/Jean (%s) vs %d women statues (%s%s). %d statues (%s) have unknown gender. Shares are of %d identifiable statues; %d records with no name or subject are not counted.",
      johns, format_percent(johns, total), women, format_percent(women, total),
      if (mixed > 0) sprintf(", including %d of a woman with a man", mixed) else "",
      unknown_statues, format_percent(unknown_statues, total),
      total, unnamed
    )
  )

  return(results)
}

# Helper (mockable): can the genderdata name-lookup cascade run?
genderdata_available <- function() {
  requireNamespace("gender", quietly = TRUE) &&
    requireNamespace("genderdata", quietly = TRUE)
}
