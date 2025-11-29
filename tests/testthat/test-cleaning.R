test_that("clean_names removes honorifics and punctuation", {
  raw <- c("Sir John Doe (1900-1990)", "Queen Victoria", "Mr. Smith")
  clean <- clean_names(raw)
  
  expect_equal(clean[1], "John Doe")
  expect_equal(clean[2], "Victoria")
})

test_that("is_man_named_john identifies Johns correctly", {
  expect_true(is_man_named_john("John Smith"))
  expect_true(is_man_named_john("Jon Doe"))
  expect_true(is_man_named_john("Sir John Lennon"))
  
  expect_false(is_man_named_john("Mary John")) # Female
  expect_false(is_man_named_john("William Shakespeare"))
})

test_that("classify_subject categorizes correctly", {
  expect_equal(classify_subject("John Smith", "male"), "Men named John")
  expect_equal(classify_subject("Victoria", "female"), "Women")
  expect_equal(classify_subject("Fido", "unknown", "Dog statue"), "Dog")
  expect_equal(classify_subject("Unknown Soldier", "male"), "Other")
})
