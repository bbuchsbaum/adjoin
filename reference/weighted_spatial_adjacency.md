# Weighted Spatial Adjacency

Constructs a spatial adjacency matrix, where weights are determined by a
secondary feature matrix.

## Usage

``` r
weighted_spatial_adjacency(
  coord_mat,
  feature_mat,
  wsigma = 0.73,
  alpha = 0.5,
  nnk = 27,
  weight_mode = c("binary", "heat"),
  sigma = 1,
  dthresh = sigma * 2.5,
  include_diagonal = TRUE,
  normalized = FALSE,
  stochastic = FALSE
)
```

## Arguments

- coord_mat:

  A matrix with the spatial coordinates of the data points, where each
  row represents a point and each column represents a coordinate
  dimension.

- feature_mat:

  A matrix with the feature vectors of the data points, where each row
  represents a point and each column represents a feature dimension. The
  number of rows in feature_mat must be equal to the number of rows in
  coord_mat.

- wsigma:

  The spatial weight scale (default: 0.73).

- alpha:

  The mixing parameter between 0 and 1 (default: 0.5). A value of 0
  results in a purely spatial adjacency matrix, while a value of 1
  results in a purely feature-based adjacency matrix.

- nnk:

  The number of nearest neighbors to consider (default: 27).

- weight_mode:

  The mode to use for weighting the adjacency matrix, either "binary" or
  "heat" (default: "binary").

- sigma:

  The bandwidth for heat kernel weights (default: 1).

- dthresh:

  The distance threshold for nearest neighbors (default: sigma \* 2.5).

- include_diagonal:

  A logical value indicating whether to include diagonal elements in the
  adjacency matrix (default: TRUE).

- normalized:

  A logical value indicating whether to normalize the adjacency matrix
  (default: FALSE).

- stochastic:

  A logical value indicating whether to make the resulting adjacency
  matrix doubly stochastic (default: FALSE).

## Value

A sparse adjacency matrix with weighted spatial relationships.

## Examples

``` r
# \donttest{
set.seed(123)
coord_mat <- as.matrix(expand.grid(x=1:9, y=1:9, z=1:9))
fmat <- matrix(rnorm(nrow(coord_mat) * 100), nrow(coord_mat), 100)
wsa1 <- weighted_spatial_adjacency(coord_mat, fmat, nnk=3, 
                                  weight_mode="binary", alpha=1, 
                                  stochastic=TRUE)
wsa2 <- weighted_spatial_adjacency(coord_mat, fmat, nnk=27, 
                                  weight_mode="heat", alpha=0, 
                                  stochastic=TRUE, sigma=2.5)
# }
```
