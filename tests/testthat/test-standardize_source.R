# #114: standardize_statue_data() must record which source each row came
# from. `mutate(source = source)` read the NA column that
# ensure_standard_columns() had just added, not the argument, so `source`
# was NA for every row and de-duplication could not apply its preference.

raw_sample <- function() readRDS(test_path("fixtures", "raw_sample.rds"))

test_that("standardize_statue_data() records the source on every row (#114)", {
  raw <- raw_sample()
  for (src in names(raw)) {
    std <- standardize_statue_data(raw[[src]], src)
    expect_equal(unique(std$source), src, info = src)
  }
})

test_that("de-duplication keeps the record from the preferred source (#114)", {
  raw <- raw_sample()
  osm <- standardize_statue_data(raw$osm[2, ], "osm")  # row 1 has no name
  glher <- standardize_statue_data(raw$glher[1, ], "glher")
  # Make the GLHER record a duplicate of the OSM one: same place and same
  # subject (#117 merges only those). Bind order puts OSM first, so only
  # the preference can pick GLHER.
  glher$lat <- osm$lat
  glher$lon <- osm$lon
  glher$subject <- osm$subject
  glher$name <- osm$name
  combined <- suppressMessages(
    combine_statue_sources(list(osm = osm, glher = glher), distance_threshold = 50)
  )
  expect_equal(nrow(combined), 1)
  expect_equal(combined$source, "glher")
  expect_equal(combined$source_name, "glher")
  expect_setequal(strsplit(combined$sources, ", ")[[1]], c("osm", "glher"))
})
