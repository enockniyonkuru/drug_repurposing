#!/usr/bin/env Rscript
# TAHOE PART 3a: Create RData (All Experiments)
# Converts ranked parquet to RData format for all 56,827 experiments.
# Input: checkpoint_ranked_genes_x_exper.parquet (from Part 2)
# Output: tahoe_genes_filtered.RData (~1.8 GB, 12,544 genes × 56,827 signatures)
# Runtime: ~15 minutes

library(arrow)

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("Converting Part 2A Checkpoint Data to RData (Memory-Efficient)\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")

# Paths
checkpoint_file <- "../data/filtered_tahoe/checkpoint_ranked_genes_x_exper.parquet"
output_rdata <- "../data/drug_signatures/tahoe/tahoe_genes_filtered.RData"

cat("\n[Step 1] Loading checkpoint ranked data from parquet...\n")
ranked_df <- read_parquet(checkpoint_file)
cat(sprintf("  - Loaded data with shape: %d rows x %d columns\n", nrow(ranked_df), ncol(ranked_df)))

# Set entrezID as rownames and remove the column
rownames(ranked_df) <- ranked_df$entrezID
ranked_df$entrezID <- NULL
cat(sprintf("  - Matrix shape after setting rownames: %d genes x %d experiments\n", 
            nrow(ranked_df), ncol(ranked_df)))

cat("\n[Step 2] Converting to CMap-like format (processing in chunks)...\n")
# Transpose so experiments are rows, genes are columns
cat("  - Transposing matrix...\n")
transposed <- t(ranked_df)
cat(sprintf("  - Transposed shape: %d experiments x %d genes\n", 
            nrow(transposed), ncol(transposed)))

# Get entrez IDs
entrez_ids <- as.integer(colnames(transposed))

# Create CMap-like data frame with V1, V2, V3, ... column names
# V1 will be the Entrez IDs, V2-Vn will be the experiments
cat("  - Creating CMap-like DataFrame...\n")
cat(sprintf("  - This will create a data frame with %d rows and %d columns\n", 
            length(entrez_ids), nrow(transposed) + 1))

# Initialize with V1 (Entrez IDs)
cmap_like <- data.frame(V1 = entrez_ids)

# Process experiments in chunks to manage memory
chunk_size <- 1000
n_experiments <- nrow(transposed)
n_chunks <- ceiling(n_experiments / chunk_size)

cat(sprintf("  - Processing %d experiments in %d chunks of %d...\n", 
            n_experiments, n_chunks, chunk_size))

for (chunk_idx in 1:n_chunks) {
  start_idx <- (chunk_idx - 1) * chunk_size + 1
  end_idx <- min(chunk_idx * chunk_size, n_experiments)
  
  cat(sprintf("  - Chunk %d/%d: experiments %d to %d\n", 
              chunk_idx, n_chunks, start_idx, end_idx))
  
  # Add experiments in this chunk
  for (i in start_idx:end_idx) {
    col_name <- paste0("V", i + 1)
    cmap_like[[col_name]] <- as.numeric(transposed[i, ])
  }
  
  # Force garbage collection every 10 chunks
  if (chunk_idx %% 10 == 0) {
    gc()
  }
}

cat(sprintf("  - CMap-like DataFrame created with shape: %d rows x %d columns\n", 
            nrow(cmap_like), ncol(cmap_like)))

cat("\n[Step 3] Saving to RData...\n")
cat("  - This may take a few minutes for large files...\n")
tahoe_genes_filtered <- cmap_like
save(tahoe_genes_filtered, file = output_rdata, compress = TRUE)
cat(sprintf("  - Saved: %s\n", output_rdata))
cat(sprintf("  - Shape: %d genes x %d signatures\n", 
            nrow(tahoe_genes_filtered), ncol(tahoe_genes_filtered) - 1))

# Get file size
file_size_mb <- file.info(output_rdata)$size / (1024^2)
cat(sprintf("  - File size: %.1f MB\n", file_size_mb))

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("✅ Part 2A Complete - RData file created successfully!\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("\nNote: This file contains ALL experiments (56,827 signatures).\n")
cat("For shared drugs only, use tahoe_genes_drugs.RData instead.\n")
