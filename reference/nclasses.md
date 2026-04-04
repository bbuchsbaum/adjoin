# Number of Classes

A generic function to compute the number of classes in a graph.

## Usage

``` r
nclasses(x)
```

## Arguments

- x:

  An object.

## Value

The number of classes in the input object.

## Examples

``` r
labs <- factor(c("a","a","b"))
cg <- class_graph(labs)
nclasses(cg)
#> [1] 2
```
