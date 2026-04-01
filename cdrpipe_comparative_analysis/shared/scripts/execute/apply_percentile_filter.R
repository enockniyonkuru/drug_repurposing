#' Apply Percentile-Based Gene Filtering to Disease Signature
#'
#' Filters genes in a disease signature based on percentile ranking of logFC values.
#' Each disease keeps its top X% of genes by absolute logFC magnitude.
#'
#' @param disease_df Data frame with disease signature (must have logfc column)
#' @param logfc_col Character vector specifying the logFC column name(s).
#'                  If multiple columns, will use mean across them.
#' @param percentile_threshold Numeric (0-100). Percentile cutoff to keep genes.
#'                            e.g., 75 = keep top 75% of genes by logFC
#'
#' @return Data frame with genes filtered to top percentile (sorted by logfc desc)
#'
#' @examples
#' \dontrun{
#' filtered_df <- apply_percentile_filter(disease_df, "mean_logfc", 75)
#' }

apply_percentile_filter <- function(disease_df, logfc_col = "mean_logfc", 
                                     percentile_threshold = 75) {
  
  # Validate inputs
  if (!is.data.frame(disease_df) || nrow(disease_df) == 0) {
    stop("disease_df must be a non-empty data frame")
  }
  
  if (!percentile_threshold %in% 1:100) {
    stop("percentile_threshold must be between 1 and 100")
  }
  
  # Handle logFC column
  if (length(logfc_col) == 1) {
    if (!logfc_col %in% names(disease_df)) {
      stop(sprintf("Column '%s' not found in disease_df", logfc_col))
    }
    logfc_vals <- abs(disease_df[[logfc_col]])
  } else {
    # Multiple columns: use mean
    missing_cols <- setdiff(logfc_col, names(disease_df))
    if (length(missing_cols) > 0) {
      stop(sprintf("Columns not found: %s", paste(missing_cols, collapse = ", ")))
    }
    logfc_vals <- rowMeans(abs(disease_df[, logfc_col, drop = FALSE]), na.rm = TRUE)
  }
  
  # Calculate percentile threshold value
  percentile_value <- quantile(logfc_vals, probs = percentile_threshold / 100, na.rm = TRUE)
  
  # Filter genes
  filtered_df <- disease_df[abs(logfc_vals) >= percentile_value, ]
  
  # Return sorted by logFC descending
  if (length(logfc_col) == 1) {
    filtered_df <- filtered_df[order(-abs(filtered_df[[logfc_col]])), ]
  }
  
  # Store metadata about filtering
  attr(filtered_df, "percentile_threshold") <- percentile_threshold
  attr(filtered_df, "percentile_cutoff_value") <- percentile_value
  attr(filtered_df, "genes_before") <- nrow(disease_df)
  attr(filtered_df, "genes_after") <- nrow(filtered_df)
  attr(filtered_df, "genes_filtered") <- nrow(disease_df) - nrow(filtered_df)
  attr(filtered_df, "pct_filtered") <- round((1 - nrow(filtered_df)/nrow(disease_df)) * 100, 1)
  
  return(filtered_df)
}

#' Summarize Percentile Filter Results
#'
#' @param filtered_df Data frame with percentile filtering attributes
#'
#' @return Character string with summary statistics

summarize_percentile_filter <- function(filtered_df) {
  pct_thresh <- attr(filtered_df, "percentile_threshold")
  cutoff_val <- attr(filtered_df, "percentile_cutoff_value")
  before <- attr(filtered_df, "genes_before")
  after <- attr(filtered_df, "genes_after")
  pct_filt <- attr(filtered_df, "pct_filtered")
  
  sprintf("Percentile filter (%.0f%%): %.0f genes → %.0f genes (removed %.1f%%, threshold: %.4f)", 
          pct_thresh, before, after, pct_filt, cutoff_val)
}
