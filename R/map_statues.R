#' Create Interactive Map of Statues with Popup Information
#'
#' @description
#' Creates an interactive Leaflet map showing statue locations with
#' rich popup information that appears on hover or click.
#'
#' @param statue_data A tibble of statue data (standardized format)
#' @param popup_fields Vector of column names to include in popup
#' @param color_by Column name to use for color coding (default: "source")
#' @param cluster Whether to use marker clustering (default: TRUE)
#' @param tiles Map tile provider (default: "OpenStreetMap")
#'
#' @return A leaflet map object
#'
#' @examples
#' \dontrun{
#' # Get and combine data
#' all_statues <- get_all_statue_data()
#'
#' # Create interactive map
#' map <- map_statues(all_statues)
#' map  # Display in viewer/browser
#'
#' # Customize popup fields
#' map2 <- map_statues(
#'   all_statues,
#'   popup_fields = c("name", "subject", "year_installed", "material"),
#'   color_by = "type"
#' )
#'
#' # Save to HTML
#' htmlwidgets::saveWidget(map2, "london_statues_map.html")
#' }
#'
#' @export
map_statues <- function(statue_data,
                        popup_fields = c("name", "subject", "year_installed",
                                          "material", "sculptor", "source_url"),
                        color_by = "source",
                        cluster = TRUE,
                        tiles = "OpenStreetMap") {

  # Remove records without coordinates
  mapped_data <- statue_data %>%
    dplyr::filter(!is.na(lat), !is.na(lon))

  message("Mapping ", nrow(mapped_data), " statues with coordinates")

  # Create color palette
  if (color_by %in% names(mapped_data)) {
    unique_values <- unique(mapped_data[[color_by]])
    colors <- leaflet::colorFactor(
      palette = "Set1",
      domain = unique_values
    )
    marker_color <- colors(mapped_data[[color_by]])
  } else {
    marker_color <- "blue"
  }

  # Create popups
  popups <- create_statue_popups(mapped_data, popup_fields)

  # Initialize map
  map <- leaflet::leaflet(mapped_data) %>%
    leaflet::addProviderTiles(tiles)

  # Add markers
  if (cluster) {
    map <- map %>%
      leaflet::addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        radius = 6,
        color = marker_color,
        fillOpacity = 0.7,
        popup = popups,
        label = ~name,
        clusterOptions = leaflet::markerClusterOptions()
      )
  } else {
    map <- map %>%
      leaflet::addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        radius = 6,
        color = marker_color,
        fillOpacity = 0.7,
        popup = popups,
        label = ~name
      )
  }

  # Add legend if coloring by a variable
  if (color_by %in% names(mapped_data) && is.factor(mapped_data[[color_by]])) {
    map <- map %>%
      leaflet::addLegend(
        position = "bottomright",
        pal = colors,
        values = mapped_data[[color_by]],
        title = tools::toTitleCase(gsub("_", " ", color_by))
      )
  }

  return(map)
}

# Helper function: Create HTML popups
create_statue_popups <- function(data, fields) {
  popups <- apply(data, 1, function(row) {
    popup_html <- "<div style='max-width: 300px;'>"

    # Title
    if (!is.na(row["name"]) && row["name"] != "") {
      popup_html <- paste0(
        popup_html,
        "<h4 style='margin-bottom: 5px;'>", row["name"], "</h4>"
      )
    }

    # Fields
    for (field in fields) {
      if (field %in% names(row) && !is.na(row[field]) && row[field] != "") {
        label <- tools::toTitleCase(gsub("_", " ", field))

        # Special handling for URLs
        if (grepl("url$", field, ignore.case = TRUE)) {
          value <- sprintf("<a href='%s' target='_blank'>View Source</a>",
                           row[field])
        } else {
          value <- row[field]
        }

        popup_html <- paste0(
          popup_html,
          "<p style='margin: 3px 0;'><strong>", label, ":</strong> ",
          value, "</p>"
        )
      }
    }

    # Add image if available
    if ("image_url" %in% names(row) && !is.na(row["image_url"]) && row["image_url"] != "") {
      popup_html <- paste0(
        popup_html,
        "<img src='", row["image_url"], "' ",
        "style='width: 100%; max-height: 200px; object-fit: cover; margin-top: 5px;'>"
      )
    }

    popup_html <- paste0(popup_html, "</div>")
    return(popup_html)
  })

  return(popups)
}