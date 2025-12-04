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
       ?materialLabel ?creatorLabel ?image ?article ?nhle
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
      subject_gender = genderLabel,
      lat = lat,
      lon = lon,
      inception_date = inceptionDate,
      material = materialLabel,
      creator = creatorLabel,
      image_url = image,
      wikipedia_url = article,
      nhle_id = nhle,
      source = "wikidata"
    )

  # Cache if requested
  if (!is.null(cache_path)) {
    saveRDS(statues_wikidata, cache_path)
    message("Cached results to ", cache_path)
  }

  return(statues_wikidata)
}
