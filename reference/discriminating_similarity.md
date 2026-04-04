# Compute Similarity Graph Weighted by Class Structure

This function computes a similarity graph that is weighted by the class
structure of the data. It is useful for preserving the local similarity
and diversity within the data, making it suitable for tasks like face
and handwriting digits recognition.

## Usage

``` r
discriminating_similarity(X, k, sigma, cg, threshold = 0.01)
```

## Arguments

- X:

  A numeric matrix or data frame containing the data points.

- k:

  An integer representing the number of nearest neighbors to consider.

- sigma:

  A numeric value representing the scaling factor for the heat kernel.

- cg:

  A class_graph object computed from the labels.

- threshold:

  A numeric value representing the threshold for the class graph.
  Default is 0.01.

## Value

A weighted similarity graph in the form of a sparse matrix.

## References

Local similarity and diversity preserving discriminant projection for
face and handwriting digits recognition

## Examples

``` r
# \donttest{
X <- matrix(rnorm(100*100), 100, 100)
labels <- factor(rep(1:5, each=20))
cg <- class_graph(labels)
sigma <- 0.7
W <- discriminating_similarity(X, k=length(labels)/2, sigma, cg)
# }
```
