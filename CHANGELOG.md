# Changelog

Session log: what was done, what failed and why, measurable changes, and
known limitations. Newest first.

## 2026-10-01 (#108: follow-ups to #107 from roborev 13861)

### Completed
- **Item 1:** `plan_files` has `cue = tar_cue(mode = "always")`, so a new file in
  `R/tar_plans/` reaches `target_code`. The file hashes still stop
  `target_code` from re-running when nothing changed.
- **Item 2:** a new value target `wikidata_match_confidence`
  (`wikidata_confidence()`) replaces `params_file` as the dependency of
  `wikidata_people_fetch`. Editing `classification_threshold` no longer
  re-runs the live Wikidata fetch; editing a confidence still does.
- **Item 3:** `dedent()` strips only the leading whitespace of the line the
  command starts on, as literal characters, so tab indentation works.
  - Lines inside multi-line strings are left exactly as written.
  - Arguments aligned under their call keep their alignment. Before, they
    lost it (`"  b)"`), a bug the new test found.
- **Item 4:** links stay on `blob/main`; documented why in
  `target_code_markdown()`. The re-rendered vignette is committed together
  with the plan edit, so a SHA pinned at render time would point at the
  commit *before* the edit. The deployed site (built from `main`) links
  correctly.

### Verification
- Scratch copy of project and store:
  - Item 2: a threshold edit re-ran the analysis but not the fetch. Control:
    a `wikidata_partial_confidence` edit re-ran the fetch.
  - Item 1: a new plan file's target appears in `target_code`. Without the
    cue, it does not (falsified).
- New `target_code` tests failed first, as expected (3 failures), then
  passed: `[ FAIL 0 | PASS 16 ]`.
- Full suite: `[ FAIL 0 | WARN 3 | SKIP 0 | PASS 243 ]` (the 3 warnings come
  from the existing network tests).
- `tar_make()`: 7 completed, 25 skipped. `wikidata_people` was unchanged, so
  the analysis did not re-run. Headline unchanged.
- The rendered vignette's 5 line links moved +6 (the new target); each was
  checked against the plan file.

### Failed Approaches
- The first falsification script edited the plan file with a broad line
  filter. It left a trailing comma and also changed the `pkgdown_site`
  block, which broke the scratch copy only. Redone on a fresh copy with one
  exact edit.

## 2026-09-30 (pipeline tracking: #105, #79, #81)

### Completed
- #105: `_targets.R` sets `tar_option_set(imports = "statuesnamedjohn")`,
  so editing a function in `R/` re-runs the targets that use it. The
  lookup tables (`gender_overrides.csv`, `non_name_words.csv`) are a file
  target (`lookup_files`) listed by the classifying targets;
  `wikidata_people_fetch` now also depends on `params.csv` (its match
  confidences live there). `params_file` uses a relative path.
- New `tests/testthat/test-pipeline_tracking.R`: on a scratch copy of the
  project and store, edits `analyze_by_gender()` and then
  `gender_overrides.csv`, and asserts `gender_analysis` and
  `johns_comparison` become outdated. Skips (does not pass) when no store
  exists or the analysis is already outdated.
- #79: `README.md` is rendered from `inst/qmd/README.qmd` by targets
  `readme_qmd` -> `readme_md`; `pkgdown_site` depends on it.
- #81: `target_commands()` reads each `tar_target()` command from the plan
  files as written; `target_code_markdown()` turns them into collapsed
  "Show code for target" blocks with a `#L<n>` link. The vignette shows
  one under five results (summary table, top names, plot, map,
  Johns-vs-women).

### Verification
- `tar_make()` run 1: 30 completed, 1 skipped. Run 2 with no changes: 29
  skipped; only `pkgdown_site` (cue always) and `pkgdown_verification` ran.
- Headline unchanged: 76 Johns (3%) vs 239 women (10%), 845 unknown (37%).
- Tests: `[ FAIL 0 | WARN 4 | SKIP 0 | PASS 240 ]` (3 warnings from the
  existing network tests; 1 from recording the new snapshot).
- Falsified the tracking test: in a scratch copy with `imports` removed
  and a store built that way, the code-edit check failed (line 47) while
  the lookup-table check still passed. With `imports` removed from an
  existing tracked store, the test skips rather than passing.

### Known limitations
- `vignettes/_targets.yaml` still points at an old absolute store path
  (`/Users/johngavin/docs_gh/claude_rix/...`); not changed here.
