# ------------------------------------------------------------------------------
# File: processing_fixed.R
#
# FIXED VERSION with diagnostic logging and proper handling of zero p-values
# ------------------------------------------------------------------------------

#' @keywords internal
#' @importFrom dplyr select all_of
#' @importFrom gprofiler2 gconvert
#' @importFrom pbapply pbsapply
#' @importFrom qvalue qvalue
NULL

# [Previous functions remain the same: clean_table, cmap_score, random_score, query_score]
# Only the query() function is modified below:

#' Assemble per-experiment results with p-values and q-values (FIXED VERSION)
#'
#' @param rand_cmap_scores numeric vector of null scores from random_score()
#' @param dz_cmap_scores numeric vector of observed scores from query_score()
#' @param subset_comparison_id string label for this query (e.g., dataset name)
#' @param analysis_id string label for the analysis type (default: "cmap")
#' @return data.frame with experiment id, score, p, q, subset_comparison_id, analysis_id
#' @export
query_fixed <- function(rand_cmap_scores, dz_cmap_scores, subset_comparison_id, analysis_id = "cmap") {
    # --- Diagnostic: Check null distribution -----------------------------------
    message("=== DIAGNOSTIC INFORMATION ===")
    message(sprintf("Null distribution size: %d", length(rand_cmap_scores)))
    message(sprintf("Null distribution range: [%.6f, %.6f]", 
                    min(rand_cmap_scores), max(rand_cmap_scores)))
    message(sprintf("Null distribution mean: %.6f, sd: %.6f", 
                    mean(rand_cmap_scores), sd(rand_cmap_scores)))
    message(sprintf("Observed scores range: [%.6f, %.6f]", 
                    min(dz_cmap_scores), max(dz_cmap_scores)))
    message(sprintf("Observed scores mean: %.6f", mean(dz_cmap_scores)))
    
    # --- Two-sided p-values from the empirical null (frequency method) --------
    message("COMPUTING p-values")
    p_values <- sapply(dz_cmap_scores, function(score) {
        # Count how many null scores are as extreme or more extreme
        count_extreme <- sum(abs(rand_cmap_scores) >= abs(score))
        p_val <- count_extreme / length(rand_cmap_scores)
        
        # CRITICAL FIX: Prevent p-values from being exactly 0
        # Use machine epsilon as minimum p-value
        if (p_val == 0) {
            p_val <- 1 / (length(rand_cmap_scores) + 1)  # Permutation-based minimum
        }
        
        return(p_val)
    })
    
    # --- Diagnostic: Check p-value distribution --------------------------------
    message(sprintf("P-values computed: %d", length(p_values)))
    message(sprintf("P-value range: [%.10f, %.10f]", min(p_values), max(p_values)))
    message(sprintf("P-values == 0: %d (%.1f%%)", 
                    sum(p_values == 0), 100 * mean(p_values == 0)))
    message(sprintf("P-values < 0.001: %d (%.1f%%)", 
                    sum(p_values < 0.001), 100 * mean(p_values < 0.001)))
    message(sprintf("P-values < 0.01: %d (%.1f%%)", 
                    sum(p_values < 0.01), 100 * mean(p_values < 0.01)))
    message(sprintf("P-values < 0.05: %d (%.1f%%)", 
                    sum(p_values < 0.05), 100 * mean(p_values < 0.05)))
    
    # --- Additional safety check: replace any remaining zeros ------------------
    if (any(p_values == 0)) {
        warning(sprintf("Found %d p-values == 0 after initial fix. Replacing with minimum.", 
                       sum(p_values == 0)))
        p_values[p_values == 0] <- min(p_values[p_values > 0], na.rm = TRUE) / 10
    }
    
    # --- Check for NA or invalid p-values --------------------------------------
    if (any(is.na(p_values))) {
        warning(sprintf("Found %d NA p-values. Replacing with 1.0", sum(is.na(p_values))))
        p_values[is.na(p_values)] <- 1.0
    }
    
    if (any(p_values < 0 | p_values > 1)) {
        warning("Found p-values outside [0,1] range. Clamping to valid range.")
        p_values <- pmax(0, pmin(1, p_values))
    }
    
    # --- q-values (FDR correction) --------------------------------------------
    message("COMPUTING q-values")
    
    # Try qvalue with error handling
    q_values <- tryCatch({
        qval_obj <- qvalue::qvalue(p_values, pi0.method = "bootstrap")
        qval_obj$qvalues
    }, error = function(e) {
        warning(sprintf("qvalue() failed: %s. Using p.adjust() instead.", e$message))
        # Fallback to Benjamini-Hochberg
        p.adjust(p_values, method = "BH")
    })
    
    # --- Diagnostic: Check q-value distribution --------------------------------
    message(sprintf("Q-values computed: %d", length(q_values)))
    message(sprintf("Q-value range: [%.10f, %.10f]", min(q_values), max(q_values)))
    message(sprintf("Q-values == 0: %d (%.1f%%)", 
                    sum(q_values == 0), 100 * mean(q_values == 0)))
    message(sprintf("Q-values < 0.05: %d (%.1f%%)", 
                    sum(q_values < 0.05), 100 * mean(q_values < 0.05)))
    message(sprintf("Q-values < 0.10: %d (%.1f%%)", 
                    sum(q_values < 0.10), 100 * mean(q_values < 0.10)))
    message("=== END DIAGNOSTIC ===\n")
    
    # --- Final safety check ----------------------------------------------------
    if (all(q_values == 0)) {
        stop("CRITICAL ERROR: All q-values are 0. This indicates a problem with the FDR correction or p-value calculation.")
    }
    
    # Annotate result set with provided analysis_id
    drugs <- data.frame(
        exp_id = seq_along(dz_cmap_scores),
        cmap_score = dz_cmap_scores,
        p = p_values,
        q = q_values,
        subset_comparison_id = subset_comparison_id,
        analysis_id = analysis_id
    )
    
    return(drugs)
}
