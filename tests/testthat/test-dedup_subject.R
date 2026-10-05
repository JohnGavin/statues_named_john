# #117: de-duplication must merge only records that are near each other AND
# describe the same subject. It used to keep one record from everything
# within 50m of a seed record (4,666 raw records -> 2,301, groups of up to
# 165), so distinct statues standing together became one.

rec <- function(source, name, lat, lon, subject = NA_character_) {
  tibble::tibble(id = paste0(source, "_", make.names(name)), name = name,
                 subject = subject, lat = lat, lon = lon, source = source)
}
combine <- function(...) {
  suppressMessages(combine_statue_sources(list(...), distance_threshold = 50))
}
# About 20m apart in Waterloo Place
lat0 <- 51.5072
lon0 <- -0.1322
near_lat <- lat0 + 0.00018

test_that("distinct statues standing together are not merged (#117)", {
  out <- combine(
    osm = rec("osm", "Florence Nightingale the 'Lady with the Lamp'", lat0, lon0),
    glher = rec("glher", "Statue of Lord Herbert of Lea", near_lat, lon0)
  )
  expect_equal(nrow(out), 2)
  expect_setequal(out$name, c("Florence Nightingale the 'Lady with the Lamp'",
                              "Statue of Lord Herbert of Lea"))
})

test_that("the same statue described differently is merged, preferred source kept (#117)", {
  out <- combine(
    osm = rec("osm", "Edith Cavell Memorial", lat0, lon0),
    glher = rec("glher", "The Edith Cavell Memorial", near_lat, lon0)
  )
  expect_equal(nrow(out), 1)
  expect_equal(out$source, "glher")
  expect_equal(out$n_sources, 2)
})

test_that("a subject-only match far apart is not merged (#117)", {
  out <- combine(
    osm = rec("osm", "Statue of Queen Victoria", lat0, lon0),
    glher = rec("glher", "Queen Victoria", lat0 + 0.01, lon0)  # ~1.1 km
  )
  expect_equal(nrow(out), 2)
})

test_that("records near a common neighbour are not merged with each other (#117)", {
  # B is near both A and C, and matches neither: three separate statues.
  out <- combine(
    osm = dplyr::bind_rows(
      rec("osm", "Statue of Sir Hugh Myddelton", lat0, lon0),
      rec("osm", "Gracie Fields", near_lat, lon0),
      rec("osm", "Mary Seacole", near_lat + 0.00018, lon0)
    )
  )
  expect_equal(nrow(out), 3)
})

test_that("records without a name or subject are never merged (#117)", {
  out <- combine(
    osm = rec("osm", NA_character_, lat0, lon0),
    glher = rec("glher", NA_character_, near_lat, lon0)
  )
  expect_equal(nrow(out), 2)
})

test_that("same_subject() matches on the subject, ignoring generic and title words", {
  expect_true(same_subject("Edith Cavell Memorial", "The Edith Cavell Memorial"))
  expect_true(same_subject("Statue of Florence Nightingale",
                           "Florence Nightingale the 'Lady with the Lamp'"))
  expect_true(same_subject("Statue of Queen Victoria", "Queen Victoria"))
  expect_false(same_subject("Statue of Lord Herbert of Lea", "Florence Nightingale"))
  expect_false(same_subject("Statue", "Memorial"))
  expect_false(same_subject(NA_character_, "Mary Seacole"))
})
