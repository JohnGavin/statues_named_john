# Fetch an optional data source, recording its status explicitly

Evaluates `expr` (a fetch such as
[`get_statues_glher()`](https://johngavin.github.io/statues_named_john/reference/get_statues_glher.md)).
A failure does not stop the pipeline but is recorded as `"unavailable"`
with its reason, so an optional source that cannot be fetched is never
mistaken for one that returned no records (#94). Required sources
(Wikidata, OSM) should be called directly so their failures stop the
pipeline.

## Usage

``` r
fetch_optional_source(source, expr)
```

## Arguments

- source:

  Source name, e.g. `"glher"`.

- expr:

  Expression returning a data frame. Evaluated lazily inside this
  function so its error can be captured.

## Value

A list with `data` (the fetched tibble, or a zero-row tibble when
unavailable) and `status` (a one-row tibble: `source`, `status` one of
"ok"/"empty"/"unavailable", `rows`, `reason`).
