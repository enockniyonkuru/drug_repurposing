#!/usr/bin/env Rscript

# Check if 85 refers to experiment counts or instances, not unique names

library(tidyverse)
library(arrow)

cat("Loading data...\n")

# Load CMap and Tahoe drug lists
cmap_drugs <- read.csv('tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_drug_experiments_new.csv')
tahoe_drugs_df <- read.csv('tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv')

cat("\n=== Data Dimensions ===\n")
cat("CMap rows (experiments/instances):", nrow(cmap_drugs), "\n")
cat("Tahoe rows (experiments/instances):", nrow(tahoe_drugs_df), "\n")

# Get unique drug names
unique_cmap_norm <- unique(tolower(trimws(cmap_drugs$name)))
unique_tahoe_norm <- unique(tolower(trimws(tahoe_drugs_df$name)))

cat("\nCMap unique drugs:", length(unique_cmap_norm), "\n")
cat("Tahoe unique drugs:", length(unique_tahoe_norm), "\n")

# Find overlapping drugs
both_drugs_norm <- intersect(unique_cmap_norm, unique_tahoe_norm)
cat("\nDrugs in BOTH (unique names):", length(both_drugs_norm), "\n")

# Count experiments/instances for overlapping drugs
cat("\n=== Counting Experiments for Overlapping Drugs ===\n")

cmap_experiments_for_both <- sum(tolower(trimws(cmap_drugs$name)) %in% both_drugs_norm)
tahoe_experiments_for_both <- sum(tolower(trimws(tahoe_drugs_df$name)) %in% both_drugs_norm)

cat("CMap experiments for shared drugs:", cmap_experiments_for_both, "\n")
cat("Tahoe experiments for shared drugs:", tahoe_experiments_for_both, "\n")
cat("Total experiments (CMap + Tahoe) for shared drugs:", cmap_experiments_for_both + tahoe_experiments_for_both, "\n")

# Check the shared drugs data file if it exists
cat("\n=== Checking for shared drugs data file ===\n")
shared_drugs_file <- 'tahoe_cmap_analysis/data/shared_drugs_cmap_tahoe.csv'
if (file.exists(shared_drugs_file)) {
  shared_df <- read.csv(shared_drugs_file)
  cat("Found shared_drugs_cmap_tahoe.csv\n")
  cat("Rows:", nrow(shared_df), "\n")
  cat("Columns:", colnames(shared_df), "\n\n")
  print(head(shared_df, 10))
} else {
  cat("shared_drugs_cmap_tahoe.csv not found\n")
}
