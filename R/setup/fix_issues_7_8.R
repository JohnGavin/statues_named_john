# statues_named_john/R/setup/fix_issues_7_8.R
# Log for fixing issues #7 and #8

library(gert)

# -----------------------------------------------------------------------------
# Issue #7: Embed Quarto presentation in pkgdown documentation
# -----------------------------------------------------------------------------
# 1. Created inst/qmd/presentation.qmd (Placeholder)
# 2. Modified R/tar_plans/documentation_plan.R
#    - Added vignette_presentation_html target
#    - Updated pkgdown_site target to copy presentation and update index
# 3. Modified _pkgdown.yml to link presentation

# -----------------------------------------------------------------------------
# Issue #8: Display target source code in vignettes
# -----------------------------------------------------------------------------
# 1. Modified inst/qmd/memorial-analysis.qmd
#    - Added "Reproducibility: Pipeline Code" section
#    - Reads and displays R/tar_plans/memorial_analysis_plan.R

# -----------------------------------------------------------------------------
# Fix: Package Dependencies
# -----------------------------------------------------------------------------
# 1. Modified package.nix
#    - Added missing 'gender' and 'readr' packages to propagatedBuildInputs
#    - Required for build success

# -----------------------------------------------------------------------------
# Build & Verify
# -----------------------------------------------------------------------------
# Ran targets::tar_make()
# - Successfully built presentation.html
# - Successfully built pkgdown site with articles
# - Pushed to johngavin cachix via ../push_to_cachix.sh
