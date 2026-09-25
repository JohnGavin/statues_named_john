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

  # Download CSV. Any failure is an error with its reason, never a silent
  # empty tibble; get_statues_glher() callers that treat GLHER as optional
  # wrap it in fetch_optional_source() (#94).
  response <- httr::GET(base_url, query = params, httr::timeout(60))

  status <- httr::status_code(response)
  if (status != 200) {
    cli::cli_abort("GLHER request failed with HTTP {status}.", call = NULL)
  }

  content_text <- httr::content(response, as = "text", encoding = "UTF-8")

  # /search serves the GLHER search web page, not a CSV export. The real
  # export endpoint (/search/export_results) returns HTTP 403 without an
  # account that has export permission. See #94.
  if (startsWith(trimws(content_text), "<")) {
    cli::cli_abort(
      c("GLHER returned its search web page, not CSV.",
        "i" = "/search is not an export endpoint; /search/export_results needs an account with export permission (#94)."),
      call = NULL
    )
  }

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
}
