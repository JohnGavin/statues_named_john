# test_that("fetch_art_uk_data returns a tibble", {
#   skip_if_offline()
#   # Skip on CRAN to avoid hitting external servers
#   skip_on_cran()
#   
#   # We limit to 1 page for testing
#   data <- fetch_art_uk_data(pages = 1)
#   
#   expect_s3_class(data, "tbl_df")
#   if (nrow(data) > 0) {
#     expect_true("title" %in% names(data))
#     expect_true("artist" %in% names(data))
#   }
# })



test_that("fetch_historic_england_data returns a tibble", {
  data <- fetch_historic_england_data()
  expect_s3_class(data, "tbl_df")
})
