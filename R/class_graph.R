#' Construct a Class Graph
#'
#' A graph in which members of the same class have edges.
#'
#' @param labels A vector of class labels.
#' @param sparse A logical value, indicating whether to use sparse matrices in the computation. Default is TRUE.
#'
#' @return A class_graph object, which is a list containing the following components:
#' \describe{
#'   \item{adjacency}{A matrix representing the adjacency of the graph.}
#'   \item{params}{A list of parameters used in the construction of the graph.}
#'   \item{labels}{A vector of class labels.}
#'   \item{class_indices}{A list of vectors, each containing the indices of elements belonging to a specific class.}
#'   \item{class_freq}{A table of frequencies for each class.}
#'   \item{levels}{A vector of unique class labels.}
#'   \item{classes}{A character string indicating the type of graph ("class_graph").}
#' }
#'
#' @importFrom Matrix sparseMatrix tcrossprod
#'
#' @examples
#' data(iris)
#' labels <- iris[,5]
#' cg <- class_graph(labels)
#'
#' @export
class_graph <- function(labels, sparse = TRUE) {
  labels <- as.factor(labels)
  n <- length(labels)
  lvls <- levels(labels)

  if (sparse) {
    # Efficient sparse construction using indicator matrix

    # Create sparse indicator matrix (n x k) where k = number of classes
    # Then compute tcrossprod to get n x n class adjacency
    label_int <- as.integer(labels)
    indicator <- Matrix::sparseMatrix(
      i = seq_len(n),
      j = label_int,
      x = rep(1, n),
      dims = c(n, length(lvls))
    )
    out <- Matrix::tcrossprod(indicator)
  } else {
    # Dense version
    indicator <- model.matrix(~ labels - 1)
    out <- tcrossprod(indicator)
  }

  ret <- neighbor_graph(
    out,
    params = list(weight_mode = "binary", neighbor_mode = "supervised"),
    labels = labels,
    class_indices = split(seq_len(n), labels),
    class_freq = table(labels),
    levels = lvls,
    classes = "class_graph"
  )

  ret
}



#' Number of Classes for class_graph Objects
#'
#' Compute the number of classes in a class_graph object.
#'
#' @param x A class_graph object.
#'
#' @return The number of classes in the class_graph.
#'
#' @examples
#' labs <- factor(c("a","a","b"))
#' cg <- class_graph(labs)
#' nclasses(cg)
#' @method nclasses class_graph
#' @export
nclasses.class_graph <- function(x) {
  length(x$levels)
}


#' Class Means for class_graph Objects
#'
#' Compute the mean of each class for a class_graph object.
#'
#' @param x A class_graph object.
#' @param X The data matrix corresponding to the graph nodes.
#' @param ... Additional arguments (currently ignored).
#'
#' @return A matrix where each row represents the mean values for each class.
#'
#' @examples
#' labs <- factor(c("a","a","b"))
#' cg <- class_graph(labs)
#' class_means(cg, matrix(1:9, nrow=3))
#' @method class_means class_graph
#' @export
class_means.class_graph <- function(x, X, ...) {
  ret <- do.call(rbind, lapply(x$class_indices, function(i) {
    colMeans(X[i,,drop=FALSE])
  }))

  row.names(ret) <- names(x$class_indices)
  ret
}


