# SOLUTION: Generic HTTP Packages Work!

**Date:** 2025-11-12
**Status:** ✅ UNBLOCKED

---

## Problem Solved

The specialized R packages (WikidataQueryServiceR, osmdata, sf, leaflet) are **not available in nixpkgs**.

## Solution: Use Generic HTTP Packages

Instead of specialized packages, we use **generic HTTP tools that ARE available in nix**:

| Generic Package | Purpose | Nix Status |
|-----------------|---------|------------|
| **httr2** | HTTP requests | ✅ Available |
| **jsonlite** | JSON parsing | ✅ Available |
| **xml2** | XML parsing | ✅ Available |
| **rvest** | HTML scraping | ✅ Available |
| **curl** | Low-level HTTP | ✅ Available |

---

## Proof of Concept: Wikidata ✅

**Test Script:** `R/setup/test_wikidata_simple.R`

**Results:**
- ✅ Successfully retrieved **26 London statues** from Wikidata
- ✅ 100% with coordinates (26/26)
- ✅ 92% with Wikipedia articles (24/26)
- ✅ 96% with creator info (25/26)
- ✅ 88% with material info (23/26)

**Sample Data:**
```
name                          subject      lat     lon
Our Lady of Westminster       <NA>       51.496  -0.139
Machine Gun Corps Memorial    sword      51.503  -0.151
Machine Gun Corps Memorial    wreath     51.503  -0.151
```

**Code Approach:**
```r
library(httr2)
library(jsonlite)

# SPARQL query
response <- request("https://query.wikidata.org/sparql") %>%
  req_url_query(query = sparql_query, format = "json") %>%
  req_perform()

# Parse JSON
data <- response %>%
  resp_body_string() %>%
  fromJSON()

# Extract results
results <- data$results$bindings
```

---

## OpenStreetMap: Concept Proven

**Test Script:** `R/setup/test_osm_simple.R`

**Results:**
- ✅ Successfully queried Overpass API
- ✅ Retrieved **2,496 features** from OpenStreetMap
- ⏳ Data structure needs refinement (complex nested JSON)

**Code Approach:**
```r
library(httr2)
library(jsonlite)

# Overpass QL query
response <- request("https://overpass-api.de/api/interpreter") %>%
  req_body_form(data = overpass_query) %>%
  req_perform()

# Parse JSON
data <- response %>%
  resp_body_string() %>%
  fromJSON()

results <- data$elements
```

---

## Why This Works Better

### vs Specialized Packages:
- ✅ **No nix dependency issues** - generic packages already in nixpkgs
- ✅ **Direct API access** - no intermediary library
- ✅ **Transparent** - see exactly what HTTP requests are made
- ✅ **Maintainable** - fewer moving parts

### API Endpoints Used:
1. **Wikidata SPARQL:** `https://query.wikidata.org/sparql`
2. **OSM Overpass:** `https://overpass-api.de/api/interpreter`
3. **GLHER:** Can use rvest for HTML scraping or direct CSV downloads

---

## Implementation Path Forward

### 1. Wikidata Function (Ready)

```r
get_statues_wikidata <- function(limit = 100) {
  library(httr2)
  library(jsonlite)

  sparql_query <- paste0('
    SELECT ?statue ?statueLabel ?coords ?subjectLabel ...
    WHERE {
      ?statue wdt:P31 wd:Q179700.  # Instance of statue
      ?statue wdt:P131+ wd:Q84.     # Located in London
      ?statue wdt:P625 ?coords.     # Has coordinates
      ...
    }
    LIMIT ', limit)

  response <- request("https://query.wikidata.org/sparql") %>%
    req_url_query(query = sparql_query, format = "json") %>%
    req_user_agent("LondonRemembersR/1.0") %>%
    req_perform()

  data <- response %>%
    resp_body_string() %>%
    fromJSON()

  return(data$results$bindings)
}
```

### 2. OSM Function (Needs Refinement)

```r
get_statues_osm <- function(bbox = "51.28676,-0.510375,51.691874,0.334015") {
  library(httr2)
  library(jsonlite)

  overpass_query <- paste0('
    [out:json][timeout:25];
    (
      node["memorial"="statue"](', bbox, ');
      way["memorial"="statue"](', bbox, ');
    );
    out center;
  ')

  response <- request("https://overpass-api.de/api/interpreter") %>%
    req_body_form(data = overpass_query) %>%
    req_timeout(60) %>%
    req_perform()

  data <- response %>%
    resp_body_string() %>%
    fromJSON()

  return(data$elements)
}
```

### 3. Mapping (Without leaflet)

Since `leaflet` isn't available, we can:

**Option A: Basic HTML map with JavaScript**
```r
create_simple_map <- function(statues) {
  html <- paste0('
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
</head>
<body>
  <div id="map" style="height: 600px"></div>
  <script>
    var map = L.map("map").setView([51.5074, -0.1278], 11);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png").addTo(map);

    var statues = ', toJSON(statues), ';

    statues.forEach(function(s) {
      L.marker([s.lat, s.lon])
        .bindPopup("<b>" + s.name + "</b><br>" + s.subject)
        .addTo(map);
    });
  </script>
</body>
</html>
  ')

  writeLines(html, "london_statues_map.html")
}
```

**Option B: Use plotly** (if available in nix)
```r
library(plotly)

plot_ly(statues,
  lat = ~lat,
  lon = ~lon,
  text = ~name,
  type = "scattermapbox",
  mode = "markers"
) %>%
  layout(mapbox = list(
    style = "open-street-map",
    center = list(lat = 51.5074, lon = -0.1278),
    zoom = 10
  ))
```

---

## Key Takeaways

1. **Generic >> Specialized** for nix environments
2. **Direct API access** is simpler than wrapper packages
3. **HTTP + JSON** solves 90% of data retrieval needs
4. **JavaScript mapping** works without R leaflet package

---

## Next Steps

### Immediate (Now):
1. ✅ Wikidata retrieval working (26 statues)
2. ⏳ Refine OSM data extraction
3. ⏳ Create simple HTML map with JavaScript

### Short-term (Next hour):
1. Write production `get_statues_wikidata()` function
2. Fix OSM data structure handling
3. Create interactive map generator
4. Document functions with roxygen2

### Medium-term (Future):
1. Add GLHER data source
2. Implement spatial deduplication (pure R, no sf)
3. Add gender analysis functions
4. Update vignette with real data

---

## Files Created

- ✅ `R/setup/test_wikidata_simple.R` - Working Wikidata test
- ✅ `R/setup/wikidata_london_statues_simple.rds` - 26 statues retrieved
- ⏳ `R/setup/test_osm_simple.R` - OSM test (needs refinement)
- ✅ `R/setup/SOLUTION.md` - This document

---

## Credit

**User insight:** "Why not use generic HTTP packages instead of specialized ones?"

This simple question unblocked hours of struggling with nix package availability. The solution was hiding in plain sight - we already had all the tools we needed!

---

**Status:** UNBLOCKED - Can proceed with implementation using httr2 + jsonlite + xml2
