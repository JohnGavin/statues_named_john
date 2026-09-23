test_that("parse_sparql_json parses normal rows with all vars present", {
  json_text <- '{
    "head": {"vars": ["statue", "label"]},
    "results": {"bindings": [
      {"statue": {"type": "uri", "value": "Q1"}, "label": {"type": "literal", "value": "A"}},
      {"statue": {"type": "uri", "value": "Q2"}, "label": {"type": "literal", "value": "B"}}
    ]}
  }'

  result <- parse_sparql_json(json_text)

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("statue", "label"))
  expect_equal(nrow(result), 2)
  expect_equal(result$statue, c("Q1", "Q2"))
  expect_equal(result$label, c("A", "B"))
})

test_that("parse_sparql_json fills NA when a variable is missing from some rows", {
  json_text <- '{
    "head": {"vars": ["statue", "label", "optional_field"]},
    "results": {"bindings": [
      {"statue": {"type": "uri", "value": "Q1"}, "label": {"type": "literal", "value": "A"}, "optional_field": {"type": "literal", "value": "X"}},
      {"statue": {"type": "uri", "value": "Q2"}, "label": {"type": "literal", "value": "B"}}
    ]}
  }'

  result <- parse_sparql_json(json_text)

  expect_named(result, c("statue", "label", "optional_field"))
  expect_equal(nrow(result), 2)
  expect_equal(result$optional_field, c("X", NA_character_))
})

test_that("parse_sparql_json keeps a column present, all NA, when a variable is missing from every row", {
  json_text <- '{
    "head": {"vars": ["statue", "label", "never_present"]},
    "results": {"bindings": [
      {"statue": {"type": "uri", "value": "Q1"}, "label": {"type": "literal", "value": "A"}},
      {"statue": {"type": "uri", "value": "Q2"}, "label": {"type": "literal", "value": "B"}}
    ]}
  }'

  result <- parse_sparql_json(json_text)

  expect_named(result, c("statue", "label", "never_present"))
  expect_equal(nrow(result), 2)
  expect_true(all(is.na(result$never_present)))
})

test_that("parse_sparql_json returns a zero-row tibble with the right columns for zero bindings", {
  json_text <- '{
    "head": {"vars": ["statue", "label"]},
    "results": {"bindings": []}
  }'

  result <- parse_sparql_json(json_text)

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("statue", "label"))
  expect_equal(nrow(result), 0)
})
