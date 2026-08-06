# Pre-compute the vignette.
#
# The vignette talks to the dataseries.org API, and CRAN builds vignettes on
# machines that should not depend on network access. So the chunks are run
# here, once, and `dataseries.Rmd` is committed with the output baked in.
#
# Re-run after changing `dataseries.Rmd.orig` (from the package root):
#
#   Rscript vignettes/precompute.R

local({
  old <- setwd("vignettes")
  on.exit(setwd(old))
  knitr::knit("dataseries.Rmd.orig", output = "dataseries.Rmd")
})
