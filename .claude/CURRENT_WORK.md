# Current Work

**Last updated:** 2026-10-01 (session end)

Ephemeral session state. The durable record is `CHANGELOG.md`.

## Done (2026-09-30 / 10-01)

- Group 1 (#105, #79, #81) merged in
  [#107](https://github.com/JohnGavin/statues_named_john/pull/107).
  The pipeline tracks package code, lookup CSVs and `params.csv`;
  `README.md` and the vignette's per-target code come from targets.
- [#108](https://github.com/JohnGavin/statues_named_john/issues/108)
  (roborev 13861 follow-ups) merged in
  [#110](https://github.com/JohnGavin/statues_named_john/pull/110).
- [#111](https://github.com/JohnGavin/statues_named_john/pull/111) (open,
  needs explicit merge): fixes #110's `dedent()` alignment regression and
  adds a test for the Wikidata fetch dependency (roborev 13889).
- llm: [#1309](https://github.com/JohnGavin/llm/pull/1309) merged. The
  own-package tracking check runs in `r_code_check.sh` and the session
  banner.

## Next

1. Merge #111. Then confirm the pkgdown deploy and the live vignette's
   "Defined in" links: after #110/#111 they are #L97/#L107/#L118/#L131/#L162.
   The #110 deploy run 36917112935 was still installing dependencies
   at session end.
2. Group 2, classification correctness: #102 (partly done in #103; a
   `fix/102-whole-percent` worktree exists), then #70.
3. Group 3, vignette layout and pkgdown deploy: #82, #80.
4. Group 4, CI and Nix setup: #51, #45, #53.
5. Group 5, more data sources: #20, #14, #21.

## Loose ends

- `vignettes/_targets.yaml` points at an old absolute store path.
- `_targets/meta/meta` is tracked despite `.gitignore`; it is modified in
  worktree `feat/cc-20260930-193608` and left uncommitted.
- The local `main` checkout (`~/docs_gh/proj/data/statues_named_john`) is
  behind `origin/main`.
- micromort#206: micromort's pipeline does not track its package;
  `r_code_check.sh` fails there until it is fixed.
