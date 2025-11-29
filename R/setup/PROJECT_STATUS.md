# Project Status: UK Statues Analysis - Multi-Source Data Retrieval

**Date:** 2025-11-12
**Status:** ✅ **MAJOR MILESTONE ACHIEVED**

---

## Quick Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Data Retrieval** | ✅ Working | Wikidata: 26 statues retrieved |
| **Interactive Map** | ✅ Complete | HTML with 26 markers + popups |
| **Nix Environment** | ✅ Stable | Using generic HTTP packages |
| **Documentation** | ✅ Comprehensive | 9 files created |
| **OSM Integration** | ⏳ In Progress | API works, needs parsing |
| **Production Code** | ⏳ Next Phase | Test scripts ready to productionize |

---

## What Works Right Now

### 1. Wikidata Data Retrieval ✅

**Command to run:**
```bash
nix-shell --run "Rscript R/setup/test_wikidata_simple.R"
```

**Output:**
- 26 London statues with full metadata
- 100% with coordinates
- Saved to: `R/setup/wikidata_london_statues_simple.rds`

### 2. Interactive Map Generation ✅

**Command to run:**
```bash
nix-shell --run "Rscript R/setup/create_simple_map.R"
```

**Output:**
- Standalone HTML file: `R/setup/london_statues_map.html`
- Features: markers, tooltips, popups, links
- Opens in any browser

**To view:**
```bash
open R/setup/london_statues_map.html
```

### 3. Complete Workflow ✅

**End-to-end pipeline:**
```bash
# Get data
nix-shell --run "Rscript R/setup/test_wikidata_simple.R"

# Create map
nix-shell --run "Rscript R/setup/create_simple_map.R"

# View result
open R/setup/london_statues_map.html
```

---

## Technical Solution

### The Breakthrough

**Problem:** Specialized R packages not in nixpkgs
**Solution:** Use generic HTTP packages that ARE available

### Packages Used

| Package | Purpose | Version | Status |
|---------|---------|---------|--------|
| httr2 | HTTP requests | Available | ✅ |
| jsonlite | JSON parsing | Available | ✅ |
| xml2 | XML parsing | Available | ✅ |
| rvest | HTML scraping | Available | ✅ |
| curl | Low-level HTTP | Available | ✅ |

### Why This Works

1. **Direct API access** - no wrapper layers
2. **Nix-friendly** - generic tools always available
3. **Transparent** - see exactly what's happening
4. **Maintainable** - fewer dependencies
5. **Portable** - works anywhere with HTTP

---

## Data Sources

### 1. Wikidata (Working) ✅

**API:** SPARQL endpoint at `https://query.wikidata.org/sparql`

**What we retrieve:**
- Statue names and subjects
- Geographic coordinates (lat/lon)
- Materials, creators, dates
- Wikipedia links
- Wikidata IDs

**Current results:** 26 London statues

### 2. OpenStreetMap (Proven) ⏳

**API:** Overpass at `https://overpass-api.de/api/interpreter`

**What we can retrieve:**
- Memorial tags (statue, memorial)
- Geographic coordinates
- Names and descriptions
- Links to Wikidata/Wikipedia

**Current status:** 2,496 features retrieved, needs JSON parsing

### 3. Art UK (Reference) 📚

**Source:** https://artuk.org/

**Coverage:** 14,800+ UK public sculptures

**Status:** No API available, used for context via PACK & SEND study

**Key statistics:**
- Total women statues: 351
- Named women: 128
- Men named "John": 82
- **Verdict:** More women than Johns (claim is FALSE for UK)

---

## Files Created This Session

### Documentation (7 files)

1. **`art_uk_research.md`** - Art UK as gold standard source
   - 14,800+ sculptures documented
   - PACK & SEND study statistics
   - "Johns vs Women" claim analysis

2. **`BLOCKER.md`** - Problem analysis
   - Package availability issues
   - 5 solution options evaluated
   - Decision to use generic HTTP

3. **`SOLUTION.md`** - Implementation approach
   - Generic HTTP package details
   - Code patterns and examples
   - Comparison vs specialized packages

4. **`SESSION_SUMMARY_FINAL.md`** - Complete session overview
   - Timeline and achievements
   - Lessons learned
   - Next steps

5. **`STATUS.md`** (previous version) - Nix build tracking

6. **`PROJECT_STATUS.md`** - This file

