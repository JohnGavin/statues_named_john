# Data Sources Research

## Primary Sources identified
Based on research, the following sources are recommended for the `statues_named_john` project:

### 1. Wikidata (Preferred)
- **Method**: SPARQL queries via `WikidataQueryServiceR` or `httr`.
- **Data Points**: 
    - Subject (and their gender `P21`)
    - Instance of (`P31`): Statue (`Q179700`), Public Art (`Q557908`)
    - Location (`P131`: London)
    - Creator/Artist (`P170` and their gender)
    - Inception date (`P571`)
    - Coordinates (`P625`)
- **Pros**: Highly structured, easy to filter by gender/name (e.g. "John"), links to Wikipedia.
- **Cons**: Might be incomplete for smaller/newer memorials.

### 2. OpenStreetMap (OSM)
- **Method**: `osmdata` R package.
- **Data Points**:
    - Location (lat/long)
    - Tags: `historic=memorial`, `memorial=statue`, `name=*`, `subject:wikidata=*`
- **Pros**: Excellent geospatial coverage, often links to Wikidata.
- **Cons**: Attribute data (like subject gender) is not stored directly, must be linked.

### 3. Historic England (Official)
- **Method**: Downloadable GIS/CSV data or scraping.
- **Pros**: Authoritative for listed structures.
- **Cons**: "Listed Building" data is broad; filtering for "statues of specific people" is harder than Wikidata.

### 4. Art UK / London Remembers
- **Method**: Web scraping.
- **Pros**: Rich descriptive text, photos (urls).
- **Cons**: Unstructured text requires parsing; scraping is slower and more brittle than APIs.

## Recommendation
**Hybrid Approach**: 
1. Use **Wikidata** as the primary backbone for the "Subject Analysis" (Gender/Name counts).
2. Use **OSM** to validate locations and find items missing from Wikidata.
3. Supplement with **Art UK/London Remembers** scraping only where data is missing.