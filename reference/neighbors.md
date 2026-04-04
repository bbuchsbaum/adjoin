# Neighbors of a Set of Nodes

This function retrieves the indices of neighbors of one or more vertices
in a given graph or graph-like object.

## Usage

``` r
neighbors(x, i, ...)
```

## Arguments

- x:

  The graph or graph-like object in which to find the neighbors.

- i:

  The vertex or vertices for which to find the neighbors. Can be a
  single vertex index or a vector of vertex indices.

- ...:

  Additional arguments to be passed to specific implementations of the
  neighbors method.

## Value

A list of vertex indices representing the neighbors of the specified
vertices. The length of the list is equal to the number of input
vertices, and each element in the list contains the neighbor indices for
the corresponding input vertex.

## Examples

``` r
# \donttest{
g <- neighbor_graph(igraph::make_ring(5))

n <- adjoin::neighbors(g, 1)
# }
```