#' Heterogeneous Neighbors for class_graph Objects
#'
#' Compute the neighbors between different classes for a class_graph object.
#'
#' @param x A class_graph object.
#' @param X The data matrix corresponding to the graph nodes.
#' @param k The number of nearest neighbors to find.
#' @param weight_mode Method for weighting edges (e.g., "heat", "binary", "euclidean").
#' @param sigma Scaling factor for heat kernel if `weight_mode="heat"`.
#' @param ... Additional arguments passed to weight function.
#'
#' @return A neighbor_graph object representing the between-class neighbors.
#' @importFrom Matrix sparseMatrix
#' @examples
#' labs <- factor(c("a","a","b","b"))
#' cg <- class_graph(labs)
#' X <- matrix(rnorm(8), ncol=2)
#' heterogeneous_neighbors(cg, X, k=1)
#' @export
heterogeneous_neighbors <- function(x, X, k, weight_mode = "heat", sigma = 1, ...) {
  N <- nrow(X)
  all_indices <- seq_len(N)
  class_indices <- x$class_indices
  all_triplets <- vector("list", length(class_indices))

  weight_fun <- get_neighbor_fun(weight_mode, sigma = sigma, ...)

  for (idx in seq_along(class_indices)) {
    lev <- names(class_indices)[idx]
    query_idx <- class_indices[[lev]]
    # Get indices of points NOT in this class
    data_idx <- setdiff(all_indices, query_idx)

    if (length(data_idx) == 0 || length(query_idx) == 0) next

    # Adjust k if fewer points available than requested
    actual_k <- min(k, length(data_idx))
    if (actual_k == 0) next

    knn_result <- Rnanoflann::nn(
      data = X[data_idx, , drop = FALSE],
      points = X[query_idx, , drop = FALSE],
      k = actual_k
    )

    weights <- weight_fun(knn_result$distances)

    # Row indices: each query point repeated actual_k times (column-major flattening)
    row_indices_orig <- rep(query_idx, times = actual_k)
    # Column indices: map indices back to original indices
    col_indices_orig <- data_idx[as.vector(knn_result$indices)]

    # Use matrix instead of data.frame for efficiency
    all_triplets[[idx]] <- cbind(
      i = row_indices_orig,
      j = col_indices_orig,
      weight = as.vector(weights)
    )
  }

  # Remove NULL entries
  all_triplets <- all_triplets[!vapply(all_triplets, is.null, logical(1))]

  if (length(all_triplets) == 0) {
    adj <- Matrix::sparseMatrix(i = integer(0), j = integer(0), dims = c(N, N))
  } else {
    final_triplets <- do.call(rbind, all_triplets)

    adj <- Matrix::sparseMatrix(
      i = final_triplets[, "i"],
      j = final_triplets[, "j"],
      x = final_triplets[, "weight"],
      dims = c(N, N)
    )
    # Make symmetric - choose max weight for shared edges
    adj <- pmax(adj, Matrix::t(adj))
  }

  neighbor_graph(adj, params = list(weight_mode = weight_mode, neighbor_mode = "heterogeneous", k = k, sigma = sigma))
}

