#!/usr/bin/env Rscript
# Check aggregation differences between CMAP and TAHOE

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/results")

load("endo_v3/CMAP_Endometriosis_ESE_Strict_20260121-185219/endomentriosis_ese_disease_signature_results.RData")
cmap_results <- results

load("endo_tahoe_ESE/endomentriosis_ese_disease_signature_results.RData")
tahoe_results <- results

cat("=== Score Distribution ===\n")
cat("CMAP scores: min=", min(cmap_results$drugs$cmap_score), " max=", max(cmap_results$drugs$cmap_score), "\n")
cat("TAHOE scores: min=", min(tahoe_results$drugs$cmap_score), " max=", max(tahoe_results$drugs$cmap_score), "\n")

cat("\n=== P-value Distribution ===\n")
cat("CMAP p=0:", sum(cmap_results$drugs$p == 0), "/", nrow(cmap_results$drugs), "(", round(100*sum(cmap_results$drugs$p == 0)/nrow(cmap_results$drugs),1), "%)\n")
cat("TAHOE p=0:", sum(tahoe_results$drugs$p == 0), "/", nrow(tahoe_results$drugs), "(", round(100*sum(tahoe_results$drugs$p == 0)/nrow(tahoe_results$drugs),1), "%)\n")

cat("\n=== Signature Size ===\n")
cat("CMAP signature genes:", length(cmap_results$signature_clean$gene_id), "\n")
cat("TAHOE signature genes:", length(tahoe_results$signature_clean$gene_id), "\n")

cat("\n=== Q=0 and score<0 counts ===\n")
cmap_q0 <- cmap_results$drugs[cmap_results$drugs$q == 0 & cmap_results$drugs$cmap_score < 0, ]
tahoe_q0 <- tahoe_results$drugs[tahoe_results$drugs$q == 0 & tahoe_results$drugs$cmap_score < 0, ]
cat("CMAP:", nrow(cmap_q0), "\n")
cat("TAHOE:", nrow(tahoe_q0), "\n")
