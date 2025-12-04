# Current Focus: Feature Implementation

## Active Branch
`main` (switched back after pushing feature branches)

## What I'm Doing
Implemented three key features/fixes locally and pushed them to GitHub. Created PRs for each.

## Progress
- [x] **Issue #69 (Bug - Male Plot):**
    -   Fix: Updated `analyze_by_gender` to use case-insensitive check for "male"/"female".
    -   Verification: Verified locally with reproduction script.
    -   Status: Pushed -> PR #71 Created.
- [x] **Issue #67 (QA Validation):**
    -   Feat: Added `generate_qa_sample()` in `R/qa_utils.R`.
    -   Verification: Function exists, but documentation build skipped locally due to `gender` package reload requirement (see Limitations).
    -   Status: Pushed -> PR #72 Created.
- [x] **Issue #20 (Wikidata Props):**
    -   Feat: Updated `get_statues_wikidata.R` to fetch `height` (P2048) and `dedicatedTo` (P825).
    -   Status: Pushed -> PR #73 Created.
- [x] **Docs:** Updated `AGENTS.md` to clarify nested nix-shell usage.

## Key Files Modified
- `R/analyze_statues.R`
- `R/qa_utils.R` (New)
- `R/get_statues_wikidata.R`
- `AGENTS.md`

## Next Session Should
1. **Monitor CI:** Check status of PRs #71, #72, #73.
2. **Review:** Ensure the new Wikidata columns don't break downstream schema validation (targets pipeline).
3. **Merge:** Merge passing PRs.
