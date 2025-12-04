# R/setup/test_full_pipeline.R

message("=== Starting Full Pipeline Test ===")

# Load dependencies
# We load these explicitly to ensure they are available in the environment
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(leaflet)
  library(htmlwidgets)
  library(sf)
  library(readr)
  library(stringr)
  library(purrr)
})

message("✓ Dependencies loaded")

# Source functions manually to bypass package loading issues
message("Sourcing R functions...")
source("R/get_statues_wikidata.R")
source("R/get_statues_osm.R")
source("R/get_statues_glher.R")
source("R/standardize_statue_data.R")
source("R/combine_statue_sources.R")
source("R/map_statues.R")
source("R/analyze_statues.R")
message("✓ Functions sourced")

# Create cache directory
dir.create("data-raw", showWarnings = FALSE)

# 1. Get data
message("\n--- 1. Data Retrieval ---")

message("Getting Wikidata data (limit=50)...")
wikidata_raw <- tryCatch(
  get_statues_wikidata(limit = 50, cache_path = "data-raw/wikidata_cache.rds"),
  error = function(e) { warning("Wikidata failed: ", e$message); return(tibble::tibble()) }
)

message("Getting OSM data (small bbox)...")
# Small bbox for testing: Westminster area
test_bbox <- c(-0.15, 51.49, -0.12, 51.51)
osm_raw <- tryCatch(
  get_statues_osm(bbox = test_bbox, cache_path = "data-raw/osm_cache.rds"),
  error = function(e) { warning("OSM failed: ", e$message); return(tibble::tibble()) }
)

message("Getting GLHER data...")
glher_raw <- tryCatch(
  get_statues_glher(max_results = 20, cache_path = "data-raw/glher_cache.rds"),
  error = function(e) { warning("GLHER failed: ", e$message); return(tibble::tibble()) }
)

# 2. Standardize
message("\n--- 2. Standardization ---")
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
osm_std <- standardize_statue_data(osm_raw, "osm")
glher_std <- standardize_statue_data(glher_raw, "glher")

message(sprintf("Standardized counts: Wikidata=%d, OSM=%d, GLHER=%d",
                nrow(wikidata_std), nrow(osm_std), nrow(glher_std)))

# 3. Combine with deduplication
message("\n--- 3. Combination & Deduplication ---")
all_statues <- combine_statue_sources(
  list(wikidata = wikidata_std, osm = osm_std, glher = glher_std),
  distance_threshold = 50
)

# 4. Summary
message("\n--- 4. Summary ---")
message("Total unique statues: ", nrow(all_statues))
message("Multi-source records: ", sum(all_statues$is_multi_source))
message("With names: ", sum(!is.na(all_statues$name)))
message("With coordinates: ", sum(!is.na(all_statues$lat)))

# 5. Create interactive map
message("\n--- 5. Mapping ---")
map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "source",
  cluster = TRUE
)

# 6. Save map and combined dataset
saveRDS(all_statues, "data-raw/combined_statues.rds")
htmlwidgets::saveWidget(map, "london_statues_interactive_map.html")

message("\n✓ Full pipeline complete! Map saved to london_statues_interactive_map.html")

# 7. Analysis
message("\n--- 6. Analysis ---")
gender_results <- analyze_by_gender(all_statues)
print(gender_results$summary)

comparison <- compare_johns_vs_women(all_statues)
message(comparison$message)
message("Claim validated: ", comparison$claim_validated)
