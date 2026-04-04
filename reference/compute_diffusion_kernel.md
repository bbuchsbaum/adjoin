# Compute Markov diffusion kernel via eigen decomposition

Efficient computation of the Markov diffusion kernel for a graph
represented by a sparse adjacency matrix. For large graphs, uses
RSpectra to compute only the leading k eigenpairs of the normalized
transition matrix.

## Usage

``` r
compute_diffusion_kernel(A, t, k = NULL, symmetric = TRUE)
```

## Arguments

- A:

  Square sparse adjacency matrix (dgCMatrix) of an undirected, weighted
  graph with non-negative entries.

- t:

  Diffusion time parameter (positive scalar).

- k:

  Number of leading eigenpairs to compute. If NULL, performs full
  eigendecomposition.

- symmetric:

  If TRUE (default), uses symmetric normalization to guarantee real
  eigenvalues.

## Value

dgCMatrix representing the diffusion kernel matrix.

## Examples

``` r
library(Matrix)
A <- sparseMatrix(i = c(1, 2, 3, 4), j = c(2, 3, 4, 5), 
                  x = c(1, 1, 1, 1), dims = c(5, 5))
A <- A + t(A)  # Make symmetric

K <- compute_diffusion_kernel(A, t = 0.5)

K_approx <- compute_diffusion_kernel(A, t = 0.5, k = 3)
```
