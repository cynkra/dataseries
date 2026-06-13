#' Download time series from dataseries.org
#'
#' `ds()` downloads open Swiss economic time series from
#' [dataseries.org](https://dataseries.org).
#'
#' Data on dataseries.org is organized into **datasets**. A dataset is a family
#' of related series and is, in most cases, a multi-dimensional *cube*: a single
#' time series is one cell of the cube, addressed by the dataset plus one code
#' per dimension. Pass those codes as **named arguments** (the names are the
#' dimension names, see [ds_meta()]):
#'
#' ```r
#' ds("ch_seco_gdp", type = "real", structure = "gdp", seas_adj = "csa")
#' ```
#'
#' Dimension arguments are optional. Omit them and you get the whole dataset
#' (all series, in long format). A few datasets are a single series and take no
#' dimensions at all (e.g. `ds("ch_kof_barometer")`). Filtering happens on the
#' server, so selecting one series does not download the whole cube.
#'
#' Downloads are **cached in memory** for the session. Run [cache_rm()] to force
#' a fresh download.
#'
#' @param dataset a single dataset `id`, as listed by [ds_catalog()].
#' @param ... dimension filters, given as named arguments where each name is a
#'   dimension of `dataset` and each value is one or more codes, e.g.
#'   `type = "real"` or `structure = c("gdp", "gva")`. A single named list may be
#'   passed instead, which is convenient programmatically (e.g. from the output
#'   of [ds_search()]). See [ds_meta()] for the available dimensions and codes.
#' @param from,to optional date bounds (a `Date` or an ISO `"YYYY-MM-DD"`
#'   string) that restrict the returned range, inclusive.
#' @param class class of the return value: `"data.frame"` (the default, one row
#'   per observation in long format) or `"ts"`. For `"ts"` the selected series
#'   are laid out as columns, one per cell. (To obtain an \pkg{xts} object,
#'   wrap the result: `xts::as.xts(ds(..., class = "ts"))`.)
#' @return A `data.frame` or `ts`/`mts` object, or `NULL` if the selection is
#'   empty.
#' @seealso [ds_catalog()] for the list of datasets and [ds_meta()] for a
#'   dataset's dimensions.
#' @examples
#' \dontrun{
#' # whole dataset (long data.frame)
#' ds("ch_fso_cpi")
#'
#' # one series, by dimension code
#' ds("ch_fso_cpi", item = "100_100")
#'
#' # several series, restricted to a date range
#' ds("ch_fso_cpi", item = c("100_100", "100_1"), from = "2020-01-01")
#'
#' # as a ts object
#' ds("ch_seco_gdp", type = "real", structure = "gdp", seas_adj = "csa",
#'    class = "ts")
#' }
#' @export
ds <- function(dataset, ..., from = NULL, to = NULL,
               class = c("data.frame", "ts")) {
  class <- match.arg(class)
  stopifnot(is.character(dataset), length(dataset) == 1L, nzchar(dataset))

  dims <- list(...)
  # Allow a single named list (e.g. built from ds_search()) in place of named
  # arguments: ds("x", list(item = "a")) behaves like ds("x", item = "a").
  if (length(dims) == 1L && is.null(names(dims)) && is.list(dims[[1]])) {
    dims <- dims[[1]]
  }

  df <- ds_fetch_series(dataset, dims, from = from, to = to)
  if (is.null(df) || nrow(df) == 0L) return(NULL)

  switch(class,
    data.frame = df,
    ts         = series_to_ts(df)
  )
}


# Build the dims grammar string ("item=100_100,100_1;type=real") from a named
# list of dimension filters. Errors if any filter is unnamed.
build_dims <- function(dims) {
  if (length(dims) == 0L) return("")
  nm <- names(dims)
  if (is.null(nm) || any(!nzchar(nm))) {
    stop("dimension filters must be named, e.g. ",
         "ds(\"ch_seco_gdp\", type = \"real\"). See ds_meta() for dimensions.",
         call. = FALSE)
  }
  parts <- vapply(seq_along(dims), function(i) {
    paste0(nm[i], "=", paste(dims[[i]], collapse = ","))
  }, character(1))
  paste(parts, collapse = ";")
}


