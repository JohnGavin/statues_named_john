# Read the command of every target defined in plan files

Parses each plan file and returns the command of every `tar_target()`
call, as written in the file (comments and layout kept), with the line
it starts on. The only change is to indentation: the whitespace its
later lines share is removed, up to the width of the text before the
command on its first line, so code inside `{` and arguments aligned
under a call both keep their relative layout. Lines inside multi-line
strings are left untouched.

## Usage

``` r
target_commands(files)
```

## Arguments

- files:

  Paths to plan files, e.g.
  `list.files("R/tar_plans", full.names = TRUE)`.

## Value

A data frame with columns `name`, `command`, `file` and `line`, one row
per target.

## Examples

``` r
plan <- tempfile(fileext = ".R")
writeLines(c(
  "plan <- list(",
  "  tar_target(x, 1 + 1),",
  "  tar_target(y, {",
  "    x * 2  # double it",
  "  })",
  ")"
), plan)
target_commands(plan)
#>   name                    command                               file line
#> 1    x                      1 + 1 /tmp/RtmpM7JzgJ/file20df1fe08c61.R    2
#> 2    y {\n  x * 2  # double it\n} /tmp/RtmpM7JzgJ/file20df1fe08c61.R    3
```
