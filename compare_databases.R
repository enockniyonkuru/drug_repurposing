#!/usr/bin/env Rscript
# Detailed comparison of CMAP vs TAHOE results

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/results")

# Load CMAP results
load("endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
cmap_results <- results

# Load TAHOE results  
load("endo_v5_tahoe/endo_tahoe_ESE/endomentriosis_ese_disease_signature_results.RData")
tahoe_results <- results

cat("=== DATABASE SIZE ===\n")
cat("CMAP total drug experiments:", nrow(cmap_results$drugs), "\n")
cat("TAHOE total drug experiments:", nrow(tahoe_results$drugs), "\n")

cat("\n=== UNIQUE DRUGS ===\n")
cat("CMAP unique drugs:", length(unique(cmap_results$drugs$name)), "\n")
cat("TAHOE unique drugs:", length(unique(tahoe_results$drugs$name)), "\n")

cat("\n=== SCORE DISTRIBUTION ===\n")
cat("CMAP scores: min=", min(cmap_results$drugs$cmap_score), " max=", max(cmap_results$drugs$cmap_score), "\n")
cat("TAHOE scores: min=", min(tahoe_results$drugs$cmap_score), " max=", max(tahoe_results$drugs$cmap_score), "\n")
cat("CMAP mean:", mean(cmap_results$drugs$cmap_score), " sd:", sd(cmap_results$drugs$cmap_score), "\n")
cat("TAHOE mean:", mean(tahoe_results$drugs$cmap_score), " sd:", sd(tahoe_results$drugs$cmap_score), "\n")

cat("\n=== SIGNATURE OVERLAP ===\n")
cat("CMAP disease signature genes:", length(cmap_results$signature_clean$gene_id), "\n")
cat("TAHOE disease signature genes:", length(tahoe_results$signature_clean$gene_id), "\n")

cat("\n=== P-VALUE DISTRIBUTION ===\n")
cat("CMAP p=0:", sum(cmap_results$drugs$p == 0), "(", round(100*sum(cmap_results$drugs$p == 0)/nrow(cmap_results$drugs),1), "%)\n")
cat("TAHOE p=0:", sum(tahoe_results$drugs$p == 0), "(", round(100*sum(tahoe_results$drugs$p == 0)/nrow(tahoe_results$drugs),1), "%)\n")

cat("\n=== Q-VALUE DISTRIBUTION (q=0 with negative scores) ===\n")
cmap_q0 <- sum(cmap_results$drugs$q == 0 & cmap_results$drugs$cmap_score < 0)
tahoe_q0 <- sum(tahoe_results$drugs$q == 0 & tahoe_results$drugs$cmap_score < 0)
cat("CMAP hits (q=0, score<0):", cmap_q0, "\n")
cat("TAHOE hits (q=0, score<0):", tahoe_q0, "\n")

cat("\n=== Q-VALUE QUANTILES ===\n")
cat("CMAP q-value quantiles:\n")
print(quantile(cmap_results$drugs$q, probs=c(0, 0.01, 0.05, 0.10, 0.25, 0.5)))
cat("TAHOE q-value quantiles:\n")
print(quantile(tahoe_results$drugs$q, probs=c(0, 0.01, 0.05, 0.10, 0.25, 0.5)))

cat("\n=== PERMUTATION COUNT ===\n")
cat("CMAP permutations:", length(cmap_results$random_scores), "\n")
cat("TAHOE permutations:", length(tahoe_results$random_scores), "\n")
