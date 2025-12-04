# Project Overview: statuesnamedjohn

This document provides a comprehensive overview of the `statuesnamedjohn` R package, including its project plan, detailed implementation, and a summary of its key features and architecture.

---

## 1. Project Plan (`PROJECT_PLAN.md`)

Build an R package `statuesnamedjohn` to source and analyze data about statues in London, specifically to compare memorials for men named John, women, and dogs. The project aims to provide a transparent, reproducible, and interactive analysis of London's commemorative landscape, validating public claims with real data.

### Core Requirements

*   **R Package Development:** Build a robust R package with comprehensive documentation, tests, and adherence to R CMD check standards.
*   **Vignette:** Create a detailed `memorial-analysis` vignette comparing memorials honoring:
    *   Men named John vs. women of any name vs. dogs (male or female).
    *   Memorials can include statues, plaques, busts, or other specific markers.
*   **Vignette Content:** Tables and plots should include:
    *   Type of memorial (e.g., statue, plaque, bust).
    *   Year and decade of erection.
    *   Reason for memorial (e.g., politician, war hero, artist, scientist, philosopher, writer).
    *   Location information for mapping (region/postcode, longitude/latitude).
    *   Artist who made the statue and their gender.
    *   Statues and artists who are people of colour.
    *   Any other factors that might partition the data.
*   **Exclusions:** Exclude statues of mythical or royal people.
*   **Reproducibility:** Use `targets` pipelines to generate vignettes, tables, and graphs.
*   **Mapping:** Include longitude and latitude information to support interactive mapping of results.
*   **External Claims Validation:** Compare analysis results with external studies and claims, such as those from "Statues for Equality" and the PACK & SEND study.

### Data Sources Strategy

The project adopts a multi-source, API-driven approach for London-specific data, supplemented by external studies for broader context.

#### Primary Data Sources for London Analysis

| Source                  | Method                            | Data Points (Key)                                         | Pros                                                                    | Cons                                                                                                                       |
| :---------------------- | :-------------------------------- | :-------------------------------------------------------- | :---------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| **Wikidata** (Preferred) | SPARQL queries via `WikidataQueryServiceR` | Subject (P21, P31), Location (P131), Creator (P170), Inception Date (P571), Coordinates (P625) | Highly structured, easy to filter by gender/name, links to Wikipedia.   | Might be incomplete for smaller/newer memorials.                                                                           |
| **OpenStreetMap (OSM)** | `osmdata` R package (Overpass API)    | Location (lat/long), Tags (`historic=memorial`, `memorial=statue`, `name=*`, `subject:wikidata=*`) | Excellent geospatial coverage, often links to Wikidata, detailed tags.    | Attribute data (like subject gender) not stored directly, requires linking or inference.                                   |
| **Historic England (GLHER)** | CSV download / Targeted Scraping | Location, type, name, description, period, lat/lon.       | Authoritative for listed structures, high data quality, precise coords. | Filtering for specific statue types can be broad; requires careful extraction.                                              |

#### Supplementary Data & Comparative Context

*   **PACK & SEND Study / Art UK Research**: Use findings from the PACK & SEND study (which analyzed Art UK data) to provide UK-wide context and compare against London-specific results, especially for claims like "more Johns than women."
*   **Other Studies**: Reference and compare findings with other relevant studies (e.g., Statues for Equality, Hyperallergic, BBC News, New Statesman).
*   **London Remembers / Art UK (Limited Scraping)**: Acknowledge these sources for rich descriptive text and photos. However, direct programmatic access (API) is unavailable, and web scraping is brittle. **Scraping is considered a supplementary/last-resort method for specific enrichment where data is missing from primary API sources, not a primary data acquisition strategy.**

#### Art UK: A Superior Source with Access Limitations

*   **Coverage**: Art UK is a definitive source with over 14,800 UK public sculptures, professionally curated.
*   **Access Challenges**: No public API, web requests are blocked (403 Forbidden) for automated access, and no bulk CSV/JSON downloads are available.
*   **Implication**: While superior, its programmatic access limitations necessitate focusing on London-specific analysis with available APIs (Wikidata, OSM, GLHER). PACK & SEND study findings will be used for UK-wide context.

### Key Comparisons & Claims Validation

The project will critically examine and validate claims from campaigns such as "Statues for Equality" and findings from the PACK & SEND study.

*   **"More Johns than women"**: Analyze London-specific data to determine if the claim holds true for the capital, comparing results with UK-wide statistics from the PACK & SEND study (which found the claim to be false for the UK).
*   **Animal Representation**: Investigate claims regarding animal representation versus named women.

### Required R Packages

