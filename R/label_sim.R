#' Create a Binary Label Adjacency Matrix (All Pairs)
#'
#' Constructs a binary adjacency matrix based on two sets of labels `a` and `b`,
#' creating edges for ALL pairs (i, j) where labels match (type="s") or differ (type="d").
#' This computes the full cross-product comparison between the two label vectors.
#'
#' @param a A vector of labels for the first set of data points.
#' @param b A vector of labels for the second set of data points (default: NULL). If NULL, `b` will be set to `a`.
#' @param type A character specifying the type of adjacency matrix to create, either "s" for same labels or "d" for different labels (default: "s").
#'
#' @return A sparse binary adjacency matrix of dimensions (length(a) x length(b)) with 1s
#'   where the label relationship holds.
#'
#' @details
#' For type="s", the result is a block-diagonal structure when a==b, with blocks
#' corresponding to each class. For type="d", the result is the complement.
#'
#' This function uses efficient sparse matrix multiplication via indicator matrices,
#' avoiding O(n^2) memory usage from expanding all pairs.
#'
#' @examples
#' data(iris)
#' a <- iris[,5]
#' bl <- binary_label_matrix(a, type="d")
#'
#' @seealso \code{\link{diagonal_label_matrix}} for element-wise (positional) comparison
#'
#' @export
#' @importFrom Matrix sparseMatrix tcrossprod
binary_label_matrix <- function(a, b = NULL, type = c("s", "d")) {
  type <- match.arg(type)
  if (is.null(b)) b <- a


  fa <- as.factor(a)
  fb <- as.factor(b)
  na <- length(fa)
  nb <- length(fb)


  # Unify factor levels between a and b for correct comparison
  all_levels <- union(levels(fa), levels(fb))
  fa <- factor(fa, levels = all_levels)
  fb <- factor(fb, levels = all_levels)

  ia <- as.integer(fa)
  ib <- as.integer(fb)
  nlev <- length(all_levels)

  # Create sparse indicator matrices (efficient O(n) construction)
  # indicator_a: na x nlev matrix with 1 at (i, label[i])
  # indicator_b: nb x nlev matrix with 1 at (j, label[j])
  indicator_a <- Matrix::sparseMatrix(
    i = seq_len(na),
    j = ia,
    x = 1,
    dims = c(na, nlev)
  )
  indicator_b <- Matrix::sparseMatrix(
    i = seq_len(nb),
    j = ib,
    x = 1,
    dims = c(nb, nlev)
  )

  if (type == "s") {
    # Same labels: tcrossprod gives 1 where labels match
    Matrix::tcrossprod(indicator_a, indicator_b)
  } else {
    # Different labels: complement of same-label matrix
    # Note: For type="d", the result can be very dense (most pairs differ)
    # We compute it as: 1 - same_labels, but only store non-zero entries
    same_labels <- Matrix::tcrossprod(indicator_a, indicator_b)
    # Use drop0 to ensure sparse, then compute logical complement
    # same_labels == 0 creates dense matrix, so we avoid that
    # Instead, flip: start with all-1s conceptually, subtract same_labels
    # For sparse efficiency, we accept that "different" matrices may be dense
    ones <- Matrix::Matrix(1, nrow = na, ncol = nb, sparse = TRUE)
    Matrix::drop0(ones - same_labels)
  }
}


#' Create a Diagonal Label Comparison Matrix (Element-wise)
#'
#' Compares labels at corresponding positions (element-wise) between two equal-length
#' vectors `a` and `b`. Creates a sparse matrix with entries only on the diagonal,
#' where position (i, i) is 1 if `a[i]` and `b[i]` satisfy the comparison.
#'
#' @param a A vector of labels for the first set of data points.
#' @param b A vector of labels for the second set of data points. Must have same length as `a`.
#' @param type A character specifying the comparison type: "s" for same labels (a[i] == b[i])
#'   or "d" for different labels (a[i] != b[i]). Default is "s".
#' @param dim1 The row dimension of the output matrix (default: length(a)).
#' @param dim2 The column dimension of the output matrix (default: length(b)).
#'
#' @return A sparse diagonal matrix where entry (i, i) is 1 if the labels at position i
#'   satisfy the comparison, 0 otherwise.
#'
#' @details
#' This function performs element-wise comparison, NOT all-pairs comparison.
#' For all-pairs comparison (block structure), use \code{\link{binary_label_matrix}}.
#'
#' The vectors `a` and `b` must have the same length. If they differ, recycling
#' will occur which is likely unintended.
#'
#' @seealso \code{\link{binary_label_matrix}} for all-pairs comparison
#'
#' @examples
#' a <- factor(c("x","y","x"))
#' b <- factor(c("x","x","y"))
#' diagonal_label_matrix(a, b, type="d")
#'
#' @export
diagonal_label_matrix <- function(a, b, type = c("s", "d"), dim1 = length(a),
                                  dim2 = length(b)) {
  type <- match.arg(type)


  if (length(a) != length(b)) {
    warning("Vectors a and b have different lengths; comparison uses recycling which may be unintended")
  }

  fa <- as.factor(a)
  fb <- as.factor(b)
  ia <- as.integer(fa)
  ib <- as.integer(fb)

  if (type == "s") {
    keep <- ia == ib
  } else {
    keep <- ia != ib
  }

  idx <- which(keep)
  Matrix::sparseMatrix(
    i = idx,
    j = idx,
    x = rep(1L, length(idx)),
    dims = c(dim1, dim2)
  )
}

