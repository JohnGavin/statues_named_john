#' Retrieve Statue Data from OpenStreetMap
#'
#' @description
#' Queries OpenStreetMap Overpass API for statues and memorials
#' using multiple OSM tags to maximize coverage.
#'
#' Fails fast (#90): any query that cannot be completed aborts the whole
#' call immediately, rather than being downgraded to a warning and
#' returning partial data. Each request is bounded (see
#' \code{osm_fetch_features()}), so a network outage surfaces in seconds,
#' not after osmdata's internal ten-try retry loop.
#'
#' @param bbox Bounding box (min_lon, min_lat, max_lon, max_lat).
#'   Default is Greater London.
#' @param tags OSM tags to query. Default includes memorial=statue,
#'   historic=memorial, man_made=statue
#' @param cache_path Path to cache results (default: NULL)
#' @param pause Seconds to wait between queries, to be polite to the
#'   Overpass API (default: 2)
#'
#' @return A tibble with columns: osm_id, osm_type, name, subject, lat, lon,
#'   memorial_type, historic_type, man_made_type, material, wikipedia, source
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
                             cache_path = NULL,
                             pause = 2) {

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
    tag_label <- paste0(tag$key, "=", tag$value)
    message(sprintf("  Query %d/%d: %s", i, length(tags), tag_label))

    q <- osmdata::opq(bbox = bbox) %>%
      osmdata::add_osm_feature(key = tag$key, value = tag$value)

    # A failed query aborts immediately: continuing would either return
    # partial data (a biased headline) or waste time on later queries.
    query <- tryCatch(
      osm_fetch_features(q),
      error = function(e) {
        cli::cli_abort(
          c(
            "OSM query {i}/{length(tags)} ({tag_label}) failed; aborting without partial data.",
            "x" = conditionMessage(e)
          ),
          call = NULL
        )
      }
    )

    # "No features" is a legitimate empty result for a tag, not a failure
    if (!is.null(query$osm_points) && nrow(query$osm_points) > 0) {
      all_results[[paste0(tag$key, "_", tag$value)]] <- query$osm_points
      message(sprintf("    Found %d features", nrow(query$osm_points)))
    } else {
      message("    No features found")
    }

    # Be nice to Overpass API - rate limit
    if (i < length(tags) && pause > 0) Sys.sleep(pause)
  }

  if (length(all_results) == 0) {
    cli::cli_abort(
      "No OSM features returned for any tag in the bounding box; refusing to return an empty dataset.",
      call = NULL
    )
  }

  # Optional tag columns are only present when some feature carries that tag;
  # add any that are missing so the reshape works on any subset of results.
  optional_cols <- c("name", "subject", "memorial", "historic", "man_made",
                     "material", "wikipedia")
  all_results <- lapply(all_results, function(pts) {
    for (col in setdiff(optional_cols, names(pts))) pts[[col]] <- NA_character_
    pts[, c("osm_id", optional_cols)]
  })

  # Combine all results
  combined <- dplyr::bind_rows(all_results, .id = "query_tag")

  # Extract coordinates from sf geometry
  coords <- sf::st_coordinates(combined)

  # Standardize to tibble
  statues_osm <- combined %>%
    sf::st_drop_geometry() %>%
    tibble::as_tibble() %>%
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

#' Run one Overpass query with a bounded time budget
#'
#' @description
#' Replaces \code{osmdata::osmdata_sf(q)}'s own request, which retries up to
#' ten times with growing back-off and sleeps on rate limits, so a dead
#' network could stall a pipeline for tens of minutes (#90). Here:
#' \itemize{
#'   \item each attempt times out after \code{timeout_s} seconds;
#'   \item only HTTP 429/5xx responses are retried, at most \code{max_tries}
#'     attempts with a capped back-off;
#'   \item connection/DNS failures and timeouts are not retried at all;
#'   \item an HTTP 200 whose body carries an Overpass runtime-error remark
#'     is treated as a failure.
#' }
#'
#' @param q An \code{overpass_query} from \code{osmdata::opq()}.
#' @param timeout_s Per-attempt timeout in seconds.
#' @param max_tries Maximum attempts for retryable HTTP statuses.
#' @param backoff_base Seconds before the first retry; doubles per retry,
#'   capped at 30.
#'
#' @return The \code{osmdata} object from \code{osmdata::osmdata_sf()}.
#' @noRd
osm_fetch_features <- function(q, timeout_s = 90, max_tries = 3, backoff_base = 5) {
  xml_path <- tempfile(fileext = ".osm")
  on.exit(unlink(xml_path), add = TRUE)

  url <- osmdata::get_overpass_url()
  body <- osmdata::opq_string(q)

  # Explicit loop rather than httr::RETRY(): RETRY (httr 1.4.7) also retries
  # request errors, so a DNS/connection failure cost ~25s of pointless
  # retries. Here a request error (DNS, refused connection, timeout) fails
  # on the first attempt; only HTTP 429/5xx are retried.
  for (attempt in seq_len(max_tries)) {
    resp <- httr::POST(
      url,
      body = body,
      httr::timeout(timeout_s),
      httr::write_disk(xml_path, overwrite = TRUE),
      httr::user_agent(
        "statuesnamedjohn R package (https://github.com/JohnGavin/statues_named_john)"
      )
    )
    status <- httr::status_code(resp)
    retryable <- status == 429L || status >= 500L
    if (!retryable || attempt == max_tries) break
    wait <- min(backoff_base * 2^(attempt - 1), 30)
    message(sprintf("    Overpass HTTP %d; retry %d/%d in %ds",
                    status, attempt, max_tries - 1, wait))
    Sys.sleep(wait)
  }
  httr::stop_for_status(resp, task = "query the Overpass API")
  check_overpass_remark(xml_path)

  osmdata::osmdata_sf(q, doc = xml_path, quiet = TRUE)
}

#' Fail on an Overpass response that reports a server-side error
#'
#' Overpass can return HTTP 200 with a \code{<remark>} saying the query
#' timed out or ran out of memory; the result is then silently truncated.
#'
#' @param xml_path Path to the downloaded Overpass XML.
#' @return \code{NULL}, invisibly, when no error remark is present.
#' @noRd
check_overpass_remark <- function(xml_path) {
  lines <- readLines(xml_path, warn = FALSE)
  remark <- grep("<remark>.*(runtime error|timed out|out of memory)", lines,
                 value = TRUE, ignore.case = TRUE)
  if (length(remark) > 0) {
    cli::cli_abort(
      c("Overpass returned a truncated result.",
        "x" = trimws(gsub("</?remark>", "", remark[1]))),
      call = NULL
    )
  }
  invisible(NULL)
}
