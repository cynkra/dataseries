# Offline tests for the CSV parser (no network).

test_that("dimension codes are read verbatim, including \"NA\"", {
  csv <- paste(
    "D0,D1,date,value",
    "NA,A,2020-01-01,1.5",
    "NP,01,2020-01-01,2",
    "S,100_100,2020-01-01,3",
    sep = "\n"
  )
  x <- read_series_csv(text = csv)
  expect_type(x$D0, "character")
  expect_equal(x$D0, c("NA", "NP", "S"))
  expect_equal(x$D1, c("A", "01", "100_100"))
})

test_that("only an empty value is missing", {
  csv <- paste("D0,date,value", "NA,2020-01-01,", "NA,2021-01-01,4", sep = "\n")
  x <- read_series_csv(text = csv)
  expect_equal(x$D0, c("NA", "NA"))
  expect_equal(as.numeric(x$value), c(NA, 4))
})

test_that("column names equal the API's dimension names", {
  csv <- paste(
    "Wirtschaftsabteilung,Offene Stellen,1st-dim,date,value",
    "A,1,x,2020-01-01,3",
    sep = "\n"
  )
  x <- read_series_csv(text = csv)
  expect_equal(names(x),
               c("Wirtschaftsabteilung", "Offene Stellen", "1st-dim",
                 "date", "value"))
})

test_that("dimension names with spaces are passed to the API unmangled", {
  expect_equal(build_dims(list(`Offene Stellen` = "1")), "Offene Stellen=1")
})
