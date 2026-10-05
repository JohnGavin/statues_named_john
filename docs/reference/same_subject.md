# Do two texts name the same subject?

Used by \[combine_statue_sources()\] to decide whether two nearby
records are the same memorial. Each text is reduced with
\[extract_subject()\] to its identifying words (object words such as
"statue" or "memorial", titles and articles are dropped). The subjects
match when one word set contains the other, or they share at least half
of their combined words.

## Usage

``` r
same_subject(a, b)
```

## Arguments

- a, b:

  Character vectors of subject or name text, recycled together.

## Value

Logical vector; `FALSE` when either text is `NA` or has no identifying
words.

## Examples

``` r
same_subject("Edith Cavell Memorial", "The Edith Cavell Memorial")
#> [1] TRUE
same_subject("Statue of Lord Herbert of Lea", "Florence Nightingale")
#> [1] FALSE
```
