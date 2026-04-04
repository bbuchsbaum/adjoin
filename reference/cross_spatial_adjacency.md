# Cross Spatial Adjacency

Constructs a cross spatial adjacency matrix between two sets of points,
where weights are determined by spatial relationships.

## Usage

``` r
cross_spatial_adjacency(
  coord_mat1,
  coord_mat2,
  dthresh = sigma * 3,
  nnk = 27,
  weight_mode = c("binary", "heat"),
  sigma = 5,
  normalized = TRUE
)
```

## Arguments

- coord_mat1:

  A matrix with the spatial coordinates of the first set of data points,
  where each row represents a point and each column represents a
  coordinate dimension.

- coord_mat2:

  A matrix with the spatial coordinates of the second set of data
  points, where each row represents a point and each column represents a
  coordinate dimension.

- dthresh:

  The distance threshold for nearest neighbors (default: sigma \* 3).

- nnk:

  The number of nearest neighbors to consider (default: 27).

- weight_mode:

  The mode to use for weighting the adjacency matrix, either "binary" or
  "heat" (default: "binary").

- sigma:

  The bandwidth for heat kernel weights (default: 5).

- normalized:

  A logical value indicating whether to normalize the adjacency matrix
  (default: TRUE).

## Value

A sparse cross adjacency matrix with weighted spatial relationships
between the two sets of points.

## Examples

``` r
# \donttest{
coord_mat1 <- as.matrix(expand.grid(x=1:5, y=1:5, z=1:5))
coord_mat2 <- as.matrix(expand.grid(x=6:10, y=6:10, z=6:10))
csa <- cross_spatial_adjacency(coord_mat1, coord_mat2, nnk=3, 
                               weight_mode="binary", sigma=5, 
                               normalized=TRUE)
# }
```
