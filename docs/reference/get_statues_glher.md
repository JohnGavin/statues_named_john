# Retrieve Statue Data from Greater London HER

Downloads CSV data from Greater London Historic Environment Record
(GLHER) for monuments tagged as statues or person memorials.

## Usage

``` r
get_statues_glher(
  query_terms = c("person", "statue"),
  resource_type = "Monument",
  max_results = 500,
  cache_path = NULL
)
```

## Arguments

- query_terms:

  Search terms (default: c("person", "statue"))

- resource_type:

  Resource type filter (default: "Monument")

- max_results:

  Maximum results to retrieve (default: 500)

- cache_path:

  Path to cache results (default: NULL)

## Value

A tibble with columns: glher_id, name, description, type, lat, lon,
period, url

## Details

GLHER provides professional heritage data with high quality metadata and
precise coordinates. The CSV export is accessed via URL parameters.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get person statues from GLHER
glher_statues <- get_statues_glher()

# Get all monument types
glher_monuments <- get_statues_glher(
  query_terms = NULL,
  max_results = 1000
)
} # }
```
