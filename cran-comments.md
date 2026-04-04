# CRAN submission comments — adjoin 0.1.0

## Test environments

* macOS Sonoma 14.3 (aarch64), R 4.5.1 (local)
* GitHub Actions: ubuntu-latest / R release

## R CMD check results

0 errors | 0 warnings | 1 note

The single NOTE is:

> Maintainer: 'Bradley R. Buchsbaum <brad.buchsbaum@gmail.com>'
> New submission

This is expected for a first CRAN submission.

## Local compiler note (not reproducible on CRAN)

On this machine, R uses Homebrew clang 20.1.8 rather than the system Apple
clang.  Homebrew clang 20 emits an "unknown warning group '-Wfixed-enum-extension'"
diagnostic when compiling R's own `Boolean.h` header.  This warning does not
appear when building with Apple clang (the compiler used on CRAN's macOS
builders) and is not caused by any code in this package.

## Downstream dependencies

None — this is a new package.
