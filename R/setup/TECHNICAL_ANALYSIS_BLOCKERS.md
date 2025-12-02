# Technical Analysis: Local Workflow Stability & Website Deployment Blockers

**Date:** 2025-12-02
**Status:** Active Analysis
**Related Issues:** #50 (Local macOS segfault), #49 (pkgdown permissions), #55 (pkgdown fix attempt)

---

## Executive Summary

Two critical blockers prevent full local development and public website deployment:

1. **Local macOS Blocker:** roxygen2 segmentation fault on Apple Silicon (AArch64)
2. **CI Website Blocker:** pkgdown unable to copy bslib assets from read-only Nix store

Both issues stem from the tension between Nix's immutable store philosophy and R package expectations of writable file systems.

---

## Blocker 1: Local macOS Segfault (Issue #50)

### Problem Statement

```
*** caught segfault ***
address 0x0, cause 'invalid permissions'

Traceback:
 1: dyn.load(file, DLLpath = DLLpath, ...)
10: library(roxygen2)
```

**Impact:** Local development blocked on macOS Apple Silicon; must rely on Linux CI only.

### Root Cause Analysis

**Primary Cause:** Platform-specific binary incompatibility in `2025-11-24` nixpkgs snapshot for aarch64-darwin.

**Evidence:**
- Linux CI (x86_64-linux) works perfectly
- macOS AArch64 consistently segfaults
- Clean rebuild attempts (nix-collect-garbage -d) did not resolve
- GC root pinning had no effect

**Likely culprit packages:**
- `roxygen2` (loads compiled C/C++ extensions)
- `stringi` (ICU library bindings)
- `xml2` (libxml2 bindings)
- `Rcpp` (C++ interface)

**Technical explanation:**
- Nix builds binaries for aarch64-darwin using cross-compilation or native builds
- The `2025-11-24` snapshot may have broken native builds or incorrect linking flags
- Dynamic library loading (`dyn.load`) fails due to ABI mismatch or memory alignment issues

### Solutions (Ranked by Difficulty)

#### Option 1A: Update Nix Snapshot (RECOMMENDED - LOW EFFORT)

**Action:** Update `default.R` to use a newer nixpkgs snapshot.

**Steps:**
1. Check available snapshots: `rix::available_dates() |> tail(10)`
2. Update `default.R` date to most recent (e.g., `2025-12-01` or `2025-12-02`)
3. Regenerate: `source("default.R")`
4. Restart nix-shell and test: `Rscript -e 'library(roxygen2); roxygen2::roxygenise()'`

**Pros:**
- Simple one-line change
- Likely to fix if it was a temporary build issue
- No workflow disruption

**Cons:**
- May introduce other package version changes
- Snapshot may not exist yet for very recent dates

**Risk:** Low
**Effort:** 5 minutes
**Likelihood of success:** 70%

#### Option 1B: Pin to Working Snapshot (MEDIUM EFFORT)

**Action:** Bisect to find the last working snapshot before `2025-11-24`.

**Steps:**
1. Test snapshots: `2025-11-20`, `2025-11-15`, `2025-11-10`, etc.
2. Find the last date where `library(roxygen2)` works
3. Pin to that date in `default.R`

**Pros:**
- Guaranteed to find a working version
- Known stable baseline

**Cons:**
- Time-consuming to test multiple snapshots
- May miss newer package features
- Older snapshot may have other issues

**Risk:** Low
**Effort:** 1-2 hours
**Likelihood of success:** 95%

#### Option 1C: Switch to R-Universe for macOS (HIGH EFFORT)

**Action:** Use r-universe.dev binary packages instead of nixpkgs for macOS only.

**Steps:**
1. Create `default-macos.nix` that uses r-universe binaries
2. Document dual-environment setup
3. Maintain separate Nix configs for macOS vs. Linux

**Pros:**
- R-Universe provides pre-built macOS binaries
- May have better platform support

