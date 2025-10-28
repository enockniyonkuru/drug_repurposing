#!/usr/bin/env Rscript
# Batch script to run all disease signatures with both CMAP and TAHOE drug signatures
# This script processes all disease files in the CREEDS disease signature directory
# NOTE: Runs BOTH CMAP and TAHOE experiments for each disease automatically

suppressPackageStartupMessages(library(DRpipe))

# Define paths
disease_dir <- "/Users/enockniyonkuru/Desktop/tahoe_analysis/data/disease_signature/creeds_disease_signature"

# disease_dir <-"/Users/enockniyonkuru/Desktop/tahoe_analysis/data/disease_signature/temp_disease_signature"
# CMAP configuration
cmap_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/drug_rep_cmap_ranks_shared_genes_drugs.RData"
cmap_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/cmap_drug_experiments_new.csv"

# TAHOE configuration
tahoe_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/drug_rep_tahoe_ranks_shared_genes_drugs.RData"
tahoe_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/tahoe_drug_experiments_new.csv"

# Common parameters
# NOTE: cmap_valid is set to NULL to skip filtering by cmap_valid_instances.csv
cmap_valid <- NULL
out_root <- "results"

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
cat("Found", length(disease_files), "disease signature files\n\n")
cat("Diseases to process:\n")
for (f in disease_files) {
  cat("  -", gsub("_signature\\.csv$", "", basename(f)), "\n")
}
cat("\n")

# Create timestamp for this batch run
batch_ts <- format(Sys.time(), "%Y%m%d-%H%M%S")
batch_log_file <- file.path(out_root, paste0("batch_run_log_", batch_ts, ".txt"))

# Create results directory if it doesn't exist
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

# Initialize log
log_conn <- file(batch_log_file, open = "wt")
writeLines(paste("Batch run started at:", Sys.time()), log_conn)
writeLines(paste("Total diseases to process:", length(disease_files)), log_conn)
writeLines(paste("Drug signatures: CMAP and TAHOE"), log_conn)
writeLines(paste("LogFC cutoff: 0.05"), log_conn)
writeLines(paste("P-value filtering: None"), log_conn)
writeLines("", log_conn)
close(log_conn)

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
  # NOTE: cmap_valid_path is NULL to skip filtering by cmap_valid_instances.csv
  # NOTE: cmap_meta_path uses the appropriate metadata file (CMAP or TAHOE)
  # NOTE: Using very lenient settings to maximize hits
  drp <- DRP$new(
    signatures_rdata = sig_path,
    disease_path     = disease_file,
    disease_pattern  = NULL,
    cmap_meta_path   = meta_path,
    cmap_valid_path  = NULL,  # Do NOT filter by cmap_valid_instances.csv
    out_dir          = out_dir,
    gene_key         = "SYMBOL",
    logfc_cols_pref  = "log2FC",
    logfc_cutoff     = 0.0,    # NO logFC filtering - accept all genes
    pval_key         = NULL,   # NO p-value filtering
    pval_cutoff      = 1.0,    # Accept all p-values (if pval_key were set)
    q_thresh         = 1.0,    # Accept all q-values - very lenient!
    reversal_only    = FALSE,  # Accept both reversal AND mimicry
    seed             = 123,
    verbose          = TRUE,
    analysis_id      = sig_name,  # Pass "CMAP" or "TAHOE" as analysis_id
    mode             = "single",
    gene_conversion_table = "/Users/enockniyonkuru/Desktop/gene_id_conversion_table.tsv"
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
  
  # Log to file
  log_conn <- file(batch_log_file, open = "at")
  writeLines(paste("\n[", Sys.time(), "] Processing:", disease_name, "(", i, "of", length(disease_files), ")"), log_conn)
  close(log_conn)
  
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
}

# Save summary
summary_file <- file.path(out_root, paste0("batch_run_summary_", batch_ts, ".csv"))
write.csv(results_summary, summary_file, row.names = FALSE)

# Print final summary
cat("\n\n")
cat("================================================================================\n")
cat("BATCH RUN COMPLETED\n")
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
writeLines("BATCH RUN COMPLETED", log_conn)
writeLines("================================================================================", log_conn)
writeLines(paste("Batch run ended at:", Sys.time()), log_conn)
writeLines(paste("Total diseases processed:", length(disease_files)), log_conn)
writeLines(paste("Total runs (CMAP + TAHOE):", nrow(results_summary)), log_conn)
writeLines(paste("Successful runs:", sum(results_summary$status == "SUCCESS")), log_conn)
writeLines(paste("Failed runs:", sum(results_summary$status == "FAILED")), log_conn)
close(log_conn)

# Print failures if any
if (sum(results_summary$status == "FAILED") > 0) {
  cat("\nFailed runs:\n")
  failed <- results_summary[results_summary$status == "FAILED", ]
  for (i in 1:nrow(failed)) {
    cat("  -", failed$disease[i], "(", failed$signature_type[i], "):", failed$error_message[i], "\n")
  }
}

cat("\nAll results saved in:", out_root, "\n")
cat("\nNOTE: Column alignment in drug signatures:\n")
cat("  - V1 = Gene IDs\n")
cat("  - V2, V3, V4... = Experiment data\n")
cat("  - To get actual experiment ID: experiment_id = column_number - 1\n")
cat("  - Example: V2 corresponds to experiment ID 1, V3 to experiment ID 2, etc.\n")





