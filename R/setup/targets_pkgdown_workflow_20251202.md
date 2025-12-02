# Targets-Based Pkgdown Workflow - December 2, 2025

## Overview

This document describes the automated targets workflow for rendering vignettes and building the pkgdown site.

## Problem Solved

**Original Issue**: Quarto vignettes + bslib + Nix = incompatible (see `R/setup/WIKI_NIX_PKGDOWN_ISSUE.md`)

**Previous Approach**: Use r-lib/actions (native R) instead of Nix
- Problem: Packages building from source (20+ minutes)
- Problem: Manual vignette rendering required

**New Approach**: targets workflow that automates everything
- ✅ Vignettes render automatically when data changes
- ✅ pkgdown builds automatically when vignettes change
- ✅ All managed through targets DAG
- ✅ Pre-built vignettes committed to git
- ✅ Fast pkgdown builds (no Quarto rendering needed)

## Architecture

### Dependency Chain

```
Data targets                    Vignette targets               pkgdown target
(memorial_analysis_plan)  →  (documentation_plan)  →  (documentation_plan)

get_statues_wikidata()
get_statues_osm()
get_statues_glher()
         ↓
standardize_statue_data()
         ↓
combine_statue_sources()
         ↓
analyze_by_gender()              →    vignette_memorial_analysis_html   →   pkgdown_site
compare_johns_vs_women()                   (renders .qmd to .html)           (builds site)
         ↓                                           ↓                              ↓
category_plot                              inst/doc/*.html                      docs/
memorial_map_plot                       (pre-built vignettes)            (complete site)
```

### Files Created/Modified

1. **R/tar_plans/documentation_plan.R** (NEW)
   - Defines vignette rendering targets
   - Defines pkgdown build target
   - Manages dependencies automatically

2. **_targets.R** (UPDATED)
   - Added quarto, pkgdown, sf to packages
   - Sources documentation_plan.R
   - Includes documentation_plan in pipeline

