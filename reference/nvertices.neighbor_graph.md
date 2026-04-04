# Get number of vertices in neighbor_graph object

Get the number of vertices in a neighbor_graph object.

## Usage

``` r
# S3 method for class 'neighbor_graph'
nvertices(x, ...)
```

## Arguments

- x:

  A neighbor_graph object.

- ...:

  Additional arguments (currently ignored).

## Value

An integer representing the number of vertices in the graph.

## Examples

``` r
adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), 
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
nvertices(ng)  # Should return 3
#> [1] 3
```
