# Construct a Class Graph

A graph in which members of the same class have edges.

## Usage

``` r
class_graph(labels, sparse = TRUE)
```

## Arguments

- labels:

  A vector of class labels.

- sparse:

  A logical value, indicating whether to use sparse matrices in the
  computation. Default is TRUE.

## Value

A class_graph object, which is a list containing the following
components:

- adjacency:

  A matrix representing the adjacency of the graph.

- params:

  A list of parameters used in the construction of the graph.

- labels:

  A vector of class labels.

- class_indices:

  A list of vectors, each containing the indices of elements belonging
  to a specific class.

- class_freq:

  A table of frequencies for each class.

- levels:

  A vector of unique class labels.

- classes:

  A character string indicating the type of graph ("class_graph").

## Examples

``` r
data(iris)
labels <- iris[,5]
cg <- class_graph(labels)
```
