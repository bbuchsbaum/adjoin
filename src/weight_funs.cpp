#include "clang_compat.h"
#include <RcppArmadillo.h>
#include <vector>
#include <utility> // For std::pair
#include <algorithm> // For std::sort
#include <cmath> // For std::sqrt, std::exp
#include <limits> // For std::numeric_limits
#include <numeric> // For std::iota

using namespace Rcpp;

// Triplet holder for sparse output
struct WeightTriplet {
    double i, j, weight;
};

// utility: sum neighbor counts for reserve sizing
inline std::size_t total_neighbors(const List& indices) {
  std::size_t total = 0;
  int n = indices.size();
  for (int i = 0; i < n; ++i) {
    total += Rf_length(indices[i]);
  }
  return total;
}

// This is a simple example of exporting a C++ function to R. You can
// source this function into an R session using the Rcpp::sourceCpp
// function (or via the Source button on the editor toolbar). Learn
// more about Rcpp at:
//
//   http://www.rcpp.org/
//   http://adv-r.had.co.nz/Rcpp.html
//   http://gallery.rcpp.org/
//

// Optimized distance_heat
inline NumericVector distance_heat(NumericVector dist, double sigma) {
  int n = dist.size();
  NumericVector out(n);
  double denom = 2.0 * sigma * sigma;
  if (denom == 0) { // Avoid division by zero
      stop("sigma cannot be zero in distance_heat");
  }
  for (int i = 0; i < n; ++i) {
    double d = dist[i];
    out[i] = std::exp(-(d * d) / denom); // standard Gaussian RBF on Euclidean distance
  }
  return out;
}

// Optimized norm_heat_kernel
inline double norm_heat_kernel(const NumericVector& x1, const NumericVector& x2, double fsigma) {
  int len = x1.size();
  if (len != x2.size() || len == 0) {
      stop("Vectors must have the same non-zero length in norm_heat_kernel (got %d vs %d)", len, x2.size());
  }
  double dist_sq = 0.0;
  for (int i = 0; i < len; ++i) {
    double diff = x1[i] - x2[i];
    dist_sq += diff * diff;
  }
  // Match R normalized_heat_kernel: exp(-(dist^2/(2*len)) / (2*fsigma^2))
  double norm_dist = dist_sq / (2.0 * len);
  double denom = 2.0 * fsigma * fsigma;
  if (denom == 0) { // Avoid division by zero
     stop("fsigma cannot be zero in norm_heat_kernel");
  }
  return std::exp(-norm_dist / denom);
}

// [[Rcpp::export(rng = false)]]
NumericMatrix expand_similarity_cpp(const IntegerVector& indices, const NumericMatrix& simmat, double thresh) {
  int n = indices.size();
  int N_sim = simmat.nrow();
  int M_sim = simmat.ncol();
  std::vector<WeightTriplet> triplets;
  triplets.reserve(n * std::min(N_sim, 10)); // heuristic

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0) R_CheckUserInterrupt();
    int r = indices[i] - 1; // Convert to 0-based index
    if (r < 0 || r >= N_sim) continue; // Bounds check

    for (int j = 0; j <= i; ++j) { // Iterate only lower triangle including diagonal
      int c = indices[j] - 1; // Convert to 0-based index
      if (c < 0 || c >= N_sim || c >= M_sim || r >= M_sim) continue; // Bounds check

      if (simmat(r, c) > thresh) {
        triplets.push_back({(double)(i + 1), (double)(j + 1), simmat(r, c)}); // Store 1-based indices
      }
    }
  }

  int m = triplets.size();
  NumericMatrix out(m, 3);
  for (int i = 0; i < m; ++i) {
    out(i, 0) = triplets[i].i;
    out(i, 1) = triplets[i].j;
    out(i, 2) = triplets[i].weight;
  }

  return out;
}

// [[Rcpp::export(rng = false)]]
NumericMatrix expand_similarity_below_cpp(const IntegerVector& indices, const NumericMatrix& simmat, double thresh) {
  int n = indices.size();
  int N_sim = simmat.nrow();
  int M_sim = simmat.ncol();
  std::vector<WeightTriplet> triplets;
  triplets.reserve(n * std::min(N_sim, 10));

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0) R_CheckUserInterrupt();
    int r = indices[i] - 1; // Convert to 0-based index
    if (r < 0 || r >= N_sim) continue; // Bounds check

    for (int j = 0; j <= i; ++j) { // Iterate only lower triangle including diagonal
      int c = indices[j] - 1; // Convert to 0-based index
      if (c < 0 || c >= N_sim || c >= M_sim || r >= M_sim) continue; // Bounds check

      if (simmat(r, c) < thresh) { // Changed condition to '<'
        triplets.push_back({(double)(i + 1), (double)(j + 1), simmat(r, c)}); // Store 1-based indices
      }
    }
  }

  int m = triplets.size();
  NumericMatrix out(m, 3);
  for (int i = 0; i < m; ++i) {
    out(i, 0) = triplets[i].i;
    out(i, 1) = triplets[i].j;
    out(i, 2) = triplets[i].weight;
  }

  return out;
}


