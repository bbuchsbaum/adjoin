# Get non-neighbors for neighbor_graph object

Retrieve the non-neighboring nodes of a given node in a neighbor_graph
object.

## Usage

``` r
# S3 method for class 'neighbor_graph'
non_neighbors(x, i, ...)
```

## Arguments

- x:

  A neighbor_graph object.

- i:

  The index of the node for which non-neighboring nodes will be
  returned.

- ...:

  Additional arguments (currently ignored).

## Value

A numeric vector of node indices that are not neighbors of the given
node (excluding the node itself).

## Examples

``` r
adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), 
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
```
