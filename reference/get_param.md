# Read a project parameter from the single parameters file

Parameters live in one place, `inst/extdata/params.csv` (columns `name`,
`value`, `note`). The main one is `classification_threshold`: the
minimum confidence (0-1) needed to accept a gender, whether it comes
from a first-name prediction or a Wikidata person match. Set it to 1 to
accept only certain answers.

## Usage

``` r
get_param(name)
```

## Arguments

- name:

  Parameter name.

## Value

The parameter value as a number. Aborts if the value is not a number, or
if a threshold or confidence is outside 0-1.

## Examples

``` r
get_param("classification_threshold")
#> [1] 0.9
```
