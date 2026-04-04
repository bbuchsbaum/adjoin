# Compute a pairwise adjacency matrix for multiple graphs

This function computes a pairwise adjacency matrix for multiple graphs
with a given set of spatial coordinates and feature vectors. The
function takes two user-defined functions to compute within-graph and
between-graph similarity measures.

## Usage

``` r
pairwise_adjacency(Xcoords, Xfeats, fself, fbetween)
```

## Arguments

- Xcoords:

  A list of numeric matrices or data.frames containing the spatial
  coordinates of the nodes of each graph.

- Xfeats:

  A list of numeric matrices or data.frames containing the feature
  vectors for the nodes of each graph.

- fself:

  A function that computes similarity for nodes within the same graph
  (e.g., Xi_1, Xi_2).

- fbetween:

  A function that computes similarity for nodes across graphs (e.g.,
  Xi_1, Xj_1).

## Value

A sparse matrix representing the pairwise adjacency matrix for the input
graphs.

## Examples

``` r
coords <- list(matrix(c(0,0,1,0), ncol=2, byrow=TRUE),
               matrix(c(0,1,1,1), ncol=2, byrow=TRUE))
feats  <- list(matrix(rnorm(2), ncol=1),
               matrix(rnorm(2), ncol=1))
fself <- function(c,f) spatial_adjacency(c, normalized=FALSE, include_diagonal=FALSE)
fbetween <- function(c1,c2,f1,f2) cross_spatial_adjacency(c1,c2, normalized=FALSE)
M <- pairwise_adjacency(coords, feats, fself, fbetween)
dim(M)
#> [1] 4 4
```