#' Homogeneous Neighbors for class_graph Objects
#'
#' Compute the neighbors within the same class for a class_graph object.
#'
#' @param x A class_graph object.
#' @param X The data matrix corresponding to the graph nodes.
#' @param k The number of nearest neighbors to find.
#' @param weight_mode Method for weighting edges (e.g., "heat", "binary", "euclidean").
#' @param sigma Scaling factor for heat kernel if `weight_mode="heat"`.
#' @param ... Additional arguments passed to weight function.
#'
#' @return A neighbor_graph object representing the within-class neighbors.
#' @importFrom Matrix sparseMatrix
#' @examples
#' labs <- factor(c("a","a","b","b"))
#' cg <- class_graph(labs)
#' X <- matrix(rnorm(8), ncol=2)
#' homogeneous_neighbors(cg, X, k=1)
#' @export
homogeneous_neighbors <- function(x, X, k, weight_mode = "heat", sigma = 1, ...) {
  class_indices <- x$class_indices
  all_triplets <- vector("list", length(class_indices))
  N <- nrow(X)

  weight_fun <- get_neighbor_fun(weight_mode, sigma = sigma, ...)

  for (idx in seq_along(class_indices)) {
    lev <- names(class_indices)[idx]
    idx_subset <- class_indices[[lev]]
    n_subset <- length(idx_subset)

    # Need at least 2 points to find neighbors (can't be neighbor of yourself)
    if (n_subset <= 1) next

    # Adjust k if class is smaller than requested k
    actual_k <- min(k, n_subset - 1)

    # Request k+1 neighbors to exclude self (first column).
    X_subset <- X[idx_subset, , drop = FALSE]
    knn_result <- Rnanoflann::nn(data = X_subset, points = X_subset, k = actual_k + 1L)

    # Exclude self-neighbor (first column)
    nn_indices <- knn_result$indices[, -1, drop = FALSE]
    nn_distances <- knn_result$distances[, -1, drop = FALSE]

    weights <- weight_fun(nn_distances)

    # Row indices within the subset (repeated k times for column-major flattening)
    row_indices_subset <- rep(seq_len(n_subset), times = actual_k)
    # Column indices within the subset (from indices, flattened column-major)
    col_indices_subset <- as.vector(nn_indices)

    # Map back to original indices
    row_indices_orig <- idx_subset[row_indices_subset]
    col_indices_orig <- idx_subset[col_indices_subset]

    # Use matrix instead of data.frame for efficiency
    all_triplets[[idx]] <- cbind(
      i = row_indices_orig,
      j = col_indices_orig,
      weight = as.vector(weights)
    )
  }

  # Remove NULL entries
  all_triplets <- all_triplets[!vapply(all_triplets, is.null, logical(1))]

  if (length(all_triplets) == 0) {
    adj <- Matrix::sparseMatrix(i = integer(0), j = integer(0), dims = c(N, N))
  } else {
    final_triplets <- do.call(rbind, all_triplets)

    adj <- Matrix::sparseMatrix(
      i = final_triplets[, "i"],
      j = final_triplets[, "j"],
      x = final_triplets[, "weight"],
      dims = c(N, N)
    )
    # Make symmetric: take the max weight if edge (i,j) and (j,i) both exist
    adj <- pmax(adj, Matrix::t(adj))
  }

  neighbor_graph(adj, params = list(weight_mode = weight_mode, neighbor_mode = "homogeneous", k = k, sigma = sigma))
}


#' Within-Class Neighbors for class_graph Objects
#'
#' Compute the within-class neighbors of a class_graph object.
#'
#' @param x A class_graph object.
#' @param ng A neighbor graph object.
#' @param ... Additional arguments (currently ignored).
#'
#' @return A neighbor_graph object representing the within-class neighbors of the input class_graph.
#'
#' @examples
#' labs <- factor(c("a","a","b"))
#' cg <- class_graph(labs)
#' ng <- neighbor_graph(matrix(c(0,1,0,1,0,0,0,0,0),3))
#' within_class_neighbors(cg, ng)
#' @method within_class_neighbors class_graph
#' @export
within_class_neighbors.class_graph <- function(x, ng, ...) {
  Ac <- adjacency(x)
  An <- adjacency(ng)
  Aout <- Ac * An
  neighbor_graph(Aout)
}


#' Between-Class Neighbors for class_graph Objects
#'
#' Compute the between-class neighbors of a class_graph object.
#'
#' @param x A class_graph object.
#' @param ng A neighbor_graph object.
#' @param ... Additional arguments (currently ignored).
#'
#' @return A neighbor_graph object representing the between-class neighbors.
#'
#' @examples
#' labs <- factor(c("a","a","b"))
#' cg <- class_graph(labs)
#' ng <- neighbor_graph(matrix(c(0,1,1,1,0,1,1,1,0),3))
#' between_class_neighbors(cg, ng)
#'
#' @method between_class_neighbors class_graph
#' @export
between_class_neighbors.class_graph <- function(x, ng, ...) {
  Ac <- adjacency(x)
  An <- adjacency(ng)
  # Compute edges in An that are NOT in class graph (between-class)

  # This is equivalent to An * (!Ac) but avoids creating dense matrix
  # An - (Ac * An) keeps only edges where Ac is 0
  Aout <- An - (Ac * An)
  neighbor_graph(Aout)
}


