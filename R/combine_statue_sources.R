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
