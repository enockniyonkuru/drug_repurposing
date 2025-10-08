#!/usr/bin/env Rscript

# Test script to verify padj filtering works correctly across different profiles

suppressPackageStartupMessages(library(DRpipe))

# Load helper function
source("load_execution_config.R")

# Test profiles with different pval_cutoff values
test_profiles <- c("Endothelial_Standard", "Endothelial_Strict", "Endothelial_Lenient")

cat("\n=== Testing padj Filter Across Profiles ===\n\n")

for (profile_name in test_profiles) {
  cat(sprintf("\n--- Testing Profile: %s ---\n", profile_name))
  
  # Load config for this profile
  cfg <- load_profile_config(profile = profile_name, config_file = "config.yml")
  
  cat(sprintf("Config pval_cutoff: %s\n", cfg$params$pval_cutoff))
  
  # Create DRP instance
  drp <- DRP$new(
    signatures_rdata = cfg$paths$signatures,
    disease_path     = cfg$paths$disease_file,
    cmap_meta_path   = cfg$paths$cmap_meta %||% NULL,
    cmap_valid_path  = cfg$paths$cmap_valid %||% NULL,
    out_dir          = tempdir(),  # Use temp dir for testing
    gene_key         = cfg$params$gene_key %||% "SYMBOL",
    logfc_cols_pref  = cfg$params$logfc_cols_pref %||% "log2FC",
    logfc_cutoff     = cfg$params$logfc_cutoff %||% 1,
    pval_key         = cfg$params$pval_key,
    pval_cutoff      = cfg$params$pval_cutoff,
    q_thresh         = cfg$params$q_thresh %||% 0.05,
    reversal_only    = isTRUE(cfg$params$reversal_only %||% TRUE),
    seed             = cfg$params$seed %||% 123,
    verbose          = TRUE
  )
  
  # Load CMAP and disease data
  drp$load_cmap()
  drp$load_disease()
  
  # Clean signature (this is where the filtering happens)
  drp$clean_signature()
  
  cat(sprintf("\nResults for %s:\n", profile_name))
  cat(sprintf("  Up-regulated genes: %d\n", length(drp$dz_genes_up)))
  cat(sprintf("  Down-regulated genes: %d\n", length(drp$dz_genes_down)))
  cat(sprintf("  Total genes: %d\n\n", length(drp$dz_genes_up) + length(drp$dz_genes_down)))
}

cat("\n=== Test Complete ===\n")
cat("\nIf the padj filter is working correctly, you should see:\n")
cat("  - Endothelial_Standard (pval_cutoff=0.05): moderate number of genes\n")
cat("  - Endothelial_Strict (pval_cutoff=1e-25): very few genes\n")
cat("  - Endothelial_Lenient (pval_cutoff=0.1): more genes\n\n")

`%||%` <- function(x, y) if (is.null(x)) y else x
