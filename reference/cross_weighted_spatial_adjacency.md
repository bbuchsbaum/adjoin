# Cross-adjacency matrix with feature weighting

Cross-adjacency matrix with feature weighting

## Usage

``` r
cross_weighted_spatial_adjacency(
  coord_mat1,
  coord_mat2,
  feature_mat1,
  feature_mat2,
  wsigma = 0.73,
  alpha = 0.5,
  nnk = 27,
  maxk = nnk,
  weight_mode = c("binary", "heat"),
  sigma = 1,
  dthresh = sigma * 2.5,
  normalized = TRUE
)
```

## Arguments

- coord_mat1:

  the first coordinate matrix (the query)

- coord_mat2:

  the second coordinate matrix (the reference)

- feature_mat1:

  the first feature matrix

- feature_mat2:

  the second feature matrix

- wsigma:

  the sigma for the feature heat kernel

- alpha:

  the mixing weight for the spatial distance (1=all spatial weighting,
  0=all feature weighting)

- nnk:

  the maximum number of spatial nearest neighbors to include

- maxk:

  the maximum number of neighbors to include within spatial window

- weight_mode:

  the type of weighting to use: "binary" or "heat" (default: "binary")

- sigma:

  the spatial sigma for the heat kernel weighting (default: 1)

- dthresh:

  the threshold for the spatial distance

- normalized:

  whether to normalize the rows to sum to 1

## Value

A sparse cross-graph adjacency matrix of feature-weighted spatial
similarities.

## Examples

``` r
set.seed(123)
coords <- as.matrix(expand.grid(1:5, 1:5))
fmat1 <- matrix(rnorm(5*25), 25, 5)
fmat2 <- matrix(rnorm(5*25), 25, 5)

adj <- cross_weighted_spatial_adjacency(coords, coords, fmat1, fmat2)
```
