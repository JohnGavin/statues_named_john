# #115: the names counted as "John" have one home, john_variants(). The
# headline count, its message and the dashboard caption all read from it.

test_that("every John variant is counted, and the result lists them", {
  d <- tibble::tibble(
    name = c("John Smith", "Jon Snow", "Jonathan Swift", "Jean Rhys",
             "Jonny Wilkinson", "Johnson Memorial"),
    subject = NA_character_, subject_gender = NA_character_,
    type = "statue", source = "osm"
  )
  res <- compare_johns_vs_women(d, threshold = 0.9)
  expect_equal(res$john_statues, 5)          # not "Johnson"
  expect_equal(res$john_variants, john_variants())
  expect_match(res$message, paste(john_variants(), collapse = "/"), fixed = TRUE)
})

test_that("john_variants() is the documented list", {
  expect_snapshot(john_variants())
})
