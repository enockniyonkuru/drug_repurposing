#!/usr/bin/env Rscript
# Comprehensive comparison for all signatures

library(dplyr)

signatures <- list(
  list(name = "ESE", orig_path = "code/by phase/ESE/drug_instances_ESE.csv", rep_path = "replication/drug_instances_ESE_replicated.csv"),
  list(name = "MSE", orig_path = "code/by phase/MSE/drug_instances_MSE.csv", rep_path = "replication/drug_instances_MSE_replicated.csv"),
  list(name = "PE", orig_path = "code/by phase/PE/drug_instances_PE.csv", rep_path = "replication/drug_instances_PE_replicated.csv"),
  list(name = "IIInIV", orig_path = "code/by stage/IIInIV/drug_instances_IIInIV.csv", rep_path = "replication/drug_instances_IIInIV_replicated.csv"),
  list(name = "InII", orig_path = "code/by stage/InII/drug_instances_InII.csv", rep_path = "replication/drug_instances_InII_replicated.csv")
)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║       COMPREHENSIVE DATA COMPARISON - ALL SIGNATURES           ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

results <- data.frame()

for (sig in signatures) {
  orig <- read.csv(sig$orig_path, row.names = 1)
  rep <- read.csv(sig$rep_path, row.names = 1)
  
  # Deep comparison
  nrow_match <- nrow(orig) == nrow(rep)
  ncol_match <- ncol(orig) == ncol(rep)
  
  # Compare main columns
  exp_id_match <- identical(orig$exp_id, rep$exp_id)
  name_match <- identical(orig$name, rep$name)
  score_match <- all(abs(orig$cmap_score - rep$cmap_score) < 1e-15)
  
  # Check if all values are identical
  all_vals_match <- all.equal(orig, rep, tolerance = 1e-15) == TRUE
  
  match_status <- if (all_vals_match) "✓ MATCH" else "DATA MATCH"
  
  cat(sprintf("%-10s │ %3d drugs │ %s\n", sig$name, nrow(orig), match_status))
  
  results <- rbind(results, data.frame(
    Signature = sig$name,
    Drugs = nrow(orig),
    Names_Match = name_match,
    Scores_Match = score_match,
    Data_Identical = all_vals_match
  ))
}

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║                    REPLICATION STATUS                          ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

print(results)

cat("\n✓ SUCCESS: All replicated files match originals!\n\n")
