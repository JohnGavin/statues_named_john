# Quick Start Guide: Multi-Source Statue Data

**Once nix packages finish building, follow these steps:**

---

## Step 1: Verify Packages (1 minute)

```bash
nix-shell --run "Rscript -e 'library(WikidataQueryServiceR); library(osmdata); library(sf); library(leaflet); cat(\"✓ All packages loaded successfully\n\")'"
```

**Expected:** "✓ All packages loaded successfully"

---

## Step 2: Test Wikidata (5 minutes)

```bash
nix-shell --run "Rscript R/setup/test_wikidata.R 2>&1 | tee R/setup/test_wikidata.log"
```

**Expected Output:**
```
=== Testing Wikidata SPARQL for London Statues ===
Date: 2025-11-12

--- Executing SPARQL Query ---
Querying Wikidata for London statues...

✓ Query successful!
  Retrieved 50-100 statue records

--- Summary Statistics ---
  Total statues: 75
  With subjects: 60
  With dates: 45
  With materials: 30
  With creators: 25
  With images: 40
  With Wikipedia: 50

✓ Results saved to R/setup/wikidata_london_statues.rds
✓ Results saved to R/setup/wikidata_london_statues.csv
```

**Files Created:**
- `R/setup/wikidata_london_statues.rds`
- `R/setup/wikidata_london_statues.csv`

---

## Step 3: Test OpenStreetMap (5 minutes)

```bash
nix-shell --run "Rscript R/setup/test_osm.R 2>&1 | tee R/setup/test_osm.log"
```

**Expected Output:**
```
=== Testing OpenStreetMap Overpass API for London Statues ===

--- Query 1: Statues (memorial=statue) ---
✓ Found 150 statues with memorial=statue

--- Query 2: Historic Memorials ---
✓ Found 200 historic memorials

--- Query 3: Man-made Statues ---
✓ Found 100 man-made statues

--- Summary Statistics ---
Total datasets retrieved: 3
  memorial_statue: 150 features
    - With names: 120
    - With subject: 30
  historic_memorial: 200 features
    - With names: 180
  manmade_statue: 100 features
    - With names: 85

✓ All results saved to R/setup/osm_all_statues.rds
```

**Files Created:**
- `R/setup/osm_statues_memorial.rds`
- `R/setup/osm_historic_memorial.rds`
- `R/setup/osm_manmade_statue.rds`
- `R/setup/osm_all_statues.rds`

---

## Step 4: Quick Data Inspection (2 minutes)

```bash
nix-shell --run "Rscript -e '
# Load test results
wd <- readRDS(\"R/setup/wikidata_london_statues.rds\")
osm <- readRDS(\"R/setup/osm_all_statues.rds\")

# Summary
cat(\"\\n=== Data Summary ===\\n\")
cat(\"Wikidata records:\", nrow(wd), \"\\n\")
cat(\"OSM records:\", sum(sapply(osm, nrow)), \"\\n\")
cat(\"\\nWikidata sample:\\n\")
print(head(wd[, c(\"name\", \"subject\", \"lat\", \"lon\")], 3))
cat(\"\\nOSM sample:\\n\")
print(head(osm[[1]][, c(\"name\", \"lat\", \"lon\")], 3))
'"
```

---

## Step 5: Create Simple Test Map (5 minutes)

```bash
nix-shell --run "Rscript -e '
library(leaflet)
library(dplyr)

# Load Wikidata results
wd <- readRDS(\"R/setup/wikidata_london_statues.rds\")

# Create simple map
map <- leaflet(wd) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~lon,
    lat = ~lat,
    radius = 6,
    popup = ~paste0(
      \"<b>\", name, \"</b><br>\",
      \"Subject: \", subject, \"<br>\",
      \"Year: \", inception_date
    ),
    label = ~name
  )

# Save map
htmlwidgets::saveWidget(map, \"R/setup/test_map.html\")
cat(\"\\n✓ Test map saved to R/setup/test_map.html\\n\")
cat(\"Open in browser to view\\n\")
'"
```

**Result:** Interactive map at `R/setup/test_map.html`

---

## Step 6: Implement Full Functions (30 minutes)

### Option A: Extract from implementation_plan.md

```bash
# The implementation_plan.md contains all complete function code
# Extract each function to its own file:

# 1. R/get_statues_wikidata.R (lines 32-125)
# 2. R/get_statues_osm.R (lines 135-230)
# 3. R/get_statues_glher.R (lines 240-330)
# 4. R/standardize_statue_data.R (lines 340-500)
# 5. R/combine_statue_sources.R (lines 510-650)
# 6. R/map_statues.R (lines 660-750)
# 7. R/analyze_statues.R (lines 760-850)
```

### Option B: Quick Implementation Script

Create `R/setup/implement_functions.R`:

```r
#!/usr/bin/env Rscript
# Quick implementation of core functions

# Read implementation plan
plan <- readLines("R/setup/implementation_plan.md")

# Find function code blocks (between ```r and ```)
# Extract and save to individual files

# For now, test with simplified versions...
message("Use implementation_plan.md as reference")
message("All code is ready to be extracted")
```

---

## Step 7: Full Pipeline Test (10 minutes)

Once functions are implemented:

```bash
nix-shell --run "Rscript -e '
library(londonremembers)
library(dplyr)

# 1. Get data
message(\"Getting Wikidata...\")
wd <- get_statues_wikidata(cache_path = \"data-raw/wd_cache.rds\")

message(\"Getting OSM...\")
osm <- get_statues_osm(cache_path = \"data-raw/osm_cache.rds\")

# 2. Standardize
message(\"Standardizing...\")
wd_std <- standardize_statue_data(wd, \"wikidata\")
osm_std <- standardize_statue_data(osm, \"osm\")

# 3. Combine
message(\"Combining sources...\")
all_statues <- combine_statue_sources(
  list(wikidata = wd_std, osm = osm_std),
  distance_threshold = 50
)

# 4. Summary
cat(\"\\n=== Final Dataset ===\\n\")
cat(\"Total unique statues:\", nrow(all_statues), \"\\n\")
cat(\"Multi-source records:\", sum(all_statues$is_multi_source), \"\\n\")
cat(\"With names:\", sum(!is.na(all_statues$name)), \"\\n\")
cat(\"With coordinates:\", sum(!is.na(all_statues$lat)), \"\\n\")

# 5. Create map
message(\"Creating interactive map...\")
map <- map_statues(
  all_statues,
  popup_fields = c(\"name\", \"subject\", \"year_installed\", \"material\"),
  color_by = \"source\",
  cluster = TRUE
)

# 6. Save
htmlwidgets::saveWidget(map, \"london_statues_interactive_map.html\")
saveRDS(all_statues, \"data-raw/combined_statues.rds\")

cat(\"\\n✓ Complete! Map saved to london_statues_interactive_map.html\\n\")
'"
```

---

## Step 8: Gender Analysis (5 minutes)

```bash
nix-shell --run "Rscript -e '
library(londonremembers)

# Load combined data
all_statues <- readRDS(\"data-raw/combined_statues.rds\")

# Gender analysis
gender_results <- analyze_by_gender(all_statues)

cat(\"\\n=== Gender Analysis ===\\n\")
print(gender_results$summary)

# Johns vs Women
comparison <- compare_johns_vs_women(all_statues)
cat(\"\\n=== Johns vs Women ===\\n\")
cat(comparison$message, \"\\n\")
cat(\"Claim validated:\", comparison$claim_validated, \"\\n\")
'"
```

---

## Step 9: Update Vignette (15 minutes)

1. Open `vignettes/memorial-analysis.Rmd`
2. Replace demonstration data sections with real data retrieval
3. Add interactive map code
4. Add gender analysis
5. Build vignette:

```bash
nix-shell --run "Rscript -e 'devtools::build_vignettes()'"
```

---

## Step 10: Check & Commit (15 minutes)

```bash
# Run package check
nix-shell --run "Rscript -e 'devtools::check()'"

# If all passes, commit
git add R/ vignettes/ DESCRIPTION default.R default.nix
git commit -m "Add multi-source statue data retrieval and interactive mapping

- Replace blocked web scraping with Wikidata, OSM, GLHER
- Add spatial deduplication (50m threshold)
- Implement interactive Leaflet maps with rich popups
- Add gender analysis and Johns vs Women comparison
- Update vignette with real data and validation

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to GitHub
git push origin main
```

---

## Troubleshooting

### If packages not found:
```bash
# Check what's available
nix-shell --run "Rscript -e 'installed.packages()[, c(\"Package\", \"Version\")]' | grep -E '(Wikidata|osmdata|sf|leaflet)'"

# Rebuild environment
nix-shell --run "Rscript default.R"
```

### If SPARQL query times out:
```r
# Reduce limit
get_statues_wikidata(limit = 50)
```

### If OSM query fails:
```r
# Smaller bbox (Westminster only)
get_statues_osm(bbox = c(-0.1773, 51.4899, -0.1131, 51.5155))
```

---

## Expected Timeline

| Task | Time | Status |
|------|------|--------|
| Verify packages | 1 min | Pending |
| Test Wikidata | 5 min | Pending |
| Test OSM | 5 min | Pending |
| Inspect data | 2 min | Pending |
| Test map | 5 min | Pending |
| Implement functions | 30 min | Code ready |
| Full pipeline | 10 min | Pending |
| Gender analysis | 5 min | Pending |
| Update vignette | 15 min | Pending |
| Check & commit | 15 min | Pending |
| **Total** | **~90 min** | **Ready** |

---

## Success Criteria

✅ **Data Retrieval:**
- 50+ statues from Wikidata
- 100+ features from OSM
- All have coordinates

✅ **Interactive Map:**
- Displays in browser
- Hover shows name
- Click shows full popup
- Can zoom/pan

✅ **Analysis:**
- Gender breakdown calculated
- Johns vs Women comparison complete
- Results match expectations

✅ **Documentation:**
- Functions documented with roxygen2
- Vignette includes real data
- README updated
- All tests pass

---

## Files Reference

**Documentation:**
- `R/setup/data_sources_research.md` - Research findings
- `R/setup/implementation_plan.md` - Complete code (700+ lines)
- `R/setup/session_summary.md` - Progress summary
- `R/setup/QUICK_START.md` - This file

**Test Scripts:**
- `R/setup/test_wikidata.R` - Ready to run
- `R/setup/test_osm.R` - Ready to run

**Next to Create:**
- `R/get_statues_wikidata.R` - Extract from implementation_plan.md
- `R/get_statues_osm.R` - Extract from implementation_plan.md
- `R/standardize_statue_data.R` - Extract from implementation_plan.md
- `R/combine_statue_sources.R` - Extract from implementation_plan.md
- `R/map_statues.R` - Extract from implementation_plan.md
- `R/analyze_statues.R` - Extract from implementation_plan.md

---

**Ready to execute when nix packages finish building!**
