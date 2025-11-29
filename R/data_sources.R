#' Fetch data from Art UK
#'
#' Scrapes statue and sculpture data from Art UK.
#'
#' @param pages Integer, number of pages to scrape (default: 1)
#' @return A tibble containing Art UK data
#' @export
#' @importFrom rvest html_elements html_text2 html_attr html_element
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
fetch_art_uk_data <- function(pages = 1) {
  # Base URL for Art UK sculpture search in London
  # Note: This URL might need adjustment based on specific search parameters
  base_search_url <- "https://artuk.org/discover/artworks/view_as/list/search/work_type:sculpturestatue--region:englandlondon"
  
  all_data <- list()
  
  for (page in 1:pages) {
    url <- if (page == 1) {
      base_search_url
    } else {
      sprintf("%s/page/%d", base_search_url, page)
    }
    
    message(sprintf("Fetching Art UK page %d of %d...", page, pages))
    html <- fetch_page(url)
    
    if (is.null(html)) {
      warning(sprintf("Failed to fetch Art UK page %d", page))
      next
    }
    
    items <- rvest::html_elements(html, ".artwork-result, .search-result") # Class names need verification
    
    if (length(items) == 0) {
      # Fallback for different page structure
      items <- rvest::html_elements(html, ".grid__item")
    }

    if (length(items) == 0) {
       warning(sprintf("No items found on Art UK page %d", page))
       break
    }
    
    page_data <- purrr::map_dfr(items, function(item) {
      title_elem <- rvest::html_element(item, ".artwork-title, h3")
      title <- clean_text(rvest::html_text2(title_elem))
      
      artist_elem <- rvest::html_element(item, ".artist-name")
      artist <- clean_text(rvest::html_text2(artist_elem))
      
      date_elem <- rvest::html_element(item, ".artwork-date")
      date <- clean_text(rvest::html_text2(date_elem))

      link_elem <- rvest::html_element(item, "a")
      link <- rvest::html_attr(link_elem, "href")
      
      tibble::tibble(
        title = title,
        artist = artist,
        date = date,
        url = link,
        source = "Art UK"
      )
    })
    
    all_data[[page]] <- page_data
    Sys.sleep(1) # Be polite
  }
  
  dplyr::bind_rows(all_data)
}

#' Fetch data from Historic England
#'
#' Fetches listed building data for statues.
#' 
#' @param pages Integer, number of pages (default 1)
#' @return A tibble containing Historic England data
#' @export
fetch_historic_england_data <- function(pages = 1) {
  # Placeholder: Historic England often provides CSV downloads or requires complex search queries.
  # For now, we will define the structure.
  
  # This would ideally hit an API or scrape a search result page like:
  # https://historicengland.org.uk/listing/the-list/results/?search=statue&searchType=NHLE+Simple
  
  message("Historic England scraper not yet fully implemented. Returning empty tibble.")
  
  tibble::tibble(
    title = character(),
    grade = character(),
    location = character(),
    source = character()
  )
}