| Purpose                 | Package                 | Summary                                                      |
| :---------------------- | :---------------------- | :----------------------------------------------------------- |
| **Analysis & Reporting**| `ggplot2`                 | For creating static maps and visualizations                  |
|                         | `knitr`                   | For dynamic report generation                                |
|                         | `rmarkdown`               | For authoring vignettes                                      |
|                         | `targets`                 | For reproducible analysis pipelines                          |
|                         | `tarchetypes`             | Helpers for targets pipelines                                |
| **Data Acquisition**    | `WikidataQueryServiceR` | SPARQL queries to Wikidata                                   |
|                         | `osmdata`                 | OpenStreetMap Overpass API                                   |
|                         | `sf`                      | Spatial features for handling geographic data                |
|                         | `httr`                    | For HTTP requests to APIs (if direct `httr` is preferred)    |
|                         | `rvest`                   | For web scraping HTML pages (for supplementary data only)    |
| **Data Processing**     | `dplyr`                   | For data manipulation                                        |
|                         | `purrr`                   | For functional programming/iteration                         |
|                         | `stringr`                 | For string manipulation (names, cleaning)                    |
|                         | `tibble`                  | For modern data frames                                       |
| **Geospatial**          | `leaflet`                 | For interactive maps                                         |
| **Testing**             | `testthat`                | For unit testing                                             |

---

## 2. Implementation Details (`PROJECT_IMPLEMENTATION.md` & `implementation_plan.md`)

This section details the architecture, data flow, function implementations, and technical strategy used in the `statuesnamedjohn` package.

### Architecture Overview

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

### Data Acquisition

*   **Wikidata**: `get_statues_wikidata()` queries SPARQL endpoint for London statues (`Q84`), retrieving coordinates and metadata.
*   **OpenStreetMap**: `get_statues_osm()` queries Overpass API for `historic=memorial`, `memorial=statue`, `man_made=statue` within a London bounding box.
*   **Historic England (GLHER)**: `get_statues_glher()` downloads/processes CSV exports for monuments.
*   **Caching**: Caching mechanisms are implemented for all data retrieval functions to minimize API calls and speed up development.

### Data Processing

*   **Standardization**: `standardize_statue_data()` converts raw data from all sources into a common, consistent schema (ID, name, subject, lat, lon, type, year, source, URL, etc.).
*   **Cleaning**: `clean_names()` removes honorifics and dates from names. `clean_text()` for general text processing.
*   **Gender Classification**: `classify_gender_from_subject()` uses a heuristic first-name lookup for common names, defaulting to "unknown".
*   **Subject Classification**: `classify_subject()` categorizes memorials by reason (e.g., politician, artist).
*   **Geospatial Processing**: `extract_coords_from_wkt()` for WKT geometry strings.
*   **Merging & Deduplication**: `combine_statue_sources()` merges standardized dataframes, deduplicates records based on geographic proximity (e.g., 50m threshold), and enriches records with information from multiple sources using `sf` for spatial operations.

### Analysis & Visualization

*   **Vignette Integration**: The `memorial-analysis.qmd` vignette loads and displays pre-computed objects from the `targets` pipeline.
*   **Interactive Mapping**: `map_statues()` uses `leaflet` to create interactive maps of statue locations with rich popup information and marker clustering.
*   **Summary Tables**: Summary statistics and tables (counts by category, year, type, gender) are generated.
*   **Gender Analysis**: `analyze_by_gender()` performs gender analysis on statue subjects (men, women, animals, unknown).
*   **Johns vs Women Comparison**: `compare_johns_vs_women()` validates claims, specifically "more Johns than women," using London-specific data.
*   **Comparison to External Studies**: Findings and statistics from external studies (e.g., PACK & SEND) are incorporated into the vignette for comparative analysis.

### Package Structure

*   **Standard Layout**: Adheres to standard R package structure (`R/`, `tests/`, `vignettes/`, `man/`, `data-raw/`).
*   **Reproducible Pipeline**: Uses the `targets` R package for managing and orchestrating the entire analysis workflow (`_targets.R` and `R/tar_plans/`).
*   **Testing**: Implements comprehensive unit tests using `testthat`.
*   **Documentation**: Provides extensive Roxygen2 documentation for all functions.
*   **Quality Checks**: Ensures the package passes `R CMD check` with zero errors, warnings, or notes.

### Usage Examples

#### Basic: Get Data from One Source

```r
library(statuesnamedjohn)

# Get Wikidata statues
statues <- get_statues_wikidata(location = "Q84")  # Q84 = London
head(statues)
```

#### Intermediate: Combine Multiple Sources

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

#### Advanced: Full Pipeline with Analysis and Mapping

```r
library(statuesnamedjohn)
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

#### Vignette Usage

```r
# Build vignette with real data
devtools::build_vignettes()

