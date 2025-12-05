# R/setup/session_logs/fix_deployment_issue_78.R
#
# Date: 2025-12-05
#
# Addressed Issue #78 (Limerick formatting) and a critical deployment bug
# where CI was overwriting pre-built vignettes with empty ones.
#
# Actions:
# 1.  Created Issue #78.
# 2.  Modified `.github/workflows/pkgdown.yml`:
#     - Added `override = list(articles = NULL)` to `pkgdown::build_site_github_pages`.
#     - This prevents pkgdown from rebuilding vignettes in the CI environment (where targets store is missing).
#     - CI now relies on the manual `cp` step to install the pre-built `vignettes/*.html`.
# 3.  Fixed Limerick Formatting:
#     - Updated `inst/qmd/README.qmd` and `inst/qmd/memorial-analysis.qmd` to use `<br>` for line breaks.
#     - Rendered `README.md`.
# 4.  Verified Content:
#     - Re-ran `tar_make()` to regenerate `vignettes/memorial-analysis.html`.
#     - Verified "Animal" tab content exists in the HTML.
# 5.  Committed & Merged:
#     - Merged `fix/pkgdown-override` to `main`.
#
# Expected Result:
# - Website should now display the correct plot (with Male/Animal categories) and tabs.
# - Limerick should be formatted correctly.
