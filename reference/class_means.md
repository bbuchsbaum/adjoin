# Class Means

A generic function to compute the mean of each class.

## Usage

``` r
class_means(x, ...)
```

## Arguments

- x:

  An object (e.g., class_graph).

- ...:

  Additional arguments passed to specific methods.

## Value

A matrix or data frame representing the means of each class, the
structure of which depends on the input object's class.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
class_means(cg, matrix(1:9, nrow=3))
#>   [,1] [,2] [,3]
#> a  1.5  4.5  7.5
#> b  3.0  6.0  9.0
```
