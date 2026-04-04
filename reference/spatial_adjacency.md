# Compute the spatial adjacency matrix for a coordinate matrix

This function computes the spatial adjacency matrix for a given
coordinate matrix using specified parameters. Adjacency is determined by
distance threshold and the maximum number of neighbors.

## Usage

``` r
spatial_adjacency(
  coord_mat,
  dthresh = sigma * 3,
  nnk = 27,
  weight_mode = c("binary", "heat"),
  sigma = 5,
  include_diagonal = TRUE,
  normalized = TRUE,
  stochastic = FALSE,
  handle_isolates = c("self_loop", "keep_zero", "drop")
)
```

## Arguments

- coord_mat:

  A numeric matrix representing the spatial coordinates

- dthresh:

  Numeric, the distance threshold defining the radius of the
  neighborhood (default is sigma\*3)

- nnk:

  Integer, the maximum number of neighbors to include in each spatial
  neighborhood (default is 27)

- weight_mode:

  Character, the mode for computing weights, either "binary" or "heat"
  (default is "binary")

- sigma:

  Numeric, the bandwidth of the heat kernel if weight_mode == "heat"
  (default is 5)

- include_diagonal:

  Logical, whether to assign 1 to diagonal elements (default is TRUE)

- normalized:

  Logical, whether to make row elements sum to 1 (default is TRUE)

- stochastic:

  Logical, whether to make column elements also sum to 1 (only relevant
  if normalized == TRUE) (default is FALSE)

- handle_isolates:

  How to treat zero-degree nodes when normalizing: "self_loop" adds a
  self-loop (default), "keep_zero" leaves them as zero, or "drop"
  removes them from the matrix.

## Value

A sparse symmetric matrix representing the computed spatial adjacency

## Examples

``` r
coord_mat = as.matrix(expand.grid(x=1:6, y=1:6))
sa <- spatial_adjacency(coord_mat)
```
