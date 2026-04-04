
#' Compute Markov diffusion kernel via eigen decomposition
#'
#' Efficient computation of the Markov diffusion kernel for a graph represented by
#' a sparse adjacency matrix. For large graphs, uses RSpectra to compute only the
#' leading k eigenpairs of the normalized transition matrix.
#'
#' @param A Square sparse adjacency matrix (dgCMatrix) of an undirected, weighted graph with non-negative entries.
#' @param t Diffusion time parameter (positive scalar).
#' @param k Number of leading eigenpairs to compute. If NULL, performs full eigendecomposition.
#' @param symmetric If TRUE (default), uses symmetric normalization to guarantee real eigenvalues.
#' @return dgCMatrix representing the diffusion kernel matrix.
#' @examples
#' library(Matrix)
#' A <- sparseMatrix(i = c(1, 2, 3, 4), j = c(2, 3, 4, 5), 
#'                   x = c(1, 1, 1, 1), dims = c(5, 5))
#' A <- A + t(A)  # Make symmetric
#' 
#' K <- compute_diffusion_kernel(A, t = 0.5)
#' 
#' K_approx <- compute_diffusion_kernel(A, t = 0.5, k = 3)
#' @importFrom Matrix Diagonal crossprod tcrossprod
#' @importFrom RSpectra eigs
#' @export
compute_diffusion_kernel <- function(A, t, k = NULL, symmetric = TRUE) {

  # Input validation
  assertthat::assert_that(is.numeric(t) && length(t) == 1 && t > 0,
                          msg = "t must be a positive scalar")

  if (!inherits(A, "dgCMatrix")) A <- as(A, "CsparseMatrix")
  n <- nrow(A)
  assertthat::assert_that(ncol(A) == n, msg = "A must be square.")

  # Validate k
  if (!is.null(k)) {
    assertthat::assert_that(k < n, msg = "k must be less than n (number of nodes)")
    assertthat::assert_that(k >= 1, msg = "k must be at least 1")
  }

  # Degree vector
  d <- Matrix::rowSums(A)
  isolated <- d == 0
  if (any(isolated)) {
    warning("Isolated nodes present; they will remain isolated in kernel.")
  }

  # Build transition matrix P with safe degree normalization
  if (symmetric) {
    # Use 0 for isolated nodes to avoid Inf
    d_inv_sqrt <- ifelse(d > 0, 1 / sqrt(d), 0)
    Dm12 <- Diagonal(x = d_inv_sqrt)
    P <- Dm12 %*% A %*% Dm12
  } else {
    d_inv <- ifelse(d > 0, 1 / d, 0)
    Dinv <- Diagonal(x = d_inv)
    P <- Dinv %*% A
  }

  # Eigen decomposition
  if (!is.null(k) && k < n) {
    # Compute top k eigenpairs
    eig <- RSpectra::eigs(P, k = k, which = "LM")
    U <- eig$vectors
    L <- eig$values
  } else {
    eig <- eigen(as.matrix(P), symmetric = symmetric)
    U <- eig$vectors
    L <- eig$values
  }

  # Handle potential complex eigenvalues (can occur with numerical asymmetry)
  if (is.complex(L)) {
    if (max(abs(Im(L))) > 1e-10) {
      warning("Complex eigenvalues detected; using real parts only")
    }
    L <- Re(L)
    U <- Re(U)
  }

  # Diffusion kernel: K = U diag(L^t) U^T
  # Efficient computation: scale columns of U, then tcrossprod
  Lt <- L^t
  Uscaled <- sweep(U, 2, sqrt(pmax(Lt, 0)), "*")  # pmax to handle negative eigenvalues
  K <- tcrossprod(Uscaled)

  # Return as matrix (diffusion kernels are typically dense)
  # Converting to sparse wastes memory on indices with no benefit
  if (n > 5000) warning(paste0("compute_diffusion_kernel: returning a dense ", n, "x", n, " matrix (~", round(n^2 * 8 / 1e9, 2), " GB). Consider compute_diffusion_map() for large graphs."))
  return(Matrix::Matrix(K, sparse = FALSE))
}

