# Retrieve Statue Data from Wikidata

Queries Wikidata SPARQL endpoint for statues in a specified location
with geographic coordinates and metadata.

## Usage

``` r
get_statues_wikidata(location = "Q84", limit = 1000, cache_path = NULL)
```

## Arguments

- location:

  Wikidata ID for location (default: "Q84" for London)

- limit:

  Maximum number of results (default: 1000)

- cache_path:

  Path to cache results (default: NULL for no caching)

## Value

A tibble with columns: wikidata_id, name, subject, lat, lon,
inception_date, material, creator, image_url, wikipedia_url

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all London statues from Wikidata
london_statues <- get_statues_wikidata(location = "Q84")

# Get statues with caching
london_statues <- get_statues_wikidata(
  location = "Q84",
  cache_path = "data-raw/wikidata_cache.rds"
)
} # }
```
