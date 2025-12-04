#!/usr/bin/env Rscript
# Create simple interactive HTML map from Wikidata results

library(jsonlite)

message("=== Creating Interactive Map from Wikidata Results ===")

# Load Wikidata results
results <- readRDS("R/setup/wikidata_london_statues_simple.rds")

message("Loaded ", nrow(results), " statues from Wikidata")

# Prepare data for JavaScript
statues_data <- data.frame(
  name = results$statueLabel$value,
  subject = ifelse(!is.na(results$subjectLabel$value),
                   results$subjectLabel$value,
                   "Unknown subject"),
  lat = results$lat,
  lon = results$lon,
  material = ifelse(!is.na(results$materialLabel$value),
                    results$materialLabel$value,
                    "Unknown material"),
  creator = ifelse(!is.na(results$creatorLabel$value),
                   results$creatorLabel$value,
                   "Unknown creator"),
  date = ifelse(!is.na(results$inceptionDate$value),
                results$inceptionDate$value,
                "Unknown date"),
  wikipedia = ifelse(!is.na(results$article$value),
                     results$article$value,
                     ""),
  wikidata = results$statue$value,
  stringsAsFactors = FALSE
)

# Remove any rows without coordinates
statues_data <- statues_data[!is.na(statues_data$lat) & !is.na(statues_data$lon), ]

message("Creating map with ", nrow(statues_data), " statues with coordinates")

# Convert to JSON for JavaScript
statues_json <- toJSON(statues_data, pretty = TRUE)

# Create HTML with embedded Leaflet map
html_content <- paste0('
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>London Statues - Wikidata</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- Leaflet CSS -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
    integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
    crossorigin=""/>

  <!-- Leaflet JS -->
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
    integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
    crossorigin=""></script>

  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #map {
      position: absolute;
      top: 60px;
      bottom: 0;
      width: 100%;
    }
    .header {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 60px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 0 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      z-index: 1000;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
    }
    .header .stats {
      font-size: 14px;
      opacity: 0.9;
    }
    .popup-content h3 {
      margin: 0 0 10px 0;
      color: #667eea;
    }
    .popup-content p {
      margin: 5px 0;
      font-size: 14px;
    }
    .popup-content strong {
      color: #555;
    }
    .popup-content a {
      color: #667eea;
      text-decoration: none;
    }
    .popup-content a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🗿 London Statues from Wikidata</h1>
    <div class="stats">
      <span id="statue-count">0</span> statues |
      Data: <a href="https://www.wikidata.org" target="_blank" style="color: white;">Wikidata</a>
    </div>
  </div>

  <div id="map"></div>

  <script>
    // Initialize map centered on London
    var map = L.map("map").setView([51.5074, -0.1278], 11);

    // Add OpenStreetMap tile layer
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: \'&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors\',
      maxZoom: 19
    }).addTo(map);

    // Statue data from R
    var statues = ', statues_json, ';

    // Update count
    document.getElementById("statue-count").textContent = statues.length;

    // Add markers for each statue
    statues.forEach(function(statue) {
      // Create popup content
      var popupContent = `
        <div class="popup-content">
          <h3>${statue.name}</h3>
          <p><strong>Subject:</strong> ${statue.subject}</p>
          <p><strong>Material:</strong> ${statue.material}</p>
          <p><strong>Creator:</strong> ${statue.creator}</p>
          <p><strong>Date:</strong> ${statue.date}</p>
          ${statue.wikipedia ? `<p><strong>Wikipedia:</strong> <a href="${statue.wikipedia}" target="_blank">View article</a></p>` : \'\'}
          <p><strong>Wikidata:</strong> <a href="${statue.wikidata}" target="_blank">View entry</a></p>
        </div>
      `;

      // Create marker with popup
      L.marker([statue.lat, statue.lon])
        .bindPopup(popupContent, { maxWidth: 300 })
        .bindTooltip(statue.name, { direction: "top", offset: [0, -10] })
        .addTo(map);
    });

    console.log("Loaded", statues.length, "statues");
  </script>
</body>
</html>
')

# Write HTML file
output_file <- "R/setup/london_statues_map.html"
writeLines(html_content, output_file)

message("\n✓ Interactive map created!")
message("  File: ", output_file)
message("  Statues: ", nrow(statues_data))
message("\nOpen in browser to view the map")
message("  open ", output_file)
