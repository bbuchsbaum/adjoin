# Number of Classes for class_graph Objects

Compute the number of classes in a class_graph object.

## Usage

``` r
# S3 method for class 'class_graph'
nclasses(x)
```

## Arguments

- x:

  A class_graph object.

## Value

The number of classes in the class_graph.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
nclasses(cg)
#> [1] 2
```
