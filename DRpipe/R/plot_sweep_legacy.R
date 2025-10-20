#' Plot sweep outputs in legacy format
#' 
#' Creates the four specific files: cmap_score.jpg, comprehensive_sweep_analysis.jpg, 
#' dist_rev_score.jpeg, sweep_cutoff_summary.jpg
#' 
#' @param run_dir The run directory where img/ should be created
#' @param per_cutoff_df Data frame with per-cutoff summary (can be NULL)
#' @param aggregated_df Data frame with aggregated robust hits
#' @param cutoff_summary Data frame with cutoff summary statistics (can be NULL)
#' @return TRUE if successful, FALSE otherwise
#' @export
plot_sweep_outputs_legacy <- function(run_dir, per_cutoff_df = NULL, aggregated_df = NULL, cutoff_summary = NULL) {
  
  # Create img directory
  img_dir <- file.path(run_dir, "img")
  dir.create(img_dir, recursive = TRUE, showWarnings = FALSE)
  
  if (is.null(aggregated_df) || nrow(aggregated_df) == 0) {
    warning("No aggregated data provided for plotting")
    return(FALSE)
  }
  
  # Prepare consolidated drugs dataframe for plotting
  consolidated_drugs <- data.frame(
    exp_id = 1:nrow(aggregated_df),
    cmap_score = aggregated_df$aggregated_score,
    q = aggregated_df$min_q,
    subset_comparison_id = "sweep_aggregated",
    name = aggregated_df$name,
    n_support = aggregated_df$n_support,
    stringsAsFactors = FALSE
  )
  
  # Remove any rows with NA names
  consolidated_drugs <- consolidated_drugs[!is.na(consolidated_drugs$name) & consolidated_drugs$name != "", ]
  
  cat("Generating legacy plots for", nrow(consolidated_drugs), "drugs...\n")
  
  # Plot 1: Histogram of reversal scores (dist_rev_score.jpeg)
  tryCatch({
    sweep_drugs_list <- list(sweep_aggregated = consolidated_drugs)
    pl_hist_revsc(sweep_drugs_list, 
                  save = "dist_rev_score.jpeg", 
                  path = img_dir)
    cat("✅ Generated dist_rev_score.jpeg\n")
  }, error = function(e) {
    cat("❌ Failed to generate dist_rev_score.jpeg:", e$message, "\n")
  })
  
  # Plot 2: CMap score plot (cmap_score.jpg)
  tryCatch({
    pl_cmap_score(consolidated_drugs, 
                  save = file.path(img_dir, "cmap_score.jpg"))
    cat("✅ Generated cmap_score.jpg\n")
  }, error = function(e) {
    cat("❌ Failed to generate cmap_score.jpg:", e$message, "\n")
  })
  
  # Plot 3: Cutoff summary plot (sweep_cutoff_summary.jpg)
  if (!is.null(cutoff_summary) && nrow(cutoff_summary) > 0) {
    tryCatch({
      jpeg(file.path(img_dir, "sweep_cutoff_summary.jpg"), 
           width = 12, height = 6, units = "in", res = 300)
      
      par(mfrow = c(1, 2))
      
      # Plot 3a: Number of hits vs cutoff
      plot(cutoff_summary$cutoff, cutoff_summary$n_hits,
           type = "b", pch = 16, cex = 1.2,
           xlab = "Log2FC Cutoff", ylab = "Number of Hits",
           main = "Hits vs Cutoff Threshold",
           col = "steelblue", lwd = 2)
      grid()
      
      # Plot 3b: Median q-value vs cutoff
      plot(cutoff_summary$cutoff, cutoff_summary$median_q,
           type = "b", pch = 16, cex = 1.2,
           xlab = "Log2FC Cutoff", ylab = "Median Q-value",
           main = "Significance vs Cutoff Threshold",
           col = "darkred", lwd = 2)
      abline(h = 0.05, lty = 2, col = "gray50", lwd = 2)
      grid()
      
      dev.off()
      cat("✅ Generated sweep_cutoff_summary.jpg\n")
    }, error = function(e) {
      cat("❌ Failed to generate sweep_cutoff_summary.jpg:", e$message, "\n")
    })
  } else {
    # Create placeholder plot if no cutoff summary
    tryCatch({
      jpeg(file.path(img_dir, "sweep_cutoff_summary.jpg"), 
           width = 12, height = 6, units = "in", res = 300)
      plot(1, 1, type = "n", main = "No Cutoff Summary Data Available")
      text(1, 1, "Cutoff summary data not available", cex = 1.5)
      dev.off()
      cat("⚠️ Generated placeholder sweep_cutoff_summary.jpg\n")
    }, error = function(e) {
      cat("❌ Failed to generate placeholder sweep_cutoff_summary.jpg:", e$message, "\n")
    })
  }
  
  # Plot 4: Comprehensive sweep analysis (comprehensive_sweep_analysis.jpg)
  tryCatch({
    img_file <- file.path(img_dir, "comprehensive_sweep_analysis.jpg")
    
    jpeg(img_file, width = 14, height = 10, units = "in", res = 300)
    par(mfrow = c(2, 3))
    
    # 4a: Score distribution
    if (length(consolidated_drugs$cmap_score) > 0 && any(is.finite(consolidated_drugs$cmap_score))) {
      hist(consolidated_drugs$cmap_score, breaks = 25, 
           main = "CMap Score Distribution",
           xlab = "CMap Score", col = "lightblue", border = "darkblue")
    } else {
      plot(1, 1, type = "n", main = "Score data not available", axes = FALSE)
      text(1, 1, "No finite score data", cex = 1.2)
    }
    
    # 4b: Q-value distribution
    if (length(consolidated_drugs$q) > 0 && any(is.finite(consolidated_drugs$q))) {
      hist(consolidated_drugs$q, breaks = 25, 
           main = "Q-value Distribution",
           xlab = "Q-value", col = "lightgreen", border = "darkgreen")
      abline(v = 0.05, col = "red", lty = 2, lwd = 2)
    } else {
      plot(1, 1, type = "n", main = "Q-value data not available", axes = FALSE)
      text(1, 1, "No finite q-value data", cex = 1.2)
    }
    
    # 4c: Support vs Score
    if ("n_support" %in% names(consolidated_drugs) && 
        length(consolidated_drugs$n_support) > 0 && 
        any(is.finite(consolidated_drugs$n_support)) &&
        any(is.finite(consolidated_drugs$cmap_score))) {
      plot(consolidated_drugs$n_support, consolidated_drugs$cmap_score, 
           main = "Threshold Support vs Score",
           xlab = "Number of Supporting Thresholds", ylab = "CMap Score",
           pch = 16, col = "red", cex = 1.2)
    } else {
      plot(1, 1, type = "n", main = "Support data not available", axes = FALSE)
      text(1, 1, "No support data", cex = 1.2)
    }
    
    # 4d: Top drugs bar plot
    top_drugs <- head(consolidated_drugs[order(consolidated_drugs$cmap_score), ], 15)
    par(mar = c(8, 4, 4, 2))
    if (nrow(top_drugs) > 0 && any(is.finite(top_drugs$cmap_score))) {
      barplot(top_drugs$cmap_score, names.arg = top_drugs$name,
              main = "Top 15 Candidate Drugs", ylab = "CMap Score",
              las = 2, col = "steelblue", cex.names = 0.8)
    } else {
      plot(1, 1, type = "n", main = "No drug data available", axes = FALSE)
      text(1, 1, "No drugs to display", cex = 1.2)
    }
    
    # 4e: Score vs Q-value scatter
    par(mar = c(4, 4, 4, 2))
    if (length(consolidated_drugs$cmap_score) > 0 && 
        length(consolidated_drugs$q) > 0 &&
        any(is.finite(consolidated_drugs$cmap_score)) &&
        any(is.finite(consolidated_drugs$q))) {
      
      # Filter out non-finite values
      valid_idx <- is.finite(consolidated_drugs$cmap_score) & is.finite(consolidated_drugs$q)
      valid_scores <- consolidated_drugs$cmap_score[valid_idx]
      valid_q <- consolidated_drugs$q[valid_idx]
      
      # Compute -log10(q) safely
      log_q <- -log10(pmax(valid_q, 1e-300))  # Avoid log(0)
      
      if (length(valid_scores) > 0 && any(is.finite(log_q))) {
        plot(valid_scores, log_q,
             main = "Score vs Significance", 
             xlab = "CMap Score", ylab = "-log10(Q-value)",
             pch = 16, col = "orange", cex = 1.2,
             ylim = range(log_q[is.finite(log_q)], na.rm = TRUE))
        abline(h = -log10(0.05), col = "red", lty = 2, lwd = 2)
      } else {
        plot(1, 1, type = "n", main = "Score vs Significance", axes = FALSE)
        text(1, 1, "No valid data", cex = 1.2)
      }
    } else {
      plot(1, 1, type = "n", main = "Score vs Significance", axes = FALSE)
      text(1, 1, "No data available", cex = 1.2)
    }
    
    # 4f: Support distribution
    par(mar = c(4, 4, 4, 2))
    if ("n_support" %in% names(consolidated_drugs) && 
        length(consolidated_drugs$n_support) > 0 &&
        any(is.finite(consolidated_drugs$n_support))) {
      support_table <- table(consolidated_drugs$n_support)
      if (length(support_table) > 0) {
        barplot(support_table,
                main = "Distribution of Threshold Support",
                xlab = "Number of Supporting Thresholds", ylab = "Number of Drugs",
                col = "purple")
      } else {
        plot(1, 1, type = "n", main = "Support distribution", axes = FALSE)
        text(1, 1, "No support data", cex = 1.2)
      }
    } else {
      plot(1, 1, type = "n", main = "Support distribution", axes = FALSE)
      text(1, 1, "No support data", cex = 1.2)
    }
    
    dev.off()
    cat("✅ Generated comprehensive_sweep_analysis.jpg\n")
  }, error = function(e) {
    cat("❌ Failed to generate comprehensive_sweep_analysis.jpg:", e$message, "\n")
  })
  
  # Verify all files were created
  expected_files <- c("cmap_score.jpg", "comprehensive_sweep_analysis.jpg", 
                     "dist_rev_score.jpeg", "sweep_cutoff_summary.jpg")
  existing_files <- list.files(img_dir)
  
  success <- all(expected_files %in% existing_files)
  
  if (success) {
    cat("✅ All 4 legacy plot files created successfully in:", img_dir, "\n")
  } else {
    missing <- expected_files[!expected_files %in% existing_files]
    cat("⚠️ Some files missing:", paste(missing, collapse = ", "), "\n")
  }
  
  return(success)
}
