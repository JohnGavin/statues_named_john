# Classify gender based on first name or available metadata

A simple heuristic function. For robust analysis, relies on Wikidata
'gender' field.

## Usage

``` r
classify_gender(name, known_gender = NA)
```

## Arguments

- name:

  Character string

- known_gender:

  Optional character string (e.g., from Wikidata)

## Value

"Male", "Female", or "Unknown"
