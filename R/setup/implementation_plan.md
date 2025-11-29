# Multi-Source Statue Data Implementation Plan

**Date:** 2025-11-12
**Package:** londonremembers
**Goal:** Replace blocked web scraping with multi-source data retrieval and interactive mapping

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Data Retrieval Functions](#data-retrieval-functions)
3. [Data Standardization](#data-standardization)
4. [Data Merging & Deduplication](#data-merging--deduplication)
5. [Interactive Map Implementation](#interactive-map-implementation)
6. [Analysis Functions](#analysis-functions)
7. [Vignette Integration](#vignette-integration)
8. [File Structure](#file-structure)
9. [Usage Examples](#usage-examples)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Sources                              │
├─────────────┬─────────────┬─────────────┬──────────────────┤
│   Wikidata  │     OSM     │   GLHER     │ Historic England │
│   SPARQL    │  Overpass   │   CSV       │      CSV         │
└──────┬──────┴──────┬──────┴──────┬──────┴────────┬─────────┘
       │             │              │               │
       ▼             ▼              ▼               ▼
┌──────────────────────────────────────────────────────────────┐
│              Source-Specific Retrieval Functions             │
│  get_statues_wikidata() | get_statues_osm() |               │
│  get_statues_glher() | get_statues_historic_england()       │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Standardization Layer                           │
│              standardize_statue_data()                       │
│  Converts each source to common schema with:                 │
│  id, name, subject, lat, lon, type, year, source, url, etc. │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Merging & Deduplication                         │
│              combine_statue_sources()                        │
│  - Spatial join by coordinates (tolerance ~50m)              │
│  - Enrich records from multiple sources                      │
│  - Flag duplicates, keep best data                           │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Unified Dataset                                 │
│  Single tibble with all statues, coordinates, metadata       │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ├─────────────┬────────────────┐
                         ▼             ▼                ▼
                  ┌──────────┐  ┌──────────┐   ┌──────────────┐
                  │ Analysis │  │   Maps   │   │  Vignettes   │
                  │ Functions│  │ (leaflet)│   │  (updated)   │
                  └──────────┘  └──────────┘   └──────────────┘
```

---

## Data Retrieval Functions

### 1. Wikidata SPARQL Retrieval

**File:** `R/get_statues_wikidata.R`

```r
#' Retrieve Statue Data from Wikidata
#'
#' @description
#' Queries Wikidata SPARQL endpoint for statues in a specified location
#' with geographic coordinates and metadata.
#'
#' @param location Wikidata ID for location (default: "Q84" for London)
#' @param limit Maximum number of results (default: 1000)
#' @param cache_path Path to cache results (default: NULL for no caching)
#'
#' @return A tibble with columns: wikidata_id, name, subject, lat, lon,
#'   inception_date, material, creator, image_url, wikipedia_url
#'
#' @examples
#' \dontrun{
#' # Get all London statues from Wikidata
#' london_statues <- get_statues_wikidata(location = "Q84")
#'
#' # Get statues with caching
#' london_statues <- get_statues_wikidata(
#'   location = "Q84",
#'   cache_path = "data-raw/wikidata_cache.rds"
#' )
#' }
#'
#' @export
get_statues_wikidata <- function(location = "Q84",
                                   limit = 1000,
                                   cache_path = NULL) {

  # Check cache first
  if (!is.null(cache_path) && file.exists(cache_path)) {
    message("Loading cached Wikidata results from ", cache_path)
    return(readRDS(cache_path))
  }

  # SPARQL query
  sparql_query <- sprintf('
SELECT ?statue ?statueLabel ?coords ?subjectLabel ?inceptionDate
       ?materialLabel ?creatorLabel ?image ?article
WHERE {
  # Instance of statue
  ?statue wdt:P31 wd:Q179700.

  # Located in specified location (or any subdivision)
  ?statue wdt:P131+ wd:%s.

  # Must have coordinates
  ?statue wdt:P625 ?coords.

  # Optional fields
  OPTIONAL { ?statue wdt:P180 ?subject }
  OPTIONAL { ?statue wdt:P571 ?inceptionDate }
  OPTIONAL { ?statue wdt:P186 ?material }
  OPTIONAL { ?statue wdt:P170 ?creator }
  OPTIONAL { ?statue wdt:P18 ?image }

  # Wikipedia article link
  OPTIONAL {
    ?article schema:about ?statue .
    ?article schema:inLanguage "en" .
    ?article schema:isPartOf <https://en.wikipedia.org/> .
  }

  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
LIMIT %d
', location, limit)

  message("Querying Wikidata SPARQL endpoint...")
  message("Location: ", location, " | Limit: ", limit)

  # Execute query
  results <- WikidataQueryServiceR::query_wikidata(sparql_query)

  if (nrow(results) == 0) {
    warning("No statues found in Wikidata for location ", location)
    return(tibble::tibble())
  }

  message("Retrieved ", nrow(results), " records from Wikidata")

  # Parse coordinates from "Point(lon lat)" format
  coords_parsed <- results %>%
    dplyr::mutate(
      coords_clean = stringr::str_remove_all(coords, "Point\\(|\\)"),
      lon = as.numeric(stringr::str_extract(coords_clean, "^[^ ]+")),
      lat = as.numeric(stringr::str_extract(coords_clean, "[^ ]+$"))
    )

  # Standardize to tibble
  statues_wikidata <- coords_parsed %>%
    dplyr::transmute(
      wikidata_id = stringr::str_extract(statue, "Q[0-9]+$"),
      name = statueLabel,
      subject = subjectLabel,
      lat = lat,
      lon = lon,
      inception_date = inceptionDate,
      material = materialLabel,
      creator = creatorLabel,
      image_url = image,
      wikipedia_url = article,
      source = "wikidata"
    )

  # Cache if requested
  if (!is.null(cache_path)) {
    saveRDS(statues_wikidata, cache_path)
    message("Cached results to ", cache_path)
  }

  return(statues_wikidata)
}
```

---

### 2. OpenStreetMap Overpass Retrieval

**File:** `R/get_statues_osm.R`

```r
#' Retrieve Statue Data from OpenStreetMap
#'
#' @description
#' Queries OpenStreetMap Overpass API for statues and memorials
#' using multiple OSM tags to maximize coverage.
#'
#' @param bbox Bounding box (min_lon, min_lat, max_lon, max_lat).
#'   Default is Greater London.
#' @param tags OSM tags to query. Default includes memorial=statue,
#'   historic=memorial, man_made=statue
#' @param cache_path Path to cache results (default: NULL)
#'
#' @return A tibble with columns: osm_id, osm_type, name, subject, lat, lon,
#'   memorial_type, historic_type, tags_list
#'
#' @examples
#' \dontrun{
#' # Get all London statues from OSM
#' london_statues_osm <- get_statues_osm()
#'
#' # Custom bounding box (Westminster)
#' westminster_bbox <- c(-0.1773, 51.4899, -0.1131, 51.5155)
#' westminster_statues <- get_statues_osm(bbox = westminster_bbox)
#' }
#'
#' @export
get_statues_osm <- function(bbox = c(-0.510375, 51.28676, 0.334015, 51.691874),
                             tags = list(
                               list(key = "memorial", value = "statue"),
                               list(key = "historic", value = "memorial"),
                               list(key = "man_made", value = "statue")
                             ),
                             cache_path = NULL) {

  # Check cache
  if (!is.null(cache_path) && file.exists(cache_path)) {
    message("Loading cached OSM results from ", cache_path)
    return(readRDS(cache_path))
  }

  message("Querying OpenStreetMap Overpass API...")
  message("Bounding box: ", paste(bbox, collapse = ", "))

  all_results <- list()

  # Query each tag combination
  for (i in seq_along(tags)) {
    tag <- tags[[i]]
    message(sprintf("  Query %d/%d: %s=%s",
                    i, length(tags), tag$key, tag$value))

    tryCatch({
      query <- osmdata::opq(bbox = bbox) %>%
        osmdata::add_osm_feature(key = tag$key, value = tag$value) %>%
        osmdata::osmdata_sf()

      # Extract points (statues are usually point features)
      if (!is.null(query$osm_points) && nrow(query$osm_points) > 0) {
        all_results[[paste0(tag$key, "_", tag$value)]] <- query$osm_points
        message(sprintf("    Found %d features", nrow(query$osm_points)))
      } else {
        message("    No features found")
      }

    }, error = function(e) {
      warning(sprintf("Error querying %s=%s: %s", tag$key, tag$value, e$message))
    })

    # Be nice to Overpass API - rate limit
    Sys.sleep(2)
  }

  if (length(all_results) == 0) {
    warning("No statues found in OSM for the specified bounding box")
    return(tibble::tibble())
  }

  # Combine all results
  combined <- dplyr::bind_rows(all_results, .id = "query_tag")

  # Extract coordinates from sf geometry
  coords <- sf::st_coordinates(combined)

  # Standardize to tibble
  statues_osm <- combined %>%
    sf::st_drop_geometry() %>%
    dplyr::mutate(
      lon = coords[, 1],
      lat = coords[, 2]
    ) %>%
    dplyr::transmute(
      osm_id = osm_id,
      osm_type = as.character(query_tag),
      name = name,
      subject = subject,  # May be missing in many cases
      lat = lat,
      lon = lon,
      memorial_type = memorial,
      historic_type = historic,
      man_made_type = man_made,
      material = material,
      wikipedia = wikipedia,
      source = "osm"
    )

  message("Total unique OSM features retrieved: ", nrow(statues_osm))

  # Cache if requested
  if (!is.null(cache_path)) {
    saveRDS(statues_osm, cache_path)
    message("Cached results to ", cache_path)
  }

  return(statues_osm)
}
```

---

### 3. GLHER CSV Retrieval

**File:** `R/get_statues_glher.R`

```r
#' Retrieve Statue Data from Greater London HER
#'
#' @description
#' Downloads CSV data from Greater London Historic Environment Record (GLHER)
#' for monuments tagged as statues or person memorials.
#'
#' @param query_terms Search terms (default: c("person", "statue"))
#' @param resource_type Resource type filter (default: "Monument")
#' @param max_results Maximum results to retrieve (default: 500)
#' @param cache_path Path to cache results (default: NULL)
#'
#' @return A tibble with columns: glher_id, name, description, type,
#'   lat, lon, period, url
#'
#' @details
#' GLHER provides professional heritage data with high quality metadata
#' and precise coordinates. The CSV export is accessed via URL parameters.
#'
#' @examples
#' \dontrun{
#' # Get person statues from GLHER
#' glher_statues <- get_statues_glher()
#'
#' # Get all monument types
#' glher_monuments <- get_statues_glher(
#'   query_terms = NULL,
#'   max_results = 1000
#' )
#' }
#'
#' @export
get_statues_glher <- function(query_terms = c("person", "statue"),
                               resource_type = "Monument",
                               max_results = 500,
                               cache_path = NULL) {

  # Check cache
  if (!is.null(cache_path) && file.exists(cache_path)) {
    message("Loading cached GLHER results from ", cache_path)
    return(readRDS(cache_path))
  }

  # Build GLHER search URL
  base_url <- "https://glher.historicengland.org.uk/search"

  # Construct query parameters
  params <- list(
    `paging-filter` = 1,
    tiles = "true",
    format = "tilecsv",
    reportlink = "false",
    precision = 6,
    total = max_results
  )

  # Add term filters if provided
  if (!is.null(query_terms) && length(query_terms) > 0) {
    term_filter <- lapply(query_terms, function(term) {
      list(
        inverted = FALSE,
        type = "string",
        context = "",
        context_label = "",
        id = term,
        text = term,
        value = term
      )
    })
    params$`term-filter` <- jsonlite::toJSON(term_filter, auto_unbox = TRUE)
  }

  # Add resource type filter if provided
  if (!is.null(resource_type)) {
    # Monument graphid from GLHER system
    resource_filter <- list(
      list(
        graphid = "076f9381-7b00-11e9-8d6b-80000b44d1d9",
        name = resource_type,
        inverted = FALSE
      )
    )
    params$`resource-type-filter` <- jsonlite::toJSON(resource_filter, auto_unbox = TRUE)
  }

  message("Downloading data from GLHER...")
  message("Search terms: ", paste(query_terms, collapse = ", "))
  message("Resource type: ", resource_type)

  # Download CSV
  tryCatch({
    response <- httr::GET(base_url, query = params)

    if (httr::status_code(response) != 200) {
      stop("GLHER request failed with status ", httr::status_code(response))
    }

    # Parse CSV
    content_text <- httr::content(response, as = "text", encoding = "UTF-8")
    statues_glher_raw <- readr::read_csv(content_text, show_col_types = FALSE)

    message("Retrieved ", nrow(statues_glher_raw), " records from GLHER")

    # Standardize column names and extract coordinates
    statues_glher <- statues_glher_raw %>%
      dplyr::transmute(
        glher_id = `Monument ID`,  # Adjust based on actual column names
        name = Name,
        description = Description,
        type = `Monument Type`,
        lat = Latitude,
        lon = Longitude,
        period = Period,
        url = sprintf("https://glher.historicengland.org.uk/monument/%s", `Monument ID`),
        source = "glher"
      )

    # Cache if requested
    if (!is.null(cache_path)) {
      saveRDS(statues_glher, cache_path)
      message("Cached results to ", cache_path)
    }

    return(statues_glher)

  }, error = function(e) {
    warning("Error retrieving GLHER data: ", e$message)
    warning("Note: Column names may need adjustment based on actual GLHER CSV format")
    return(tibble::tibble())
  })
}
```

---

### 4. Historic England National Heritage List

**File:** `R/get_statues_historic_england.R`

```r
#' Retrieve Statue Data from Historic England National Heritage List
#'
#' @description
#' Downloads CSV data from Historic England's National Heritage List
#' for listed statues and monuments. Note: coordinates may require
#' geocoding from location text.
#'
#' @param search_query Search query (default: "monumentType:\"Statue\"")
#' @param max_results Maximum results (default: 500)
#' @param geocode Whether to attempt geocoding locations (default: FALSE)
#' @param cache_path Path to cache results (default: NULL)
#'
#' @return A tibble with columns: list_entry_number, name, heritage_category,
#'   grade, location, lat (if geocoded), lon (if geocoded), url
#'
#' @examples
#' \dontrun{
#' # Get listed statues
#' he_statues <- get_statues_historic_england()
#'
#' # With geocoding (requires additional setup)
#' he_statues_geo <- get_statues_historic_england(geocode = TRUE)
#' }
#'
#' @export
get_statues_historic_england <- function(search_query = 'monumentType:"Statue"',
                                          max_results = 500,
                                          geocode = FALSE,
                                          cache_path = NULL) {

  # Check cache
  if (!is.null(cache_path) && file.exists(cache_path)) {
    message("Loading cached Historic England results from ", cache_path)
    return(readRDS(cache_path))
  }

  base_url <- "https://historicengland.org.uk/listing/the-list/results/"

  params <- list(
    search = search_query,
    searchType = "NHLE Simple",
    page = 1
  )

  message("Downloading data from Historic England National Heritage List...")
  message("Search: ", search_query)

  # Note: This is a simplified example. The actual implementation
  # would need to:
  # 1. Navigate pagination
  # 2. Parse HTML results (or find CSV export link)
  # 3. Handle download of CSV
  # 4. Optionally geocode location strings

  warning("Historic England implementation requires manual CSV download")
  warning("Visit: ", httr::modify_url(base_url, query = params))
  warning("Then download CSV and load manually")

  # Placeholder for manual CSV loading
  statues_he <- tibble::tibble(
    list_entry_number = character(),
    name = character(),
    heritage_category = character(),
    grade = character(),
    location = character(),
    url = character(),
    source = character()
  )

  return(statues_he)
}
```

---

## Data Standardization

**File:** `R/standardize_statue_data.R`

```r
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
      subject_gender = NA_character_,  # Could be enhanced with additional query
      lat = lat,
      lon = lon,
      location = NA_character_,  # Could reverse geocode
      type = "statue",
      material = material,
      year_installed = as.integer(stringr::str_extract(inception_date, "^[0-9]{4}")),
      sculptor = creator,
      description = NA_character_,
      image_url = image_url,
      source_url = wikipedia_url
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
      )
    )
}

# Helper function: Standardize GLHER
standardize_glher <- function(data) {
  data %>%
    dplyr::transmute(
      id = paste0("glher_", glher_id),
      name = name,
      subject = NA_character_,  # May need to extract from description
      subject_gender = NA_character(),
      lat = lat,
      lon = lon,
      location = NA_character_,
      type = type,
      material = NA_character_,
      year_installed = NA_integer_,  # May be in period field
      sculptor = NA_character_,
      description = description,
      image_url = NA_character_,
      source_url = url
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
      source_url = url
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
```

---

## Data Merging & Deduplication

**File:** `R/combine_statue_sources.R`

```r
#' Combine and Deduplicate Statue Data from Multiple Sources
#'
#' @description
#' Merges statue data from multiple sources, deduplicates based on
#' geographic proximity, and enriches records with data from multiple sources.
#'
#' @param source_list Named list of standardized data frames, e.g.
#'   list(wikidata = wd_data, osm = osm_data, glher = glher_data)
#' @param distance_threshold Distance in meters for considering records
#'   as duplicates (default: 50)
#' @param prefer_sources Vector of source names in order of preference
#'   for resolving conflicts (default: c("glher", "wikidata", "osm", "he"))
#'
#' @return A tibble with combined, deduplicated statue data, with additional
#'   columns:
#'   - sources: character - comma-separated list of contributing sources
#'   - n_sources: integer - number of sources contributing data
#'   - is_multi_source: logical - TRUE if data from multiple sources
#'   - duplicate_ids: character - IDs of duplicate records that were merged
#'
#' @examples
#' \dontrun{
#' # Get data from all sources
#' wd <- get_statues_wikidata() %>% standardize_statue_data("wikidata")
#' osm <- get_statues_osm() %>% standardize_statue_data("osm")
#' glher <- get_statues_glher() %>% standardize_statue_data("glher")
#'
#' # Combine
#' all_statues <- combine_statue_sources(
#'   list(wikidata = wd, osm = osm, glher = glher)
#' )
#' }
#'
#' @export
combine_statue_sources <- function(source_list,
                                     distance_threshold = 50,
                                     prefer_sources = c("glher", "wikidata", "osm", "he")) {

  if (length(source_list) == 0) {
    stop("source_list must contain at least one data source")
  }

  message("Combining statue data from ", length(source_list), " sources")
  for (name in names(source_list)) {
    message("  ", name, ": ", nrow(source_list[[name]]), " records")
  }

  # Stack all sources
  all_records <- dplyr::bind_rows(source_list, .id = "source_name")

  message("\nTotal records before deduplication: ", nrow(all_records))

  # Convert to SF object for spatial operations
  all_records_sf <- all_records %>%
    dplyr::filter(!is.na(lat), !is.na(lon)) %>%
    sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

  # Find duplicates based on spatial proximity
  message("Identifying duplicates within ", distance_threshold, "m...")

  # Create distance matrix (this can be slow for large datasets)
  distances <- sf::st_distance(all_records_sf)

  # Find groups of nearby points
  duplicate_groups <- find_duplicate_groups(distances, distance_threshold)

  message("Found ", length(duplicate_groups), " groups of potential duplicates")

  # Merge duplicate groups
  merged_records <- merge_duplicate_groups(
    all_records_sf,
    duplicate_groups,
    prefer_sources
  )

  message("Records after deduplication: ", nrow(merged_records))

  # Convert back from SF to regular tibble with lat/lon columns
  merged_records_tibble <- merged_records %>%
    dplyr::mutate(
      coords = sf::st_coordinates(geometry),
      lon = coords[, 1],
      lat = coords[, 2]
    ) %>%
    sf::st_drop_geometry() %>%
    dplyr::select(-coords)

  return(merged_records_tibble)
}

# Helper function: Find groups of duplicates
find_duplicate_groups <- function(distance_matrix, threshold) {
  n <- nrow(distance_matrix)
  visited <- rep(FALSE, n)
  groups <- list()
  group_id <- 1

  for (i in 1:n) {
    if (visited[i]) next

    # Find all points within threshold of point i
    nearby <- which(distance_matrix[i, ] <= threshold)

    if (length(nearby) > 1) {
      groups[[group_id]] <- nearby
      visited[nearby] <- TRUE
      group_id <- group_id + 1
    }
  }

  return(groups)
}

# Helper function: Merge duplicate groups
merge_duplicate_groups <- function(sf_data, groups, prefer_sources) {
  # Separate records into duplicates and non-duplicates
  all_duplicate_indices <- unlist(groups)
  non_duplicate_indices <- setdiff(1:nrow(sf_data), all_duplicate_indices)

  non_duplicates <- sf_data[non_duplicate_indices, ]

  # Merge each group
  merged_groups <- lapply(groups, function(group_indices) {
    group_records <- sf_data[group_indices, ]
    merge_group(group_records, prefer_sources)
  })

  merged <- dplyr::bind_rows(merged_groups)

  # Combine non-duplicates with merged duplicates
  result <- dplyr::bind_rows(non_duplicates, merged)

  return(result)
}

# Helper function: Merge a single group of duplicates
merge_group <- function(group_records, prefer_sources) {
  # Sort by source preference
  group_records <- group_records %>%
    dplyr::mutate(
      source_priority = match(source, prefer_sources),
      source_priority = dplyr::if_else(is.na(source_priority),
                                        999L, source_priority)
    ) %>%
    dplyr::arrange(source_priority)

  # Start with highest priority record
  merged <- group_records[1, ]

  # Enrich with non-NA values from other sources
  for (col in names(merged)) {
    if (col %in% c("geometry", "source_priority")) next

    # If primary source has NA, try to fill from other sources
    if (is.na(merged[[col]])) {
      non_na_values <- group_records[[col]][!is.na(group_records[[col]])]
      if (length(non_na_values) > 0) {
        merged[[col]] <- non_na_values[1]
      }
    }
  }

  # Add metadata about merged sources
  merged$sources <- paste(unique(group_records$source), collapse = ", ")
  merged$n_sources <- nrow(group_records)
  merged$is_multi_source <- nrow(group_records) > 1
  merged$duplicate_ids <- paste(group_records$id, collapse = "; ")

  # Use centroid of all locations as final location
  merged$geometry <- sf::st_centroid(sf::st_union(group_records$geometry))

  return(merged)
}
```

---

## Interactive Map Implementation

**File:** `R/map_statues.R`

```r
#' Create Interactive Map of Statues with Popup Information
#'
#' @description
#' Creates an interactive Leaflet map showing statue locations with
#' rich popup information that appears on hover or click.
#'
#' @param statue_data A tibble of statue data (standardized format)
#' @param popup_fields Vector of column names to include in popup
#' @param color_by Column name to use for color coding (default: "source")
#' @param cluster Whether to use marker clustering (default: TRUE)
#' @param tiles Map tile provider (default: "OpenStreetMap")
#'
#' @return A leaflet map object
#'
#' @examples
#' \dontrun{
#' # Get and combine data
#' all_statues <- get_all_statue_data()
#'
#' # Create interactive map
#' map <- map_statues(all_statues)
#' map  # Display in viewer/browser
#'
#' # Customize popup fields
#' map2 <- map_statues(
#'   all_statues,
#'   popup_fields = c("name", "subject", "year_installed", "material"),
#'   color_by = "type"
#' )
#'
#' # Save to HTML
#' htmlwidgets::saveWidget(map2, "london_statues_map.html")
#' }
#'
#' @export
map_statues <- function(statue_data,
                        popup_fields = c("name", "subject", "year_installed",
                                          "material", "sculptor", "source_url"),
                        color_by = "source",
                        cluster = TRUE,
                        tiles = "OpenStreetMap") {

  # Remove records without coordinates
  mapped_data <- statue_data %>%
    dplyr::filter(!is.na(lat), !is.na(lon))

  message("Mapping ", nrow(mapped_data), " statues with coordinates")

  # Create color palette
  if (color_by %in% names(mapped_data)) {
    unique_values <- unique(mapped_data[[color_by]])
    colors <- leaflet::colorFactor(
      palette = "Set1",
      domain = unique_values
    )
    marker_color <- colors(mapped_data[[color_by]])
  } else {
    marker_color <- "blue"
  }

  # Create popups
  popups <- create_statue_popups(mapped_data, popup_fields)

  # Initialize map
  map <- leaflet::leaflet(mapped_data) %>%
    leaflet::addProviderTiles(tiles)

  # Add markers
  if (cluster) {
    map <- map %>%
      leaflet::addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        radius = 6,
        color = marker_color,
        fillOpacity = 0.7,
        popup = popups,
        label = ~name,
        clusterOptions = leaflet::markerClusterOptions()
      )
  } else {
    map <- map %>%
      leaflet::addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        radius = 6,
        color = marker_color,
        fillOpacity = 0.7,
        popup = popups,
        label = ~name
      )
  }

  # Add legend if coloring by a variable
  if (color_by %in% names(mapped_data) && is.factor(mapped_data[[color_by]])) {
    map <- map %>%
      leaflet::addLegend(
        position = "bottomright",
        pal = colors,
        values = mapped_data[[color_by]],
        title = tools::toTitleCase(gsub("_", " ", color_by))
      )
  }

  return(map)
}

# Helper function: Create HTML popups
create_statue_popups <- function(data, fields) {
  popups <- apply(data, 1, function(row) {
    popup_html <- "<div style='max-width: 300px;'>"

    # Title
    if (!is.na(row["name"]) && row["name"] != "") {
      popup_html <- paste0(
        popup_html,
        "<h4 style='margin-bottom: 5px;'>", row["name"], "</h4>"
      )
    }

    # Fields
    for (field in fields) {
      if (field %in% names(row) && !is.na(row[field]) && row[field] != "") {
        label <- tools::toTitleCase(gsub("_", " ", field))

        # Special handling for URLs
        if (grepl("url$", field, ignore.case = TRUE)) {
          value <- sprintf("<a href='%s' target='_blank'>View Source</a>",
                           row[field])
        } else {
          value <- row[field]
        }

        popup_html <- paste0(
          popup_html,
          "<p style='margin: 3px 0;'><strong>", label, ":</strong> ",
          value, "</p>"
        )
      }
    }

    # Add image if available
    if ("image_url" %in% names(row) && !is.na(row["image_url"]) && row["image_url"] != "") {
      popup_html <- paste0(
        popup_html,
        "<img src='", row["image_url"], "' ",
        "style='width: 100%; max-height: 200px; object-fit: cover; margin-top: 5px;'>"
      )
    }

    popup_html <- paste0(popup_html, "</div>")
    return(popup_html)
  })

  return(popups)
}
```

---

## Analysis Functions

**File:** `R/analyze_statues.R`

```r
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

  # Attempt to classify gender from subject names
  classified <- statue_data %>%
    dplyr::mutate(
      inferred_gender = classify_gender(subject, gender_mapping)
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
classify_gender <- function(subjects, gender_mapping = NULL) {
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
```

---

## Vignette Integration

**File:** `vignettes/memorial-analysis.Rmd` (updated sections)

```rmd
## Real Data from Multiple Sources

This analysis uses real data retrieved from multiple authoritative sources:

- **Wikidata**: Structured linked open data with rich metadata
- **OpenStreetMap**: Community-contributed geographic data
- **Greater London HER**: Professional heritage records
- **Historic England**: Listed monuments and heritage assets

### Data Retrieval

```{r get-data, cache=TRUE}
library(londonremembers)
library(dplyr)
library(ggplot2)
library(leaflet)

# Retrieve data from all sources
wikidata_raw <- get_statues_wikidata(
  location = "Q84",  # London
  cache_path = "data-raw/wikidata_cache.rds"
)

osm_raw <- get_statues_osm(
  cache_path = "data-raw/osm_cache.rds"
)

glher_raw <- get_statues_glher(
  cache_path = "data-raw/glher_cache.rds"
)

# Standardize all sources
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
osm_std <- standardize_statue_data(osm_raw, "osm")
glher_std <- standardize_statue_data(glher_raw, "glher")

# Combine and deduplicate
all_statues <- combine_statue_sources(
  list(
    wikidata = wikidata_std,
    osm = osm_std,
    glher = glher_std
  )
)

# Summary
message("Total unique statues identified: ", nrow(all_statues))
message("With coordinates: ", sum(!is.na(all_statues$lat)))
message("Multi-source records: ", sum(all_statues$is_multi_source, na.rm = TRUE))
```

### Data Quality Comparison

```{r data-quality}
# Compare coverage across sources
source_comparison <- all_statues %>%
  group_by(source) %>%
  summarize(
    n_records = n(),
    with_names = sum(!is.na(name)),
    with_subjects = sum(!is.na(subject)),
    with_dates = sum(!is.na(year_installed)),
    with_materials = sum(!is.na(material)),
    with_images = sum(!is.na(image_url))
  )

knitr::kable(source_comparison,
             caption = "Data Quality Comparison Across Sources")
```

### Interactive Map

```{r interactive-map, fig.height=8, fig.width=10}
# Create interactive map
statue_map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material",
                   "sculptor", "source_url"),
  color_by = "source",
  cluster = TRUE
)

statue_map
```

**Map Features:**
- Click markers to see detailed information
- Hover to see statue names
- Zoom and pan to explore different areas
- Markers are clustered for better performance
- Colors indicate data source

### Gender Analysis

```{r gender-analysis}
# Analyze by gender
gender_results <- analyze_by_gender(all_statues)

# Summary table
knitr::kable(gender_results$summary,
             caption = "Gender Representation in London Statues")

# Visualization
ggplot(gender_results$summary, aes(x = inferred_gender, y = n, fill = inferred_gender)) +
  geom_col() +
  geom_text(aes(label = sprintf("%d (%.1f%%)", n, percent)),
            vjust = -0.5) +
  labs(
    title = "Gender Representation in London Statues",
    x = "Gender",
    y = "Number of Statues",
    caption = sprintf("Total: %d statues from %s",
                     nrow(all_statues),
                     format(Sys.Date(), "%Y-%m-%d"))
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

### Validation of "Statues for Equality" Claims

```{r johns-vs-women}
# Compare Johns vs Women
comparison <- compare_johns_vs_women(all_statues)

cat(comparison$message, "\n\n")
cat("Claim validated:", comparison$claim_validated, "\n")
```

**Analysis:**

The "Statues for Equality" campaign claims that:
> "more statues named John dotted around the country than of women"

Our analysis of real data from London shows:
- **John statues:** `r comparison$john_statues` (`r comparison$john_percent`%)
- **Women statues:** `r comparison$woman_statues` (`r comparison$woman_percent`%)
- **Claim validated:** `r comparison$claim_validated`

### Methodology Transparency

Unlike the Statues for Equality website, this analysis provides:

1. **Source Attribution:** All data sources clearly identified
2. **Reproducible Code:** Complete R code provided
3. **Data Quality Metrics:** Coverage and completeness documented
4. **Geographic Verification:** Coordinates validated across sources
5. **Deduplication:** Spatial matching documented
6. **Classification Methods:** Gender inference methods explained

### Data Limitations

- **Coverage:** Data sources may not include all statues
- **Gender Classification:** Simple heuristic; manual review recommended
- **Subject Identification:** Some statues lack subject metadata
- **Geographic Scope:** London-focused; UK-wide data requires expansion
```

---

## File Structure

```
londonremembers/
├── R/
│   ├── get_statues_wikidata.R           # Wikidata SPARQL queries
│   ├── get_statues_osm.R                # OSM Overpass API
│   ├── get_statues_glher.R              # GLHER CSV download
│   ├── get_statues_historic_england.R   # Historic England data
│   ├── standardize_statue_data.R        # Data standardization
│   ├── combine_statue_sources.R         # Merging & deduplication
│   ├── map_statues.R                    # Interactive leaflet maps
│   ├── analyze_statues.R                # Analysis functions
│   └── utils.R                          # Helper functions
├── R/setup/
│   ├── test_wikidata.R                  # Test Wikidata queries
│   ├── test_osm.R                       # Test OSM queries
│   ├── test_glher.R                     # Test GLHER downloads
│   ├── data_sources_research.md         # Research document
│   └── implementation_plan.md           # This document
├── data-raw/
│   ├── wikidata_cache.rds               # Cached Wikidata results
│   ├── osm_cache.rds                    # Cached OSM results
│   ├── glher_cache.rds                  # Cached GLHER results
│   └── combined_statues.rds             # Final combined dataset
├── vignettes/
│   └── memorial-analysis.Rmd            # Updated vignette with real data
├── inst/
│   └── example_maps/
│       └── london_statues.html          # Example saved map
├── DESCRIPTION                           # Updated with new dependencies
└── default.R / default.nix              # Nix environment with new packages
```

---

## Usage Examples

### Basic: Get Data from One Source

```r
library(londonremembers)

# Get Wikidata statues
statues <- get_statues_wikidata(location = "Q84")  # Q84 = London
head(statues)
```

### Intermediate: Combine Multiple Sources

```r
# Get from multiple sources
wd <- get_statues_wikidata() %>% standardize_statue_data("wikidata")
osm <- get_statues_osm() %>% standardize_statue_data("osm")

# Combine
all_statues <- combine_statue_sources(list(wikidata = wd, osm = osm))

# How many statues?
nrow(all_statues)

# How many from multiple sources?
sum(all_statues$is_multi_source)
```

### Advanced: Full Pipeline with Analysis and Mapping

```r
library(londonremembers)
library(dplyr)
library(ggplot2)

# 1. Retrieve from all sources (with caching)
wikidata_raw <- get_statues_wikidata(
  cache_path = "data-raw/wikidata_cache.rds"
)

osm_raw <- get_statues_osm(
  cache_path = "data-raw/osm_cache.rds"
)

glher_raw <- get_statues_glher(
  cache_path = "data-raw/glher_cache.rds"
)

# 2. Standardize
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
osm_std <- standardize_statue_data(osm_raw, "osm")
glher_std <- standardize_statue_data(glher_raw, "glher")

# 3. Combine with deduplication
all_statues <- combine_statue_sources(
  list(wikidata = wikidata_std, osm = osm_std, glher = glher_std),
  distance_threshold = 50  # 50 meters
)

# 4. Analyze by gender
gender_analysis <- analyze_by_gender(all_statues)
print(gender_analysis$summary)

# 5. Compare Johns vs Women
comparison <- compare_johns_vs_women(all_statues)
print(comparison$message)

# 6. Create interactive map
map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "source",
  cluster = TRUE
)

# 7. Display map
map

# 8. Save map to HTML
htmlwidgets::saveWidget(map, "london_statues_map.html")

# 9. Save combined dataset
saveRDS(all_statues, "data-raw/combined_statues.rds")
```

### Vignette Usage

```r
# Build vignette with real data
devtools::build_vignettes()

# View vignette
vignette("memorial-analysis", package = "londonremembers")
```

---

## Performance Considerations

### Caching Strategy

All data retrieval functions support caching via `cache_path` parameter:

```r
# First call: retrieves from API (slow)
data <- get_statues_wikidata(cache_path = "cache/wikidata.rds")

# Subsequent calls: loads from cache (fast)
data <- get_statues_wikidata(cache_path = "cache/wikidata.rds")
```

### Rate Limiting

- **Wikidata SPARQL:** No strict limits, but be considerate
- **OSM Overpass:** 2-second delay between queries (implemented)
- **GLHER:** Unknown limits - implement conservative delays

### Large Dataset Handling

For London-wide or UK-wide data:

- Use spatial indexing with `sf` package
- Implement chunked processing for deduplication
- Consider using `data.table` for large merges
- Cache intermediate results

### Targets Pipeline Integration

```r
# _targets.R
library(targets)
library(tarchetypes)

tar_plan(
  # Data retrieval
  tar_target(wikidata_raw, get_statues_wikidata(cache_path = "cache/wd.rds")),
  tar_target(osm_raw, get_statues_osm(cache_path = "cache/osm.rds")),
  tar_target(glher_raw, get_statues_glher(cache_path = "cache/glher.rds")),

  # Standardization
  tar_target(wikidata_std, standardize_statue_data(wikidata_raw, "wikidata")),
  tar_target(osm_std, standardize_statue_data(osm_raw, "osm")),
  tar_target(glher_std, standardize_statue_data(glher_raw, "glher")),

  # Combination
  tar_target(
    all_statues,
    combine_statue_sources(list(
      wikidata = wikidata_std,
      osm = osm_std,
      glher = glher_std
    ))
  ),

  # Analysis
  tar_target(gender_analysis, analyze_by_gender(all_statues)),
  tar_target(johns_comparison, compare_johns_vs_women(all_statues)),

  # Visualization
  tar_target(statue_map, map_statues(all_statues))
)
```

---

## Testing Strategy

### Unit Tests

```r
# tests/testthat/test-get-statues-wikidata.R
test_that("get_statues_wikidata returns valid data", {
  # Mock or use small test query
  data <- get_statues_wikidata(location = "Q84", limit = 10)

  expect_s3_class(data, "tbl_df")
  expect_true("lat" %in% names(data))
  expect_true("lon" %in% names(data))
  expect_true(all(!is.na(data$lat)))
  expect_true(all(!is.na(data$lon)))
})

# tests/testthat/test-standardize.R
test_that("standardize_statue_data creates correct schema", {
  mock_data <- tibble::tibble(
    wikidata_id = "Q12345",
    name = "Test Statue",
    lat = 51.5,
    lon = -0.1
  )

  std <- standardize_statue_data(mock_data, "wikidata")

  expect_true("id" %in% names(std))
  expect_true("source" %in% names(std))
  expect_equal(nrow(std), 1)
})
```

### Integration Tests

```r
# tests/testthat/test-full-pipeline.R
test_that("full pipeline works end-to-end", {
  skip_on_cran()
  skip_if_offline()

  # Small test area
  bbox <- c(-0.15, 51.5, -0.1, 51.52)

  # Get data
  osm <- get_statues_osm(bbox = bbox)
  std <- standardize_statue_data(osm, "osm")

  # Should have some results
  expect_gt(nrow(std), 0)

  # Should have coordinates
  expect_true(all(!is.na(std$lat)))
  expect_true(all(!is.na(std$lon)))
})
```

---

## Documentation Requirements

Each function requires:

1. **Roxygen2 comments** with:
   - `@description`
   - `@param` for each parameter
   - `@return` describing return value
   - `@examples` with working code
   - `@export` for user-facing functions

2. **Vignette coverage** showing:
   - Basic usage
   - Common workflows
   - Interpretation of results

3. **README** with:
   - Installation instructions
   - Quick start guide
   - Link to full vignette

---

## Next Steps After Implementation

1. **Data validation:** Manually verify sample of records
2. **Gender classification:** Improve with manual mapping file
3. **UK-wide expansion:** Extend beyond London
4. **Additional sources:** Investigate more data sources
5. **API rate limits:** Document and implement proper throttling
6. **Shiny app:** Interactive web application for exploration
7. **Publication:** Document methodology in academic paper
8. **Data release:** Publish combined dataset with DOI

---

## Conclusion

This implementation provides a **robust, transparent, and reproducible** approach to statue data analysis that:

✅ Replaces blocked web scraping with legitimate APIs
✅ Combines multiple authoritative sources
✅ Provides geographic visualization with interactive maps
✅ Enables rigorous validation of public claims
✅ Documents methodology transparently
✅ Supports reproducible research through caching and `targets`
✅ Creates reusable R package functions

The interactive map with hover popups will allow users to explore each statue in detail, seeing its name, subject, date, materials, and links to source data - far exceeding the functionality of the original scraping approach.
