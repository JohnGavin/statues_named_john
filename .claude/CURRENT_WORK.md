# Current Focus: Documentation and Merge Resolution

## Active Branch
`docs-update-r-setup-organization`

## What I'm Doing
Resolving merge conflicts in `AGENTS.md` update branch after merging other feature PRs into `main`.

## Progress
- [x] **Feature:** Integrated `gender` R package for refining "Unknown" gender classifications (PR #68 merged).
- [x] **Refactor:** Organized `R/setup/` directory (PR #68 merged).
- [x] **Fix:** Corrected CI script path in `R-CMD-check.yml` (PR #68 merged).
- [x] **Docs:** Updated limerick formatting in vignette (PR #68 merged).
- [x] **Planning:** Raised issues #69 (Representation Analysis missing Male) and #70 (Animal Detection).
- [x] **PR #71 (Bug - Male Plot):** Merged.
- [x] **PR #72 (QA Validation):** Merged.
- [x] **PR #73 (Wikidata Props):** Merged.
- [x] **PR #74 (AGENTS.md Update):** Still pending due to merge conflicts, currently being resolved.

## Key Files Modified
- `AGENTS.md` (updated)
- `.claude/CURRENT_WORK.md` (conflict resolved)

## Next Session Should
1. **Push Resolved Branch:** Push `docs-update-r-setup-organization` to refresh PR #74.
2. **Merge PR #74:** Attempt to merge PR #74 again now that conflicts are resolved.
3. **Verify main:** Ensure all merged changes are present and correct in the `main` branch.
4. **Run targets:** Execute `targets::tar_make()` to generate new data and plots locally.
5. **Local Verification:** Check local website/vignettes (`memorial-analysis.qmd`) for merged features.
6. **Clean up:** Delete local branches.