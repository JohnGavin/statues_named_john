#' Standardize Statue Data to Common Schema
#'
#' @description
#' Converts statue data from any source to a standardized schema with
#' consistent column names, data types, and structure.
#'
#' @param data A tibble from any source (wikidata, osm, glher, etc.)
#' @param source Source identifier ("wikidata", "osm", "glher", "he")
#'
#' @return A tibble with standardized schema:
#'   - id: character - unique identifier (source_originalid)
#'   - name: character - statue/memorial name
#'   - subject: character - who/what is commemorated
#'   - subject_gender: character - gender (if determinable)
#'   - lat: numeric - latitude (WGS84)
#'   - lon: numeric - longitude (WGS84)
#'   - location: character - human-readable location
#'   - type: character - statue, memorial, plaque, etc.
#'   - material: character - bronze, stone, etc.
#'   - year_installed: integer - year of installation/inception
#'   - sculptor: character - creator name
#'   - description: character - full description
#'   - image_url: character - URL to image
#'   - source: character - data source
#'   - source_url: character - link to source record
#'   - last_updated: Date - when data was retrieved
#'
#' @examples
#' \dontrun{
#' wikidata_raw <- get_statues_wikidata()
#' wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
#' }
#'
#' @export
standardize_statue_data <- function(data, source) {

  if (nrow(data) == 0) {
    return(create_empty_standard_schema())
  }

  standardized <- switch(source,
    "wikidata" = standardize_wikidata(data),
    "osm" = standardize_osm(data),
    "glher" = standardize_glher(data),
    "he" = standardize_historic_england(data),
    stop("Unknown source: ", source)
  )

  # Ensure all required columns exist
  standardized <- ensure_standard_columns(standardized)

  # Add metadata
  standardized <- standardized %>%
    dplyr::mutate(
      source = source,
      last_updated = Sys.Date()
    )

  return(standardized)
}

# Helper function: Create empty schema
create_empty_standard_schema <- function() {
  tibble::tibble(
    id = character(),
    name = character(),
    subject = character(),
    subject_gender = character(),
    lat = numeric(),
    lon = numeric(),
    location = character(),
    type = character(),
    material = character(),
    year_installed = integer(),
    sculptor = character(),
    description = character(),
    image_url = character(),
    source = character(),
    source_url = character(),
    nhle_id = character(),
    last_updated = as.Date(character())
  )
}

# Helper function: Standardize Wikidata
standardize_wikidata <- function(data) {
  data %>%
    dplyr::transmute(
      id = paste0("wikidata_", wikidata_id),
      name = name,
      subject = subject,
      subject_gender = subject_gender,  # Now fetched from query
      lat = lat,
      lon = lon,
      location = NA_character_,  # Could reverse geocode
      type = "statue",
      material = material,
      year_installed = as.integer(stringr::str_extract(inception_date, "^[0-9]{4}")),
      sculptor = creator,
      description = NA_character_,
      image_url = image_url,
      source_url = wikipedia_url,
      nhle_id = as.character(nhle_id)
    )
}

# Helper function: Standardize OSM
standardize_osm <- function(data) {
  data %>%
    dplyr::transmute(
      id = paste0("osm_", osm_id),
      name = name,
      subject = subject,
      subject_gender = NA_character_,
      lat = lat,
      lon = lon,
      location = NA_character_,
      type = dplyr::coalesce(memorial_type, historic_type, man_made_type, "memorial"),
      material = material,
      year_installed = NA_integer_,
      sculptor = NA_character_,
      description = NA_character_,
      image_url = NA_character_,
      source_url = dplyr::if_else(
        !is.na(wikipedia),
        paste0("https://en.wikipedia.org/wiki/", wikipedia),
        paste0("https://www.openstreetmap.org/", osm_type, "/", osm_id)
      ),
      nhle_id = NA_character_
    )
}

# Helper function: Standardize GLHER
standardize_glher <- function(data) {
  data %>%
    dplyr::transmute(
      id = paste0("glher_", glher_id),
      name = name,
      subject = NA_character_,  # May need to extract from description
      subject_gender = NA_character_,
      lat = lat,
      lon = lon,
      location = NA_character_,
      type = type,
      material = NA_character_,
      year_installed = NA_integer_,  # May be in period field
      sculptor = NA_character_,
      description = description,
      image_url = NA_character_,
      source_url = url,
      nhle_id = NA_character_
    )
}

# Helper function: Standardize Historic England
standardize_historic_england <- function(data) {
  data %>%
    dplyr::transmute(
      id = paste0("he_", list_entry_number),
      name = name,
      subject = NA_character_,
      subject_gender = NA_character_,
      lat = lat,  # Will be NA unless geocoded
      lon = lon,  # Will be NA unless geocoded
      location = location,
      type = "statue",
      material = NA_character_,
      year_installed = NA_integer_,
      sculptor = NA_character_,
      description = paste(heritage_category, grade, sep = " - "),
      image_url = NA_character_,
      source_url = url,
      nhle_id = list_entry_number
    )
}

# Helper function: Ensure all standard columns exist
ensure_standard_columns <- function(data) {
  standard_cols <- create_empty_standard_schema()

  for (col in names(standard_cols)) {
    if (!col %in% names(data)) {
      data[[col]] <- standard_cols[[col]][1]
    }
  }

  return(data)
}
