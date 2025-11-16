#!/usr/bin/env Rscript
# Batch script to run SIROTA LAB disease signatures with both CMAP and TAHOE drug signatures
# This script processes all disease files in the Sirota lab disease signature directory

suppressPackageStartupMessages(library(DRpipe))

# Define paths - SIROTA LAB
disease_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/disease_signatures/temp_singnatures"

# # CMAP configuration - Part 1: genes_drugs
# cmap_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_genes_drugs.RData"
# cmap_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_drug_experiments_new.csv"

#CMAP configuration - Part 2: genes_filtered (COMMENTED OUT)
cmap_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_genes_filtered.RData"
cmap_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_drug_experiments_new.csv"

# # TAHOE configuration - Part 1: genes_drugs
# tahoe_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_genes_drugs.RData"
# tahoe_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv"

# TAHOE configuration - Part 2: genes_filtered (COMMENTED OUT)
tahoe_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_genes_filtered.RData"
tahoe_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv"

# Common parameters
cmap_valid <- NULL
out_root <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/results/temp_special_1_results_filtered"
report_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/reports"

# Verify directories and files exist
if (!dir.exists(disease_dir)) {
  cat("Error: Disease directory not found:", disease_dir, "\n")
  quit(status = 1)
}
if (!file.exists(cmap_signatures)) {
  cat("Error: CMAP signatures file not found:", cmap_signatures, "\n")
  quit(status = 1)
}
if (!file.exists(tahoe_signatures)) {
  cat("Error: TAHOE signatures file not found:", tahoe_signatures, "\n")
  quit(status = 1)
}

# Get all disease signature files
disease_files <- list.files(disease_dir, pattern = "_signature\\.csv$", full.names = TRUE)
cat("Found", length(disease_files), "Special disease signature files\n\n")
cat("Diseases to process:\n")
for (f in disease_files) {
  cat("  -", gsub("_signature\\.csv$", "", basename(f)), "\n")
}
cat("\n")

# Create timestamp for this batch run
batch_ts <- format(Sys.time(), "%Y%m%d-%H%M%S")
batch_log_file <- file.path(out_root, paste0("batch_run_log_", batch_ts, ".txt"))
batch_report_file <- file.path(report_dir, paste0("sirota_lab_batch_report_", batch_ts, ".txt"))

# Create results and reports directories if they don't exist
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

# Initialize log
log_conn <- file(batch_log_file, open = "wt")
writeLines(paste("Batch run started at:", Sys.time()), log_conn)
writeLines(paste("Disease source: SIROTA LAB"), log_conn)
writeLines(paste("Total diseases to process:", length(disease_files)), log_conn)
writeLines(paste("Drug signatures: CMAP and TAHOE"), log_conn)
writeLines(paste("LogFC cutoff: 0.0"), log_conn)
writeLines(paste("P-value filtering: None"), log_conn)
writeLines("", log_conn)
close(log_conn)

# Initialize report
report_conn <- file(batch_report_file, open = "wt")
writeLines("================================================================================", report_conn)
writeLines("SIROTA LAB DISEASE SIGNATURES - BATCH ANALYSIS REPORT", report_conn)
writeLines("================================================================================", report_conn)
writeLines(paste("Report generated:", Sys.time()), report_conn)
writeLines(paste("Batch timestamp:", batch_ts), report_conn)
writeLines("", report_conn)
writeLines("CONFIGURATION:", report_conn)
writeLines(paste("  Disease source: SIROTA LAB"), report_conn)
writeLines(paste("  Disease directory:", disease_dir), report_conn)
writeLines(paste("  CMAP signatures:", cmap_signatures), report_conn)
writeLines(paste("  TAHOE signatures:", tahoe_signatures), report_conn)
writeLines(paste("  Output directory:", out_root), report_conn)
writeLines(paste("  Q-value threshold:", "0.5"), report_conn)
writeLines(paste("  LogFC cutoff:", "0.0"), report_conn)
writeLines(paste("  P-value filtering:", "None"), report_conn)
writeLines("", report_conn)
writeLines(paste("DISEASES TO PROCESS (", length(disease_files), " total):", sep=""), report_conn)
for (f in disease_files) {
  writeLines(paste("  -", gsub("_signature\\.csv$", "", basename(f))), report_conn)
}
writeLines("", report_conn)
writeLines("================================================================================", report_conn)
writeLines("PROCESSING LOG:", report_conn)
writeLines("================================================================================", report_conn)
close(report_conn)

