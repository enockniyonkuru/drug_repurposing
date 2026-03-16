#!/usr/bin/env Rscript
# Convert RData files to RDS format using GZIP (faster) instead of XZ

cat("\n")
cat("=========================================================\n")
cat("CONVERTING RDATA FILES TO RDS FORMAT\n")
cat("Using gzip compression (faster, less CPU intensive)\n")
cat("=========================================================\n\n")

# File paths
tahoe_rdata <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData"
tahoe_rds <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.rds"

cmap_rdata <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.RData"
cmap_rds <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.rds"

# Function to convert with progress
convert_rdata_to_rds <- function(rdata_path, rds_path, name) {
  cat("[CONVERTING]", basename(rdata_path), "\n")
  
  # Check file exists
  if (!file.exists(rdata_path)) {
    cat("  ✗ ERROR: File not found\n")
    return(FALSE)
  }
  
  file_size_gb <- file.size(rdata_path) / (1024^3)
  cat("  File size:", sprintf("%.2f GB", file_size_gb), "\n")
  
  # Load RData
  cat("  [STEP 1/2] Loading RData into memory...\n")
  flush(stdout())
  
  start_load <- Sys.time()
  tryCatch({
    env <- new.env(parent = emptyenv())
    load(rdata_path, envir = env)
    
    obj_names <- ls(env)
    obj <- get(obj_names[1], envir = env)
    obj_size <- object.size(obj) / (1024^3)
    
    elapsed_load <- difftime(Sys.time(), start_load, units = "secs")
    cat("    ✓ Loaded successfully in", sprintf("%.1f seconds", as.numeric(elapsed_load)), "\n")
    cat("    Object size in memory:", sprintf("%.2f GB", obj_size), "\n")
    
  }, error = function(e) {
    cat("    ✗ Failed to load:", e$message, "\n")
    return(FALSE)
  })
  
  # Save as RDS with GZIP compression (faster than xz)
  cat("  [STEP 2/2] Saving as RDS with gzip compression...\n")
  flush(stdout())
  
  start_save <- Sys.time()
  tryCatch({
    saveRDS(obj, rds_path, compress = "gzip")
    
    elapsed_save <- difftime(Sys.time(), start_save, units = "secs")
    rds_size <- file.size(rds_path) / (1024^3)
    compression_ratio <- (1 - rds_size / file_size_gb) * 100
    
    cat("    ✓ Saved successfully in", sprintf("%.1f seconds", as.numeric(elapsed_save)), "\n")
    cat("    RDS size:", sprintf("%.2f GB", rds_size), "\n")
    cat("    Compression ratio:", sprintf("%.1f%%", compression_ratio), "\n")
    
    return(TRUE)
    
  }, error = function(e) {
    cat("    ✗ Failed to save:", e$message, "\n")
    return(FALSE)
  })
}

# Convert TAHOE
cat(">>> TAHOE FILE (1.67 GB) <<<\n")
tahoe_ok <- convert_rdata_to_rds(tahoe_rdata, tahoe_rds, "tahoe_filtered")
cat("\n")

# Convert CMAP
cat(">>> CMAP FILE (0.57 GB) <<<\n")
cmap_ok <- convert_rdata_to_rds(cmap_rdata, cmap_rds, "cmap_filtered")
cat("\n")

# Summary
cat("=========================================================\n")
cat("CONVERSION SUMMARY\n")
cat("=========================================================\n\n")

cat("TAHOE:", ifelse(tahoe_ok, "✓ SUCCESS", "✗ FAILED"), "\n")
cat("CMAP:", ifelse(cmap_ok, "✓ SUCCESS", "✗ FAILED"), "\n")
cat("\n")

if (tahoe_ok && cmap_ok) {
  cat("✓ All files converted successfully!\n")
  cat("Next step: Restart the pipeline\n")
} else {
  cat("⚠ Conversion incomplete. Check errors above.\n")
}

cat("\n=========================================================\n\n")
