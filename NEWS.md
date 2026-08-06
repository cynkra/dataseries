# dataseries 1.1.0

## New features

- New vignette, `vignette("dataseries")`, introducing dataseries.org and
  walking through the package.

- `ds_catalog()` and `ds_search()` gain a `lang` argument (`"en"`, `"de"`,
  `"fr"` or `"it"`). dataseries.org publishes its labels in all four
  languages and the package used to discard everything but English. Searching
  also matches in the chosen language, so `ds_search("arbeitslosen", lang =
  "de")` works. Missing translations fall back to English.

## Bug fixes

- The `concept` and `topic` columns of `ds_catalog()` were `NA` for every
  dataset. Both are objects in the API and were being read as if they were
  plain strings. `concept` now holds the (translated) concept and `topic` the
  stable topic key.

- The `path` column of `ds_search()` repeated each element once per language,
  e.g. `"Total / Total / Total / Totale"`. It now holds the path in the
  chosen language.

## Other

- Relicensed from GPL-3 to MIT.

- The README no longer points to GitHub for the current version; 1.0.0 and
  later are on CRAN.

- Added a pointer to the Python package, which mirrors this interface.

# dataseries 1.0.0

This is a ground-up rewrite. dataseries.org now serves its data through a public
API (`api.dataseries.org`), and the package has been rebuilt around it.
The old flat series identifiers (e.g. `"CCI.AIK"`) no longer exist, so this
release is **not backward compatible**.

## New data model

- Data is now organized into **datasets**, most of which are multi-dimensional
  cubes. A single series is one cell, addressed by a dataset plus one code per
  dimension.

## New and changed functions

- `ds(dataset, ..., from, to, class)` is the new download function. The first
  argument is a dataset id; dimension filters are passed as named arguments
  (e.g. `ds("ch_seco_gdp", type = "real", structure = "gdp")`). The default
  `data.frame` is returned in long (tidy) format; `class = "ts"` lays the
  selected series out as columns. The `xts` option (and the `xts` dependency)
  has been dropped, as all series are regular-frequency and covered by `ts`.
- `ds_catalog()` lists all datasets (replaces `inventory()`).
- `ds_search(pattern)` is a flat, searchable list of the individual series
  across all datasets — the finest-grained way to discover what exists.
- `ds_meta(dataset)` returns a dataset's dimensions and codes, for discovery.
- `inventory()` is **deprecated**; it now warns and calls `ds_catalog()`.
- `cache_ls()` / `cache_rm()` continue to manage the in-memory cache.

# dataseries 0.2.0

- supports `class = "ts"`.
- new function `inventory()`, returns a data.frame with all series on
  www.dataseries.org.

# dataseries 0.1.0

- initial release.
