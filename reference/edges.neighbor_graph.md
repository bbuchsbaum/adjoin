# Extract edges from neighbor_graph object

Retrieve the edges of a neighbor_graph object.

## Usage

``` r
# S3 method for class 'neighbor_graph'
edges(x, ...)
```

## Arguments

- x:

  A neighbor_graph object.

- ...:

  Additional arguments (currently ignored).

## Value

A two-column matrix containing the edges, where each row represents an
edge between two nodes.

## Examples

``` r
adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), 
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
edge_list <- edges(ng)
```
