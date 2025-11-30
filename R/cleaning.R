#' Clean and standardize names
#'
#' Removes honorifics, dates, and extra whitespace from names.
#'
#' @param name_vector Character vector of names
#' @return Cleaned character vector
#' @export
#' @importFrom stringr str_replace_all str_trim
clean_names <- function(name_vector) {
  name_vector %>%
    stringr::str_replace_all("(?i)^(Statue of |Memorial to |Bust of |Monument to |Sculpture of )", "") %>%
    stringr::str_replace_all("\\(.*?\\)", "") %>% # Remove parenthesized text (e.g. dates)
    stringr::str_replace_all("Sir |Dame |Lord |Lady |King |Queen |Prince |Princess ", "") %>%
    stringr::str_replace_all("[[:punct:]]", "") %>%
    stringr::str_trim()
}

#' Classify gender based on first name or available metadata
#'
#' A simple heuristic function. For robust analysis, relies on Wikidata 'gender' field.
#'
#' @param name Character string
#' @param known_gender Optional character string (e.g., from Wikidata)
#' @return "Male", "Female", or "Unknown"
#' @export
classify_gender <- function(name, known_gender = NA) {
  if (!is.na(known_gender) && known_gender != "unknown" && known_gender != "") {
    return(known_gender)
  }
  
  if (is.na(name) || name == "") return("unknown")

  # Very basic heuristic for fallback (can be expanded)
  first_name <- stringr::word(name, 1)
  
  # Common lists (placeholders - in real package use a dataset)
  common_male <- c("John", "William", "George", "Robert", "James", "Charles", "David", "Arthur", "Edward", "Henry", "Richard", "Thomas")
  common_female <- c("Mary", "Elizabeth", "Victoria", "Anne", "Sarah", "Margaret", "Florence", "Edith", "Catherine", "Alice")
  
  if (first_name %in% common_male) return("male")
  if (first_name %in% common_female) return("female")
  
  return("unknown")
}

#' Check if a subject is a "Man named John"
#'
#' @param name Character string of the subject's name
#' @param gender Character string (optional)
#' @return Logical
#' @export
#' @importFrom stringr str_detect word
is_man_named_john <- function(name, gender = "male") {
  if (is.na(name)) return(FALSE)

  # Normalize
  clean_name <- clean_names(name)
  first_name <- tolower(stringr::word(clean_name, 1))
  
  is_john <- first_name == "john" | first_name == "jon" | first_name == "jonathan"
  
  # If gender is explicitly female, return FALSE even if named John (rare but possible)
  if (!is.na(gender) && tolower(gender) == "female") {
    return(FALSE)
  }
  
  is_john
}

#' Classify subject type
#'
#' Categorizes subjects into "John", "Woman", "Dog", or "Other".
#'
#' @param name Character name
#' @param gender Character gender ("male", "female")
#' @param subjects_list List or vector of subject tags (e.g., "dog", "animal")
#' @return Character string category
#' @export
classify_subject <- function(name, gender, subjects_list = NULL) {
  if (is.na(name)) return("Other")
  
  name_lower <- tolower(name)

  # Check for animals
  if (!is.null(subjects_list)) {
    subjects_str <- tolower(paste(subjects_list, collapse = " "))
    if (grepl("\\bdogs?\\b", subjects_str)) return("Dogs")
    if (grepl("animal", subjects_str)) return("Other") # Could be specific animal
  }
  
  if (grepl("\\bdogs?\\b", name_lower)) return("Dogs")
  
  # Check for John
  if (is_man_named_john(name, gender)) return("Men named John")
  
  # Check for Women (Metadata or Name keywords)
  if (!is.na(gender) && tolower(gender) == "female") return("Women")
  
  women_terms <- c("\\bqueen\\b", "\\bwoman\\b", "\\bwomen\\b", "\\blady\\b", "\\bdame\\b", "\\bprincess\\b", "\\bduchess\\b")
  if (any(sapply(women_terms, function(x) grepl(x, name_lower)))) return("Women")
  
  return("Other")
}

#' Extract coordinates from WKT Point
#'
#' @param wkt Character string (e.g., "Point(-0.1 51.5)")
#' @return A named vector with lat and lon
#' @export
#' @importFrom stringr str_match
extract_coords_from_wkt <- function(wkt) {
  if (is.na(wkt)) return(c(lat = NA_real_, lon = NA_real_))
  
  # WKT format: "Point(LON LAT)"
  matches <- stringr::str_match(wkt, "Point\\(([^ ]+) ([^ ]+)\\)")
  
  if (nrow(matches) > 0 && !is.na(matches[1, 2])) {
    return(c(lon = as.numeric(matches[1, 2]), lat = as.numeric(matches[1, 3])))
  }
  
  return(c(lat = NA_real_, lon = NA_real_))
}

#' Normalize and Merge Data Sources
#'
#' Combines Wikidata and OSM data into a single clean dataset.
#'
#' @param wikidata_df Tibble from fetch_wikidata_statues
#' @param osm_df Tibble from fetch_osm_statues
#' @return A combined tibble
#' @export
#' @importFrom dplyr mutate select bind_rows distinct filter rowwise ungroup
#' @importFrom purrr map_dbl
join_and_clean_data <- function(wikidata_df, osm_df) {
  
  # Process Wikidata
  wiki_clean <- wikidata_df %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      lat = as.numeric(extract_coords_from_wkt(coords)["lat"]),
      lon = as.numeric(extract_coords_from_wkt(coords)["lon"])
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      gender = tolower(creator_gender),
      subject_category = purrr::map2_chr(title, gender, classify_subject)
    ) %>%
    dplyr::select(
      id = item,
      title = title,
      subject_category,
      lat,
      lon,
      date = inception,
      creator = creator,
      source = source
    )
  
  # Process OSM
  # OSM 'subject' might need gender inference
  osm_clean <- osm_df %>%
    dplyr::mutate(
      gender = purrr::map_chr(subject, classify_gender),
      subject_category = purrr::map2_chr(subject, gender, classify_subject),
      date = NA_character_,
      creator = NA_character_
    ) %>%
    dplyr::select(
      id = osm_id,
      title = name,
      subject_category,
      lat,
      lon,
      date,
      creator,
      source = source
    ) %>%
    dplyr::mutate(id = as.character(id)) %>%
    # Filter out items without names as they are hard to categorize
    dplyr::filter(!is.na(title))
  
  # Combine
  dplyr::bind_rows(wiki_clean, osm_clean) %>%
    # Basic deduplication based on title (very rough) or location could be added here
    # For now, keeping all distinct IDs
    dplyr::distinct(id, .keep_all = TRUE)
}
