#' Generate QA Samples for Data Inspection
#'
#' @description
#' Generates a set of tibbles to inspect the quality and content of the statue dataset.
#' Includes \"flagged\" edge cases, random samples, and specific category subsets.
#'
#' @param statue_data The standardized statue data tibble
#' @param sample_size Number of records for random/flagged samples (default: 50)
#' @param output_path Optional path to save the flagged CSV (default: NULL)
#'
#' @return A named list of tibbles:
#'   - `flagged`: Records with Unknown gender, missing metadata, etc.
#'   - `random`: A purely random sample of the dataset.
#'   - `animals`: A sample of records classified as Animals.
#'   - `by_source`: A stratified sample (up to 10 per source).
#' @export
generate_qa_sample <- function(statue_data, sample_size = 50, output_path = NULL) {
  
  # Run analysis to get inferred genders if not present
  if (!"inferred_gender" %in% names(statue_data)) {
    analyzed <- analyze_by_gender(statue_data)
    data <- analyzed$data
  } else {
    data <- statue_data
  }
  
  # 1. Flagged / Edge Cases
  flagged <- data %>%
    dplyr::mutate(
      risk_reason = dplyr::case_when(
        inferred_gender == "Unknown" ~ "Unknown Gender",
        stringr::str_detect(subject, "(?i)unknown") ~ "Unknown Subject",
        is.na(subject) & is.na(name) ~ "Missing Name/Subject",
        inferred_gender == "Other" ~ "Verify 'Other' Gender",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::filter(!is.na(risk_reason))
  
  flagged_sample <- if (nrow(flagged) > sample_size) {
    flagged %>% dplyr::slice_sample(n = sample_size)
  } else {
    flagged
  }
  
  # 2. Random Sample
  random_sample <- data %>% 
    dplyr::slice_sample(n = sample_size)
  
  # 3. Animals
  animal_sample <- data %>%
    dplyr::filter(inferred_gender == "Animal" | stringr::str_detect(type, "(?i)animal")) %>%
    head(20)
    
  # 4. By Source
  by_source_sample <- data %>%
    dplyr::group_by(source) %>%
    dplyr::slice_head(n = 10) %>%
    dplyr::ungroup()
  
  # Select useful columns for display
  cols_to_keep <- c("source", "name", "subject", "inferred_gender", "type", "material", "inscription", "year_installed", "url", "wikipedia_url")
  # Intersect with existing names to avoid errors
  cols_to_keep <- intersect(cols_to_keep, names(data))
  
  # Add risk_reason to flagged only
  flagged_output <- flagged_sample %>%
    dplyr::select(dplyr::any_of(c("risk_reason", cols_to_keep)))
    
  # Others
  random_output <- random_sample %>% dplyr::select(dplyr::all_of(cols_to_keep))
  animal_output <- animal_sample %>% dplyr::select(dplyr::all_of(cols_to_keep))
  by_source_output <- by_source_sample %>% dplyr::select(dplyr::all_of(cols_to_keep))

  if (!is.null(output_path)) {
    readr::write_csv(flagged_output, output_path)
    message("Flagged QA sample written to ", output_path)
  }
  
  return(list(
    flagged = flagged_output,
    random = random_output,
    animals = animal_output,
    by_source = by_source_output
  ))
}
