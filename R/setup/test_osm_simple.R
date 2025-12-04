#!/usr/bin/env Rscript
# Test OpenStreetMap Overpass API using httr2 + xml2 (available in nix)

library(httr2)
library(xml2)
library(jsonlite)

message("=== Testing OpenStreetMap Overpass API with Generic HTTP Packages ===")
message("Date: ", Sys.Date())

# Overpass API endpoint
endpoint <- "https://overpass-api.de/api/interpreter"

# London bounding box: [south, west, north, east]
bbox <- "51.28676,-0.510375,51.691874,0.334015"

# Overpass QL query for statues in London
# Using JSON output format for easier parsing
overpass_query <- paste0('
[out:json][timeout:25];
(
  // Query 1: memorial=statue
  node["memorial"="statue"](', bbox, ');
  way["memorial"="statue"](', bbox, ');

  // Query 2: historic=memorial
  node["historic"="memorial"](', bbox, ');
  way["historic"="memorial"](', bbox, ');

  // Query 3: man_made=statue
  node["man_made"="statue"](', bbox, ');
  way["man_made"="statue"](', bbox, ');
);
out center;
')

message("\n--- Executing Overpass Query ---")
message("Querying OpenStreetMap for London statues...")
message("Bbox: ", bbox)

# Make HTTP request
tryCatch({
  response <- request(endpoint) %>%
    req_body_form(data = overpass_query) %>%
    req_user_agent("LondonRemembersR/1.0 (https://github.com/user/statuesnamedjohn)") %>%
    req_timeout(60) %>%
    req_perform()

  # Parse JSON response
  data <- response %>%
    resp_body_string() %>%
    fromJSON()

  # Extract elements
  if (!is.null(data$elements) && nrow(data$elements) > 0) {
    results <- data$elements

    message("\n✓ Query successful!")
    message("  Retrieved ", nrow(results), " features")

    # Extract coordinates
    # For nodes: use lat/lon directly
    # For ways: use center.lat/center.lon (if center exists)
    results$latitude <- results$lat
    results$longitude <- results$lon

    # Handle ways with center coordinates
    has_center <- !is.na(results$type) & results$type == "way"
    if (sum(has_center) > 0 && "center" %in% names(results)) {
      for (i in which(has_center)) {
        if (!is.null(results$center[[i]]) && is.list(results$center[[i]])) {
          if ("lat" %in% names(results$center[[i]])) {
            results$latitude[i] <- results$center[[i]]$lat
          }
          if ("lon" %in% names(results$center[[i]])) {
            results$longitude[i] <- results$center[[i]]$lon
          }
        }
      }
    }

    # Extract common tags
    extract_tag <- function(tags, key) {
      sapply(tags, function(t) {
        if (is.null(t) || !is.list(t)) return(NA_character_)
        if (key %in% names(t)) t[[key]] else NA_character_
      })
    }

    results$name <- extract_tag(results$tags, "name")
    results$memorial_type <- extract_tag(results$tags, "memorial")
    results$historic <- extract_tag(results$tags, "historic")
    results$man_made <- extract_tag(results$tags, "man_made")
    results$subject <- extract_tag(results$tags, "subject:wikidata")
    results$wikipedia <- extract_tag(results$tags, "wikipedia")
    results$wikidata <- extract_tag(results$tags, "wikidata")
    results$material <- extract_tag(results$tags, "material")
    results$artist <- extract_tag(results$tags, "artist_name")
    results$start_date <- extract_tag(results$tags, "start_date")

    # Summary statistics
    message("\n--- Summary Statistics ---")
    message("  Total features: ", nrow(results))
    message("  With names: ", sum(!is.na(results$name)))
    message("  With coordinates: ", sum(!is.na(results$latitude)))
    message("  Nodes: ", sum(results$type == "node"))
    message("  Ways: ", sum(results$type == "way"))
    message("\nBy tag type:")
    message("  memorial=statue: ", sum(!is.na(results$memorial_type)))
    message("  historic=memorial: ", sum(!is.na(results$historic)))
    message("  man_made=statue: ", sum(!is.na(results$man_made)))
    message("\nMetadata:")
    message("  With Wikipedia: ", sum(!is.na(results$wikipedia)))
    message("  With Wikidata: ", sum(!is.na(results$wikidata)))
    message("  With material: ", sum(!is.na(results$material)))
    message("  With artist: ", sum(!is.na(results$artist)))
    message("  With dates: ", sum(!is.na(results$start_date)))

    # Save results
    saveRDS(results, "R/setup/osm_london_statues_simple.rds")
    message("\n✓ Results saved to R/setup/osm_london_statues_simple.rds")

    # Show sample
    message("\n--- Sample Records (first 5 with names) ---")
    named <- results[!is.na(results$name), ]
    if (nrow(named) > 0) {
      sample_df <- data.frame(
        name = named$name[1:min(5, nrow(named))],
        type = named$type[1:min(5, nrow(named))],
        lat = round(named$latitude[1:min(5, nrow(named))], 5),
        lon = round(named$longitude[1:min(5, nrow(named))], 5),
        stringsAsFactors = FALSE
      )
      print(sample_df)
    } else {
      message("  No named features found")
    }

  } else {
    message("✗ Query returned no results")
    message("  Response structure: ", str(data))
  }

}, error = function(e) {
  message("✗ Error: ", e$message)
  quit(status = 1)
})

message("\n=== Test Complete ===")
