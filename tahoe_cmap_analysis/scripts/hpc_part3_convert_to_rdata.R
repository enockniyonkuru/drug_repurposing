#!/usr/bin/env Rscript
# HPC PART 3 (FIX): Convert Parquet Checkpoint to RData - WITH ENHANCED LOGGING
#===================================================================================
# Loads the ranked parquet checkpoint from the Python script
# and converts it to the final CMap-like RData format.
#
# Input: checkpoint_ranked_all_genes_all_drugs.parquet
# Output: tahoe_signatures.RData
# Runtime: ~15-20 minutes
#
# ENHANCED VERSION: Includes comprehensive error logging and debugging information
#===================================================================================

# ============================================================================
# LOGGING SETUP
# ============================================================================

# Create detailed log file
log_dir <- "../logs"
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
log_file <- file.path(log_dir, paste0("hpc_part3_rdata_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log"))

# Function to log messages to both console and file
log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] [%s] %s", timestamp, level, msg)
  
  # Print to console
  cat(log_entry, "\n")
  
  # Write to log file
  cat(log_entry, "\n", file = log_file, append = TRUE)
}

# Function to log errors with full context
log_error <- function(error_msg, context = "", traceback = TRUE) {
  log_message("=" %>% rep(80) %>% paste(collapse = ""), "ERROR")
  log_message(paste("ERROR OCCURRED:", error_msg), "ERROR")
  
  if (context != "") {
    log_message(paste("CONTEXT:", context), "ERROR")
  }
  
  if (traceback) {
    log_message("TRACEBACK:", "ERROR")
    tb <- sys.calls()
    for (i in seq_along(tb)) {
      log_message(paste("  ", i, ":", deparse(tb[[i]])[1]), "ERROR")
    }
  }
  
  # System information
  log_message("SYSTEM INFO:", "ERROR")
  log_message(paste("  R Version:", R.version.string), "ERROR")
  log_message(paste("  Platform:", R.version$platform), "ERROR")
  log_message(paste("  Working Directory:", getwd()), "ERROR")
  
  # Memory information
  if (requireNamespace("pryr", quietly = TRUE)) {
    log_message(paste("  Memory Usage:", pryr::mem_used()), "ERROR")
  }
  
  log_message("=" %>% rep(80) %>% paste(collapse = ""), "ERROR")
}

# Start logging
log_message("=" %>% rep(80) %>% paste(collapse = ""))
log_message("HPC PART 3: Converting Checkpoint to RData (All Genes, All Exps)")
log_message("=" %>% rep(80) %>% paste(collapse = ""))
log_message(paste("Log file:", log_file))
log_message(paste("Start time:", Sys.time()))
log_message(paste("Working directory:", getwd()))
log_message(paste("R version:", R.version.string))

# ============================================================================
# STEP 0: ENVIRONMENT SETUP
# ============================================================================

log_message("", "INFO")
log_message("[STEP 0] Setting up environment...", "INFO")

# Check and load required packages
log_message("Checking for required packages...", "INFO")

tryCatch({
  if (!requireNamespace("arrow", quietly = TRUE)) {
    log_error("arrow package not installed", 
              "The arrow package is required for reading parquet files")
    stop("Please install arrow package: install.packages('arrow')")
  }
  
  log_message("Loading arrow package...", "INFO")
  library(arrow)
  log_message(paste("✓ arrow package loaded, version:", packageVersion("arrow")), "INFO")
  
}, error = function(e) {
  log_error(e$message, "Failed to load arrow package")
  stop(e)
})

# ============================================================================
# STEP 1: PATH SETUP AND VALIDATION
# ============================================================================

log_message("", "INFO")
log_message("[STEP 1] Setting up paths and validating files...", "INFO")

tryCatch({
  # Define paths
  checkpoint_file <- "../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet"
  output_rdata <- "../data/drug_signatures/tahoe/tahoe_signatures.RData"
  output_dir <- dirname(output_rdata)
  
  log_message(paste("Input file:", checkpoint_file), "INFO")
  log_message(paste("Output file:", output_rdata), "INFO")
  log_message(paste("Output directory:", output_dir), "INFO")
  
  # Check if input file exists
  log_message("Checking if checkpoint file exists...", "INFO")
  if (!file.exists(checkpoint_file)) {
    log_error(paste("Checkpoint file not found:", checkpoint_file),
              "This file should be created by Part 2 (hpc_part2_rank_and_save_parquet.py)")
    stop("Checkpoint file not found. Run Part 2 first.")
  }
  
  # Get file info
  file_info <- file.info(checkpoint_file)
  file_size_mb <- file_info$size / (1024^2)
  log_message(sprintf("✓ Checkpoint file found (%.2f MB)", file_size_mb), "INFO")
  log_message(paste("  Last modified:", file_info$mtime), "INFO")
  
  # Create output directory
  log_message("Creating output directory if needed...", "INFO")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  if (!dir.exists(output_dir)) {
    log_error(paste("Cannot create output directory:", output_dir),
              "Check permissions and disk space")
    stop("Failed to create output directory")
  }
  log_message("✓ Output directory ready", "INFO")
  
  # Check available disk space
  if (.Platform$OS.type == "unix") {
    disk_info <- system(paste("df -h", output_dir), intern = TRUE)
    log_message("Disk space information:", "INFO")
    for (line in disk_info) {
      log_message(paste("  ", line), "INFO")
    }
  }
  
}, error = function(e) {
  log_error(e$message, "Path setup and validation failed")
  stop(e)
})