7. **`data_sources_research.md`** (from earlier) - Multi-source analysis

### Working Code (3 files)

8. **`test_wikidata_simple.R`** - ✅ Working retrieval
   - Queries Wikidata SPARQL
   - Parses JSON response
   - Extracts coordinates
   - Saves to RDS

9. **`test_osm_simple.R`** - ⏳ Needs refinement
   - Queries Overpass API
   - Gets 2,496 features
   - Coordinate parsing incomplete

10. **`create_simple_map.R`** - ✅ Map generator
    - Loads Wikidata results
    - Generates JavaScript
    - Creates standalone HTML

### Data & Output (2 files)

11. **`wikidata_london_statues_simple.rds`** - 26 statues data

12. **`london_statues_map.html`** - Interactive map

---

## Interactive Map Features

### What the Map Shows

- 📍 **26 statue locations** on OpenStreetMap base
- 🎨 **Styled header** with gradient and count
- 🖱️ **Hover tooltips** - show statue name
- 🔍 **Click popups** - full metadata:
  - Name
  - Subject (who/what commemorated)
  - Material
  - Creator/sculptor
  - Date installed
  - Wikipedia link (if available)
  - Wikidata link (always available)

### Technologies Used

- **Leaflet.js** - mapping library (via CDN)
- **OpenStreetMap** - base map tiles
- **Pure JavaScript** - no R leaflet package needed
- **Responsive design** - works on mobile

### Sample Statues Shown

1. Our Lady of Westminster (51.496, -0.139)
2. Machine Gun Corps Memorial (51.503, -0.151)
3. Plus 24 more London statues

---

## What's Next

### Immediate Priorities

1. **Fix OSM parsing** - Handle nested JSON structure
2. **Combine sources** - Merge Wikidata + OSM data
3. **Deduplication** - Remove geographic duplicates

### Short-term Goals

1. **Write production functions**
   - `get_statues_wikidata()`
   - `get_statues_osm()`
   - `create_interactive_map()`

2. **Add documentation**
   - Roxygen2 for all functions
   - Usage examples
   - Parameter descriptions

3. **Update vignette**
   - Replace demo data with real retrieval
   - Show interactive map
   - Add gender analysis

### Medium-term Goals

1. **Expand coverage**
   - More Wikidata queries (increase limit)
   - Fix OSM data extraction
   - Add GLHER if accessible

2. **Enhance analysis**
   - Extract gender from Wikidata
   - Identify "Johns"
   - Compare to UK statistics

3. **Improve visualization**
   - Add map filters (by gender, date, material)
   - Cluster markers for performance
   - Color-code by data source

---

## Research Findings

### UK-Wide Statistics (PACK & SEND Study)

**Dataset:** 4,912 publicly-owned sculptures (via Art UK)

**Gender breakdown:**
- Total gendered: 1,470 sculptures
- Men: 1,119 (76%)
- Women: 351 (24%)

**Named statues (892 total):**
- Men: 764 (86%)
- Women: 128 (14%)
- **Men named "John": 82**

**Key finding:** Named women (128) outnumber Johns (82) by 1.56x

**Verdict:** "More Johns than women" claim is **FALSE for UK**

### London-Specific Data (Our Work)

**Source:** Wikidata (via our retrieval)

**Current dataset:** 26 statues
- 100% with coordinates
- 92% with Wikipedia articles
- 96% with creator info

**Next step:** Expand query to get more London statues (limit currently 50)

---

## Code Patterns

### Wikidata SPARQL Query

```r
library(httr2)
library(jsonlite)

# Define SPARQL query
sparql <- '
SELECT ?statue ?statueLabel ?coords ?subjectLabel ...
WHERE {
  ?statue wdt:P31 wd:Q179700.  # Instance of statue
  ?statue wdt:P131+ wd:Q84.     # Located in London
  ?statue wdt:P625 ?coords.     # Has coordinates
  ...
}
LIMIT 50'

# Execute query
response <- request("https://query.wikidata.org/sparql") %>%
  req_url_query(query = sparql, format = "json") %>%
  req_perform()

# Parse response
data <- response %>%
  resp_body_string() %>%
  fromJSON()

results <- data$results$bindings
```

### JavaScript Map Generation

