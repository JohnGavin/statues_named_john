# Tests for the GLHER public search API fetcher (#94). Network is mocked;
# the fixture is trimmed from a real /search/resources response.

fixture_json <- function() {
  paste(readLines(testthat::test_path("fixtures", "glher_search_page.json"), warn = FALSE),
        collapse = "\n")
}

json_response <- function(body, status = 200L) {
  structure(
    list(status_code = status,
         url = "https://glher.historicengland.org.uk/search/resources",
         headers = list(`content-type` = "application/json"),
         content = charToRaw(enc2utf8(body))),
    class = "response"
  )
}

with_paging <- function(body, has_next, total) {
  j <- jsonlite::fromJSON(body, simplifyVector = FALSE)
  j$`paging-filter`$paginator$has_next <- has_next
  j$results$hits$total$value <- total
  as.character(jsonlite::toJSON(j, auto_unbox = TRUE, null = "null"))
}

test_that("parse_glher_hits extracts id, name, type, coordinates and report URL", {
  j <- jsonlite::fromJSON(fixture_json(), simplifyVector = FALSE)
  res <- parse_glher_hits(j$results$hits$hits)
  expect_equal(nrow(res), 3)
  expect_equal(res$glher_id[1], "149436")
  expect_equal(res$name[1], "West Norwood Memorial Park Tomb of Elizabeth King")
  expect_equal(res$type[1], "Early 20th Century Tomb")
  expect_match(res$description[1], "dedicated to Elizabeth King")
  expect_true(is.numeric(res$lat) && is.numeric(res$lon))
  expect_equal(round(res$lat[1]), 51)
  expect_true(is.na(res$lat[3]) && is.na(res$lon[3]))
  expect_match(res$url[1], "^https://glher.historicengland.org.uk/report/[0-9a-f-]{36}$")
  expect_true(all(res$source == "glher"))
})

test_that("get_statues_glher follows pages until has_next is FALSE", {
  calls <- 0
  testthat::local_mocked_bindings(
    GET = function(...) {
      calls <<- calls + 1
      json_response(with_paging(fixture_json(), has_next = calls < 2, total = 6))
    },
    .package = "httr"
  )
  res <- suppressMessages(get_statues_glher(pause = 0))
  expect_equal(calls, 2)
  expect_equal(nrow(res), 6)
})

test_that("get_statues_glher fails when fewer records arrive than GLHER reports", {
  testthat::local_mocked_bindings(
    GET = function(...) json_response(with_paging(fixture_json(), has_next = FALSE, total = 302)),
    .package = "httr"
  )
  expect_error(suppressMessages(get_statues_glher(pause = 0)), "302.*3|3.*302")
})

test_that("get_statues_glher fails rather than truncating at max_pages", {
  testthat::local_mocked_bindings(
    GET = function(...) json_response(with_paging(fixture_json(), has_next = TRUE, total = 999)),
    .package = "httr"
  )
  expect_error(suppressMessages(get_statues_glher(pause = 0, max_pages = 2)), "max_pages")
})

test_that("get_statues_glher fails on a non-JSON response", {
  testthat::local_mocked_bindings(
    GET = function(...) structure(
      list(status_code = 200L, url = "https://glher", headers = list(`content-type` = "text/html"),
           content = charToRaw("<!DOCTYPE html><title>GLHER - Search</title>")),
      class = "response"),
    .package = "httr"
  )
  expect_error(suppressMessages(get_statues_glher(pause = 0)), "not JSON")
})

test_that("get_statues_glher fails with the HTTP status on an error response", {
  testthat::local_mocked_bindings(
    GET = function(...) json_response('{"message": "forbidden"}', status = 403L),
    .package = "httr"
  )
  expect_error(suppressMessages(get_statues_glher(pause = 0)), "403")
})
