#' Get latest memorials from London Remembers
#'
#' Fetches the most recently added memorials from the London Remembers website.
#'
#' @param pages Integer, number of pages to fetch (default: 1)
#' @return A tibble containing memorial information with columns:
#'   \describe{
#'     \item{title}{Memorial title}
#'     \item{url}{URL to memorial page}
#'     \item{memorial_type}{Type of memorial (statue, plaque, etc.)}
#'     \item{subjects}{Subjects commemorated}
#'     \item{location}{Location of the memorial}
#'   }
#' @export
#' @importFrom rvest html_elements html_text2 html_attr html_element
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @importFrom purrr map_dfr
#' @examples
#' \dontrun{
#' memorials <- get_memorials_latest(pages = 2)
#' }
get_memorials_latest <- function(pages = 1) {
  all_data <- list()

  for (page in 1:pages) {
    url <- if (page == 1) {
      sprintf("%s/memorials/latest", base_url)
    } else {
      sprintf("%s/memorials/latest?page=%d", base_url, page)
    }

    message(sprintf("Fetching page %d of %d...", page, pages))
    html <- fetch_page(url)

    if (is.null(html)) {
      warning(sprintf("Failed to fetch page %d", page))
      next
    }

    # Extract memorial items
    items <- rvest::html_elements(html, ".memorial.card")

    if (length(items) == 0) {
      warning(sprintf("No memorial items found on page %d", page))
      next
    }

    page_data <- purrr::map_dfr(items, function(item) {
      # Extract title and URL
      title_elem <- rvest::html_element(item, "h2 a")
      title <- clean_text(rvest::html_text2(title_elem))
      url <- rvest::html_attr(title_elem, "href")

      # Extract memorial type
      type_elem <- rvest::html_element(item, ".memorial-type, .type")
      memorial_type <- clean_text(rvest::html_text2(type_elem))

      # Extract subjects
      subjects_elem <- rvest::html_element(item, ".subjects, .commemorates")
      subjects <- clean_text(rvest::html_text2(subjects_elem))

      # Extract location
      location_elem <- rvest::html_element(item, "h3")
      location <- clean_text(rvest::html_text2(location_elem))

      tibble::tibble(
        title = title,
        url = if (!is.na(url) && !grepl("^http", url)) paste0(base_url, url) else url,
        memorial_type = memorial_type,
        subjects = subjects,
        location = location
      )
    })

    all_data[[page]] <- page_data
    Sys.sleep(1) # Be polite to the server
  }

  dplyr::bind_rows(all_data)
}


#' Get detailed information about a specific memorial
#'
#' @param memorial_url Character string, URL or slug of the memorial
#' @return A list containing detailed memorial information
#' @export
#' @importFrom rvest html_elements html_text2 html_attr html_element
#' @examples
#' \dontrun{
#' memorial <- get_memorial("/memorials/john-lennon-statue")
#' }
get_memorial <- function(memorial_url) {
  if (!grepl("^http", memorial_url)) {
    memorial_url <- paste0(base_url, memorial_url)
  }

  html <- fetch_page(memorial_url)
  if (is.null(html)) {
    return(NULL)
  }

  # Extract memorial details
  title <- clean_text(rvest::html_text2(rvest::html_element(html, "h1")))

  # Extract type
  type <- clean_text(rvest::html_text2(rvest::html_element(html, ".memorial-type")))

  # Extract inscription
  inscription <- clean_text(rvest::html_text2(rvest::html_element(html, ".inscription")))

  # Extract location
  location <- clean_text(rvest::html_text2(rvest::html_element(html, ".location, .address")))

  # Extract coordinates if available
  lat <- rvest::html_attr(rvest::html_element(html, "[data-latitude]"), "data-latitude")
  lon <- rvest::html_attr(rvest::html_element(html, "[data-longitude]"), "data-longitude")

  # Extract subjects/commemorates
  subjects <- rvest::html_elements(html, ".subjects a, .commemorates a")
  subjects_list <- clean_text(rvest::html_text2(subjects))

  # Extract erected date
  erected <- clean_text(rvest::html_text2(rvest::html_element(html, ".erected, .date")))

  list(
    title = title,
    url = memorial_url,
    type = type,
    inscription = inscription,
    location = location,
    latitude = lat,
    longitude = lon,
    subjects = subjects_list,
    erected = erected
  )
}


#' Search for memorials
#'
#' @param query Character string, search term
#' @param pages Integer, number of pages to fetch (default: 1)
#' @return A tibble containing search results
#' @export
#' @importFrom rvest html_elements html_text2 html_attr html_element
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @examples
#' \dontrun{
#' results <- search_memorials("John", pages = 3)
#' }
search_memorials <- function(query, pages = 1) {
  all_data <- list()

  for (page in 1:pages) {
    url <- sprintf("%s/search?q=%s&page=%d",
                   base_url,
                   utils::URLencode(query),
                   page)

    message(sprintf("Searching page %d of %d...", page, pages))
    html <- fetch_page(url)

    if (is.null(html)) {
      warning(sprintf("Failed to fetch search page %d", page))
      next
    }

    # Extract search results
    items <- rvest::html_elements(html, ".memorial.card")

    if (length(items) == 0) {
      message(sprintf("No results found on page %d", page))
      break
    }

    page_data <- purrr::map_dfr(items, function(item) {
      title_elem <- rvest::html_element(item, "h2 a")
      title <- clean_text(rvest::html_text2(title_elem))
      url <- rvest::html_attr(title_elem, "href")

      type_elem <- rvest::html_element(item, ".type, .memorial-type")
      type <- clean_text(rvest::html_text2(type_elem))

      tibble::tibble(
        title = title,
        url = if (!is.na(url) && !grepl("^http", url)) paste0(base_url, url) else url,
        type = type
      )
    })

    all_data[[page]] <- page_data
    Sys.sleep(1)
  }

  dplyr::bind_rows(all_data)
}