#' Compute Discriminating Distance for Similarity Graph
#'
#' This function computes a discriminating distance matrix for the similarity graph based on the class labels.
#' It adjusts the similarity graph by modifying the weights within and between classes, making it more suitable for
#' tasks like classification and clustering.
#'
#' @param X A numeric matrix or data frame containing the data points.
#' @param labels A factor or numeric vector containing the class labels for each data point.
#' @param k An integer representing the number of nearest neighbors to consider. Default is half the number of samples.
#' @param sigma A numeric value representing the scaling factor for the heat kernel. If not provided, it will be estimated.
#'
#' @return A discriminating distance matrix in the form of a sparse matrix.
#'
#' @examples
#' \donttest{
#' X <- matrix(rnorm(100*100), 100, 100)
#' labels <- factor(rep(1:5, each=20))
#' sigma <- 0.7
#' D <- discriminating_distance(X, labels, k=length(labels)/2, sigma=sigma)
#' }
#'
#' @export
discriminating_distance <- function(X, labels, k = NULL, sigma = NULL) {
  if (is.null(k)) {
    k <- floor(length(labels) / 2)
  }

  if (is.null(sigma)) {
    sigma <- estimate_sigma(X, prop = 0.1)
  }

  Wall <- graph_weights(X, k = k, weight_mode = "euclidean", neighbor_mode = "knn")
  Wall <- adjacency(Wall)

  Ww <- diagonal_label_matrix(labels, labels)
  Wb <- diagonal_label_matrix(labels, labels, type = "d")

  Ww2 <- Wall * Ww
  Wb2 <- Wall * Wb

  wind <- which(Ww2 > 0)
  bind <- which(Wb2 > 0)

  hw <- inverse_heat_kernel(Wall[wind], sigma)
  hb <- inverse_heat_kernel(Wall[bind], sigma)

  # Discriminating transformation:
  # Within-class: reduce distance (multiply by factor < 1 when hw < 1)
  # Between-class: increase distance (multiply by factor > 1)
  Wall[wind] <- pmax(0, hw * (1 - hw))  # Clamp to non-negative

  Wall[bind] <- hb * (1 + hb)
  Wall
}

#' Compute Similarity Graph Weighted by Class Structure
#'
#' This function computes a similarity graph that is weighted by the class structure of the data.
#' It is useful for preserving the local similarity and diversity within the data, making it
#' suitable for tasks like face and handwriting digits recognition.
#'
#' @param X A numeric matrix or data frame containing the data points.
#' @param k An integer representing the number of nearest neighbors to consider.
#' @param sigma A numeric value representing the scaling factor for the heat kernel.
#' @param cg A class_graph object computed from the labels.
#' @param threshold A numeric value representing the threshold for the class graph. Default is 0.01.
#'
#' @return A weighted similarity graph in the form of a sparse matrix.
#'
#' @examples
#' \donttest{
#' X <- matrix(rnorm(100*100), 100, 100)
#' labels <- factor(rep(1:5, each=20))
#' cg <- class_graph(labels)
#' sigma <- 0.7
#' W <- discriminating_similarity(X, k=length(labels)/2, sigma, cg)
#' }
#'
#' @references
#' Local similarity and diversity preserving discriminant projection for face and
#' handwriting digits recognition
#'
#' @export
discriminating_similarity <- function(X, k, sigma, cg, threshold=.01) {
  Wall <- graph_weights(X, k=k, weight_mode="heat", neighbor_mode="knn", sigma=sigma)
  Wall <- adjacency(Wall)

  # Extract adjacency from class_graph object
  Ww <- adjacency(cg)
  # Between-class mask: edges NOT in class graph, but only where Wall has edges
  # Avoid creating dense matrix by working only with non-zero entries of Wall
  Wb <- Wall > 0
  Wb[Ww > threshold] <- FALSE

  # Within-class edges
  Ww2 <- Wall * (Ww > threshold)
  # Between-class edges
  Wb2 <- Wall * Wb

  wind <- which(Ww2 > 0)
  bind <- which(Wb2 > 0)

  # Apply discriminating weights
  # Within-class: boost similarity
  hw <- heat_kernel(Wall[wind], sigma)
  Wall[wind] <- hw * (1 + hw)


  # Between-class: reduce similarity
  hb <- heat_kernel(Wall[bind], sigma)
  Wall[bind] <- hb * (1 - hb)

  Wall
}

