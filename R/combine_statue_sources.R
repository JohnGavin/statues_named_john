#' Combine and Deduplicate Statue Data from Multiple Sources
#'
#' @description
#' Merges statue data from multiple sources, deduplicates based on
#' geographic proximity, and enriches records with data from multiple sources.
#'
#' @param source_list Named list of standardized data frames, e.g.
#'   list(wikidata = wd_data, osm = osm_data, glher = glher_data)
#' @param distance_threshold Distance in meters for considering records
#'   as duplicates (default: 50)
#' @param prefer_sources Vector of source names in order of preference
#'   for resolving conflicts (default: c("glher", "wikidata", "osm", "he"))
#'
#' @return A tibble with combined, deduplicated statue data, with additional
#'   columns:
#'   - sources: character - comma-separated list of contributing sources
#'   - n_sources: integer - number of sources contributing data
#'   - is_multi_source: logical - TRUE if data from multiple sources
#'   - duplicate_ids: character - IDs of duplicate records that were merged
#'
#' @examples
#' \dontrun{
#' # Get data from all sources
#' wd <- get_statues_wikidata() %>% standardize_statue_data("wikidata")
#' osm <- get_statues_osm() %>% standardize_statue_data("osm")
#' glher <- get_statues_glher() %>% standardize_statue_data("glher")
#'
#' # Combine
#' all_statues <- combine_statue_sources(
#'   list(wikidata = wd, osm = osm, glher = glher)
#' )
#' }
#'
#' @export
combine_statue_sources <- function(source_list,
                                     distance_threshold = 50,
                                     prefer_sources = c("glher", "wikidata", "osm", "he")) {

  if (length(source_list) == 0) {
    stop("source_list must contain at least one data source")
  }

  message("Combining statue data from ", length(source_list), " sources")
  for (name in names(source_list)) {
    message("  ", name, ": ", nrow(source_list[[name]]), " records")
  }

  # Stack all sources
  all_records <- dplyr::bind_rows(source_list, .id = "source_name")

  message("\nTotal records before deduplication: ", nrow(all_records))

  # Convert to SF object for spatial operations
  all_records_sf <- all_records %>%
    dplyr::filter(!is.na(lat), !is.na(lon)) %>%
    sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

  # Duplicates: records within distance_threshold that describe the same
  # subject (#117). Proximity alone merged distinct statues standing together.
  message("Identifying duplicates within ", distance_threshold, "m with the same subject...")

  # Create distance matrix (this can be slow for large datasets)
  distances <- sf::st_distance(all_records_sf)

  subject_text <- dplyr::coalesce(all_records_sf$subject, all_records_sf$name)
  duplicate_groups <- find_duplicate_groups(distances, distance_threshold, subject_text)

  message("Found ", length(duplicate_groups), " groups of potential duplicates")

  # Merge duplicate groups
  merged_records <- merge_duplicate_groups(
    all_records_sf,
    duplicate_groups,
    prefer_sources
  )

  message("Records after deduplication: ", nrow(merged_records))

  # Convert back from SF to regular tibble with lat/lon columns
  merged_records_tibble <- merged_records %>%
    dplyr::mutate(
      coords = sf::st_coordinates(geometry),
      lon = coords[, 1],
      lat = coords[, 2]
    ) %>%
    sf::st_drop_geometry() %>%
    dplyr::select(-coords)

  return(merged_records_tibble)
}

# Helper function: Find groups of duplicates. A pair is a duplicate when the
# records are within `threshold` metres AND same_subject() holds; groups are
# the connected components of those pairs (#117).
find_duplicate_groups <- function(distance_matrix, threshold, subject_text) {
  n <- nrow(distance_matrix)
  d <- matrix(as.numeric(distance_matrix), n, n)
  pairs <- which(d <= threshold & upper.tri(d), arr.ind = TRUE)
  if (nrow(pairs) == 0) {
    return(list())
  }
  keys <- subject_tokens(subject_text)
  is_dup <- mapply(function(i, j) tokens_match(keys[[i]], keys[[j]]),
                   pairs[, 1], pairs[, 2])
  pairs <- pairs[is_dup, , drop = FALSE]
  if (nrow(pairs) == 0) {
    return(list())
  }

  # Connected components (union-find with path halving)
  parent <- seq_len(n)
  find <- function(x) {
    while (parent[x] != x) {
      parent[x] <<- parent[parent[x]]
      x <- parent[x]
    }
    x
  }
  for (k in seq_len(nrow(pairs))) {
    a <- find(pairs[k, 1])
    b <- find(pairs[k, 2])
    if (a != b) parent[max(a, b)] <- min(a, b)
  }
  roots <- vapply(seq_len(n), find, integer(1))
  groups <- split(seq_len(n), roots)
  unname(groups[lengths(groups) > 1])
}

