

#' @keywords internal
as_triplet <- function(M) {
  tm <- as(M, "dgTMatrix")
  cbind(i=tm@i+1, j=tm@j+1, x=tm@x)
}

#' @keywords internal
triplet_to_matrix <- function(trip, dim) {
  sparseMatrix(i=trip[,1], j=trip[,2], x=trip[,3],dims=dim)
}


#' @keywords internal
indices_to_sparse <- function(nn.index, hval, return_triplet=FALSE,
                              idim=nrow(nn.index),
                              jdim=nrow(nn.index)) {

  i <- rep(seq_len(nrow(nn.index)), times = ncol(nn.index))
  j <- as.vector(nn.index)
  x <- as.vector(hval)

  valid <- !is.na(j) & j > 0 & !is.na(x)
  i <- i[valid]; j <- j[valid]; x <- x[valid]

  if (return_triplet) {
    cbind(i=i, j=j, x=x)
  } else {
    Matrix::sparseMatrix(i=i, j=j, x=x, dims=c(idim, jdim))
  }
}

#' Compute the Heat Kernel
#'
#' This function computes the heat kernel, which is a radial basis function that can be used for smoothing, interpolation, and approximation tasks. The heat kernel is defined as exp(-x^2/(2*sigma^2)), where x is the distance and sigma is the bandwidth. It acts as a similarity measure for points in a space, assigning high values for close points and low values for distant points.
#'
#' @section Details:
#' The heat kernel is widely used in various applications, including machine learning, computer graphics, and image processing. It can be employed in kernel methods, such as kernel PCA, Gaussian process regression, and support vector machines, to capture the local structure of the data. The heat kernel's behavior is controlled by the bandwidth parameter sigma, which determines the smoothness of the resulting function.
#'
#' @param x A numeric vector or matrix representing the distances between data points.
#' @param sigma The bandwidth of the heat kernel, a positive scalar value. Default is 1.
#'
#' @return A numeric vector or matrix with the same dimensions as the input `x`, containing the computed heat kernel values.
#'
#' @examples
#' x <- seq(-3, 3, length.out = 100)
#' y <- heat_kernel(x, sigma = 1)
#' plot(x, y, type = "l", main = "Heat Kernel")
#'
#' @export
heat_kernel <- function(x, sigma=1) {
  stopifnot(is.numeric(x), is.numeric(sigma), length(sigma) == 1, sigma > 0)
  exp((-x^2)/(2*sigma^2))
}


#' inverse_heat_kernel
#'
#' @param x the distances
#' @param sigma the bandwidth
#' @return Numeric vector/matrix of inverse heat kernel values.
#' @examples
#' inverse_heat_kernel(c(1, 2), sigma = 1)
#' @export
inverse_heat_kernel <- function(x, sigma=1) {
  stopifnot(is.numeric(x), is.numeric(sigma), length(sigma) == 1, sigma > 0)
  x[x == 0] <- .Machine$double.eps
  #exp((-x^2)/(2*sigma^2))
  exp((-2*sigma^2)/x)
}




#' normalized_heat_kernel
#'
#' @param x the distances
#' @param sigma the bandwidth
#' @param len the normalization factor (e.g. the length of the feature vectors)
#' @return Numeric vector/matrix of normalized heat kernel values.
#' @examples
#' normalized_heat_kernel(c(1,2), sigma = .5, len = 4)
#' @export
normalized_heat_kernel <- function(x, sigma=.68, len) {
  stopifnot(is.numeric(x), is.numeric(sigma), length(sigma) == 1, sigma > 0, is.numeric(len), len > 0)
  norm_dist <- (x^2)/(2*len)
  exp(-norm_dist/(2*sigma^2))
}


#' @keywords internal
correlation_kernel <- function(x, len) {
  1 - (x^2)/(2*(len-1))
}


#' @keywords internal
cosine_kernel <- function(x, sigma=1) {
  stopifnot(is.numeric(x))
  1 - (x^2)/2
}



#' @keywords internal
get_neighbor_fun <- function(weight_mode = c("heat", "binary", "normalized",
                                             "euclidean", "cosine",
                                             "correlation"),
                             len, sigma) {
  switch(match.arg(weight_mode),
    heat        = function(x) heat_kernel(x, sigma),
    binary      = function(x) rep_len(1, length(x)),
    normalized  = function(x) normalized_heat_kernel(x, sigma, len),
    euclidean   = identity,
    cosine      = cosine_kernel,
    correlation = function(x) correlation_kernel(x, len)
  )
}


