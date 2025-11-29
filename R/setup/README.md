# Multi-Source Statue Data Implementation

**Project:** londonremembers R package
**Date:** 2025-11-12
**Status:** Ready for execution once nix packages build

---

## 📚 Documentation Files

### Planning & Research
- **`data_sources_research.md`** - Comprehensive research on alternative data sources
  - Evaluated: GLHER, Wikidata, OSM, Historic England, StatueFindr, Art UK
  - Prioritized sources with coordinates and APIs
  - Comparison matrix of all sources

- **`implementation_plan.md`** (700+ lines) - Complete implementation with full R code
  - All function implementations ready to use
  - Data architecture diagram
  - Interactive map code with popups
  - Gender analysis functions
  - Testing strategy
  - Usage examples

### Session Documentation
- **`session_summary.md`** - Complete progress summary
  - What was completed
  - What's in progress
  - Next steps clearly defined
  - Expected results

- **`QUICK_START.md`** - Step-by-step execution guide (this session)
  - 10 steps from package verification to final commit
  - Expected outputs for each step
  - Timeline: ~90 minutes total
  - Troubleshooting tips

- **`session_notes.md`** - Notes from previous session
  - Reproducibility requirements
  - Persistent nix shell setup
  - PR workflow

- **`skills_update_summary.md`** - Claude skills updates
  - Critical reproducibility requirements
  - Single persistent shell mandate

### Ready-to-Run Scripts
- **`test_wikidata.R`** - Test Wikidata SPARQL queries
  - Queries London statues with coordinates
  - Saves results as RDS and CSV
  - Shows summary statistics

- **`test_osm.R`** - Test OpenStreetMap Overpass API
  - Queries 3 tag combinations
  - Returns SF objects with coordinates
  - Saves all results separately and combined

### Workflow Scripts (from previous session)
- **`check_workflows.R`** - Monitor GitHub Actions
- **`create_pr.R`** - Create PR using R gh package
- **`check_pr_status.R`** - Check PR status
- **`merge_pr.R`** - Merge PR using R gh package

### Log Files
- **`regenerate_nix.log`** - Nix environment regeneration output
- **`check_workflows.log`** - GitHub Actions monitoring output
- **`merge_pr.log`** - PR merge documentation
- **`test_wikidata.log`** - Will be created when test runs
- **`test_osm.log`** - Will be created when test runs

---

## 🎯 What We're Building

### Problem
- London Remembers website blocks web scraping
- No API or downloadable data available
- Need geographic coordinates for mapping
- Need to validate "Statues for Equality" claims

### Solution
**Multi-source data architecture:**
```
Wikidata (SPARQL) ─┐
OpenStreetMap      ├─→ Standardization ─→ Spatial Deduplication ─→
GLHER (CSV)        │                      (50m threshold)
Historic England  ─┘

                    ↓
              Unified Dataset
                    ↓
      ┌─────────────┼─────────────┐
      ↓             ↓              ↓
  Analysis    Interactive      Vignette
  Functions      Maps         with Real Data
```

### Key Features

**1. Interactive Leaflet Map**
```r
map <- map_statues(
  all_statues,
  popup_fields = c("name", "subject", "year_installed", "material"),
  color_by = "source",
  cluster = TRUE
)
```

**Popup on hover/click shows:**
- Statue name (header)
- Subject (who/what commemorated)
- Year installed
- Material (bronze, stone, etc.)
- Sculptor name
- Clickable link to source
- Image (if available)

**2. Multi-Source Data Integration**
- Wikidata: 50-100 London statues (high metadata quality)
- OSM: 150-300 features (excellent coordinates)
- GLHER: 100-200 monuments (professional heritage data)
- **Combined: 150-300 unique statues** after deduplication

**3. Spatial Deduplication**
- Identifies duplicates within 50 meters
- Merges records intelligently
- Enriches with data from multiple sources
- Keeps best data from preferred sources

**4. Gender Analysis**
```r
gender_results <- analyze_by_gender(all_statues)
# Returns: Male/Female/Animal/Unknown counts and percentages
```

**5. Johns vs Women Validation**
```r
comparison <- compare_johns_vs_women(all_statues)
# Validates "Statues for Equality" claim with real data
```

---

## 🚀 Quick Start (Once Packages Built)

### 1-Minute Verification
```bash
nix-shell --run "Rscript -e 'library(WikidataQueryServiceR); library(osmdata); library(sf); library(leaflet)'"
```

### 5-Minute Data Test
```bash
# Test Wikidata
nix-shell --run "Rscript R/setup/test_wikidata.R"

# Test OSM
nix-shell --run "Rscript R/setup/test_osm.R"
```

### 90-Minute Full Implementation
See **`QUICK_START.md`** for complete step-by-step guide

---

## 📦 Package Changes

### Dependencies Added (DESCRIPTION)
```r
Imports:
  WikidataQueryServiceR,  # Wikidata SPARQL queries
  osmdata,                # OpenStreetMap Overpass API
  sf,                     # Spatial features for deduplication
  leaflet,                # Interactive maps
  # ... existing packages
```

### Nix Environment (default.R)
```r
r_pkgs = c(
  "WikidataQueryServiceR",
  "osmdata",
  "sf",
  "leaflet",
  "gh", "gert", "usethis",  # For Git/GitHub operations
  # ... all other packages
)
```

---

## 📊 Expected Results

### Data Coverage
| Source | Records | Coordinates | Metadata Quality |
|--------|---------|-------------|------------------|
| Wikidata | 50-100 | 100% | 70-80% |
| OSM | 150-300 | 100% | 40-50% |
| GLHER | 100-200 | 100% | 90-95% |
| **Combined** | **150-300** | **100%** | **80-85%** |

