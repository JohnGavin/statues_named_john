# Art UK: Superior Data Source for UK Statue Analysis

**Date:** 2025-11-12
**Discovery:** User-identified primary source for UK public statues

---

## Executive Summary

**Art UK is the definitive source** for UK public statue data, containing **14,800+ public sculptures** digitized and available online. This is far superior to the sources previously researched (Wikidata, OSM, GLHER).

### Key Advantages Over Previous Sources

| Source | Coverage | Data Quality | Accessibility |
|--------|----------|--------------|---------------|
| **Art UK** | **14,800+ UK sculptures** | **Professional curation** | **Website only (no API found)** |
| Wikidata | 50-100 London statues | Crowd-sourced, 70-80% metadata | SPARQL API ✅ |
| OSM | 150-300 London features | Crowd-sourced, 40-50% metadata | Overpass API ✅ |
| GLHER | 100-200 London monuments | Professional, 90-95% metadata | CSV export ✅ |

---

## Art UK: The Primary Source

### Overview

**Website:** https://artuk.org/
**Collection:** 14,800+ public sculptures across the UK
**Project:** "Landmark project puts all the nation's public sculptures online"
**Status:** Completed digitization project, fully searchable online

### Coverage

- **Total sculptures:** 14,800+
- **Geographic scope:** Entire United Kingdom
- **Includes:** Public statues, monuments, memorials, outdoor sculptures
- **Fields available (via web interface):**
  - Title
  - Artist/Sculptor
  - Location (specific address/area)
  - Work type (statue/sculpture/monument)
  - Date
  - Material
  - Collection owner

### Data Access Challenges

**❌ No Public API found**
- Extensive search found no Art UK API documentation
- Web requests return 403 Forbidden for automated access
- Website appears to block scraping/automated access

**❌ No CSV/JSON Download found**
- No evidence of bulk data export options
- Data only accessible via web interface search