#' @keywords internal
knn_search_euclidean <- function(data, points = data, k,
                                 backend = c("nanoflann", "hnsw"),
                                 drop_first = FALSE,
                                 M = 16, ef = 200, ...) {
  backend <- match.arg(backend)
  data <- as.matrix(data)
  points <- as.matrix(points)
  k_search <- min(k + as.integer(drop_first), nrow(data))

  if (backend == "hnsw") {
    if (!requireNamespace("RcppHNSW", quietly = TRUE)) {
      stop("backend='hnsw' requires the RcppHNSW package.", call. = FALSE)
    }

    ann <- RcppHNSW::hnsw_build(data, distance = "l2", M = M, ef = ef)
    res <- RcppHNSW::hnsw_search(points, ann, k = k_search)
    idx <- res$idx
    dst <- sqrt(res$dist)
  } else {
    res <- Rnanoflann::nn(data = data, points = points, k = k_search, ...)
    idx <- res$indices
    dst <- res$distances
  }

  if (min(idx, na.rm = TRUE) == 0L) idx <- idx + 1L

  if (drop_first) {
    idx <- idx[, -1, drop = FALSE]
    dst <- dst[, -1, drop = FALSE]
  }

  list(indices = idx, distances = dst)
}


#' @keywords internal
symmetrize_knn_sparse <- function(W, type = c("normal", "mutual", "asym")) {
  type <- match.arg(type)
  Wt <- Matrix::t(W)

  out <- switch(type,
    asym = W,
    normal = (W + Wt + abs(W - Wt)) / 2,
    mutual = (W + Wt - abs(W - Wt)) / 2
  )

  Matrix::drop0(out)
}


#' Compute Similarity Matrix for Factors in a Data Frame
#'
#' Calculate the similarity matrix for a set of factors in a data frame using various similarity methods.
#'
#' @param des A data frame containing factors for which the similarity matrix will be computed.
#' @param method A character vector specifying the method used for computing the similarity. The available methods are:
#'   \itemize{
#'     \item "Jaccard" - Jaccard similarity coefficient
#'     \item "Rogers" - Rogers and Tanimoto similarity coefficient
#'     \item "simple matching" - Simple matching coefficient
#'     \item "Dice" - Dice similarity coefficient
#'   }
#' @return A similarity matrix computed using the specified method for the factors in the data frame.
#' @details
#' The \code{factor_sim} function computes the similarity matrix for a set of factors in a data frame using the chosen method.
#' The function first converts the data frame into a model matrix, then calculates the similarity matrix using the \code{proxy::simil}
#' function from the \code{proxy} package.
#'
#' The function supports four similarity methods: Jaccard, Rogers, simple matching, and Dice. The choice of method depends on the
#' specific use case and the desired properties of the similarity measure.
#'
#' @export
#' @examples
#' des <- data.frame(
#'   var1 = factor(c("a", "b", "a", "b", "a")),
#'   var2 = factor(c("c", "c", "d", "d", "d"))
#' )
#'
#' sim_jaccard <- factor_sim(des, method = "Jaccard")
#'
#' sim_dice <- factor_sim(des, method = "Dice")
factor_sim <- function(des,
                       method = c("Jaccard", "Rogers", "simple matching", "Dice")) {

  method <- match.arg(method)
  mm <- lapply(names(des), function(nm) model.matrix(~ . - 1, data = des[nm]))
  mat <- do.call(cbind, mm)
  if (!requireNamespace("proxy", quietly = TRUE)) stop("Package 'proxy' is required. Install with install.packages('proxy')")
  proxy::simil(mat, method = method)
}


#' Compute Weighted Similarity Matrix for Factors in a Data Frame
#'
#' Calculate the weighted similarity matrix for a set of factors in a data frame.
#'
#' @param des A data frame containing factors for which the weighted similarity matrix will be computed.
#' @param wts A numeric vector of weights corresponding to the factors in the data frame. The default is equal weights for all factors.
#' @return A weighted similarity matrix computed for the factors in the data frame.
#'
#' @export
#' @examples
#' des <- data.frame(
#'   var1 = factor(c("a", "b", "a", "b", "a")),
#'   var2 = factor(c("c", "c", "d", "d", "d"))
#' )
#'
#' sim_default_weights <- weighted_factor_sim(des)
#'
#' sim_custom_weights <- weighted_factor_sim(des, wts = c(0.7, 0.3))
weighted_factor_sim <- function(des, wts = rep(1, ncol(des)) / ncol(des)) {
  wts <- wts / sum(wts)
  mats <- Map(function(nm, wt) {
    diagonal_label_matrix_na(des[[nm]], des[[nm]]) * wt
  }, names(des), wts)
  Reduce(`+`, mats)
}


