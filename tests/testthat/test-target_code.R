write_plan <- function(lines) {
  path <- withr::local_tempfile(fileext = ".R", .local_envir = parent.frame())
  writeLines(lines, path)
  path
}

test_that("target_commands() reads positional and named commands as written", {
  plan <- write_plan(c(
    "plan <- list(",
    "  tar_target(x, 1 + 1),",
    "  tar_target(",
    "    y,",
    "    {",
    "      x * 2  # double it",
    "    },",
    "    format = \"rds\"",
    "  ),",
    "  tar_target(name = z, command = paste(x, y))",
    ")"
  ))
  code <- target_commands(plan)
  expect_equal(code$name, c("x", "y", "z"))
  expect_equal(code$command[1], "1 + 1")
  expect_equal(code$command[2], "{\n  x * 2  # double it\n}")
  expect_equal(code$command[3], "paste(x, y)")
  expect_equal(code$line, c(2L, 5L, 10L))
})

test_that("target_commands() rejects a target defined twice", {
  plan <- write_plan(c("list(tar_target(x, 1), tar_target(x, 2))"))
  expect_snapshot(error = TRUE, target_commands(plan))
})

test_that("target_commands() reads this project's plan files", {
  plans <- test_path("..", "..", "R", "tar_plans")
  skip_if_not(dir.exists(plans), "plan files are not shipped with the package")
  code <- target_commands(list.files(plans, full.names = TRUE))
  expect_true(all(c("gender_analysis", "category_plot", "johns_comparison") %in% code$name))
  expect_match(code$command[code$name == "category_plot"], "ggplot\\(")
})

test_that("target_code_markdown() gives a collapsed block with a line link per target", {
  code <- data.frame(name = c("x", "y"), command = c("1 + 1", "x * 2"),
                     file = "R/tar_plans/p.R", line = c(7L, 9L))
  md <- target_code_markdown(code, repo_url = "https://example.org")
  expect_named(md, c("x", "y"))
  expect_match(md[["x"]], "<details>", fixed = TRUE)
  expect_match(md[["x"]], "[R/tar_plans/p.R#L7](https://example.org/R/tar_plans/p.R#L7)", fixed = TRUE)
  expect_match(md[["y"]], "```r\nx * 2\n```", fixed = TRUE)
  expect_match(target_code_markdown(code, repo_url = NULL)[["x"]], "Defined in R/tar_plans/p.R#L7:",
               fixed = TRUE)
})
