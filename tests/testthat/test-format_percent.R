# Display percentages are whole numbers; stored values keep 2 dp (#102).

test_that("format_percent rounds to the nearest whole percent from raw counts", {
  expect_equal(format_percent(229, 2301), "10%")   # 9.952...
  expect_equal(format_percent(73, 2301), "3%")     # 3.17...
  expect_equal(format_percent(1, 3), "33%")
  expect_equal(format_percent(0, 10), "0%")
  expect_equal(format_percent(c(1, 2), c(4, 4)), c("25%", "50%"))
})

test_that("format_percent formats from counts, so it never double-rounds", {
  # 29.495% rounded to 2 dp is 29.5 and would then round up to 30%;
  # from the raw counts it is 29%.
  expect_equal(format_percent(5899, 20000), "29%")
})

test_that("format_percent returns 'n/a' when the total is missing or zero", {
  expect_equal(format_percent(0, NA_real_), "n/a")
  expect_equal(format_percent(0, 0), "n/a")
})

mock_statues <- function(names) {
  tibble::tibble(subject = NA_character_, name = names,
                 subject_gender = NA_character_, type = "statue", source = "t")
}

test_that("compare_johns_vs_women keeps 2 dp in stored values and whole percents in text", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      m <- c(john = "Male", mary = "Female")
      stats::setNames(unname(m[tolower(names)]), names)
    }
  )
  res <- compare_johns_vs_women(mock_statues(c("John Smith", "Mary Jones", "Xyzzy Qwerty")))
  expect_equal(res$john_percent, 33.33)
  expect_equal(res$woman_percent, 33.33)
  expect_equal(res$john_percent_label, "33%")
  expect_equal(res$woman_percent_label, "33%")
  expect_match(res$message, "\\(33%\\)")
  expect_false(grepl("33\\.3", res$message))
})

test_that("analyze_by_gender stores 2 dp and adds a whole-percent label", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      m <- c(john = "Male", mary = "Female")
      stats::setNames(unname(m[tolower(names)]), names)
    }
  )
  s <- analyze_by_gender(mock_statues(c("John Smith", "Mary Jones", "Xyzzy Qwerty")))$summary
  expect_true(all(s$percent == 33.33))
  expect_true(all(s$percent_label == "33%"))
})
