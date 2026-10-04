# Records with no name, no subject and no stated gender cannot be
# identified. They stay in the data (and on the map) as "Unnamed", but are
# left out of every share, so they do not dilute the headline (#117).

mock <- function() {
  tibble::tibble(
    name = c("Queen Victoria", "Lord Nelson", NA, NA),
    subject = NA_character_,
    subject_gender = NA_character_,
    type = "statue",
    source = "osm"
  )
}

test_that("records with no name or subject are Unnamed and not counted in shares", {
  res <- analyze_by_gender(mock(), threshold = 0.9)
  expect_equal(sum(res$data$inferred_gender == "Unnamed"), 2)
  s <- res$summary
  expect_equal(s$n[s$inferred_gender == "Unnamed"], 2)
  expect_true(is.na(s$percent[s$inferred_gender == "Unnamed"]))
  expect_equal(s$percent_label[s$inferred_gender == "Unnamed"], "not counted")
  expect_equal(sum(s$percent, na.rm = TRUE), 100)
  expect_equal(s$percent[s$inferred_gender == "Female"], 50)
})

test_that("compare_johns_vs_women() uses identifiable statues as the total", {
  res <- compare_johns_vs_women(mock(), threshold = 0.9)
  expect_equal(res$total_statues, 2)
  expect_equal(res$unnamed_statues, 2)
  expect_equal(res$woman_statues, 1)
  expect_equal(res$woman_percent_label, "50%")
  expect_match(res$message, "2 records with no name")
})

test_that("a record with a stated gender but no name is still classified", {
  d <- mock()
  d$subject_gender[3] <- "female"
  res <- analyze_by_gender(d, threshold = 0.9)
  expect_equal(res$data$inferred_gender[3], "Female")
})
