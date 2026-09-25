# Tests for explicit source status (#94): an optional source that cannot be
# fetched is recorded as "unavailable" with its reason, never as a silent
# empty table.

test_that("fetch_optional_source records a successful fetch as ok with its row count", {
  res <- fetch_optional_source("glher", tibble::tibble(x = 1:3))
  expect_equal(nrow(res$data), 3)
  expect_equal(res$status$source, "glher")
  expect_equal(res$status$status, "ok")
  expect_equal(res$status$rows, 3L)
  expect_true(is.na(res$status$reason))
})

test_that("fetch_optional_source distinguishes a genuinely empty result", {
  res <- fetch_optional_source("glher", tibble::tibble())
  expect_equal(nrow(res$data), 0)
  expect_equal(res$status$status, "empty")
  expect_equal(res$status$rows, 0L)
})

test_that("fetch_optional_source records a failed fetch as unavailable with the reason", {
  expect_message(
    res <- fetch_optional_source("glher", stop("HTTP 403: no export permission")),
    "glher.*unavailable"
  )
  expect_equal(nrow(res$data), 0)
  expect_equal(res$status$status, "unavailable")
  expect_equal(res$status$rows, 0L)
  expect_match(res$status$reason, "no export permission")
})

test_that("source_row summarises a required source", {
  s <- source_row("osm", tibble::tibble(a = 1:2))
  expect_equal(s$status, "ok")
  expect_equal(s$rows, 2L)
  expect_equal(source_row("osm", tibble::tibble())$status, "empty")
})