**✅ Museum Data Service (Future)**
- Art UK is collaborating on the [Museum Data Service](https://www.theartnewspaper.com/2024/09/17/enormous-milestone-museums-platform-designed-host-100-million-object-records-launches-uk)
- Launched September 2024, aims to host 100 million object records
- May eventually provide programmatic access to Art UK data
- Partnership: Art UK + Collections Trust + University of Leicester
- Funding: Bloomberg Philanthropies + Arts and Humanities Research Council

---

## The PACK & SEND Study

### Study Details

**Source:** https://www.packsend.co.uk/whether-subject-or-artist-uk-publicly-owned-statues-are-very-much-a-mans-world/
**Methodology:** Analyzed 4,912 publicly-owned sculptures using **Art UK database**
**Date:** 2020 (referenced in Hyperallergic article August 2020)

### Key Findings

#### Overall Statistics

| Category | Count | Percentage |
|----------|-------|------------|
| **Total sculptures analyzed** | 4,912 | 100% |
| **With gender assigned** | 1,470 | 30% |
| **Men** | 1,119 | 76% of gendered |
| **Women** | 351 | 24% of gendered |

#### Named vs Unnamed Statues

| Gender | Named | Unnamed |
|--------|-------|---------|
| **Women** | 36% | 64% |
| **Men** | 68% | 32% |

**Of 892 named statues:**
- Women: 128 (14%)
- Men: 764 (86%)
- **Men named "John": 82**

#### Artist Gender

| Artist Gender | Count |
|---------------|-------|
| Men | 1,521 (79%) |
| Women | 393 (21%) |

**Sculptures by subject & artist gender:**
- Men of men: 768
- Women of women: 213
- Women of men: 93
- Men of women: 44

### The "John" Claim

**Original claim from PACK & SEND:**
> "In the United Kingdom, public statues of women just barely outnumber those of men named John"

**Actual numbers:**
- Total women statues: 351
- Men named "John": 82
- **Named women statues: 128**

**Reality:** The claim is misleading. While total women statues (351) outnumber Johns (82), **named women statues (128) outnumber Johns (82)** but only by 1.56x.

---

## Implications for Our Project

### What We Can Do

1. **✅ Use existing published statistics**
   - PACK & SEND study provides UK-wide validated numbers
   - Can reference their methodology and findings
   - No need to recreate their full analysis

2. **✅ Focus on London-specific analysis**
   - Use Wikidata + OSM + GLHER for London data with coordinates
   - Compare London vs UK-wide statistics
   - Provide interactive map (which PACK & SEND doesn't have)

3. **✅ Add transparency and reproducibility**
   - Our analysis will be fully reproducible
   - Code and methodology publicly available
   - Deduplication methods documented
   - Unlike PACK & SEND, show all work

4. **✅ Provide interactive visualization**
   - Art UK search interface is static
   - We can create interactive Leaflet maps with hover popups
   - Allow users to explore spatial distribution
   - Filter by gender, date, material, etc.

### What We Cannot Do (Yet)

1. **❌ Access full Art UK dataset programmatically**
   - No API available
   - Website blocks automated access
   - Would need to contact Art UK directly for data access

2. **❌ Match PACK & SEND's UK-wide coverage**
   - Their 4,912 sculptures across entire UK
   - Our sources focus on London only
   - Could expand later if Art UK provides API

### Recommended Approach

**Phase 1: London Analysis (Current Project)**
- Continue with Wikidata + OSM + GLHER for London
- 150-300 unique statues with coordinates
- Interactive map with hover popups
- Gender analysis for London specifically
- Compare London vs UK-wide statistics from PACK & SEND

**Phase 2: UK-Wide (Future - if Art UK API becomes available)**
- Contact Art UK about data access via Museum Data Service
- Request API access or bulk data export
- Expand analysis to entire UK
- Validate/extend PACK & SEND findings

---

## Data Quality Comparison

### PACK & SEND Study (via Art UK)

**Strengths:**
- ✅ Comprehensive UK coverage (4,912 sculptures)
- ✅ Professional curation via Art UK
- ✅ Clear methodology documented
- ✅ Validated gender assignments

**Weaknesses:**
- ❌ No downloadable dataset
- ❌ No geographic coordinates provided
- ❌ No interactive visualization
- ❌ Cannot verify/reproduce analysis
- ❌ Published findings only, no raw data

### Our Approach (Wikidata + OSM + GLHER)

**Strengths:**
- ✅ Geographic coordinates for all statues
- ✅ Interactive map with hover popups
- ✅ Fully reproducible with code
- ✅ API access for data retrieval
- ✅ Spatial deduplication documented
- ✅ Open source and transparent

**Weaknesses:**
- ❌ London-only (not UK-wide)
- ❌ Smaller sample size (150-300 vs 4,912)
- ❌ Crowd-sourced data quality varies
- ❌ Gender classification less rigorous

---

## Validation of "Statues for Equality" Claim

### Original Claim

From the Statues for Equality campaign:
> "More statues of men named John than all women"

### Evidence from PACK & SEND Study

**UK-Wide:**
- Named women statues: 128
- Men named "John": 82
- **Claim is FALSE for UK**

**Possible interpretation:**
- If including unnamed women: 351 women vs 82 Johns
- If counting all Johns (not just statues): Different story

### Our London Analysis Will Show

- Johns in London: TBD from our data
- Women in London: TBD from our data
- Geographic distribution on interactive map
- Comparison to UK-wide statistics

---

## Action Items

### Immediate (No Art UK API)

1. ✅ Document Art UK as the gold standard source
2. ✅ Reference PACK & SEND study statistics
3. ✅ Continue with London-focused multi-source approach
4. ✅ Create interactive map Art UK doesn't provide
5. ✅ Add UK-wide context from published statistics

### Future (If Art UK API Available)

1. ⏳ Contact Art UK re: Museum Data Service API access
2. ⏳ Request bulk data export or developer API key
3. ⏳ Expand analysis to UK-wide coverage
4. ⏳ Validate PACK & SEND findings independently
5. ⏳ Create comprehensive UK statue database

---

## References

1. **Art UK Public Sculpture Project**
   https://artuk.org/discover/stories/landmark-project-puts-all-the-nations-public-sculptures-online

2. **PACK & SEND Study**
   https://www.packsend.co.uk/whether-subject-or-artist-uk-publicly-owned-statues-are-very-much-a-mans-world/

3. **Hyperallergic Coverage**
   https://hyperallergic.com/586720/uk-study-women-statues-john-statues/

4. **Art UK London Report**
   https://artuk.org/discover/stories/revealing-the-facts-and-figures-of-londons-statues-and-monuments

5. **Museum Data Service Launch**
   https://www.theartnewspaper.com/2024/09/17/enormous-milestone-museums-platform-designed-host-100-million-object-records-launches-uk

---

## Conclusion

**Art UK is the superior data source**, but access limitations mean we must:

1. Use published statistics from PACK & SEND for UK-wide context
2. Focus on London-specific analysis with available APIs
3. Provide value through interactive visualization and reproducibility
4. Position for future expansion when Art UK API becomes available

Our contribution will be:
- **Interactive maps** (Art UK doesn't have)
- **Reproducible analysis** (PACK & SEND doesn't provide)
- **Geographic visualization** (PACK & SEND doesn't offer)
- **Open source code** (Neither Art UK nor PACK & SEND provide)

---

**Status:** Art UK identified as best source, but API access blocked.
**Next step:** Proceed with London multi-source approach, add UK-wide context from published studies.