#' Estimate Bandwidth Parameter (Sigma) for the Heat Kernel
#'
#' Estimate a reasonable bandwidth parameter (sigma) for the heat kernel based on a data matrix and the specified quantile of the frequency distribution of distances.
#'
#' @param X A data matrix where samples are rows and features are columns.
#' @param prop A numeric value representing the quantile of the frequency distribution of distances used to determine the bandwidth parameter. Default is 0.25.
#' @param nsamples An integer representing the number of samples to draw from the data matrix. Default is 500.
#' @param normalized A logical value indicating whether to normalize the data. Default is FALSE.
#'
#' @return A numeric value representing the estimated bandwidth parameter (sigma) for the heat kernel.
#' @export
#'
#' @examples
#' X <- matrix(rnorm(1000), nrow=100, ncol=10)
#'
#' sigma_default <- estimate_sigma(X)
#'
#' sigma_custom <- estimate_sigma(X, prop=0.3, nsamples=300)
estimate_sigma <- function(X, prop = .25, nsamples = 500, normalized = FALSE) {
  if (nrow(X) > nsamples) {
    sam <- sample.int(nrow(X), nsamples)
  } else {
    sam <- seq_len(nrow(X))
  }
  d <- stats::dist(X[sam, ])
  q  <- stats::quantile(d[d > 0], probs = prop, na.rm = TRUE)
  if (is.na(q) || q == 0) stop("Unable to estimate sigma (all distances zero)")
  unname(q)
}


#' Convert a Data Matrix to an Adjacency Graph
#'
#' Convert a data matrix with n instances and p features to an n-by-n adjacency graph using specified neighbor and weight modes.
#'
#' @details
#' This function converts a data matrix with n instances and p features into an adjacency graph. The adjacency graph is created
#' based on the specified neighbor and weight modes. The neighbor mode determines how neighbors are assigned weights, and the weight
#' mode defines the method used to compute weights.
#'
#' @param X A data matrix where each row represents an instance and each column represents a variable. Similarity is computed over instances.
#' @param k An integer representing the number of neighbors (ignored when neighbor_mode is not 'epsilon').
#' @param neighbor_mode A character string specifying the method for assigning weights to neighbors, either "supervised", "knn", "knearest_misses", or "epsilon".
#' @param weight_mode A character string specifying the weight mode: binary (1 if neighbor, 0 otherwise), 'heat', 'normalized', 'euclidean', 'cosine', or 'correlation'.
#' @param type A character string specifying the nearest neighbor policy, one of: normal, mutual, asym.
#' @param sigma A numeric parameter for the heat kernel (exp(-dist/(2*sigma^2))).
#' @param eps A numeric value representing the neighborhood radius when neighbor_mode is 'epsilon' (not implemented).
#' @param labels A factor vector representing the class of the categories when weight_mode is 'supervised' with nrow(labels) equal to nrow(X).
#' @param ... Additional parameters passed to the internal functions.
#'
#' @details
#' Distances passed to `weight_mode` kernels are Euclidean (square root already applied to
#' Rnanoflann outputs). Custom kernels should be written accordingly; if a kernel expects
#' squared distances, wrap it to square its input.
#'
#' @return An adjacency graph based on the specified neighbor and weight modes.
#' @seealso \code{\link{graph_weights_fast}} for additional backends and self-tuning options
#' @export
#'
#' @examples
#' X <- matrix(rnorm(100*100), 100, 100)
#' sm <- graph_weights(X, neighbor_mode="knn", weight_mode="normalized", k=3)
#'
#' labels <- factor(rep(letters[1:4], 5))
#' sm3 <- graph_weights(X, neighbor_mode="knn", k=3, labels=labels, weight_mode="cosine")
#' sm4 <- graph_weights(X, neighbor_mode="knn", k=100, labels=labels, weight_mode="cosine")
graph_weights <- function(X, k=5, neighbor_mode=c("knn"),
                          weight_mode=c("heat", "normalized", "binary", "euclidean",
                                        "cosine", "correlation"),
                          type=c("normal", "mutual", "asym"),
                          sigma=NULL,eps=NULL, labels=NULL, ...) {

  neighbor_mode = match.arg(neighbor_mode)
  weight_mode = match.arg(weight_mode)
  type <- match.arg(type)
  if (!is.null(labels)) warning("'labels' parameter is not yet implemented and has no effect")
  X <- as.matrix(X)
  p <- ncol(X)

  if (weight_mode == "normalized" || weight_mode == "correlation") {
    mu <- rowMeans(X)
    X <- X - mu
    denom <- max(p - 1L, 1L)
    s <- sqrt(rowSums(X * X) / denom)
    s[!is.finite(s) | s == 0] <- 1
    X <- X / s
    X[!is.finite(X)] <- 0
  } else if (weight_mode == "cosine") {
    nrm <- sqrt(rowSums(X * X))
    nrm[!is.finite(nrm) | nrm == 0] <- 1
    X <- X / nrm
    X[!is.finite(X)] <- 0
  }

  if ((is.null(sigma)) && (weight_mode %in% c("heat", "normalized"))) {
    if (weight_mode == "heat") {
      sigma <- estimate_sigma(X)
    } else if (weight_mode == "normalized") {
      sigma <- estimate_sigma(X, normalized=TRUE)
    }
    message("sigma is ", sigma)
  }

  wfun <- get_neighbor_fun(weight_mode, len=ncol(X), sigma=sigma)

  W <- weighted_knn(X, k, FUN=wfun, type=type,...)

  neighbor_graph(W, params=list(k=k, neighbor_mode=neighbor_mode,
                                     weight_mode=weight_mode,
                                     sigma=sigma,
                                     type=type,
                                     labels=labels))



}



