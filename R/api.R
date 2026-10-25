# Low-level access to the dataseries.org API plus a simple in-memory cache.
#
# Everything fetched from the API (catalog, metadata, series) is cached by URL
# for the lifetime of the R session, so repeated calls are free. Use cache_rm()
# to force a fresh download.

env.cache <- new.env(parent = emptyenv())

cache_get <- function(key) {
  if (exists(key, envir = env.cache, inherits = FALSE)) {
    get(key, envir = env.cache, inherits = FALSE)
  } else {
    NULL
  }
}

cache_set <- function(key, value) {
  assign(key, value, envir = env.cache)
  invisible(value)
}

# A failed request. `reason` is the underlying R error message. Callers that
# know more (see ds_diagnose()) can turn it into a more specific message.
ds_request_error <- function(url, reason) {
  structure(
    class = c("ds_request_error", "error", "condition"),
    list(
      message = paste0("could not reach the dataseries.org API (", url, "): ",
                       reason),
      call = NULL, url = url, reason = reason
    )
  )
}

# Run `expr`; on failure signal a ds_request_error. The download failure itself
# (e.g. "HTTP status was '404 Not Found'") arrives as a warning ahead of the
# error, so keep it as the reason instead of letting it print.
ds_try_request <- function(expr, url) {
  warned <- NULL
  tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warned <<- c(warned, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      reason <- if (length(warned)) warned[length(warned)] else conditionMessage(e)
      stop(ds_request_error(url, reason))
    }
  )
}

# GET a path and parse the JSON body. `simplify = FALSE` keeps the nested list
# structure (used for metadata); `TRUE` lets jsonlite simplify where it can.
ds_get_json <- function(path, simplify = FALSE, cache = TRUE) {
  url <- paste0(ds_api_url(), path)
  key <- paste0("json:", url)
  if (cache) {
    hit <- cache_get(key)
    if (!is.null(hit)) return(hit)
  }
  out <- ds_try_request(jsonlite::fromJSON(url, simplifyVector = simplify), url)
  if (cache) cache_set(key, out)
  out
}

# Parse series CSV (a URL, or the CSV itself via `text`). Every column is read
# as character with no NA conversion, so dimension codes survive verbatim
# ("NA", "01", "100_100"); an empty `value` field stays "" and becomes NA when
# the caller converts it. Column names are kept exactly as sent (check.names =
# FALSE), because they are the API's dimension names.
read_series_csv <- function(file, text = NULL) {
  args <- list(stringsAsFactors = FALSE, colClasses = "character",
               na.strings = character(), check.names = FALSE,
               encoding = "UTF-8")
  if (is.null(text)) {
    do.call(utils::read.csv, c(list(file), args))
  } else {
    do.call(utils::read.csv, c(list(text = text), args))
  }
}

# GET a /series.csv path and read it as a data.frame (see read_series_csv());
# `date` and `value` are converted by the caller.
ds_get_csv <- function(path, cache = TRUE) {
  url <- paste0(ds_api_url(), path)
  key <- paste0("csv:", url)
  if (cache) {
    hit <- cache_get(key)
    if (!is.null(hit)) return(hit)
  }
  out <- ds_try_request(read_series_csv(url), url)
  if (cache) cache_set(key, out)
  out
}

#' List or clear the in-memory cache
#'
#' Everything downloaded from [dataseries.org](https://dataseries.org) is cached
#' in memory for the lifetime of the R session. `cache_ls()` lists the cached
#' objects (keyed by request URL); `cache_rm()` empties the cache, which forces
#' the next call to download fresh data.
#'
#' @return `cache_ls()` returns a character vector of cache keys; `cache_rm()`
#'   is called for its side effect and returns `NULL` invisibly.
#' @examples
#' \dontrun{
#' ds_catalog()
#' cache_ls()
#' cache_rm()
#' }
#' @export
cache_ls <- function() {
  ls(envir = env.cache)
}

#' @rdname cache_ls
#' @export
cache_rm <- function() {
  rm(list = cache_ls(), envir = env.cache)
  invisible(NULL)
}
