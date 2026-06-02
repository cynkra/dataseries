#' dataseries: Switzerland's Data Series in One Place
#'
#' Download and import open Swiss economic time series from
#' [dataseries.org](https://dataseries.org).
#'
#' The data are organized as **datasets**, each of which is a family of related
#' series. Most datasets are multi-dimensional *cubes*: a single time series is
#' one cell, addressed by the dataset plus one code per dimension (e.g. the GDP
#' cube splits along `type`, `structure` and `seas_adj`). A handful of datasets
#' are a single series and need no dimensions at all.
#'
#' - [ds_catalog()] lists every available dataset.
#' - [ds_search()] is a flat, searchable list of the individual series.
#' - [ds_meta()] describes one dataset's dimensions and their codes.
#' - [ds()] downloads series, as a `data.frame` or `ts` object.
#'
#' @keywords internal
"_PACKAGE"