**Cons:**
- Breaks environment purity/reproducibility
- Maintenance burden of two configs
- Defeats purpose of Nix

**Risk:** Medium (complexity)
**Effort:** 4-8 hours
**Likelihood of success:** 80%

#### Option 1D: Accept Linux-Only Development (NO EFFORT)

**Action:** Document that local development requires Linux (VM/Docker/remote).

**Pros:**
- Zero effort required
- CI already works on Linux
- Many developers already use Linux VMs

**Cons:**
- Poor developer experience for macOS users
- Slower iteration cycle (must push to CI)

**Risk:** None
**Effort:** 0
**Likelihood of success:** 100% (workaround)

---

## Blocker 2: Website Deployment (Issues #49, #55)

### Problem Statement

```
Warning: problem copying
/nix/store/.../bslib/lib/bs5/dist/js/bootstrap.bundle.min.js
to ...: Permission denied
```

**Impact:** pkgdown site cannot be built/deployed; documentation website inaccessible.

### Root Cause Analysis

**Primary Cause:** pkgdown/bslib attempts to copy assets from read-only Nix store to mutable build directory.

**Technical flow:**
1. pkgdown calls `bslib::bs_theme()` to style site
2. bslib needs to copy Bootstrap CSS/JS files to `docs/` output
3. `file.copy()` tries to copy from `/nix/store/...bslib/` (mode 0444)
4. Operation fails because Nix store is immutable (by design)

**Why PR #55 failed:**
- Installing bslib to `$HOME/R_libs` moved the package files
- But pkgdown still references Bootstrap assets via `system.file()` in bslib
- Those assets live in the installed package directory
- Even in `$HOME/R_libs`, the permissions may be restrictive or the copy operation uses wrong flags

**Underlying issue:** Mismatch between:
- Nix philosophy: immutable, read-only packages
- R package expectations: writable output directories and flexible file copying

### Solutions (Ranked by Difficulty)

#### Option 2A: Skip bslib Entirely (RECOMMENDED - LOW EFFORT)

**Action:** Configure pkgdown to use minimal/built-in theme without bslib.

**Steps:**
1. Update `_pkgdown.yml`:
   ```yaml
   template:
     bootstrap: 5
     bslib:
       enabled: false  # Disable bslib dependency
   ```
2. Or use simpler Bootstrap 4 theme (no bslib):
   ```yaml
   template:
     bootstrap: 4
   ```
3. Simplify pkgdown workflow to remove bslib installation steps

**Pros:**
- Eliminates root cause entirely
- Faster builds (fewer dependencies)
- Guaranteed to work in Nix

**Cons:**
- Less customizable styling
- May look slightly less polished

**Risk:** Low
**Effort:** 15 minutes
**Likelihood of success:** 95%

#### Option 2B: Pre-build Site Locally, Commit to Repo (LOW-MEDIUM EFFORT)

**Action:** Build pkgdown site outside Nix, commit `docs/` directory to repo.

**Steps:**
1. Build site locally (macOS/Linux native R): `pkgdown::build_site()`
2. Add `docs/` to git (remove from `.gitignore`)
3. Commit and push generated site
4. Simplify GitHub workflow to just deploy existing `docs/` folder (no build)

**Pros:**
- Bypasses Nix entirely for site generation
- Faster CI (no build step)
- Known to work

**Cons:**
- Commits generated files to repo (anti-pattern)
- Requires manual rebuild on doc changes
- Loses automation benefits

**Risk:** Low
**Effort:** 30 minutes
**Likelihood of success:** 100%

#### Option 2C: Use Quarto Instead of pkgdown (MEDIUM EFFORT)

**Action:** Replace pkgdown with Quarto for documentation website.

**Steps:**
1. Create `_quarto.yml` for project
2. Convert package documentation to Quarto format
3. Use `quarto render` in CI (already in Nix environment)
4. Deploy Quarto output to GitHub Pages

