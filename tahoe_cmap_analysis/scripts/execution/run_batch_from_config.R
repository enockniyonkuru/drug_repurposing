#!/usr/bin/env Rscript
#' Run DRpipe Batch Analysis from Configuration File
#'
#' Reads parameters from a YAML configuration file and executes the DRpipe
#' batch analysis pipeline. This wrapper provides a simpler interface compared
#' to passing individual command-line arguments.
#'
#' Usage:
#'   Rscript run_batch_from_config.R --config_file path/to/config.yml
#'

suppressPackageStartupMessages(library(argparse))
suppressPackageStartupMessages(library(yaml))

# Define command-line arguments
parser <- ArgumentParser(description = "Run batch DRpipe analysis from YAML config file")
parser$add_argument("--config_file", type = "character", required = TRUE, 
                    help = "Path to YAML configuration file")

# Parse arguments
args <- parser$parse_args()

config_file <- args$config_file

# Check if config file exists
if (!file.exists(config_file)) {
  cat("Error: Configuration file not found:", config_file, "\n")
  quit(status = 1)
}

# Load configuration
tryCatch({
  config <- yaml::read_yaml(config_file)
}, error = function(e) {
  cat("Error reading configuration file:", conditionMessage(e), "\n")
  quit(status = 1)
})

# Validate required configuration sections
required_sections <- c("disease", "cmap", "tahoe", "analysis", "output", "runtime")
for (section in required_sections) {
  if (is.null(config[[section]])) {
    cat("Error: Missing required configuration section:", section, "\n")
    quit(status = 1)
  }
}

# Extract values from configuration with validation
tryCatch({
  disease_dir      <- config$disease$directory
  disease_source   <- config$disease$source
  cmap_signatures  <- config$cmap$signatures
  cmap_meta        <- config$cmap$metadata
  tahoe_signatures <- config$tahoe$signatures
  tahoe_meta       <- config$tahoe$metadata
  gene_conv_table  <- config$analysis$gene_table
  gene_key         <- config$analysis$gene_key %||% "gene_symbol"
  logfc_cols_pref  <- config$analysis$logfc_cols_pref %||% "logfc_dz"
  logfc_col_select <- config$analysis$logfc_column_selection %||% "all"
  use_averaging    <- config$analysis$use_averaging
  out_root         <- config$output$root_directory
  report_dir       <- config$output$report_directory
  report_prefix    <- config$output$report_prefix
  skip_existing    <- as.logical(config$runtime$skip_existing_results)
  verbose          <- as.logical(config$runtime$verbose)
  start_from       <- config$runtime$start_from_disease %||% 1
  end_at           <- config$runtime$end_at_disease
  
  # Handle NA values and defaults
  if (is.na(skip_existing)) skip_existing <- FALSE
  if (is.na(verbose)) verbose <- TRUE
  if (is.na(use_averaging)) use_averaging <- TRUE
  if (is.na(start_from) || is.null(start_from)) start_from <- 1
  if (!is.null(end_at) && is.na(end_at)) end_at <- NULL
  
}, error = function(e) {
  cat("Error extracting configuration values:", conditionMessage(e), "\n")
  quit(status = 1)
})