#' Convolve a Data Matrix with a Kernel Matrix
#'
#' Performs right-multiplication of a data matrix `X` by a kernel matrix `Kern`,
#' optionally with symmetric normalization.
#'
#' @param X A data matrix to be transformed (n x p).
#' @param Kern A square kernel matrix (p x p) used for the transformation.
#' @param normalize A logical flag indicating whether to apply symmetric normalization
#'   D^(-1/2) Kern D^(-1/2) before multiplication (default: FALSE).
#'
#' @return A matrix resulting from X \%*\% Kern (or normalized version).
#'
#' @importFrom Matrix Diagonal
#' @return A matrix resulting from \code{X \%*\% Kern} (or the normalized version when \code{normalize=TRUE}).
#' @examples
#' X <- matrix(1:6, nrow=2)
#' K <- diag(3)
#' convolve_matrix(X, K)
#' @export
convolve_matrix <- function(X, Kern, normalize = FALSE) {
  assertthat::assert_that(ncol(Kern) == nrow(Kern), msg = "'Kern' must be a square matrix")
  assertthat::assert_that(ncol(X) == nrow(Kern), msg = "ncol(X) must equal nrow(Kern)")

  if (normalize) {
    rs <- rowSums(Kern)
    scale <- ifelse(rs > 0, 1 / sqrt(rs), 0)
    Kern <- Diagonal(x = scale) %*% Kern %*% Diagonal(x = scale)
  }
  X %*% Kern
}


#' Diagonal Label Comparison with NA Handling
#'
#' Compares labels at corresponding positions (element-wise) between two equal-length
#' vectors `a` and `b`, with explicit NA handling. Creates a sparse matrix with entries
#' only on the diagonal.
#'
#' @param a The first categorical label vector.
#' @param b The second categorical label vector. Must have same length as `a`.
#' @param type The type of comparison: "s" for same labels (a[i] == b[i])
#'   or "d" for different labels (a[i] != b[i]). Default is "s".
#' @param return_matrix A logical flag indicating whether to return the result as a
#'   sparse matrix (default: TRUE) or a triplet matrix with columns (i, j, x).
#' @param dim1 The row dimension of the output matrix (default: length(a)).
#' @param dim2 The column dimension of the output matrix (default: length(b)).
#'
#' @return If return_matrix is TRUE, a sparse diagonal matrix where entry (i, i) is 1
#'   if the labels at position i satisfy the comparison (and neither is NA).
#'   If return_matrix is FALSE, a 3-column matrix of (row, col, value) triplets.
#'
#' @details
#' This function performs element-wise (positional) comparison, NOT all-pairs comparison.
#' Positions where either label is NA are excluded from the result.
#'
#' For all-pairs comparison (block structure), use \code{\link{binary_label_matrix}}.
#' For diagonal comparison without NA handling, use \code{\link{diagonal_label_matrix}}.
#'
#' @seealso \code{\link{binary_label_matrix}}, \code{\link{diagonal_label_matrix}}
#'
#' @importFrom Matrix sparseMatrix
#' @examples
#' a <- c("x","y", NA)
#' b <- c("x","y","y")
#' diagonal_label_matrix_na(a, b, type="s", return_matrix=TRUE)
#' @export
diagonal_label_matrix_na <- function(a, b, type = c("s", "d"),
                                     return_matrix = TRUE,
                                     dim1 = length(a),
                                     dim2 = length(b)) {
  type <- match.arg(type)

  if (length(a) != length(b)) {
    warning("Vectors a and b have different lengths; comparison uses recycling which may be unintended")
  }

  fa <- as.factor(a)
  fb <- as.factor(b)
  ia <- as.integer(fa)
  ib <- as.integer(fb)

  # Element-wise comparison with NA handling
  if (type == "s") {
    keep <- ia == ib & !is.na(ia) & !is.na(ib)
  } else {
    keep <- ia != ib & !is.na(ia) & !is.na(ib)
  }

  if (!any(keep)) {
    if (return_matrix) {
      return(Matrix::Matrix(0, nrow = dim1, ncol = dim2, sparse = TRUE))
    } else {
      return(matrix(integer(0), ncol = 3))
    }
  }

  idx <- which(keep)
  if (return_matrix) {
    Matrix::sparseMatrix(
      i = idx,
      j = idx,
      x = rep(1L, length(idx)),
      dims = c(dim1, dim2)
    )
  } else {
    cbind(idx, idx, 1L)
  }
}

