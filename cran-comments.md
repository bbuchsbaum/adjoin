# CRAN submission comments — adjoin 0.1.0

## Resubmission

This is a resubmission. In response to CRAN feedback:

* Removed the redundant phrase "A collection of functions for" from the
  beginning of the `Description` field.
* Added method references to the `Description` field using CRAN's requested
  auto-linking format: `authors (year) <doi:...>`.
* Updated the plotting code in `vignettes/adjoin.Rmd` and
  `vignettes/spatial-neighbors.Rmd` so every change to graphical parameters is
  wrapped with `oldpar <- par(no.readonly = TRUE)` and restored using a
  top-level-safe pattern (`tryCatch(..., finally = par(oldpar))`), rather than
  `on.exit()`. The generated `inst/doc/adjoin.R` and
  `inst/doc/spatial-neighbors.R` files in the source package were rebuilt and
  now reset graphical parameters after each plotting block.

## Test environments

* macOS Sonoma 14.3 (aarch64), R 4.5.1 (local)
* GitHub Actions: ubuntu-latest / R release

## R CMD check results

Local `R CMD check --as-cran` result:

0 errors | 1 warning | 3 notes

The first NOTE is:

> Maintainer: 'Bradley R. Buchsbaum <brad.buchsbaum@gmail.com>'
> New submission

This is expected for a first CRAN submission.

The second NOTE is:

> unable to verify current time

This appears to be specific to the local check environment.

The third NOTE is:

> Skipping checking HTML validation: 'tidy' doesn't look like recent enough HTML Tidy.

This is caused by the local HTML Tidy installation and is not package-specific.

## Local compiler warning (not reproducible on CRAN)

On this machine, R uses Homebrew clang 20.1.8 rather than the system Apple
clang.  Homebrew clang 20 emits an "unknown warning group '-Wfixed-enum-extension'"
diagnostic when compiling R's own `Boolean.h` header.  This warning does not
appear when building with Apple clang (the compiler used on CRAN's macOS
builders) and is not caused by any code in this package.

## Downstream dependencies

None — this is a new package.
