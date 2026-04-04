# Local + Global KNN Adjacency

Build an adjacency matrix that mixes `L` neighbors inside a local radius
`r` with `K` neighbors outside that radius. Far neighbors receive a mild
penalty so they can contribute without dominating.

## Usage

``` r
local_global_adjacency(
  coord_mat,
  L = 5,
  K = 5,
  r,
  weight_mode = c("heat", "binary"),
  sigma = r/2,
  far_penalty = c("lambda", "exp"),
  lambda = 0.6,
  tau = r,
  nnk_buffer = 10,
  include_diagonal = FALSE,
  symmetric = TRUE,
  normalized = FALSE
)
```

## Arguments

- coord_mat:

  Numeric matrix of coordinates (rows = points).

- L:

  Number of local neighbors (within `r`) to keep for each point.

- K:

  Number of far neighbors (outside `r`) to keep for each point.

- r:

  Radius defining the local ball.

- weight_mode:

  Weighting scheme name (e.g., "heat"); forwarded to internal helper
  get_neighbor_fun.

- sigma:

  Bandwidth for the heat/normalized kernels; default `r/2`.

- far_penalty:

  Either `"lambda"` (constant multiplier) or `"exp"` (decay with
  distance beyond `r`).

- lambda:

  Constant multiplier for far neighbors when `far_penalty = "lambda"`.

- tau:

  Scale of exponential decay when `far_penalty = "exp"`.

- nnk_buffer:

  Extra candidates requested from the NN search to ensure enough far
  neighbors are available.

- include_diagonal:

  Logical; keep self-loops.

- symmetric:

  Logical; if TRUE, symmetrize by averaging `A` and `t(A)`.

- normalized:

  Logical; if TRUE, row-normalize the matrix (stochastic).

## Value

A sparse adjacency matrix mixing local and far neighbors.

## Examples

``` r
set.seed(1)
coords <- matrix(runif(200), ncol = 2)
A <- local_global_adjacency(coords, L = 4, K = 3, r = 0.15,
                            weight_mode = "heat", lambda = 0.7)
Matrix::rowSums(A)[1:5]
#> [1] 3.245938 2.436397 1.753766 2.281660 2.486815
```
