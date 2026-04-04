# Diffusion map embedding and distance

Computes the diffusion map embedding of a graph and the pairwise
diffusion distances based on the leading eigenvectors of the normalized
transition matrix.

## Usage

``` r
compute_diffusion_map(A, t, k = 10)
```

## Arguments

- A:

  Square sparse adjacency matrix (dgCMatrix) of an undirected, weighted
  graph.

- t:

  Diffusion time parameter (positive scalar).

- k:

  Number of diffusion coordinates to compute, excluding the trivial
  first coordinate.

## Value

A list with two components:

- embedding:

  n×k matrix of diffusion coordinates where n is the number of nodes.

- distances:

  n×n matrix of squared diffusion distances between all node pairs.

## Examples

``` r
library(Matrix)
A <- sparseMatrix(i = c(1, 2, 3), j = c(2, 3, 4), x = c(1, 1, 1), dims = c(4, 4))
A <- A + t(A)  # Make symmetric

result <- compute_diffusion_map(A, t = 1.0, k = 2)

print(result$embedding)
#>            [,1]       [,2]
#> [1,]  0.2886751  0.4082483
#> [2,]  0.2041241 -0.5773503
#> [3,] -0.2041241  0.5773503
#> [4,] -0.2886751 -0.4082483

print(result$distances[1, ])  # distances from node 1
#> [1] 0.0000000 0.9785534 0.2714466 1.0000000
```
