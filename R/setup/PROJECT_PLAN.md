# Project Plan: londonremembers

## 1. Objective
Build an R package `londonremembers` to source and analyze data about statues in London, specifically to compare memorials for men named John, women, and dogs. The project aims to provide a transparent, reproducible, and interactive analysis of London's commemorative landscape, validating public claims with real data.

## 2. Core Requirements

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

## 3. Data Sources Strategy

The project adopts a multi-source, API-driven approach for London-specific data, supplemented by external studies for broader context.

### 3.1 Primary Data Sources for London Analysis

| Source                  | Method                            | Data Points (Key)                                         | Pros                                                                    | Cons                                                                                                                       |
| :---------------------- | :-------------------------------- | :-------------------------------------------------------- | :---------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| **Wikidata** (Preferred) | SPARQL queries via `WikidataQueryServiceR` | Subject (P21, P31), Location (P131), Creator (P170), Inception Date (P571), Coordinates (P625) | Highly structured, easy to filter by gender/name, links to Wikipedia.   | Might be incomplete for smaller/newer memorials.                                                                           |
| **OpenStreetMap (OSM)** | `osmdata` R package (Overpass API)    | Location (lat/long), Tags (`historic=memorial`, `memorial=statue`, `name=*`, `subject:wikidata=*`) | Excellent geospatial coverage, often links to Wikidata, detailed tags.    | Attribute data (like subject gender) not stored directly, requires linking or inference.                                   |
| **Historic England (GLHER)** | CSV download / Targeted Scraping | Location, type, name, description, period, lat/lon.       | Authoritative for listed structures, high data quality, precise coords. | Filtering for specific statue types can be broad; requires careful extraction.                                              |

### 3.2 Supplementary Data & Comparative Context

*   **PACK & SEND Study / Art UK Research**: Use findings from the PACK & SEND study (which analyzed Art UK data) to provide UK-wide context and compare against London-specific results, especially for claims like "more Johns than women."
*   **Other Studies**: Reference and compare findings with other relevant studies (e.g., Statues for Equality, Hyperallergic, BBC News, New Statesman).
*   **London Remembers / Art UK (Limited Scraping)**: Acknowledge these sources for rich descriptive text and photos. However, direct programmatic access (API) is unavailable, and web scraping is brittle. **Scraping is considered a supplementary/last-resort method for specific enrichment where data is missing from primary API sources, not a primary data acquisition strategy.**

### 3.3 Art UK: A Superior Source with Access Limitations

*   **Coverage**: Art UK is a definitive source with over 14,800 UK public sculptures, professionally curated.
*   **Access Challenges**: No public API, web requests are blocked (403 Forbidden) for automated access, and no bulk CSV/JSON downloads are available.
*   **Implication**: While superior, its programmatic access limitations necessitate focusing on London-specific analysis with available APIs (Wikidata, OSM, GLHER). PACK & SEND study findings will be used for UK-wide context.

## 4. Implementation Strategy (High-Level)

The implementation will follow a structured approach to acquire, process, and analyze statue data.

### 4.1 Data Acquisition

*   **Wikidata**: `fetch_wikidata_statues()` using `WikidataQueryServiceR` package to query SPARQL endpoint for statues in London (`Q84`), retrieving coordinates and metadata.
*   **OpenStreetMap**: `fetch_osm_statues()` using `osmdata` package to query Overpass API for `historic=memorial`, `memorial=statue`, `man_made=statue` within a London bounding box.
*   **Historic England (GLHER)**: `fetch_glher_data()` to download/process CSV exports for monuments.
*   **Caching**: Implement caching mechanisms for all data retrieval functions to minimize API calls and speed up development.

### 4.2 Data Processing

*   **Standardization**: `standardize_statue_data()` to convert raw data from all sources into a common, consistent schema (ID, name, subject, lat, lon, type, year, source, URL, etc.).
*   **Cleaning**: `clean_names()` to remove honorifics and dates from names. `clean_text()` for general text processing.
*   **Gender Classification**: `classify_gender()` using a heuristic first-name lookup table for common names, defaulting to "unknown" if not found or provided by Wikidata.
*   **Subject Classification**: `classify_subject()` to categorize memorials by reason (e.g., politician, artist).
*   **Geospatial Processing**: `extract_coords_from_wkt()` for WKT geometry strings.
*   **Merging & Deduplication**: `combine_statue_sources()` to merge standardized dataframes, deduplicate records based on geographic proximity (e.g., 50m threshold), and enrich records with information from multiple sources using `sf` for spatial operations.

### 4.3 Analysis & Visualization

*   **Vignette Integration**: Update `vignettes/memorial-analysis.qmd` to load and display pre-computed objects from the `targets` pipeline.
*   **Interactive Mapping**: `map_statues()` using `leaflet` to create interactive maps of statue locations with rich popup information (name, subject, year, material, sculptor, source URL, image) and marker clustering.
*   **Summary Tables**: Generate summary statistics and tables (counts by category, year, type, gender).
*   **Gender Analysis**: `analyze_by_gender()` to perform gender analysis on statue subjects (men, women, animals, unknown).
*   **Johns vs Women Comparison**: `compare_johns_vs_women()` to validate claims, specifically "more Johns than women," using London-specific data.
*   **Comparison to External Studies**: Incorporate findings and statistics from external studies (e.g., PACK & SEND) into the vignette for comparative analysis.

### 4.4 Package Structure

*   **Standard Layout**: Adhere to standard R package structure (`R/`, `tests/`, `vignettes/`, `man/`, `data-raw/`).
*   **Reproducible Pipeline**: Use the `targets` R package for managing and orchestrating the entire analysis workflow (`_targets.R` and `R/tar_plans/`).
*   **Testing**: Implement comprehensive unit tests using `testthat`.
*   **Documentation**: Provide extensive Roxygen2 documentation for all functions.
*   **Quality Checks**: Ensure the package passes `R CMD check` with zero errors, warnings, or notes.

## 5. Key Comparisons & Claims Validation

The project will critically examine and validate claims from campaigns such as "Statues for Equality" and findings from the PACK & SEND study.

*   **"More Johns than women"**: Analyze London-specific data to determine if the claim holds true for the capital, comparing results with UK-wide statistics from the PACK & SEND study (which found the claim to be false for the UK).
*   **Animal Representation**: Investigate claims regarding animal representation versus named women.

## 6. Required R Packages

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