# Helper function to run pipeline
run_pipeline <- function(sig_path, sig_name, disease_file, disease_name, batch_ts, meta_path) {
  cat("\n========================================\n")
  cat("Running", sig_name, "for", disease_name, "\n")
  cat("========================================\n")
  
  # Preprocess the disease file
  preprocessed_file <- tempfile(fileext = ".csv")
  df <- read.csv(disease_file, stringsAsFactors = FALSE)
  colnames(df)[colnames(df) == "gene_symbol"] <- "SYMBOL"
  colnames(df)[colnames(df) == "common_experiment"] <- "log2FC"
  df_out <- df[, c("SYMBOL", "log2FC")]
  write.csv(df_out, preprocessed_file, row.names = FALSE, quote = FALSE)
  disease_file <- preprocessed_file
  
  # Create output directory
  folder_name <- paste0(disease_name, "_", sig_name, "_", batch_ts)
  out_dir <- file.path(out_root, folder_name)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Initialize DRP object
  drp <- DRP$new(
    signatures_rdata = sig_path,
    disease_path     = disease_file,
    disease_pattern  = NULL,
    cmap_meta_path   = meta_path,
    cmap_valid_path  = NULL,
    out_dir          = out_dir,
    gene_key         = "SYMBOL",
    logfc_cols_pref  = "log2FC",
    logfc_cutoff     = 0.0,
    pval_key         = NULL,
    pval_cutoff      = 0.05,
    q_thresh         = 0.5,
    reversal_only    = TRUE,
    seed             = 123,
    verbose          = TRUE,
    analysis_id      = sig_name,
    mode             = "single",
    gene_conversion_table = "../data/gene_id_conversion_table.tsv"
  )
  
  # Run the pipeline with plots
  success <- FALSE
  error_msg <- NULL
  
  tryCatch({
    drp$run_all(make_plots = TRUE)
    success <- TRUE
    cat("\n[SUCCESS]", sig_name, "analysis completed for", disease_name, "\n")
    cat("Results saved to:", out_dir, "\n")
  }, error = function(e) {
    error_msg <<- conditionMessage(e)
    cat("\n[ERROR]", sig_name, "analysis failed for", disease_name, "\n")
    cat("Error message:", error_msg, "\n")
  })
  
  return(list(
    success = success,
    out_dir = out_dir,
    error_msg = error_msg
  ))
}

# Initialize tracking
results_summary <- data.frame(
  disease = character(),
  signature_type = character(),
  status = character(),
  output_dir = character(),
  error_message = character(),
  stringsAsFactors = FALSE
)

# Process each disease
for (i in seq_along(disease_files)) {
  disease_file <- disease_files[i]
  
  # Extract disease name from filename
  disease_name <- basename(disease_file)
  disease_name <- gsub("_signature\\.csv$", "", disease_name)
  
  cat("\n\n")
  cat("================================================================================\n")
  cat("Processing disease", i, "of", length(disease_files), ":", disease_name, "\n")
  cat("================================================================================\n")
  
  # Log to file and report
  log_conn <- file(batch_log_file, open = "at")
  writeLines(paste("\n[", Sys.time(), "] Processing:", disease_name, "(", i, "of", length(disease_files), ")"), log_conn)
  close(log_conn)
  
  report_conn <- file(batch_report_file, open = "at")
  writeLines(paste("\n[", Sys.time(), "] Processing disease", i, "of", length(disease_files), ":", disease_name), report_conn)
  close(report_conn)
  
  # Run with CMAP
  cmap_result <- run_pipeline(
    sig_path = cmap_signatures,
    sig_name = "CMAP",
    disease_file = disease_file,
    disease_name = disease_name,
    batch_ts = batch_ts,
    meta_path = cmap_meta
  )
  
  # Add to summary
  results_summary <- rbind(results_summary, data.frame(
    disease = disease_name,
    signature_type = "CMAP",
    status = ifelse(cmap_result$success, "SUCCESS", "FAILED"),
    output_dir = cmap_result$out_dir,
    error_message = ifelse(is.null(cmap_result$error_msg), "", cmap_result$error_msg),
    stringsAsFactors = FALSE
  ))
  
  # Run with TAHOE
  tahoe_result <- run_pipeline(
    sig_path = tahoe_signatures,
    sig_name = "TAHOE",
    disease_file = disease_file,
    disease_name = disease_name,
    batch_ts = batch_ts,
    meta_path = tahoe_meta
  )
  
  # Add to summary
  results_summary <- rbind(results_summary, data.frame(
    disease = disease_name,
    signature_type = "TAHOE",
    status = ifelse(tahoe_result$success, "SUCCESS", "FAILED"),
    output_dir = tahoe_result$out_dir,
    error_message = ifelse(is.null(tahoe_result$error_msg), "", tahoe_result$error_msg),
    stringsAsFactors = FALSE
  ))
  
  # Log results
  log_conn <- file(batch_log_file, open = "at")
  writeLines(paste("  CMAP:", ifelse(cmap_result$success, "SUCCESS", "FAILED")), log_conn)
  writeLines(paste("  TAHOE:", ifelse(tahoe_result$success, "SUCCESS", "FAILED")), log_conn)
  close(log_conn)
  
  # Report results
  report_conn <- file(batch_report_file, open = "at")
  writeLines(paste("  CMAP:", ifelse(cmap_result$success, "SUCCESS", "FAILED")), report_conn)
  if (!cmap_result$success && !is.null(cmap_result$error_msg)) {
    writeLines(paste("    Error:", cmap_result$error_msg), report_conn)
  }
  writeLines(paste("  TAHOE:", ifelse(tahoe_result$success, "SUCCESS", "FAILED")), report_conn)
  if (!tahoe_result$success && !is.null(tahoe_result$error_msg)) {
    writeLines(paste("    Error:", tahoe_result$error_msg), report_conn)
  }
  close(report_conn)
}

