# Compute the Difference of Gaussians for a coordinate matrix

This function computes the Difference of Gaussians for a given
coordinate matrix using specified sigma values and the number of nearest
neighbors.

## Usage

``` r
difference_of_gauss(
  coord_mat,
  sigma1 = 2,
  sigma2 = sigma1 * 1.6,
  nnk = min(nrow(coord_mat), max(27, ncol(coord_mat)^2))
)
```

## Arguments

- coord_mat:

  A numeric matrix representing coordinates

- sigma1:

  Numeric, the first sigma parameter for the Gaussian smoother (default
  is 2)

- sigma2:

  Numeric, the second sigma parameter for the Gaussian smoother (default
  is sigma1 \* 1.6)

- nnk:

  Integer, the number of nearest neighbors for adjacency (default is
  3^(ncol(coord_mat)))

## Value

A sparse symmetric matrix representing the computed Difference of
Gaussians

## Examples

``` r
coord_mat <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)

result <- difference_of_gauss(coord_mat, sigma1 = 2, sigma2 = 3.2)
```
