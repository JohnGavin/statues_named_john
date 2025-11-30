# Project Implementation: londonremembers

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Sources                              │
├─────────────┬─────────────┬─────────────┬──────────────────┤
│   Wikidata  │     OSM     │   GLHER     │ Historic England │
│   SPARQL    │  Overpass   │   CSV       │      CSV         │
└──────┬──────┴──────┬──────┴──────┬──────┴────────┬─────────┘
       │             │              │               │
       ▼             ▼              ▼               ▼
┌──────────────────────────────────────────────────────────────┐
│              Source-Specific Retrieval Functions             │
│  get_statues_wikidata() | get_statues_osm() |               │
│  get_statues_glher() | get_statues_historic_england()       │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Standardization Layer                           │
│              standardize_statue_data()                       │
│  Converts each source to common schema with:                 │
│  id, name, subject, lat, lon, type, year, source, url, etc. │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Merging & Deduplication                         │
│              combine_statue_sources()                        │
│  - Spatial join by coordinates (tolerance ~50m)              │
│  - Enrich records from multiple sources                      │
│  - Flag duplicates, keep best data                           │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Unified Dataset                                 │
│  Single tibble with all statues, coordinates, metadata       │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ├─────────────┬────────────────┐
                         ▼             ▼                ▼
                  ┌──────────┐  ┌──────────┐   ┌──────────────┐
                  │ Analysis │  │   Maps   │   │  Vignettes   │
                  │ Functions│  │ (leaflet)│   │  (updated)   │
                  └──────────┘  └──────────┘   └──────────────┘
```

## 2. Data Retrieval Functions

### 2.1 Wikidata SPARQL Retrieval

**File:** `R/get_statues_wikidata.R`

See implementation in [`R/get_statues_wikidata.R`](../../R/get_statues_wikidata.R).

### 2.2 OpenStreetMap Overpass Retrieval

**File:** `R/get_statues_osm.R`

See implementation in [`R/get_statues_osm.R`](../../R/get_statues_osm.R).

### 2.3 GLHER CSV Retrieval

**File:** `R/get_statues_glher.R`

See implementation in [`R/get_statues_glher.R`](../../R/get_statues_glher.R).

### 2.4 Historic England National Heritage List

**File:** `R/get_statues_historic_england.R`

See implementation in [`R/get_statues_historic_england.R`](../../R/get_statues_historic_england.R).

## 3. Data Standardization

**File:** `R/standardize_statue_data.R`

See implementation in [`R/standardize_statue_data.R`](../../R/standardize_statue_data.R).

## 4. Data Merging & Deduplication

**File:** `R/combine_statue_sources.R`

See implementation in [`R/combine_statue_sources.R`](../../R/combine_statue_sources.R).

## 5. Interactive Map Implementation

**File:** `R/map_statues.R`

See implementation in [`R/map_statues.R`](../../R/map_statues.R).

## 6. Analysis Functions

**File:** `R/analyze_statues.R`

See implementation in [`R/analyze_statues.R`](../../R/analyze_statues.R).

## 7. Vignette Integration

**File:** `vignettes/memorial-analysis.Rmd` (updated sections)

```rmd
## Real Data from Multiple Sources

This analysis uses real data retrieved from multiple authoritative sources:

- **Wikidata**: Structured linked open data with rich metadata
- **OpenStreetMap**: Community-contributed geographic data
- **Greater London HER**: Professional heritage records
- **Historic England**: Listed monuments and heritage assets

### Data Retrieval

```{r get-data, cache=TRUE}
library(londonremembers)
library(dplyr)
library(ggplot2)
library(leaflet)

# Retrieve data from all sources
wikidata_raw <- get_statues_wikidata(
  location = "Q84",  # London
  cache_path = "data-raw/wikidata_cache.rds"
)

osm_raw <- get_statues_osm(
  cache_path = "data-raw/osm_cache.rds"
)

glher_raw <- get_statues_glher(
  cache_path = "data-raw/glher_cache.rds"
)

# Standardize all sources
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
osm_std <- standardize_statue_data(osm_raw, "osm")
glher_std <- standardize_statue_data(glher_raw, "glher")

# Combine and deduplicate
all_statues <- combine_statue_sources(
  list(
    wikidata = wikidata_std,
    osm = osm_std,
    glher = glher_std
  )
)

# Summary
message("Total unique statues identified: ", nrow(all_statues))
message("With coordinates: ", sum(!is.na(all_statues$lat)))
message("Multi-source records: ", sum(all_statues$is_multi_source, na.rm = TRUE))
```

