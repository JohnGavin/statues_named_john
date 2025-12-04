# Developer Workflow - Pre-built Vignettes Strategy

## ⚠️ CRITICAL: Always Run Targets Locally Before Push

**Never push without running `targets::tar_make()` locally first!**

---

## The Correct Workflow

### Step 1: Make Changes Locally

```bash
# Edit R code, vignettes, documentation, etc.
vim R/my_function.R
vim vignettes/memorial-analysis.qmd
```

### Step 2: Run Targets Locally (REQUIRED)

```bash
# Inside nix shell
Rscript -e 'targets::tar_make()'
```

**This will:**
- Fetch data (if needed)
- Run analysis
- Render vignettes to `inst/doc/*.html` (794KB)
- Build pkgdown site to `docs/`

**Fix ALL errors and warnings before proceeding!**

### Step 3: Verify Everything Works

```bash
# Check that vignette rendered
ls -lh inst/doc/memorial-analysis.html

# Check that pkgdown built
ls -lh docs/articles/memorial-analysis.html

# Run package checks
Rscript -e 'devtools::check()'
```

### Step 4: Commit Everything (Including Pre-built Vignettes)

```r
library(gert)

# Stage all changes
git_add(c(
  "R/",                           # Your code changes
  "vignettes/",                   # Vignette source
  "inst/doc/*.html",              # Pre-built vignettes (REQUIRED)
  "man/",                         # Documentation
  "NAMESPACE"                     # If changed
))

git_commit("Update analysis: description of changes")
```

### Step 5: Push to Trigger Fast CI

```r
usethis::pr_push()
```

**CI will:**
- Run in **1-2 minutes** (not 20 minutes!)
- Use pre-built vignettes from `inst/doc/`
- Build pkgdown site
- Deploy to GitHub Pages

**NO targets, NO Quarto, NO data fetching in CI**

---

## Why This Strategy?

### The Problem
- Quarto + bslib + Nix = incompatible in CI
- Data fetching + rendering = 20+ minutes per push
- Would exhaust GitHub Actions quota quickly

### The Solution
- Build vignettes **locally** (Nix works fine locally)
- Commit pre-built HTML to git
- CI just builds website (fast)

### Trade-offs
✅ **Pros:**
- Fast CI (1-2 mins vs 20+ mins)
- No bslib/Nix compatibility issues
- Saves GitHub Actions quota
- Reproducible (Nix locally, targets manages dependencies)

⚠️ **Cons:**
- Must run targets locally before push (REQUIRED step)
- Pre-built HTML in git (~794KB per vignette)
- Must remember to commit `inst/doc/*.html`

---

## Common Mistakes to Avoid

### ❌ WRONG: Push without running targets locally

```bash
vim R/my_function.R
git add R/
git commit -m "Update function"
git push  # ← WRONG! Vignette is now stale!
```

**Problem:** Vignette shows old results, website is outdated

### ✅ CORRECT: Always run targets first

```bash
vim R/my_function.R
Rscript -e 'targets::tar_make()'  # ← Rebuilds vignette
git add R/ inst/doc/
git commit -m "Update function and vignette"
git push  # ← Good! Everything is up-to-date
```

---

### ❌ WRONG: Forget to commit pre-built vignettes

```bash
Rscript -e 'targets::tar_make()'
git add R/ vignettes/  # ← Missing inst/doc/!
git commit -m "Update"
git push
```

**Problem:** CI won't find pre-built vignettes

### ✅ CORRECT: Always commit inst/doc/*.html

```bash
Rscript -e 'targets::tar_make()'
git add R/ vignettes/ inst/doc/*.html  # ← Include pre-built HTML
git commit -m "Update"
git push
```

---

## Troubleshooting

### "CI says no pre-built vignettes found"

```bash
# Check if they exist
ls -lh inst/doc/

# If missing, run targets
Rscript -e 'targets::tar_make()'

# Commit them
git add inst/doc/*.html
git commit --amend --no-edit
git push --force-with-lease
```

### "Vignette shows old data"

```bash
# Force rebuild
Rscript -e 'targets::tar_destroy()'
Rscript -e 'targets::tar_make()'

# Commit updated vignette
git add inst/doc/*.html
git commit -m "Update vignette with latest data"
git push
```

### "CI taking too long"

If CI is taking 20+ minutes, check:
1. Is `targets-pkgdown.yml` enabled? (should be DISABLED)
2. Is `pkgdown.yml` running? (should be the ONLY active workflow)

```bash
ls -lh .github/workflows/
# Should see:
# pkgdown.yml ← ACTIVE (simple, fast)
# targets-pkgdown.yml.DISABLED ← DISABLED (slow)
```

---

## Summary Checklist

Before every push:
- [ ] Run `targets::tar_make()` locally
- [ ] Fix all errors/warnings
- [ ] Verify `inst/doc/*.html` exists
- [ ] Commit code changes
- [ ] Commit `inst/doc/*.html` (pre-built vignettes)
- [ ] Push to trigger fast CI (1-2 mins)

---

**Last Updated:** December 2, 2025
**Strategy:** Pre-built vignettes (local targets, fast CI)