#' Diffusion map embedding and distance
#'
#' Computes the diffusion map embedding of a graph and the pairwise diffusion distances
#' based on the leading eigenvectors of the normalized transition matrix.
#'
#' @param A Square sparse adjacency matrix (dgCMatrix) of an undirected, weighted graph.
#' @param t Diffusion time parameter (positive scalar).
#' @param k Number of diffusion coordinates to compute, excluding the trivial first coordinate.
#' @return A list with two components:
#'   \item{embedding}{n×k matrix of diffusion coordinates where n is the number of nodes.}
#'   \item{distances}{n×n matrix of squared diffusion distances between all node pairs.}
#' @examples
#' library(Matrix)
#' A <- sparseMatrix(i = c(1, 2, 3), j = c(2, 3, 4), x = c(1, 1, 1), dims = c(4, 4))
#' A <- A + t(A)  # Make symmetric
#' 
#' result <- compute_diffusion_map(A, t = 1.0, k = 2)
#' 
#' print(result$embedding)
#' 
#' print(result$distances[1, ])  # distances from node 1
#' @importFrom RSpectra eigs
#' @importFrom Matrix Diagonal
#' @export
compute_diffusion_map <- function(A, t, k = 10) {

  # Input validation
  assertthat::assert_that(is.numeric(t) && length(t) == 1 && t > 0,
                          msg = "t must be a positive scalar")
  assertthat::assert_that(is.numeric(k) && length(k) == 1 && k >= 1,
                          msg = "k must be a positive integer")
  k <- as.integer(k)

  if (!inherits(A, "dgCMatrix")) A <- as(A, "CsparseMatrix")
  n <- nrow(A)
  assertthat::assert_that(ncol(A) == n, msg = "A must be square.")

  # Validate k against matrix size (need k+1 eigenpairs, excluding trivial)
  assertthat::assert_that(k + 1 < n,
                          msg = "k must be less than n - 1 (number of nodes minus 1)")

  # Build symmetric transition P with safe degree normalization
  d <- Matrix::rowSums(A)
  isolated <- d == 0
  if (any(isolated)) {
    warning("Isolated nodes present; their embedding coordinates will be zero.")
  }

  # Use 0 for isolated nodes to avoid Inf
  d_inv_sqrt <- ifelse(d > 0, 1 / sqrt(d), 0)
  Dm12 <- Diagonal(x = d_inv_sqrt)
  P <- Dm12 %*% A %*% Dm12

  # Compute k+1 eigenpairs (first eigenvalue = 1)
  eig <- RSpectra::eigs(P, k = k + 1, which = "LM")
  lambdas <- eig$values
  U <- eig$vectors  # n × (k+1)

  # Handle potential complex eigenvalues
  if (is.complex(lambdas)) {
    if (max(abs(Im(lambdas))) > 1e-10) {
      warning("Complex eigenvalues detected; using real parts only")
    }
    lambdas <- Re(lambdas)
    U <- Re(U)
  }

  # Sort in descending order by magnitude
  ord <- order(Re(lambdas), decreasing = TRUE)
  lambdas <- lambdas[ord][2:(k+1)]  # Exclude first (trivial) eigenvalue
  U <- U[, ord, drop = FALSE][, 2:(k+1), drop = FALSE]

  # Diffusion coordinates: psi_j = lambda_j^t * U[,j]
  coords <- sweep(U, 2, lambdas^t, "*")

  # Squared diffusion distances
  # Efficient computation: ||x_i - x_j||^2 = ||x_i||^2 + ||x_j||^2 - 2*x_i'*x_j
  row_norms_sq <- rowSums(coords^2)
  D2 <- outer(row_norms_sq, row_norms_sq, "+") - 2 * tcrossprod(coords)
  # Ensure non-negative (numerical precision)
  D2 <- pmax(D2, 0)

  list(embedding = coords, distances = D2)
}