- The companion rule/check in `JohnGavin/llm` (#105 "Mandatory
  everywhere") is not part of this change.

## 2026-09-30

### Completed
- #102 items 1 and 3 (#103): displayed percentages are whole numbers
  everywhere via `format_percent()` ("<1%" for small non-zero groups,
  "n/a" for a missing total); stored values keep 2 dp.
- "Statue of X": `extract_subject()` reads X from text such as "Statue of
  Sir John Millais in North Forecourt of Tate Gallery" before the name
  rules run, so they see "Sir John Millais", not "Statue". Also used for
  the John count.
- Wikidata person lookup for the X that the name rules still cannot
  decide: `lookup_wikidata_people()` (is X a human, and which sex;
  confidence 1.0 exact / 0.7 partial). An optional pipeline step
  (`wikidata_people_fetch`), recorded in `source_status`, retried when
  not "ok".
- One classification threshold in `inst/extdata/params.csv`
  (`classification_threshold`, 0.9), read by `get_param()` and used by
  both the first-name predictions and the Wikidata matches. Set it to 1
  to keep only certain answers. A file target, so editing it re-runs the
  analysis.
- Mrs/Miss/Ms/Mr added as titles ("Mrs Siddons" and "Mrs Ramsay
  Macdonald" were Male: the surname was read as a first name); "siege"
  added to non-name words.
- Headline, same 2,301 statues: women 229 -> 239 (10%), Johns 73 -> 76
  (3%), unknown 886 -> 845 (37%). Per-statue diff: 44 changed (Unknown ->
  Male 33, Unknown -> Female 9, Male -> Female 1, Male -> Unknown 1).

### Failed Approaches
- The Wikidata lookup, as built, resolves none of the statues: once X is
  read, titles and first names already decide the 27 people the
  prototype found on Wikidata. The 10 subjects left are not people
  (Hercules, Neptune, the Bali bombings, ...) except "Eighth Duke of
  Devonshire", which the Wikidata search does not find. It stays as the
  fallback for people without a known first name.

### Known Limitations
- targets does not see edits to package code (loaded with
  `pkgload::load_all()`), so results can be stale after a code change
  until the affected targets are invalidated.
- Mythical figures and personifications are gendered like people:
  "Diana with Fawn" is Female, "Father Thames" is Male.

## 2026-09-29

### Completed
- #98 item 1 (#100): a statue of a woman together with a man ("Mixed")
  now counts as a statue of a woman in the headline. This resolves the
  2026-09-27 limitation "Mixed statues are excluded from the women count".
- #98 items 2-15: classification corrections, including a fix to the
  root cause of non-statues being counted as women. The genderdata name
  lists resolve ordinary words as first names ("Site" = Female,
  "Memorial" = Female, "Parish"/"Corpus"/"Tomb" = Male), so entries such
  as "Site of Anchor Brewery" and "Memorial Bench" were counted as statues
  of women. Candidate first names must now be capitalised and not in
  `inst/extdata/non_name_words.csv`; church/school/college dedications
  and "Site of ..." segments are not people; a title (Duke, Lady, ...)
  beats an animal word; "and"/"&" split people in any case.
- Headline, same 2,301 statues: women 260 -> 229 (10.0%; 222 women only
  + 7 with a man), Johns 74 -> 73 (3.2%; "St John the Evangelist Church"
  was counted as a John), unknown 833 -> 886. Per-statue diff: 53 changed,
  all towards Unknown (29 Female, 22 Male, 2 Mixed); none gained a wrong
  label.

### Failed Approaches
- Splitting people on commas (#98 item 3 as written): in this data a comma
  almost always introduces a location ("Statue of Hercules, Trent Park"),
  so it turned place names into people (13 Unknown -> Male/Female, 4 new
  false Mixed). Reverted; commas are not person separators.
- Resolving people before animals whenever any name resolved: the lookup
  also resolves animals' names ("Hodge the Cat" -> Male). Narrowed so only
  an explicit title beats an animal word.

### Known Limitations
- Many real statues are titled "Statue of X" / "Tomb of X"; the first
  word is taken as the candidate first name, so these stay Unknown
  (e.g. "Tomb of Blanche Roosevelt Macchetta"). Stripping such prefixes
  would reduce the 886 Unknown.
- Ambiguous first names follow the name lists: "Camille Silvy" (a man)
  resolves Female.

## 2026-09-27

### Completed
- Merged #96 (site re-rendered with GLHER) and #97 (this changelog).
  Live vignette verified: 2,301 statues; Johns 74 (3.2%), women 251
  (10.9%), unknown 833 (36.2%); no error text.
- Removed 10 finished worktrees from the 2026-09-24/25 work.
- Posted a reply on #61 explaining how the slow pkgdown build was
  diagnosed (pak's per-package "Built" vs "Installed" lines).
- Triaged the 3 open roborev reviews for this repo (10447, 10448, 10451,
  on the original #84 commits). The High finding was already fixed
  (127ef95); the still-valid Medium/Low findings are filed as #98 and the
  reviews closed with a pointer to it. Repo roborev: 26/26 failed verdicts
  addressed.

### Failed Approaches
- First post-merge fetch of the live vignette still showed the #93
  numbers although gh-pages and the Pages build were already correct; a
  re-fetch minutes later showed the new page. Poll the deployed page
  for a headline string before concluding a deploy failed.
- `roborev comment <id>` takes job IDs, not review IDs ("job not found");
  map via `reviews.job_id` or use `--job`.

### Known Limitations
- #98: "Mixed" statues (9) are excluded from the women count and the
  headline message; animal detection outranks person titles ("Duke of
  Wellington on horse" -> Animal); the person-split regex misses
  "A, B" and "A And B".
- PR #83 (December #7/#8 vignette work) is still open against an old base.

## 2026-09-25

### Completed
- #84: gender classification via the `gender` package + `genderdata`, with
  a small documented override table; unknown genders are now reported
  instead of silently guessed (#89; #88 closed as superseded).
- Nix: dropped WikidataQueryServiceR and `llvmPackages.openmp`, added
  `genderdata` (#87).
- #90: OSM fetch fails fast — bounded per-request timeout, only HTTP
  429/5xx retried, DNS/connection errors not retried, any failed query
  aborts (no partial data), queries overpass-api.de (#91).
- Vignette render: absolute targets store path; `_targets.yaml` store made
  relative (it pinned an old `claude_rix` checkout); site build depends on
  the vignette; `gender_analysis` feeds the vignette (#92).
- Site re-rendered with the #84 classification (#93).
- #94: GLHER fetched from its public Arches search API
  (`/search/resources`) using the monument-type concept "Statue": 302
  records. New `source_status` target (ok / empty / unavailable + reason).
  `pkgdown_verification` runs after `pkgdown_site`; the vignette `.qmd` is
  a tracked file target (#95).
- Site re-rendered with GLHER (#96, open).

Headline (`johns_comparison`):

| | #93 | #96 (with GLHER) |
|---|---|---|
| Total statues | 2,138 | 2,301 |
| Johns | 73 (3.4%) | 74 (3.2%) |
| Women | 237 (11.1%) | 251 (10.9%) |
| Unknown gender | 749 (35.0%) | 833 (36.2%) |

### Failed Approaches
- `httr::RETRY()` for Overpass: it also retries request errors, so a dead
  host took 24.9 s. Replaced by an explicit loop that retries only 429/5xx.
- osmdata's default Overpass mirror (overpass.kumi.systems): HTTP 504 after
  66 s for the London `memorial=statue` query; overpass-api.de answered in
  13 s. Now the default (override with option
  `statuesnamedjohn.overpass_url`).
- GLHER `/search?format=tilecsv`: returns the GLHER search web page, not
  CSV. GLHER `/search/export_results`: HTTP 403 ("You do not have
  permission to download exports") without an account.
- GLHER plain-text "statue" search: 899 hits including gardens, offices, a
  nunnery. The monument-type concept filter returns 302 statues.
- Pipeline runs failed on transient upstream errors (Overpass 429/504,
  Wikidata 502, a local DNS outage); the fail-fast changes turned these from
  a 23-minute silent stall into an error within ~1.5 minutes.

### Accuracy / Metrics
- Tests: 57 -> 150 passing (FAIL 0; 3 known network warnings: Art UK 403 x2,
  invalid-hostname test).
- Data sources: wikidata 52, osm 3,900, glher 0 -> 302.

### Known Limitations
- roborev merge-gate script cannot read schema-v2 reviews, so it returns
  indeterminate on every PR (JohnGavin/llm#1267); its findings table
  crashes with a SyntaxError (JohnGavin/llm#1263).
- One GLHER name arrives double-encoded at source ("La Délivrance").
- Historic England's reuse terms for automated GLHER queries not checked.
- `_targets/meta/meta` is tracked despite `.gitignore` and records absolute
  paths; left uncommitted after local runs.
- 5 unmerged commits from 2025-12-08 (#7/#8 vignette work) remain on
  `feat/cc-20260924-100825`; its `default.nix` does not evaluate
  (`codex-cli` missing).
