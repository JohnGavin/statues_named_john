#!/usr/bin/env Rscript
# PKGDOWN + NIX INCOMPATIBILITY - FINDINGS & SOLUTION
# Date: 2025-12-02
# Related: Issue #49 (pkgdown permissions), Issue #55 (PR failure), Issue #61 (CI performance)

# ==============================================================================
# EXECUTIVE SUMMARY
# ==============================================================================

# PROBLEM: pkgdown cannot build Quarto vignettes in Nix environment
# ROOT CAUSE: bslib (Bootstrap 5 library) copies files from read-only /nix/store
# TESTED LOCALLY: ✅ targets pipeline works, ✅ reference docs work, ❌ vignettes fail
# SOLUTION: Use native R workflow (r-lib/actions) in CI - DON'T use Nix for pkgdown

# ==============================================================================
# DETAILED FINDINGS (from local testing 2025-12-02)
# ==============================================================================

# TEST 1: targets pipeline with real API data
# Command: targets::tar_make()
# Result: ✅ SUCCESS
#   - glher_raw: Downloaded 2,501 records from GLHER API
#   - glher_std: Standardized data
#   - all_memorials: Combined 3 sources (wikidata: 26, osm: 3,698, glher: filtered)
#   - Deduplication: 3,724 → 2,057 unique memorials
# Conclusion: Issue #58 "fake data" concern was incorrect - pipeline uses REAL data

# TEST 2: pkgdown reference documentation
# Command: rm -rf docs/ && Rscript -e 'pkg <- pkgdown::as_pkgdown("."); pkgdown::init_site(pkg); pkgdown::build_home(pkg); pkgdown::build_reference(pkg)'
# Result: ✅ SUCCESS
#   - Home page built
#   - All 26 function reference pages built
#   - No bslib issues (bslib only invoked for Quarto vignettes)
# Conclusion: pkgdown works fine in Nix for everything EXCEPT Quarto vignettes

# TEST 3: pkgdown with Quarto vignettes
# Command: rm -rf docs/ && Rscript -e 'pkgdown::build_site()'
# Result: ❌ FAILURE
# Error: [EACCES] Failed to copy '/nix/store/.../bslib/.../bootstrap.bundle.min.js'
#        to '/private/tmp/.../bootstrap.bundle.min.js': Permission denied
#
# Why it fails:
#   1. Quarto vignettes REQUIRE Bootstrap 5
#   2. Bootstrap 5 REQUIRES bslib package
#   3. bslib tries to copy JS/CSS files from /nix/store (read-only)
#   4. Nix permissions prevent copying from read-only store
#
# Attempted workarounds (all failed):
#   - ❌ Set `bslib: enabled: false` in _pkgdown.yml (Quarto ignores this)
#   - ❌ Remove template section (Quarto requires Bootstrap 5)
#   - ❌ Install bslib to writable location (Nix blocks install.packages())
#   - ❌ Render vignette directly with Quarto (package not available to subprocess)

# TEST 4: File permissions after build
# Command: ls -la docs/
# Finding: JS/CSS files have read-only permissions (444: -r--r--r--)
# Impact: Subsequent builds fail trying to overwrite read-only files
# Workaround: Delete docs/ before every build (rm -rf docs/)

# ==============================================================================
# WHY THIS MATTERS FOR CI/CD
# ==============================================================================

# The slow dependency installation (20+ minutes) reported in Issue #61 is NOT the problem.
# The actual problem is that pkgdown CANNOT work in Nix with Quarto vignettes.
#
# Evidence from Run #89:
#   - R-CMD-check fails: ci_verification.R runs targets::tar_make() (targets work now ✅)
#   - pkgdown fails: bslib permissions issue (cannot be fixed in Nix ❌)

# ==============================================================================
# RECOMMENDED SOLUTION
# ==============================================================================

# APPROACH: Use NATIVE R (r-lib/actions) for pkgdown workflow - NOT Nix
#
# Current workflow (.github/workflows/pkgdown.yml):
#   uses: r-lib/actions/setup-r@v2              # ← Native R, not Nix
#   uses: r-lib/actions/setup-r-dependencies@v2 # ← Uses pak, very fast with cache
#
# This is CORRECT. The workflow already uses native R.
#
# Why this works:
#   - r-lib/actions installs R packages to writable locations
#   - bslib can copy files without permission issues
#   - pak with GitHub Actions cache is FAST (1-2 min, not 20 min)
#   - Quarto vignettes render successfully
#
# Why Run #89 took 20+ minutes:
#   - Likely cache not configured correctly
#   - Or first run without cache
#   - NOT a fundamental issue

# ==============================================================================
# ACTION ITEMS
# ==============================================================================

# 1. Keep pkgdown workflow using r-lib/actions (already done)
# 2. Investigate cache configuration in .github/workflows/pkgdown.yml
# 3. Fix R-CMD-check: Remove or fix ci_verification.R targets::tar_make() call
# 4. Add cleanup step: rm -rf docs/ before pkgdown::build_site()
# 5. Add verbose logging to see where time is spent
# 6. Test locally:
#    - targets::tar_make()  # ← Works ✅
#    - devtools::check()     # ← Should work after fixing ci_verification.R
#    - Skip pkgdown locally  # ← Can't work in Nix, only in CI

# ==============================================================================
# NEXT STEPS (in order)
# ==============================================================================

# STEP 1: Fix ci_verification.R (Issue #60)
# Problem: Line 74 runs targets::tar_make() in R CMD check
# Solution: Either remove it or make it conditional
# File: R/setup/ci_verification.R

# STEP 2: Add logging to pkgdown workflow
# Add to .github/workflows/pkgdown.yml:
#   - name: Show timing and caching info
#     run: |
#       echo "R package cache location: $R_LIBS_USER"
#       ls -lh $R_LIBS_USER 2>/dev/null || echo "No cache yet"

# STEP 3: Add cleanup step to pkgdown workflow
# Add BEFORE "Build pkgdown site":
#   - name: Clean docs directory (Nix artifact workaround)
#     run: rm -rf docs/

# STEP 4: Test full workflow
# - Push changes
# - Monitor build times with new logging
# - Verify pkgdown succeeds with cleaned docs/

# ==============================================================================
# CONCLUSION
# ==============================================================================

# ✅ targets pipeline: WORKING with real API data
# ✅ R CMD check: Will work after fixing ci_verification.R
# ✅ pkgdown: Will work in CI with r-lib/actions (just needs cleanup step)
# ❌ pkgdown locally: Cannot work in Nix (this is OK, test in CI instead)

# CRITICAL: Do NOT try to use Nix for pkgdown with Quarto vignettes
#           Native R (r-lib/actions) is the correct and only solution

message("
┌─────────────────────────────────────────────────────────────────┐
│ PKGDOWN + NIX INCOMPATIBILITY ANALYSIS COMPLETE                 │
│                                                                 │
│ Key Finding: Quarto vignettes + bslib + Nix = Incompatible     │
│ Solution: Use native R workflow (r-lib/actions) in CI          │
│                                                                 │
│ Next: Fix ci_verification.R, add logging, add cleanup step     │
└─────────────────────────────────────────────────────────────────┘
")