# Print configuration summary
if (verbose) {
  cat("\n================================================================================\n")
  cat("BATCH RUN CONFIGURATION SUMMARY\n")
  cat("================================================================================\n")
  cat("Config file:", config_file, "\n")
  cat("\nDisease Configuration:\n")
  cat("  Source:", disease_source, "\n")
  cat("  Directory:", disease_dir, "\n")
  cat("\nCMAP Configuration:\n")
  cat("  Signatures:", cmap_signatures, "\n")
  cat("  Metadata:", cmap_meta, "\n")
  cat("\nTAHOE Configuration:\n")
  cat("  Signatures:", tahoe_signatures, "\n")
  cat("  Metadata:", tahoe_meta, "\n")
  cat("\nAnalysis Configuration:\n")
  cat("  Gene table:", gene_conv_table, "\n")
  cat("  LogFC cutoff:", config$analysis$logfc_cutoff, "\n")
  cat("  Q-value threshold:", config$analysis$qval_threshold, "\n")
  cat("  LogFC column selection:", ifelse(is.character(logfc_col_select) && logfc_col_select == "all", "all", paste(logfc_col_select, collapse=", ")), "\n")
  cat("  Use averaging:", use_averaging, "\n")
  cat("\nOutput Configuration:\n")
  cat("  Root directory:", out_root, "\n")
  cat("  Report directory:", report_dir, "\n")
  cat("  Report prefix:", report_prefix, "\n")
  cat("\nRuntime Options:\n")
  cat("  Skip existing results:", skip_existing, "\n")
  cat("  Verbose:", verbose, "\n")
  cat("  Start from disease:", start_from, "\n")
  cat("  End at disease:", ifelse(is.null(end_at), "(all remaining)", end_at), "\n")
  cat("================================================================================\n\n")
}

# Build command to call run_drpipe_batch.R
# Get the directory of this script
script_dir <- dirname(normalizePath(config_file))

# If config is in batch_configs subdirectory, go up to execution directory
if (basename(script_dir) == "batch_configs") {
  script_dir <- dirname(script_dir)
}

drpipe_batch_script <- file.path(script_dir, "run_drpipe_batch.R")

# Check if the script exists
if (!file.exists(drpipe_batch_script)) {
  cat("Error: run_drpipe_batch.R not found at:", drpipe_batch_script, "\n")
  quit(status = 1)
}

if (verbose) {
  cat("Using batch script:", drpipe_batch_script, "\n\n")
}

# Build command line arguments
cmd_args <- c(
  sprintf("--disease_dir '%s'", disease_dir),
  sprintf("--disease_source '%s'", disease_source),
  sprintf("--cmap_sig '%s'", cmap_signatures),
  sprintf("--cmap_meta '%s'", cmap_meta),
  sprintf("--tahoe_sig '%s'", tahoe_signatures),
  sprintf("--tahoe_meta '%s'", tahoe_meta),
  sprintf("--gene_table '%s'", gene_conv_table),
  sprintf("--gene_key '%s'", gene_key),
  sprintf("--logfc_cols_pref '%s'", logfc_cols_pref),
  sprintf("--out_root '%s'", out_root),
  sprintf("--report_dir '%s'", report_dir),
  sprintf("--report_prefix '%s'", report_prefix),
  sprintf("--start_from %d", start_from)
)

if (skip_existing) {
  cmd_args <- c(cmd_args, "--skip_existing TRUE")
}

if (!is.null(end_at)) {
  cmd_args <- c(cmd_args, sprintf("--end_at %d", end_at))
}

# Handle logfc column selection (can be "all" or specific columns)
if (is.character(logfc_col_select) && length(logfc_col_select) == 1) {
  cmd_args <- c(cmd_args, sprintf("--logfc_col_select '%s'", logfc_col_select))
} else if (is.character(logfc_col_select) && length(logfc_col_select) > 1) {
  # Multiple columns: join with comma
  cmd_args <- c(cmd_args, sprintf("--logfc_col_select '%s'", paste(logfc_col_select, collapse=",")))
}

if (!use_averaging) {
  cmd_args <- c(cmd_args, "--use_averaging FALSE")
}

# Execute the batch script
cmd <- paste("Rscript", drpipe_batch_script, paste(cmd_args, collapse = " "))

if (verbose) {
  cat("Executing command:\n")
  cat(cmd, "\n\n")
}

# Run the script
exit_code <- system(cmd)

if (exit_code != 0) {
  cat("\nError: Batch script failed with exit code", exit_code, "\n")
  quit(status = exit_code)
} else {
  if (verbose) {
    cat("\nBatch script completed successfully!\n")
  }
}