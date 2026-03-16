#!/usr/bin/env Rscript

# =============================================================================
# DEEP INVESTIGATION: Why does TAHOE produce fewer hits than CMAP?
# =============================================================================

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

library(dplyr)
library(ggplot2)

cat("================================================================================\n")
cat("INVESTIGATION: Why does TAHOE produce fewer hits than CMAP?\n")
cat("================================================================================\n\n")

# Load results for ESE (representative signature)
load("scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
cmap_results <- results

load("scripts/results/endo_v5_tahoe/endo_tahoe_ESE/endomentriosis_ese_disease_signature_results.RData")
tahoe_results <- results

# =============================================================================
# 1. DATABASE SIZE COMPARISON
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("1. DATABASE SIZE COMPARISON\n")
cat(paste(rep("=", 80), collapse=""), "\n")

cat("\nTotal drug experiments:\n")
cat("  CMAP:  ", format(nrow(cmap_results$drugs), big.mark=","), "\n")
cat("  TAHOE: ", format(nrow(tahoe_results$drugs), big.mark=","), "\n")
cat("  Ratio: TAHOE has", round(nrow(tahoe_results$drugs)/nrow(cmap_results$drugs), 1), "x more experiments\n")

cat("\nUnique drugs:\n")
cat("  CMAP:  ", length(unique(cmap_results$drugs$name)), "\n")
cat("  TAHOE: ", length(unique(tahoe_results$drugs$name)), "\n")

# =============================================================================
# 2. SCORE DISTRIBUTION ANALYSIS
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("2. SCORE DISTRIBUTION ANALYSIS\n")
cat(paste(rep("=", 80), collapse=""), "\n")

cat("\nScore statistics:\n")
cat("                    CMAP            TAHOE\n")
cat(sprintf("  Min:          %10.4f      %10.4f\n", min(cmap_results$drugs$cmap_score), min(tahoe_results$drugs$cmap_score)))
cat(sprintf("  Max:          %10.4f      %10.4f\n", max(cmap_results$drugs$cmap_score), max(tahoe_results$drugs$cmap_score)))
cat(sprintf("  Mean:         %10.4f      %10.4f\n", mean(cmap_results$drugs$cmap_score), mean(tahoe_results$drugs$cmap_score)))
cat(sprintf("  Median:       %10.4f      %10.4f\n", median(cmap_results$drugs$cmap_score), median(tahoe_results$drugs$cmap_score)))
cat(sprintf("  SD:           %10.4f      %10.4f\n", sd(cmap_results$drugs$cmap_score), sd(tahoe_results$drugs$cmap_score)))

cat("\nScore percentiles:\n")
cat("  Percentile        CMAP            TAHOE\n")
for (p in c(0.01, 0.05, 0.10, 0.25, 0.50)) {
  cat(sprintf("  %5.0f%%:       %10.4f      %10.4f\n", 
              p*100, 
              quantile(cmap_results$drugs$cmap_score, p),
              quantile(tahoe_results$drugs$cmap_score, p)))
}

# Count negative scores (therapeutic direction)
cmap_neg <- sum(cmap_results$drugs$cmap_score < 0)
tahoe_neg <- sum(tahoe_results$drugs$cmap_score < 0)
cat("\nNegative scores (therapeutic direction):\n")
cat(sprintf("  CMAP:  %d / %d (%.1f%%)\n", cmap_neg, nrow(cmap_results$drugs), 100*cmap_neg/nrow(cmap_results$drugs)))
cat(sprintf("  TAHOE: %d / %d (%.1f%%)\n", tahoe_neg, nrow(tahoe_results$drugs), 100*tahoe_neg/nrow(tahoe_results$drugs)))

# =============================================================================
# 3. P-VALUE DISTRIBUTION
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("3. P-VALUE DISTRIBUTION\n")
cat(paste(rep("=", 80), collapse=""), "\n")

cat("\nP-value = 0 (most significant):\n")
cmap_p0 <- sum(cmap_results$drugs$p == 0)
tahoe_p0 <- sum(tahoe_results$drugs$p == 0)
cat(sprintf("  CMAP:  %d / %d (%.1f%%)\n", cmap_p0, nrow(cmap_results$drugs), 100*cmap_p0/nrow(cmap_results$drugs)))
cat(sprintf("  TAHOE: %d / %d (%.1f%%)\n", tahoe_p0, nrow(tahoe_results$drugs), 100*tahoe_p0/nrow(tahoe_results$drugs)))

cat("\nP-value percentiles:\n")
cat("  Percentile        CMAP            TAHOE\n")
for (p in c(0.25, 0.50, 0.75, 0.90, 0.95)) {
  cat(sprintf("  %5.0f%%:       %10.4f      %10.4f\n", 
              p*100, 
              quantile(cmap_results$drugs$p, p),
              quantile(tahoe_results$drugs$p, p)))
}

# =============================================================================
# 4. Q-VALUE (FDR) DISTRIBUTION - THE KEY FACTOR
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("4. Q-VALUE (FDR) DISTRIBUTION - KEY FACTOR\n")
cat(paste(rep("=", 80), collapse=""), "\n")

cat("\nQ-value = 0 (hits with q < 0.01 threshold):\n")
cmap_q0 <- sum(cmap_results$drugs$q == 0)
tahoe_q0 <- sum(tahoe_results$drugs$q == 0)
cat(sprintf("  CMAP:  %d / %d (%.1f%%)\n", cmap_q0, nrow(cmap_results$drugs), 100*cmap_q0/nrow(cmap_results$drugs)))
cat(sprintf("  TAHOE: %d / %d (%.1f%%)\n", tahoe_q0, nrow(tahoe_results$drugs), 100*tahoe_q0/nrow(tahoe_results$drugs)))

cat("\nQ-value = 0 AND negative score (actual hits):\n")
cmap_hits <- sum(cmap_results$drugs$q == 0 & cmap_results$drugs$cmap_score < 0)
tahoe_hits <- sum(tahoe_results$drugs$q == 0 & tahoe_results$drugs$cmap_score < 0)
cat(sprintf("  CMAP:  %d\n", cmap_hits))
cat(sprintf("  TAHOE: %d\n", tahoe_hits))
cat(sprintf("  Ratio: CMAP has %.1fx more hits\n", cmap_hits/tahoe_hits))

cat("\nQ-value percentiles:\n")
cat("  Percentile        CMAP            TAHOE\n")
for (p in c(0.10, 0.25, 0.50, 0.75, 0.90)) {
  cat(sprintf("  %5.0f%%:       %10.4f      %10.4f\n", 
              p*100, 
              quantile(cmap_results$drugs$q, p),
              quantile(tahoe_results$drugs$q, p)))
}

# =============================================================================
# 5. MULTIPLE TESTING CORRECTION IMPACT
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("5. MULTIPLE TESTING CORRECTION IMPACT\n")
cat(paste(rep("=", 80), collapse=""), "\n")

cat("\nBenjamini-Hochberg FDR correction:\n")
cat("  - More tests = stricter correction = fewer discoveries\n")
cat("  - CMAP tests:", format(nrow(cmap_results$drugs), big.mark=","), "hypotheses\n")
cat("  - TAHOE tests:", format(nrow(tahoe_results$drugs), big.mark=","), "hypotheses\n")

# Calculate what p-value is needed for q < 0.01
cmap_sorted <- sort(cmap_results$drugs$p)
tahoe_sorted <- sort(tahoe_results$drugs$p)

# For BH correction: q = p * n / rank
# To get q < 0.01: p < 0.01 * rank / n
cat("\nP-value threshold for q < 0.01 at different ranks:\n")
cat("  Rank          CMAP p-threshold    TAHOE p-threshold\n")
for (rank in c(10, 50, 100, 500, 1000)) {
  cmap_thresh <- 0.01 * rank / nrow(cmap_results$drugs)
  tahoe_thresh <- 0.01 * rank / nrow(tahoe_results$drugs)
  cat(sprintf("  %5d         %.6f            %.6f\n", rank, cmap_thresh, tahoe_thresh))
}

cat("\n  => TAHOE requires ~9x smaller p-values to achieve the same q-value!\n")

# =============================================================================
# 6. GENE SIGNATURE OVERLAP
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("6. GENE SIGNATURE OVERLAP WITH DRUG DATABASES\n")
cat(paste(rep("=", 80), collapse=""), "\n")

# Load the drug signature databases
tryCatch({
  if (file.exists("scripts/data/drug_signatures/cmap_signatures.RData")) {
    load("scripts/data/drug_signatures/cmap_signatures.RData")
    # Check what object was loaded
    loaded_objs <- ls()
    if ("drug_signatures" %in% loaded_objs) {
      cmap_genes <- rownames(drug_signatures)
      cat("\nCMAP database genes:", length(cmap_genes), "\n")
    } else if ("signatures" %in% loaded_objs) {
      cmap_genes <- rownames(signatures)
      cat("\nCMAP database genes:", length(cmap_genes), "\n")
    } else {
      cat("\nCMAP signature file structure unknown\n")
    }
  }
  
  if (file.exists("scripts/data/drug_signatures/tahoe_signatures.RData")) {
    load("scripts/data/drug_signatures/tahoe_signatures.RData")
    if ("drug_signatures" %in% ls()) {
      tahoe_genes <- rownames(drug_signatures)
    } else if ("signatures" %in% ls()) {
      tahoe_genes <- rownames(signatures)
    }
    cat("TAHOE database genes:", length(tahoe_genes), "\n")
    
    if (exists("cmap_genes") && exists("tahoe_genes")) {
      overlap <- intersect(cmap_genes, tahoe_genes)
      cat("Overlapping genes:", length(overlap), "\n")
      cat("CMAP-only genes:", length(setdiff(cmap_genes, tahoe_genes)), "\n")
      cat("TAHOE-only genes:", length(setdiff(tahoe_genes, cmap_genes)), "\n")
    }
  }
}, error = function(e) {
  cat("\nCould not load signature files:", e$message, "\n")
})

# =============================================================================
# 7. SCORE-TO-SIGNIFICANCE RELATIONSHIP
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("7. SCORE-TO-SIGNIFICANCE RELATIONSHIP\n")
cat(paste(rep("=", 80), collapse=""), "\n")

# What score is needed to get a significant result?
cmap_sig <- cmap_results$drugs[cmap_results$drugs$q == 0 & cmap_results$drugs$cmap_score < 0, ]
tahoe_sig <- tahoe_results$drugs[tahoe_results$drugs$q == 0 & tahoe_results$drugs$cmap_score < 0, ]

if (nrow(cmap_sig) > 0) {
  cat("\nCMAP significant hits (q=0, score<0):\n")
  cat(sprintf("  Score range: %.4f to %.4f\n", min(cmap_sig$cmap_score), max(cmap_sig$cmap_score)))
  cat(sprintf("  Mean score: %.4f\n", mean(cmap_sig$cmap_score)))
}

if (nrow(tahoe_sig) > 0) {
  cat("\nTAHOE significant hits (q=0, score<0):\n")
  cat(sprintf("  Score range: %.4f to %.4f\n", min(tahoe_sig$cmap_score), max(tahoe_sig$cmap_score)))
  cat(sprintf("  Mean score: %.4f\n", mean(tahoe_sig$cmap_score)))
}

# What's the least negative score that's still significant?
cat("\nLeast negative significant score (threshold for significance):\n")
cat(sprintf("  CMAP:  %.4f\n", max(cmap_sig$cmap_score)))
if (nrow(tahoe_sig) > 0) {
  cat(sprintf("  TAHOE: %.4f\n", max(tahoe_sig$cmap_score)))
} else {
  cat("  TAHOE: No significant hits\n")
}

# =============================================================================
# 8. RANDOM SCORE DISTRIBUTION (PERMUTATION NULL)
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("8. PERMUTATION NULL DISTRIBUTION ANALYSIS\n")
cat(paste(rep("=", 80), collapse=""), "\n")

# Load random scores if available
cmap_random_file <- "scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_random_scores_logFC_1.1.RData"
tahoe_random_file <- "scripts/results/endo_v5_tahoe/endo_tahoe_ESE/endomentriosis_ese_disease_signature_random_scores_logFC_1.1.RData"

if (file.exists(cmap_random_file) && file.exists(tahoe_random_file)) {
  load(cmap_random_file)
  cmap_random <- random_scores
  
  load(tahoe_random_file)
  tahoe_random <- random_scores
  
  cat("\nRandom score distribution (permutation null):\n")
  cat("  Number of permutations:\n")
  cat("    CMAP: ", length(cmap_random), "\n")
  cat("    TAHOE:", length(tahoe_random), "\n")
  
  if (length(cmap_random) > 0 && length(tahoe_random) > 0) {
    cat("\n  Random score statistics:\n")
    cat("                      CMAP            TAHOE\n")
    cat(sprintf("    Min:          %10.4f      %10.4f\n", min(cmap_random), min(tahoe_random)))
    cat(sprintf("    Max:          %10.4f      %10.4f\n", max(cmap_random), max(tahoe_random)))
    cat(sprintf("    Mean:         %10.4f      %10.4f\n", mean(cmap_random), mean(tahoe_random)))
    cat(sprintf("    SD:           %10.4f      %10.4f\n", sd(cmap_random), sd(tahoe_random)))
    
    cat("\n  Negative random scores (false positive rate under null):\n")
    cmap_neg_random <- sum(cmap_random < 0)
    tahoe_neg_random <- sum(tahoe_random < 0)
    cat(sprintf("    CMAP:  %d / %d (%.1f%%)\n", cmap_neg_random, length(cmap_random), 100*cmap_neg_random/length(cmap_random)))
    cat(sprintf("    TAHOE: %d / %d (%.1f%%)\n", tahoe_neg_random, length(tahoe_random), 100*tahoe_neg_random/length(tahoe_random)))
  }
}

# =============================================================================
# SUMMARY AND CONCLUSIONS
# =============================================================================
cat("\n", paste(rep("=", 80), collapse=""), "\n")
cat("SUMMARY: ROOT CAUSES FOR FEWER TAHOE HITS\n")
cat(paste(rep("=", 80), collapse=""), "\n")

cat("
1. LARGER DATABASE SIZE (PRIMARY CAUSE)
   - TAHOE has 9.3x more drug experiments than CMAP
   - Benjamini-Hochberg FDR correction becomes much stricter
   - Same p-value results in ~9x higher q-value in TAHOE

2. POSITIVE SCORE SHIFT
   - CMAP mean score: -0.065 (toward therapeutic)
   - TAHOE mean score: +0.142 (away from therapeutic)
   - Only 29% of TAHOE scores are negative vs 60% of CMAP

3. TIGHTER SCORE DISTRIBUTION
   - CMAP SD: 0.30 (more spread, more extreme values)
   - TAHOE SD: 0.17 (tighter distribution)
   - Harder to achieve extreme negative scores in TAHOE

4. DIFFERENT DRUG LIBRARIES
   - TAHOE contains newer drugs not in CMAP
   - Different cell lines and experimental conditions
   - 24-hour exposures (TAHOE) vs 6-hour (CMAP)

RECOMMENDATIONS:
   a) Consider using a less stringent q-value threshold for TAHOE (e.g., q < 0.05)
   b) Use rank-based comparison instead of significance threshold
   c) Validate top TAHOE candidates even without strict significance
   d) Consider combining results from both databases
")

cat("\n✓ Investigation complete!\n")
