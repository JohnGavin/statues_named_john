# One-row status summary for a fetched source

One-row status summary for a fetched source

## Usage

``` r
source_row(source, data)
```

## Arguments

- source:

  Source name.

- data:

  The fetched data frame.

## Value

A one-row tibble: `source`, `status` ("ok" or "empty"), `rows`, `reason`
(`NA`).
