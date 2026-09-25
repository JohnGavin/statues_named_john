# Standardize Statue Data to Common Schema

Converts statue data from any source to a standardized schema with
consistent column names, data types, and structure.

## Usage

``` r
standardize_statue_data(data, source)
```

## Arguments

- data:

  A tibble from any source (wikidata, osm, glher, etc.)

- source:

  Source identifier ("wikidata", "osm", "glher", "he")

## Value

A tibble with standardized schema: - id: character - unique identifier
(source_originalid) - name: character - statue/memorial name - subject:
character - who/what is commemorated - subject_gender: character -
gender (if determinable) - lat: numeric - latitude (WGS84) - lon:
numeric - longitude (WGS84) - location: character - human-readable
location - type: character - statue, memorial, plaque, etc. - material:
character - bronze, stone, etc. - year_installed: integer - year of
installation/inception - sculptor: character - creator name -
description: character - full description - image_url: character - URL
to image - source: character - data source - source_url: character -
link to source record - last_updated: Date - when data was retrieved

## Examples

``` r
if (FALSE) { # \dontrun{
wikidata_raw <- get_statues_wikidata()
wikidata_std <- standardize_statue_data(wikidata_raw, "wikidata")
} # }
```
