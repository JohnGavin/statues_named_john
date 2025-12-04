# Quick Start Guide: Multi-Source Statue Data

---

## Step 1: Verify Packages (1 minute)

Confirm the specialized R packages required for this project are loaded in your Nix environment.

```bash
R --quiet -e 'c("WikidataQueryServiceR", "osmdata", "sf", "leaflet") |> sapply(library, char = T); cat("✓ All specialized packages loaded successfully\n")'
```

**Expected Output:** "✓ All specialized packages loaded successfully" (along with various loading messages from the packages).

---

## Step 2: Test Wikidata Data Retrieval (5 minutes)

Execute the test script for Wikidata data retrieval. This script queries the Wikidata SPARQL endpoint for London statues.

```bash
R --quiet -e 'source("R/setup/test_wikidata.R")' 2>&1 | tee R/setup/test_wikidata.log
```

**Expected Output (example):**
```
=== Testing Wikidata SPARQL for London Statues ===
Date: 2025-11-XX

--- Executing SPARQL Query ---
Querying Wikidata for London statues...

✓ Query successful!
  Retrieved [e.g., 75] statue records

--- Summary Statistics ---
  Total statues: [e.g., 75]
  With subjects: [e.g., 60]
  With dates: [e.g., 45]
  With materials: [e.g., 30]
  With creators: [e.g., 25]
  With images: [e.g., 40]
  With Wikipedia: [e.g., 50]

✓ Results saved to R/setup/wikidata_london_statues.rds
✓ Results saved to R/setup/wikidata_london_statues.csv
```

**Files Created:**
- `R/setup/wikidata_london_statues.rds`
- `R/setup/wikidata_london_statues.csv`
- `R/setup/test_wikidata.log`

---

## Step 3: Test OpenStreetMap Data Retrieval (5 minutes)

Execute the test script for OpenStreetMap (OSM) data retrieval. This script queries the Overpass API for various types of memorials in London.

```bash
R --quiet -e 'source("R/setup/test_osm.R")' 2>&1 | tee R/setup/test_osm.log
```

**Expected Output (example):**
```
=== Testing OpenStreetMap Overpass API for London Statues ===

--- Query 1: Statues (memorial=statue) ---
✓ Found [e.g., 150] statues with memorial=statue

--- Query 2: Historic Memorials ---
✓ Found [e.g., 200] historic memorials

--- Query 3: Man-made Statues ---
✓ Found [e.g., 100] man-made statues

--- Summary Statistics ---
Total datasets retrieved: 3
  memorial_statue: [e.g., 150] features
    - With names: [e.g., 120]
    - With subject: [e.g., 30]
  historic_memorial: [e.g., 200] features
    - With names: [e.g., 180]
  manmade_statue: [e.g., 100] features
    - With names: [e.g., 85]

✓ All results saved to R/setup/osm_all_statues.rds
```

**Files Created:**
- `R/setup/osm_statues_memorial.rds`
- `R/setup/osm_historic_memorial.rds`
- `R/setup/osm_manmade_statue.rds`
- `R/setup/osm_all_statues.rds`
- `R/setup/test_osm.log`

---

## Step 4: Quick Data Inspection (2 minutes)

Inspect the retrieved dataframes for basic structure and content.

```bash
R --quiet -e '
# Load test results
wd <- readRDS("R/setup/wikidata_london_statues.rds")
osm <- readRDS("R/setup/osm_all_statues.rds")

# Summary
cat("\n=== Data Summary ===\n")
cat("Wikidata records:", nrow(wd), "\n")
cat("OSM records (combined):", sum(sapply(osm, nrow)), "\n")
cat("\nWikidata sample (first 3 rows):\n")
print(head(wd[, c("name", "subject", "lat", "lon")], 3))
cat("\nOSM sample (first 3 rows of first dataset):\n")
print(head(osm[[1]][, c("name", "lat", "lon")], 3))
'
```

---

## Step 5: Create Simple Test Map (5 minutes)

Generate a basic interactive map using the retrieved Wikidata results to visually confirm data.