### Data Quality Comparison

```{r data-quality}
# Compare coverage across sources
source_comparison <- all_statues %>%
  group_by(source) %>%
  summarize(
    n_records = n(),
    with_names = sum(!is.na(name)),
    with_subjects = sum(!is.na(subject)),
    with_dates = sum(!is.na(year_installed)),
    with_materials = sum(!is.na(material)),
    with_images = sum(!is.na(image_url))
  )

knitr::kable(source_comparison,
             caption = "Data Quality Comparison Across Sources")
```

### Interactive Map

```{r interactive-map, fig.height=8, fig.width=10}
# Create interactive map
statue_map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material",
                   "sculptor", "source_url"),
  color_by = "source",
  cluster = TRUE
)

statue_map
```

**Map Features:**
- Click markers to see detailed information
- Hover to see statue names
- Zoom and pan to explore different areas
- Markers are clustered for better performance
- Colors indicate data source

### Gender Analysis

```{r gender-analysis}
# Analyze by gender
gender_results <- analyze_by_gender(all_statues)

# Summary table
knitr::kable(gender_results$summary,
             caption = "Gender Representation in London Statues")

# Visualization
ggplot(gender_results$summary, aes(x = inferred_gender, y = n, fill = inferred_gender)) +
  geom_col() +
  geom_text(aes(label = sprintf("%d (%.1f%%)", n, percent)),
            vjust = -0.5) +
  labs(
    title = "Gender Representation in London Statues",
    x = "Gender",
    y = "Number of Statues",
    caption = sprintf("Total: %d statues from %s",
                     nrow(all_statues),
                     format(Sys.Date(), "%Y-%m-%d"))
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

### Validation of "Statues for Equality" Claims

```{r johns-vs-women}
# Compare Johns vs Women
comparison <- compare_johns_vs_women(all_statues)

cat(comparison$message, "\n\n")
cat("Claim validated:", comparison$claim_validated, "\n")
```

**Analysis:**

The "Statues for Equality" campaign claims that:
> "more statues named John dotted around the country than of women"

Our analysis of real data from London shows:
- **John statues:** `r comparison$john_statues` (`r comparison$john_percent`%)
- **Women statues:** `r comparison$woman_statues` (`r comparison$woman_percent`%)
- **Claim validated:** `r comparison$claim_validated`

### Methodology Transparency

Unlike the Statues for Equality website, this analysis provides:

1. **Source Attribution:** All data sources clearly identified
2. **Reproducible Code:** Complete R code provided
3. **Data Quality Metrics:** Coverage and completeness documented
4. **Geographic Verification:** Coordinates validated across sources
5. **Deduplication:** Spatial matching documented
6. **Classification Methods:** Gender inference methods explained

### Data Limitations

- **Coverage:** Data sources may not include all statues
- **Gender Classification:** Simple heuristic; manual review recommended
- **Subject Identification:** Some statues lack subject metadata
- **Geographic Scope:** London-focused; UK-wide data requires expansion
```

## 8. File Structure

