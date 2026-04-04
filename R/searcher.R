#' Nearest Neighbor Searcher
#'
#' Create a nearest neighbor searcher object for efficient nearest neighbor search.
#' Uses Rnanoflann (exact Euclidean search) by default, or RcppHNSW (approximate search
#' with cosine/inner-product support) when those distance metrics are requested.
#'
#' @param X A numeric matrix where each row represents a data point.
#' @param labels A vector of labels corresponding to each row in X. Defaults to row indices.
#' @param ... Additional arguments (currently unused).
#' @param distance The distance metric to use. One of "l2", "euclidean", "cosine", or "ip".
#'   Note: "cosine" and "ip" require the RcppHNSW package.
#' @param M The maximum number of connections for HNSW (only used with cosine/ip).
#' @param ef The size of the dynamic candidate list for HNSW (only used with cosine/ip).
#'
#' @return An object of class "nnsearcher" containing the data matrix, labels,
#'   search index, and search parameters.
#'
#' @examples
#' \donttest{
#' X <- matrix(rnorm(100), nrow=10, ncol=10)
#' searcher <- nnsearcher(X)
#' }
#'
#' @importFrom chk chk_matrix chk_numeric
#' @export
nnsearcher <- function(X, labels=1:nrow(X), ...,
                       distance=c("l2", "euclidean", "cosine", "ip"), M=16, ef=200) {
  distance <- match.arg(distance)
  X <- as.matrix(X)

  # Validation checks
  stopifnot(
    "Number of labels must equal the number of rows in the data matrix 'X'" =
      length(labels) == nrow(X)
  )
  if (anyNA(labels)) {
    stop("NA values are not permitted in 'labels'.", call. = FALSE)
  }

  # Determine backend: use Rnanoflann for Euclidean, RcppHNSW for cosine/ip
  use_hnsw <- distance %in% c("cosine", "ip")


  if (use_hnsw) {
    if (!requireNamespace("RcppHNSW", quietly = TRUE)) {
      stop("RcppHNSW package is required for '", distance, "' distance metric. ",
           "Install it with: install.packages('RcppHNSW')", call. = FALSE)
    }
    ann <- RcppHNSW::hnsw_build(X, distance, ef=ef, M=M)
    backend <- "hnsw"
  } else {
    # Rnanoflann uses Euclidean distance (stores data for queries)
    ann <- NULL
    backend <- "nanoflann"
  }

  structure(list(
    X=X,
    labels=labels,
    ann=ann,
    distance=distance,
    ef=ef,
    M=M,
    backend=backend),
    class="nnsearcher")
}

#' Convert Search Results for nnsearcher Objects
#'
#' Convert raw search results to a standardized format for nnsearcher objects.
#'
#' @param x An object of class "nnsearcher".
#' @param result A raw result object from nearest neighbor search.
#'
#' @return An object of class "nn_search" with standardized field names.
#'
#' @examples
#' res <- list(idx = matrix(c(1L,2L), nrow=1),
#'             dist = matrix(c(0.1,0.2), nrow=1))
#' dummy <- nnsearcher(matrix(rnorm(4), nrow=2))
#' search_result(dummy, res)
#' @method search_result nnsearcher
#' @export
search_result.nnsearcher <- function(x, result) {
  # Map field names to public API standard
  result$indices <- result$idx
  result$distances <- result$dist
  result$idx <- NULL      # Remove internal names
  result$dist <- NULL
  
  attr(result, "len") <- ncol(x$X)
  attr(result, "metric") <- x$distance
  class(result) <- "nn_search"
  result
}

