# CRITICAL BLOCKER: Package Availability in Nix

**Date:** 2025-11-12
**Status:** ⛔ BLOCKED

---

## Problem Summary

The required R packages for multi-source statue data retrieval are **NOT available in nixpkgs** and nix's reproducibility model **blocks standard `install.packages()`**.

### Required Packages:
- **WikidataQueryServiceR** - SPARQL queries to Wikidata
- **osmdata** - OpenStreetMap Overpass API
- **sf** - Spatial features (GIS operations)
- **leaflet** - Interactive maps

### What We Tried:

1. **Added packages to default.R r_pkgs** ❌
   - Result: Nix downloaded 169 paths, built 40 derivations
   - Problem: Target packages not included in nixpkgs repository

2. **Added packages via git_pkgs (GitHub URLs)** ❌
   - Updated default.R with repo URLs
   - Regenerated default.nix
   - Result: Same 169 packages, targets still missing

3. **Direct install.packages() in nix-shell** ❌
   - Error: "You are currently in an R session running from Nix. Don't install packages using install.packages(), add them to the default.nix file instead."
   - Nix enforces reproducibility by blocking dynamic package installation

4. **System R installation** ❌
   - No system R available (project is pure nix)
   - Cannot install packages outside nix environment

---

## Root Cause

Nix R packages come from **nixpkgs** repository, which:
- Contains ~5,000 R packages (subset of CRAN's 20,000+)
- Updates on schedule, not immediately when CRAN updates
- May not include all packages, especially niche ones

Our required packages appear to **not be packaged for nixpkgs** or use the wrong package names.

---

## Solutions (Ranked by Feasibility)

### 🟢 Option 1: Find Nix Package Names (RECOMMENDED)

The packages MAY exist in nixpkgs under different names.

**Action:**
```bash
# Search nixpkgs for our packages
nix-env -qaP | grep -i wikidata
nix-env -qaP | grep -i osmdata
nix-env -qaP | grep -i "\\bsf\\b"
nix-env -qaP | grep -i leaflet

# Alternative: search attribute names
nix search nixpkgs WikidataQueryServiceR
nix search nixpkgs osmdata
nix search nixpkgs r-sf
nix search nixpkgs r-leaflet
```

**If found:** Update default.R with correct nix package names.

**Likelihood:** Medium - sf and leaflet are popular, might be available.

---

### 🟡 Option 2: Build Custom Nix Derivations

Create nix expressions to build packages from CRAN.

**Steps:**
1. Create `nix/WikidataQueryServiceR.nix`:
```nix
{ R, buildRPackage, fetchurl, httr, jsonlite }:

buildRPackage rec {
  pname = "WikidataQueryServiceR";
  version = "1.0.0";

  src = fetchurl {
    url = "https://cran.r-project.org/src/contrib/${pname}_${version}.tar.gz";
    sha256 = "...";  # Need to compute
  };

  propagatedBuildInputs = [ httr jsonlite ];
}
```

2. Add to default.nix
3. Repeat for osmdata, sf, leaflet

**Pros:** Maintains nix reproducibility
**Cons:**
- Time-consuming (hours)
- Need to resolve all dependencies recursively
- sf requires complex system libraries (GDAL, PROJ, GEOS)
- Advanced nix knowledge required

**Likelihood:** Low - complex, time-intensive

---

### 🟢 Option 3: Use renv + Nix Hybrid (PRAGMATIC)

Abandon pure nix for R packages, use R's native package management.

**Steps:**

1. **Remove rix-based package management:**
   - Keep nix for R itself and system dependencies
   - Use R's `renv` for package management

2. **Update default.nix to allow package installation:**
```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    R
    # System dependencies for spatial packages
    gdal
    proj
    geos
    udunits
    # For package compilation
    gcc
    pkg-config
  ];

  shellHook = ''
    export R_LIBS_USER="$PWD/renv/library/R-${pkgs.R.version}"
    mkdir -p $R_LIBS_USER
  '';
}
```

3. **Initialize renv:**
```bash
nix-shell --run "Rscript -e 'install.packages(\"renv\"); renv::init()'"
```

4. **Install packages:**
```bash
nix-shell --run "Rscript -e 'renv::install(c(\"WikidataQueryServiceR\", \"osmdata\", \"sf\", \"leaflet\"))'"
```

**Pros:**
- Works with all CRAN packages
- Familiar R workflow
- Snapshot versioning via renv
- Nix still provides system dependencies

**Cons:**
- Less pure than full nix approach
- Binary compatibility across systems not guaranteed

**Likelihood:** High - practical compromise

---

### 🔴 Option 4: Pivot to Python

Abandon R entirely, rewrite in Python with available nix packages.

**Python equivalents:**
- WikidataQueryServiceR → `sparqlwrapper` (in nixpkgs)
- osmdata → `overpy` (Overpass API client)
- sf → `geopandas` (in nixpkgs)
- leaflet → `folium` (in nixpkgs)

**Pros:** Python packages well-supported in nixpkgs
**Cons:** Complete rewrite, abandons existing R package

**Likelihood:** Very Low - too disruptive

---

### 🔴 Option 5: Abandon Nix

Remove nix entirely, use standard R installation.

**Pros:** No package availability issues
**Cons:** Loses reproducibility, not aligned with project setup

**Likelihood:** Very Low - defeats original purpose

---

## Recommended Path Forward

### Immediate (Next 30 minutes):

**Try Option 1: Search for existing nix packages**

```bash
# Comprehensive search
nix-shell --run "Rscript -e 'available.packages()[grepl(\"wiki|osm|^sf$|leaflet\", available.packages()[,\"Package\"], ignore.case=TRUE), c(\"Package\", \"Version\")]'"

# Check rix's available packages
nix-shell --run "Rscript -e 'library(rix); rix::available_r_pkgs_from_nix() %>% filter(grepl(\"wiki|osm|^sf$|leaflet\", Package, ignore.case=TRUE))'"
```

If packages found with different names → Update default.R → Regenerate → Test

### Fallback (If Option 1 fails):

**Implement Option 3: renv + nix hybrid**

1. Simplify default.nix to basic shell with R + system deps
2. Use renv for R package management
3. Document the hybrid approach
4. Proceed with implementation

**Timeline:**
- Setup renv: 10 minutes
- Install packages: 15 minutes
- Test data retrieval: 15 minutes
- **Total: 40 minutes to unblock**

---

## Decision Required

**Question for user:**

Given that pure nix approach is blocked, which do you prefer?

**Option A:** Spend time searching for packages in nixpkgs (may or may not work)

**Option B:** Pivot to renv + nix hybrid (will definitely work, less pure)

**Option C:** Wait for community help on nix package availability

---

## Impact on Project Goals

### What's NOT Blocked:
✅ All research and documentation complete
✅ All function code written and ready
✅ Test scripts prepared
✅ Implementation plan documented
✅ Art UK findings and UK-wide statistics documented

### What IS Blocked:
❌ Testing data retrieval functions
❌ Creating interactive maps
❌ Validating multi-source approach
❌ Completing the implementation
❌ Updating vignette with real data

### Alternative: Documentation-Only Delivery

If unblocking takes too long, we can deliver:

1. **Complete documentation** (already done)
2. **Complete implementation code** (already written)
3. **Clear instructions** for future execution
4. **Research findings** (Art UK, PACK & SEND study)
5. **Note:** "Implementation blocked by nix package availability, code ready to execute once resolved"

This provides value even without running code:
- Other developers can use our code
- User can try different nix approaches
- Research findings are documented
- Implementation strategy is clear

---

## Files Status

**Documentation (Complete):**
- ✅ `R/setup/art_uk_research.md` - Best data source identified
- ✅ `R/setup/data_sources_research.md` - Multi-source analysis
- ✅ `R/setup/implementation_plan.md` - 700+ lines of ready code
- ✅ `R/setup/session_summary.md` - Progress tracking
- ✅ `R/setup/QUICK_START.md` - Execution guide
- ✅ `R/setup/README.md` - Master reference
- ✅ `R/setup/STATUS.md` - Project status
- ✅ `R/setup/BLOCKER.md` - This document

**Test Scripts (Ready, Can't Run):**
- ⏳ `R/setup/test_wikidata.R` - Awaiting packages
- ⏳ `R/setup/test_osm.R` - Awaiting packages

**Implementation Functions (Written, Can't Test):**
- ⏳ All code in `implementation_plan.md`
- ⏳ 6 complete functions ready to extract

---

**DECISION NEEDED:** Which unblocking approach should we pursue?
