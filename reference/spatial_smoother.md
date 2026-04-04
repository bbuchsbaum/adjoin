# Compute the spatial smoother matrix for a coordinate matrix

This function computes the spatial smoother matrix for a given
coordinate matrix using specified parameters.

## Usage

``` r
spatial_smoother(
  coord_mat,
  sigma = 5,
  nnk = 3^(ncol(coord_mat)),
  stochastic = TRUE,
  handle_isolates = c("self_loop", "keep_zero", "drop")
)
```

## Arguments

- coord_mat:

  A numeric matrix representing coordinates

- sigma:

  Numeric, the sigma parameter for the Gaussian smoother (default is 5)

- nnk:

  Integer, the number of nearest neighbors for adjacency (default is
  3^(ncol(coord_mat)))

- stochastic:

  Logical, whether the adjacency matrix should be doubly stochastic
  (default is TRUE)

- handle_isolates:

  How to treat zero-degree nodes when normalizing: "self_loop" adds a
  self-loop (default), "keep_zero" leaves them as zero, or "drop"
  removes them from the matrix.

## Value

A sparse matrix representing the computed spatial smoother. If
stochastic=TRUE, the matrix is row-stochastic (rows sum to 1) but not
symmetric. If stochastic=FALSE, the matrix is symmetric but not
row-stochastic.

## Examples

``` r
coord_mat <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)

result <- spatial_smoother(coord_mat, sigma = 5, nnk = 3^(ncol(coord_mat)), stochastic = TRUE)
```
