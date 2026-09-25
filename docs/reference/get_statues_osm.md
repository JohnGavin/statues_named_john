# Retrieve Statue Data from OpenStreetMap

Queries OpenStreetMap Overpass API for statues and memorials using
multiple OSM tags to maximize coverage.

Fails fast (#90): any query that cannot be completed aborts the whole
call immediately, rather than being downgraded to a warning and
returning partial data. Each request is bounded (see
`osm_fetch_features()`), so a network outage surfaces in seconds, not
after osmdata's internal ten-try retry loop.

## Usage

``` r
get_statues_osm(
  bbox = c(-0.510375, 51.28676, 0.334015, 51.691874),
  tags = list(list(key = "memorial", value = "statue"), list(key = "memorial", value =
    "animal"), list(key = "historic", value = "memorial"), list(key = "man_made", value =
    "statue")),
  cache_path = NULL,
  pause = 2
)
```

## Arguments

- bbox:

  Bounding box (min_lon, min_lat, max_lon, max_lat). Default is Greater
  London.

- tags:

  OSM tags to query. Default includes memorial=statue,
  historic=memorial, man_made=statue

- cache_path:

  Path to cache results (default: NULL)

- pause:

  Seconds to wait between queries, to be polite to the Overpass API
  (default: 2)

## Value

A tibble with columns: osm_id, osm_type, name, subject, lat, lon,
memorial_type, historic_type, man_made_type, material, wikipedia, source

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all London statues from OSM
london_statues_osm <- get_statues_osm()

# Custom bounding box (Westminster)
westminster_bbox <- c(-0.1773, 51.4899, -0.1131, 51.5155)
westminster_statues <- get_statues_osm(bbox = westminster_bbox)
} # }
```
