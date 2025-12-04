#!/usr/bin/env Rscript
# Test Wikidata SPARQL using httr2 + jsonlite (available in nix)

library(httr2)
library(jsonlite)
library(dplyr)

message("=== Testing Wikidata SPARQL with Generic HTTP Packages ===")
message("Date: ", Sys.Date())

# Wikidata SPARQL endpoint
endpoint <- "https://query.wikidata.org/sparql"

# SPARQL query for London statues
sparql_query <- '
SELECT ?statue ?statueLabel ?coords ?subjectLabel ?inceptionDate
       ?materialLabel ?creatorLabel ?image ?article
WHERE {
  ?statue wdt:P31 wd:Q179700.  # Instance of statue
  ?statue wdt:P131+ wd:Q84.     # Located in London
  ?statue wdt:P625 ?coords.     # Has coordinates
  OPTIONAL { ?statue wdt:P180 ?subject }
  OPTIONAL { ?statue wdt:P571 ?inceptionDate }
  OPTIONAL { ?statue wdt:P186 ?material }
  OPTIONAL { ?statue wdt:P170 ?creator }
  OPTIONAL { ?statue wdt:P18 ?image }
  OPTIONAL {
    ?article schema:about ?statue .
    ?article schema:inLanguage "en" .
    ?article schema:isPartOf <https://en.wikipedia.org/> .
  }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
LIMIT 50'

message("\n--- Executing SPARQL Query ---")
message("Querying Wikidata for London statues...")

# Make HTTP request
tryCatch({
  response <- request(endpoint) %>%
    req_url_query(query = sparql_query, format = "json") %>%
    req_user_agent("LondonRemembersR/1.0 (https://github.com/user/statuesnamedjohn)") %>%
    req_perform()

  # Parse JSON response
  data <- response %>%
    resp_body_string() %>%
    fromJSON()

  # Extract bindings
  if (!is.null(data$results$bindings) && nrow(data$results$bindings) > 0) {
    results <- data$results$bindings

    message("\n✓ Query successful!")
    message("  Retrieved ", nrow(results), " statue records")

    # Extract coordinates
    if ("coords" %in% names(results) && !is.null(results$coords$value)) {
      # Parse "Point(lon lat)" format
      coords_parse <- function(point_str) {
        if (is.null(point_str) || point_str == "") return(c(NA, NA))
        coords <- gsub("Point\\(|\\)", "", point_str)
        as.numeric(strsplit(coords, " ")[[1]])
      }

      coords_list <- lapply(results$coords$value, coords_parse)
      results$lon <- sapply(coords_list, function(x) x[1])
      results$lat <- sapply(coords_list, function(x) x[2])
    }

    # Summary statistics
    message("\n--- Summary Statistics ---")
    message("  Total statues: ", nrow(results))
    message("  With subjects: ", sum(!is.na(results$subject$value)))
    message("  With dates: ", sum(!is.na(results$inceptionDate$value)))
    message("  With materials: ", sum(!is.na(results$material$value)))
    message("  With creators: ", sum(!is.na(results$creator$value)))
    message("  With images: ", sum(!is.na(results$image$value)))
    message("  With Wikipedia: ", sum(!is.na(results$article$value)))
    message("  With coordinates: ", sum(!is.na(results$lat)))

    # Save results
    saveRDS(results, "R/setup/wikidata_london_statues_simple.rds")
    message("\n✓ Results saved to R/setup/wikidata_london_statues_simple.rds")

    # Show sample
    message("\n--- Sample Records (first 3) ---")
    sample_df <- data.frame(
      name = results$statueLabel$value[1:min(3, nrow(results))],
      subject = results$subjectLabel$value[1:min(3, nrow(results))],
      lat = results$lat[1:min(3, nrow(results))],
      lon = results$lon[1:min(3, nrow(results))]
    )
    print(sample_df)

  } else {
    message("✗ Query returned no results")
  }

}, error = function(e) {
  message("✗ Error: ", e$message)
  quit(status = 1)
})

message("\n=== Test Complete ===")