# ============================================================================
# STEP 2: LOAD PARQUET DATA
# ============================================================================

log_message("", "INFO")
log_message("[STEP 2] Loading checkpoint data from parquet...", "INFO")

tryCatch({
  log_message("Starting parquet read operation...", "INFO")
  start_time <- Sys.time()
  
  # Attempt to read parquet file
  ranked_df_raw <- read_parquet(checkpoint_file)
  
  end_time <- Sys.time()
  load_duration <- as.numeric(end_time - start_time, units = "secs")
  
  log_message(sprintf("✓ Data loaded successfully in %.1f seconds", load_duration), "INFO")
  log_message(sprintf("  Dimensions: %d rows x %d columns", 
                     nrow(ranked_df_raw), ncol(ranked_df_raw)), "INFO")
  log_message(paste("  Column names:", paste(head(names(ranked_df_raw), 10), collapse = ", "), 
                   "..."), "INFO")
  log_message(paste("  Data types:", paste(sapply(ranked_df_raw[,1:min(5, ncol(ranked_df_raw))], class), 
                   collapse = ", ")), "INFO")
  
  # Check for entrezID column
  if (!"entrezID" %in% names(ranked_df_raw)) {
    log_error("entrezID column not found in data",
              paste("Available columns:", paste(names(ranked_df_raw), collapse = ", ")))
    stop("Required entrezID column missing from checkpoint file")
  }
  log_message("✓ entrezID column found", "INFO")
  
  # Memory usage
  obj_size_mb <- object.size(ranked_df_raw) / (1024^2)
  log_message(sprintf("  Object size in memory: %.2f MB", obj_size_mb), "INFO")
  
}, error = function(e) {
  log_error(e$message, "Failed to load parquet file")
  log_message("Possible causes:", "ERROR")
  log_message("  1. File is corrupted", "ERROR")
  log_message("  2. Insufficient memory", "ERROR")
  log_message("  3. arrow package version incompatibility", "ERROR")
  log_message("  4. File format mismatch", "ERROR")
  stop(e)
})

# ============================================================================
# STEP 3: CONVERT TO CMAP-LIKE FORMAT
# ============================================================================

log_message("", "INFO")
log_message("[STEP 3] Converting to CMap-like format...", "INFO")

tryCatch({
  # Extract entrezID column
  log_message("Extracting entrezID column...", "INFO")
  v1_col <- ranked_df_raw$entrezID
  log_message(sprintf("✓ Extracted %d gene IDs", length(v1_col)), "INFO")
  log_message(paste("  First few IDs:", paste(head(v1_col, 5), collapse = ", ")), "INFO")
  
  # Extract experiment data
  log_message("Extracting experiment data columns...", "INFO")
  exp_data <- ranked_df_raw[, -which(names(ranked_df_raw) == "entrezID")]
  n_experiments <- ncol(exp_data)
  log_message(sprintf("✓ Extracted %d experiment columns", n_experiments), "INFO")
  
  # Create initial data frame
  log_message("Creating CMap-like data frame structure...", "INFO")
  cmap_like <- data.frame(V1 = v1_col)
  log_message("✓ Initial data frame created with V1 column", "INFO")
  
  # Add experiment columns iteratively
  log_message(sprintf("Adding %d experiment columns (this may take 10-20 minutes)...", 
                     n_experiments), "INFO")
  log_message("Progress will be updated every 100 columns", "INFO")
  
  start_time <- Sys.time()
  pb <- txtProgressBar(min = 0, max = n_experiments, style = 3)
  
  for (i in 1:n_experiments) {
    tryCatch({
      col_name <- paste0("V", i + 1)
      cmap_like[[col_name]] <- exp_data[[i]]
      
      if (i %% 100 == 0) {
        setTxtProgressBar(pb, i)
        elapsed <- as.numeric(Sys.time() - start_time, units = "mins")
        rate <- i / elapsed
        remaining <- (n_experiments - i) / rate
        log_message(sprintf("  Progress: %d/%d columns (%.1f%%), Est. remaining: %.1f min",
                           i, n_experiments, (i/n_experiments)*100, remaining), "INFO")
      }
      
    }, error = function(e) {
      close(pb)
      log_error(e$message, 
                sprintf("Failed while adding column %d (V%d)", i, i+1))
      stop(e)
    })
  }
  
  close(pb)
  end_time <- Sys.time()
  conversion_duration <- as.numeric(end_time - start_time, units = "mins")
  
  log_message(sprintf("✓ CMap-like data frame created in %.1f minutes", 
                     conversion_duration), "INFO")
  log_message(sprintf("  Final dimensions: %d rows x %d columns",
                     nrow(cmap_like), ncol(cmap_like)), "INFO")
  
  # Verify structure
  log_message("Verifying data structure...", "INFO")
  log_message(paste("  Column names (first 10):", 
                   paste(head(names(cmap_like), 10), collapse = ", ")), "INFO")
  log_message(sprintf("  Total genes: %d", nrow(cmap_like)), "INFO")
  log_message(sprintf("  Total signatures: %d", ncol(cmap_like) - 1), "INFO")
  
}, error = function(e) {
  log_error(e$message, "Failed during CMap format conversion")
  log_message("Possible causes:", "ERROR")
  log_message("  1. Insufficient memory for data frame operations", "ERROR")
  log_message("  2. Data type incompatibility", "ERROR")
  log_message("  3. Column structure mismatch", "ERROR")
  stop(e)
})