# Words that do not identify a subject: object words, titles, articles and
# prepositions. "Statue of Queen Victoria" and "Queen Victoria" both reduce
# to {victoria}.
subject_stopwords <- c(
  "the", "a", "an", "of", "to", "for", "and", "in", "at", "on", "with", "by",
  "statue", "statues", "bust", "sculpture", "figure", "effigy", "tomb", "grave",
  "headstone", "monument", "memorial", "plaque", "tablet", "marker",
  "sir", "dame", "lord", "lady", "queen", "king", "prince", "princess",
  "mrs", "mr", "dr", "st", "saint"
)

# Identifying words of each subject: extract_subject(), lower case, letters
# only, generic words dropped. A list of character vectors (empty when the
# text is NA or only generic words).
subject_tokens <- function(text) {
  x <- tolower(extract_subject(text))
  x <- gsub("[^a-z ]", " ", x)
  lapply(strsplit(x, "\\s+"), function(w) {
    w <- w[!is.na(w) & nzchar(w)]
    unique(w[!w %in% subject_stopwords])
  })
}

# Two token sets describe the same subject when one contains the other or
# they share at least half of their combined words. Empty sets never match.
tokens_match <- function(a, b) {
  if (length(a) == 0 || length(b) == 0) {
    return(FALSE)
  }
  shared <- length(intersect(a, b))
  shared == length(a) || shared == length(b) ||
    shared / length(union(a, b)) >= 0.5
}

#' Do two texts name the same subject?
#'
#' @description
#' Used by [combine_statue_sources()] to decide whether two nearby records
#' are the same memorial. Each text is reduced with [extract_subject()] to
#' its identifying words (object words such as "statue" or "memorial",
#' titles and articles are dropped). The subjects match when one word set
#' contains the other, or they share at least half of their combined words.
#'
#' @param a,b Character vectors of subject or name text, recycled together.
#' @return Logical vector; \code{FALSE} when either text is \code{NA} or has
#'   no identifying words.
#' @export
#' @examples
#' same_subject("Edith Cavell Memorial", "The Edith Cavell Memorial")
#' same_subject("Statue of Lord Herbert of Lea", "Florence Nightingale")
same_subject <- function(a, b) {
  ka <- subject_tokens(a)
  kb <- subject_tokens(b)
  mapply(tokens_match, ka, kb, USE.NAMES = FALSE)
}

# Helper function: Merge duplicate groups
merge_duplicate_groups <- function(sf_data, groups, prefer_sources) {
  # Separate records into duplicates and non-duplicates
  all_duplicate_indices <- unlist(groups)
  non_duplicate_indices <- setdiff(1:nrow(sf_data), all_duplicate_indices)

  non_duplicates <- sf_data[non_duplicate_indices, ]

  # Merge each group
  merged_groups <- lapply(groups, function(group_indices) {
    group_records <- sf_data[group_indices, ]
    merge_group(group_records, prefer_sources)
  })

  # Combine non-duplicates with merged duplicates (none when no group formed)
  result <- if (length(merged_groups) == 0) {
    non_duplicates
  } else {
    dplyr::bind_rows(non_duplicates, dplyr::bind_rows(merged_groups))
  }

  return(result)
}

# Helper function: Merge a single group of duplicates
merge_group <- function(group_records, prefer_sources) {
  # Sort by source preference
  group_records <- group_records %>%
    dplyr::mutate(
      source_priority = match(source, prefer_sources),
      source_priority = dplyr::if_else(is.na(source_priority),
                                        999L, source_priority)
    ) %>%
    dplyr::arrange(source_priority)

  # Start with highest priority record
  merged <- group_records[1, ]

  # Enrich with non-NA values from other sources
  for (col in names(merged)) {
    if (col %in% c("geometry", "source_priority")) next

    # If primary source has NA, try to fill from other sources
    if (is.na(merged[[col]])) {
      non_na_values <- group_records[[col]][!is.na(group_records[[col]])]
      if (length(non_na_values) > 0) {
        merged[[col]] <- non_na_values[1]
      }
    }
  }

  # Add metadata about merged sources
  merged$sources <- paste(unique(group_records$source), collapse = ", ")
  merged$n_sources <- nrow(group_records)
  merged$is_multi_source <- nrow(group_records) > 1
  merged$duplicate_ids <- paste(group_records$id, collapse = "; ")

  # Use centroid of all locations as final location
  merged$geometry <- sf::st_centroid(sf::st_union(group_records$geometry))

  return(merged)
}
