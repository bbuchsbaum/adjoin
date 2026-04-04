# Extract adjacency matrix from neighbor_graph object

Extract the adjacency matrix from a neighbor_graph object.

## Usage

``` r
# S3 method for class 'neighbor_graph'
adjacency(x, attr = "weight", ...)
```

## Arguments

- x:

  A neighbor_graph object.

- attr:

  A character string specifying the edge attribute to use for weights
  (default: "weight").

- ...:

  Additional arguments (currently ignored).

## Value

A sparse Matrix object representing the adjacency matrix.

## Examples

``` r
adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), 
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
adj <- adjacency(ng)
```
