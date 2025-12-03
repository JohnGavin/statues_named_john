# Testing Log - Pre-built Vignettes Workflow

**Date:** December 2, 2025
**Purpose:** Verify complete workflow before updating documentation

---

## Test Plan

### Phase 1: Local Build (In Progress)

**Goal:** Verify targets pipeline builds everything correctly

**Steps:**
1. ✅ Clean targets cache (`tar_destroy()`)
2. ⏳ Run full pipeline (`tar_make()`)
3. ⏳ Verify outputs generated:
   - [ ] `inst/doc/memorial-analysis.html` (pre-built vignette)
   - [ ] `docs/` directory (pkgdown site)
   - [ ] All assets copied correctly

**What This Tests:**
- Data fetching works
- Vignette renders with Quarto
- pkgdown builds with pre-built vignette
- All dependencies resolved

---

### Phase 2: Identify Files to Commit

**Goal:** Document exactly what needs to be committed after `tar_make()`

**Files to Check:**
- Code changes: `R/`, `vignettes/`, `man/`, `NAMESPACE`
- Pre-built vignettes: `inst/doc/*.html`
- pkgdown site: `docs/` directory
- Documentation: `README.md`, etc.

**What This Tests:**
- Nothing is missed in git commits
- CI will have all files it needs

---

### Phase 3: CI Workflow Test

**Goal:** Verify CI builds site correctly from pre-built vignettes

**Steps:**
1. ⏳ Commit all outputs (code + inst/doc/ + docs/)
2. ⏳ Push to GitHub
3. ⏳ Monitor `.github/workflows/pkgdown.yml`
4. ⏳ Verify:
   - [ ] CI completes in 1-2 mins (not 20 mins)
   - [ ] Uses pre-built vignettes (doesn't run Quarto)
   - [ ] Deploys to GitHub Pages correctly
   - [ ] Site accessible at https://johngavin.github.io/statues_named_john/

**What This Tests:**
- Workflow is actually fast
- No bslib/Quarto issues
- GitHub Pages deployment works

---

### Phase 4: Documentation Update

**Goal:** Update all docs to reflect correct workflow

**Files to Update:**
- [ ] `DEVELOPER_WORKFLOW.md` - Complete workflow guide
- [ ] `AGENTS.md` - AI agent instructions
- [ ] `README.md` - User-facing docs
- [ ] `.github/workflows/README.md` - Workflow docs

**What This Tests:**
- Documentation matches reality
- Future developers/AIs follow correct process

---

### Phase 5: User Approval

**Goal:** Get user sign-off before finalizing

**Deliverables:**
- Summary of what works
- Summary of what needs committing
- Documentation changes preview
- Confirmation workflow is fast

---

## Current Status

**Phase 1:** In progress (building locally)

**Next Steps:**
1. Wait for `tar_make()` to complete
2. Check what files were generated
3. Move to Phase 2
