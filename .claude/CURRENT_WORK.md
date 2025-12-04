# Current Focus: Maintenance & Next Steps

## Active Branch
`refactor-rename-package` (PR Open)

## What I'm Doing
Renamed the package to `statuesnamedjohn` to reflect multi-source data.

## Progress
- [x] **Refactor:** Renamed `londonremembers` -> `statuesnamedjohn` globally.
- [x] **Validation:** `tar_make()` and `devtools::document()` passed locally.
- [x] **CI:** Pushed to trigger checks.

## Key Files Modified
- `DESCRIPTION`
- `package.nix`
- All `.R` files (renamed calls)
- `_targets.R`

## Next Session Should
1. **Merge PR:** `usethis::pr_merge_main()` if CI passes.
2. **Verify Website:** Ensure the site deploys correctly with the new package name (URLs might change if we update `_pkgdown.yml` url field to match repo, which we did).
