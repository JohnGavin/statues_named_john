# Get latest memorials from London Remembers

Fetches the most recently added memorials from the London Remembers
website.

## Usage

``` r
get_memorials_latest(pages = 1)
```

## Arguments

- pages:

  Integer, number of pages to fetch (default: 1)

## Value

A tibble containing memorial information with columns:

- title:

  Memorial title

- url:

  URL to memorial page

- memorial_type:

  Type of memorial (statue, plaque, etc.)

- subjects:

  Subjects commemorated

- location:

  Location of the memorial

## Examples

``` r
if (FALSE) { # \dontrun{
memorials <- get_memorials_latest(pages = 2)
} # }
```
