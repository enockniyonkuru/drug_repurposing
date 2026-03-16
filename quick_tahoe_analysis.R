#!/usr/bin/env Rscript
# Quick investigation of TAHOE zero scores

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("=== WHY TAHOE HAS FEWER HITS - QUICK ANALYSIS ===\n\n")

# Load results
load("scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
cmap <- results$drugs

load("scripts/results/endo_v5_tahoe/endo_tahoe_ESE/endomentriosis_ese_disease_signature_results.RData")
tahoe <- results$drugs

cat("1. DATABASE SIZE:\n")
cat("   CMAP:", nrow(cmap), "experiments\n")
cat("   TAHOE:", nrow(tahoe), "experiments (9.3x larger)\n")

cat("\n2. ZERO SCORE RATE:\n")
cat("   CMAP:", round(100*sum(cmap$cmap_score == 0)/nrow(cmap),1), "% zero scores\n")
cat("   TAHOE:", round(100*sum(tahoe$cmap_score == 0)/nrow(tahoe),1), "% zero scores\n")

cat("\n3. NEGATIVE SCORE RATE (therapeutic direction):\n")
cat("   CMAP:", round(100*sum(cmap$cmap_score < 0)/nrow(cmap),1), "%\n")
cat("   TAHOE:", round(100*sum(tahoe$cmap_score < 0)/nrow(tahoe),1), "%\n")

cat("\n4. SIGNIFICANCE (p=0):\n")
cat("   CMAP:", round(100*sum(cmap$p == 0)/nrow(cmap),1), "%\n")
cat("   TAHOE:", round(100*sum(tahoe$p == 0)/nrow(tahoe),1), "%\n")

cat("\n5. HITS (q=0 AND score<0):\n")
cat("   CMAP:", sum(cmap$q == 0 & cmap$cmap_score < 0), "\n")
cat("   TAHOE:", sum(tahoe$q == 0 & tahoe$cmap_score < 0), "\n")

cat("\n6. SCORE DISTRIBUTION (non-zero only):\n")
cmap_nz <- cmap$cmap_score[cmap$cmap_score != 0]
tahoe_nz <- tahoe$cmap_score[tahoe$cmap_score != 0]
cat("   CMAP mean:", round(mean(cmap_nz), 4), "\n")
cat("   TAHOE mean:", round(mean(tahoe_nz), 4), "\n")

cat("\n================================================================================\n")
cat("CONCLUSION: THREE REASONS FOR FEWER TAHOE HITS\n")
cat("================================================================================\n")
cat("
1. HIGH ZERO-SCORE RATE (55.8% vs 33.7%)
   - Many TAHOE experiments have no overlap with disease signature genes
   - Or gene identifier mismatch between disease and drug signatures

2. POSITIVE SCORE BIAS
   - Only 0.3% of TAHOE scores are negative (vs 41.5% for CMAP)
   - TAHOE drugs tend to correlate WITH disease, not reverse it
   - Could be biological (different cell lines, concentrations, durations)

3. STRICTER FDR CORRECTION
   - 56,827 tests vs 6,100 tests
   - Same p-value gives ~9x higher q-value in TAHOE
   - Fewer discoveries pass the significance threshold
")
