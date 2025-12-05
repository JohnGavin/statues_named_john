# R/tar_plans/memorial_analysis_plan.R

memorial_analysis_plan <- list(
  # Fetch data
  tar_target(wikidata_raw, get_statues_wikidata()),
  tar_target(osm_raw, get_statues_osm()),
  tar_target(glher_raw, get_statues_glher()),

  # Standardize
  tar_target(wikidata_std, standardize_statue_data(wikidata_raw, "wikidata")),
  tar_target(osm_std, standardize_statue_data(osm_raw, "osm")),
  tar_target(glher_std, standardize_statue_data(glher_raw, "glher")),

  # Combine
  tar_target(
    all_memorials,
    combine_statue_sources(
      list(wikidata = wikidata_std, osm = osm_std, glher = glher_std), 
      distance_threshold = 50
    )
  ),

  # Analysis
  tar_target(
    gender_analysis,
    analyze_by_gender(all_memorials),
    format = "rds"
  ),
  
  tar_target(
    johns_comparison,
    compare_johns_vs_women(all_memorials),
    format = "rds"
  ),

  tar_target(
    summary_table,
    gender_analysis$summary
  ),

  tar_target(
    findings,
    gender_analysis$summary %>%
      dplyr::rename(Category = inferred_gender, Count = n, Percentage = percent)
  ),

  # Plots
  tar_target(
    category_plot,
    {
      # Explicitly set factor levels to ensure consistent ordering and prevent dropping
      plot_data <- gender_analysis$summary %>%
        dplyr::mutate(inferred_gender = factor(inferred_gender, 
                                               levels = c("Male", "Female", "Unknown", "Animal", "Other")))
      
      ggplot(plot_data, aes(x = inferred_gender, y = n, fill = inferred_gender)) +
        geom_col() +
        geom_text(aes(label = sprintf("%d (%.1f%%)", n, percent)), vjust = -0.5) +
        scale_x_discrete(drop = FALSE) + # Force all levels to display
        labs(
          title = "Gender Representation in London Statues (Verified)",
          x = "Gender",
          y = "Count"
        ) +
        theme_minimal()
    },
    format = "rds"
  ),

  # Map (Static ggplot for vignette PDF/HTML)
  tar_target(
    memorial_map_plot,
    {
      data_sf <- all_memorials %>%
        dplyr::filter(!is.na(lat), !is.na(lon)) %>%
        sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
        
      ggplot() +
        geom_sf(data = data_sf, aes(color = source), size = 2, alpha = 0.7) +
        labs(title = "Memorials in London by Source") +
        theme_minimal()
    },
    format = "rds"
  ),
  
  # Interactive Map (Leaflet widget)
  tar_target(
    memorial_interactive_map,
    map_statues(all_memorials, cluster = TRUE),
    format = "rds"
  )
)