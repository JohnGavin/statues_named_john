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
                               list(key = "memorial", value = "animal"),
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
      osm_type = "node", # osm_points are nodes
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