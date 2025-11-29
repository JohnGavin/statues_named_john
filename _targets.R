#!/usr/bin/env Rscript
# _targets.R - targets pipeline for vignette data preprocessing
# Run with: tar_make() in R

library(targets)
library(tarchetypes)

# Load package from source (for development)
if (file.exists("DESCRIPTION")) {
  suppressMessages(devtools::load_all())
}

# Set options
tar_option_set(
  packages = c(
    "londonremembers", # Or statuesnamedjohn, ensuring correct package load
    "dplyr",
    "tidyr",
    "stringr",
    "ggplot2",
    "lubridate",
    "arrow" # Added for parquet support
  ),
  format = "parquet" # Use parquet for storage
)

# Define pipeline
list(
  # Fetch data from APIs
  tar_target(
    wikidata_raw,
    fetch_wikidata_statues()
  ),
  
  tar_target(
    osm_raw,
    fetch_osm_statues()
  ),

  # Clean and Combine
  tar_target(
    all_memorials,
    join_and_clean_data(wikidata_raw, osm_raw)
  ),

  # Summary statistics
  tar_target(
    summary_table,
    all_memorials %>%
      group_by(subject_category) %>%
      summarise(
        Total = n(),
        `Unique Memorials` = n_distinct(title, na.rm = TRUE)
      ) %>%
      arrange(desc(Total))
  ),

  # Type distribution table (Note: 'memorial_type' was 'type' in raw data, need to ensure column exists if needed)
  # Current join_and_clean_data only keeps standard cols. 
  # Let's focus on subject category analysis for the vignette.
  
  # Distribution table
  tar_target(
    findings,
    all_memorials %>%
      group_by(subject_category) %>%
      summarise(
        count = n(),
        percentage = round(100 * n() / nrow(all_memorials), 1)
      )
  ),
  
  # Visualizations
  tar_target(
    category_plot,
    ggplot(all_memorials, aes(x = subject_category, fill = subject_category)) +
      geom_bar() +
      labs(
        title = "Memorials in London by Category",
        subtitle = "Comparing Johns, Women, and Dogs",
        x = "Category",
        y = "Count"
      ) +
      theme_minimal()
  )
)
