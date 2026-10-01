# Regression check for #105: editing package code or a lookup table must
# make the downstream targets outdated. Before #105, _targets.R loaded the
# package without tar_option_set(imports = ...), so tar_make() skipped
# everything after a code change and results went stale silently.
#
# Works on a scratch copy of the project (with its targets store), so the
# real store and source are never touched. Needs a store in which
# gender_analysis is up to date; otherwise it cannot tell tracking from
# "everything was outdated anyway", and it skips rather than passing.

copy_project <- function(root, dest) {
  keep <- c("DESCRIPTION", "NAMESPACE", "R", "inst", "_targets.R", "_targets.yaml", "_targets")
  keep <- keep[file.exists(file.path(root, keep))]
  file.copy(file.path(root, keep), dest, recursive = TRUE)
  dest
}

outdated_in <- function(dir) {
  withr::with_dir(dir, targets::tar_outdated(
    names = c("gender_analysis", "johns_comparison"),
    reporter = "silent"
  ))
}

test_that("editing package code or a lookup table outdates the analysis (#105)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("targets")
  root <- normalizePath(test_path("..", ".."))
  skip_if_not(file.exists(file.path(root, "_targets.R")), "no _targets.R (installed package)")
  skip_if_not(dir.exists(file.path(root, "_targets", "objects")), "no targets store; run tar_make()")

  scratch <- withr::local_tempdir()
  copy_project(root, scratch)
  skip_if(length(outdated_in(scratch)) > 0,
          "analysis targets already outdated; run tar_make() first")

  # 1. A function body in R/
  fn_file <- file.path(scratch, "R", "analyze_statues.R")
  src <- readLines(fn_file)
  at <- grep("^analyze_by_gender <- function", src)
  expect_length(at, 1)
  # First line of the body: the signature may span several lines
  body_start <- at - 1 + grep("\\{\\s*$", src[at:length(src)])[1]
  src <- append(src, "  invisible(NULL) # #105 tracking probe", after = body_start)
  writeLines(src, fn_file)
  expect_true(all(c("gender_analysis", "johns_comparison") %in% outdated_in(scratch)))

  # 2. A lookup table in inst/extdata (restore the code first)
  file.copy(file.path(root, "R", "analyze_statues.R"), fn_file, overwrite = TRUE)
  expect_length(outdated_in(scratch), 0)
  csv <- file.path(scratch, "inst", "extdata", "gender_overrides.csv")
  cat("probe_term_105,Female\n", file = csv, append = TRUE)
  expect_true(all(c("gender_analysis", "johns_comparison") %in% outdated_in(scratch)))
})

# #108 item 2: the live Wikidata fetch depends on the match confidences, not
# on the whole params.csv. tar_outdated() alone cannot show this (it treats
# everything downstream of a changed file as outdated), so the cheap value
# targets are rebuilt in the scratch copy first; the fetch itself never runs.
test_that("the Wikidata fetch re-runs only when a match confidence changes (#108)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("targets")
  root <- normalizePath(test_path("..", ".."))
  skip_if_not(file.exists(file.path(root, "_targets.R")), "no _targets.R (installed package)")
  skip_if_not(dir.exists(file.path(root, "_targets", "objects")), "no targets store; run tar_make()")

  scratch <- withr::local_tempdir()
  copy_project(root, scratch)
  fetch_outdated <- function() {
    withr::with_dir(scratch, {
      targets::tar_make(
        names = c(wikidata_match_confidence, classification_threshold, people_candidates),
        reporter = "silent"
      )
      "wikidata_people_fetch" %in% targets::tar_outdated(names = "wikidata_people_fetch",
                                                         reporter = "silent")
    })
  }
  # The fetch is forced to re-run while its stored status is not "ok".
  skip_if(fetch_outdated(), "wikidata_people_fetch already outdated (status not ok?); run tar_make()")

  params <- file.path(scratch, "inst", "extdata", "params.csv")
  p <- utils::read.csv(params, stringsAsFactors = FALSE)

  # A params.csv edit that changes no value: the fetch must not re-run.
  p$note[p$name == "classification_threshold"] <- "edited note (#108 probe)"
  utils::write.csv(p, params, row.names = FALSE)
  expect_false(fetch_outdated())

  # A confidence edit: the fetch must re-run.
  p$value[p$name == "wikidata_partial_confidence"] <- 0.75
  utils::write.csv(p, params, row.names = FALSE)
  expect_true(fetch_outdated())
})
