#!/usr/bin/env Rscript
#' Filter TAHOE Signatures by Shared Genes with CMAP
#'
#' This script filters the tahoe_signatures.RData to keep only genes
#' that are shared between TAHOE and CMAP datasets, as defined in
#' shared_genes_cmap_tahoe.csv
#'

suppressPackageStartupMessages({
  library(readr)
})

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("Filtering TAHOE Signatures by Shared Genes\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")

# Paths
project_root <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis"
shared_genes_csv <- file.path(project_root, "validation/shared_genes_cmap_tahoe.csv")
tahoe_signatures_rdata <- file.path(project_root, "data/drug_signatures/tahoe/tahoe_signatures.RData")
output_rdata <- file.path(project_root, "data/drug_signatures/tahoe/tahoe_signatures_shared_genes_only.RData")

cat("\n[1/4] Reading shared genes CSV...\n")
cat(sprintf("      File: %s\n", shared_genes_csv))

if (!file.exists(shared_genes_csv)) {
  stop(sprintf("Error: Shared genes file not found: %s", shared_genes_csv))
}

shared_genes <- read_csv(shared_genes_csv, show_col_types = FALSE)

cat(sprintf("      ✓ Loaded: %d shared genes\n", nrow(shared_genes)))
cat(sprintf("      Columns: %s\n", paste(colnames(shared_genes), collapse = ", ")))
cat(sprintf("      First gene: %s (entrezID: %s)\n", 
            shared_genes$gene_name[1], shared_genes$entrezID[1]))

cat("\n[2/4] Loading original TAHOE signatures...\n")
cat(sprintf("      File: %s\n", tahoe_signatures_rdata))

if (!file.exists(tahoe_signatures_rdata)) {
  stop(sprintf("Error: TAHOE signatures file not found: %s", tahoe_signatures_rdata))
}

load(tahoe_signatures_rdata)

# The loaded object should be named 'tahoe_signatures'
if (!exists("tahoe_signatures")) {
  stop("Error: tahoe_signatures object not found in RData file")
}

orig_dims <- dim(tahoe_signatures)
cat(sprintf("      ✓ Loaded: %d genes × %d signatures\n", orig_dims[1], orig_dims[2]))
cat(sprintf("      First column: %s\n", colnames(tahoe_signatures)[1]))
cat(sprintf("      Memory: ~%.1f MB\n", object.size(tahoe_signatures) / (1024^2)))

cat("\n[3/4] Filtering by shared genes...\n")

# The first column should be V1 (genes), but let's check
first_col_name <- colnames(tahoe_signatures)[1]
cat(sprintf("      Using column '%s' for gene matching\n", first_col_name))

# Get the gene identifiers from tahoe_signatures
tahoe_gene_ids <- tahoe_signatures[[first_col_name]]
cat(sprintf("      TAHOE has %d genes\n", length(tahoe_gene_ids)))
cat(sprintf("      Shared genes file has %d genes\n", nrow(shared_genes)))

# Create shared gene set from entrezID
shared_entrez <- as.character(shared_genes$entrezID)
cat(sprintf("      Shared entrezIDs: %s\n", 
            paste(head(shared_entrez, 3), collapse = ", ")))

# Filter rows where first column is in shared genes
matching_rows <- which(tahoe_gene_ids %in% shared_entrez)
cat(sprintf("      ✓ Found %d matching genes\n", length(matching_rows)))

if (length(matching_rows) == 0) {
  warning("No matching genes found! Check that gene identifiers match.")
}

# Subset the data frame
tahoe_signatures <- tahoe_signatures[matching_rows, ]

new_dims <- dim(tahoe_signatures)
cat(sprintf("      New dimensions: %d genes × %d signatures\n", new_dims[1], new_dims[2]))
cat(sprintf("      Reduction: %.1f%% of genes retained\n", 
            (new_dims[1] / orig_dims[1]) * 100))

cat("\n[4/4] Saving filtered RData...\n")
cat(sprintf("      File: %s\n", output_rdata))

# Create output directory if needed
output_dir <- dirname(output_rdata)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

save(tahoe_signatures, file = output_rdata, compress = TRUE)

# Verify the saved file
if (!file.exists(output_rdata)) {
  stop("Error: Failed to save RData file")
}

file_size_mb <- file.info(output_rdata)$size / (1024^2)
cat(sprintf("      ✓ Successfully saved (%.2f MB)\n", file_size_mb))

# Quick validation
test_env <- new.env()
load(output_rdata, envir = test_env)
if ("tahoe_signatures" %in% ls(test_env)) {
  test_dims <- dim(test_env$tahoe_signatures)
  cat(sprintf("      ✓ Validation: Object loaded correctly (%d × %d)\n", 
              test_dims[1], test_dims[2]))
} else {
  warning("Warning: Could not validate saved object")
}

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("FILTERING COMPLETE\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat(sprintf("\nOutput: %s\n", output_rdata))
cat(sprintf("Summary: %d → %d genes | %d signatures unchanged\n", 
            orig_dims[1], new_dims[1], new_dims[2]))
cat(sprintf("Reduction: %.1f%% of genes retained\n\n", 
            (new_dims[1] / orig_dims[1]) * 100))
