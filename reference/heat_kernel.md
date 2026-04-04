# Compute the Heat Kernel

This function computes the heat kernel, which is a radial basis function
that can be used for smoothing, interpolation, and approximation tasks.
The heat kernel is defined as exp(-x^2/(2\*sigma^2)), where x is the
distance and sigma is the bandwidth. It acts as a similarity measure for
points in a space, assigning high values for close points and low values
for distant points.

## Usage

``` r
heat_kernel(x, sigma = 1)
```

## Arguments

- x:

  A numeric vector or matrix representing the distances between data
  points.

- sigma:

  The bandwidth of the heat kernel, a positive scalar value. Default is
  1.

## Value

A numeric vector or matrix with the same dimensions as the input \`x\`,
containing the computed heat kernel values.

## Details

The heat kernel is widely used in various applications, including
machine learning, computer graphics, and image processing. It can be
employed in kernel methods, such as kernel PCA, Gaussian process
regression, and support vector machines, to capture the local structure
of the data. The heat kernel's behavior is controlled by the bandwidth
parameter sigma, which determines the smoothness of the resulting
function.

## Examples

``` r
x <- seq(-3, 3, length.out = 100)
y <- heat_kernel(x, sigma = 1)
plot(x, y, type = "l", main = "Heat Kernel")

```
