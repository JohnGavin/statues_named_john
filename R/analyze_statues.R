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
#'   - data: original data with 'inferred_gender' column
#'
#' @examples
#' \dontrun{
#' all_statues <- get_all_statue_data()
#' gender_analysis <- analyze_by_gender(all_statues)
#' print(gender_analysis$summary)
#' }
#'
#' @export
analyze_by_gender <- function(statue_data, gender_mapping = NULL) {

  # Attempt to classify gender
  # Priority: 1. Existing subject_gender (from Wikidata), 2. Heuristic from name
  classified <- statue_data %>%
    dplyr::mutate(
      heuristic_gender = classify_gender_from_subject(subject, gender_mapping),
      inferred_gender = dplyr::case_when(
        !is.na(subject_gender) & subject_gender %in% c("male", "female") ~ stringr::str_to_title(subject_gender),
        !is.na(subject_gender) ~ "Other", # Transgender, non-binary, etc. mapped to Other for high-level summary
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

  return(list(
    summary = summary,
    by_source = by_source,
    top_subjects = top_subjects,
    data = classified
  ))
}

# Helper function: Classify gender
classify_gender_from_subject <- function(subjects, gender_mapping = NULL) {
  if (!is.null(gender_mapping)) {
    return(gender_mapping[subjects])
  }

  # Simple heuristic classification (would need enhancement)
  classified <- dplyr::case_when(
    is.na(subjects) ~ "Unknown",
    stringr::str_detect(subjects, "(?i)queen|victoria|elizabeth|woman") ~ "Female",
    stringr::str_detect(subjects, "(?i)king|prince|duke|sir|man|admiral") ~ "Male",
    stringr::str_detect(subjects, "(?i)dog|horse|lion|animal") ~ "Animal",
    TRUE ~ "Unknown"
  )

  return(classified)
}

#' Compare John Statues vs Women Statues
#'
#' @description
#' Validates the "Statues for Equality" claim that there are more statues
#' named John than women in the UK.
#'
#' @param statue_data Standardized statue data tibble
#'
#' @return A list with comparison results
#'
#' @export
compare_johns_vs_women <- function(statue_data) {
  classified <- analyze_by_gender(statue_data)$data

  # Count Johns
  johns <- classified %>%
    dplyr::filter(stringr::str_detect(subject, "(?i)john")) %>%
    nrow()

  # Count women
  women <- classified %>%
    dplyr::filter(inferred_gender == "Female") %>%
    nrow()

  # Calculate percentage
  total <- nrow(classified)

  results <- list(
    total_statues = total,
    john_statues = johns,
    woman_statues = women,
    john_percent = round(100 * johns / total, 2),
    woman_percent = round(100 * women / total, 2),
    claim_validated = johns > women,
    message = sprintf(
      "Found %d statues named John (%.1f%%) vs %d women statues (%.1f%%). ",
      johns, 100 * johns / total, women, 100 * women / total
    )
  )

  return(results)
}
