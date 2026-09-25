# Classify gender based on first name or available metadata

Delegates to `classify_gender_from_subject()` (Wikidata P21 priority,
then a documented title/term override table, then a genderdata
name-lookup cascade). `known_gender`, when supplied and not
"unknown"/"", always wins outright and is returned unchanged.

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

"male", "female", "unknown", "animal", or "mixed" (lower-case)
