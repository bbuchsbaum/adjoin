# Spatial Laplacian of Gaussian for coordinates

This function computes the spatial Laplacian of Gaussian for a given
coordinate matrix using a specified sigma value.

## Usage

``` r
spatial_lap_of_gauss(coord_mat, sigma = 2)
```

## Arguments

- coord_mat:

  A numeric matrix representing coordinates

- sigma:

  Numeric, the sigma parameter for the Gaussian smoother (default is 2)

## Value

A sparse symmetric matrix representing the computed spatial Laplacian of
Gaussian

## Examples

``` r
coord_mat <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)

result <- spatial_lap_of_gauss(coord_mat, sigma = 2)
```
