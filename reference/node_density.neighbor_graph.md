# Compute node density for neighbor_graph object

Compute the node density for a neighbor_graph object based on local
neighborhoods.

## Usage

``` r
# S3 method for class 'neighbor_graph'
node_density(x, X, ...)
```

## Arguments

- x:

  A neighbor_graph object.

- X:

  A data matrix containing the data points, with rows as observations.

- ...:

  Additional arguments (currently ignored).

## Value

A numeric vector containing the node densities.

## Details

Node density is computed as the average squared distance from each node
to its neighbors, normalized by the square of the neighborhood size.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(30), nrow = 10, ncol = 3)
adj_matrix <- Matrix::Matrix(diag(10), sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
densities <- node_density(ng, X)
# }
```
