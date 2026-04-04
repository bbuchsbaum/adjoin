# Cross Adjacency

This function computes the cross adjacency matrix or graph between two
sets of points based on their k-nearest neighbors and a kernel function
applied to their distances.

## Usage

``` r
cross_adjacency(
  X,
  Y,
  k = 5,
  FUN = heat_kernel,
  type = c("normal", "mutual", "asym"),
  as = c("igraph", "sparse", "index_sim"),
  backend = c("nanoflann", "hnsw"),
  M = 16,
  ef = 200
)
```

## Arguments

- X:

  A matrix of size nXk, where n is the number of data points and k is
  the dimensionality of the feature space.

- Y:

  A matrix of size pXk, where p is the number of query points and k is
  the dimensionality of the feature space.

- k:

  An integer indicating the number of nearest neighbors to consider
  (default: 5).

- FUN:

  A kernel function to apply to the Euclidean distances between data
  points (default: heat_kernel).

- type:

  A character string indicating the type of adjacency to compute. One of
  "normal", "mutual", or "asym" (default: "normal").

- as:

  A character string indicating the format of the output. One of
  "igraph", "sparse", or "index_sim" (default: "igraph").

- backend:

  Nearest-neighbor backend. \`"nanoflann"\` uses exact Euclidean search;
  \`"hnsw"\` uses approximate search via \`RcppHNSW\`.

- M, ef:

  HNSW tuning parameters used only when \`backend="hnsw"\`.

## Value

If 'as' is "index_sim", a two-column matrix where the first column
contains the indices of nearest neighbors and the second column contains
the corresponding kernel values. If 'as' is "igraph", an igraph object
representing the cross adjacency graph. If 'as' is "sparse", a sparse
adjacency matrix.

## Details

Distances passed to \`FUN\` are Euclidean distances. With
\`backend="hnsw"\`, squared L2 distances from \`RcppHNSW\` are converted
back to Euclidean distances before weighting.

## Examples

``` r
X <- matrix(rnorm(6), ncol=2)
Y <- matrix(rnorm(8), ncol=2)
cross_adjacency(X, Y, k=1, as="sparse")
#> 4 x 3 sparse Matrix of class "dgCMatrix"
#>                            
#> [1,] .         . 0.20617346
#> [2,] .         . 0.01038239
#> [3,] 0.1349088 . .         
#> [4,] .         . 0.77465201
```
