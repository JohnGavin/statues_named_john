# Current Work

**Last updated:** 2026-10-04 (session end)

Ephemeral session state. The durable record is `CHANGELOG.md`.

## Done (2026-09-30 to 10-04)

- Group 1 (#105, #79, #81) merged in #107; #108 follow-ups in #110; the
  `dedent()` regression fixed in #111.
- The vignette is a Quarto dashboard (pages + tabsets, no TOC), merged in
  [#112](https://github.com/JohnGavin/statues_named_john/pull/112) and live
  at https://johngavin.github.io/statues_named_john/articles/memorial-analysis.html
- llm#1309: the own-package tracking check runs in `r_code_check.sh` and the
  session banner.

## Next (in order)

1. [#114](https://github.com/JohnGavin/statues_named_john/issues/114):
   `source` is NA for every record (`standardize_statue_data.R:55`
   masking). De-duplication ignores the glher > wikidata > osm preference;
   the interactive map has one colour. Snapshot the store first; report
   the before/after headline.
2. [#115](https://github.com/JohnGavin/statues_named_john/issues/115):
   dashboard follow-ups (Top Names captions misstate counts/percentages,
   John variants, source list, zoom in Code tabs, duplicate
   `inst/qmd/*_files`, map width).
3. [#113](https://github.com/JohnGavin/statues_named_john/issues/113):
   "The" and "World" counted as first names.
4. Group 2, classification correctness: #102, #70.
5. Group 3, vignette layout and pkgdown deploy: #82, #80.
6. Group 4, CI and Nix setup: #51, #45, #53. Group 5, data sources: #20, #14, #21.

## Loose ends

- DT is not in the nix shell; dashboard tables are `knitr::kable`. Adding DT
  needs `default.R` + a rebuild (ask first, per project AGENTS.md).
- `vignettes/_targets.yaml` points at an old absolute store path.
- `_targets/meta/meta` is tracked despite `.gitignore`; it is modified in
  worktree `feat/cc-20260930-193608` and left uncommitted.
- The local `main` checkout (`~/docs_gh/proj/data/statues_named_john`) is
  behind `origin/main`.
- micromort#206: micromort's pipeline does not track its own package.
