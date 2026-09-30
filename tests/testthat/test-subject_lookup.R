# Subject extraction ("Statue of X" -> X), Wikidata person lookup, and the
# single classification threshold parameter.

test_that("extract_subject strips object prefixes and trailing locations", {
  expect_equal(extract_subject("Statue of Sir John Millais in North Forecourt of Tate Gallery"),
               "Sir John Millais")
  expect_equal(extract_subject("Statue of Hercules, Trent Park"), "Hercules")
  expect_equal(extract_subject("Tomb of Maria Tustin"), "Maria Tustin")
  expect_equal(extract_subject("Monument to Eliza Vaughan in Highgate (Western) Cemetery, Highgate Cemetery"),
               "Eliza Vaughan")
  expect_equal(extract_subject("Memorial of Lord Nelson"), "Lord Nelson")
  # A leading "the" is dropped, so it is never read as a first name
  expect_equal(extract_subject("Memorial To The Executed in the Tower"), "Executed")
  expect_equal(extract_subject("Statue of the Eighth Duke of Devonshire"), "Eighth Duke of Devonshire")
  # No object prefix: unchanged (location suffixes are only stripped after a prefix)
  expect_equal(extract_subject("Queen Victoria, Kensington"), "Queen Victoria, Kensington")
  expect_equal(extract_subject("Duke of Wellington on horse"), "Duke of Wellington on horse")
  expect_true(is.na(extract_subject(NA_character_)))
})

test_that("classification_threshold comes from the single params file", {
  expect_equal(get_param("classification_threshold"), 0.9)
  expect_error(get_param("no_such_param"), "no_such_param")
  expect_equal(wikidata_confidence(), c(exact = 1, partial = 0.7, weak = 0.4))
})

test_that("get_param rejects a value that is not a number, or a threshold above 1", {
  old <- .lookup_cache$params
  on.exit(.lookup_cache$params <- old, add = TRUE)
  .lookup_cache$params <- data.frame(
    name = c("classification_threshold", "x_threshold"),
    value = c("0,9", "1.5"), stringsAsFactors = FALSE
  )
  expect_error(get_param("classification_threshold"), "not a number")
  expect_error(get_param("x_threshold"), "between 0 and 1")
})

test_that("extract_first_names reads the name after 'Statue of', so the John count sees it", {
  expect_equal(extract_first_names("Statue of Sir John Millais in North Forecourt of Tate Gallery"), "John")
})

# --- Wikidata lookup (network mocked) ------------------------------------

mock_wd <- function(search, entities) {
  list(
    wd_search = function(x) search[[x]],
    wd_entities = function(ids) entities[ids]
  )
}
human <- function(sex_qid) list(claims = list(
  P31 = list(list(mainsnak = list(datavalue = list(value = list(id = "Q5"))))),
  P21 = list(list(mainsnak = list(datavalue = list(value = list(id = sex_qid)))))
))
thing <- list(claims = list(
  P31 = list(list(mainsnak = list(datavalue = list(value = list(id = "Q4271324")))))
))

test_that("lookup_wikidata_people scores exact human matches 1 and partial 0.7; rejects non-humans", {
  m <- mock_wd(
    search = list(
      "Mrs Siddons" = list(list(id = "Q1", label = "Sarah Siddons",
                                match = list(text = "Mrs Siddons"))),
      "William Iii" = list(list(id = "Q2", label = "William III of England")),
      "Hercules"    = list(list(id = "Q3", label = "Hercules"))
    ),
    entities = list(Q1 = human("Q6581072"), Q2 = human("Q6581097"), Q3 = thing)
  )
  testthat::local_mocked_bindings(wd_search = m$wd_search, wd_entities = m$wd_entities)
  res <- lookup_wikidata_people(c("Mrs Siddons", "William Iii", "Hercules"), pause = 0)
  expect_equal(res$x, c("Mrs Siddons", "William Iii", "Hercules"))
  expect_equal(res$sex, c("Female", "Male", NA))
  expect_equal(res$confidence, c(1, 0.7, 0))
  expect_equal(res$qid, c("Q1", "Q2", NA))
})

test_that("lookup_wikidata_people fails fast when Wikidata errors", {
  testthat::local_mocked_bindings(wd_search = function(x) stop("HTTP 503"))
  expect_error(lookup_wikidata_people("Anyone", pause = 0), "503")
})

# --- Classification with the lookup and the threshold --------------------

people <- tibble::tibble(
  x = c("Mrs Siddons", "William Iii"),
  sex = c("Female", "Male"),
  confidence = c(1, 0.7),
  qid = c("Q1", "Q2")
)
no_lookup <- function(names, threshold = 0.9) stats::setNames(rep(NA_character_, length(names)), names)

test_that("a Wikidata match at or above the threshold decides the gender", {
  testthat::local_mocked_bindings(lookup_first_name_gender = no_lookup)
  res <- classify_gender_from_subject(
    c("Statue of Mrs Siddons", "Statue of William Iii"),
    names = c(NA_character_, NA_character_),
    person_lookup = people, threshold = 0.9
  )
  # Siddons exact (1.0) accepted; William III partial (0.7) below 0.9 falls back
  # to the name rules on X ("William" -> not resolved by the mocked lookup)
  expect_equal(res, c("Female", "Unknown"))
})

test_that("lowering the threshold accepts the partial match; 1.0 accepts only exact", {
  testthat::local_mocked_bindings(lookup_first_name_gender = no_lookup)
  lo <- classify_gender_from_subject("Statue of William Iii", names = NA_character_,
                                     person_lookup = people, threshold = 0.6)
  expect_equal(lo, "Male")
  hi <- classify_gender_from_subject(c("Statue of Mrs Siddons", "Statue of William Iii"),
                                     names = c(NA_character_, NA_character_),
                                     person_lookup = people, threshold = 1)
  expect_equal(hi, c("Female", "Unknown"))
})

test_that("without a Wikidata match, name rules apply to the extracted subject", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      m <- c(maria = "Female")
      stats::setNames(unname(m[tolower(names)]), names)
    }
  )
  res <- classify_gender_from_subject(c("Tomb of Maria Tustin", "Memorial of Lord Nelson"),
                                      names = c(NA_character_, NA_character_))
  expect_equal(res, c("Female", "Male"))
})

test_that("candidate_subjects lists the unique extracted subjects that follow a prefix", {
  txt <- c("Statue of Richard Cobden", "Statue of Richard Cobden",
           "Queen Victoria", NA, "Tomb of Maria Tustin")
  expect_equal(candidate_subjects(txt), c("Richard Cobden", "Maria Tustin"))
})

test_that("Mrs/Miss/Ms/Mr are titles, and 'Siege' is not a first name", {
  testthat::local_mocked_bindings(
    lookup_first_name_gender = function(names, threshold = 0.9) {
      # the gender data really does call these surnames/words Male
      m <- c(siddons = "Male", siege = "Male")
      stats::setNames(unname(m[tolower(names)]), names)
    }
  )
  res <- classify_gender_from_subject(
    c("Statue of Mrs Siddons", "Statue of Miss Smith", "Memorial to the Siege of Cadiz"),
    names = rep(NA_character_, 3)
  )
  expect_equal(res, c("Female", "Female", "Unknown"))
})
