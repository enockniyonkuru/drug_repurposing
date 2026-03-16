#!/usr/bin/env Rscript
# Comprehensive diagnostic for TAHOE load hang issue

cat("\n========================================================\n")
cat("TAHOE LOAD HANG - COMPREHENSIVE DIAGNOSTICS\n")
cat("========================================================\n\n")

library(tools)

# ============================================================
# 1. Verify fix is in place
# ============================================================
cat("[1] CHECKING IF FIX IS IN PLACE\n")
cat("---\n")

fix_file <- "/Users/enockniyonkuru/Desktop/drug_repurposing/DRpipe/R/pipeline_processing.R"
if (file.exists(fix_file)) {
  content <- readLines(fix_file)
  has_subprocess <- any(grepl("subprocess loader", content))
  has_readrds <- any(grepl("readRDS", content))
  
  cat("✓ File exists:", fix_file, "\n")
  cat("  - Has 'subprocess loader' code:", has_subprocess, "\n")
  cat("  - Has 'readRDS' references:", has_readrds, "\n")
  
  if (!has_subprocess) {
    cat("  ⚠ WARNING: Fix code not found in load_cmap() method\n")
  }
} else {
  cat("✗ File not found:", fix_file, "\n")
}
cat("\n")

# ============================================================
# 2. Check file existence and properties
# ============================================================
cat("[2] CHECKING FILES\n")
cat("---\n")

tahoe_rdata <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData"
tahoe_rds <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.rds"
cmap_rdata <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.RData"
cmap_rds <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.rds"

check_file <- function(path) {
  if (file.exists(path)) {
    size_gb <- file.size(path) / (1024^3)
    info <- file.info(path)
    cat("✓", basename(path), "\n")
    cat("  Size:", sprintf("%.2f GB", size_gb), "\n")
    cat("  Modified:", format(info$mtime), "\n")
    return(TRUE)
  } else {
    cat("✗", basename(path), "NOT FOUND\n")
    return(FALSE)
  }
}

tahoe_ok <- check_file(tahoe_rdata)
tahoe_rds_ok <- check_file(tahoe_rds)
cat("\n")
cmap_ok <- check_file(cmap_rdata)
cmap_rds_ok <- check_file(cmap_rds)
cat("\n")

# ============================================================
# 3. Test load() with CMAP (smaller file - should work)
# ============================================================
cat("[3] TESTING CMAP LOAD (0.57 GB - smaller file)\n")
cat("---\n")

if (cmap_ok) {
  cat("Starting load test for CMAP...\n")
  flush(stdout())
  
  start_time <- Sys.time()
  tryCatch({
    cat("  [PROGRESS] Calling load()...\n")
    flush(stdout())
    
    env <- new.env(parent = emptyenv())
    load(cmap_rdata, envir = env)
    
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    
    obj_names <- ls(env)
    obj_size <- object.size(get(obj_names[1], envir = env)) / (1024^3)
    
    cat("  ✓ SUCCESS! Loaded in", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
    cat("  Object size:", sprintf("%.2f GB", obj_size), "\n")
    
  }, error = function(e) {
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    cat("  ✗ ERROR:", e$message, "\n")
    cat("  Time before error:", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
  })
} else {
  cat("Skipping - file not found\n")
}
cat("\n")

# ============================================================
# 4. Test readRDS() with CMAP if RDS exists
# ============================================================
cat("[4] TESTING READRDS() WITH CMAP RDS (if available)\n")
cat("---\n")

if (cmap_rds_ok) {
  cat("Starting readRDS test for CMAP...\n")
  flush(stdout())
  
  start_time <- Sys.time()
  tryCatch({
    cat("  [PROGRESS] Calling readRDS()...\n")
    flush(stdout())
    
    obj <- readRDS(cmap_rds)
    
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    obj_size <- object.size(obj) / (1024^3)
    
    cat("  ✓ SUCCESS! Loaded in", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
    cat("  Object size:", sprintf("%.2f GB", obj_size), "\n")
    
  }, error = function(e) {
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    cat("  ✗ ERROR:", e$message, "\n")
    cat("  Time before error:", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
  })
} else {
  cat("Skipping - RDS file not found (expected, needs conversion)\n")
}
cat("\n")

# ============================================================
# 5. Test load() with TAHOE (1.67 GB - the problematic file)
# ============================================================
cat("[5] TESTING TAHOE LOAD (1.67 GB - this might hang!)\n")
cat("---\n")

if (tahoe_ok) {
  cat("⚠ WARNING: This test MIGHT HANG if the issue exists\n")
  cat("Starting load test for TAHOE (with 5 second timeout)...\n")
  flush(stdout())
  
  start_time <- Sys.time()
  timeout_seconds <- 5
  
  # Set alarm to interrupt after timeout
  setTimeLimit(elapsed = timeout_seconds, transient = TRUE)
  
  tryCatch({
    cat("  [PROGRESS] Calling load()...\n")
    flush(stdout())
    
    env <- new.env(parent = emptyenv())
    load(tahoe_rdata, envir = env)
    
    setTimeLimit(elapsed = Inf, transient = FALSE)
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    
    obj_names <- ls(env)
    obj_size <- object.size(get(obj_names[1], envir = env)) / (1024^3)
    
    cat("  ✓ SUCCESS! Loaded in", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
    cat("  Object size:", sprintf("%.2f GB", obj_size), "\n")
    
  }, error = function(e) {
    setTimeLimit(elapsed = Inf, transient = FALSE)
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    cat("  ✗ ERROR/TIMEOUT:", e$message, "\n")
    cat("  Time before error:", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
  })
} else {
  cat("Skipping - file not found\n")
}
cat("\n")

# ============================================================
# 6. System resource check
# ============================================================
cat("[6] SYSTEM RESOURCES\n")
cat("---\n")

# Memory info
tryCatch({
  total_mem <- as.numeric(system("sysctl -n hw.memsize", intern = TRUE))
  cat("Total RAM:", sprintf("%.1f GB", total_mem / (1024^3)), "\n")
}, error = function(e) {})

# Disk space
tryCatch({
  disk_out <- system(paste("df -h | grep Volumes | head -1"), intern = TRUE)
  if (length(disk_out) > 0) {
    cat("Disk space:\n")
    cat("  ", disk_out, "\n")
  }
}, error = function(e) {})

cat("\n")

# ============================================================
# 7. Summary & Recommendations
# ============================================================
cat("========================================================\n")
cat("DIAGNOSTIC SUMMARY\n")
cat("========================================================\n\n")

cat("Key findings:\n")
cat("1. Fix code present:", ifelse(has_subprocess, "✓", "✗"), "\n")
cat("2. TAHOE RData exists:", ifelse(tahoe_ok, "✓", "✗"), "\n")
cat("3. TAHOE RDS exists:", ifelse(tahoe_rds_ok, "✓", "✗"), "\n")
cat("4. CMAP loads successfully:", "Check output above\n")
cat("5. TAHOE load timeout/hang:", "Check output above\n")
cat("\n")

cat("NEXT STEPS:\n")
cat("1. If CMAP loads successfully but TAHOE hangs/times out:\n")
cat("   → The issue is specific to the large 1.67 GB TAHOE file\n")
cat("   → We need to convert it to RDS format first\n\n")

cat("2. If readRDS works faster than load():\n")
cat("   → Use RDS format as primary method\n\n")

cat("3. If CMAP fails too:\n")
cat("   → There may be a system-level issue\n")
cat("   → Check disk space and RAM availability\n\n")

cat("========================================================\n\n")