# ============================================================================
# STEP 4: SAVE TO RDATA
# ============================================================================

log_message("", "INFO")
log_message("[STEP 4] Saving to RData format...", "INFO")

tryCatch({
  log_message("Preparing data for save...", "INFO")
  tahoe_signatures <- cmap_like
  
  log_message(sprintf("Object to save: tahoe_signatures (%d x %d)",
                     nrow(tahoe_signatures), ncol(tahoe_signatures)), "INFO")
  
  # Check available disk space before saving
  if (.Platform$OS.type == "unix") {
    disk_cmd <- paste("df -h", dirname(output_rdata), "| tail -1 | awk '{print $4}'")
    available_space <- system(disk_cmd, intern = TRUE)
    log_message(paste("Available disk space:", available_space), "INFO")
  }
  
  log_message("Starting save operation (this may take several minutes)...", "INFO")
  start_time <- Sys.time()
  
  save(tahoe_signatures, file = output_rdata, compress = TRUE)
  
  end_time <- Sys.time()
  save_duration <- as.numeric(end_time - start_time, units = "mins")
  
  log_message(sprintf("✓ Data saved successfully in %.1f minutes", save_duration), "INFO")
  
  # Verify output file
  if (!file.exists(output_rdata)) {
    log_error("Output file not found after save operation",
              paste("Expected file:", output_rdata))
    stop("Save operation appeared to succeed but file not found")
  }
  
  # Get file information
  file_info <- file.info(output_rdata)
  file_size_gb <- file_info$size / (1024^3)
  log_message(sprintf("✓ Output file verified (%.2f GB)", file_size_gb), "INFO")
  log_message(paste("  Location:", output_rdata), "INFO")
  log_message(paste("  Created:", file_info$mtime), "INFO")
  
  # Test loading the file
  log_message("Testing file integrity by loading...", "INFO")
  test_env <- new.env()
  load(output_rdata, envir = test_env)
  
  if (!"tahoe_signatures" %in% ls(test_env)) {
    log_error("tahoe_signatures object not found in saved file",
              "File may be corrupted")
    stop("Saved file does not contain expected object")
  }
  
  test_dims <- dim(test_env$tahoe_signatures)
  log_message(sprintf("✓ File integrity verified (loaded %d x %d)", 
                     test_dims[1], test_dims[2]), "INFO")
  rm(test_env)
  
}, error = function(e) {
  log_error(e$message, "Failed during RData save operation")
  log_message("Possible causes:", "ERROR")
  log_message("  1. Insufficient disk space", "ERROR")
  log_message("  2. Permission denied", "ERROR")
  log_message("  3. Disk I/O error", "ERROR")
  log_message("  4. File system limitations", "ERROR")
  stop(e)
})

# ============================================================================
# COMPLETION
# ============================================================================

log_message("", "INFO")
log_message("=" %>% rep(80) %>% paste(collapse = ""))
log_message("✅✅✅ HPC PIPELINE PART 3 COMPLETE! ✅✅✅", "INFO")
log_message("=" %>% rep(80) %>% paste(collapse = ""))
log_message("", "INFO")
log_message("SUMMARY:", "INFO")
log_message(sprintf("  Input: %s", checkpoint_file), "INFO")
log_message(sprintf("  Output: %s (%.2f GB)", output_rdata, file_size_gb), "INFO")
log_message(sprintf("  Dimensions: %d genes x %d signatures", 
                   nrow(tahoe_signatures), ncol(tahoe_signatures) - 1), "INFO")
log_message(sprintf("  End time: %s", Sys.time()), "INFO")
log_message(sprintf("  Log file: %s", log_file), "INFO")
log_message("", "INFO")
log_message("Next steps:", "INFO")
log_message("  1. Verify the output file can be loaded in your analysis", "INFO")
log_message("  2. Check data dimensions match expectations", "INFO")
log_message("  3. Proceed with downstream drug repurposing analysis", "INFO")
log_message("=" %>% rep(80) %>% paste(collapse = ""))

# Exit successfully
quit(status = 0)