**Pros:**
- Quarto is Nix-friendly (already in environment)
- More flexible than pkgdown
- Better integration with `.qmd` vignettes
- Modern tooling

**Cons:**
- Significant restructuring required
- Learning curve
- Loses pkgdown-specific features (auto function reference)

**Risk:** Medium
**Effort:** 4-6 hours
**Likelihood of success:** 90%

#### Option 2D: Patch bslib in Nix (HIGH EFFORT)

**Action:** Create custom Nix derivation that patches bslib to handle read-only stores.

**Steps:**
1. Fork bslib or create Nix overlay
2. Patch `file.copy()` calls to use `fs::file_copy(overwrite=TRUE)` or similar
3. Build custom bslib derivation in Nix
4. Reference custom derivation in `default.nix`

**Pros:**
- Keeps full pkgdown/bslib functionality
- "Proper" Nix solution
- Could contribute upstream

**Cons:**
- High complexity
- Requires Nix packaging expertise
- Maintenance burden
- May break on bslib updates

**Risk:** High
**Effort:** 8-12 hours
**Likelihood of success:** 60%

#### Option 2E: Use GitHub Actions Native R (WORKAROUND)

**Action:** Build pkgdown site using GitHub Actions' native R (not Nix).

**Steps:**
1. Create separate workflow `pkgdown-native.yml`
2. Use `r-lib/actions/setup-r` instead of Nix
3. Install packages from CRAN/GitHub as usual
4. Build and deploy with standard pkgdown workflow

**Pros:**
- Guaranteed to work (standard R environment)
- Fast (uses cached binaries)
- Well-documented pattern

**Cons:**
- Breaks reproducibility for documentation builds
- Separate environment from package checks
- May have version mismatches with Nix environment

**Risk:** Low
**Effort:** 1 hour
**Likelihood of success:** 99%

---

## Recommended Action Plan

### Phase 1: Quick Wins (Week 1)

**Goal:** Unblock development and deployment with minimal effort.

#### 1.1 Fix Local macOS Segfault
- **Action:** Try Option 1A (update snapshot)
- **Fallback:** Option 1B (bisect to working snapshot)
- **Timeline:** 1-2 hours
- **Success criteria:** `devtools::document()` works locally on macOS

#### 1.2 Fix Website Deployment
- **Action:** Try Option 2A (disable bslib) OR Option 2E (native R for pkgdown)
- **Timeline:** 30 minutes
- **Success criteria:** Website deploys successfully at johngavin.github.io/statues_named_john

### Phase 2: Validation (Week 1-2)

#### 2.1 Test Snapshot Update
```bash
# Update default.R to newer date
# Test all critical workflows
Rscript -e 'library(roxygen2); devtools::document()'
Rscript -e 'devtools::test()'
Rscript -e 'devtools::check()'
```

#### 2.2 Verify CI Stability
- Monitor 5+ consecutive successful CI runs
- Verify all three workflows pass (R-CMD-check, test-coverage, pkgdown)
- Check website is accessible and renders correctly

### Phase 3: Documentation (Week 2)

#### 3.1 Update Documentation
- Document chosen solutions in AGENTS.md
- Update QUICK_START_GUIDE.md with any new requirements
- Add troubleshooting section for common issues

#### 3.2 Close Issues
- Close #50 (if segfault resolved)
- Close #49, #55 (if pkgdown working)
- Update any related issues with resolution notes

---

## Implementation Steps (Detailed)

### Step 1: Update Nix Snapshot (Option 1A - Local Fix)