```r
library(jsonlite)

# Prepare data
statues <- data.frame(name, lat, lon, ...)

# Convert to JSON
statues_json <- toJSON(statues)

# Create HTML
html <- paste0('
<html>
<head>
  <link rel="stylesheet" href="...leaflet.css" />
  <script src="...leaflet.js"></script>
</head>
<body>
  <div id="map"></div>
  <script>
    var map = L.map("map").setView([51.5074, -0.1278], 11);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png").addTo(map);

    var statues = ', statues_json, ';
    statues.forEach(s => {
      L.marker([s.lat, s.lon])
        .bindPopup(s.name)
        .addTo(map);
    });
  </script>
</body>
</html>
')

writeLines(html, "map.html")
```

---

## Commands Reference

### Development Workflow

```bash
# Enter nix shell
nix-shell

# Test Wikidata retrieval
nix-shell --run "Rscript R/setup/test_wikidata_simple.R"

# Test OSM retrieval (needs work)
nix-shell --run "Rscript R/setup/test_osm_simple.R"

# Create map
nix-shell --run "Rscript R/setup/create_simple_map.R"

# View map
open R/setup/london_statues_map.html
```

### Package Management

```bash
# Check available HTTP packages
nix-shell --run "Rscript -e 'installed.packages()[,\"Package\"] %>% grep(\"httr|json|xml|curl\", ., value=TRUE)'"

# Verify packages work
nix-shell --run "Rscript -e 'library(httr2); library(jsonlite); cat(\"✓ Ready\n\")'"
```

### Git Workflow (When Ready)

```bash
# Check status
git status

# Add new files
git add R/setup/*.md R/setup/*.R R/setup/*.html

# Commit (when production-ready)
git commit -m "Add multi-source statue data retrieval with generic HTTP packages

- Implement Wikidata SPARQL query using httr2 + jsonlite
- Create interactive HTML map with JavaScript Leaflet
- Retrieve 26 London statues with full metadata
- Document generic HTTP approach for nix compatibility
- Add Art UK research and UK-wide statistics

Fixes package availability issues by using generic HTTP tools
instead of specialized R packages not in nixpkgs.

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push (when ready)
git push origin main
```

---

## Success Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Data retrieved | >20 statues | 26 statues | ✅ |
| With coordinates | >90% | 100% | ✅ |
| With metadata | >70% | 90%+ | ✅ |
| Map created | Yes | Yes | ✅ |
| Interactive | Yes | Yes | ✅ |
| Reproducible | Yes | Yes | ✅ |
| Documented | Yes | Yes | ✅ |

**Overall:** ✅ **All core objectives met**

---

## Lessons Learned

### 1. Question Assumptions
- Assumed we needed specialized packages
- User asked "why not generic HTTP?"
- Result: Simpler, better solution

### 2. Nix Philosophy
- Favor generic over specialized
- Fewer dependencies are better
- Direct API access preferred

### 3. JavaScript Integration
- Don't need R leaflet
- Can generate HTML/JS from R
- Standalone maps are portable

### 4. Documentation Matters
- 9 files created
- Future sessions will benefit
- Clear handoff for production

---

## Project Context

### Original Goal
Replace blocked web scraping with proper API-based multi-source data retrieval for analyzing UK statue gender representation.

### Current Status
✅ **Phase 1 Complete:** Proof-of-concept working
- Wikidata retrieval functional
- Interactive map generated
- Generic HTTP approach proven
- Documentation comprehensive

⏳ **Phase 2 Next:** Production implementation
- Fix OSM parsing
- Write package functions
- Add gender analysis
- Update vignette

---

## Contact & Handoff

### For Next Session

**Quick start:**
```bash
cd /Users/johngavin/docs_gh/claude_rix/statues_named_john
nix-shell
Rscript R/setup/test_wikidata_simple.R
Rscript R/setup/create_simple_map.R
open R/setup/london_statues_map.html
```

**Read first:**
1. `R/setup/SOLUTION.md` - Technical approach
2. `R/setup/SESSION_SUMMARY_FINAL.md` - Complete overview
3. `R/setup/PROJECT_STATUS.md` - This file

**Priority tasks:**
1. Fix `test_osm_simple.R` coordinate parsing
2. Write production `get_statues_wikidata()` function
3. Add roxygen2 documentation

---

**Last Updated:** 2025-11-12
**Status:** ✅ Major milestone achieved, ready for next phase
**Next Milestone:** Production functions and vignette update
