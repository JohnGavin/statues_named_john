# R/tar_plans/memorial_analysis_plan.R

memorial_analysis_plan <- list(
  # Fetch data
  tar_target(wikidata_raw, get_statues_wikidata()),
  tar_target(osm_raw, get_statues_osm()),
  # GLHER is optional and currently unavailable (#94): record why, rather
  # than letting it look like a source that simply has no statues.
  # Re-fetch whenever the stored status is not "ok", so a one-off failure
  # (timeout, 5xx) is not cached as if it were a result (roborev 10508).
  tar_target(
    glher_fetch,
    fetch_optional_source("glher", get_statues_glher()),
    format = "rds",
    cue = tarchetypes::tar_cue_force(glher_needs_refetch())
  ),
  tar_target(glher_raw, glher_fetch$data),

  # Per-source row counts and status (ok / empty / unavailable + reason)
  tar_target(
    source_status,
    dplyr::bind_rows(
      source_row("wikidata", wikidata_raw),
      source_row("osm", osm_raw),
      glher_fetch$status,
      wikidata_people_fetch$status
    )
  ),

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

  # Single classification threshold (inst/extdata/params.csv). A file
  # target, so editing the threshold re-runs the analysis.
  tar_target(params_file, params_path(), format = "file"),
  tar_target(classification_threshold, {
    params_file
    get_param("classification_threshold")
  }, format = "rds"),

  # "Statue of X": subjects of statues the name rules leave Unknown, looked
  # up on Wikidata (is X a person, and which sex?). Optional: if Wikidata
  # is unreachable the lookup is recorded as unavailable in source_status
  # and retried on the next run, and classification carries on without it.
  tar_target(
    people_candidates,
    {
      base <- analyze_by_gender(all_memorials, threshold = classification_threshold)$data
      unknown <- base[base$inferred_gender == "Unknown", ]
      candidate_subjects(dplyr::coalesce(unknown$subject, unknown$name))
    },
    format = "rds"
  ),
  tar_target(
    wikidata_people_fetch,
    fetch_optional_source("wikidata_people", lookup_wikidata_people(people_candidates)),
    format = "rds",
    cue = tarchetypes::tar_cue_force(optional_needs_refetch("wikidata_people_fetch"))
  ),
  tar_target(wikidata_people, wikidata_people_fetch$data),

  # Analysis
  tar_target(
    gender_analysis,
    analyze_by_gender(all_memorials, person_lookup = wikidata_people,
                      threshold = classification_threshold),
    format = "rds"
  ),
  
  tar_target(
    johns_comparison,
    compare_johns_vs_women(all_memorials, person_lookup = wikidata_people,
                           threshold = classification_threshold),
    format = "rds"
  ),

  # Display table: whole-percent labels (stored percent keeps 2 dp, #102)
  tar_target(
    summary_table,
    gender_analysis$summary %>%
      dplyr::select(Category = inferred_gender, Count = n, Percent = percent_label)
  ),

  tar_target(
    findings,
    gender_analysis$summary %>%
      dplyr::rename(Category = inferred_gender, Count = n, Percentage = percent)
  ),

  # Plots
  tar_target(
    category_plot,
    ggplot(gender_analysis$summary, aes(x = inferred_gender, y = n, fill = inferred_gender)) +
      geom_col() +
      geom_text(aes(label = sprintf("%d (%s)", n, percent_label)), vjust = -0.5) +
      labs(
        title = "Gender Representation in London Statues",
        x = "Gender",
        y = "Count"
      ) +
      theme_minimal(),
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