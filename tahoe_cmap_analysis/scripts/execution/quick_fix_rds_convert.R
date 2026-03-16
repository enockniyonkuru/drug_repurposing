#!/usr/bin/env Rscript
# IMMEDIATE FIX: Convert RData to RDS format
# RDS is much faster to load than RData for large objects

cat("=========================================================\n")
cat("QUICK FIX: Converting TAHOE signatures to RDS format\n")
cat("This will allow the pipeline to proceed\n")
cat("=========================================================\n\n")

tahoe_rdata <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData"
tahoe_rds <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.rds"

cat("[STEP 1] Check if conversion already done...\n")
if (file.exists(tahoe_rds)) {
  cat("✓ RDS file already exists, testing...\n")
  tryCatch({
    test <- readRDS(tahoe_rds)
    cat("✓ RDS file loads successfully\n")
    cat("[SUCCESS] Use the .rds file instead of .RData\n")
    quit(status = 0)
  }, error = function(e) {
    cat("⚠ RDS file corrupted, will recreate\n")
  })
}

cat("\n[STEP 2] Loading RData file (this may take 1-2 minutes)...\n")
cat("Timestamp:", format(Sys.time()), "\n")
flush(stdout())

start <- Sys.time()

# Try loading in a subprocess to prevent hanging the main R session
system(paste0("
  Rscript -e '
  cat(\"Loading RData...\n\")
  env <- new.env(parent = emptyenv())
  load(\"", tahoe_rdata, "\", envir = env)
  obj <- get(ls(env)[1], envir = env)
  cat(\"Saving as RDS...\n\")
  saveRDS(obj, \"", tahoe_rds, "\", compress = \"xz\")
  cat(\"Done!\n\")
  '
"))

elapsed <- difftime(Sys.time(), start, units = "mins")

if (file.exists(tahoe_rds)) {
  size_orig_gb <- file.size(tahoe_rdata) / (1024^3)
  size_rds_gb <- file.size(tahoe_rds) / (1024^3)
  reduction <- (1 - size_rds_gb / size_orig_gb) * 100
  
  cat("\n[SUCCESS] Conversion complete!\n")
  cat("Original RData size:", sprintf("%.2f GB", size_orig_gb), "\n")
  cat("New RDS size:", sprintf("%.2f GB", size_rds_gb), "\n")
  cat("Size reduction:", sprintf("%.1f%%", reduction), "\n")
  cat("Time taken:", sprintf("%.1f minutes", elapsed), "\n\n")
  
  cat("UPDATE DRpipe CODE TO USE RDS:\n")
  cat("- Change: load(file) in pipeline_processing.R\n")
  cat("- To: readRDS(file)\n\n")
  
  quit(status = 0)
} else {
  cat("\n✗ Failed to create RDS file\n")
  quit(status = 1)
}