// order_vec was duplicative of R's order(); remove export to reduce maintenance.

// [[Rcpp::export(rng = false)]]
NumericMatrix cross_fspatial_weights(const List& indices, const List& distances, const NumericMatrix& feature_mat1,
                                     const NumericMatrix& feature_mat2,
                                     double sigma,
                                     double fsigma, double alpha,
                                     int maxk,
                                     bool binary) {

  int n = indices.size();
  if (n != feature_mat1.nrow()) {
      stop("Length of indices/distances must match number of rows in feature_mat1");
  }

  // Use std::vector to store results temporarily
  std::vector<WeightTriplet> triplets;
  std::size_t expected = total_neighbors(indices);
  if (maxk > 0 && maxk < Rf_length(indices[0])) {
    expected = std::min<std::size_t>(expected, (std::size_t) n * maxk);
  }
  triplets.reserve(std::max<std::size_t>(expected, 16));

  double alpha2 = 1.0 - alpha;
  int N_feat2 = feature_mat2.nrow();

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0) R_CheckUserInterrupt();
    IntegerVector ind = indices[i];
    NumericVector dist = distances[i];
    int k_neighbors = ind.size();

    if (k_neighbors == 0 || k_neighbors != dist.size()) continue; // Skip if no neighbors or mismatched sizes

    NumericVector spatial_vals = binary ? NumericVector(k_neighbors, 1.0) : distance_heat(dist, sigma);
    NumericVector f1 = feature_mat1.row(i);

    std::vector<std::pair<double, int>> neighbor_data; // Store {combined_value, original_index_in_ind}
    if (maxk > 0 && maxk < k_neighbors) {
        neighbor_data.reserve(k_neighbors);
    }

    for (int j = 0; j < k_neighbors; ++j) {
      int neighbor_idx = ind[j] - 1; // 0-based index for feature_mat2

      // Bounds check for feature_mat2
      if (neighbor_idx < 0 || neighbor_idx >= N_feat2) continue;

      NumericVector f2 = feature_mat2.row(neighbor_idx);
      double feature_sim = norm_heat_kernel(f1, f2, fsigma);
      double combined_val = alpha * spatial_vals[j] + alpha2 * feature_sim;

      if (R_finite(combined_val)) { // Check for NaN/Inf
          if (maxk > 0 && maxk < k_neighbors) {
              neighbor_data.push_back({combined_val, j});
          } else { // maxk is non-limiting or disabled
              triplets.push_back({(double)(i + 1), (double)ind[j], combined_val});
          }
      } else {
           warning("Non-finite weight encountered for pair (%d, %d)", i + 1, ind[j]);
      }
    }

    // If maxk is active, sort and select top k
    if (maxk > 0 && maxk < k_neighbors && !neighbor_data.empty()) {
        // Sort by combined_val (descending)
        std::sort(neighbor_data.rbegin(), neighbor_data.rend()); // Sort descending by weight

        int num_to_take = std::min((int)neighbor_data.size(), maxk);
        for (int j = 0; j < num_to_take; ++j) {
            int original_j = neighbor_data[j].second;
            triplets.push_back({(double)(i + 1), (double)ind[original_j], neighbor_data[j].first});
        }
    }
  }

  // Create the final matrix from the collected triplets
  int m = triplets.size();
  NumericMatrix wout(m, 3);
  for(int i = 0; i < m; ++i) {
      wout(i, 0) = triplets[i].i;
      wout(i, 1) = triplets[i].j;
      wout(i, 2) = triplets[i].weight;
  }
  return wout;
}


