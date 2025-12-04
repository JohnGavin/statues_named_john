# R/setup/fix_ci_workflows.R
# 2025-12-01
# Purpose: Fix CI workflows failing due to permission errors on GC roots and R_LIBS_SITE issues.

# Issue:
# 1. R-CMD-check and test-coverage failed because `mkdir -p /nix/var/nix/gcroots/per-user/runner` failed (Permission denied).
# 2. pkgdown failed because `pkgdown` package wasn't found, likely due to `R_LIBS_SITE` override.

# Changes:
# 1. Modified .github/workflows/R-CMD-check.yml: Replaced system GC root with local `ci-shell` symlink. Removed R_LIBS_SITE override.
# 2. Modified .github/workflows/test-coverage.yml: Replaced system GC root with local `ci-shell` symlink. Removed R_LIBS_SITE override.
# 3. Modified .github/workflows/pkgdown.yml: Removed R_LIBS_SITE override.

# Commands (Manual via CLI due to local segfault):
# git checkout -b fix-ci-workflows
# (Edited files)
# git add .github/workflows/*.yml R/setup/fix_ci_workflows.R
# git commit -m "FIX: Simplify CI GC roots and remove R_LIBS_SITE override"
# git push origin fix-ci-workflows
# gh pr create --title "FIX: CI Workflow Permissions and Environment" --body "Fixes permission errors in GC root creation and R_LIBS_SITE env var issues."