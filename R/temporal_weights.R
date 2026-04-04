#' Compute the temporal autocorrelation of a matrix
#'
#' This function computes the temporal autocorrelation of a given matrix using a specified window size and
#' optionally inverts the correlation matrix.
#'
#' @param X A numeric matrix for which to compute the temporal autocorrelation
#' @param window integer, the window size for computing the autocorrelation, must be between 1 and ncol(X) (default is 3)
#' @param inverse logical, whether to compute the inverse of the correlation matrix (default is FALSE)
#'
#' @return A sparse symmetric matrix representing the computed temporal autocorrelation
#'
#' @importFrom Matrix bandSparse
#'
#' @examples
#' X <- matrix(rnorm(50), nrow = 10, ncol = 5)
#'
#' result <- temporal_autocor(X, window = 2)
#'
#' @export
temporal_autocor <- function(X, window=3, inverse=FALSE) {
  assertthat::assert_that(window >= 1 && window < ncol(X))
  cmat <- cor(X)
  if (inverse) {
    if (!requireNamespace("corpcor", quietly = TRUE)) stop("Package 'corpcor' is required for inverse=TRUE. Install with install.packages('corpcor')")
    cmat <- corpcor::invcor.shrink(cmat)
  }

  n <- ncol(cmat)

  # Efficiently compute mean correlation at each lag

  # Extract k-th super-diagonal using matrix indexing (O(n) per lag)
  cvals <- vapply(seq_len(window), function(k) {
    idx <- cbind(seq_len(n - k), seq_len(n - k) + k)
    mean(cmat[idx])
  }, numeric(1))

  # bandSparse expects a list/data.frame of diagonals, each replicated n times
  bmat <- matrix(cvals, nrow = n, ncol = window, byrow = TRUE)
  bLis <- as.data.frame(bmat)
  A <- bandSparse(n, k = seq_len(window), diagonals = bLis, symmetric = TRUE)
  A
}


#' Compute the temporal adjacency matrix of a time series
#'
#' This function computes the temporal adjacency matrix of a given time series using a specified weight mode,
#' sigma, and window size.
#'
#' @param time A numeric vector representing a time series
#' @param weight_mode Character, the mode for computing weights, either "heat" or "binary" (default is "heat")
#' @param sigma Numeric, the sigma parameter for the heat kernel (default is 1)
#' @param window Integer, the window size for computing adjacency (default is 2)
#'
#' @return A sparse symmetric matrix representing the computed temporal adjacency
#'
#' @importFrom Matrix sparseMatrix
#'
#' @examples
#' time <- 1:10
#'
#' result <- temporal_adjacency(time, weight_mode = "heat", sigma = 1, window = 2)
#'
#' @export
temporal_adjacency <- function(time, weight_mode = c("heat", "binary"), sigma=1, window=2) {
  weight_mode <- match.arg(weight_mode)
  len <- length(time)

  wfun <- if (weight_mode == "binary") {
    function(x) rep(1, length(x))
  } else {
    function(x) heat_kernel(x, sigma)
  }

  # Pre-allocate list for efficiency (avoid growing matrix in loop)
  results <- vector("list", len)

  for (i in seq_len(len)) {
    end_idx <- min(i + window - 1, len)
    # Get time values in the window
    t_window <- time[i:end_idx]
    # Compute distances from first element
    dists <- abs(t_window[1] - t_window)
    # Compute weights
    weights <- wfun(dists)
    # Store row indices, column indices, and weights
    results[[i]] <- cbind(i, i:end_idx, weights)
  }

  m <- do.call(rbind, results)

  sm <- sparseMatrix(i = m[, 1], j = m[, 2], x = m[, 3], dims = c(len, len))
  sm <- Matrix::forceSymmetric(sm)
  sm
}

#' Compute the temporal Laplacian matrix of a time series
#'
#' This function computes the temporal Laplacian matrix of a given time series using a specified weight mode,
#' sigma, and window size.
#'
#' @param time A numeric vector representing a time series
#' @param weight_mode Character, the mode for computing weights, either "heat" or "binary" (default is "heat")
#' @param sigma Numeric, the sigma parameter for the heat kernel (default is 1)
#' @param window Integer, the window size for computing adjacency (default is 2)
#'
#' @return A sparse symmetric matrix representing the computed temporal Laplacian
#'
#' @importFrom Matrix Diagonal
#'
#' @examples
#' time <- 1:10
#'
#' result <- temporal_laplacian(time, weight_mode = "heat", sigma = 1, window = 2)
#'
#' @export
temporal_laplacian <- function(time, weight_mode = c("heat", "binary"), sigma=1, window=2) {
  weight_mode <- match.arg(weight_mode)
  adj <- temporal_adjacency(time, weight_mode, sigma, window)
  Diagonal(x = rowSums(adj)) - adj
}
