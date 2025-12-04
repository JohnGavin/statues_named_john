#!/usr/bin/env Rscript
# Test OpenStreetMap Overpass API for London statues
# Date: 2025-11-12

library(osmdata)
library(dplyr)
library(sf)

message("=== Testing OpenStreetMap Overpass API for London Statues ===")
message(sprintf("Date: %s", Sys.time()))

# Define London bounding box
# Format: (min_lon, min_lat, max_lon, max_lat)
london_bbox <- c(-0.510375, 51.28676, 0.334015, 51.691874)

message("\n--- Query 1: Statues (memorial=statue) ---")

tryCatch({
  # Query for memorials that are statues
  q1 <- opq(bbox = london_bbox) %>%
    add_osm_feature(key = "memorial", value = "statue") %>%
    osmdata_sf()

  statues_sf <- q1$osm_points

  if (!is.null(statues_sf) && nrow(statues_sf) > 0) {
    message(sprintf("✓ Found %d statues with memorial=statue", nrow(statues_sf)))

    # Show available fields
    message("\n--- Available Fields ---")
    print(names(statues_sf))

    # Show first few records
    message("\n--- First 3 Records ---")
    print(head(statues_sf, 3))

    # Save results
    saveRDS(statues_sf, "R/setup/osm_statues_memorial.rds")
    message("\n✓ Saved to R/setup/osm_statues_memorial.rds")

  } else {
    message("✗ No statues found with memorial=statue")
  }

}, error = function(e) {
  message(sprintf("✗ Error in Query 1: %s", e$message))
})

message("\n--- Query 2: Historic Memorials ---")

tryCatch({
  # Query for historic memorials
  q2 <- opq(bbox = london_bbox) %>%
    add_osm_feature(key = "historic", value = "memorial") %>%
    osmdata_sf()

  memorials_sf <- q2$osm_points

  if (!is.null(memorials_sf) && nrow(memorials_sf) > 0) {
    message(sprintf("✓ Found %d historic memorials", nrow(memorials_sf)))

    # Save results
    saveRDS(memorials_sf, "R/setup/osm_historic_memorial.rds")
    message("✓ Saved to R/setup/osm_historic_memorial.rds")

  } else {
    message("✗ No historic memorials found")
  }

}, error = function(e) {
  message(sprintf("✗ Error in Query 2: %s", e$message))
})

message("\n--- Query 3: Man-made Statues ---")

tryCatch({
  # Query for man-made statues
  q3 <- opq(bbox = london_bbox) %>%
    add_osm_feature(key = "man_made", value = "statue") %>%
    osmdata_sf()

  manmade_sf <- q3$osm_points

  if (!is.null(manmade_sf) && nrow(manmade_sf) > 0) {
    message(sprintf("✓ Found %d man-made statues", nrow(manmade_sf)))

    # Save results
    saveRDS(manmade_sf, "R/setup/osm_manmade_statue.rds")
    message("✓ Saved to R/setup/osm_manmade_statue.rds")

  } else {
    message("✗ No man-made statues found")
  }

}, error = function(e) {
  message(sprintf("✗ Error in Query 3: %s", e$message))
})

message("\n--- Summary Statistics ---")

# Combine all results if they exist
all_features <- list()
if (exists("statues_sf") && !is.null(statues_sf)) all_features$memorial_statue <- statues_sf
if (exists("memorials_sf") && !is.null(memorials_sf)) all_features$historic_memorial <- memorials_sf
if (exists("manmade_sf") && !is.null(manmade_sf)) all_features$manmade_statue <- manmade_sf

if (length(all_features) > 0) {
  message(sprintf("Total datasets retrieved: %d", length(all_features)))
  for (name in names(all_features)) {
    df <- all_features[[name]]
    message(sprintf("  %s: %d features", name, nrow(df)))

    # Check for name/subject fields
    if ("name" %in% names(df)) {
      named_count <- sum(!is.na(df$name))
      message(sprintf("    - With names: %d", named_count))
    }
    if ("subject" %in% names(df)) {
      subject_count <- sum(!is.na(df$subject))
      message(sprintf("    - With subject: %d", subject_count))
    }
  }

  # Save combined dataset
  saveRDS(all_features, "R/setup/osm_all_statues.rds")
  message("\n✓ All results saved to R/setup/osm_all_statues.rds")

} else {
  message("✗ No OSM data retrieved")
}

sessionInfo()
