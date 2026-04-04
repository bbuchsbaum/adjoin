# Compute the temporal adjacency matrix of a time series

This function computes the temporal adjacency matrix of a given time
series using a specified weight mode, sigma, and window size.

## Usage

``` r
temporal_adjacency(
  time,
  weight_mode = c("heat", "binary"),
  sigma = 1,
  window = 2
)
```

## Arguments

- time:

  A numeric vector representing a time series

- weight_mode:

  Character, the mode for computing weights, either "heat" or "binary"
  (default is "heat")

- sigma:

  Numeric, the sigma parameter for the heat kernel (default is 1)

- window:

  Integer, the window size for computing adjacency (default is 2)

## Value

A sparse symmetric matrix representing the computed temporal adjacency

## Examples

``` r
time <- 1:10

result <- temporal_adjacency(time, weight_mode = "heat", sigma = 1, window = 2)
```
