# Current Focus: Maintenance & Next Steps

## Active Branch
`main`

## What I'm Doing
Session complete. Project stable. Data analysis improved significantly.

## Progress
- [x] **CI Speed:** Restored to 3 mins (Reverted Magic Cache).
- [x] **Website:** Assets fixed, stats updated.
- [x] **Data:** Gender inference now falls back to `name` column, reducing "Unknown" from 99% to ~75%.
- [x] **Docs:** All documentation synchronized.

## Key Files Modified
- `R/analyze_statues.R` (Improved logic)
- `AGENTS.md` (Caching strategy updated)

## Next Session Should
1. **Verify Website:** Confirm `johngavin.github.io/statues_named_john/articles/memorial-analysis.html` shows the new stats (Male ~22%).
2. **Further Data Work:** To tackle the remaining 75% Unknowns, consider querying OSM for `subject:wikidata` tags or using a name-gender dictionary.