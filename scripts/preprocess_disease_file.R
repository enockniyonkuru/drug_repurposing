#!/usr/bin/env Rscript
#' Preprocess Disease Signature Files
#'
#' Standardizes disease signature files to match DRpipe expected format.
#' Renames columns (gene_symbol to SYMBOL, mean_logfc to log2FC) for
#' compatibility with downstream analysis pipeline.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  cat("Usage: Rscript preprocess_disease_file.R <input_file> <output_file>\n")
  quit(status = 1)
}

input_file <- args[1]
output_file <- args[2]

# Read the disease file
df <- read.csv(input_file, stringsAsFactors = FALSE)

# Check if gene_symbol column exists
if (!"gene_symbol" %in% colnames(df)) {
  cat("Error: gene_symbol column not found in", input_file, "\n")
  cat("Available columns:", paste(colnames(df), collapse = ", "), "\n")
  quit(status = 1)
}

# Rename gene_symbol to SYMBOL and mean_logfc to log2FC
colnames(df)[colnames(df) == "gene_symbol"] <- "SYMBOL"

# Rename mean_logfc to log2FC to match DRpipe expected format
if ("mean_logfc" %in% colnames(df)) {
  colnames(df)[colnames(df) == "mean_logfc"] <- "log2FC"
  df_out <- df[, c("SYMBOL", "log2FC")]
} else {
  cat("Error: mean_logfc column not found in", input_file, "\n")
  cat("Available columns:", paste(colnames(df), collapse = ", "), "\n")
  quit(status = 1)
}

# Write output
write.csv(df_out, output_file, row.names = FALSE, quote = FALSE)
cat("Preprocessed file saved to:", output_file, "\n")
cat("Rows:", nrow(df_out), "\n")
cat("Columns:", paste(colnames(df_out), collapse = ", "), "\n")
