# Markdown blocks showing the code of pipeline targets

For each target, a collapsed "Show code" block holding its command and a
link to where it is defined. A vignette prints one with
`cat(blocks[["target_name"]])` in a chunk with `results: asis`.

## Usage

``` r
target_code_markdown(
  code,
  repo_url = "https://github.com/JohnGavin/statues_named_john/blob/main"
)
```

## Arguments

- code:

  Data frame from
  [`target_commands()`](https://johngavin.github.io/statues_named_john/reference/target_commands.md).

- repo_url:

  Base URL for links to the plan files, or `NULL` for no links. Links
  point at `main` on purpose (#108): line numbers come from the working
  tree at render time, and the re-rendered vignette is committed
  together with the plan edit, so the deployed site (built from `main`)
  links to the right lines. Pinning the current commit SHA instead would
  point at the commit before the edit. Links from a branch render match
  only once that branch is merged.

## Value

Named character vector of markdown, one element per target.
