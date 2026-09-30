# Format a percentage for display

The single place where displayed percentages are rounded (#102). Stored
values keep 2 decimal places; everything shown to readers (headline,
vignette text, table columns, plot labels) is rounded to the nearest
whole percent, with halves rounded up (12.5 always computed from the raw
counts, never from an already-rounded percentage, so a value is never
rounded twice.

A non-zero share that would round to 0 is shown as "\<1 but real group
(e.g. 7 of 2,301) is never displayed as "0

## Usage

``` r
format_percent(count, total)
```

## Arguments

- count:

  Numeric vector of counts.

- total:

  Numeric vector of totals (recycled against \`count\`).

## Value

Character vector such as "10 total is missing or zero.

## Examples

``` r
format_percent(229, 2301)
#> [1] "10%"
format_percent(7, 2301)
#> [1] "<1%"
```
