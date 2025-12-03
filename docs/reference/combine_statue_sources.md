# Combine and Deduplicate Statue Data from Multiple Sources

Merges statue data from multiple sources, deduplicates based on
geographic proximity, and enriches records with data from multiple
sources.

## Usage

``` r
combine_statue_sources(
  source_list,
  distance_threshold = 50,
  prefer_sources = c("glher", "wikidata", "osm", "he")
)
```

## Arguments

- source_list:

  Named list of standardized data frames, e.g. list(wikidata = wd_data,
  osm = osm_data, glher = glher_data)

- distance_threshold:

  Distance in meters for considering records as duplicates (default: 50)

- prefer_sources:

  Vector of source names in order of preference for resolving conflicts
  (default: c("glher", "wikidata", "osm", "he"))

## Value

A tibble with combined, deduplicated statue data, with additional
columns: - sources: character - comma-separated list of contributing
sources - n_sources: integer - number of sources contributing data -
is_multi_source: logical - TRUE if data from multiple sources -
duplicate_ids: character - IDs of duplicate records that were merged

## Examples

``` r
if (FALSE) { # \dontrun{
# Get data from all sources
wd <- get_statues_wikidata() %>% standardize_statue_data("wikidata")
osm <- get_statues_osm() %>% standardize_statue_data("osm")
glher <- get_statues_glher() %>% standardize_statue_data("glher")

# Combine
all_statues <- combine_statue_sources(
  list(wikidata = wd, osm = osm, glher = glher)
)
} # }
```
