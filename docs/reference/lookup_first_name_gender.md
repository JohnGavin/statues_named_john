# Look up gender for first names via the genderdata cascade

Internal helper (mockable in tests). Tries, in order, the "napp" (North
Atlantic Population Project historical census data, covering the UK
among other countries), "ipums" (US census 1789-1930), and "ssa" (US
Social Security data 1880-2012) methods provided by the \`gender\`
package, keeping the first method that returns a prediction for each
name. A prediction is only accepted when its confidence
(\`max(proportion_male, 1 - proportion_male)\`) is at least
\`threshold\`; names with no record in any source, or whose best
prediction is below the threshold (including "either"), are left
unresolved (\`NA\`) so the caller reports them as "Unknown" rather than
guessing.

## Usage

``` r
lookup_first_name_gender(names, threshold = 0.9)
```

## Arguments

- names:

  Character vector of first names (NA/"" are ignored).

- threshold:

  Numeric, minimum acceptable prediction confidence.

## Value

A character vector named by the unique, non-missing input names, valued
"Male", "Female", or \`NA_character\_\` when unresolved.

## Details

Never fails silently: if the \`gender\` package is unavailable, or every
lookup method errors, a \`warning()\` names how many lookups could not
be attempted and why; the affected names are returned as \`NA\`.
