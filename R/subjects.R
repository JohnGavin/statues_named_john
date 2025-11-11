#' Get subjects by category
#'
#' Fetches subjects (people, groups, buildings) from a specific category.
#'
#' @param category Character string, category name (e.g., "Literature", "Medicine")
#' @param pages Integer, number of pages to fetch (default: 1)
#' @return A tibble containing subject information
#' @export
#' @importFrom rvest html_elements html_text2 html_attr html_element
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @importFrom purrr map_dfr
#' @examples
#' \dontrun{
#' literature <- get_subjects_by_category("Literature", pages = 2)
#' }
get_subjects_by_category <- function(category, pages = 1) {
  all_data <- list()

  # URL encode the category
  category_slug <- tolower(gsub(" ", "-", category))

  for (page in 1:pages) {
    url <- if (page == 1) {
      sprintf("%s/subjects/categories/%s", base_url, category_slug)
    } else {
      sprintf("%s/subjects/categories/%s?page=%d", base_url, category_slug, page)
    }

    message(sprintf("Fetching %s page %d of %d...", category, page, pages))
    html <- fetch_page(url)

    if (is.null(html)) {
      warning(sprintf("Failed to fetch page %d", page))
      next
    }

    items <- rvest::html_elements(html, ".subject-item, .item")

    if (length(items) == 0) {
      message(sprintf("No subjects found on page %d", page))
      break
    }

    page_data <- purrr::map_dfr(items, function(item) {
      title_elem <- rvest::html_element(item, "h3 a, h2 a, a")
      name <- clean_text(rvest::html_text2(title_elem))
      url <- rvest::html_attr(title_elem, "href")

      type_elem <- rvest::html_element(item, ".subject-type, .type")
      subject_type <- clean_text(rvest::html_text2(type_elem))

      tibble::tibble(
        name = name,
        url = if (!is.na(url) && !grepl("^http", url)) paste0(base_url, url) else url,
        subject_type = subject_type,
        category = category
      )
    })

    all_data[[page]] <- page_data
    Sys.sleep(1)
  }

  dplyr::bind_rows(all_data)
}


#' Get detailed information about a specific subject
#'
#' @param subject_url Character string, URL or slug of the subject
#' @return A list containing detailed subject information including associated memorials
#' @export
#' @importFrom rvest html_elements html_text2 html_attr html_element
#' @importFrom tibble tibble
#' @examples
#' \dontrun{
#' subject <- get_subject("/subjects/john-lennon")
#' }
get_subject <- function(subject_url) {
  if (!grepl("^http", subject_url)) {
    subject_url <- paste0(base_url, subject_url)
  }

  html <- fetch_page(subject_url)
  if (is.null(html)) {
    return(NULL)
  }

  # Extract subject details
  name <- clean_text(rvest::html_text2(rvest::html_element(html, "h1")))

  # Extract type
  subject_type <- clean_text(rvest::html_text2(rvest::html_element(html, ".subject-type")))

  # Extract biography/description
  bio <- clean_text(rvest::html_text2(rvest::html_element(html, ".biography, .description")))

  # Extract dates
  born <- clean_text(rvest::html_text2(rvest::html_element(html, ".born, .birth-date")))
  died <- clean_text(rvest::html_text2(rvest::html_element(html, ".died, .death-date")))

  # Extract associated memorials
  memorial_links <- rvest::html_elements(html, ".memorials a, .memorial-list a")
  memorials <- tibble::tibble(
    title = clean_text(rvest::html_text2(memorial_links)),
    url = rvest::html_attr(memorial_links, "href")
  )

  if (nrow(memorials) > 0 && any(!is.na(memorials$url))) {
    memorials$url <- ifelse(
      !grepl("^http", memorials$url),
      paste0(base_url, memorials$url),
      memorials$url
    )
  }

  list(
    name = name,
    url = subject_url,
    type = subject_type,
    biography = bio,
    born = born,
    died = died,
    memorials = memorials
  )
}


#' Get subjects by gender
#'
#' Helper function to filter subjects by gender-related keywords.
#' Note: This is an approximation based on available data.
#'
#' @param gender Character string: "male", "female", or specific terms
#' @param pages Integer, number of search pages to fetch
#' @return A tibble containing subjects matching the gender criteria
#' @export
#' @examples
#' \dontrun{
#' women <- get_subjects_by_gender("female", pages = 5)
#' }
get_subjects_by_gender <- function(gender = "female", pages = 5) {
  # This is a simplified approach - actual implementation may need refinement
  # based on the website's actual structure
  search_terms <- list(
    male = c("men", "man", "male"),
    female = c("women", "woman", "female")
  )

  term <- search_terms[[tolower(gender)]][1]
  if (is.na(term)) term <- gender

  search_memorials(term, pages = pages)
}