### Gender Analysis (Expected)
- Male subjects: ~70-80%
- Female subjects: ~10-15%
- Animals: ~5-10%
- Unknown: ~5-10%

### Johns vs Women (Expected for London)
- Statues named "John": ~15-25
- Women statues: ~20-40
- **Likely to refute** the claim for London
- May hold true for UK-wide data

---

## 📁 File Organization

```
statues_named_john/
├── R/
│   ├── get_statues_wikidata.R        # To be created
│   ├── get_statues_osm.R             # To be created
│   ├── get_statues_glher.R           # To be created
│   ├── standardize_statue_data.R     # To be created
│   ├── combine_statue_sources.R      # To be created
│   ├── map_statues.R                 # To be created
│   ├── analyze_statues.R             # To be created
│   └── setup/
│       ├── README.md                  # This file
│       ├── QUICK_START.md             # Execution guide
│       ├── data_sources_research.md   # Research findings
│       ├── implementation_plan.md     # Complete code
│       ├── session_summary.md         # Progress summary
│       ├── test_wikidata.R            # Test script
│       ├── test_osm.R                 # Test script
│       └── *.log                      # Log files
├── data-raw/
│   ├── wikidata_cache.rds            # Will be created
│   ├── osm_cache.rds                 # Will be created
│   └── combined_statues.rds          # Will be created
├── vignettes/
│   └── memorial-analysis.Rmd         # To be updated
├── DESCRIPTION                        # Updated
├── default.R                          # Updated
└── default.nix                        # Regenerated
```

---

## ⏱️ Implementation Timeline

| Phase | Tasks | Time | Status |
|-------|-------|------|--------|
| **Setup** | Verify packages | 1 min | ⏳ Waiting for nix |
| **Testing** | Test Wikidata + OSM | 10 min | ⏳ Ready |
| **Implementation** | Extract functions from plan | 30 min | ✅ Code ready |
| **Integration** | Full pipeline test | 10 min | ⏳ Pending |
| **Analysis** | Gender + Johns analysis | 5 min | ⏳ Pending |
| **Documentation** | Update vignette | 15 min | ⏳ Pending |
| **Finalization** | Check + commit | 15 min | ⏳ Pending |
| **Total** | | **~90 min** | ⏳ Ready to execute |

---

## 🎓 Key Technical Innovations

### 1. Multi-Source Architecture
Combines professional (GLHER) and crowd-sourced (Wikidata, OSM) data for comprehensive coverage

### 2. Spatial Deduplication
```r
# Uses sf package for geographic operations
# Identifies duplicates within 50m
# Merges intelligently with source priority
combine_statue_sources(
  list(wikidata = wd, osm = osm, glher = glher),
  distance_threshold = 50
)
```

### 3. Rich Interactive Popups
HTML popups with complete metadata, images, and links - appears on hover/click

### 4. Reproducibility
- Nix for exact package versions
- Caching for data retrieval
- Targets pipeline integration
- All operations logged

### 5. Transparent Methodology
Unlike "Statues for Equality":
- ✅ All sources documented
- ✅ All code provided
- ✅ Deduplication explained
- ✅ Classification methods shown
- ✅ Data quality metrics included

---

## 🔧 Current Status

### ✅ Completed
- [x] Comprehensive research of all data sources
- [x] Complete implementation plan with full code
- [x] Test scripts for Wikidata and OSM
- [x] Package dependencies updated
- [x] Nix environment regenerated
- [x] Documentation complete
- [x] Skills updated with reproducibility requirements
- [x] PR #5 merged (vignette enhancements)

### ⏳ In Progress
- [ ] Nix packages building from source (WikidataQueryServiceR, osmdata, sf, leaflet)
  - Estimated time: 30-60 minutes
  - All subsequent steps blocked until complete

### 📋 Next (Once Build Complete)
1. Run test scripts
2. Implement functions (code ready in implementation_plan.md)
3. Create interactive map
4. Update vignette
5. Commit and push

---

## 📞 Getting Help

### If packages not building:
```bash
# Check build status
tail -f R/setup/regenerate_nix.log

# Check what's available
nix-shell --run "Rscript -e 'installed.packages()[,\"Package\"]'"
```

### If queries fail:
- Check internet connection
- Reduce query limits
- Use smaller bounding boxes
- Check API status pages

### If deduplication is slow:
- Reduce dataset size first
- Use smaller distance threshold
- Consider batching large datasets

---

## 🎯 Success Criteria

### Data Quality
- ✅ 100+ unique statues with coordinates
- ✅ 80%+ with metadata (name, subject, etc.)
- ✅ Multiple sources contributing to records
- ✅ Spatial deduplication working correctly

### Interactive Map
- ✅ Displays in browser
- ✅ Hover shows statue names
- ✅ Click shows full popups with metadata
- ✅ Colors indicate data sources
- ✅ Clustering for performance
- ✅ Can save as standalone HTML

### Analysis
- ✅ Gender breakdown calculated
- ✅ Johns vs Women comparison complete
- ✅ Results documented in vignette
- ✅ Methodology transparent

### Package
- ✅ All functions documented with roxygen2
- ✅ Tests pass
- ✅ Vignette builds successfully
- ✅ README updated
- ✅ Git history clean

---

## 📖 Further Reading

- **Wikidata:** https://www.wikidata.org/
- **OpenStreetMap:** https://www.openstreetmap.org/
- **GLHER:** https://glher.historicengland.org.uk/
- **Leaflet for R:** https://rstudio.github.io/leaflet/
- **SF Package:** https://r-spatial.github.io/sf/

---

**Ready to execute when nix packages finish building!**

All code is written. All documentation is complete. The system is fully planned and ready to implement in approximately 90 minutes once the build completes.
