#!/usr/bin/env Rscript

# Debug script to investigate drug overlaps more carefully

library(tidyverse)
library(arrow)

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data...\n")

# Load CMap and Tahoe drug lists
cmap_drugs <- read.csv('tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_drug_experiments_new.csv')
tahoe_drugs_df <- read.csv('tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv')

# Get unique drugs with different normalization approaches
cat("\n=== Approach 1: Full normalization (lowercase + trim) ===\n")
unique_cmap_norm <- unique(tolower(trimws(cmap_drugs$name)))
unique_tahoe_norm <- unique(tolower(trimws(tahoe_drugs_df$name)))

both_platforms_norm <- intersect(unique_cmap_norm, unique_tahoe_norm)
cat("Drugs in both CMap and Tahoe (normalized):", length(both_platforms_norm), "\n")

cat("\n=== Approach 2: No normalization ===\n")
unique_cmap_orig <- unique(cmap_drugs$name)
unique_tahoe_orig <- unique(tahoe_drugs_df$name)

both_platforms_orig <- intersect(unique_cmap_orig, unique_tahoe_orig)
cat("Drugs in both CMap and Tahoe (original):", length(both_platforms_orig), "\n")

cat("\n=== Approach 3: Case-insensitive only ===\n")
unique_cmap_case <- unique(tolower(cmap_drugs$name))
unique_tahoe_case <- unique(tolower(tahoe_drugs_df$name))

both_platforms_case <- intersect(unique_cmap_case, unique_tahoe_case)
cat("Drugs in both CMap and Tahoe (case-insensitive):", length(both_platforms_case), "\n")

# Check first few entries to understand the data
cat("\n=== Sample CMap drugs ===\n")
print(head(unique_cmap_orig, 10))

cat("\n=== Sample Tahoe drugs ===\n")
print(head(unique_tahoe_orig, 10))

# Try grepl-based matching (more flexible)
cat("\n=== Approach 4: Using fuzzy matching on exact case-insensitive names ===\n")
both_fuzzy <- c()
for (drug in unique_tahoe_orig) {
  drug_lower <- tolower(trimws(drug))
  matches <- unique_cmap_orig[tolower(trimws(unique_cmap_orig)) == drug_lower]
  if (length(matches) > 0) {
    both_fuzzy <- c(both_fuzzy, drug)
  }
}
cat("Drugs in both platforms (fuzzy):", length(both_fuzzy), "\n")

# Save samples of what overlaps
cat("\n=== Sample of overlapping drugs ===\n")
if (length(both_platforms_norm) > 0) {
  print(head(sort(both_platforms_norm), 20))
}
