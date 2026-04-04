# Convert Distance to Similarity

Convert distance values to similarity values using various
transformation methods.

## Usage

``` r
dist_to_sim(x, ...)
```

## Arguments

- x:

  An object representing distances (Matrix, nn_search, etc.).

- ...:

  Additional arguments passed to specific methods.

## Value

A similarity matrix or object with distances converted to similarities.

## Examples

``` r
d <- Matrix::Matrix(as.matrix(dist(matrix(rnorm(6), ncol=2))), sparse=TRUE)
dist_to_sim(d, method="heat", sigma=1)
#> 3 x 3 sparse Matrix of class "dgCMatrix"
#>           1         2         3
#> 1 .         0.1887303 0.0104792
#> 2 0.1887303 .         0.4767891
#> 3 0.0104792 0.4767891 .        
```
