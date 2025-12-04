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
#' @export
analyze_by_gender <- function(statue_data, gender_mapping = NULL) {

  # Attempt to classify gender
  # Priority: 1. Existing subject_gender (from Wikidata), 2. Heuristic from subject, 3. Heuristic from name
  classified <- statue_data %>%
    dplyr::mutate(
      heuristic_gender = classify_gender_from_subject(subject, name, gender_mapping),
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

# Helper function: Classify gender
classify_gender_from_subject <- function(subjects, names = NULL, gender_mapping = NULL) {
  if (!is.null(gender_mapping)) {
    return(gender_mapping[subjects])
  }
  
  text_to_check <- dplyr::coalesce(subjects, names)

  # Heuristic using common names (Top 50-100 common English names)
  # Source: US SSA / UK ONS common historic names
  classified <- dplyr::case_when(
    is.na(text_to_check) ~ "Unknown",
    
    # Female Names & Titles
    stringr::str_detect(text_to_check, "(?i)\\b(queen|victoria|elizabeth|woman|mary|anne|lady|dame|florence|edith|patricia|linda|barbara|jennifer|maria|susan|margaret|dorothy|lisa|nancy|karen|betty|helen|sandra|donna|carol|ruth|sharon|michelle|laura|sarah|kimberly|deborah|jessica|shirley|cynthia|angela|melissa|brenda|amy|anna|rebecca|virginia|kathleen|pamela|martha|debra|amanda|stephanie|carolyn|christine|marie|janet|catherine|frances|ann|joyce|diane)\\b") ~ "Female",
    
    # Male Names & Titles
    stringr::str_detect(text_to_check, "(?i)\\b(king|prince|duke|sir|man|admiral|john|william|george|henry|charles|james|edward|richard|robert|thomas|arthur|michael|david|joseph|christopher|daniel|paul|mark|kenneth|steven|brian|ronald|anthony|kevin|jason|matthew|gary|timothy|jose|larry|jeffrey|frank|scott|eric|stephen|andrew|raymond|gregory|joshua|jerry|dennis|walter|patrick|peter|harold|douglas|carl|ryan|roger)\\b") ~ "Male",
    
    # Animals
    stringr::str_detect(text_to_check, "(?i)\\b(dog|horse|lion|animal|cat)\\b") ~ "Animal",
    
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

  # Calculate percentage of total statues
  total <- nrow(classified)

  results <- list(
    total_statues = total,
    john_statues = johns,
    woman_statues = women,
    john_percent = round(100 * johns / total, 2),
    woman_percent = round(100 * women / total, 2),
    claim_validated = johns > women,
    message = sprintf(
      "Found %d statues named John/Jon/Jean (%.1f%%) vs %d women statues (%.1f%%). ",
      johns, 100 * johns / total, women, 100 * women / total
    )
  )

  return(results)
}
