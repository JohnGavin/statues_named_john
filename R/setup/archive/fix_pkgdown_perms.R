# R/setup/fix_pkgdown_perms.R
# 2025-12-01
# Purpose: Fix 'Permission denied' error in pkgdown workflow (Issue #49).

# Issue:
# pkgdown/quarto fails to copy 'bslib' assets (bootstrap.bundle.min.js) because they are
# located in the read-only Nix store.

# Solution:
# Explicitly install 'bslib' into a writable user library ($HOME/R_libs) in the CI workflow
# before building the site. This overrides the Nix store version of bslib for the R session.

# Actions:
# - Modified .github/workflows/pkgdown.yml to include `install.packages("bslib", ...)` step.