// [[Rcpp::export(rng = false)]]
NumericMatrix bilateral_weights(const List& indices, const List& distances, const NumericMatrix& feature_mat,
                                double sigma, double fsigma) {
  int n = indices.size();
  if (n != feature_mat.nrow()) {
      stop("Length of indices/distances must match number of rows in feature_mat");
  }
  int N_feat = feature_mat.nrow();

  std::vector<WeightTriplet> triplets;
  std::size_t expected = total_neighbors(indices);
  triplets.reserve(std::max<std::size_t>(expected, 16));

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0) R_CheckUserInterrupt();
    IntegerVector ind = indices[i];
    NumericVector dist = distances[i];
    int k_neighbors = ind.size();

    if (k_neighbors == 0 || k_neighbors != dist.size()) continue;

    NumericVector spatial_vals = distance_heat(dist, sigma);
    NumericVector f1 = feature_mat.row(i);

    for (int j = 0; j < k_neighbors; ++j) {
      int neighbor_idx = ind[j] - 1; // 0-based index

      // Bounds check
      if (neighbor_idx < 0 || neighbor_idx >= N_feat) continue;

      NumericVector f2 = feature_mat.row(neighbor_idx);
      double feature_sim = norm_heat_kernel(f1, f2, fsigma);
      double final_weight = spatial_vals[j] * feature_sim;

      if (R_finite(final_weight)) {
          triplets.push_back({(double)(i + 1), (double)ind[j], final_weight});
      } else {
           warning("Non-finite weight encountered for pair (%d, %d)", i + 1, ind[j]);
      }
    }
  }

  // Create the final matrix
  int m = triplets.size();
  NumericMatrix wout(m, 3);
  for(int i = 0; i < m; ++i) {
      wout(i, 0) = triplets[i].i;
      wout(i, 1) = triplets[i].j;
      wout(i, 2) = triplets[i].weight;
  }
  return wout;
}


// [[Rcpp::export(rng = false)]]
NumericMatrix fspatial_weights(const List& indices, const List& distances, const NumericMatrix& feature_mat,
                               double sigma, double fsigma, double alpha, bool binary) {
  int n = indices.size();
   if (n != feature_mat.nrow()) {
      stop("Length of indices/distances must match number of rows in feature_mat");
  }
  int N_feat = feature_mat.nrow();

  std::vector<WeightTriplet> triplets;
  std::size_t expected = total_neighbors(indices);
  triplets.reserve(std::max<std::size_t>(expected, 16));

  double alpha2 = 1.0 - alpha;

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0) R_CheckUserInterrupt();
    IntegerVector ind = indices[i];
    NumericVector dist = distances[i];
    int k_neighbors = ind.size();

    if (k_neighbors == 0 || k_neighbors != dist.size()) continue;

    NumericVector spatial_vals = binary ? NumericVector(k_neighbors, 1.0) : distance_heat(dist, sigma);
    NumericVector f1 = feature_mat.row(i);

    for (int j = 0; j < k_neighbors; ++j) {
      int neighbor_idx = ind[j] - 1; // 0-based index

      // Bounds check
      if (neighbor_idx < 0 || neighbor_idx >= N_feat) continue;

      NumericVector f2 = feature_mat.row(neighbor_idx);
      double feature_sim = norm_heat_kernel(f1, f2, fsigma);
      double final_weight = alpha * spatial_vals[j] + alpha2 * feature_sim;

       if (R_finite(final_weight)) {
          triplets.push_back({(double)(i + 1), (double)ind[j], final_weight});
      } else {
          warning("Non-finite weight encountered for pair (%d, %d)", i + 1, ind[j]);
      }
    }
  }

  // Create the final matrix
  int m = triplets.size();
  NumericMatrix wout(m, 3);
  for(int i = 0; i < m; ++i) {
      wout(i, 0) = triplets[i].i;
      wout(i, 1) = triplets[i].j;
      wout(i, 2) = triplets[i].weight;
  }
  return wout;
}

// [[Rcpp::export(rng = false)]]
NumericMatrix spatial_weights(const List& indices, const List& distances, double sigma, bool binary) {
  int n = indices.size();
  
  std::vector<WeightTriplet> triplets;
  std::size_t expected = total_neighbors(indices);
  triplets.reserve(std::max<std::size_t>(expected, 16));

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0) R_CheckUserInterrupt();
    IntegerVector ind = indices[i];
    NumericVector dist = distances[i];
    int k_neighbors = ind.size();

    if (k_neighbors == 0 || k_neighbors != dist.size()) continue;

    NumericVector spatial_vals = binary ? NumericVector(k_neighbors, 1.0) : distance_heat(dist, sigma);

    for (int j = 0; j < k_neighbors; ++j) {
      // No feature matrix index check needed here
      double final_weight = spatial_vals[j];

       if (R_finite(final_weight)) {
            triplets.push_back({(double)(i + 1), (double)ind[j], final_weight});
       } else {
            warning("Non-finite weight encountered for pair (%d, %d)", i + 1, ind[j]);
       }
    }
  }

  // Create the final matrix
  int m = triplets.size();
  NumericMatrix wout(m, 3);
  for(int i = 0; i < m; ++i) {
      wout(i, 0) = triplets[i].i;
      wout(i, 1) = triplets[i].j;
      wout(i, 2) = triplets[i].weight;
  }
  return wout;
}
