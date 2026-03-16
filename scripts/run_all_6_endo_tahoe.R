#!/usr/bin/env Rscript
# Run all 6 endometriosis signatures with TAHOE drug signatures
# Compares results with Tomiko's original pipeline

library(DRpipe)

cat("================================================================\n")
cat("Running all 6 Endometriosis signatures with TAHOE\n")
cat("================================================================\n\n")

# Short names for output
short_names <- c("ESE", "InII", "IIInIV", "MSE", "PE", "Unstratified")

# Disease signature files
disease_files <- c(
  ESE = "data/disease_signatures/endo_disease_signatures/endomentriosis_ese_disease_signature.csv",
  InII = "data/disease_signatures/endo_disease_signatures/endomentriosis_inii_disease_signature.csv",
  IIInIV = "data/disease_signatures/endo_disease_signatures/endomentriosis_iiiniv_disease_signature.csv",
  MSE = "data/disease_signatures/endo_disease_signatures/endomentriosis_mse_disease_signature.csv",
  PE = "data/disease_signatures/endo_disease_signatures/endomentriosis_pe_disease_signature.csv",
  Unstratified = "data/disease_signatures/endo_disease_signatures/endomentriosis_unstratified_disease_signature.csv.csv"
)

# Results summary
results_summary <- data.frame(
  Signature = character(),
  DRpipe_Drugs = integer(),
  stringsAsFactors = FALSE
)

for (i in seq_along(short_names)) {
  short_name <- short_names[i]
  disease_file <- disease_files[short_name]
  
  cat("\n================================================================\n")
  cat(sprintf("Processing: %s with TAHOE\n", short_name))
  cat("================================================================\n")
  
  # Create output directory
  out_dir <- file.path("results", paste0("endo_tahoe_", short_name))
  
  # Run DRpipe with Tahoe
  drp <- DRP$new(
    signatures_rdata    = "data/drug_signatures/tahoe_signatures.RData",
    disease_path        = disease_file,
    drug_meta_path      = "data/drug_signatures/tahoe_drug_experiments_new.csv",
    drug_valid_path     = NULL,  # Skip valid instances filtering for Tahoe
    out_dir             = out_dir,
    gene_key            = "symbols",
    logfc_cols_pref     = "logFC",
    gene_conversion_table = NULL,
    probe_id_fallback   = TRUE,
    logfc_cutoff        = 1.1,
    percentile_filtering = list(enabled = FALSE, threshold = NULL),
    pval_key            = "adj.P.Val",
    pval_cutoff         = 0.05,
    q_thresh            = 0.0001,
    reversal_only       = TRUE,
    seed                = 2009,
    n_permutations      = 1000,
    pvalue_method       = "discrete",
    phipson_smyth_correction = FALSE,
    mode                = "single",
    combine_log2fc      = "average",
    analysis_id         = "tahoe",
    verbose             = TRUE
  )
  
  # Run pipeline
  drp$run_all(make_plots = FALSE)
  
  # Load DRpipe results
  drpipe_file <- list.files(out_dir, pattern = "_hits_.*\\.csv$", full.names = TRUE)[1]
  if (!is.null(drpipe_file) && file.exists(drpipe_file)) {
    drpipe <- read.csv(drpipe_file)
    drpipe_rev <- drpipe[drpipe$q == 0 & drpipe$cmap_score < 0, ]
    n_drugs <- nrow(drpipe_rev)
    
    results_summary <- rbind(results_summary, data.frame(
      Signature = short_name,
      DRpipe_Drugs = n_drugs,
      stringsAsFactors = FALSE
    ))
    
    cat(sprintf("\n%s TAHOE: %d drugs with q=0 and score<0\n",
                short_name, n_drugs))
  } else {
    results_summary <- rbind(results_summary, data.frame(
      Signature = short_name,
      DRpipe_Drugs = 0,
      stringsAsFactors = FALSE
    ))
    cat(sprintf("Warning: No results file found for %s\n", short_name))
  }
}

cat("\n\n================================================================\n")
cat("FINAL SUMMARY - TAHOE\n")
cat("================================================================\n\n")
print(results_summary)

# Save summary
write.csv(results_summary, "results/endo_tahoe_comparison_summary.csv", row.names = FALSE)
cat("\nSummary saved to: results/endo_tahoe_comparison_summary.csv\n")

# Also create comparison with CMAP results
cat("\n================================================================\n")
cat("CMAP vs TAHOE Comparison\n")
cat("================================================================\n\n")

cmap_summary <- read.csv("results/endo_v3_comparison_summary.csv")
comparison <- merge(
  cmap_summary[, c("Signature", "DRpipe_Drugs")],
  results_summary[, c("Signature", "DRpipe_Drugs")],
  by = "Signature",
  suffixes = c("_CMAP", "_TAHOE")
)
print(comparison)
write.csv(comparison, "results/endo_cmap_vs_tahoe.csv", row.names = FALSE)
cat("\nComparison saved to: results/endo_cmap_vs_tahoe.csv\n")
