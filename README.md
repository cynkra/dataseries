# dataseries: Switzerland's Data Series in One Place

<!-- badges: start -->
[![R-CMD-check](https://github.com/cynkra/dataseries/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cynkra/dataseries/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/cynkra/dataseries/branch/main/graph/badge.svg)](https://app.codecov.io/gh/cynkra/dataseries/branch/main)
[![CRAN status](https://www.r-pkg.org/badges/version/dataseries)](https://CRAN.R-project.org/package=dataseries)
<!-- badges: end -->

Download and import open Swiss economic time series from
[dataseries.org](https://dataseries.org), a comprehensive and up-to-date
collection of public data from Switzerland. The package talks to the public
[dataseries.org API](https://dataseries.org) and imports series as a
`data.frame` or `ts` object.

## Installation

The current version, which talks to the new dataseries.org API, lives on GitHub:

```r
# install.packages("remotes")
remotes::install_github("cynkra/dataseries")
```

(The version on CRAN is the older 0.2.0 release and predates the API.)

## Data model

Data on dataseries.org is organized into **datasets**. A dataset is a family of
related series and, in most cases, a multi-dimensional *cube* — a single time
series is one cell of that cube, addressed by the dataset plus one code per
dimension. For example the GDP dataset (`ch_seco_gdp`) splits along three
dimensions: `type` (nominal/real/…), `structure` (GDP, value added, …) and
`seas_adj` (seasonally adjusted or not).

- `ds_catalog()` lists every dataset.
- `ds_search(pattern)` is a flat, searchable list of the individual series.
- `ds_meta(id)` describes a dataset's dimensions and the codes within them.
- `ds(id, ...)` downloads series.

## Usage

```r
library(dataseries)

# Browse what's available
ds_catalog()

# Find a specific series across all datasets
ds_search("unemployment")

# A dataset's dimensions and codes
ds_meta("ch_seco_gdp")

# Whole dataset (long data.frame)
ds("ch_fso_cpi")

# One series: pass dimension codes as named arguments
ds("ch_fso_cpi", item = "100_100")

# Several series, restricted to a date range
ds("ch_fso_cpi", item = c("100_100", "100_1"), from = "2020-01-01")

# One cell of a multi-dimensional cube, as a ts object
ds("ch_seco_gdp", type = "real", structure = "gdp", seas_adj = "csa",
   class = "ts")
```

All series on dataseries.org are regular (annual, quarterly or monthly), so
`ts` covers them. If you prefer `xts`, convert the `ts` in one line:
`xts::as.xts(ds("ch_fso_cpi", item = "100_100", class = "ts"))`.

Dimension arguments are optional: omit them and you get the whole dataset.
Filtering happens on the server, so selecting one series does not download the
whole cube. Downloads are cached in memory for the session; `cache_rm()` forces
a fresh download.

## Beyond R

Every series is also available as a plain CSV from any tool that can read a URL:

```
https://api.dataseries.org/series.csv?dataset=ch_fso_cpi&dims=item=100_100
```
