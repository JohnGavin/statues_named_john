# Current Work

**Last updated:** 2026-09-30 (session end)

Ephemeral session state. The durable record is `CHANGELOG.md`; the
previous version of this file (2025-12-04, R CMD check fixes) is in git
history.

## Done this session

- Issue grouping by priority (below). Group 1 fixed and merged in
  [#107](https://github.com/JohnGavin/statues_named_john/pull/107):
  - #105: the pipeline tracks package code (`imports = "statuesnamedjohn"`),
    lookup CSVs and `params.csv`.
  - #79: `README.md` rendered by targets.
  - #81: the vignette shows each target's code.
- Deployed vignette verified live: 5 "Show code for target" blocks, 0
  error patterns, line links match the merged plan file.
- Cross-project: [llm#1309](https://github.com/JohnGavin/llm/pull/1309)
  wires the own-package tracking check into `r_code_check.sh` and the
  session banner. Open; needs an explicit "merge" (touches hooks/rules).
- Filed [micromort#206](https://github.com/JohnGavin/micromort/issues/206)
  (same defect as #105).

## Next

1. [#108](https://github.com/JohnGavin/statues_named_john/issues/108):
   roborev 13861 follow-ups from #107. Start with #1 (`plan_files` cue)
   and #2 (Wikidata fetch re-runs on any `params.csv` edit).
2. Group 2, classification correctness: #102 (partly done in #103; a
   `fix/102-whole-percent` worktree exists), then #70.
3. Group 3, vignette layout and pkgdown deploy: #82, #80.
4. Group 4, CI and Nix setup: #51, #45, #53.
5. Group 5, more data sources: #20, #14, #21.

## Loose ends

- `vignettes/_targets.yaml` points at an old absolute store path
  (`/Users/johngavin/docs_gh/claude_rix/...`).
- `_targets/meta/meta` is tracked in git despite `.gitignore` (`/_targets/`).
  It is modified in worktree `feat/cc-20260930-193608` after copying main's
  store there for testing; left uncommitted.
- The local `main` checkout (`~/docs_gh/proj/data/statues_named_john`) is
  behind `origin/main`; pull before working there.