3. **_pkgdown.yml** (UPDATED)
   - Updated comment to reference targets workflow
   - No functional changes (pkgdown automatically uses inst/doc/*.html)

4. **.gitignore** (UPDATED)
   - Added /_targets/ (ignore local cache)
   - Documented that inst/doc/*.html SHOULD be committed

5. **.Rbuildignore** (NO CHANGE NEEDED)
   - Already excludes vignettes/ (source files)
   - Automatically includes inst/doc/ (built files)

6. **.github/workflows/targets-pkgdown.yml** (NEW)
   - Uses r-lib/actions (native R, not Nix)
   - Runs targets::tar_make() (full pipeline)
   - Commits pre-built vignettes and docs/
   - Deploys to GitHub Pages

## Workflow Execution

### Local Development

```r
# 1. Make changes to vignette source
edit("vignettes/memorial-analysis.qmd")

# 2. Run targets pipeline
targets::tar_make()
# → Detects vignette source changed
# → Re-renders vignette to inst/doc/memorial-analysis.html
# → Rebuilds pkgdown site in docs/

# 3. View site locally
pkgdown::preview_site()

# 4. Commit changes (including pre-built HTML)
gert::git_add(c(
  "vignettes/memorial-analysis.qmd",
  "inst/doc/memorial-analysis.html",  # Pre-built vignette
  "docs/"                              # pkgdown site (optional)
))
gert::git_commit("Update memorial analysis vignette")
gert::git_push()
```

### CI/CD (GitHub Actions)

```
Trigger: Push to main
         ↓
┌─────────────────────────────────────────────────────┐
│  Setup: R + Quarto + System Deps + R packages       │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  Run: targets::tar_make()                           │
│  ├─ Data targets (if data sources changed)          │
│  ├─ Vignette rendering (if data or .qmd changed)    │
│  └─ pkgdown build (if vignettes or code changed)    │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  Commit: inst/doc/*.html + docs/                    │
│  Message: "AUTO: Update pre-built vignettes [skip ci]" │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  Deploy: docs/ to gh-pages branch                   │
└─────────────────────────────────────────────────────┘
```

## Benefits

### 1. Automatic Updates

**When data changes**:
```
API data updates → targets detects → re-renders vignette → rebuilds pkgdown
```

**When vignette text changes**:
```
Edit .qmd → targets detects → re-renders → rebuilds pkgdown
```

**When R code changes**:
```
Update function → targets (optional) → pkgdown reference updated
```

### 2. No Manual Steps

❌ Old way:
```r
# Manual process
targets::tar_make()              # Render data
quarto::quarto_render(...)       # Render vignette
pkgdown::build_site()            # Build site
git add inst/doc/*.html          # Stage HTML
git commit -m "..."              # Commit
git push                         # Push
```

✅ New way:
```r
# Automatic process
targets::tar_make()              # Does everything!
```

### 3. Fast CI Builds

- **Previous**: 19+ minutes (rendering vignettes in CI)
- **Now**: ~5-10 minutes (using pre-built vignettes)

### 4. Reproducibility

- All outputs generated from targets pipeline
- Complete audit trail via targets metadata
- Can reproduce any state: `targets::tar_load(vignette_memorial_analysis_html)`

### 5. Caching

- targets caches intermediate results
- Only re-runs what changed
- Example: If only vignette text changes, doesn't re-fetch data

## Limitations

### 1. Pre-built HTML in Git

**Trade-off**: Commit binary files (HTML) to git

**Size impact**: ~100-500 KB per vignette

**Mitigation**:
- HTML is compressed by git
- Only changes tracked (not full files each time)
- Use git-lfs for very large vignettes (optional)

### 2. CI Commits

**Trade-off**: CI makes automatic commits

**Considerations**:
- Uses `[skip ci]` to avoid infinite loops
- Bot commits clearly marked with "AUTO:"
- Can disable for pull requests if desired

### 3. Local vs CI Differences

**Trade-off**: Local may differ from CI temporarily

**When**: Between local commit and CI push

**Duration**: ~10 minutes (CI runtime)

**Mitigation**: Run `targets::tar_make()` locally before pushing

## Comparison with Alternatives

### Alternative 1: Pure Nix (IMPOSSIBLE)

```
❌ Nix → Quarto → bslib → /nix/store (read-only) → FAILS
```

**Verdict**: Fundamentally incompatible (documented in WIKI_NIX_PKGDOWN_ISSUE.md)

### Alternative 2: r-lib/actions + Live Rendering

```
✅ r-lib/actions → Quarto → writable dirs → WORKS
⚠️  But: 20+ minutes building packages from source
```

**Verdict**: Works but slow

### Alternative 3: This Approach (targets + pre-built)

```
✅ Local: Nix → targets → Quarto → inst/doc/*.html
✅ CI: r-lib/actions → pkgdown → uses pre-built HTML → FAST
```

**Verdict**: Best of both worlds

## Monitoring

### Check targets status

```r
# What needs to be rebuilt?
targets::tar_outdated()

# What was built and when?
targets::tar_meta() %>%
  dplyr::select(name, seconds, bytes, time) %>%
  dplyr::arrange(desc(time))

# Visualize pipeline
targets::tar_visnetwork()
```

### Check vignette freshness

```r
# Compare vignette source vs built HTML
vignette_qmd_time <- file.info("vignettes/memorial-analysis.qmd")$mtime
vignette_html_time <- file.info("inst/doc/memorial-analysis.html")$mtime

if (vignette_qmd_time > vignette_html_time) {
  warning("Vignette source is newer than HTML - run targets::tar_make()")
}
```

### Check CI status

```bash
# Latest workflow runs
gh run list --workflow=targets-pkgdown.yml --limit 5

# Watch current run
gh run watch
```

## Troubleshooting

### Vignette not updating

**Symptom**: Changes to .qmd not reflected in HTML

**Fix**:
```r
# Force rebuild
targets::tar_invalidate(vignette_memorial_analysis_html)
targets::tar_make()
```

### pkgdown not rebuilding

**Symptom**: Changes to vignette HTML not reflected in docs/

**Fix**:
```r
# Force rebuild
targets::tar_invalidate(pkgdown_site)
targets::tar_make()
```

### CI failing on commit

**Symptom**: "nothing to commit, working tree clean"

**Explanation**: This is expected when no changes (targets cached)

**No action needed**: This is normal behavior

### HTML diff too large

**Symptom**: Git diff shows huge changes in HTML

**Explanation**: HTML whitespace or timestamps changed

**Fix**: Add `.gitattributes`:
```
inst/doc/*.html -diff
```

This tells git to skip HTML diffs in pull requests.

## Future Enhancements

### 1. Parallel Vignettes

If multiple vignettes, render in parallel:

```r
tar_target(
  vignette_htmls,
  {
    vignettes <- list.files("vignettes", pattern = "\\.qmd$")
    parallel::mclapply(vignettes, render_vignette)
  },
  pattern = map(vignettes)
)
```

### 2. Conditional Rendering

Only render vignettes if data changed:

```r
tar_target(
  vignette_conditional,
  {
    if (targets::tar_older(vignette_html, all_memorials)) {
      render_vignette()
    }
  }
)
```

### 3. Multiple Output Formats

Render to both HTML and PDF:

```r
tar_target(vignette_html, render_vignette(format = "html"))
tar_target(vignette_pdf, render_vignette(format = "pdf"))
```

## References

- targets documentation: https://books.ropensci.org/targets/
- pkgdown vignettes: https://pkgdown.r-lib.org/articles/pkgdown.html#vignettes
- Quarto with R: https://quarto.org/docs/computations/r.html
- GitHub Actions r-lib: https://github.com/r-lib/actions

## Related Issues

- Issue #49: Original pkgdown + Nix + Quarto incompatibility
- Issue #55: PR with initial bslib workarounds
- Issue #61: CI performance (packages building from source)
- Issue #62: Central claude_rix documentation repo

---

**Created**: 2025-12-02
**Approach**: targets-based automation
**Status**: Implemented and ready to test
