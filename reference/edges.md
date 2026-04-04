# Edges for Graph-Like Objects

Retrieve the edges of a graph-like object.

## Usage

``` r
edges(x, ...)
```

## Arguments

- x:

  A graph-like object.

- ...:

  Further arguments passed to or from other methods.

## Value

A matrix containing the edges of the graph-like object.

## Examples

``` r
adj_matrix <- matrix(c(0,1,0,
                       1,0,1,
                       0,1,0), nrow=3, byrow=TRUE)
ng <- neighbor_graph(adj_matrix)
edges(ng)
#>      [,1] [,2]
#> [1,] "1"  "2" 
#> [2,] "2"  "3" 
```
