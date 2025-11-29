# Implementation Strategy: londonremembers (How)

**Implementation Strategy (Bullet Summary):**
*   **`R/data_sources.R`**: 
    *   Update `fetch_wikidata_statues()` to use `httr::GET` with a raw SPARQL query string, handling JSON parsing manually to avoid `WikidataQueryServiceR` dependency.
    *   Update `fetch_osm_statues()` to use `httr::POST` against the Overpass API (`https://overpass-api.de/api/interpreter`) with an Overpass QL query for `node/way/relation["historic"="memorial"]["memorial"="statue"]`.
    *   Investigate and fix 403 errors in `fetch_art_uk_data()` (potential user-agent issue or blocking).
*   **`R/cleaning.R`**: 
    *   Implement `clean_names()` using regex to remove honorifics (Sir, Dame, etc.) and dates.
    *   Implement `classify_gender()` using a heuristic first-name lookup table for common names, defaulting to "unknown" if not found or provided by Wikidata.
    *   Implement `is_man_named_john()` to strictly filter for "John", "Jon", "Jonathan".
*   **`_targets.R`**: 
    *   Define a pipeline using `tar_plan()`:
        *   `tar_target(wikidata_raw, fetch_wikidata_statues())`
        *   `tar_target(osm_raw, fetch_osm_statues())`
        *   `tar_target(combined_data, join_and_clean_data(wikidata_raw, osm_raw))`
        *   `tar_target(analysis_summary, generate_summary_stats(combined_data))`
        *   `tar_render(vignette, "vignettes/memorial-analysis.Rmd")`
*   **`vignettes/memorial-analysis.Rmd`**: 
    *   Load `combined_data` from targets.
    *   Use `ggplot2` + `sf` (via `geom_sf`) for static mapping of statue locations.
    *   Create bar charts comparing counts of "Johns", "Women", and "Dogs".
