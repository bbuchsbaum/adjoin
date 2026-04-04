# Compute the spatial Laplacian matrix of a coordinate matrix

This function computes the spatial Laplacian matrix of a given
coordinate matrix using specified parameters.

## Usage

``` r
spatial_laplacian(
  coord_mat,
  dthresh = 1.42,
  nnk = 27,
  weight_mode = c("binary", "heat"),
  sigma = dthresh/2,
  normalized = TRUE,
  stochastic = FALSE,
  handle_isolates = c("self_loop", "keep_zero", "drop")
)
```

## Arguments

- coord_mat:

  A numeric matrix representing coordinates

- dthresh:

  Numeric, the distance threshold for adjacency (default is 1.42)

- nnk:

  Integer, the number of nearest neighbors for adjacency (default is 27)

- weight_mode:

  Character, the mode for computing weights, either "binary" or "heat"
  (default is "binary")

- sigma:

  Numeric, the sigma parameter for the heat kernel (default is
  dthresh/2)

- normalized:

  Logical, whether the adjacency matrix should be normalized (default is
  TRUE)

- stochastic:

  Logical, whether the adjacency matrix should be stochastic (default is
  FALSE)

- handle_isolates:

  How to treat zero-degree nodes when normalizing: "self_loop"
  (default), "keep_zero", or "drop".

## Value

A sparse symmetric matrix representing the computed spatial Laplacian

## Examples

``` r
coord_mat <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)

result <- spatial_laplacian(coord_mat, dthresh = 1.42, nnk = 27, weight_mode = "binary")
```
