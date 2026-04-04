# Create Neighbor Graph from nnsearcher Object

Construct a neighbor graph from nearest neighbor search results.

## Usage

``` r
# S3 method for class 'nnsearcher'
neighbor_graph(
  x,
  query = NULL,
  k = 5,
  type = c("normal", "asym", "mutual"),
  transform = c("heat", "binary", "euclidean", "normalized", "cosine", "correlation"),
  sigma = 1,
  ...
)
```

## Arguments

- x:

  An object of class "nnsearcher".

- query:

  A matrix of query points. If NULL, uses original data.

- k:

  The number of nearest neighbors to find.

- type:

  The type of graph construction method.

- transform:

  The transformation method for converting distances to weights.

- sigma:

  The bandwidth parameter for the transformation.

- ...:

  Additional arguments (currently unused).

## Value

A neighbor_graph object representing the constructed graph.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(20), nrow=5)
searcher <- nnsearcher(X)
neighbor_graph(searcher, k=2, type="normal", transform="heat", sigma=1)
#> $G
#> IGRAPH e529095 U-W- 5 7 -- 
#> + attr: weight (e/n)
#> + edges from e529095:
#> [1] 1--2 1--5 2--3 2--4 2--5 3--5 4--5
#> 
#> $params
#> $params$k
#> [1] 2
#> 
#> $params$transform
#> [1] "heat"
#> 
#> $params$sigma
#> [1] 1
#> 
#> $params$type
#> [1] "normal"
#> 
#> $params$labels
#> [1] 1 2 3 4 5
#> 
#> 
#> attr(,"class")
#> [1] "neighbor_graph"
# }
```