#' Expand Similarity Between Labels Based on a Precomputed Similarity Matrix
#'
#' Expands the similarity between labels based on a precomputed similarity matrix, `sim_mat`, with either above-threshold or below-threshold values depending on the value of the `above` parameter.
#'
#' @param labels A vector of labels for which the similarities will be expanded.
#' @param sim_mat A precomputed similarity matrix containing similarities between the unique labels.
#' @param threshold A threshold value used to filter the expanded similarity values (default: 0).
#' @param above A boolean flag indicating whether to include the values above the threshold (default: TRUE) or below the threshold (FALSE).
#'
#' @return A sparse symmetric similarity matrix with the expanded similarity values.
#'
#' @examples
#' labels <- c("a","b","a")
#' smat <- matrix(c(1,.2,.2, 0.2,1,0.5, 0.2,0.5,1), nrow=3,
#'                dimnames=list(c("a","b","c"), c("a","b","c")))
#' expand_label_similarity(labels, smat, threshold=0.1)
#'
#' @export
expand_label_similarity <- function(labels, sim_mat, threshold=0, above=TRUE) {
  cnames <- colnames(sim_mat)
  rnames <- rownames(sim_mat)
  assertthat::assert_that(!(is.null(cnames) && is.null(rnames)))

  if (!is.null(cnames) && !is.null(rnames)) {
    assertthat::assert_that(identical(cnames, rnames),
                            msg = "Row and column names of similarity matrix must be identical")
  }
  if (is.null(cnames)) {
    lnames <- rnames
  } else {
    lnames <- cnames
  }

  mind <- match(labels, lnames)

  if (all(is.na(mind))) {
    stop(paste("no matches between `labels` and similarity matrix entries"))
  }

  # Ensure indices passed to C++ are integers and handle NAs by setting to 0 (or another indicator if needed)
  # C++ code currently skips negative indices, so 0 should work if C++ expects 1-based and subtracts 1.
  # Let's confirm C++ handles 0 correctly or adjust here.
  # C++ code does `indices[i] - 1`, so passing 0 will result in -1, which is skipped. This is okay.
  mind[is.na(mind)] <- 0
  mind <- as.integer(mind)

  out <- if (above) {
    expand_similarity_cpp(mind, sim_mat, threshold)
  } else {
    expand_similarity_below_cpp(mind, sim_mat, threshold)
  }

  # Check if the returned matrix is empty
  if (!is.matrix(out) || nrow(out) == 0) {
    warning("No similarities met the threshold criteria or C++ function failed.")
    # Return an empty sparse matrix with correct dimensions
    return(sparseMatrix(i={}, j={}, x={}, dims=c(length(labels), length(labels)), symmetric=TRUE))
  }

  # Ensure columns are numeric before passing to sparseMatrix
  i_col <- as.numeric(out[,1])
  j_col <- as.numeric(out[,2])
  x_col <- as.numeric(out[,3])
  
  # Check for NAs or non-finite values introduced somehow
  valid_idx <- is.finite(i_col) & is.finite(j_col) & is.finite(x_col)
  if (!all(valid_idx)) {
      warning("Non-finite values detected in matrix returned from C++; removing them.")
      i_col <- i_col[valid_idx]
      j_col <- j_col[valid_idx]
      x_col <- x_col[valid_idx]
  }
  
  sparseMatrix(i=i_col, j=j_col, x=x_col, 
               dims=c(length(labels), length(labels)), 
               symmetric=TRUE, 
               index1 = TRUE) # Assuming C++ returns 1-based indices

}
