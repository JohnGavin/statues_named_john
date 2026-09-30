# Look up subjects on Wikidata: is X a person, and of which sex?

For each X, searches Wikidata and takes the first result that is a human
(P31 = Q5), reading its sex (P21). Confidence comes from
\[wikidata_confidence()\]: `exact` when the result's label or the
matched alias equals X (ignoring titles and punctuation), `partial` when
one contains the other, `weak` otherwise, and 0 when no human was found.
Errors are not caught, so an unreachable Wikidata fails fast; the
pipeline wraps this in \[fetch_optional_source()\].

## Usage

``` r
lookup_wikidata_people(x, pause = 0.2)
```

## Arguments

- x:

  Character vector of subjects (see \[candidate_subjects()\]).

- pause:

  Seconds to wait between searches (politeness to the API).

## Value

A tibble: `x`, `label`, `qid`, `sex` ("Male"/"Female"/NA), `confidence`.
