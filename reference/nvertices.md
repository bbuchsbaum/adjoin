# Number of Vertices in Graph-like Objects

Retrieve the number of vertices in a neighbor_graph object.

## Usage

``` r
nvertices(x, ...)
```

## Arguments

- x:

  an object with a neighborhood

- ...:

  Additional arguments (currently ignored).

## Value

The number of vertices in the neighbor_graph object.

## Examples

``` r
adj_matrix <- matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), nrow = 3, byrow = TRUE)
ng <- neighbor_graph(adj_matrix)
nvertices(ng) # Should return 3
#> [1] 3
```
