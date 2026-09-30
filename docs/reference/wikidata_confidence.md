# Confidence scores for a Wikidata person match

Confidence scores for a Wikidata person match

## Usage

``` r
wikidata_confidence()
```

## Value

Named numeric vector: `exact` (label or alias equals the subject),
`partial` (one contains the other) and `weak` (a human, but the names
differ). Read from `inst/extdata/params.csv`, their single home.
