#' Fast kNN Graph Weights
#'
#' Construct a sparse k-nearest-neighbor (kNN) graph quickly. For L2 distance, this
#' uses `RcppHNSW` when available (approximate, very fast) and falls back to
#' `Rnanoflann` (exact) otherwise.
#'
#' The default weighting mode (`"self_tuned"`) uses a self-tuning heat kernel based
#' on per-point local scale, which tends to work well across varying densities.
#'
#' @param X A numeric matrix with rows as observations and columns as features.
#' @param k Number of nearest neighbors (per row).
#' @param weight_mode Weighting to convert distances into edge weights. One of
#'   `"self_tuned"`, `"heat"`, `"normalized"`, `"binary"`, `"euclidean"`,
#'   `"cosine"`, or `"correlation"`.
#' @param type Symmetrization policy. `"normal"` returns a union graph with
#'   `max(w_ij, w_ji)`; `"mutual"` returns an intersection graph with
#'   `min(w_ij, w_ji)`; `"asym"` returns the directed kNN graph.
#' @param backend Neighbor search backend: `"auto"` (default), `"hnsw"`, or
#'   `"nanoflann"`.
#' @param sigma Bandwidth for `"heat"`/`"normalized"` modes. If `NULL`, a robust
#'   value is estimated from kNN distances.
#' @param local_k Local neighborhood size used by `"self_tuned"`; defaults to
#'   `min(7, k)`.
#' @param M,ef HNSW parameters (only used when `backend="hnsw"`).
#'
#' @details Provides additional neighbor search backends (HNSW, nanoflann) and self-tuning sigma estimation not available in \code{\link{graph_weights}}.
#'
#' @return A sparse `dgCMatrix` adjacency matrix.
#' @seealso \code{\link{graph_weights}} for the standard interface
#'
#' @examples
#' X <- matrix(rnorm(200), 20, 10)
#' W <- graph_weights_fast(X, k = 5)
#'
#' @export
graph_weights_fast <- function(X, k = 15,
                               weight_mode = c("self_tuned", "heat", "normalized", "binary",
                                               "euclidean", "cosine", "correlation"),
                               type = c("normal", "mutual", "asym"),
                               backend = c("auto", "hnsw", "nanoflann"),
                               sigma = NULL,
                               local_k = min(7L, k),
                               M = 16, ef = 200) {

  weight_mode <- match.arg(weight_mode)
  type <- match.arg(type)
  backend <- match.arg(backend)

  X <- as.matrix(X)
  n <- nrow(X)
  p <- ncol(X)

  stopifnot(
    "`X` must have at least 2 rows." = n >= 2,
    "`k` must be between 1 and n-1." = is.numeric(k) && length(k) == 1 && k >= 1 && k <= (n - 1)
  )
  k <- as.integer(k)
  local_k <- as.integer(local_k)
  if (local_k < 1L || local_k > k) {
    stop("`local_k` must be between 1 and `k`.", call. = FALSE)
  }

  # Fast row-wise standardization / normalization (avoids transpose+scale).
  if (weight_mode %in% c("normalized", "correlation")) {
    mu <- rowMeans(X)
    X <- X - mu
    # sample sd: sqrt(sum((x-mu)^2)/(p-1)), matching base::scale() defaults
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

  if (backend == "auto") {
    backend <- if (requireNamespace("RcppHNSW", quietly = TRUE)) "hnsw" else "nanoflann"
  }

  # Compute kNN: idx (n x k) and d2 (n x k) where d2 are squared L2 distances.
  k_use <- min(k + 1L, n)
  if (backend == "hnsw") {
    if (!requireNamespace("RcppHNSW", quietly = TRUE)) {
      stop("backend='hnsw' requires the RcppHNSW package.", call. = FALSE)
    }
    ann <- RcppHNSW::hnsw_build(X, distance = "l2", M = M, ef = ef)
    res <- RcppHNSW::hnsw_search(X, ann, k = k_use)
    idx <- res$idx[, -1, drop = FALSE]
    d2 <- res$dist[, -1, drop = FALSE]
  } else {
    nn <- Rnanoflann::nn(data = X, points = X, k = k_use)
    idx <- nn$indices[, -1, drop = FALSE]
    # Rnanoflann returns Euclidean distances; square once and keep squared throughout.
    d2 <- nn$distances[, -1, drop = FALSE]^2
  }

  if (min(idx, na.rm = TRUE) == 0L) idx <- idx + 1L

  # Build weights from squared distances.
  w <- switch(weight_mode,
    binary = {
      matrix(1, nrow = nrow(idx), ncol = ncol(idx))
    },
    euclidean = {
      sqrt(d2)
    },
    heat = {
      sigma2 <- if (is.null(sigma)) {
        kth <- min(5L, ncol(d2))
        s2 <- stats::median(d2[, kth], na.rm = TRUE)
        if (!is.finite(s2) || s2 <= 0) {
          s2 <- stats::quantile(as.vector(d2), probs = 0.25, na.rm = TRUE, names = FALSE)
        }
        if (!is.finite(s2) || s2 <= 0) stop("Unable to estimate sigma (all distances zero).", call. = FALSE)
        s2
      } else {
        if (!is.numeric(sigma) || length(sigma) != 1 || !is.finite(sigma) || sigma <= 0) {
          stop("`sigma` must be a positive scalar.", call. = FALSE)
        }
        sigma^2
      }
      exp(-d2 / (2 * sigma2))
    },
    normalized = {
      if (p < 1L) stop("`X` must have at least 1 column.", call. = FALSE)
      sigma2 <- if (is.null(sigma)) {
        kth <- min(5L, ncol(d2))
        s2 <- stats::median(d2[, kth], na.rm = TRUE)
        if (!is.finite(s2) || s2 <= 0) {
          s2 <- stats::quantile(as.vector(d2), probs = 0.25, na.rm = TRUE, names = FALSE)
        }
        if (!is.finite(s2) || s2 <= 0) stop("Unable to estimate sigma (all distances zero).", call. = FALSE)
        s2
      } else {
        if (!is.numeric(sigma) || length(sigma) != 1 || !is.finite(sigma) || sigma <= 0) {
          stop("`sigma` must be a positive scalar.", call. = FALSE)
        }
        sigma^2
      }
      # normalized_heat_kernel on Euclidean distances:
      # exp(-(d^2/(2*len)) / (2*sigma^2)) == exp(-d^2/(4*len*sigma^2))
      exp(-d2 / (4 * p * sigma2))
    },
    cosine = {
      1 - d2 / 2
    },
    correlation = {
      if (p < 2L) stop("`correlation` weights require ncol(X) >= 2.", call. = FALSE)
      1 - d2 / (2 * (p - 1))
    },
    self_tuned = {
      # Self-tuning kernel: sigma_i = distance to local_k-th neighbor.
      s2 <- d2[, local_k]
      s2[!is.finite(s2) | s2 <= 0] <- 0
      s <- sqrt(s2)
      # Avoid 0 scale; fall back to a small positive value.
      fallback <- suppressWarnings(min(d2[d2 > 0 & is.finite(d2)], na.rm = TRUE))
      if (!is.finite(fallback) || fallback <= 0) fallback <- 1
      s[s == 0] <- sqrt(fallback)
      s[!is.finite(s) | s == 0] <- 1

      sj <- s[idx]
      denom <- sj * s
      denom[!is.finite(denom) | denom <= 0] <- Inf
      exp(-d2 / denom)
    }
  )

  Wdir <- indices_to_sparse(idx, w, idim = n, jdim = n)

  Wt <- Matrix::t(Wdir)
  W <- switch(type,
    asym = Wdir,
    normal = (Wdir + Wt + abs(Wdir - Wt)) / 2,
    mutual = (Wdir + Wt - abs(Wdir - Wt)) / 2
  )

  Matrix::drop0(W)
}
