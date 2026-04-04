# Convert Distance to Similarity for Matrix Objects

Convert distance values in a sparse Matrix to similarity values.

## Usage

``` r
# S3 method for class 'Matrix'
dist_to_sim(
  x,
  method = c("heat", "binary", "normalized", "cosine", "correlation"),
  sigma = 1,
  len = 1,
  ...
)
```

## Arguments

- x:

  A Matrix object containing distances.

- method:

  The transformation method for converting distances to similarities.

- sigma:

  The bandwidth parameter for the heat kernel method.

- len:

  The length parameter used in transformation calculations.

- ...:

  Additional arguments (currently ignored).

## Value

The Matrix object with distances converted to similarities.

## Examples

``` r
m <- Matrix::Matrix(c(0,1,2,0), nrow=2, sparse=TRUE)
dist_to_sim(m, method="heat", sigma=1)
#> 2 x 2 sparse Matrix of class "dgCMatrix"
#>                         
#> [1,] .         0.1353353
#> [2,] 0.6065307 .        
```
