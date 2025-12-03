# Retrieve Statue Data from OpenStreetMap

Queries OpenStreetMap Overpass API for statues and memorials using
multiple OSM tags to maximize coverage.

## Usage

``` r
get_statues_osm(
  bbox = c(-0.510375, 51.28676, 0.334015, 51.691874),
  tags = list(list(key = "memorial", value = "statue"), list(key = "historic", value =
    "memorial"), list(key = "man_made", value = "statue")),
  cache_path = NULL
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

## Value

A tibble with columns: osm_id, osm_type, name, subject, lat, lon,
memorial_type, historic_type, tags_list

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