#' Threshold Adjacency
#'
#' This function extracts the k-nearest neighbors from an existing adjacency matrix.
#' It returns a new adjacency matrix containing only the specified number of nearest neighbors.
#'
#' @param A An adjacency matrix representing the graph.
#' @param k An integer specifying the number of neighbors to consider (default: 5).
#' @param type A character string indicating the type of k-nearest neighbors graph to compute. One of "normal" or "mutual" (default: "normal").
#' @param ncores An integer specifying the number of cores to use for parallel computation (default: 1).
#'
#' @return A sparse adjacency matrix containing only the specified number of nearest neighbors.
#'
#' @examples
#' A <- matrix(runif(100), 10, 10)
#' A_thresholded <- threshold_adjacency(A, k = 5)
#'
#' @importFrom assertthat assert_that
#' @importFrom parallel mclapply
#' @importFrom Matrix sparseMatrix
#' @export
threshold_adjacency <- function(A, k = 5,
                                type = c("normal", "mutual"),
                                ncores = 1) {
  assertthat::assert_that(k > 0, k <= nrow(A))
  type <- match.arg(type)
  stopifnot(is.numeric(ncores), length(ncores) == 1, ncores >= 1)
  ncores <- as.integer(ncores)
  if (.Platform$OS.type == "windows") ncores <- 1L

  rows <- parallel::mclapply(seq_len(nrow(A)), mc.cores = ncores, function(i) {
    ord <- utils::head(order(A[i, ], decreasing = TRUE), k)
    cbind(i = i, j = ord, x = A[i, ord])
  })
  rows <- do.call(rbind, rows)

  m <- Matrix::sparseMatrix(i = rows[, 1], j = rows[, 2], x = rows[, 3],
                            dims = dim(A))

  psparse(m, if (type == "normal") pmax else pmin)
}


