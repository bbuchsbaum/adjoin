#' Local + Global KNN Adjacency
#'
#' Build an adjacency matrix that mixes \code{L} neighbors inside a local radius
#' \code{r} with \code{K} neighbors outside that radius. Far neighbors receive a
#' mild penalty so they can contribute without dominating.
#'
#' @param coord_mat Numeric matrix of coordinates (rows = points).
#' @param L Number of local neighbors (within \code{r}) to keep for each point.
#' @param K Number of far neighbors (outside \code{r}) to keep for each point.
#' @param r Radius defining the local ball.
#' @param weight_mode Weighting scheme name (e.g., "heat"); forwarded to internal helper get_neighbor_fun.
#' @param sigma Bandwidth for the heat/normalized kernels; default \code{r/2}.
#' @param far_penalty Either \code{"lambda"} (constant multiplier) or
#'   \code{"exp"} (decay with distance beyond \code{r}).
#' @param lambda Constant multiplier for far neighbors when
#'   \code{far_penalty = "lambda"}.
#' @param tau Scale of exponential decay when \code{far_penalty = "exp"}.
#' @param nnk_buffer Extra candidates requested from the NN search to ensure
#'   enough far neighbors are available.
#' @param include_diagonal Logical; keep self-loops.
#' @param symmetric Logical; if TRUE, symmetrize by averaging \code{A} and
#'   \code{t(A)}.
#' @param normalized Logical; if TRUE, row-normalize the matrix (stochastic).
#'
#' @return A sparse adjacency matrix mixing local and far neighbors.
#' @export
#'
#' @examples
#' set.seed(1)
#' coords <- matrix(runif(200), ncol = 2)
#' A <- local_global_adjacency(coords, L = 4, K = 3, r = 0.15,
#'                             weight_mode = "heat", lambda = 0.7)
#' Matrix::rowSums(A)[1:5]
local_global_adjacency <- function(coord_mat, L = 5, K = 5, r,
                                   weight_mode = c("heat", "binary"),
                                   sigma = r / 2,
                                   far_penalty = c("lambda", "exp"),
                                   lambda = 0.6, tau = r,
                                   nnk_buffer = 10,
                                   include_diagonal = FALSE,
                                   symmetric = TRUE, normalized = FALSE) {

  assertthat::assert_that(!missing(r))
  assertthat::assert_that(r > 0)
  assertthat::assert_that(L >= 0, K >= 0)

  weight_mode <- match.arg(weight_mode)
  far_penalty <- match.arg(far_penalty)

  n <- nrow(coord_mat)
  if (n < 2) {
    return(Matrix::sparseMatrix(i = integer(), j = integer(), x = numeric(), dims = c(n, n)))
  }

  k_req <- max(1, min(n - 1, L + K + nnk_buffer))

  nn <- Rnanoflann::nn(data = coord_mat, points = coord_mat, k = k_req)
  idx_mat <- nn$indices
  dist_mat <- nn$distances

  max_edges <- n * (L + K + as.integer(include_diagonal))
  ii <- integer(max_edges)
  jj <- integer(max_edges)
  xx <- numeric(max_edges)
  used <- 0L

  for (i in seq_len(n)) {
    idx <- idx_mat[i, ]
    d <- dist_mat[i, ]

    ok <- !is.na(idx) & idx > 0 & !is.na(d) & idx != i
    idx <- idx[ok]
    d <- d[ok]

    loc_mask <- d <= r
    n_loc <- min(sum(loc_mask), L)
    n_far <- min(sum(!loc_mask), K)

    if (!include_diagonal && (n_loc + n_far) == 0L) {
      next
    }

    total_i <- n_loc + n_far + as.integer(include_diagonal)
    if (total_i == 0L) {
      next
    }

    sel_idx <- integer(total_i)
    sel_w <- numeric(total_i)
    pos <- 1L

    if (include_diagonal) {
      sel_idx[pos] <- i
      sel_w[pos] <- 1
      pos <- pos + 1L
    }

    if (n_loc > 0L) {
      loc_idx <- idx[loc_mask]
      loc_d <- d[loc_mask]
      if (n_loc < length(loc_idx)) {
        loc_idx <- loc_idx[seq_len(n_loc)]
        loc_d <- loc_d[seq_len(n_loc)]
      }

      rng <- pos:(pos + n_loc - 1L)
      sel_idx[rng] <- loc_idx
      sel_w[rng] <- if (weight_mode == "binary") {
        1
      } else {
        exp(-(loc_d^2) / (2 * sigma^2))
      }
      pos <- pos + n_loc
    }

    if (n_far > 0L) {
      far_idx <- idx[!loc_mask]
      far_d <- d[!loc_mask]
      if (n_far < length(far_idx)) {
        far_idx <- far_idx[seq_len(n_far)]
        far_d <- far_d[seq_len(n_far)]
      }

      far_w <- if (weight_mode == "binary") {
        rep_len(1, n_far)
      } else {
        exp(-(far_d^2) / (2 * sigma^2))
      }
      far_adj <- if (far_penalty == "lambda") {
        rep(lambda, n_far)
      } else {
        exp(-(far_d - r) / tau)
      }

      rng <- pos:(pos + n_far - 1L)
      sel_idx[rng] <- far_idx
      sel_w[rng] <- far_w * far_adj
    }

    rng <- (used + 1L):(used + total_i)
    ii[rng] <- i
    jj[rng] <- sel_idx
    xx[rng] <- sel_w
    used <- used + total_i
  }

  if (used == 0L) {
    return(Matrix::sparseMatrix(i = integer(), j = integer(), x = numeric(), dims = c(n, n)))
  }

  keep <- seq_len(used)
  A <- Matrix::sparseMatrix(i = ii[keep], j = jj[keep], x = xx[keep], dims = c(n, n))

  if (symmetric) {
    A <- (A + Matrix::t(A)) / 2
  }

  if (normalized) {
    rs <- Matrix::rowSums(A)
    invd <- 1 / pmax(rs, .Machine$double.eps)
    A <- Matrix::Diagonal(x = invd) %*% A
  }

  A
}
