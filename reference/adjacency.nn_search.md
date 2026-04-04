# Create Adjacency Matrix from nnsearch Object

Convert a nearest neighbor search result to a sparse adjacency matrix.

## Usage

``` r
# S3 method for class 'nn_search'
adjacency(
  x,
  idim = nrow(x$indices),
  jdim = max(x$indices),
  return_triplet = FALSE,
  ...
)
```

## Arguments

- x:

  An object of class "nnsearch".

- idim:

  The number of rows in the resulting matrix.

- jdim:

  The number of columns in the resulting matrix.

- return_triplet:

  Logical; whether to return triplet format.

- ...:

  Additional arguments (currently ignored).

## Value

A sparse Matrix representing the adjacency matrix.

## Examples

``` r
res <- list(indices = matrix(c(2L,1L), nrow=2),
            distances = matrix(c(0.1,0.2), nrow=2))
class(res) <- "nn_search"
attr(res,"len") <- 2; attr(res,"metric") <- "l2"
adjacency(res, idim=2, jdim=2)
#> 2 x 2 sparse Matrix of class "dgCMatrix"
#>             
#> [1,] .   0.1
#> [2,] 0.2 .  
```