#' Cross Adjacency
#'
#' This function computes the cross adjacency matrix or graph between two sets of points
#' based on their k-nearest neighbors and a kernel function applied to their distances.
#'
#' @param X A matrix of size nXk, where n is the number of data points and k is the dimensionality of the feature space.
#' @param Y A matrix of size pXk, where p is the number of query points and k is the dimensionality of the feature space.
#' @param k An integer indicating the number of nearest neighbors to consider (default: 5).
#' @param FUN A kernel function to apply to the Euclidean distances between data points (default: heat_kernel).
#' @param type A character string indicating the type of adjacency to compute. One of "normal", "mutual", or "asym" (default: "normal").
#' @param as A character string indicating the format of the output. One of "igraph", "sparse", or "index_sim" (default: "igraph").
#'
#' @details
#' Distances passed to `FUN` are Euclidean distances. With `backend="hnsw"`,
#' squared L2 distances from `RcppHNSW` are converted back to Euclidean
#' distances before weighting.
#'
#' @param backend Nearest-neighbor backend. `"nanoflann"` uses exact Euclidean
#'   search; `"hnsw"` uses approximate search via `RcppHNSW`.
#' @param M,ef HNSW tuning parameters used only when `backend="hnsw"`.
#'
#' @return If 'as' is "index_sim", a two-column matrix where the first column contains the indices of nearest neighbors and the second column contains the corresponding kernel values.
#'         If 'as' is "igraph", an igraph object representing the cross adjacency graph.
#'         If 'as' is "sparse", a sparse adjacency matrix.
#' @export
#' @examples
#' X <- matrix(rnorm(6), ncol=2)
#' Y <- matrix(rnorm(8), ncol=2)
#' cross_adjacency(X, Y, k=1, as="sparse")
cross_adjacency <- function(X, Y, k = 5, FUN = heat_kernel,
                            type = c("normal", "mutual", "asym"),
                            as   = c("igraph", "sparse", "index_sim"),
                            backend = c("nanoflann", "hnsw"),
                            M = 16, ef = 200) {

  stopifnot(k > 0, k <= nrow(X))
  stopifnot(ncol(X) == ncol(Y))
  type <- match.arg(type)
  as   <- match.arg(as)
  backend <- match.arg(backend)

  nn_result <- knn_search_euclidean(X, Y, k = k, backend = backend, M = M, ef = ef)
  idx <- nn_result$indices
  dst <- nn_result$distances

  sim <- FUN(dst)

  if (as == "index_sim")
    return(cbind(as.vector(idx), as.vector(sim)))

  W <- indices_to_sparse(idx, sim,
                         idim = nrow(Y),
                         jdim = nrow(X))

  # For non-square matrices (cross-adjacency), return sparse matrix directly
  if (nrow(Y) != nrow(X)) {
    if (as == "sparse") {
      return(W)
    } else if (as == "igraph") {
      stop("igraph output not supported for non-square cross-adjacency (nrow(X) != nrow(Y)). Use as='sparse' instead.")
    }
  }

  W <- symmetrize_knn_sparse(W, type)

  if (as == "sparse") {
    W
  } else {
    igraph::graph_from_adjacency_matrix(
      W,
      weighted = TRUE,
      mode = if (type == "asym") "directed" else "undirected"
    )
  }
}

#' Weighted k-Nearest Neighbors
#'
#' This function computes a weighted k-nearest neighbors graph or adjacency matrix from a data matrix.
#' The function takes into account the Euclidean distance between instances and applies a kernel function
#' to convert the distances into similarities.
#'
#' @param X A data matrix where rows are instances and columns are features.
#' @param k An integer specifying the number of nearest neighbors to consider (default: 5).
#' @param FUN A kernel function used to convert Euclidean distances into similarities (default: heat_kernel).
#' @param type A character string indicating the type of k-nearest neighbors graph to compute. One of "normal", "mutual", or "asym" (default: "normal").
#' @param as A character string specifying the format of the output. One of "igraph" or "sparse" (default: "igraph").
#' @param ... Additional arguments passed to the nearest neighbor search function (Rnanoflann::nn).
#'
#' @details
#' Distances passed to `FUN` are Euclidean distances. With `backend="hnsw"`,
#' squared L2 distances from `RcppHNSW` are converted back to Euclidean
#' distances before weighting.
#'
#' @param backend Nearest-neighbor backend. `"nanoflann"` uses exact Euclidean
#'   search; `"hnsw"` uses approximate search via `RcppHNSW`.
#' @param M,ef HNSW tuning parameters used only when `backend="hnsw"`.
#'
#' @return If 'as' is "igraph", an igraph object representing the weighted k-nearest neighbors graph.
#'         If 'as' is "sparse", a sparse adjacency matrix.
#'
#' @examples
#' X <- matrix(rnorm(10 * 10), 10, 10)
#' w <- weighted_knn(X, k = 5)
#'
#' @importFrom assertthat assert_that
#' @importFrom igraph graph_from_adjacency_matrix as_adjacency_matrix
#' @importFrom Matrix sparseMatrix
#' @importFrom Rnanoflann nn
#' @export
weighted_knn <- function(X, k = 5, FUN = heat_kernel,
                         type = c("normal", "mutual", "asym"),
                         as   = c("igraph", "sparse"),
                         backend = c("nanoflann", "hnsw"),
                         M = 16, ef = 200, ...) {

  stopifnot(k > 0, k <= nrow(X))
  type <- match.arg(type)
  as   <- match.arg(as)
  backend <- match.arg(backend)

  nn_result <- knn_search_euclidean(
    X, X,
    k = k,
    backend = backend,
    drop_first = TRUE,
    M = M,
    ef = ef,
    ...
  )
  idx <- nn_result$indices
  dst <- nn_result$distances

  W <- indices_to_sparse(idx, FUN(dst), idim = nrow(X), jdim = nrow(X))
  W <- symmetrize_knn_sparse(W, type)

  if (as == "sparse") {
    W
  } else {
    igraph::graph_from_adjacency_matrix(
      W,
      weighted = TRUE,
      mode = if (type == "asym") "directed" else "undirected"
    )
  }
}