#' Fetch statues from Wikidata
#'
#' Queries Wikidata for statues and public art in London using SPARQL.
#'
#' @return A tibble containing Wikidata results
#' @export
#' @importFrom httr GET add_headers content
#' @importFrom dplyr as_tibble
fetch_wikidata_statues <- function() {
  # SPARQL query for Statues (Q179700) or Public Art (Q557908) in London (Q84)
  query <- '
  SELECT ?item ?itemLabel ?image ?coords ?inception ?creator ?creatorLabel ?gender ?genderLabel WHERE {
    ?item wdt:P131* wd:Q84.                 # Located in London
    { ?item wdt:P31 wd:Q179700. } UNION { ?item wdt:P31 wd:Q557908. } # Statue OR Public Art
    
    OPTIONAL { ?item wdt:P18 ?image. }      # Image
    OPTIONAL { ?item wdt:P625 ?coords. }    # Coordinates
    OPTIONAL { ?item wdt:P571 ?inception. } # Inception date
    
    OPTIONAL { 
      ?item wdt:P170 ?creator.              # Creator
      ?creator wdt:P21 ?gender.             # Creator gender
    }
    
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
  }
  LIMIT 2000
  '
  
  url <- "https://query.wikidata.org/sparql"
  
  message("Querying Wikidata SPARQL endpoint...")
  
  tryCatch({
    response <- httr::GET(
      url, 
      query = list(query = query, format = "json"),
      httr::add_headers(Accept = "application/sparql-results+json")
    )
    
    if (response$status_code == 200) {
      data <- httr::content(response, as = "parsed", type = "application/json")
      
      # Parse JSON result into a tibble
      results <- data$results$bindings
      
      if (length(results) == 0) {
        warning("No results returned from Wikidata.")
        return(tibble::tibble())
      }
      
      processed_data <- purrr::map_dfr(results, function(x) {
        tibble::tibble(
          item = x$item$value,
          title = x$itemLabel$value,
          image = if(!is.null(x$image)) x$image$value else NA_character_,
          coords = if(!is.null(x$coords)) x$coords$value else NA_character_,
          inception = if(!is.null(x$inception)) x$inception$value else NA_character_,
          creator = if(!is.null(x$creatorLabel)) x$creatorLabel$value else NA_character_,
          creator_gender = if(!is.null(x$genderLabel)) x$genderLabel$value else NA_character_,
          source = "Wikidata"
        )
      })
      
      return(processed_data)
    } else {
      warning(sprintf("Wikidata query failed: %d", response$status_code))
      return(tibble::tibble())
    }
  }, error = function(e) {
    warning(sprintf("Error fetching Wikidata: %s", e$message))
    return(tibble::tibble())
  })
}

#' Fetch statues from OpenStreetMap
#'
#' Queries the Overpass API for memorials and statues in London.
#'
#' @return A tibble containing OSM results
#' @export
#' @importFrom httr POST content
#' @importFrom dplyr bind_rows
fetch_osm_statues <- function() {
  # Overpass QL query
  # Area for London is roughly defined or fetched by name. 
  # Using a bounding box for Greater London for simplicity in this query string to avoid large area timeouts
  # or querying by area name "Greater London".
  
  query <- '
  [out:json][timeout:25];
  area[name="Greater London"]->.searchArea;
  (
    node["historic"="memorial"]["memorial"="statue"](area.searchArea);
    way["historic"="memorial"]["memorial"="statue"](area.searchArea);
    relation["historic"="memorial"]["memorial"="statue"](area.searchArea);
  );
  out body;
  >;
  out skel qt;
  '
  
  url <- "https://overpass-api.de/api/interpreter"
  
  message("Querying OpenStreetMap Overpass API...")
  
  tryCatch({
    response <- httr::POST(url, body = query)
    
    if (response$status_code == 200) {
      data <- httr::content(response, as = "parsed", type = "application/json")
      elements <- data$elements
      
      if (length(elements) == 0) {
        return(tibble::tibble())
      }
      
      # Extract relevant tags
      processed_data <- purrr::map_dfr(elements, function(x) {
        tags <- x$tags
        if (is.null(tags)) return(NULL)
        
        tibble::tibble(
          osm_id = x$id,
          type = x$type,
          lat = if(!is.null(x$lat)) x$lat else NA_real_,
          lon = if(!is.null(x$lon)) x$lon else NA_real_,
          name = if(!is.null(tags$name)) tags$name else NA_character_,
          subject = if(!is.null(tags$subject)) tags$subject else NA_character_,
          wikidata = if(!is.null(tags$`subject:wikidata`)) tags$`subject:wikidata` else NA_character_,
          source = "OpenStreetMap"
        )
      })
      
      return(processed_data)
    } else {
      warning(sprintf("OSM query failed: %d", response$status_code))
      return(tibble::tibble())
    }
  }, error = function(e) {
    warning(sprintf("Error fetching OSM: %s", e$message))
    return(tibble::tibble())
  })
}
