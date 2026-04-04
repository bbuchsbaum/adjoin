# Compute Discriminating Distance for Similarity Graph

This function computes a discriminating distance matrix for the
similarity graph based on the class labels. It adjusts the similarity
graph by modifying the weights within and between classes, making it
more suitable for tasks like classification and clustering.

## Usage

``` r
discriminating_distance(X, labels, k = NULL, sigma = NULL)
```

## Arguments

- X:

  A numeric matrix or data frame containing the data points.

- labels:

  A factor or numeric vector containing the class labels for each data
  point.

- k:

  An integer representing the number of nearest neighbors to consider.
  Default is half the number of samples.

- sigma:

  A numeric value representing the scaling factor for the heat kernel.
  If not provided, it will be estimated.

## Value

A discriminating distance matrix in the form of a sparse matrix.

## Examples

``` r
# \donttest{
X <- matrix(rnorm(100*100), 100, 100)
labels <- factor(rep(1:5, each=20))
sigma <- 0.7
D <- discriminating_distance(X, labels, k=length(labels)/2, sigma=sigma)
# }
```
