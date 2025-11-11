#!/usr/bin/env Rscript
# _targets.R - targets pipeline for vignette data preprocessing
# This file preprocesses all data for the memorial analysis vignette
# Run with: tar_make() in R

library(targets)
library(tarchetypes)

# Load package from source (for development)
# When package is installed, users can comment this out
if (file.exists("DESCRIPTION")) {
  suppressMessages(devtools::load_all())
}

# Set options
tar_option_set(
  packages = c(
    "dplyr",
    "tidyr",
    "stringr",
    "ggplot2",
    "lubridate"
  ),
  format = "rds"
)

# Define pipeline
list(
  # Collect memorials for men named John
  tar_target(
    johns_raw,
    {
      message("Collecting memorials for men named John...")
      search_memorials("John", pages = 3)
    }
  ),

  tar_target(
    johns,
    johns_raw %>%
      mutate(category = "Men named John")
  ),

  # Collect memorials for women
  tar_target(
    women_terms,
    c("woman", "women", "queen", "lady", "dame")
  ),

  tar_target(
    women_raw_list,
    {
      message("Collecting memorials for women...")
      lapply(women_terms, function(term) {
        Sys.sleep(1) # Be polite to the server
        search_memorials(term, pages = 2)
      })
    }
  ),

  tar_target(
    women,
    {
      combined <- bind_rows(women_raw_list)
      if (nrow(combined) > 0 && "url" %in% names(combined)) {
        combined %>%
          distinct(url, .keep_all = TRUE) %>%
          mutate(category = "Women")
      } else {
        combined %>%
          mutate(category = "Women")
      }
    }
  ),

  # Collect memorials for dogs
  tar_target(
    dogs_raw,
    {
      message("Collecting memorials for dogs...")
      search_memorials("dog", pages = 2)
    }
  ),

  tar_target(
    dogs,
    dogs_raw %>%
      mutate(category = "Dogs")
  ),

  # Combine all memorials
  tar_target(
    all_memorials,
    bind_rows(johns, women, dogs)
  ),

  # Summary statistics
  tar_target(
    summary_table,
    all_memorials %>%
      group_by(category) %>%
      summarise(
        Total = n(),
        `Unique Memorials` = n_distinct(title, na.rm = TRUE)
      ) %>%
      arrange(desc(Total))
  ),

  # Type distribution table
  tar_target(
    type_table,
    all_memorials %>%
      group_by(category, type) %>%
      summarise(count = n(), .groups = "drop") %>%
      pivot_wider(names_from = category, values_from = count, values_fill = 0) %>%
      arrange(desc(`Men named John` + Women + Dogs))
  ),

  # Memorial types plot
  tar_target(
    memorial_types_plot,
    ggplot(all_memorials, aes(x = category, fill = type)) +
      geom_bar(position = "stack") +
      labs(
        title = "Distribution of Memorial Types",
        subtitle = "Comparing Johns, Women, and Dogs",
        x = "Category",
        y = "Number of Memorials",
        fill = "Memorial Type"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  ),

  # Memorial types proportion plot
  tar_target(
    memorial_types_proportion_plot,
    ggplot(all_memorials, aes(x = category, fill = type)) +
      geom_bar(position = "fill") +
      labs(
        title = "Proportion of Memorial Types",
        subtitle = "Comparing Johns, Women, and Dogs",
        x = "Category",
        y = "Proportion",
        fill = "Memorial Type"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_y_continuous(labels = scales::percent)
  ),

  # Distribution table
  tar_target(
    findings,
    all_memorials %>%
      group_by(category) %>%
      summarise(
        count = n(),
        percentage = round(100 * n() / nrow(all_memorials), 1)
      )
  )
)
