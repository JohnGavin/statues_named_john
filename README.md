

# statuesnamedjohn: Multi-Source Analysis of London Statues

> In England’s grand capital, dear,<br> More Johns than dames, it
> appears.<br> For each woman of might,<br> A John’s in plain sight,<br>
> Confirming our gendered-statue fears.

<!-- badges: start -->

[![R-CMD-check](https://github.com/JohnGavin/statues_named_john/workflows/R-CMD-check/badge.svg)](https://github.com/JohnGavin/statues_named_john/actions)
[![codecov](https://codecov.io/gh/JohnGavin/statues_named_john/branch/main/graph/badge.svg)](https://codecov.io/gh/JohnGavin/statues_named_john)
<!-- badges: end -->

The `statuesnamedjohn` R package provides a robust framework for
analyzing London’s commemorative landscape. Moving beyond single data
sources, it integrates information from authoritative APIs to create a
comprehensive dataset.

**Key Capabilities:** \* **Multi-Source Integration:** Combines data
from Wikidata, OpenStreetMap, and Historic England. \* **Gender
Analysis:** Facilitates validation of public claims (e.g., “more Johns
than women”). \* **Interactive Mapping:** Visualizes data with rich,
clustered Leaflet maps. \* **Reproducibility:** Built on a Nix-based,
target-driven pipeline.

## Installation

You can install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("JohnGavin/statues_named_john")
```

**Note on Nix Environment:** This project is developed within a Nix
environment to ensure full reproducibility and consistent package
management. It is highly recommended to use the provided Nix
configuration (`default.nix`) to set up your development environment.
This will ensure all necessary R packages (e.g.,
`WikidataQueryServiceR`, `osmdata`, `sf`, `leaflet`) and system
dependencies are correctly installed. Refer to the `default.nix` and
`QUICK_START_GUIDE.md` for details on setting up and using the Nix
shell.

## Features

The `statuesnamedjohn` package offers a comprehensive suite of
functionalities for exploring London’s commemorative landscape:

- **Multi-Source Data Retrieval**: Seamlessly acquire statue and
  memorial data from Wikidata, OpenStreetMap, and GLHER APIs.
- **Data Standardization & Deduplication**: Standardize diverse data
  formats into a common schema and intelligently deduplicate records
  based on geographic proximity using spatial algorithms.
- **Interactive Mapping**: Generate rich interactive Leaflet maps
  displaying statue locations with detailed pop-ups (name, subject,
  year, material, sculptor, image, and source links) and marker
  clustering for optimal visualization.
- **Gender Analysis**: Analyze the representation of genders among
  commemorated subjects, enabling critical validation of public claims
  (e.g., “more statues of men named John than women”).
- **Reproducible Workflow**: Built with reproducibility in mind,
  leveraging caching, `targets` pipelines, and a transparent
  methodology.

## Data Sources

This package leverages a robust multi-source data acquisition strategy
to build a comprehensive dataset of London’s statues and memorials. This
approach ensures broader coverage, higher data quality, and improved
reproducibility compared to single-source methods.

**Primary Data Sources:**

- **Wikidata**: Structured linked open data, queried via its SPARQL
  endpoint. Provides rich metadata on subjects, creators, and precise
  geographic coordinates.
- **OpenStreetMap (OSM)**: Community-contributed geographic data,
  accessed via the Overpass API. Excellent for detailed location
  information and various memorial tags.
- **Greater London Historic Environment Record (GLHER)**: Professional
  heritage data, accessed via CSV exports. Offers authoritative records
  with high data quality.

**Note on `londonremembers.com`:** While initially a source of interest,
direct programmatic access (e.g., web scraping) to `londonremembers.com`
proved unfeasible due to its JavaScript-rendered content and lack of a
public API. This project thus pivots to the above API-driven sources to
ensure reliability and reproducibility.

This multi-source strategy allows for spatial deduplication and
intelligent merging of records, creating a unified and enriched dataset
for analysis.

## Usage

The `statuesnamedjohn` package simplifies the process of acquiring,
processing, and analyzing statue data. Below are basic examples to get
started. For a comprehensive guide, refer to the project vignette.

``` r
library(statuesnamedjohn)
library(dplyr)
library(ggplot2)
library(leaflet) # For viewing the map

# 1. Retrieve data from multiple sources (with caching)
#    These functions query the respective APIs
wikidata_data <- get_statues_wikidata(location = "Q84", cache_path = "data-raw/wikidata_cache.rds")
osm_data <- get_statues_osm(bbox = c(-0.510375, 51.28676, 0.334015, 51.691874), cache_path = "data-raw/osm_cache.rds")
glher_data <- get_statues_glher(cache_path = "data-raw/glher_cache.rds")

# 2. Standardize data to a common schema
wikidata_std <- standardize_statue_data(wikidata_data, "wikidata")
osm_std <- standardize_statue_data(osm_data, "osm")
glher_std <- standardize_statue_data(glher_data, "glher")

# 3. Combine and deduplicate the data
all_statues <- combine_statue_sources(
  list(wikidata = wikidata_std, osm = osm_std, glher = glher_std),
  distance_threshold = 50 # meters
)

message("Total unique statues identified: ", nrow(all_statues))
# Example: Total unique statues identified: 250

# 4. Perform gender analysis
gender_results <- analyze_by_gender(all_statues)
print(gender_results$summary)
# Example output:
#   inferred_gender     n percent
# 1            Male   180    72.0
# 2          Female    50    20.0
# 3         Unknown    15     6.0
# 4          Animal     5     2.0

# 5. Validate claims (e.g., "more Johns than women")
johns_vs_women <- compare_johns_vs_women(all_statues)
message(johns_vs_women$message)
# Example: Found 20 statues named John (8.0%) vs 50 women statues (20.0%).
message("Claim 'more Johns than women' validated (False if Johns <= Women): ", johns_vs_women$claim_validated)
# Example: Claim 'more Johns than women' validated (False if Johns <= Women): FALSE

# 6. Create an interactive map
statue_map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "source",
  cluster = TRUE
)
statue_map # Display the map in RStudio Viewer or browser
# htmlwidgets::saveWidget(statue_map, "london_statues_map.html") # To save to HTML file
```

## Vignettes

For a comprehensive walkthrough of the data acquisition, processing,
analysis, and interactive mapping, please refer to the project’s main
vignette. It provides detailed explanations and examples of the
package’s functionalities.

``` r
vignette("memorial-analysis", package = "statuesnamedjohn")
```

You can also view the deployed vignette directly on GitHub Pages:
<https://johngavin.github.io/statues_named_john/articles/memorial-analysis.html>

## Developer Documentation

For detailed information on the project’s architecture, research, and
internal guidelines, please refer to the following documents:

- [**Project Overview**](R/setup/PROJECT_OVERVIEW.md): Comprehensive
  guide to the project plan and implementation details.
- [**Developer Workflow**](DEVELOPER_WORKFLOW.md): Guide for developers
  on the targets-based workflow and pre-built vignettes.
- [**Agent Guidelines**](AGENTS.md): Internal workflow standards and
  reproducibility requirements.
- [**Quick Start Guide**](R/setup/QUICK_START_GUIDE.md): Step-by-step
  guide for setting up and running the project pipeline.
- [**GitHub
  Wiki**](https://github.com/JohnGavin/statues_named_john/wiki): Check
  the repository Wiki for FAQs, technical journals, and package
  evaluations.

## License

MIT
