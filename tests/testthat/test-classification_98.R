# #98 follow-ups: precedence, splitting, non-person segments, provenance.

mock_lookup <- function(map) {
  function(names, threshold = 0.9) {
    stats::setNames(unname(map[tolower(names)]), names)
  }
}

test_that("a title outranks an animal word, but a name lookup does not (item 2)", {
  # Name lookups resolve animals' names too ("Hodge the Cat" -> Hodge=Male,
  # seen in the real data), so only an explicit title beats an animal word.
  testthat::local_mocked_bindings(
    lookup_first_name_gender = mock_lookup(c(hodge = "Male", trafalgar = "Male"))
  )
  res <- classify_gender_from_subject(
    c("Duke of Wellington on horse", "Lady Godiva on her horse",
      "Hodge the Cat", "Trafalgar Square Lion"),
    names = rep(NA_character_, 4)
  )
  expect_equal(res, c("Male", "Female", "Animal", "Animal"))
})

test_that("people are split on 'and'/'&' in any case, but not on commas (item 3)", {
  # In this dataset a comma almost always introduces a location
  # ("Statue of Hercules, Trent Park"); splitting there turned place names
  # into people, so commas are deliberately not person separators.
  testthat::local_mocked_bindings(
    lookup_first_name_gender = mock_lookup(c(john = "Male", mary = "Female", trent = "Female"))
  )
  expect_equal(split_into_person_parts("John And Mary"), c("John", "Mary"))
  expect_equal(split_into_person_parts("John & Mary"), c("John", "Mary"))
  expect_equal(split_into_person_parts("Statue of Hercules, Trent Park"),
               "Statue of Hercules, Trent Park")
  res <- classify_gender_from_subject(c("John And Mary", "Statue of Hercules, Trent Park"),
                                      names = c(NA_character_, NA_character_))
  expect_equal(res, c("Mixed", "Unknown"))
})

test_that("church/school/college dedications and 'Site of' are not people", {
  # The real genderdata lists resolve ordinary words: Mary=Female,
  # Parish=Male, Site=Female, Corpus=Male. None of these is a person here.
  testthat::local_mocked_bindings(
    lookup_first_name_gender = mock_lookup(c(mary = "Female", parish = "Male",
                                            site = "Female", corpus = "Male"))
  )
  res <- classify_gender_from_subject(
    c("St Mary Abbot's Church of England Primary School and Parish Office",
      "Site of Laurence Pountney Church and Corpus Christi College"),
    names = c(NA_character_, NA_character_)
  )
  expect_equal(res, c("Unknown", "Unknown"))
})

test_that("a saint's statue without a church/school word is still a person", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = mock_lookup(c(george = "Male"))
  )
  expect_equal(classify_gender_from_subject("St George", names = NA_character_), "Male")
})

test_that("non-name words and lowercase tokens are never looked up as first names", {
  seen <- character(0)
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      seen <<- c(seen, names)
      stats::setNames(rep(NA_character_, length(names)), names)
    }
  )
  classify_gender_from_subject(c("Parish Office", "Corpus Christi College", "Duke of Somewhere"),
                               names = rep(NA_character_, 3))
  expect_false(any(tolower(seen) %in% c("parish", "corpus", "of")))
})

test_that("gender_method reflects whether the genderdata cascade was available (item 4)", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = mock_lookup(c(john = "Male")),
    genderdata_available = function() FALSE
  )
  mock <- tibble::tibble(subject = NA_character_, name = "John Smith",
                         subject_gender = NA_character_, type = "statue", source = "t")
  res <- compare_johns_vs_women(mock)
  # Must not claim the lookup cascade ran
  expect_false(grepl("napp_ipums_ssa", res$gender_method))
  expect_match(res$gender_method, "unavailable")
})

test_that("the headline omits the 'with a man' clause when there are no Mixed statues (item 11)", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = mock_lookup(c(john = "Male", mary = "Female"))
  )
  mock <- tibble::tibble(subject = NA_character_, name = c("John Smith", "Mary Jones"),
                         subject_gender = NA_character_, type = "statue", source = "t")
  res <- compare_johns_vs_women(mock)
  expect_equal(res$mixed_statues, 0L)
  expect_false(grepl("with a man", res$message))
  expect_match(res$message, "1 women statues")
})

test_that("join_and_clean_data classifies OSM subjects in one vectorised call (item 9)", {
  calls <- 0
  testthat::local_mocked_bindings(
    classify_gender_from_subject = function(subjects, names = NULL, gender_mapping = NULL) {
      calls <<- calls + 1
      rep("Male", length(subjects))
    }
  )
  wiki <- tibble::tibble(item = "Q1", title = "A", coords = "Point(-0.1 51.5)",
                         inception = NA_character_, creator = NA_character_,
                         creator_gender = "male", source = "wikidata")
  osm <- tibble::tibble(osm_id = 1:3, name = c("x", "y", "z"),
                        subject = c("John A", "John B", "John C"),
                        lat = 51.5, lon = -0.1, source = "osm")
  join_and_clean_data(wiki, osm)
  expect_equal(calls, 1)
})
