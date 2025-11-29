#!/usr/bin/env Rscript
# Test Wikidata SPARQL queries for London statues
# Date: 2025-11-12

library(WikidataQueryServiceR)

message("=== Testing Wikidata SPARQL for London Statues ===")
message(sprintf("Date: %s", Sys.time()))

# SPARQL query for statues in London with coordinates
sparql_query <- '
SELECT ?statue ?statueLabel ?coords ?subjectLabel ?inceptionDate
       ?materialLabel ?creatorLabel ?image ?article
WHERE {
  # Instance of statue
  ?statue wdt:P31 wd:Q179700.

  # Located in London (or any administrative subdivision of London)
  ?statue wdt:P131+ wd:Q84.

  # Has coordinates
  ?statue wdt:P625 ?coords.

  # Optional: subject depicted (who/what the statue represents)
  OPTIONAL { ?statue wdt:P180 ?subject }

  # Optional: inception/installation date
  OPTIONAL { ?statue wdt:P571 ?inceptionDate }

  # Optional: material used
  OPTIONAL { ?statue wdt:P186 ?material }

  # Optional: creator/sculptor
  OPTIONAL { ?statue wdt:P170 ?creator }

  # Optional: image
  OPTIONAL { ?statue wdt:P18 ?image }

  # Optional: Wikipedia article
  OPTIONAL {
    ?article schema:about ?statue .
    ?article schema:inLanguage "en" .
    ?article schema:isPartOf <https://en.wikipedia.org/> .
  }

  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
LIMIT 100
'

message("\n--- Executing SPARQL Query ---")
message("Querying Wikidata for London statues...")

# Execute query
tryCatch({
  results <- query_wikidata(sparql_query)

  message(sprintf("\n✓ Query successful!"))
  message(sprintf("  Retrieved %d statue records", nrow(results)))

  # Show structure
  message("\n--- Data Structure ---")
  print(str(results))

  # Show first few records
  message("\n--- First 5 Records ---")
  print(head(results, 5))

  # Summary statistics
  message("\n--- Summary Statistics ---")
  message(sprintf("  Total statues: %d", nrow(results)))
  message(sprintf("  With subjects: %d", sum(!is.na(results$subject))))
  message(sprintf("  With dates: %d", sum(!is.na(results$inceptionDate))))
  message(sprintf("  With materials: %d", sum(!is.na(results$material))))
  message(sprintf("  With creators: %d", sum(!is.na(results$creator))))
  message(sprintf("  With images: %d", sum(!is.na(results$image))))
  message(sprintf("  With Wikipedia: %d", sum(!is.na(results$article))))

  # Parse coordinates (format: "Point(lon lat)")
  if ("coords" %in% names(results)) {
    message("\n--- Coordinate Parsing ---")
    coords_sample <- head(results$coords, 3)
    message("Sample coordinates:")
    print(coords_sample)
  }

  # Save results
  saveRDS(results, "R/setup/wikidata_london_statues.rds")
  message("\n✓ Results saved to R/setup/wikidata_london_statues.rds")

  # Write CSV
  write.csv(results, "R/setup/wikidata_london_statues.csv", row.names = FALSE)
  message("✓ Results saved to R/setup/wikidata_london_statues.csv")

}, error = function(e) {
  message(sprintf("\n✗ Error executing query: %s", e$message))
})

sessionInfo()
