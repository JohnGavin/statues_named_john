# Changelog

Session log: what was done, what failed and why, measurable changes, and
known limitations. Newest first.

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
