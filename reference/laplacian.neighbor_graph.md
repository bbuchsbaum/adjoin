# Compute Laplacian matrix for neighbor_graph object

Compute the Laplacian matrix of a neighbor_graph object.

## Usage

``` r
# S3 method for class 'neighbor_graph'
laplacian(x, normalized = FALSE, ...)
```

## Arguments

- x:

  A neighbor_graph object.

- normalized:

  A logical value indicating whether the normalized Laplacian should be
  computed (default: FALSE).

- ...:

  Additional arguments (currently ignored).

## Value

A sparse Matrix object representing the Laplacian matrix.

## Details

The unnormalized Laplacian is computed as L = D - A where D is the
degree matrix and A is the adjacency matrix. The normalized Laplacian is
computed as L_sym = I - D^(-1/2) A D^(-1/2).

## Examples

``` r
adj_matrix <- Matrix::Matrix(c(0, 1, 1, 0, 1, 0, 1, 0, 0), 
                            nrow = 3, byrow = TRUE, sparse = TRUE)
ng <- neighbor_graph(adj_matrix)
L <- laplacian(ng)
L_norm <- laplacian(ng, normalized = TRUE)
```
