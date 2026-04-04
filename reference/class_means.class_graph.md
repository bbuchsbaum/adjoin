# Class Means for class_graph Objects

Compute the mean of each class for a class_graph object.

## Usage

``` r
# S3 method for class 'class_graph'
class_means(x, X, ...)
```

## Arguments

- x:

  A class_graph object.

- X:

  The data matrix corresponding to the graph nodes.

- ...:

  Additional arguments (currently ignored).

## Value

A matrix where each row represents the mean values for each class.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
class_means(cg, matrix(1:9, nrow=3))
#>   [,1] [,2] [,3]
#> a  1.5  4.5  7.5
#> b  3.0  6.0  9.0
```
