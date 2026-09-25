# Create Interactive Map of Statues with Popup Information

Creates an interactive Leaflet map showing statue locations with rich
popup information that appears on hover or click.

## Usage

``` r
map_statues(
  statue_data,
  popup_fields = c("name", "subject", "year_installed", "material", "sculptor",
    "source_url"),
  color_by = "source",
  cluster = TRUE,
  tiles = "OpenStreetMap"
)
```

## Arguments

- statue_data:

  A tibble of statue data (standardized format)

- popup_fields:

  Vector of column names to include in popup

- color_by:

  Column name to use for color coding (default: "source")

- cluster:

  Whether to use marker clustering (default: TRUE)

- tiles:

  Map tile provider (default: "OpenStreetMap")

## Value

A leaflet map object

## Examples

``` r
if (FALSE) { # \dontrun{
# Get and combine data
all_statues <- get_all_statue_data()

# Create interactive map
map <- map_statues(all_statues)
map  # Display in viewer/browser

# Customize popup fields
map2 <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "type"
)

# Save to HTML
htmlwidgets::saveWidget(map2, "london_statues_map.html")
} # }
```
