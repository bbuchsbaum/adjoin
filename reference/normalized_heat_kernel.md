# normalized_heat_kernel

normalized_heat_kernel

## Usage

``` r
normalized_heat_kernel(x, sigma = 0.68, len)
```

## Arguments

- x:

  the distances

- sigma:

  the bandwidth

- len:

  the normalization factor (e.g. the length of the feature vectors)

## Value

Numeric vector/matrix of normalized heat kernel values.

## Examples

``` r
normalized_heat_kernel(c(1,2), sigma = .5, len = 4)
#> [1] 0.7788008 0.3678794
```
