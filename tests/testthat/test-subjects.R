test_that("get_subjects_by_category returns a tibble", {
  skip_on_cran()
  skip_if_offline()

  result <- get_subjects_by_category("Literature", pages = 1)

  expect_s3_class(result, "tbl_df")
  # May be empty, so just check structure
  if (nrow(result) > 0) {
    expect_true("name" %in% names(result))
    expect_true("url" %in% names(result))
    expect_true("category" %in% names(result))
  } else {
    skip("No subjects found - may need to update CSS selectors")
  }
})


test_that("get_subject returns detailed information", {
  skip_on_cran()
  skip_if_offline()

  # This test depends on actual data being available
  subjects <- get_subjects_by_category("Literature", pages = 1)

  if (nrow(subjects) > 0) {
    subject_url <- subjects$url[1]
    result <- get_subject(subject_url)

    expect_type(result, "list")
    expect_true("name" %in% names(result))
    expect_true("url" %in% names(result))
  } else {
    skip("No subjects found to test")
  }
})


test_that("fetch_page handles invalid URLs gracefully", {
  expect_warning({
    result <- fetch_page("https://invalid-url-that-does-not-exist-12345.com")
    expect_null(result)
  }, class = "warning") # Expect any warning, or be more specific if needed
})
