#' Catalog of available datasets
#'
#' Lists every dataset available on [dataseries.org](https://dataseries.org),
#' one row per dataset. Use the `id` column with [ds()] to download data and
#' with [ds_meta()] to inspect a dataset's dimensions.
#'
#' @return A `data.frame` with one row per dataset and the columns `id`,
#'   `title`, `concept`, `topic`, `source`, `license`, `frequency`, `start`,
#'   `end` and `n_series`.
#' @examples
#' \donttest{
#' cat <- ds_catalog()
#' head(cat)
#'
#' # search the catalog
#' cat[grepl("price", cat$title, ignore.case = TRUE), c("id", "title")]
#' }
#' @export
ds_catalog <- function() {
  raw <- ds_get_json("/catalog", simplify = FALSE)
  rows <- lapply(raw, function(d) {
    data.frame(
      id        = ds_scalar(d$id),
      title     = ds_label(d$title),
      concept   = ds_scalar(d$concept),
      topic     = ds_scalar(d$topic),
      source    = ds_source_name(d$source),
      license   = ds_scalar(d$license),
      frequency = ds_scalar(d$frequency),
      start     = ds_scalar(d$start),
      end       = ds_scalar(d$end),
      n_series  = as.integer(d$n_series %||% NA_integer_),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$id), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Search for series across all datasets
#'
#' Returns a flat, searchable table of the individual series available across
#' every dataset on [dataseries.org](https://dataseries.org) — one row per
#' series. This is the finest-grained way to discover what exists: grep it, or
#' pass a `pattern` to filter. The `dataset`, `dim` and `code` columns are
#' exactly what you feed back to [ds()].
#'
#' @param pattern optional search string, treated as a case-insensitive regular
#'   expression and matched against the series `label` and `dataset_title`. When
#'   `NULL` (the default) the full table is returned.
#' @return A `data.frame` with the columns `dataset`, `dataset_title`,
#'   `frequency`, `dim`, `code`, `label` and `path`.
#' @seealso [ds_catalog()] for the dataset-level list and [ds_meta()] for one
#'   dataset's dimensions.
#' @examples
#' \donttest{
#' # everything
#' ds_search()
#'
#' # find unemployment series, then download one
#' hits <- ds_search("unemployment")
#' head(hits)
#' ds(hits$dataset[1], setNames(list(hits$code[1]), hits$dim[1]))
#' }
#' @export
ds_search <- function(pattern = NULL) {
  raw <- ds_get_json("/search-index.json", simplify = FALSE)
  rows <- lapply(raw, function(e) {
    data.frame(
      dataset       = ds_scalar(e$datasetId),
      dataset_title = ds_label(e$datasetTitle),
      frequency     = ds_scalar(e$freq),
      dim           = ds_scalar(e$dim),
      code          = ds_scalar(e$code),
      label         = ds_label(e$label),
      path          = paste(unlist(e$path), collapse = " / "),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  if (!is.null(pattern)) {
    hit <- grepl(pattern, out$label, ignore.case = TRUE) |
           grepl(pattern, out$dataset_title, ignore.case = TRUE)
    out <- out[hit, , drop = FALSE]
    rownames(out) <- NULL
  }
  out
}

#' Metadata for one dataset
#'
#' Returns the full metadata for a single dataset: its dimensions, the codes
#' (levels) available within each dimension, labels, source, license and date
#' range. Use this to discover which dimension codes to pass to [ds()].
#'
#' @param dataset a single dataset `id`, as listed by [ds_catalog()].
#' @return A named list (the parsed metadata). Notable elements are `dim_order`
#'   (the dataset's dimensions) and `dimensions` (each dimension's `levels`,
#'   keyed by code, with a `label`).
#' @examples
#' \donttest{
#' m <- ds_meta("ch_seco_gdp")
#' m$dim_order                       # "type", "structure", "seas_adj"
#' names(m$dimensions$type$levels)   # the codes you can pass as type = ...
#' }
#' @export
ds_meta <- function(dataset) {
  stopifnot(is.character(dataset), length(dataset) == 1L, nzchar(dataset))
  m <- ds_get_json(paste0("/dataset/", utils::URLencode(dataset, reserved = TRUE),
                          "/meta"), simplify = FALSE)
  if (!is.null(m$error)) {
    stop("unknown dataset: '", dataset, "'. See ds_catalog() for valid ids.",
         call. = FALSE)
  }
  m
}

#' Inventory of available series (deprecated)
#'
#' Deprecated. Use [ds_catalog()] for the dataset-level list or [ds_search()]
#' for individual series. Retained as a thin wrapper so code written against
#' earlier versions keeps working.
#'
#' @return The value of [ds_catalog()].
#' @keywords internal
#' @export
inventory <- function() {
  .Deprecated(msg = paste(
    "'inventory()' is deprecated.\n",
    "Use 'ds_catalog()' for datasets or 'ds_search()' for individual series."
  ))
  ds_catalog()
}
