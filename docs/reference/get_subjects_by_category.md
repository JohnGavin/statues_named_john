# Get subjects by category

Fetches subjects (people, groups, buildings) from a specific category.

## Usage

``` r
get_subjects_by_category(category, pages = 1)
```

## Arguments

- category:

  Character string, category name (e.g., "Literature", "Medicine")

- pages:

  Integer, number of pages to fetch (default: 1)

## Value

A tibble containing subject information

## Examples

``` r
if (FALSE) { # \dontrun{
literature <- get_subjects_by_category("Literature", pages = 2)
} # }
```
