
<!-- README.md is generated from README.Rmd. Please edit that file -->

# neighborweights

## Overview

The `neighborweights` package provides a collection of functions for
constructing adjacency matrices based on spatial and feature-based
similarity between data points. It enables users to analyze and
visualize complex data relationships by creating spatial and
feature-weighted adjacency matrices using various methods.

## Installation

You can install the `neighborweights` package from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("bbuchsbaum/neighborweights")
```

## Usage

Here’s a basic example demonstrating how to create a spatial adjacency
matrix using the spatial_adjacency function:

``` r
library(neighborweights)

# Generate random coordinates
coord_mat <- matrix(runif(20), nrow=10, ncol=2)

# Calculate the spatial adjacency matrix
spatial_mat <- spatial_adjacency(coord_mat, nnk=5, sigma=1)

# Inspect the resulting matrix
print(spatial_mat)
#> 10 x 10 sparse Matrix of class "dgCMatrix"
#>                                              
#>  [1,] 0.2 0.1 .   .   0.2 .   0.2 0.2 .   0.2
#>  [2,] 0.1 0.2 .   .   0.2 0.2 .   .   0.2 .  
#>  [3,] .   .   0.2 0.2 .   0.1 .   .   0.1 0.1
#>  [4,] .   .   0.2 0.2 .   0.2 .   .   0.2 0.1
#>  [5,] 0.2 0.2 .   .   0.2 .   0.1 0.1 .   .  
#>  [6,] .   0.2 0.1 0.2 .   0.2 .   .   0.2 0.1
#>  [7,] 0.2 .   .   .   0.1 .   0.2 0.2 0.1 0.2
#>  [8,] 0.2 .   .   .   0.1 .   0.2 0.2 0.1 0.2
#>  [9,] .   0.2 0.1 0.2 .   0.2 0.1 0.1 0.2 0.2
#> [10,] 0.2 .   0.1 0.1 .   0.1 0.2 0.2 0.2 0.2
```

For more advanced usage and additional examples, please refer to the
package documentation and vignettes (coming soon).

<!-- albersdown:theme-note:start -->
## Albers theme
This package uses the albersdown theme. Existing vignette theme hooks are replaced so `albers.css` and local `albers.js` render consistently on CRAN and GitHub Pages. The defaults are configured via `params$family` and `params$preset` (family = 'teal', preset = 'homage'). The pkgdown site uses `template: { package: albersdown }` together with generated `pkgdown/extra.css` and `pkgdown/extra.js` so the theme is linked and activated on site pages.
<!-- albersdown:theme-note:end -->