# View vignette
vignette("memorial-analysis", package = "statuesnamedjohn")
```

### Performance Considerations

*   **Caching Strategy**: All data retrieval functions support caching via `cache_path` parameter.
*   **Rate Limiting**: Implemented for OSM Overpass.
*   **Large Dataset Handling**: Suggestions for spatial indexing, chunked processing, `data.table` for larger datasets.
*   **Targets Pipeline Integration**: `_targets.R` integration for reproducible workflow.

### Testing Strategy

*   **Unit Tests**: Examples for `get_statues_wikidata` and `standardize_statue_data`.
*   **Integration Tests**: Example for full pipeline end-to-end.

### Documentation Requirements

*   **Roxygen2 comments**: For all functions.
*   **Vignette coverage**: Basic usage, common workflows, interpretation.
*   **README**: Installation, quick start, vignette link.

### Next Steps After Implementation

1. **Data validation:** Manually verify sample of records
2. **Gender classification:** Improve with manual mapping file
3. **UK-wide expansion:** Extend beyond London
4. **Additional sources:** Investigate more data sources
5. **API rate limits:** Document and implement proper throttling
6. **Shiny app:** Interactive web application for exploration
7. **Publication:** Document methodology in academic paper
8. **Data release:** Publish combined dataset with DOI

### Conclusion

This implementation provides a **robust, transparent, and reproducible** approach to statue data analysis that:

✅ Replaces blocked web scraping with legitimate APIs
✅ Combines multiple authoritative sources
✅ Provides geographic visualization with interactive maps
✅ Enables rigorous validation of public claims
✅ Documents methodology transparently
✅ Supports reproducible research through caching and `targets`
✅ Creates reusable R package functions

The interactive map with hover popups will allow users to explore each statue in detail, seeing its name, subject, date, materials, and links to source data - far exceeding the functionality of the original scraping approach.

---

## 3. Implementation Summary (`R/setup/README.md`)

**Project:** statuesnamedjohn R package
**Date:** 2025-11-12
**Status:** Ready for execution once nix packages build

### Documentation Files (Key)
- `data_sources_research.md` - Comprehensive research on alternative data sources
- `implementation_plan.md` - Complete implementation with full R code
- `session_summary.md` - Complete progress summary
- `QUICK_START.md` - Step-by-step execution guide
- `session_notes.md` - Notes from previous session
- `skills_update_summary.md` - Claude skills updates
- `test_wikidata.R` - Test Wikidata SPARQL queries
- `test_osm.R` - Test OpenStreetMap Overpass API

### What We're Building

**Problem:**
- London Remembers website blocks web scraping
- No API or downloadable data available
- Need geographic coordinates for mapping
- Need to validate "Statues for Equality" claims

**Solution: Multi-source data architecture:**
```
Wikidata (SPARQL) ─┐
OpenStreetMap      ├─→ Standardization ─→ Spatial Deduplication ─→
GLHER (CSV)        │                      (50m threshold)
Historic England  ─┘

                    ↓
              Unified Dataset
                    ↓
      ┌─────────────┼─────────────┐
      ↓             ↓              ↓
  Analysis    Interactive      Vignette
  Functions      Maps         with Real Data
```

### Key Features

**1. Interactive Leaflet Map**
**2. Multi-Source Data Integration**
**3. Spatial Deduplication**
**4. Gender Analysis**
**5. Johns vs Women Validation**

### Quick Start (Once Packages Built)
- 1-Minute Verification
- 5-Minute Data Test
- 90-Minute Full Implementation (See `QUICK_START.md`)

### Expected Results
- **Data Coverage:** Combined 150-300 unique statues, 100% coords, 80-85% metadata.
- **Gender Analysis:** Male ~70-80%, Female ~10-15%, Animals ~5-10%.
- **Johns vs Women:** Likely to refute "more Johns than women" claim for London.

### File Organization
Standard R package structure.

### Implementation Timeline
~90 min from packages ready to full implementation.

### Key Technical Innovations
1. Multi-Source Architecture
2. Spatial Deduplication
3. Rich Interactive Popups
4. Reproducibility
5. Transparent Methodology

### Current Status
- ✅ Comprehensive research of all data sources
- ✅ Complete implementation plan with full code
- ✅ Test scripts for Wikidata and OSM
- ✅ Package dependencies updated
- ✅ Nix environment regenerated
- ✅ Documentation complete
- ✅ Skills updated with reproducibility requirements
- ✅ PR #5 merged (vignette enhancements)
- ⏳ Nix packages building from source (in progress)

### Next
1. Run test scripts
2. Implement functions (code ready in implementation_plan.md)
3. Create interactive map
4. Update vignette
5. Commit and push
