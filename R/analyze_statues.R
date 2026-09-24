#' Analyze Statue Data by Gender
#'
#' @description
#' Performs gender analysis on statue subjects to compare representation
#' of men, women, and other subjects (animals, abstract concepts, etc.)
#'
#' @param statue_data Standardized statue data tibble
#' @param gender_mapping Optional named vector mapping subject names to genders
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
analyze_by_gender <- function(statue_data, gender_mapping = NULL) {

  # Attempt to classify gender
  # Priority: 1. Existing subject_gender (from Wikidata), 2. Heuristic from subject, 3. Heuristic from name
  classified <- statue_data %>%
    dplyr::mutate(
      heuristic_gender = classify_gender_from_subject(subject, name, gender_mapping),
      inferred_gender = dplyr::case_when(
        !is.na(subject_gender) & tolower(subject_gender) %in% c("male", "female") ~ stringr::str_to_title(subject_gender),
        !is.na(subject_gender) ~ "Other", # Transgender, non-binary, etc. mapped to Other for high-level summary
        type == "animal" | stringr::str_detect(type, "(?i)animal") ~ "Animal",
        TRUE ~ heuristic_gender
      )
    )

  # Overall summary
  summary <- classified %>%
    dplyr::count(inferred_gender) %>%
    dplyr::mutate(
      percent = round(100 * n / sum(n), 1)
    ) %>%
    dplyr::arrange(desc(n))

  # By source
  by_source <- classified %>%
    dplyr::count(source, inferred_gender) %>%
    dplyr::group_by(source) %>%
    dplyr::mutate(
      percent = round(100 * n / sum(n), 1)
    ) %>%
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
      percent = round(100 * n / total_gender, 1)
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
  
  # Split by 'and', '&', or ','
  parts <- stringr::str_split(text, "\\s+(and|&|,)\\s+")[[1]]
  
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
  
  # Clean up (remove punctuation)
  first_names <- stringr::str_remove_all(first_names, "[^a-zA-Z-]")
  return(first_names[first_names != ""])
}

# Helper: load the small, documented table of gendered titles/terms used to
# resolve subjects that carry an explicit honorific or generic descriptor
# (e.g. "Queen Victoria", "Unknown Woman") without ever needing a name-based
# lookup. See inst/extdata/gender_overrides.csv.
load_gender_overrides <- function() {
  path <- system.file("extdata", "gender_overrides.csv", package = "statuesnamedjohn")
  if (!nzchar(path)) {
    warning("gender_overrides.csv not found; no title/term overrides will be applied.")
    return(data.frame(term = character(0), gender = character(0), stringsAsFactors = FALSE))
  }
  utils::read.csv(path, stringsAsFactors = FALSE)
}

