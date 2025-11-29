library(testthat)
devtools::load_all()

test_that("Data processing pipeline works", {
  # Mock data for Wikidata
  mock_wiki <- tibble::tibble(
    item = c("Q1", "Q2", "Q3"),
    title = c("Statue of John Smith", "Queen Victoria Memorial", "Dog Statue"),
    inception = c("2000", "1901", "2020"),
    coords = c("Point(-0.1 51.5)", "Point(-0.2 51.6)", NA),
    creator = c("Artist A", "Artist B", "Artist C"),
    creator_gender = c("male", "male", "female"),
    source = "Wikidata"
  )
  
  # Mock data for OSM
  mock_osm <- tibble::tibble(
    osm_id = c(101, 102),
    name = c("Another John Statue", "Unknown Woman"),
    subject = c("John Doe", "Woman"),
    type = "node",
    lat = c(51.55, 51.66),
    lon = c(-0.15, -0.25),
    wikidata = NA,
    source = "OpenStreetMap"
  )
  
  # Test join_and_clean_data
  result <- join_and_clean_data(mock_wiki, mock_osm)
  
  expect_true(nrow(result) >= 5)
  expect_true("subject_category" %in% names(result))
  
  # Check classifications
  johns <- result %>% dplyr::filter(subject_category == "Men named John")
  women <- result %>% dplyr::filter(subject_category == "Women")
  dogs <- result %>% dplyr::filter(subject_category == "Dogs")
  
  expect_true(nrow(johns) >= 2) # John Smith + Another John
  expect_true(nrow(women) >= 2) # Victoria + Unknown Woman
  expect_true(nrow(dogs) >= 1)  # Dog Statue
  
  # Check Coordinates extraction
  expect_equal(result$lat[1], 51.5)
  expect_equal(result$lon[1], -0.1)
})
