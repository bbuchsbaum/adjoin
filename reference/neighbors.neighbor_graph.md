# Get neighbors for neighbor_graph object

Retrieve the neighbors of a specific node or all nodes in a
neighbor_graph object.

## Usage

``` r
# S3 method for class 'neighbor_graph'
neighbors(x, i, ...)
```

## Arguments

- x:

  A neighbor_graph object.

- i:

  An integer specifying the index of the node for which neighbors should
  be retrieved. If missing, returns neighbors for all nodes.

- ...:

  Additional arguments (currently ignored).

## Value

If i is provided, a list containing the neighbors of node i. If i is
missing, a list with neighbors for all nodes.

## Examples

``` r
# \donttest{
adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0),
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
neighbors(ng, 1)  # Neighbors of node 1
#> Error in ensure_igraph(graph): Must provide a graph object (provided wrong object type).
neighbors(ng)     # All neighbors
#> Error in ensure_igraph(graph): Must provide a graph object (provided wrong object type).
# }
```
