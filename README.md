<!-- README.md is generated from README.Rmd. Please edit that file -->

# adjoin

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/adjoin)](https://cran.r-project.org/package=adjoin)
[![R-CMD-check](https://github.com/bbuchsbaum/adjoin/actions/workflows/check-standard.yaml/badge.svg)](https://github.com/bbuchsbaum/adjoin/actions/workflows/check-standard.yaml)
[![pkgdown](https://github.com/bbuchsbaum/adjoin/actions/workflows/pkgdown.yaml/badge.svg)](https://bbuchsbaum.github.io/adjoin/)
[![Codecov test
coverage](https://codecov.io/gh/bbuchsbaum/adjoin/branch/main/graph/badge.svg)](https://app.codecov.io/gh/bbuchsbaum/adjoin)
<!-- badges: end -->

**adjoin** constructs sparse adjacency matrices from spatial coordinates,
feature measurements, class labels, and temporal indices.

[Documentation](https://bbuchsbaum.github.io/adjoin/) · [Getting
started](https://bbuchsbaum.github.io/adjoin/articles/adjoin.html) ·
[Spatial
neighbors](https://bbuchsbaum.github.io/adjoin/articles/spatial-neighbors.html) ·
[API reference](https://bbuchsbaum.github.io/adjoin/reference/) ·
[Changelog](NEWS.md)

## Installation

Install the released version from CRAN:

``` r
install.packages("adjoin")
```

Or the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("bbuchsbaum/adjoin")
```

## Quick start

Build a spatial adjacency matrix from coordinates with
`spatial_adjacency()`:

``` r
library(adjoin)

set.seed(1)
coord_mat <- matrix(runif(20), nrow = 10, ncol = 2)
spatial_mat <- spatial_adjacency(coord_mat, nnk = 5, sigma = 1)
spatial_mat
#> 10 x 10 sparse Matrix of class "dgCMatrix"
#>                                              
#>  [1,] 0.2 0.2 0.1 .   0.2 .   .   .   0.1 0.1
#>  [2,] 0.2 0.2 0.1 0.1 .   .   .   .   0.2 .  
#>  [3,] 0.1 0.1 0.2 0.1 0.1 0.2 0.2 0.2 0.2 0.1
#>  [4,] .   0.1 0.1 0.2 .   0.2 0.2 .   0.2 .  
#>  [5,] 0.2 .   0.1 .   0.2 .   .   0.2 .   0.2
#>  [6,] .   .   0.2 0.2 .   0.2 0.2 0.1 0.2 .  
#>  [7,] .   .   0.2 0.2 .   0.2 0.2 0.2 .   .  
#>  [8,] .   .   0.2 .   0.2 0.1 0.2 0.2 .   0.1
#>  [9,] 0.1 0.2 0.2 0.2 .   0.2 .   .   0.2 .  
#> [10,] 0.1 .   0.1 .   0.2 .   .   0.1 .   0.2
```

Related entry points include `weighted_knn()` / `graph_weights()` for
feature-space neighbor graphs, `weighted_spatial_adjacency()` for
space–feature blends, and `class_graph()` for label-aware neighbor
structure. See the vignettes linked above for worked examples.

<!-- albersdown:theme-note:start -->
## Albers theme
This package uses the albersdown theme. Existing vignette theme hooks are replaced so `albers.css` and local `albers.js` render consistently on CRAN and GitHub Pages. The defaults are configured via `params$family` and `params$preset` (family = 'teal', preset = 'homage'). The pkgdown site uses `template: { package: albersdown }` together with generated `pkgdown/extra.css` and `pkgdown/extra.js` so the theme is linked and activated on site pages.
<!-- albersdown:theme-note:end -->
