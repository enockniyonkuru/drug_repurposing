#!/usr/bin/env Rscript
#' Convert Filtered Tahoe Parquet to RData
#'
#' Converts tahoe_signatures_shared_genes.parquet to RData format
#'

suppressPackageStartupMessages({
  library(arrow)
})

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  sub("^--file=", "", file_arg[1])
} else {
  file.path(getwd(), "scripts", "preprocessing", "convert_filtered_tahoe_to_rdata.R")
}
script_dir <- dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE))
repo_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = FALSE)

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("Converting Filtered Tahoe Signatures to RData\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")

# Paths
parquet_file <- file.path(repo_root, "data", "drug_signatures", "tahoe", "tahoe_signatures_shared_genes.parquet")
output_rdata <- file.path(repo_root, "data", "drug_signatures", "tahoe", "tahoe_signatures_shared_genes.RData")

cat("\n[1/3] Reading filtered parquet file...\n")
cat(sprintf("      File: %s\n", parquet_file))

if (!file.exists(parquet_file)) {
  stop(sprintf("Error: File not found: %s", parquet_file))
}

tahoe_filtered <- read_parquet(parquet_file)

cat(sprintf("      ✓ Loaded: %s rows × %s columns\n", 
            format(nrow(tahoe_filtered), big.mark=","),
            format(ncol(tahoe_filtered), big.mark=",")))

cat("\n[2/3] Verifying data structure...\n")
cat(sprintf("      Memory: ~%.1f MB\n", object.size(tahoe_filtered) / (1024^2)))
cat(sprintf("      First column: %s\n", colnames(tahoe_filtered)[1]))

cat("\n[3/3] Saving to RData...\n")
cat(sprintf("      File: %s\n", output_rdata))

save(tahoe_filtered, file = output_rdata)

cat("      ✓ Successfully saved!\n")

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("CONVERSION COMPLETE\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat(sprintf("\nOutput: %s\n\n", output_rdata))
