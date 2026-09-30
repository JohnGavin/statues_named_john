# Extract the subject X from text such as "Statue of X"

Strips a leading object word ("Statue of", "Bust of", "Tomb of",
"Monument to", "Memorial of", ...) and then a trailing location ("... in
North Forecourt of Tate Gallery", "..., Trent Park"). Text without such
a prefix is returned unchanged: a trailing phrase is only treated as a
location once the prefix shows the text describes an object ("Duke of
Wellington on horse" is left alone).

## Usage

``` r
extract_subject(text)
```

## Arguments

- text:

  Character vector.

## Value

Character vector of the same length.

## Examples

``` r
extract_subject("Statue of Sir John Millais in North Forecourt of Tate Gallery")
#> [1] "Sir John Millais"
```
