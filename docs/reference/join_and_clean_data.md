# Normalize and Merge Data Sources

Combines Wikidata and OSM data into a single clean dataset.

## Usage

``` r
join_and_clean_data(wikidata_df, osm_df)
```

## Arguments

- wikidata_df:

  Tibble from fetch_wikidata_statues

- osm_df:

  Tibble from fetch_osm_statues

## Value

A combined tibble