```bash
R --quiet -e '
library(leaflet)
library(dplyr)

# Load Wikidata results
wd <- readRDS("R/setup/wikidata_london_statues.rds")

# Create simple map
map <- leaflet(wd) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~lon,
    lat = ~lat,
    radius = 6,
    popup = ~paste0(
      "<b>", name, "</b><br>",
      "Subject: ", subject, "<br>",
      "Year: ", inception_date
    ),
    label = ~name
  )

# Save map
htmlwidgets::saveWidget(map, "R/setup/test_map.html")
cat("\n✓ Test map saved to R/setup/test_map.html\n")
cat("Open in browser to view\n")
'
```

**Result:** An interactive map HTML file at `R/setup/test_map.html`. Open this file in your web browser to view the map.

---

## Step 6: Implement Full Functions (30 minutes)

The complete function code is already drafted within `R/setup/PROJECT_IMPLEMENTATION.md`. This step involves extracting these functions into their respective R files within the `R/` directory.

**Action:** Manually create the following files in the `R/` directory and populate them with the corresponding R code from `R/setup/PROJECT_IMPLEMENTATION.md`.

*   `R/get_statues_wikidata.R`
*   `R/get_statues_osm.R`
*   `R/get_statues_glher.R`
*   `R/get_statues_historic_england.R`
*   `R/standardize_statue_data.R`
*   `R/combine_statue_sources.R`
*   `R/map_statues.R`
*   `R/analyze_statues.R`
*   *(Optional `R/utils.R` for helper functions from `PROJECT_IMPLEMENTATION.md` if not already grouped).*

---

## Step 7: Full Pipeline Test (10 minutes)

After implementing the individual functions, run the full data acquisition, standardization, combination, and mapping pipeline.

```bash
R --quiet -e '
library(statuesnamedjohn)
library(dplyr)
library(htmlwidgets) # For saveWidget

# 1. Get data
message("Getting Wikidata data...")
wikidata_raw <- get_statues_wikidata(cache_path = "data-raw/wikidata_cache.rds")

message("Getting OSM data...")
osm_raw <- get_statues_osm(cache_path = "data-raw/osm_cache.rds")

message("Getting GLHER data...")
glher_raw <- get_statues_glher(cache_path = "data-raw/glher_cache.rds")

# 2. Standardize
message("Standardizing data...")
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
osm_std <- standardize_statue_data(osm_raw, "osm")
glher_std <- standardize_statue_data(glher_raw, "glher")

# 3. Combine with deduplication
message("Combining sources with deduplication...")
all_statues <- combine_statue_sources(
  list(wikidata = wikidata_std, osm = osm_std, glher = glher_std),
  distance_threshold = 50
)

# 4. Summary
cat("\n=== Final Combined Dataset Summary ===\n")
cat("Total unique statues:", nrow(all_statues), "\n")
cat("Multi-source records:", sum(all_statues$is_multi_source), "\n")
cat("With names:", sum(!is.na(all_statues$name)), "\n")
cat("With coordinates:", sum(!is.na(all_statues$lat)), "\n")

# 5. Create interactive map
message("Creating interactive map...")
map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "source",
  cluster = TRUE
)

# 6. Save map and combined dataset
saveRDS(all_statues, "data-raw/combined_statues.rds")
htmlwidgets::saveWidget(map, "london_statues_interactive_map.html")

cat("\n✓ Full pipeline complete! Interactive map saved to london_statues_interactive_map.html\n")
'
```

---

## Step 8: Gender Analysis and Claims Validation (5 minutes)

Run the analysis functions on the combined dataset.

```bash
R --quiet -e '
library(statuesnamedjohn)

# Load combined data
all_statues <- readRDS("data-raw/combined_statues.rds")

# Gender analysis
gender_results <- analyze_by_gender(all_statues)

cat("\n=== Gender Analysis Summary ===\n")
print(gender_results$summary)

# Johns vs Women comparison
comparison <- compare_johns_vs_women(all_statues)
cat("\n=== Johns vs Women Claims Validation ===\n")
cat(comparison$message, "\n")
cat("Claim 'more Johns than women' validated:", comparison$claim_validated, "\n")
'
```

---

## Step 9: Update and Build Vignette (15 minutes)

Update the project vignette to reflect the new data sources, analysis, and interactive map.

1.  Open `vignettes/memorial-analysis.qmd`
2.  Replace any demonstration data sections with code that uses the implemented functions to retrieve, process, and analyze the real multi-source data.
3.  Incorporate code to display the interactive map and the results of the gender analysis and claims validation.
4.  Build the vignette:

```bash
R --quiet -e 'devtools::build_vignettes()'
```

---

## Step 10: Run Checks and Commit Changes (15 minutes)

Perform final package checks and commit all changes to the Git repository.

```bash
# Update documentation (if functions were extracted from PROJECT_IMPLEMENTATION.md)
R --quiet -e 'devtools::document()'

# Run comprehensive package checks
R --quiet -e 'devtools::check()'
```

If all checks pass with no errors, warnings, or notes:

```bash
git add .
git commit -m "feat: Implement multi-source statue data retrieval and analysis

This commit introduces the full pipeline for acquiring statue data from
Wikidata, OpenStreetMap, and GLHER APIs, standardizing and combining
the data using spatial deduplication, and performing gender analysis.
It includes:

- Functions for data retrieval from multiple APIs.
- Data standardization and merging logic using specialized R packages.
- Interactive Leaflet map generation.
- Gender analysis and 'Johns vs Women' claims validation.
- Updated vignette reflecting the new data and analysis.
- Comprehensive documentation for all functions.

Resolves initial Nix package availability blockers by leveraging
confirmed available specialized R packages.

🤖 Generated with Claude Code"

git push origin main
```

---

## Troubleshooting

### If API queries fail or time out:
*   Check your internet connection.
*   Reduce query `limit` parameters in retrieval functions.
*   Use smaller bounding boxes for OSM queries.
*   Check the API status pages for Wikidata, Overpass (OSM), and GLHER.

### If R package checks (`devtools::check()`) report issues:
*   Review the error messages carefully.
*   Consult the R package development guidelines and fix identified problems.

---

## Expected Timeline

| Task                                 | Time       | Status     |
| :----------------------------------- | :--------- | :--------- |
| Step 1: Verify packages              | 1 min      | ✅ Complete |
| Step 2: Test Wikidata                | 5 min      | ⏳ Pending |
| Step 3: Test OSM                     | 5 min      | ⏳ Pending |
| Step 4: Inspect data                 | 2 min      | ⏳ Pending |
| Step 5: Create simple map            | 5 min      | ⏳ Pending |
| Step 6: Implement full functions     | 30 min     | ⏳ Pending |
| Step 7: Full pipeline test           | 10 min     | ⏳ Pending |
| Step 8: Gender analysis              | 5 min      | ⏳ Pending |
| Step 9: Update vignette              | 15 min     | ⏳ Pending |
| Step 10: Check & commit              | 15 min     | ⏳ Pending |
| **Total Estimated Time Remaining** | **~90 min**| **Ready**  |

---

## Success Criteria

*   **Data Retrieval:** 50+ unique statues from Wikidata and 100+ unique features from OSM (combined after deduplication). All records have coordinates.
*   **Interactive Map:** Displays in browser, shows names on hover, full popups on click, supports zoom/pan, clustering, and color-coding by source.
*   **Analysis:** Gender breakdown calculated, "Johns vs Women" comparison complete, results documented in vignette.
*   **Documentation:** All functions documented with Roxygen2, vignette includes real data, README updated, all tests pass.

---

## Files Reference

**Documentation:**
- `R/setup/PROJECT_PLAN.md` - Comprehensive project plan.
- `R/setup/PROJECT_IMPLEMENTATION.md` - Complete R code and technical architecture.
- `R/setup/PROJECT_STATUS_HISTORY.md` - Chronological log of project progress.
- `R/setup/TECHNICAL_JOURNAL.md` - Detailed account of the Nix package blocker and its resolution.
- `R/setup/QUICK_START_GUIDE.md` - This file.

**Test Scripts (to be run):**
- `R/setup/test_wikidata.R`
- `R/setup/test_osm.R`

**Next to Create (extracted from `PROJECT_IMPLEMENTATION.md`):**
- `R/get_statues_wikidata.R`
- `R/get_statues_osm.R`
- `R/get_statues_glher.R`
- `R/get_statues_historic_england.R`
- `R/standardize_statue_data.R`
- `R/combine_statue_sources.R`
- `R/map_statues.R`
- `R/analyze_statues.R`

---

**Ready to execute!**

```