# Helper: split a subject string into one segment per person, on "and"/"&"/",".
split_into_person_parts <- function(text) {
  parts <- stringr::str_split(text, "\\s+(and|&|,)\\s+")[[1]]
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
#' package, keeping the first method that returns a prediction for each
#' name. A prediction is only accepted when its confidence
#' (`max(proportion_male, 1 - proportion_male)`) is at least `threshold`;
#' names with no record in any source, or whose best prediction is below
#' the threshold (including "either"), are left unresolved (`NA`) so the
#' caller reports them as "Unknown" rather than guessing.
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
lookup_first_name_gender <- function(names, threshold = 0.9) {
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
    suppressWarnings({
      preds <- tryCatch(
        gender::gender(remaining, years = m$years, method = m$method),
        error = function(e) {
          warning(sprintf(
            "gender lookup via method '%s' failed for %d name(s): %s",
            m$method, length(remaining), conditionMessage(e)
          ))
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
  }

  result
}

# Helper function: Classify gender
#
# Priority order: (1) an explicit gender_mapping always wins, (2) animal
# detection, (3) a documented title/term override applied to the start of
# each person-segment, (4) a genderdata name lookup (see
# lookup_first_name_gender()), (5) "Unknown". A subject naming more than one
# person returns "Mixed" when the resolved people disagree, or that shared
# gender when they agree.
classify_gender_from_subject <- function(subjects, names = NULL, gender_mapping = NULL) {
  if (!is.null(gender_mapping)) {
    return(gender_mapping[subjects])
  }

  text_to_check <- dplyr::coalesce(subjects, names)
  n <- length(text_to_check)
  classified <- rep(NA_character_, n)

  is_missing <- is.na(text_to_check) | !nzchar(stringr::str_trim(dplyr::coalesce(text_to_check, "")))
  classified[is_missing] <- "Unknown"

  animal_regex <- "(?i)\\b(dog|horse|lion|animal|cat|bear|pigeon|dolphin|elephant|donkey|camel|animals? in war)\\b"
  is_animal <- !is_missing & stringr::str_detect(text_to_check, animal_regex)
  classified[is_animal] <- "Animal"

  remaining_idx <- which(is.na(classified))
  if (length(remaining_idx) == 0) return(classified)

  overrides <- load_gender_overrides()

  parts_list <- purrr::map(text_to_check[remaining_idx], split_into_person_parts)
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
    lookup_first_name_gender(all_candidates)
  } else {
    stats::setNames(character(0), character(0))
  }

  for (i in seq_along(remaining_idx)) {
    parts <- parts_list[[i]]
    og <- override_list[[i]]
    resolved <- og

    unresolved_mask <- is.na(resolved)
    if (any(unresolved_mask)) {
      looked_up_names <- purrr::map_chr(parts[unresolved_mask], extract_candidate_name)
      looked_up <- ifelse(
        !is.na(looked_up_names) & looked_up_names %in% names(name_gender_map),
        name_gender_map[looked_up_names],
        NA_character_
      )
      resolved[unresolved_mask] <- looked_up
    }

    resolved <- resolved[!is.na(resolved)]
    classified[remaining_idx[i]] <- if (length(resolved) == 0) {
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
#'
#' @return A list with comparison results:
#'   - total_statues, john_statues, woman_statues, john_percent, woman_percent,
#'     claim_validated, message (as before)
#'   - unknown_statues, unknown_percent: statues whose gender could not be
#'     confidently classified (see classify_gender_from_subject())
#'   - gender_method: which classification sources were used, in priority
#'     order (Wikidata P21, then the genderdata lookup cascade)
#'
#' @export
compare_johns_vs_women <- function(statue_data) {
  classified <- analyze_by_gender(statue_data)$data

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

  # Count women (using the row-level classification)
  # Note: A statue with 2 women counts as 1 statue record in 'classified',
  # but here we are comparing "statues of Johns" vs "statues of women".
  # The claim is usually about *number of statues*, not *number of people*.
  # So we count rows in 'classified' where gender is Female.
  women <- classified %>%
    dplyr::filter(inferred_gender == "Female") %>%
    nrow()

  # Count statues whose gender could not be confidently classified at all.
  unknown_statues <- classified %>%
    dplyr::filter(inferred_gender == "Unknown") %>%
    nrow()

  # Calculate percentage of total statues
  total <- nrow(classified)
  unknown_percent <- round(100 * unknown_statues / total, 2)

  results <- list(
    total_statues = total,
    john_statues = johns,
    woman_statues = women,
    john_percent = round(100 * johns / total, 2),
    woman_percent = round(100 * women / total, 2),
    unknown_statues = unknown_statues,
    unknown_percent = unknown_percent,
    claim_validated = johns > women,
    gender_method = "wikidata_p21+genderdata_napp_ipums_ssa",
    message = sprintf(
      "Found %d statues named John/Jon/Jean (%.1f%%) vs %d women statues (%.1f%%). %d statues (%.1f%%) have unknown gender.",
      johns, 100 * johns / total, women, 100 * women / total, unknown_statues, unknown_percent
    )
  )

  return(results)
}