# Save summary
summary_file <- file.path(out_root, paste0("batch_run_summary_", batch_ts, ".csv"))
write.csv(results_summary, summary_file, row.names = FALSE)

# Also save summary to reports directory
summary_report_file <- file.path(report_dir, paste0("sirota_lab_batch_summary_", batch_ts, ".csv"))
write.csv(results_summary, summary_report_file, row.names = FALSE)

# Print final summary
cat("\n\n")
cat("================================================================================\n")
cat("BATCH RUN COMPLETED - SIROTA LAB\n")
cat("================================================================================\n")
cat("Total diseases processed:", length(disease_files), "\n")
cat("Total runs (CMAP + TAHOE):", nrow(results_summary), "\n")
cat("Successful runs:", sum(results_summary$status == "SUCCESS"), "\n")
cat("Failed runs:", sum(results_summary$status == "FAILED"), "\n")
cat("\nSummary saved to:", summary_file, "\n")
cat("Log saved to:", batch_log_file, "\n")

# Log final summary
log_conn <- file(batch_log_file, open = "at")
writeLines("\n================================================================================", log_conn)
writeLines("BATCH RUN COMPLETED - SIROTA LAB", log_conn)
writeLines("================================================================================", log_conn)
writeLines(paste("Batch run ended at:", Sys.time()), log_conn)
writeLines(paste("Total diseases processed:", length(disease_files)), log_conn)
writeLines(paste("Total runs (CMAP + TAHOE):", nrow(results_summary)), log_conn)
writeLines(paste("Successful runs:", sum(results_summary$status == "SUCCESS")), log_conn)
writeLines(paste("Failed runs:", sum(results_summary$status == "FAILED")), log_conn)
close(log_conn)

# Write final summary to report
report_conn <- file(batch_report_file, open = "at")
writeLines("\n================================================================================", report_conn)
writeLines("FINAL SUMMARY", report_conn)
writeLines("================================================================================", report_conn)
writeLines(paste("Batch run ended at:", Sys.time()), report_conn)
writeLines(paste("Total diseases processed:", length(disease_files)), report_conn)
writeLines(paste("Total runs (CMAP + TAHOE):", nrow(results_summary)), report_conn)
writeLines(paste("Successful runs:", sum(results_summary$status == "SUCCESS")), report_conn)
writeLines(paste("Failed runs:", sum(results_summary$status == "FAILED")), report_conn)
writeLines("", report_conn)
writeLines("Summary CSV saved to:", report_conn)
writeLines(paste("  -", summary_file), report_conn)
writeLines(paste("  -", summary_report_file), report_conn)
writeLines("", report_conn)
writeLines("Results directory:", report_conn)
writeLines(paste("  -", out_root), report_conn)
close(report_conn)

# Print failures if any
if (sum(results_summary$status == "FAILED") > 0) {
  cat("\nFailed runs:\n")
  failed <- results_summary[results_summary$status == "FAILED", ]
  for (i in 1:nrow(failed)) {
    cat("  -", failed$disease[i], "(", failed$signature_type[i], "):", failed$error_message[i], "\n")
  }
  
  # Write failures to report
  report_conn <- file(batch_report_file, open = "at")
  writeLines("FAILED RUNS:", report_conn)
  for (i in 1:nrow(failed)) {
    writeLines(paste("  -", failed$disease[i], "(", failed$signature_type[i], "):", failed$error_message[i]), report_conn)
  }
  close(report_conn)
}

cat("\nAll results saved in:", out_root, "\n")
cat("Report saved to:", batch_report_file, "\n")