#' Apply a Function to Non-Zero Elements in a Sparse Matrix
#'
#' This function applies a specified function (e.g., max) to each pair of non-zero elements in a sparse matrix.
#' It can return the result as a triplet representation or a sparse matrix.
#'
#' @param M A sparse matrix object from the Matrix package.
#' @param FUN A function to apply to each pair of non-zero elements in the sparse matrix.
#' @param return_triplet A logical value indicating whether to return the result as a triplet representation. Default is FALSE.
#'
#' @return If return_triplet is TRUE, a matrix containing the i, j, and x values in the triplet format; otherwise, a sparse matrix with the updated values.
#'
#' @importFrom Matrix which
#' @importFrom Matrix sparseMatrix
#' @examples
#' library(Matrix)
#' M <- sparseMatrix(i = c(1, 3, 1), j = c(2, 3, 3), x = c(1, 2, 3))
#' psparse_max <- psparse(M, FUN = max)
#' psparse_sum_triplet <- psparse(M, FUN = `+`, return_triplet = TRUE)
#' @export
psparse <- function(M, FUN, return_triplet = FALSE) {
  if (!inherits(M, "dgTMatrix")) M <- as(M, "TsparseMatrix")

  tri <- cbind(i = M@i + 1L, j = M@j + 1L, x = M@x)
  tri_sym <- tri[tri[, 1] < tri[, 2], , drop = FALSE]

  if (nrow(tri_sym) == 0) {
    # No off-diagonal elements to process
    if (return_triplet) return(tri)
    return(M)
  }

  # Fixed: Proper row-wise matching using vectorized lookup
  # Create lookup for (i,j) -> position in tri
  tri_lookup <- paste(tri[, 1], tri[, 2], sep = ",")
  target_lookup <- paste(tri_sym[, 2], tri_sym[, 1], sep = ",")  # Reversed pairs
  
  # Find positions of reversed pairs
  match_indices <- match(target_lookup, tri_lookup)
  
  # Handle case where some reversed pairs don't exist (asymmetric matrix)
  valid_matches <- !is.na(match_indices)
  
  if (sum(valid_matches) == 0) {
    # No symmetric pairs found - return original matrix
    if (return_triplet) return(tri)
    return(M)
  }
  
  # Only process valid symmetric pairs
  valid_tri_sym <- tri_sym[valid_matches, , drop = FALSE]
  valid_match_indices <- match_indices[valid_matches]

  new_x <- FUN(
    valid_tri_sym[, 3],
    M@x[valid_match_indices]
  )

  out_tri <- rbind(
    cbind(i = valid_tri_sym[, 1], j = valid_tri_sym[, 2], x = new_x),
    cbind(i = valid_tri_sym[, 2], j = valid_tri_sym[, 1], x = new_x)
  )

  # Add back the diagonal and unmatched elements
  processed_positions <- c(which(tri[,1] < tri[,2])[valid_matches], valid_match_indices)
  unprocessed_mask <- !(seq_len(nrow(tri)) %in% processed_positions)
  diag_and_unmatched <- tri[unprocessed_mask, , drop = FALSE]
  
  if (nrow(diag_and_unmatched) > 0) {
    out_tri <- rbind(out_tri, diag_and_unmatched)
  }

  if (return_triplet) return(out_tri)

  triplet_to_matrix(out_tri, dim(M))
}
