## Submission

This is a major update (0.2.0 -> 1.0.0) of an existing CRAN package.

dataseries.org now serves its data through a public API, and the package has
been rebuilt around it. This is a ground-up rewrite and is **not backward
compatible**: the old flat series identifiers (e.g. `"CCI.AIK"`) no longer
exist. The changes are described in `NEWS.md`.

## Test environments

- local: Ubuntu 24.04, R 4.5.2
- win-builder (devel and release)
- macOS-builder

## R CMD check results

0 errors | 0 warnings | 0 notes

## Internet resources

The package accesses the public dataseries.org API. All examples that download
data are wrapped in `\dontrun{}`, and the tests guard network access with
`skip_on_cran()` and `skip_if_offline()`, so the check does not depend on the
remote resource being reachable.

## Reverse dependencies

There are no reverse dependencies.