#' Convert Distance to Similarity for nn_search Objects
#'
#' Convert distance values in a nearest neighbor search result to similarity values.
#'
#' @param x An object of class "nn_search".
#' @param method The transformation method for converting distances to similarities.
#' @param sigma The bandwidth parameter for the heat kernel method.
#' @param ... Additional arguments (currently ignored).
#'
#' @return The modified nn_search object with distances converted to similarities.
#'
#' @examples
#' res <- list(indices = matrix(c(1L,2L), nrow=1),
#'             distances = matrix(c(0.5, 1.0), nrow=1))
#' class(res) <- "nn_search"; attr(res,"len") <- 2; attr(res,"metric") <- "l2"
#' dist_to_sim(res, method="heat", sigma=1)
#' @method dist_to_sim nn_search
#' @export
dist_to_sim.nn_search <- function(x, method = c("heat", "binary", "normalized", "cosine", "correlation"), sigma=1, ...) {
  method <- match.arg(method)
  len <- attr(x, "len")
  fun <- get_neighbor_fun(method, len, sigma)
  x$distances <- fun(x$distances)
  x
}


#' Convert Distance to Similarity for Matrix Objects
#'
#' Convert distance values in a sparse Matrix to similarity values.
#'
#' @param x A Matrix object containing distances.
#' @param method The transformation method for converting distances to similarities.
#' @param sigma The bandwidth parameter for the heat kernel method.
#' @param len The length parameter used in transformation calculations.
#' @param ... Additional arguments (currently ignored).
#'
#' @return The Matrix object with distances converted to similarities.
#'
#' @examples
#' m <- Matrix::Matrix(c(0,1,2,0), nrow=2, sparse=TRUE)
#' dist_to_sim(m, method="heat", sigma=1)
#' @method dist_to_sim Matrix
#' @export
dist_to_sim.Matrix <- function(x, method = c("heat", "binary", "normalized", "cosine", "correlation"), sigma=1, len=1, ...) {
  method <- match.arg(method)
  fun <- get_neighbor_fun(method, len, sigma)

  wh <- which(x != 0)
  v <- fun(x[wh])
  x[wh] <- v
  x
}

#' Create Adjacency Matrix from nnsearch Object
#'
#' Convert a nearest neighbor search result to a sparse adjacency matrix.
#'
#' @param x An object of class "nnsearch".
#' @param idim The number of rows in the resulting matrix.
#' @param jdim The number of columns in the resulting matrix.
#' @param return_triplet Logical; whether to return triplet format.
#' @param ... Additional arguments (currently ignored).
#'
#' @return A sparse Matrix representing the adjacency matrix.
#'
#' @examples
#' res <- list(indices = matrix(c(2L,1L), nrow=2),
#'             distances = matrix(c(0.1,0.2), nrow=2))
#' class(res) <- "nn_search"
#' attr(res,"len") <- 2; attr(res,"metric") <- "l2"
#' adjacency(res, idim=2, jdim=2)
#' @method adjacency nn_search
#' @export
adjacency.nn_search <- function(x, idim=nrow(x$indices), jdim=max(x$indices), return_triplet=FALSE, ...) {
  indices_to_sparse(as.matrix(x$indices), as.matrix(x$distances), return_triplet=return_triplet, idim=idim, jdim=jdim)
}


#' Find Nearest Neighbors Using nnsearcher
#'
#' Search for the k nearest neighbors using a pre-built nnsearcher object.
#'
#' @param x An object of class "nnsearcher".
#' @param query A matrix of query points. If NULL, searches within the original data.
#' @param k The number of nearest neighbors to find.
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "nn_search" containing indices, distances, and labels.
#'
#' @examples
#' \donttest{
#' X <- matrix(rnorm(100), nrow=10, ncol=10)
#' searcher <- nnsearcher(X)
#' result <- find_nn(searcher, k=3)
#' }
#' 
#' @method find_nn nnsearcher
#' @export
find_nn.nnsearcher <- function(x, query=NULL, k=5, ...) {
  if (x$backend == "hnsw") {
    ret <- if (!is.null(query)) {
      chk_matrix(query)
      RcppHNSW::hnsw_search(query, x$ann, k = k)
    } else {
      RcppHNSW::hnsw_search(x$X, x$ann, k = k)
    }
  } else {
    # nanoflann backend
    points <- if (!is.null(query)) {
      chk_matrix(query)
      query
    } else {
      x$X
    }
    nn_result <- Rnanoflann::nn(data = x$X, points = points, k = k)
    # Match the public API used by the HNSW backend: distances are Euclidean.
    ret <- list(idx = nn_result$indices, dist = nn_result$distances)
  }

  # Vectorized label lookup using matrix indexing
  ret$labels <- matrix(x$labels[ret$idx], nrow = nrow(ret$idx), ncol = ncol(ret$idx))
  search_result(x, ret)
}

