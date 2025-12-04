# R/setup/ci_upgrade_51.R
# 2025-12-01
# Purpose: Upgrade CI workflows to match robust patterns from randomwalk repo (Issue #51).

# NOTE: All git operations in this session are performed via bash CLI 
# because local R execution is blocked by a segmentation fault on macOS AArch64 (Issue #50).
# Ideally, these would be:
# usethis::pr_init("ci-upgrade-51")

# Planned Changes:
# 1. Update .github/workflows/R-CMD-check.yml
# 2. Update .github/workflows/test-coverage.yml
# 3. Update .github/workflows/pkgdown.yml

# The goal is to fix pkgdown permission errors and optimize caching.
