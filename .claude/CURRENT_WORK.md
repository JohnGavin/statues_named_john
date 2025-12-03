# Current Focus: Fix CI Workflow & Documentation

## Active Branch
`fix-pkgdown-perms` (PR Open)

## What I'm Doing
Resolving CI failures in the `pkgdown` workflow caused by missing dependencies (`visNetwork`) and finalizing the "Pre-built Vignettes" strategy documentation.

## Progress
- [x] **Diagnosis:** Identified `visNetwork` missing from `DESCRIPTION` caused `pak` failure in CI.
- [x] **Fix:** Added `visNetwork` to `Suggests`, updated `default.R`/`package.nix`.
- [x] **Nix:** Regenerated `default.nix` and pushed binaries to **Cachix**.
- [x] **Docs:** Updated `AGENTS.md` (Critical Strategy), `README.md`, and `DEVELOPER_WORKFLOW.md`.
- [x] **Verification:** `visNetwork` verified available in local Nix shell.
- [ ] **CI:** Waiting for GitHub Actions `pkgdown` workflow to pass (currently running).

## Key Files Modified
- `DESCRIPTION`: Added `visNetwork`.
- `default.nix` / `package.nix`: Regenerated/Updated.
- `AGENTS.md`: Added mandatory pre-built vignette strategy.
- `TESTING_LOG.md`: Updated with Phase 3 diagnosis.

## Important Notes
- **Strategy:** We are using **locally rendered vignettes** (committed to `inst/doc/`) to bypass Nix/Quarto/bslib compatibility issues in CI.
- **Requirement:** Developers MUST run `targets::tar_make()` locally and commit `inst/doc/*.html` before pushing.

## Next Session Should
1. **Verify CI:** Check if the `pkgdown` workflow passed (run triggered by "Docs: Update..." commit).
   - `gh run list --workflow=pkgdown.yml`
2. **Merge PR:** If CI passes, merge `fix-pkgdown-perms` to `main`.
   - `usethis::pr_merge_main()`
3. **Final Check:** Ensure `johngavin.github.io/statues_named_john` is live and showing the map.
