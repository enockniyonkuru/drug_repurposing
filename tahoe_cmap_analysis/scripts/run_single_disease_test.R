#!/usr/bin/env Rscript
# Test script to run a single disease with both CMAP and TAHOE drug signatures
# NOTE: Runs BOTH CMAP and TAHOE experiments automatically
# Usage: Rscript run_single_disease_test.R <disease_file_path>

suppressPackageStartupMessages(library(DRpipe))

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: Rscript run_single_disease_test.R <disease_file_path>\n")
  cat("Example: Rscript run_single_disease_test.R /Users/enockniyonkuru/Desktop/tahoe_analysis/data/disease_signature/creeds_disease_signature/Acute_lung_injury_signature.csv\n")
  cat("NOTE: This will run BOTH CMAP and TAHOE experiments automatically\n")
  quit(status = 1)
}

disease_file <- args[1]

# Verify file exists
if (!file.exists(disease_file)) {
  cat("Error: Disease file not found:", disease_file, "\n")
  quit(status = 1)
}

# Extract disease name from filename (remove _signature.csv)
disease_name <- basename(disease_file)
disease_name <- gsub("_signature\\.csv$", "", disease_name)
cat("Processing disease:", disease_name, "\n")

# Preprocess the disease file to match DRpipe format
cat("Preprocessing disease file...\n")
preprocessed_file <- tempfile(fileext = ".csv")
df <- read.csv(disease_file, stringsAsFactors = FALSE)
if (!"gene_symbol" %in% colnames(df)) {
  cat("Error: gene_symbol column not found\n")
  quit(status = 1)
}
if (!"common_experiment" %in% colnames(df)) {
  cat("Error: common_experiment column not found\n")
  quit(status = 1)
}
# Rename and keep only needed columns
colnames(df)[colnames(df) == "gene_symbol"] <- "SYMBOL"
colnames(df)[colnames(df) == "common_experiment"] <- "log2FC"
df_out <- df[, c("SYMBOL", "log2FC")]
write.csv(df_out, preprocessed_file, row.names = FALSE, quote = FALSE)
cat("Preprocessed file created with", nrow(df_out), "genes\n")
disease_file <- preprocessed_file

# CMAP configuration
cmap_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/drug_rep_cmap_ranks_shared_genes_drugs.RData"
cmap_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/cmap_drug_experiments_new.csv"

# TAHOE configuration
tahoe_signatures <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/drug_rep_tahoe_ranks_shared_genes_drugs.RData"
tahoe_meta <- "/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/data/tahoe_drug_experiments_new.csv"

# Verify drug signature files exist
if (!file.exists(cmap_signatures)) {
  cat("Error: CMAP signatures file not found:", cmap_signatures, "\n")
  quit(status = 1)
}
if (!file.exists(tahoe_signatures)) {
  cat("Error: TAHOE signatures file not found:", tahoe_signatures, "\n")
  quit(status = 1)
}

# Common parameters
# NOTE: cmap_valid is set to NULL to skip filtering by cmap_valid_instances.csv
cmap_valid <- NULL
out_root <- "results"

# Create timestamp
ts <- format(Sys.time(), "%Y%m%d-%H%M%S")

# Helper function to run pipeline
run_pipeline <- function(sig_path, sig_name, disease_file, disease_name, ts, meta_path) {
  cat("\n========================================\n")
  cat("Running", sig_name, "for", disease_name, "\n")
  cat("========================================\n")
  
  # Create output directory
  folder_name <- paste0(disease_name, "_", sig_name, "_", ts)
  out_dir <- file.path(out_root, folder_name)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Initialize DRP object
  # NOTE: cmap_valid_path is NULL to skip filtering by cmap_valid_instances.csv
  # NOTE: cmap_meta_path uses the appropriate metadata file (CMAP or TAHOE)
  drp <- DRP$new(
    signatures_rdata = sig_path,
    disease_path     = disease_file,
    disease_pattern  = NULL,
    cmap_meta_path   = meta_path,
    cmap_valid_path  = NULL,  # Do NOT filter by cmap_valid_instances.csv
    out_dir          = out_dir,
    gene_key         = "SYMBOL",
    logfc_cols_pref  = "log2FC",
    logfc_cutoff     = 0.05,
    pval_key         = NULL,
    pval_cutoff      = 0.05,
    q_thresh         = 0.05,
    reversal_only    = TRUE,
    seed             = 123,
    verbose          = TRUE,
    analysis_id      = sig_name,  # Pass "CMAP" or "TAHOE" as analysis_id
    mode             = "single",
    gene_conversion_table = "/Users/enockniyonkuru/Desktop/gene_id_conversion_table.tsv"
  )
  
  # Run the pipeline with plots
  tryCatch({
    drp$run_all(make_plots = TRUE)
    cat("\n[SUCCESS]", sig_name, "analysis completed for", disease_name, "\n")
    cat("Results saved to:", out_dir, "\n")
  }, error = function(e) {
    cat("\n[ERROR]", sig_name, "analysis failed for", disease_name, "\n")
    cat("Error message:", conditionMessage(e), "\n")
  })
  
  return(out_dir)
}

# Run with CMAP signatures
cmap_out <- run_pipeline(
  sig_path = cmap_signatures,
  sig_name = "CMAP",
  disease_file = disease_file,
  disease_name = disease_name,
  ts = ts,
  meta_path = cmap_meta
)

# Run with TAHOE signatures
tahoe_out <- run_pipeline(
  sig_path = tahoe_signatures,
  sig_name = "TAHOE",
  disease_file = disease_file,
  disease_name = disease_name,
  ts = ts,
  meta_path = tahoe_meta
)

cat("\n========================================\n")
cat("TEST COMPLETED\n")
cat("========================================\n")
cat("Disease:", disease_name, "\n")
cat("CMAP results:", cmap_out, "\n")
cat("TAHOE results:", tahoe_out, "\n")
cat("\nNOTE: Column alignment in drug signatures:\n")
cat("  - V1 = Gene IDs\n")
cat("  - V2, V3, V4... = Experiment data\n")
cat("  - To get actual experiment ID: experiment_id = column_number - 1\n")
cat("  - Example: V2 corresponds to experiment ID 1, V3 to experiment ID 2, etc.\n")
