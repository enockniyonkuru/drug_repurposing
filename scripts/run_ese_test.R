#!/usr/bin/env Rscript
# Run ESE with probe_id_fallback to verify the fix

library(DRpipe)

cat("\n")
cat("================================================================\n")
cat("Running full DRpipe pipeline for ESE with probe_id_fallback\n")
cat("================================================================\n\n")

set.seed(2009)

drp <- DRP$new(
  signatures_rdata = "data/drug_signatures/cmap_signatures.RData",
  disease_path     = "data/disease_signatures/endo_disease_signatures/endomentriosis_ese_disease_signature.csv",
  drug_meta_path   = "data/drug_signatures/cmap_drug_experiments_new.csv",
  drug_valid_path  = "data/drug_signatures/cmap_valid_instances.csv",
  out_dir          = "results/ESE_test_fallback",
  gene_key         = "symbols",
  logfc_cols_pref  = "logFC",
  logfc_cutoff     = 1.1,
  pval_key         = "adj.P.Val",
  pval_cutoff      = 0.05,
  q_thresh         = 0.0001,
  reversal_only    = TRUE,
  seed             = 2009,
  n_permutations   = 1000,
  probe_id_key     = "X",
  probe_id_fallback = TRUE,
  pvalue_method    = "discrete",
  phipson_smyth_correction = FALSE,
  verbose          = TRUE
)

drp$run_all(make_plots = FALSE)

cat("\n\nResults summary:\n")
cat("  Total drugs with q < 0.0001:", sum(drp$drugs$q < 0.0001), "\n")
cat("  Reversed drugs (cmap_score < 0):", sum(drp$drugs$q < 0.0001 & drp$drugs$cmap_score < 0), "\n")

# Compare with Tomiko
tomiko_ese <- read.csv("../endo_tomiko_code/replication/e2e_rawdata/ESE/drug_instances_ESE.csv")
tomiko_count <- nrow(tomiko_ese)

cat("\n\nComparison with Tomiko:\n")
cat("  Tomiko ESE drugs:", tomiko_count, "\n")
cat("  DRpipe ESE drugs:", sum(drp$drugs$q < 0.0001 & drp$drugs$cmap_score < 0), "\n")

# Check top 20 overlap
drp_top20 <- head(drp$drugs[drp$drugs$cmap_score < 0, ][order(drp$drugs[drp$drugs$cmap_score < 0, ]$cmap_score), ], 20)
tomiko_top20 <- head(tomiko_ese[order(tomiko_ese$cmap_score), ], 20)

common <- length(intersect(drp_top20$id, tomiko_top20$id))
cat("  Top 20 overlap:", common, "/ 20\n")