# Fetch a selection as a long data.frame: dimension column(s), then `date`
# (Date) and `value` (numeric). Returns NULL for an empty selection.
ds_fetch_series <- function(dataset, dims = list(), from = NULL, to = NULL) {
  qs <- paste0("dataset=", utils::URLencode(dataset, reserved = TRUE))
  spec <- build_dims(dims)
  if (nzchar(spec)) {
    qs <- c(qs, paste0("dims=", utils::URLencode(spec, reserved = TRUE)))
  }
  if (!is.null(from)) qs <- c(qs, paste0("from=", as.character(from)))
  if (!is.null(to))   qs <- c(qs, paste0("to=", as.character(to)))

  df <- ds_get_csv(paste0("/series.csv?", paste(qs, collapse = "&")))

  # The API answers an unknown/empty dataset with a one-column "error" CSV.
  if ("error" %in% names(df) && !("value" %in% names(df))) {
    stop("dataseries.org API: ", df$error[1], " (dataset '", dataset, "').",
         call. = FALSE)
  }
  if (!all(c("date", "value") %in% names(df))) {
    stop("unexpected response for dataset '", dataset, "'.", call. = FALSE)
  }

  df$date  <- as.Date(df$date)
  df$value <- as.numeric(df$value)
  dimcols  <- setdiff(names(df), c("date", "value"))
  df <- df[, c(dimcols, "date", "value"), drop = FALSE]
  df <- df[order(df$date), , drop = FALSE]
  rownames(df) <- NULL
  df
}


# Reshape the long data.frame to one column per series (cell) and return it as a
# `ts`/`mts` object. Column names are the dimension codes joined by ".".
series_to_ts <- function(df) {
  dimcols <- setdiff(names(df), c("date", "value"))

  key <- if (length(dimcols)) {
    do.call(paste, c(df[dimcols], sep = "."))
  } else {
    rep("value", nrow(df))
  }
  keys  <- unique(key)
  dates <- sort(unique(df$date))

  mat <- matrix(NA_real_, nrow = length(dates), ncol = length(keys),
                dimnames = list(NULL, keys))
  mat[cbind(match(df$date, dates), match(key, keys))] <- df$value

  matrix_to_ts(mat, dates)
}


# Guess a ts frequency from the spacing of (sorted, unique) dates. Returns 1
# (annual), 4 (quarterly) or 12 (monthly), or NA for finer/irregular spacing.
guess_frequency <- function(dates) {
  if (length(dates) < 2L) return(NA_real_)
  step <- stats::median(as.numeric(diff(sort(unique(dates)))))
  if (step >= 350) 1 else if (step >= 80) 4 else if (step >= 25) 12 else NA_real_
}


# Place a date-by-series value matrix onto a regular time grid and wrap it in a
# `ts` object. A regular grid (with NA for gaps) is required because `ts` assumes
# evenly spaced observations.
matrix_to_ts <- function(mat, dates) {
  freq <- guess_frequency(dates)
  if (is.na(freq)) {
    stop("cannot represent this series as a 'ts' object (daily or irregular ",
         "spacing). Use the default class = \"data.frame\" (e.g. build an xts ",
         "object with xts::xts(d$value, d$date)).", call. = FALSE)
  }
  by   <- switch(as.character(freq), "12" = "month", "4" = "3 months", "1" = "year")
  grid <- seq(min(dates), max(dates), by = by)

  out <- matrix(NA_real_, nrow = length(grid), ncol = ncol(mat),
                dimnames = list(NULL, colnames(mat)))
  out[match(dates, grid), ] <- mat

  y <- as.integer(format(grid[1], "%Y"))
  m <- as.integer(format(grid[1], "%m"))
  start <- switch(as.character(freq),
    "12" = c(y, m),
    "4"  = c(y, (m - 1L) %/% 3L + 1L),
    "1"  = y
  )

  if (ncol(out) == 1L) {
    stats::ts(out[, 1], start = start, frequency = freq)
  } else {
    stats::ts(out, start = start, frequency = freq)
  }
}
