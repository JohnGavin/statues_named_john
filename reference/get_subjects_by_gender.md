# Get subjects by gender

Helper function to filter subjects by gender-related keywords. Note:
This is an approximation based on available data.

## Usage

``` r
get_subjects_by_gender(gender = "female", pages = 5)
```

## Arguments

- gender:

  Character string: "male", "female", or specific terms

- pages:

  Integer, number of search pages to fetch

## Value

A tibble containing subjects matching the gender criteria

## Examples

``` r
if (FALSE) { # \dontrun{
women <- get_subjects_by_gender("female", pages = 5)
} # }
```
