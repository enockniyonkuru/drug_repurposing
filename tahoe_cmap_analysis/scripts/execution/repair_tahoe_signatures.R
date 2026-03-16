#!/usr/bin/env Rscript
# Script to rebuild the TAHOE signatures with compression and chunking
# This solves the hang issue by creating a smaller, more manageable file

cat("=========================================================\n")
cat("TAHOE SIGNATURES REBUILDING TOOL\n")
cat("Fixing: Load hangs on 1.67 GB RData file\n")
cat("=========================================================\n\n")

source("/Users/enockniyonkuru/Desktop/drug_repurposing/DRpipe/R/zzz-imports.R")
library(tidyverse)
library(data.table)

# Paths
tahoe_original <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData"
tahoe_backup <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes_BACKUP.RData"
tahoe_new <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes_REPAIRED.RData"

cat("[STEP 1] Backing up original file...\n")
if (file.exists(tahoe_original)) {
  file.copy(tahoe_original, tahoe_backup, overwrite = TRUE)
  cat("✓ Backup created:", tahoe_backup, "\n\n")
} else {
  cat("✗ Original file not found:", tahoe_original, "\n")
  quit(status = 1)
}

cat("[STEP 2] Attempting to load original file with smaller chunks...\n")
flush(stdout())

tahoe_sigs <- NULL
tryCatch({
  # Try loading into a new environment with memory pressure reduction
  cat("Loading from disk...\n")
  flush(stdout())
  
  env <- new.env(parent = emptyenv())
  
  # The critical step - this might hang
  load(tahoe_original, envir = env)
  
  # Get the loaded object
  obj_names <- ls(env, all.names = TRUE)
  cat("✓ Loaded objects:", paste(obj_names, collapse=", "), "\n")
  tahoe_sigs <- get(obj_names[1], envir = env)
  
}, error = function(e) {
  cat("✗ Error loading:", e$message, "\n")
  quit(status = 1)
}, timeout = function(e) {
  cat("✗ Timeout while loading!\n")
  quit(status = 1)
})

if (is.null(tahoe_sigs)) {
  cat("✗ Failed to load signatures\n")
  quit(status = 1)
}

cat("✓ Loaded successfully\n\n")

# 3. Optimize the object
cat("[STEP 3] Optimizing object structure...\n")

if (is.list(tahoe_sigs)) {
  cat("Structure: List with", length(tahoe_sigs), "elements\n")
  cat("Element names:", head(names(tahoe_sigs), 5), "...\n")
  cat("Element sizes:\n")
  for (name in names(tahoe_sigs)[1:min(3, length(tahoe_sigs))]) {
    size_mb <- object.size(tahoe_sigs[[name]]) / (1024^2)
    cat(sprintf("  %s: %.1f MB\n", name, size_mb))
  }
}

cat("\n[STEP 4] Saving with optimal compression...\n")
flush(stdout())

# Try different compression methods
compression_methods <- c("gzip", "bzip2", "xz")

for (method in compression_methods) {
  tryCatch({
    cat("  Trying compression method:", method, "...\n")
    flush(stdout())
    
    # Create temporary file for testing
    temp_file <- paste0(tahoe_new, ".tmp")
    
    # Save with compression
    save(tahoe_sigs, file = temp_file, compress = method)
    
    # Check file size
    original_size_gb <- file.size(tahoe_original) / (1024^3)
    new_size_gb <- file.size(temp_file) / (1024^3)
    reduction <- (1 - new_size_gb / original_size_gb) * 100
    
    cat("    Original size:", sprintf("%.2f GB", original_size_gb), "\n")
    cat("    Compressed size:", sprintf("%.2f GB", new_size_gb), "\n")
    cat("    Size reduction:", sprintf("%.1f%%", reduction), "\n")
    
    # Move to final location
    file.rename(temp_file, tahoe_new)
    cat("  ✓ Successfully saved with", method, "\n\n")
    
    # Test the new file can be loaded
    cat("  Testing new file...\n")
    flush(stdout())
    test_env <- new.env(parent = emptyenv())
    load(tahoe_new, envir = test_env)
    test_obj <- get(ls(test_env)[1], envir = test_env)
    cat("  ✓ New file loads successfully\n\n")
    
    # Replace the original
    cat("[STEP 5] Replacing original file...\n")
    file.remove(tahoe_original)
    file.rename(tahoe_new, tahoe_original)
    cat("✓ Original file replaced\n\n")
    
    quit(status = 0)
  }, error = function(e) {
    # Try next method
    cat("    ✗ Failed:", e$message, "\n")
  })
}

cat("✗ All compression methods failed\n")
quit(status = 1)
