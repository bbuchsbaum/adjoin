#' Compute the commute-time distance between nodes in a graph
#'
#' This function computes the commute-time distance between nodes in a graph using either eigenvalue or
#' pseudoinverse methods.
#'
#' @param A A symmetric, non-negative matrix representing the adjacency matrix of the graph
#' @param ncomp Integer, number of components to use in the computation, default is (nrow(A) - 1)
#'
#' @return A list with the following components:
#'   \item{eigenvectors}{Matrix, eigenvectors of the matrix M}
#'   \item{eigenvalues}{Vector, eigenvalues of the matrix M}
#'   \item{cds}{Matrix, the computed commute-time distances}
#'   \item{gap}{Numeric, the gap between the two largest eigenvalues}
#'   The returned object has class "commute_time" and "list".
#'
#' @examples
#' A <- matrix(c(0, 1, 1, 0,
#'              1, 0, 1, 1,
#'              1, 1, 0, 1,
#'              0, 1, 1, 0), nrow = 4, byrow = TRUE)
#'
#' result <- commute_time_distance(A)
#'
#' @importFrom RSpectra eigs
#' @export
commute_time_distance <- function(A, ncomp=nrow(A)-1) {
  D <- Matrix::rowSums(A)

  Dtilde <- Diagonal(x= D^(-1/2))

  M <- Dtilde %*% A %*% Dtilde

  decomp <- RSpectra::eigs_sym(M, k=ncomp+1)

  pii <- D/sum(A)
  v <- decomp$vectors[, 2:(ncomp+1)]
  ev <- decomp$values[2:(ncomp+1)]

  if (any(decomp$values > 1 + 1e-12)) {
    stop("eigenvalue greater than 1 detected.")
  }
  #maxev <- max(ev)

  gap <- decomp$values[1] - decomp$values[2]

  cds <- sweep(v, 2, sqrt(1 - ev), "/")
  cds <- sweep(cds, 1, 1/sqrt(pii), "*")
  cds

  ret <- list(eigenvectors=decomp$vectors, eigenvalues=decomp$values, cds=cds, gap=gap)
  class(ret) <- c("commute_time", "list")
  ret
}

