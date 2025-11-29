# R/tar_plans/memorial_analysis_plan.R

memorial_analysis_plan <- list(
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
      arrange(desc(Total)),
    format = "rds"
  ),
  
  # Distribution table
  tar_target(
    findings,
    all_memorials %>%
      group_by(subject_category) %>%
      summarise(
        count = n(),
        percentage = round(100 * n() / nrow(all_memorials), 1)
      ),
    format = "rds"
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
      theme_minimal(),
    format = "rds"
  ),

  tar_target(
    memorial_map_plot,
    {
      memorials_sf <- all_memorials %>%
        dplyr::filter(!is.na(lat), !is.na(lon)) %>%
        sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
      
      ggplot() +
        geom_sf(data = memorials_sf, aes(color = subject_category), size = 2, alpha = 0.7) +
        scale_color_viridis_d() +
        labs(
          title = "Memorials in London",
          subtitle = "Spatial distribution of Johns, Women, and Dogs",
          color = "Category"
        ) +
        theme_minimal() +
        theme(legend.position = "bottom")
    },
    format = "rds"
  )
)
