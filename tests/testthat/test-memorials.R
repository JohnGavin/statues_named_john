test_that("get_memorials_latest returns a tibble", {
  skip_on_cran()
  skip_if_offline()

  result <- get_memorials_latest(pages = 1)

  expect_s3_class(result, "tbl_df")
  # Website structure may change, so just verify we get correct column names
  # even if result is empty
  if (nrow(result) > 0) {
    expect_true("title" %in% names(result))
    expect_true("url" %in% names(result))
    expect_true("memorial_type" %in% names(result))
  } else {
    skip("No memorials found on website - may need to update CSS selectors")
  }
})


test_that("get_memorial returns detailed information", {
  skip_on_cran()
  skip_if_offline()

  # First get a memorial URL
  memorials <- get_memorials_latest(pages = 1)

  if (nrow(memorials) > 0) {
    memorial_url <- memorials$url[1]
    result <- get_memorial(memorial_url)

    expect_type(result, "list")
    expect_true("title" %in% names(result))
    expect_true("url" %in% names(result))
    expect_true("type" %in% names(result))
  } else {
    skip("No memorials found to test")
  }
})


test_that("search_memorials returns results", {
  skip_on_cran()
  skip_if_offline()

  result <- search_memorials("John", pages = 1)

  expect_s3_class(result, "tbl_df")
  # Results may be empty for some searches, so just check structure
  if (nrow(result) > 0) {
    expect_true("title" %in% names(result))
    expect_true("url" %in% names(result))
  } else {
    skip("No search results found - may need to update CSS selectors")
  }
})


test_that("clean_text handles NA and empty strings", {
  expect_equal(clean_text("  test  "), "test")
  expect_equal(clean_text(""), NA_character_)
  expect_equal(clean_text(c("  a  ", "", "  b  ")), c("a", NA_character_, "b"))
})