```
londonremembers/
├── R/
│   ├── get_statues_wikidata.R           # Wikidata SPARQL queries
│   ├── get_statues_osm.R                # OSM Overpass API
│   ├── get_statues_glher.R              # GLHER CSV download
│   ├── get_statues_historic_england.R   # Historic England data
│   ├── standardize_statue_data.R        # Data standardization
│   ├── combine_statue_sources.R         # Merging & deduplication
│   ├── map_statues.R                    # Interactive leaflet maps
│   ├── analyze_statues.R                # Analysis functions
│   └── utils.R                          # Helper functions
├── R/setup/
│   ├── test_wikidata.R                  # Test Wikidata queries
│   ├── test_osm.R                       # Test OSM queries
│   ├── test_glher.R                     # Test GLHER downloads
│   ├── data_sources_research.md         # Research document
│   └── implementation_plan.md           # This document
├── data-raw/
│   ├── wikidata_cache.rds               # Cached Wikidata results
│   ├── osm_cache.rds                    # Cached OSM results
│   ├── glher_cache.rds                  # Cached GLHER results
│   └── combined_statues.rds             # Final combined dataset
├── vignettes/
│   └── memorial-analysis.Rmd            # Updated vignette with real data
├── inst/
│   └── example_maps/
│       └── london_statues.html          # Example saved map
├── DESCRIPTION                           # Updated with new dependencies
└── default.R / default.nix              # Nix environment with new packages
```

## 9. Usage Examples

### 9.1 Basic: Get Data from One Source

```r
library(londonremembers)

# Get Wikidata statues
statues <- get_statues_wikidata(location = "Q84")  # Q84 = London
head(statues)
```

### 9.2 Intermediate: Combine Multiple Sources

```r
# Get from multiple sources
wd <- get_statues_wikidata() %>% standardize_statue_data("wikidata")
osm <- get_statues_osm() %>% standardize_statue_data("osm")

# Combine
all_statues <- combine_statue_sources(list(wikidata = wd, osm = osm))

# How many statues?
nrow(all_statues)

# How many from multiple sources?
sum(all_statues$is_multi_source)
```

### 9.3 Advanced: Full Pipeline with Analysis and Mapping

```r
library(londonremembers)
library(dplyr)
library(ggplot2)

# 1. Retrieve from all sources (with caching)
wikidata_raw <- get_statues_wikidata(
  cache_path = "data-raw/wikidata_cache.rds"
)

osm_raw <- get_statues_osm(
  cache_path = "data-raw/osm_cache.rds"
)

glher_raw <- get_statues_glher(
  cache_path = "data-raw/glher_cache.rds"
)

# 2. Standardize
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
osm_std <- standardize_statue_data(osm_raw, "osm")
glher_std <- standardize_statue_data(glher_raw, "glher")

# 3. Combine with deduplication
all_statues <- combine_statue_sources(
  list(wikidata = wikidata_std, osm = osm_std, glher = glher_std),
  distance_threshold = 50  # 50 meters
)

# 4. Analyze by gender
gender_analysis <- analyze_by_gender(all_statues)
print(gender_analysis$summary)

# 5. Compare Johns vs Women
comparison <- compare_johns_vs_women(all_statues)
print(comparison$message)

# 6. Create interactive map
map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "source",
  cluster = TRUE
)

# 7. Display map
map

# 8. Save map to HTML
htmlwidgets::saveWidget(map, "london_statues_map.html")

# 9. Save combined dataset
saveRDS(all_statues, "data-raw/combined_statues.rds")
```

### 9.4 Vignette Usage

```r
# Build vignette with real data
devtools::build_vignettes()

# View vignette
vignette("memorial-analysis", package = "londonremembers")
```

## 10. Performance Considerations

### 10.1 Caching Strategy

All data retrieval functions support caching via `cache_path` parameter:

```r
# First call: retrieves from API (slow)
data <- get_statues_wikidata(cache_path = "cache/wikidata.rds")

# Subsequent calls: loads from cache (fast)
data <- get_statues_wikidata(cache_path = "cache/wikidata.rds")
```

### 10.2 Rate Limiting

- **Wikidata SPARQL:** No strict limits, but be considerate
- **OSM Overpass:** 2-second delay between queries (implemented)
- **GLHER:** Unknown limits - implement conservative delays

### 10.3 Large Dataset Handling

For London-wide or UK-wide data:

- Use spatial indexing with `sf` package
- Implement chunked processing for deduplication
- Consider using `data.table` for large merges
- Cache intermediate results

### 10.4 Targets Pipeline Integration

