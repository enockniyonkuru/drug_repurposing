#!/usr/bin/env Rscript
# Test script to verify the skip logic works for disease 50

suppressPackageStartupMessages(library(DRpipe))

disease_dir <- "../data/disease_signatures/creeds_manual_disease_signatures"
out_root <- "../results/creeds_manual_disease_results_filtered"

# Get existing directories
existing_dirs <- list.dirs(out_root, full.names = FALSE, recursive = FALSE)
cat("Found", length(existing_dirs), "existing result folders\n\n")

# Get disease files
disease_files <- list.files(disease_dir, pattern = "_signature\\.csv$", full.names = TRUE)

# Test disease 50
disease_file <- disease_files[50]
disease_name <- gsub("_signature\\.csv$", "", basename(disease_file))

cat("Testing Disease 50:\n")
cat("  Name:", disease_name, "\n")

# Apply the fix - use fixed matching instead of regex to avoid escaping issues
disease_pattern <- paste0(disease_name, "_")

cat("  Escaped pattern:", disease_pattern, "\n")

# Check for matches
matches <- grep(disease_pattern, existing_dirs, value = TRUE)
cat("  Matches found:", length(matches), "\n")

if (length(matches) > 0) {
  cat("  Matched directories:\n")
  for (m in matches) {
    cat("    -", m, "\n")
  }
}

# Use fixed=TRUE and startsWith for exact matching
already_processed <- any(startsWith(existing_dirs, disease_pattern))
cat("  Should skip:", already_processed, "\n")

if (already_processed) {
  cat("\n✓ SUCCESS: Disease 50 will be SKIPPED (fix is working!)\n")
} else {
  cat("\n✗ FAILURE: Disease 50 will be PROCESSED (fix is NOT working)\n")
}
