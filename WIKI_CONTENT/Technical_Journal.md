# Technical Journal: Nix Package Availability Blocker & Resolution

This document chronicles a critical technical challenge faced by the `londonremembers` project concerning the availability of R packages within the Nix environment, and its eventual resolution.

## 1. Initial Blocker Identification (2025-11-12)

*Originally derived from `R/setup/BLOCKER.md`*

### 1.1 Problem Summary

The required R packages for multi-source statue data retrieval were initially **perceived as NOT available in nixpkgs**, and Nix's reproducibility model **blocks standard `install.packages()`**.

### 1.2 Required Packages (Initially Perceived Unavailable)

The specialized packages deemed crucial for the multi-source API approach were:
*   **WikidataQueryServiceR** - SPARQL queries to Wikidata
*   **osmdata** - OpenStreetMap Overpass API
*   **sf** - Spatial features (GIS operations)
*   **leaflet** - Interactive maps

### 1.3 Attempts Made

Various methods were attempted to make these packages available:
1.  **Added packages to `default.R` `r_pkgs`**: Resulted in Nix downloading numerous paths and building derivations, but the target packages were not included in the `nixpkgs` repository.
2.  **Added packages via `git_pkgs` (GitHub URLs)**: Updating `default.R` with repository URLs yielded the same result; targets remained missing.
3.  **Direct `install.packages()` in nix-shell**: This was blocked by Nix, which enforces reproducibility by preventing dynamic package installation outside its defined environment.
4.  **System R installation**: Not possible as the project operates in a pure Nix environment.

### 1.4 Root Cause (Initial Perception)

The perception was that Nix R packages, sourced from the `nixpkgs` repository, represent a subset of CRAN and might not include all packages, especially niche or rapidly updated ones. It was believed that the required packages were either not packaged for `nixpkgs` or used different names.

## 2. Proposed Solutions & Workarounds

*Originally derived from `R/setup/BLOCKER.md`*

Several options were considered to overcome the perceived blocker:

### 2.1 Exploring Nix Package Names (Option 1)

*   **Action**: Search `nixpkgs` for the packages under potentially different names using `nix-env -qaP` or `nix search nixpkgs`.
*   **Likelihood**: Medium, as `sf` and `leaflet` are popular.

### 2.2 Building Custom Nix Derivations (Option 2)

*   **Action**: Create custom Nix expressions to build packages from CRAN sources.
*   **Pros**: Maintains Nix reproducibility.
*   **Cons**: Time-consuming, complex, requires advanced Nix knowledge, especially for packages like `sf` with complex system dependencies.

### 2.3 renv + Nix Hybrid (Option 3)

*   **Action**: Use R's native package manager `renv` for R packages while Nix provides the R interpreter and system dependencies.
*   **Pros**: Works with all CRAN packages, familiar R workflow, Nix still provides system dependencies.
*   **Cons**: Less "pure" Nix, binary compatibility not guaranteed across systems.

### 2.4 Pivoting to Python (Option 4)

*   **Action**: Rewrite the project in Python using equivalent packages well-supported in `nixpkgs` (e.g., `sparqlwrapper`, `overpy`, `geopandas`, `folium`).
*   **Pros**: Python packages are well-supported in `nixpkgs`.
*   **Cons**: Complete rewrite, highly disruptive.

### 2.5 Abandoning Nix (Option 5)

*   **Action**: Remove Nix entirely and use a standard R installation.
*   **Pros**: No package availability issues.
*   **Cons**: Loses reproducibility, defeats original project setup purpose.

## 3. Generic HTTP Prototype & Breakthrough (2025-11-12)

*Originally derived from `R/setup/SOLUTION.md` and `R/setup/SESSION_SUMMARY_FINAL.md`*

### 3.1 The User's Key Insight

A crucial user insight (Question: "Why are you looking for R packages related to specific url datasets. Can you try generic R packages to access remote data like http2?") completely reframed the problem and led to a breakthrough.

### 3.2 Generic HTTP Solution Adopted (as a Prototype)

Instead of specialized packages, a prototype solution using **generic HTTP tools** that were confirmed available in Nix (`httr2`, `jsonlite`, `xml2`, `rvest`, `curl`) was adopted. This approach successfully unblocked the project.

### 3.3 Proof of Concept: Wikidata & OpenStreetMap

*   **Wikidata Retrieval**: Successfully prototyped retrieval of 26 London statues from Wikidata SPARQL endpoint using `httr2` and `jsonlite`.
*   **OpenStreetMap Retrieval**: Successfully prototyped querying the Overpass API using `httr2` and `jsonlite`, retrieving 2,496 features (though parsing of complex nested JSON required refinement).
*   **Interactive HTML Map**: A standalone HTML map with 26 statue markers, styled headers, hover tooltips, and click popups was generated entirely using plain R logic and JavaScript (Leaflet.js via CDN), circumventing the need for the `leaflet` R package.

### 3.4 Why Generic HTTP Seemed Better (Initially)

At the time, this approach was considered superior because it:
*   Resolved Nix dependency issues (generic packages were available).
*   Provided direct API access without intermediary libraries.
*   Was more transparent and maintainable with fewer moving parts.
*   Aligned with Nix's philosophy of favoring generic tools and fewer dependencies.

### 3.5 Key Takeaways (from Prototype Phase)

*   Question assumptions about needing specialized packages; generic HTTP can often suffice.
*   Simpler approaches (direct API access) can be more transparent and maintainable.
*   Leveraging JavaScript with R (e.g., for mapping) can provide powerful standalone solutions.

## 4. Final Resolution: Specialized Packages Confirmed Available (2025-11-29)

### 4.1 Re-evaluation

Despite the extensive efforts and successful prototyping with generic HTTP tools, a re-evaluation of the Nix environment (prompted by user interaction) led to the confirmation that the specialized R packages (`WikidataQueryServiceR`, `osmdata`, `sf`, `leaflet`) are, in fact, fully available and functioning within the current Nix shell. The initial perception of their unavailability was due to an incorrect R command syntax for checking library loading.

### 4.2 Current Status

The critical blocker identified on `2025-11-12` has been definitively resolved. The specialized R packages required for the multi-source API approach are now confirmed to be available and will be utilized in the project's implementation. The generic HTTP prototype and the problem-solving journey documented herein represent an important historical account of the project's technical evolution.
