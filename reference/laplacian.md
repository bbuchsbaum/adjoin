# Compute Graph Laplacian of a Weight Matrix

This function computes the graph Laplacian of a given weight matrix. The
graph Laplacian is defined as the difference between the degree matrix
and the adjacency matrix.

## Usage

``` r
laplacian(x, ...)
```

## Arguments

- x:

  The weight matrix representing the graph structure.

- ...:

  Additional arguments to be passed to specific implementations of the
  laplacian method.

## Value

The graph Laplacian matrix of the given weight matrix.

## Examples

``` r
W <- Matrix::Matrix(c(0,1,0,
              1,0,1,
              0,1,0), nrow=3, byrow=TRUE, sparse=TRUE)
ng <- neighbor_graph(W)
laplacian(ng)
#> 3 x 3 sparse Matrix of class "dgCMatrix"
#>              
#> [1,]  1 -1  .
#> [2,] -1  2 -1
#> [3,]  . -1  1
```