```r
# R/setup/update_nix_snapshot.R

# 1. Check available snapshots
library(rix)
available <- available_dates()
recent <- available |> sort() |> tail(10)
print(recent)

# 2. Choose a recent snapshot (e.g., most recent available)
new_date <- recent[length(recent)]
message("Testing snapshot: ", new_date)

# 3. Update default.R
default_r_content <- readLines("default.R")
default_r_content <- gsub(
  'date = "2025-11-24"',
  sprintf('date = "%s"', new_date),
  default_r_content
)
writeLines(default_r_content, "default.R")

# 4. Regenerate default.nix
source("default.R")

message("\nNext steps:")
message("1. Exit current nix-shell")
message("2. Run: nix-shell default.nix")
message("3. Test: Rscript -e 'library(roxygen2); roxygen2::roxygenise()'")
```

### Step 2: Disable bslib in pkgdown (Option 2A - Website Fix)

```yaml
# _pkgdown.yml

template:
  bootstrap: 5
  bslib:
    enabled: false  # Disable bslib to avoid Nix store permission issues

  # Alternative: Use Bootstrap 4 (no bslib dependency)
  # bootstrap: 4

# ... rest of config
```

**Or** update pkgdown workflow to use native R:

```yaml
# .github/workflows/pkgdown.yml (Option 2E)

name: pkgdown

on:
  push:
    branches: [ main, master ]
  release:
    types: [published]
  workflow_dispatch:

permissions:
  contents: write
  pages: write
  id-token: write

jobs:
  pkgdown:
    runs-on: ubuntu-latest
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::pkgdown, local::.
          needs: website

      - name: Build site
        run: pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
        shell: Rscript {0}

      - name: Deploy to GitHub pages
        if: github.event_name != 'pull_request'
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: docs
          branch: gh-pages
```

---

## Risk Assessment

| Solution | Risk Level | Effort | Success Rate | Recommendation |
|----------|-----------|--------|--------------|----------------|
| **1A: Update snapshot** | Low | 5 min | 70% | ✅ Try first |
| **1B: Bisect snapshot** | Low | 1-2 hr | 95% | ✅ Fallback for 1A |
| **1C: R-Universe** | Medium | 4-8 hr | 80% | ⚠️ Last resort |
| **1D: Linux-only** | None | 0 | 100% | ❌ Poor UX |
| **2A: Disable bslib** | Low | 15 min | 95% | ✅ Try first |
| **2B: Commit docs/** | Low | 30 min | 100% | ⚠️ Anti-pattern |
| **2C: Switch to Quarto** | Medium | 4-6 hr | 90% | 💡 Future improvement |
| **2D: Patch bslib** | High | 8-12 hr | 60% | ❌ Too complex |
| **2E: Native R workflow** | Low | 1 hr | 99% | ✅ Good fallback |

---

## Success Metrics

### Local Development
- ✅ `devtools::document()` succeeds on macOS AArch64
- ✅ `devtools::test()` passes locally
- ✅ `devtools::check()` passes with 0 errors/warnings/notes
- ✅ Full development cycle possible without pushing to CI

### Website Deployment
- ✅ pkgdown workflow completes successfully
- ✅ Website accessible at https://johngavin.github.io/statues_named_john
- ✅ All vignettes render correctly
- ✅ Function reference pages display properly
- ✅ Consistent styling across pages

### Long-term Stability
- ✅ 10+ consecutive successful CI runs
- ✅ No regressions in package functionality
- ✅ Documentation up to date with solutions
- ✅ Clear troubleshooting guide for future issues

---

## Next Actions

1. **Immediate (Today):**
   - [ ] Execute Step 1 (update Nix snapshot)
   - [ ] Test local roxygen2 functionality
   - [ ] If successful, commit changes and push

2. **Short-term (This Week):**
   - [ ] Execute Step 2 (fix pkgdown)
   - [ ] Verify website deployment
   - [ ] Update documentation with solutions
   - [ ] Close resolved issues

3. **Follow-up (Next Week):**
   - [ ] Monitor CI stability
   - [ ] Consider Quarto migration (optional enhancement)
   - [ ] Document learnings in Technical Journal

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Author:** Claude (Technical Analysis)
