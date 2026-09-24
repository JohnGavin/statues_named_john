# Tests for the gender-classification logic that actually drives the
# "Johns vs women" headline (analyze_by_gender() / compare_johns_vs_women()
# via classify_gender_from_subject()). See issue #84.

test_that("classify_gender_from_subject applies documented title/term overrides", {
  # Override terms match against the FIRST word of a person-segment only
  # (never a substring match anywhere), so these are all start-anchored.
  subjects <- c(
    "Queen Victoria Memorial", "King Alfred The Great", "Sir James Outram",
    "Dame Ellen Terry", "Lady Godiva", "Lord Nelson", "Duke of Wellington",
    "Duchess of Kent", "Woman Reading", "Man on Horseback"
  )
  result <- classify_gender_from_subject(subjects, names = rep(NA_character_, length(subjects)))

  expect_equal(
    result,
    c("Female", "Male", "Male", "Female", "Female", "Male", "Male", "Female", "Female", "Male")
  )
})

test_that("classify_gender_from_subject resolves multi-person subjects: agree -> that gender, disagree -> Mixed", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      lookup <- c(john = "Male", jonathan = "Male", mary = "Female", william = "Male", robert = "Male")
      stats::setNames(unname(lookup[tolower(names)]), names)
    }
  )

  # Female-first bug regression: "John and Mary" must NOT collapse to Female
  # just because the female branch happened to be checked first.
  expect_equal(
    classify_gender_from_subject("John and Mary", names = NA_character_),
    "Mixed"
  )

  # Two people who agree -> that gender, not Mixed. Two-word segments are used
  # here because extract_first_names() deliberately only trusts a bare
  # single-word segment when it is in its narrow first-name whitelist (to
  # avoid treating a surname like "Johnson" as a first name) -- unrelated to
  # this fix, and unchanged by it.
  expect_equal(
    classify_gender_from_subject("William Shakespeare and Robert Burns", names = NA_character_),
    "Male"
  )
})

test_that("classify_gender_from_subject: 'Sir John Soane' resolves via the title override, not name lookup", {
  # The override on "Sir" must win outright so this never depends on a
  # genderdata lookup at all.
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      stop("lookup_first_name_gender should not be called when a title override applies")
    }
  )
  expect_equal(
    classify_gender_from_subject("Sir John Soane", names = NA_character_),
    "Male"
  )
})

test_that("classify_gender_from_subject: 'Manchester dog' is Animal, never Male via a 'man' substring match", {
  expect_equal(
    classify_gender_from_subject("Manchester dog", names = NA_character_),
    "Animal"
  )
})

test_that("classify_gender_from_subject: an unresolvable name is Unknown (no warning)", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      stats::setNames(rep(NA_character_, length(names)), names)
    }
  )
  expect_no_warning(
    result <- classify_gender_from_subject("Xyzzyplonk Nonexistentname", names = NA_character_)
  )
  expect_equal(result, "Unknown")
})

test_that("classify_gender_from_subject: a lookup failure warns and falls back to Unknown", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      warning("simulated genderdata lookup failure")
      stats::setNames(rep(NA_character_, length(names)), names)
    }
  )
  expect_warning(
    result <- classify_gender_from_subject("Someunresolvedname Placeholder", names = NA_character_),
    "simulated genderdata lookup failure"
  )
  expect_equal(result, "Unknown")
})

test_that("lookup_first_name_gender: a gender::gender() error surfaces as a warning", {
  skip_if_not_installed("gender")
  testthat::local_mocked_bindings(
    gender = function(...) stop("simulated genderdata failure"),
    .package = "gender"
  )
  warns <- character(0)
  result <- withCallingHandlers(
    lookup_first_name_gender(c("Florence", "George")),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  # One warning per cascade method (napp, ipums, ssa), none muffled.
  expect_length(warns, 3)
  expect_match(warns, "simulated genderdata failure", all = TRUE)
  expect_true(all(is.na(result)))
})

test_that("classify_gender_from_subject: animal detection still works", {
  expect_equal(
    classify_gender_from_subject("Trafalgar Square Lion", names = NA_character_),
    "Animal"
  )
  expect_equal(
    classify_gender_from_subject(NA_character_, names = "Statue of a dog"),
    "Animal"
  )
})

test_that("classify_gender_from_subject: gender_mapping argument is still honoured and takes priority", {
  mapping <- c("Fido" = "Animal", "Custom Subject" = "Female")
  result <- classify_gender_from_subject(c("Fido", "Custom Subject"), gender_mapping = mapping)
  expect_equal(unname(result), c("Animal", "Female"))
})

test_that("classify_gender_from_subject: real genderdata lookup resolves unambiguous historical names", {
  skip_if_not_installed("genderdata")
  result <- classify_gender_from_subject(
    c("Florence Nightingale", "William Shakespeare"),
    names = c(NA_character_, NA_character_)
  )
  expect_equal(result, c("Female", "Male"))
})

test_that("classify_gender (cleaning.R) delegates to classify_gender_from_subject and lower-cases the result", {
  # known_gender still wins outright.
  expect_equal(classify_gender("Anyone", known_gender = "female"), "female")

  # Delegates for title overrides (lower-cased).
  expect_equal(classify_gender("Queen Victoria"), "female")

  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      stats::setNames(rep(NA_character_, length(names)), names)
    }
  )
  expect_equal(classify_gender("Xyzzyplonk Nonexistentname"), "unknown")
})

test_that("compare_johns_vs_women reports unknown statues and the gender method used", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      lookup <- c(john = "Male", mary = "Female")
      stats::setNames(unname(lookup[tolower(names)]), names)
    }
  )

  mock_data <- tibble::tibble(
    subject = rep(NA_character_, 6),
    name = c(
      "John Smith", "Queen Victoria", "Mary Jones",
      "Trafalgar Square Lion", "Xyzzyplonk Nonexistentname", "John and Mary"
    ),
    subject_gender = NA_character_,
    type = "statue",
    source = "test"
  )

  result <- compare_johns_vs_women(mock_data)

  expect_true("unknown_statues" %in% names(result))
  expect_true("unknown_percent" %in% names(result))
  expect_true("gender_method" %in% names(result))

  expect_equal(result$unknown_statues, 1L)
  expect_equal(result$unknown_percent, round(100 * 1 / 6, 2))
  expect_match(result$message, "unknown", ignore.case = TRUE)
})