#' Find Nearest Neighbors Among Subset Using nnsearcher
#'
#' Search for the k nearest neighbors within a specified subset of points.
#'
#' @param x An object of class "nnsearcher".
#' @param k The number of nearest neighbors to find.
#' @param idx A numeric vector specifying the subset of point indices to search among.
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "nn_search" containing indices, distances, and labels.
#' @examples
#' \donttest{
#' X <- matrix(rnorm(20), nrow=5)
#' searcher <- nnsearcher(X)
#' find_nn_among(searcher, k=2, idx=1:3)
#' }
#'
#' @method find_nn_among nnsearcher
#' @export
find_nn_among.nnsearcher <- function(x, k=5, idx, ...) {
  chk_numeric(idx)

  X1 <- x$X[idx, , drop=FALSE]

  if (x$backend == "hnsw") {
    ann <- RcppHNSW::hnsw_build(X1, x$distance, M=x$M, ef=x$ef)
    nnres <- RcppHNSW::hnsw_search(X1, ann, k=k)
  } else {
    nn_result <- Rnanoflann::nn(data = X1, points = X1, k = k)
    nnres <- list(idx = nn_result$indices, dist = nn_result$distances)
  }

  search_result(x, nnres)
}

#' Find Nearest Neighbors Among Classes
#'
#' Find the nearest neighbors within each class for a class_graph object.
#'
#' @param x A class_graph object.
#' @param X The data matrix corresponding to the graph nodes.
#' @param k The number of nearest neighbors to find.
#' @param ... Additional arguments (currently unused).
#'
#' @return A search result object containing indices, distances, and labels.
#' @examples
#' \donttest{
#' labs <- factor(c("a","a","b","b"))
#' cg <- class_graph(labs)
#' X <- matrix(rnorm(12), nrow=4)
#' find_nn_among(cg, X, k=1)
#' }
#'
#' @method find_nn_among class_graph
#' @export
find_nn_among.class_graph <- function(x, X, k=5, ...) {
  searcher <- nnsearcher(X, x$labels)
  ret <- lapply(x$class_indices, function(ind) {
    nnr <- find_nn_among.nnsearcher(searcher, k=k, ind)
    # Vectorized: map local indices back to original indices
    nnr$indices <- matrix(ind[nnr$indices], nrow = nrow(nnr$indices), ncol = ncol(nnr$indices))
    # Vectorized label lookup
    nnr$labels <- matrix(x$labels[nnr$indices], nrow = nrow(nnr$indices), ncol = ncol(nnr$indices))
    nnr
  })

  indices <- do.call(rbind, lapply(ret, "[[", "indices"))
  distances <- do.call(rbind, lapply(ret, "[[", "distances"))
  labels <- do.call(rbind, lapply(ret, "[[", "labels"))
  search_result(searcher, list(idx=indices, dist=distances, labels=labels))
}