```r
# _targets.R
library(targets)
library(tarchetypes)

tar_plan(
  # Data retrieval
  tar_target(wikidata_raw, get_statues_wikidata(cache_path = "cache/wd.rds")),
  tar_target(osm_raw, get_statues_osm(cache_path = "cache/osm.rds")),
  tar_target(glher_raw, get_statues_glher(cache_path = "cache/glher.rds")),

  # Standardization
  tar_target(wikidata_std, standardize_statue_data(wikidata_raw, "wikidata")),
  tar_target(osm_std, standardize_statue_data(osm_raw, "osm")),
  tar_target(glher_std, standardize_statue_data(glher_raw, "glher")),

  # Combination
  tar_target(
    all_statues,
    combine_statue_sources(list(
      wikidata = wikidata_std,
      osm = osm_std,
      glher = glher_std
    ))
  ),

  # Analysis
  tar_target(gender_analysis, analyze_by_gender(all_statues)),
  tar_target(johns_comparison, compare_johns_vs_women(all_statues)),

  # Visualization
  tar_target(statue_map, map_statues(all_statues))
)
```

## 11. Testing Strategy

### 11.1 Unit Tests

```r
# tests/testthat/test-get-statues-wikidata.R
test_that("get_statues_wikidata returns valid data", {
  # Mock or use small test query
  data <- get_statues_wikidata(location = "Q84", limit = 10)

  expect_s3_class(data, "tbl_df")
  expect_true("lat" %in% names(data))
  expect_true("lon" %in% names(data))
  expect_true(all(!is.na(data$lat)))
  expect_true(all(!is.na(data$lon)))
})

# tests/testthat/test-standardize.R
test_that("standardize_statue_data creates correct schema", {
  mock_data <- tibble::tibble(
    wikidata_id = "Q12345",
    name = "Test Statue",
    lat = 51.5,
    lon = -0.1
  )

  std <- standardize_statue_data(mock_data, "wikidata")

  expect_true("id" %in% names(std))
  expect_true("source" %in% names(std))
  expect_equal(nrow(std), 1)
})
```

### 11.2 Integration Tests

```r
# tests/testthat/test-full-pipeline.R
test_that("full pipeline works end-to-end", {
  skip_on_cran()
  skip_if_offline()

  # Small test area
  bbox <- c(-0.15, 51.5, -0.1, 51.52)

  # Get data
  osm <- get_statues_osm(bbox = bbox)
  std <- standardize_statue_data(osm, "osm")

  # Should have some results
  expect_gt(nrow(std), 0)

  # Should have coordinates
  expect_true(all(!is.na(std$lat)))
  expect_true(all(!is.na(std$lon)))
})
```

## 12. Documentation Requirements

Each function requires:

1. **Roxygen2 comments** with:
   - `@description`
   - `@param` for each parameter
   - `@return` describing return value
   - `@examples` with working code
   - `@export` for user-facing functions

2. **Vignette coverage** showing:
   - Basic usage
   - Common workflows
   - Interpretation of results

3. **README** with:
   - Installation instructions
   - Quick start guide
   - Link to full vignette

## 13. Next Steps After Implementation

1. **Data validation:** Manually verify sample of records
2. **Gender classification:** Improve with manual mapping file
3. **UK-wide expansion:** Extend beyond London
4. **Additional sources:** Investigate more data sources
5. **API rate limits:** Document and implement proper throttling
6. **Shiny app:** Interactive web application for exploration
7. **Publication:** Document methodology in academic paper
8. **Data release:** Publish combined dataset with DOI

## 14. Conclusion

This implementation provides a **robust, transparent, and reproducible** approach to statue data analysis that:

✅ Combines multiple authoritative sources
✅ Provides geographic visualization with interactive maps
✅ Enables rigorous validation of public claims
✅ Documents methodology transparently
✅ Supports reproducible research through caching and `targets`
✅ Creates reusable R package functions

The interactive map with hover popups will allow users to explore each statue in detail, seeing its name, subject, date, materials, and links to source data.

```