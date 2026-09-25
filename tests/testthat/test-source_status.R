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

fake_response <- function(body, status = 200L, ctype = "text/html; charset=utf-8") {
  structure(
    list(
      status_code = status,
      url = "https://glher.historicengland.org.uk/search",
      headers = list(`content-type` = ctype),
      content = charToRaw(body)
    ),
    class = "response"
  )
}

test_that("get_statues_glher fails with a reason when GLHER returns its web page, not CSV", {
  testthat::local_mocked_bindings(
    GET = function(...) fake_response("<!DOCTYPE html><html><title> GLHER -  Search </title></html>"),
    .package = "httr"
  )
  expect_error(suppressMessages(get_statues_glher()), "web page.*not CSV")
})

test_that("get_statues_glher fails with a reason on a non-200 response", {
  testthat::local_mocked_bindings(
    GET = function(...) fake_response('{"message": "You do not have permission to download exports."}',
                                      status = 403L, ctype = "application/json"),
    .package = "httr"
  )
  expect_error(suppressMessages(get_statues_glher()), "403")
})
