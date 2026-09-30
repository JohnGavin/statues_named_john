# Look up gender for first names via the genderdata cascade

Internal helper (mockable in tests). Tries, in order, the "napp" (North
Atlantic Population Project historical census data, covering the UK
among other countries), "ipums" (US census 1789-1930), and "ssa" (US
Social Security data 1880-2012) methods provided by the \`gender\`
package. A prediction is only accepted when its confidence
(\`max(proportion_male, 1 - proportion_male)\`) is at least
\`threshold\`. A name whose prediction from one method is missing OR
below the threshold falls through to the next method, so a name that is
ambiguous in the UK historical data (napp) can still be resolved from US
data (ipums, ssa) if it is unambiguous there. Names with no confident
prediction from any method are left unresolved (\`NA\`) so the caller
reports them as "Unknown" rather than guessing.

## Usage

``` r
lookup_first_name_gender(
  names,
  threshold = get_param("classification_threshold")
)
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
