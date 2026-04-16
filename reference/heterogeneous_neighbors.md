# Heterogeneous Neighbors for class_graph Objects

Compute the neighbors between different classes for a class_graph
object.

## Usage

``` r
heterogeneous_neighbors(x, X, k, weight_mode = "heat", sigma = 1, ...)
```

## Arguments

- x:

  A class_graph object.

- X:

  The data matrix corresponding to the graph nodes.

- k:

  The number of nearest neighbors to find.

- weight_mode:

  Method for weighting edges (e.g., "heat", "binary", "euclidean").

- sigma:

  Scaling factor for heat kernel if \`weight_mode="heat"\`.

- ...:

  Additional arguments passed to weight function.

## Value

A neighbor_graph object representing the between-class neighbors.

## Examples

``` r
labs <- factor(c("a","a","b","b"))
cg <- class_graph(labs)
X <- matrix(rnorm(8), ncol=2)
heterogeneous_neighbors(cg, X, k=1)
#> $G
#> IGRAPH ce9d7cd U-W- 4 3 -- 
#> + attr: weight (e/n)
#> + edges from ce9d7cd:
#> [1] 1--4 2--3 2--4
#> 
#> $params
#> $params$weight_mode
#> [1] "heat"
#> 
#> $params$neighbor_mode
#> [1] "heterogeneous"
#> 
#> $params$k
#> [1] 1
#> 
#> $params$sigma
#> [1] 1
#> 
#> 
#> attr(,"class")
#> [1] "neighbor_graph"
```
