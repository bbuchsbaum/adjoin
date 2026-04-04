# Build a flexible design-similarity kernel

Constructs a positive semi-definite (PSD) kernel K over design
regressors that encodes factorial similarity: same level similarity,
optional smoothness across ordinal levels, and interaction structure via
Kronecker composition. Works either directly in cell space (one
regressor per cell) or in effect-coded space (main effects,
interactions), by pulling K back through user-specified contrast
matrices.

## Usage

``` r
design_kernel(
  factors,
  terms = NULL,
  rho = NULL,
  include_intercept = TRUE,
  rho0 = 1e-08,
  basis = c("cell", "effect"),
  contrasts = NULL,
  block_structure = NULL,
  normalize = c("none", "unit_trace", "unit_fro", "max_diag"),
  jitter = 1e-08
)
```

## Arguments

- factors:

  A named list, one entry per factor, e.g.
  list(A=list(L=5,type="nominal"), B=list(L=5,type="ordinal", l=1.5)).
  For ordinal, supply length-scale l (\>0). Supported types: "nominal",
  "ordinal", "circular" (wrap-around distances).

- terms:

  A list of character vectors; each character vector lists factor names
  that participate in that term. Examples: list("A", "B", c("A","B"))
  for main A, main B, A:B. If NULL, defaults to all singletons (main
  effects) and the full interaction.

- rho:

  A named numeric vector of nonnegative weights for each term (names
  like "A", "B", "A:B"). If NULL, defaults to 1 for each term. Use rho0
  for the identity term (see below).

- include_intercept:

  Logical; if TRUE, adds rho0 \* I to K (small ridge / identity term).

- rho0:

  Nonnegative scalar weight for the identity term; default 1e-8.

- basis:

  Either "cell" (default) or "effect". If "effect", you must supply
  \`contrasts\`.

- contrasts:

  A named list of contrast matrices for each factor, with dimensions L_i
  x d_i. For example: list(A = contr.sum(5), B = contr.sum(5)). You can
  also pass orthonormal Helmert.

- block_structure:

  If basis="effect", a character vector naming the sequence of effect
  blocks to include, e.g., c("A","B","A:B"). If NULL, inferred from
  \`terms\` and \`contrasts\`.

- normalize:

  One of c("none","unit_trace","unit_fro","max_diag").

- jitter:

  Small diagonal added to ensure SPD; default 1e-8.

## Value

A list with elements:

- K:

  PSD kernel matrix in the requested basis (cell or effect)

- K_cell:

  The cell-space kernel matrix (always returned)

- info:

  A list containing levels, factor_names, term_names, basis, map (T
  matrix for effect basis), blocks

## Details

The kernel is constructed using the following principles:

- For each factor i with L_i levels, define a per-factor kernel K_i
  (nominal or ordinal)

- For any term S (subset of factors), construct a term kernel by
  Kronecker product: K_S = kronecker(K_i, K_j, ...) for i,j in S and
  kronecker with J matrices for factors not in S

- Combine term kernels with nonnegative weights rho\[S\] and optionally
  add a small ridge

- If using effect coding, map the cell kernel to effect-space: K_effect
  = T' K_cell T

## Examples

``` r
factors <- list(
  A = list(L=2, type="nominal"),
  B = list(L=3, type="nominal")
)
K1 <- design_kernel(factors)
print(dim(K1$K))  # 6x6 cell-space kernel
#> [1] 6 6

factors <- list(
  dose = list(L=3, type="ordinal", l=1.0),
  treat = list(L=2, type="nominal")
)
K2 <- design_kernel(factors)
print(dim(K2$K))  # 6x6 cell-space kernel
#> [1] 6 6
```
