# Node Density

Compute the local density around each node in a graph.

## Usage

``` r
node_density(x, ...)
```

## Arguments

- x:

  A graph-like object.

- ...:

  Additional arguments passed to specific methods.

## Value

A numeric vector of node densities.

## Examples

``` r
adj_matrix <- matrix(c(0,1,1,
                       1,0,0,
                       1,0,0), nrow=3, byrow=TRUE)
ng <- neighbor_graph(adj_matrix)
node_density(ng, matrix(rnorm(9), nrow=3))
#> [1] 2.848366 5.300698 6.092766
```
