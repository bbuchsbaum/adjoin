# Get Indices of Non-neighbors of a Node

Retrieve the indices of nodes that are not neighbors of a specified
node.

## Usage

``` r
non_neighbors(x, ...)
```

## Arguments

- x:

  A neighbor graph object.

- ...:

  Additional arguments passed to specific methods.

## Value

A numeric vector of node indices that are not neighbors of the given
node.

## Examples

``` r
adj_matrix <- matrix(c(0,1,0,
                       1,0,0,
                       0,0,0), nrow=3, byrow=TRUE)
ng <- neighbor_graph(adj_matrix)
non_neighbors(ng, 1)
#> [1] 3
```
