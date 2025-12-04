#' @importFrom httr GET content
#' @importFrom rvest read_html
NULL

# Base URL for London Remembers
base_url <- "https://www.londonremembers.com"

#' Safely fetch and parse HTML from a URL
#'
#' @param url Character string of URL to fetch
#' @return An xml_document object or NULL on error
#' @keywords internal
fetch_page <- function(url) {
  tryCatch({
    response <- httr::GET(url, httr::timeout(30))
    if (response$status_code == 200) {
      return(rvest::read_html(httr::content(response, as = "text", encoding = "UTF-8")))
    } else {
      warning(sprintf("Failed to fetch %s: Status code %d", url, response$status_code))
      return(NULL)
    }
  }, error = function(e) {
    warning(sprintf("Error fetching %s: %s", url, e$message))
    return(NULL)
  })
}

#' Clean and trim text
#'
#' @param text Character vector to clean
#' @return Cleaned character vector
#' @keywords internal
#' @importFrom stringr str_trim
clean_text <- function(text) {
  text <- stringr::str_trim(text)
  text[text == ""] <- NA_character_
  text
}
