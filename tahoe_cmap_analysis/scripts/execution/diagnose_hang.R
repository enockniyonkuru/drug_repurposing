#!/usr/bin/env Rscript
# Diagnostic script to identify why the pipeline is hanging
# This tests loading the large RData files with timeouts and diagnostics

library(tools)

cat("\n========================================\n")
cat("TAHOE/CMAP PIPELINE HANG DIAGNOSTICS\n")
cat("========================================\n\n")

# File paths to test
tahoe_sig_file <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData"
cmap_sig_file <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.RData"

# 1. Check file existence and sizes
cat("[CHECK 1] File Existence and Sizes\n")
cat("-----------------------------------\n")

for (file in c(tahoe_sig_file, cmap_sig_file)) {
  if (file.exists(file)) {
    size_gb <- file.size(file) / (1024^3)
    cat("✓ ", basename(file), ": ", sprintf("%.2f GB", size_gb), "\n", sep="")
  } else {
    cat("✗ ", basename(file), ": NOT FOUND\n", sep="")
  }
}
cat("\n")

# 2. Check file access
cat("[CHECK 2] File Access and Read Permissions\n")
cat("-------------------------------------------\n")

for (file in c(tahoe_sig_file, cmap_sig_file)) {
  if (file.exists(file)) {
    info <- file.info(file)
    readable <- ifelse(file.access(file, 4) == 0, "✓", "✗")
    cat(readable, basename(file), "\n")
    cat("   Modification time:", format(info$mtime), "\n")
    cat("   Size:", format(info$size, big.mark=","), "bytes\n")
  }
}
cat("\n")

# 3. Test loading with timeout
cat("[CHECK 3] Loading Test with Progress Monitoring\n")
cat("----------------------------------------------\n")

test_load <- function(file_path) {
  cat("Testing:", basename(file_path), "\n")
  
  flush(stdout())
  cat("  Starting load...\n")
  flush(stdout())
  
  start_time <- Sys.time()
  
  tryCatch({
    # Force unbuffered output
    cat("  [PROGRESS] Initiating load at", format(Sys.time()), "\n")
    flush(stdout())
    
    env <- new.env(parent = emptyenv())
    
    cat("  [PROGRESS] Calling load() function...\n")
    flush(stdout())
    
    # The actual load call that might hang
    load(file_path, envir = env)
    
    cat("  [PROGRESS] Load completed\n")
    flush(stdout())
    
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    
    # Check what was loaded
    objects <- ls(env, all.names = TRUE)
    cat("  [RESULT] ✓ Loaded successfully\n")
    cat("  [RESULT] Time taken:", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
    cat("  [RESULT] Objects loaded:", paste(objects, collapse=", "), "\n")
    cat("  [RESULT] Memory used by first object:", 
        sprintf("%.2f MB", 
        object.size(get(objects[1], envir = env)) / (1024^2)), "\n")
    
    return(TRUE)
  }, error = function(e) {
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    cat("  [ERROR] Failed to load\n")
    cat("  [ERROR] Message:", e$message, "\n")
    cat("  [ERROR] Time before error:", sprintf("%.1f seconds", as.numeric(elapsed)), "\n")
    return(FALSE)
  }, timeout = function(e) {
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    cat("  [TIMEOUT] Load took too long (>", sprintf("%.1f seconds", as.numeric(elapsed)), ")\n")
    return(FALSE)
  })
}

# Load both files
tahoe_ok <- test_load(tahoe_sig_file)
cat("\n")
cmap_ok <- test_load(cmap_sig_file)
cat("\n")

# 4. System resource check
cat("[CHECK 4] System Resources\n")
cat("---------------------------\n")

# Get memory info
total_mem <- as.numeric(system("sysctl -n hw.memsize", intern = TRUE))
cat("Total RAM:", sprintf("%.2f GB", total_mem / (1024^3)), "\n")

# Check disk space
disk_info <- system(paste("df -h", dirname(tahoe_sig_file)), intern = TRUE)
cat("Disk space for:", dirname(tahoe_sig_file), "\n")
cat(disk_info[2], "\n")
cat("\n")

# 5. Check for file locking or I/O issues
cat("[CHECK 5] File System Status\n")
cat("-----------------------------\n")

# List open files (if using lsof)
result <- tryCatch({
  open_files <- system(paste("lsof", tahoe_sig_file), intern = TRUE)
  if (length(open_files) > 0) {
    cat("File is currently open by:\n")
    cat(paste(open_files[-1], collapse="\n"), "\n")
  } else {
    cat("File is not currently open\n")
  }
}, error = function(e) {
  cat("Could not check open files\n")
})
cat("\n")

# 6. Recommendations
cat("[RECOMMENDATIONS]\n")
cat("------------------\n")

if (!tahoe_ok || !cmap_ok) {
  cat("The loading process appears to be hanging. Possible solutions:\n\n")
  
  cat("1. INCREASE SYSTEM RESOURCES\n")
  cat("   - Check available RAM: `free -h` or `vm_stat`\n")
  cat("   - Close unnecessary applications\n")
  cat("   - Restart R to clear memory\n\n")
  
  cat("2. CHECK FILE INTEGRITY\n")
  cat("   - Verify files are not corrupted:\n")
  cat("     file ", tahoe_sig_file, "\n")
  cat("     file ", cmap_sig_file, "\n\n")
  
  cat("3. TRY PRECOMPRESSING THE SIGNATURES\n")
  cat("   - Save as .RData with compression=TRUE\n")
  cat("   - This can speed up loading\n\n")
  
  cat("4. USE DISK CACHE\n")
  cat("   - Ensure SSD has sufficient free space\n")
  cat("   - Check thermal throttling: `istats` (install with: brew install istats)\n\n")
  
  cat("5. RUN WITH STRACE/DTRACE\n")
  cat("   - Monitor system calls: `sudo dtruss -p <PID>`\n")
  cat("   - Identify I/O bottleneck\n\n")
  
  cat("6. ALTERNATIVE: CONVERT TO COMPRESSED FORMAT\n")
  cat("   - Try saving with: save(object, file=path, compress='xz')\n\n")
  
} else {
  cat("✓ Loading test passed! Pipeline should work.\n")
  cat("✓ If you're still experiencing hangs, the issue is elsewhere.\n\n")
}

cat("========================================\n")
cat("Diagnostics complete.\n")
cat("========================================\n\n")
