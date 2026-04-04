# Example 5x5 factorial kernel

Creates a simple 5x5 factorial design kernel with two nominal factors,
useful for testing and demonstration purposes.

## Usage

``` r
example_kernel_5x5(rho0 = 1e-08, rhoA = 1, rhoB = 1, rhoAB = 0)
```

## Arguments

- rho0:

  Weight for identity/ridge term (default 1e-8)

- rhoA:

  Weight for main effect of factor A (default 1)

- rhoB:

  Weight for main effect of factor B (default 1)

- rhoAB:

  Weight for A:B interaction (default 0)

## Value

A list with kernel matrices and metadata (see
[`design_kernel`](https://bbuchsbaum.github.io/graphweights/reference/design_kernel.md))

## Examples

``` r
K1 <- example_kernel_5x5(rhoA=1, rhoB=1, rhoAB=0)

K2 <- example_kernel_5x5(rhoA=1, rhoB=1, rhoAB=1)
```
