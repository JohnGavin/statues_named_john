# Tests for get_statues_osm() fail-fast behaviour (#90).
# All network access is mocked via osm_fetch_features().

tags4 <- list(
  list(key = "memorial", value = "statue"),
  list(key = "memorial", value = "animal"),
  list(key = "historic", value = "memorial"),
  list(key = "man_made", value = "statue")
)

fake_points <- function(n, cols = list()) {
  df <- data.frame(osm_id = as.character(seq_len(n)), name = paste("Statue", seq_len(n)))
  for (nm in names(cols)) df[[nm]] <- cols[[nm]]
  sf::st_as_sf(df, geometry = sf::st_sfc(lapply(seq_len(n), function(i) sf::st_point(c(-0.1, 51.5))), crs = 4326))
}

test_that("get_statues_osm aborts on the first failed query and does not run later ones", {
  calls <- character(0)
  testthat::local_mocked_bindings(
    osm_fetch_features = function(q, ...) {
      tag <- q$features
      calls <<- c(calls, tag)
      if (length(calls) == 2) stop("HTTP 504 Gateway Timeout")
      list(osm_points = fake_points(2, list(memorial = "statue")))
    }
  )
  expect_error(
    get_statues_osm(tags = tags4, pause = 0),
    "memorial=animal.*504"
  )
  expect_length(calls, 2)
})

test_that("get_statues_osm never returns partial data when a query fails", {
  testthat::local_mocked_bindings(
    osm_fetch_features = function(q, ...) {
      if (grepl("man_made", q$features)) stop("Could not resolve host")
      list(osm_points = fake_points(3, list(historic = "memorial")))
    }
  )
  expect_error(get_statues_osm(tags = tags4, pause = 0), "man_made=statue")
})

test_that("a tag with no features is a valid empty result, not a failure", {
  testthat::local_mocked_bindings(
    osm_fetch_features = function(q, ...) {
      if (grepl("man_made", q$features)) return(list(osm_points = NULL))
      list(osm_points = fake_points(2, list(memorial = "statue")))
    }
  )
  res <- get_statues_osm(tags = tags4, pause = 0)
  expect_s3_class(res, "tbl_df")
  expect_gt(nrow(res), 0)
})

test_that("get_statues_osm reshapes results that lack optional tag columns", {
  testthat::local_mocked_bindings(
    osm_fetch_features = function(q, ...) {
      if (grepl("historic", q$features)) {
        return(list(osm_points = fake_points(3, list(historic = "memorial"))))
      }
      list(osm_points = NULL)
    }
  )
  res <- get_statues_osm(tags = tags4, pause = 0)
  expect_equal(nrow(res), 3)
  expect_true(all(c("subject", "memorial_type", "man_made_type", "material", "wikipedia") %in% names(res)))
  expect_true(all(is.na(res$subject)))
  expect_equal(res$historic_type, rep("memorial", 3))
})

test_that("get_statues_osm aborts when every query returns nothing", {
  testthat::local_mocked_bindings(
    osm_fetch_features = function(q, ...) list(osm_points = NULL)
  )
  expect_error(get_statues_osm(tags = tags4, pause = 0), "No OSM features")
})

test_that("check_overpass_remark flags a 200 response carrying a server runtime error", {
  f <- withr::local_tempfile(fileext = ".osm")
  writeLines(c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<osm version="0.6">',
    '<remark> runtime error: Query timed out in "query" at line 3 after 26 seconds. </remark>',
    "</osm>"
  ), f)
  expect_error(check_overpass_remark(f), "runtime error")

  ok <- withr::local_tempfile(fileext = ".osm")
  writeLines(c('<?xml version="1.0" encoding="UTF-8"?>', '<osm version="0.6">', "</osm>"), ok)
  expect_invisible(check_overpass_remark(ok))
})

q_test <- function() {
  osmdata::add_osm_feature(osmdata::opq(c(-0.2, 51.4, -0.1, 51.5)), key = "memorial", value = "statue")
}

test_that("osm_fetch_features does not retry a connection/DNS failure", {
  n <- 0
  testthat::local_mocked_bindings(
    POST = function(...) {
      n <<- n + 1
      stop("Could not resolve host: overpass-api.de")
    },
    .package = "httr"
  )
  expect_error(osm_fetch_features(q_test(), backoff_base = 0), "Could not resolve host")
  expect_equal(n, 1)
})

test_that("osm_fetch_features retries 429/5xx at most max_tries times, then fails", {
  n <- 0
  testthat::local_mocked_bindings(
    POST = function(...) {
      n <<- n + 1
      structure(list(status_code = 503L, url = "https://overpass", headers = list()), class = "response")
    },
    .package = "httr"
  )
  expect_error(osm_fetch_features(q_test(), max_tries = 3, backoff_base = 0), "503|Service Unavailable")
  expect_equal(n, 3)
})

test_that("osm_fetch_features does not retry a non-retryable HTTP error", {
  n <- 0
  testthat::local_mocked_bindings(
    POST = function(...) {
      n <<- n + 1
      structure(list(status_code = 400L, url = "https://overpass", headers = list()), class = "response")
    },
    .package = "httr"
  )
  expect_error(osm_fetch_features(q_test(), backoff_base = 0), "400|Bad Request")
  expect_equal(n, 1)
})
