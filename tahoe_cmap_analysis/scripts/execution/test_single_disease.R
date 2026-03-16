#!/usr/bin/env Rscript

# Test script: Run single disease to verify caching and performance
library(DRpipe)

cat("\n=== TESTING SIGNATURE LOADING WITH CACHING ===\n\n")

# First load - should take time
cat("[TEST 1] Loading CMAP signatures (should take ~5-30 seconds)...\n")
start1 <- Sys.time()
load("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures_shared_genes.RData", envir = .GlobalEnv)
time1 <- difftime(Sys.time(), start1, units = "secs")
cat("  Time:", round(as.numeric(time1), 2), "seconds\n")
rm(cmap_signatures)
gc()

# Now create a DRP object and load via the cached method
cat("\n[TEST 2] Loading TAHOE signatures via DRP (first load)...\n")
start2 <- Sys.time()
drp <- DRP$new(
  signatures_rdata = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData",
  disease_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/disease_signatures/90_subset_creeds_manual_disease_signatures_shared_genes/acne_signature.csv",
  cmap_meta_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv",
  out_dir = "/tmp/test_out",
  gene_key = "SYMBOL",
  logfc_cols_pref = "logfc_dz",
  analysis_id = "TAHOE"
)
drp$load_cmap()
time2 <- difftime(Sys.time(), start2, units = "secs")
cat("  Time:", round(as.numeric(time2), 2), "seconds\n")

# Second load - should be much faster due to caching
cat("\n[TEST 3] Loading TAHOE signatures again (should be cached)...\n")
start3 <- Sys.time()
drp2 <- DRP$new(
  signatures_rdata = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures_shared_genes.RData",
  disease_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/disease_signatures/90_subset_creeds_manual_disease_signatures_shared_genes/diabetes_mellitus_signature.csv",
  cmap_meta_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv",
  out_dir = "/tmp/test_out",
  gene_key = "SYMBOL",
  logfc_cols_pref = "logfc_dz",
  analysis_id = "TAHOE"
)
drp2$load_cmap()
time3 <- difftime(Sys.time(), start3, units = "secs")
cat("  Time:", round(as.numeric(time3), 2), "seconds (should be much faster!)\n")

cat("\n=== TEST COMPLETED ===\n")
cat("Speedup from caching:", round(as.numeric(time2/time3), 1), "x\n\n")