#' Find Nearest Neighbors Between Two Sets Using nnsearcher
#'
#' Search for the k nearest neighbors from one set of points to another set.
#'
#' @param x An object of class "nnsearcher".
#' @param k The number of nearest neighbors to find.
#' @param idx1 A numeric vector specifying indices of the first set of points.
#' @param idx2 A numeric vector specifying indices of the second set of points.
#' @param restricted Logical; if TRUE, use restricted search mode.
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "nn_search" containing indices, distances, and labels.
#'
#' @examples
#' \donttest{
#' X <- matrix(rnorm(40), nrow=10)
#' searcher <- nnsearcher(X)
#' find_nn_between(searcher, k=2, idx1=1:5, idx2=6:10)
#' }
#' @method find_nn_between nnsearcher
#' @export
find_nn_between.nnsearcher <- function(x, k=5, idx1, idx2, restricted=FALSE, ...) {
  chk_numeric(idx1)
  chk_numeric(idx2)

  if (!restricted) {
    X1 <- x$X[idx1, , drop = FALSE]
    X2 <- x$X[idx2, , drop = FALSE]

    if (x$backend == "hnsw") {
      ann <- RcppHNSW::hnsw_build(X1, x$distance, M=x$M, ef=x$ef)
      nnres <- RcppHNSW::hnsw_search(X2, ann, k=k)
    } else {
      nn_result <- Rnanoflann::nn(data = X1, points = X2, k = k)
      nnres <- list(idx = nn_result$indices, dist = nn_result$distances)
    }

    # Vectorized: map local indices back to original indices
    nnres$idx <- matrix(idx1[nnres$idx], nrow = nrow(nnres$idx), ncol = ncol(nnres$idx))
    # Vectorized label lookup
    nnres$labels <- matrix(x$labels[nnres$idx], nrow = nrow(nnres$idx), ncol = ncol(nnres$idx))
    search_result(x, nnres)
  } else {
    find_nn.nnsearcher(x, x$X[idx2, , drop = FALSE], k = k)
  }
}

#' Create Neighbor Graph from nnsearcher Object
#'
#' Construct a neighbor graph from nearest neighbor search results.
#'
#' @param x An object of class "nnsearcher".
#' @param query A matrix of query points. If NULL, uses original data.
#' @param k The number of nearest neighbors to find.
#' @param type The type of graph construction method.
#' @param transform The transformation method for converting distances to weights.
#' @param sigma The bandwidth parameter for the transformation.
#' @param ... Additional arguments (currently unused).
#'
#' @return A neighbor_graph object representing the constructed graph.
#' @examples
#' \donttest{
#' X <- matrix(rnorm(20), nrow=5)
#' searcher <- nnsearcher(X)
#' neighbor_graph(searcher, k=2, type="normal", transform="heat", sigma=1)
#' }
#'
#' @method neighbor_graph nnsearcher
#' @export
neighbor_graph.nnsearcher <- function(x, query=NULL, k=5, type=c("normal", "asym", "mutual"),
                                      transform=c("heat", "binary", "euclidean",
                                                  "normalized", "cosine", "correlation"), sigma=1, ...) {
  type <- match.arg(type)
  transform <- match.arg(transform)

 # Search for k+1 neighbors to exclude self (first column)
  nn <- find_nn.nnsearcher(x, k = k + 1)

  # Use correct field names (indices/distances) and exclude self-neighbor (column 1)
  nni <- nn$indices[, 2:ncol(nn$indices), drop = FALSE]
  D <- nn$distances[, 2:ncol(nn$distances), drop = FALSE]

  hfun <- get_neighbor_fun(transform, len = ncol(x$X), sigma = sigma)
  hval <- hfun(D)

  W <- indices_to_sparse(nni, hval, idim = nrow(x$X), jdim = nrow(x$X))

  gg <- switch(type,
    normal = igraph::graph_from_adjacency_matrix(W, weighted = TRUE, mode = "max"),
    mutual = igraph::graph_from_adjacency_matrix(W, weighted = TRUE, mode = "min"),
    asym   = igraph::graph_from_adjacency_matrix(W, weighted = TRUE, mode = "directed")
  )

  neighbor_graph(gg, params = list(k = k,
                                   transform = transform,
                                   sigma = sigma,
                                   type = type,
                                   labels = x$labels))
}
