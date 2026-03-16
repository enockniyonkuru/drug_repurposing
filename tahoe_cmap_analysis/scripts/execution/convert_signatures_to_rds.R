#!/usr/bin/env Rscript
# Convert large RData files to RDS format to avoid load() hanging issues
# This runs in a separate process and shouldn't hang

cat("\n=========================================================\n")
cat("CONVERTING RDATA FILES TO RDS FORMAT\n")
cat("This solves the load() hanging issue\n")
cat("=========================================================\n\n")

library(tools)

# Files to convert
files_to_convert <- list(
  tahoe = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData",
  cmap = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.RData"
)

convert_to_rds <- function(rdata_file, output_name) {
  cat("[CONVERTING]", basename(rdata_file), "\n")
  cat("  File size:", sprintf("%.2f GB", file.size(rdata_file) / (1024^3)), "\n")
  flush(stdout())
  
  rds_file <- paste0(file_path_sans_ext(rdata_file), ".rds")
  
  # If RDS already exists and is valid, skip
  if (file.exists(rds_file) && file.size(rds_file) > 1000000) {
    cat("  ✓ RDS file already exists, skipping\n")
    return(TRUE)
  }
  
  tryCatch({
    cat("  Loading RData...\n")
    flush(stdout())
    
    env <- new.env(parent = emptyenv())
    load(rdata_file, envir = env)
    
    # Get the object
    obj_names <- ls(env, all.names = TRUE)
    cat("  Loaded:", paste(obj_names, collapse=", "), "\n")
    flush(stdout())
    
    obj <- get(obj_names[1], envir = env)
    
    cat("  Object size:", sprintf("%.2f GB", object.size(obj) / (1024^3)), "\n")
    cat("  Saving as RDS with compression...\n")
    flush(stdout())
    
    # Save with xz compression
    saveRDS(obj, rds_file, compress = "xz")
    
    new_size <- file.size(rds_file) / (1024^3)
    old_size <- file.size(rdata_file) / (1024^3)
    reduction <- (1 - new_size / old_size) * 100
    
    cat("  ✓ Saved to:", basename(rds_file), "\n")
    cat("  Size reduction:", sprintf("%.1f%%", reduction), "\n")
    cat("  Old size:", sprintf("%.2f GB", old_size), "\n")
    cat("  New size:", sprintf("%.2f GB", new_size), "\n\n")
    
    return(TRUE)
  }, error = function(e) {
    cat("  ✗ ERROR:", e$message, "\n\n")
    return(FALSE)
  })
}

# Convert all files
all_success <- TRUE
for (name in names(files_to_convert)) {
  file <- files_to_convert[[name]]
  if (file.exists(file)) {
    success <- convert_to_rds(file, name)
    all_success <- all_success && success
  } else {
    cat("[ERROR]", basename(file), "not found!\n\n")
    all_success <- FALSE
  }
}

cat("=========================================================\n")
if (all_success) {
  cat("✓ All files converted successfully!\n")
  cat("✓ Pipeline can now load signatures without hanging\n")
  quit(status = 0)
} else {
  cat("✗ Some files failed to convert\n")
  quit(status = 1)
}
cat("=========================================================\n\n")
