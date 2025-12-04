#' Generate QA Sample for Manual Validation
#'
#' @description
#' Selects a random sample of statue records that require manual validation,
#' focusing on 'Unknown' genders, potential errors, or missing metadata.
#'
#' @param statue_data The standardized statue data tibble
#' @param sample_size Number of records to sample (default: 50)
#' @param output_path Optional path to save the CSV (default: NULL)
#'
#' @return A tibble containing the sample
#' @export
generate_qa_sample <- function(statue_data, sample_size = 50, output_path = NULL) {
  
  # Run analysis to get inferred genders
  analyzed <- analyze_by_gender(statue_data)
  data <- analyzed$data
  
  # Define risk criteria
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
  
  # Sample
  if (nrow(flagged) > sample_size) {
    sample_data <- flagged %>% dplyr::slice_sample(n = sample_size)
  } else {
    sample_data <- flagged
  }
  
  # Select useful columns for human reviewer
  qa_output <- sample_data %>%
    dplyr::select(
      risk_reason,
      source,
      name,
      subject,
      inferred_gender,
      subject_gender,
      url = dplyr::coalesce(wikipedia_url, image_url)
    ) %>%
    dplyr::mutate(
      validation_correct = "",
      validation_notes = ""
    )
  
  if (!is.null(output_path)) {
    readr::write_csv(qa_output, output_path)
    message("QA sample written to ", output_path)
  }
  
  return(qa_output)
}
