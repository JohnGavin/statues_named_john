devtools::load_all()
library(dplyr)
library(arrow)

message("--- Testing fetch_wikidata_statues ---")
wikidata_data <- fetch_wikidata_statues()

if (!is.null(wikidata_data) && nrow(wikidata_data) > 0) {
  message(paste("Dimensions of Wikidata data:", nrow(wikidata_data), "rows,", ncol(wikidata_data), "columns"))
  print(head(wikidata_data))
  
  # Save as Parquet
  arrow::write_parquet(wikidata_data, "R/setup/wikidata_raw_sample.parquet")
  message("Saved R/setup/wikidata_raw_sample.parquet")
} else {
  message("Wikidata data fetching failed or returned no results.")
}

message("\n--- Testing fetch_osm_statues ---")
osm_data <- fetch_osm_statues()

if (!is.null(osm_data) && nrow(osm_data) > 0) {
  message(paste("Dimensions of OSM data:", nrow(osm_data), "rows,", ncol(osm_data), "columns"))
  print(head(osm_data))
  
  # Save as Parquet
  arrow::write_parquet(osm_data, "R/setup/osm_raw_sample.parquet")
  message("Saved R/setup/osm_raw_sample.parquet")
} else {
  message("OSM data fetching failed or returned no results.")
}

message("\n--- Data source tests complete ---")
