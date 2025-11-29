# Project Plan: londonremembers (What)

**Objective**: Build an R package `londonremembers` to source and analyze data about statues in London, specifically to compare memorials for men named John, women, and dogs.

**Proposed Data Sources:**
*   **Wikidata** (Primary for structured analysis: gender, subject names, artists).
*   **OpenStreetMap** (Primary for location/mapping).
*   **London Remembers / Art UK** (Supplementary via scraping).
*   **Historic England** (Supplementary for listing status).

**Plan:**
1.  **Data Acquisition**:
    *   Fetch London statues from Wikidata using SPARQL queries (via `httr`).
    *   Fetch `historic=memorial` + `memorial=statue` data from OpenStreetMap (via `httr`).
    *   Scrape Art UK and London Remembers for supplementary enrichment data.
2.  **Data Processing**:
    *   Clean and normalize data from all sources into a single tidy format.
    *   Categorize subjects into target groups: "Men named John", "Women", "Dogs", "Other".
    *   Extract and standardize dates, artist info, and location data.
3.  **Analysis & Visualization**:
    *   Create the `memorial-analysis` vignette.
    *   Generate summary tables (counts by category, year, type).
    *   Create static maps showing distribution of memorials (using `ggplot2` + `sf`).
    *   Compare results with external studies (e.g., "Statues for Equality").
4.  **Package Structure**:
    *   Ensure standard R package structure (`R/`, `tests/`, `vignettes/`).
    *   Use `targets` for reproducible analysis pipelines.
    *   Implement unit tests.
    *   Pass `R CMD check`.

**Required R Packages:**

| Purpose | Package | Summary |
| :--- | :--- | :--- |
| **Analysis & Reporting** | `ggplot2` | For creating static maps and visualizations |
| | `knitr` | For dynamic report generation |
| | `rmarkdown` | For authoring vignettes |
| | `targets` | For reproducible analysis pipelines |
| | `tarchetypes` | Helpers for targets pipelines |
| **Data Acquisition** | `httr` | For HTTP requests to APIs (Wikidata/OSM) and websites |
| | `rvest` | For web scraping HTML pages |
| **Data Processing** | `dplyr` | For data manipulation |
| | `purrr` | For functional programming/iteration |
| | `stringr` | For string manipulation (names, cleaning) |
| | `tibble` | For modern data frames |
| **Geospatial** | `sf` | For handling geospatial data (simple features) |
| **Testing** | `testthat` | For unit testing |

**Package List:**
"dplyr", "ggplot2", "httr", "knitr", "purrr", "rmarkdown", "rvest", "sf", "stringr", "tarchetypes", "targets", "testthat", "tibble"
