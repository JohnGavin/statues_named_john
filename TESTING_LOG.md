# Testing Log - Pre-built Vignettes Workflow

**Date:** December 3, 2025
**Purpose:** Verify complete workflow before updating documentation

---

## Test Plan

### Phase 1: Local Build (Completed)

**Goal:** Verify targets pipeline builds everything correctly

**Steps:**
1. ✅ Clean targets cache (`tar_destroy()`)
2. ✅ Run full pipeline (`tar_make()`) - *All targets passed locally.*
3. ✅ Verify outputs generated:
   - ✅ `vignettes/memorial-analysis.html` (pre-built vignette)
   - ✅ `docs/` directory (pkgdown site)
   - ✅ All assets copied correctly

**What This Tests:**
- Data fetching works
- Vignette renders with Quarto
- pkgdown builds with pre-built vignette
- All dependencies resolved

---

### Phase 2: Identify Files to Commit (Completed)

**Goal:** Document exactly what needs to be committed after `tar_make()`

**Files to Check:**
- ✅ Code changes: `R/tar_plans/documentation_plan.R`
- ✅ Vignette source: `inst/qmd/memorial-analysis.qmd` (moved)
- ✅ Pre-built vignettes: `vignettes/memorial-analysis.html`
- ✅ pkgdown site: `docs/` directory (generated)
- ✅ Documentation: `TESTING_LOG.md` (updated), `_Rbuildignore` (updated), `_pkgdown.yml` (updated)
- ✅ Generated files: `_targets.yaml`

**What This Tests:**
- Nothing is missed in git commits
- CI will have all files it needs

---

### Phase 3: CI Workflow Test (Failed - Pak Error)

**Goal:** Verify CI builds site correctly from pre-built vignettes

**Diagnosis (2025-12-03 Run 2):**
- **Status:** Failed (19m 16s).
- **Error:** `! Cannot select new package installation task. 1 package still waiting to install: londonremembers.`
- **Analysis:** All dependencies (including `sf`, `arrow`, `visNetwork`) were successfully installed. The error is an internal `pak` failure when attempting to install the local package itself. This might be due to a dependency resolution edge case or the package name `londonremembers` differing from the repo name (though usually fine).

**Steps:**
1. ✅ Commit all outputs (code + html + docs/)
2. ✅ Push to GitHub
3. ❌ Monitor `.github/workflows/pkgdown.yml`
   - **Run 1:** Failed (missing visNetwork).
   - **Run 2:** Failed (pak internal error).
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

### Phase 4: Documentation Update (Pending)

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

### Phase 5: User Approval (Pending)

**Goal:** Get user sign-off before finalizing

**Deliverables:**
- Summary of what works
- Summary of what needs committing
- Documentation changes preview
- Confirmation workflow is fast

---

## Current Status

**Phase 1:** Completed
**Phase 2:** Completed
**Phase 3:** **FAILED** - CI dependency installation error.

**Next Steps:**
1. Debug `pkgdown.yml` workflow: The `pak` error suggests an issue with installing the local package `.` in the CI environment.
2. Verify if `visNetwork` is available in the new local Nix shell (as requested for next session).
3. Retry CI.
