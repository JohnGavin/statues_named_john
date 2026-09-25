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
  sparql_query <- sprintf(
'SELECT ?statue ?statueLabel ?coords ?subjectLabel ?genderLabel ?inceptionDate
       ?materialLabel ?creatorLabel ?image ?article ?nhle ?height ?dedicatedToLabel
WHERE {
  # Instance of statue, sculpture, or memorial
  VALUES ?type { wd:Q179700 wd:Q860861 wd:Q5020292 }
  ?statue wdt:P31 ?type.

  # Located in specified location (or any subdivision)
  ?statue wdt:P131+ wd:%s.

  # Must have coordinates
  ?statue wdt:P625 ?coords.

  # Optional fields
  OPTIONAL { 
    ?statue wdt:P180 ?subjectItem.
    OPTIONAL { ?subjectItem wdt:P21 ?gender. }
  }
  OPTIONAL { ?statue wdt:P571 ?inceptionDate }
  OPTIONAL { ?statue wdt:P186 ?material }
  OPTIONAL { ?statue wdt:P170 ?creator }
  OPTIONAL { ?statue wdt:P18 ?image }
  OPTIONAL { ?statue wdt:P1216 ?nhle }
  OPTIONAL { ?statue wdt:P2048 ?height } # P2048: Height
  OPTIONAL { ?statue wdt:P825 ?dedicatedTo } # P825: Dedicated to

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
  results <- query_wikidata_sparql(sparql_query)

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
      subject_gender = genderLabel,
      lat = lat,
      lon = lon,
      inception_date = inceptionDate,
      material = materialLabel,
      creator = creatorLabel,
      image_url = image,
      wikipedia_url = article,
      nhle_id = nhle,
      height = as.numeric(height),
      dedicated_to = dedicatedToLabel,
      source = "wikidata"
    )

  # Cache if requested
  if (!is.null(cache_path)) {
    saveRDS(statues_wikidata, cache_path)
    message("Cached results to ", cache_path)
  }

  return(statues_wikidata)
}

#' Query the Wikidata SPARQL endpoint
#'
#' @description
#' Sends a SPARQL query to the public Wikidata Query Service and parses the
#' JSON response into a tibble. Replaces the archived
#' \code{WikidataQueryServiceR::query_wikidata()} (CRAN-archived 2026-02-08)
#' with a minimal \code{httr} + \code{jsonlite} implementation.
#'
#' @param sparql_query A SPARQL query string.
#'
#' @return A tibble, one character column per SPARQL result variable.
#'
#' @noRd
query_wikidata_sparql <- function(sparql_query) {
  response <- httr::GET(
    url = "https://query.wikidata.org/sparql",
    query = list(query = sparql_query),
    httr::add_headers(Accept = "application/sparql-results+json"),
    httr::timeout(60), # fail fast instead of hanging on a dead connection (#90)
    httr::user_agent(
      "statuesnamedjohn R package (https://github.com/JohnGavin/statues_named_john)"
    )
  )

  if (httr::status_code(response) != 200) {
    stop(
      "Wikidata SPARQL request failed with status ",
      httr::status_code(response)
    )
  }

  json_text <- httr::content(response, as = "text", encoding = "UTF-8")
  parse_sparql_json(json_text)
}

#' Parse a Wikidata SPARQL JSON response
#'
#' @description
#' Converts the JSON body returned by the Wikidata SPARQL endpoint (the
#' standard SPARQL 1.1 Query Results JSON Format) into a tibble with one
#' character column per variable named in \code{head$vars}, in that order.
#' A variable absent from a given binding (SPARQL's OPTIONAL semantics)
#' becomes \code{NA_character_} for that row; a variable absent from every
#' binding still produces a column of all-\code{NA} values. Zero bindings
#' produces a zero-row tibble with the expected columns.
#'
#' @param json_text A JSON string in SPARQL 1.1 Query Results JSON Format.
#'
#' @return A tibble.
#'
#' @noRd
parse_sparql_json <- function(json_text) {
  parsed <- jsonlite::fromJSON(json_text, simplifyVector = FALSE)

  vars <- unlist(parsed$head$vars)
  bindings <- parsed$results$bindings

  columns <- lapply(vars, function(var) {
    vapply(bindings, function(binding) {
      if (!is.null(binding[[var]]) && !is.null(binding[[var]]$value)) {
        as.character(binding[[var]]$value)
      } else {
        NA_character_
      }
    }, character(1))
  })
  names(columns) <- vars

  tibble::as_tibble(columns)
}
