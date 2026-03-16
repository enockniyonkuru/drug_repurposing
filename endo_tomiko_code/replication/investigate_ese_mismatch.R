#!/usr/bin/env Rscript

#####################################################################
# INVESTIGATION: Why does ESE have lower overlap?
# Tomiko: 208 drugs, DRpipe: 138 drugs, Common: 138
# 70 drugs found by Tomiko but NOT by DRpipe
#####################################################################

library(dplyr)

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("INVESTIGATION: ESE Mismatch Analysis\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# LOAD DATA
# ============================================================================

# Load Tomiko ESE results
tomiko_ese <- read.csv("endo_tomiko_code/replication/e2e_rawdata/ESE/drug_instances_ESE.csv")

# Load DRpipe ESE results
drpipe_ese <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_ESE_Strict_20260121-160656/endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv")

cat("Total drugs:\n")
cat("  Tomiko ESE:", nrow(tomiko_ese), "\n")
cat("  DRpipe ESE:", nrow(drpipe_ese), "\n\n")

# Identify drugs unique to Tomiko (not in DRpipe)
tomiko_only <- tomiko_ese[!tomiko_ese$name %in% drpipe_ese$name, ]
common_drugs <- tomiko_ese[tomiko_ese$name %in% drpipe_ese$name, ]

cat("Drug overlap:\n")
cat("  Common:", nrow(common_drugs), "\n")
cat("  Tomiko only:", nrow(tomiko_only), "\n\n")

# ============================================================================
# ANALYZE TOMIKO-ONLY DRUGS
# ============================================================================

cat("════════════════════════════════════════════════════════════════\n")
cat("ANALYZING 70 TOMIKO-ONLY DRUGS\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Compare q-values
cat("Q-value (FDR) statistics:\n")
cat("  Tomiko-only drugs:\n")
cat("    Min q:", min(tomiko_only$q), "\n")
cat("    Max q:", max(tomiko_only$q), "\n")
cat("    Mean q:", mean(tomiko_only$q), "\n")
cat("    Median q:", median(tomiko_only$q), "\n\n")

cat("  Common drugs (in both):\n")
cat("    Min q:", min(common_drugs$q), "\n")
cat("    Max q:", max(common_drugs$q), "\n")
cat("    Mean q:", mean(common_drugs$q), "\n")
cat("    Median q:", median(common_drugs$q), "\n\n")

# Compare cmap_scores
cat("CMAP score statistics:\n")
cat("  Tomiko-only drugs:\n")
cat("    Min score:", min(tomiko_only$cmap_score), "\n")
cat("    Max score:", max(tomiko_only$cmap_score), "\n")
cat("    Mean score:", mean(tomiko_only$cmap_score), "\n\n")

cat("  Common drugs (in both):\n")
cat("    Min score:", min(common_drugs$cmap_score), "\n")
cat("    Max score:", max(common_drugs$cmap_score), "\n")
cat("    Mean score:", mean(common_drugs$cmap_score), "\n\n")

# Compare p-values
cat("P-value statistics:\n")
cat("  Tomiko-only drugs:\n")
cat("    Min p:", min(tomiko_only$p), "\n")
cat("    Max p:", max(tomiko_only$p), "\n")
cat("    Mean p:", mean(tomiko_only$p), "\n\n")

cat("  Common drugs (in both):\n")
cat("    Min p:", min(common_drugs$p), "\n")
cat("    Max p:", max(common_drugs$p), "\n")
cat("    Mean p:", mean(common_drugs$p), "\n\n")

# ============================================================================
# CHECK DISEASE SIGNATURES
# ============================================================================

cat("════════════════════════════════════════════════════════════════\n")
cat("COMPARING DISEASE SIGNATURES\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Load Tomiko raw signature (what was used)
tomiko_rawdata <- read.csv("endo_tomiko_code/code/by phase/ESE/rawdata.csv")
cat("Tomiko rawdata.csv:\n")
cat("  Total genes:", nrow(tomiko_rawdata), "\n")
cat("  Columns:", paste(colnames(tomiko_rawdata), collapse=", "), "\n\n")

# Load DRpipe signature
drpipe_sig_files <- list.files("scripts/data/disease_signatures/endo_disease_signatures/", 
                                pattern = "ese", full.names = TRUE, ignore.case = TRUE)
cat("DRpipe ESE signature files found:\n")
for (f in drpipe_sig_files) {
  cat("  ", basename(f), "\n")
}
cat("\n")

# Load DRpipe signature
if (length(drpipe_sig_files) > 0) {
  for (f in drpipe_sig_files) {
    sig <- read.csv(f)
    cat("File:", basename(f), "\n")
    cat("  Total genes:", nrow(sig), "\n")
    cat("  Columns:", paste(colnames(sig), collapse=", "), "\n\n")
  }
}

# ============================================================================
# COMPARE AFTER FILTERING
# ============================================================================

cat("════════════════════════════════════════════════════════════════\n")
cat("COMPARING FILTERED SIGNATURES\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Load CMap gene list
load('endo_tomiko_code/code/cmap data/cmap_signatures.RData')
gene_list <- cmap_signatures[, 1]

# Filter Tomiko signature (same as pipeline)
colnames(tomiko_rawdata)[c(1,2)] <- c("GeneID", "log2FoldChange")
tomiko_filtered <- tomiko_rawdata[tomiko_rawdata$adj.P.Val < 0.05, ]
tomiko_filtered <- tomiko_filtered[abs(tomiko_filtered$log2FoldChange) > 1.1, ]
tomiko_filtered$GeneID <- gsub("_at", "", tomiko_filtered$GeneID)
tomiko_filtered <- tomiko_filtered[tomiko_filtered$GeneID %in% gene_list, ]

tomiko_up <- sum(tomiko_filtered$log2FoldChange > 0)
tomiko_down <- sum(tomiko_filtered$log2FoldChange < 0)

cat("Tomiko ESE signature after filtering:\n")
cat("  Total genes:", nrow(tomiko_filtered), "\n")
cat("  Up-regulated:", tomiko_up, "\n")
cat("  Down-regulated:", tomiko_down, "\n\n")

# Load and filter DRpipe signature
if (file.exists("scripts/data/disease_signatures/endo_disease_signatures/endomentriosis_ese_disease_signature.csv")) {
  drpipe_sig <- read.csv("scripts/data/disease_signatures/endo_disease_signatures/endomentriosis_ese_disease_signature.csv")
  cat("DRpipe ESE signature:\n")
  cat("  Total genes:", nrow(drpipe_sig), "\n")
  cat("  Columns:", paste(colnames(drpipe_sig), collapse=", "), "\n")
  
  # Check if already filtered
  if ("log2FoldChange" %in% colnames(drpipe_sig) || "logFC" %in% colnames(drpipe_sig)) {
    lfc_col <- if ("log2FoldChange" %in% colnames(drpipe_sig)) "log2FoldChange" else "logFC"
    drpipe_up <- sum(drpipe_sig[[lfc_col]] > 0)
    drpipe_down <- sum(drpipe_sig[[lfc_col]] < 0)
    cat("  Up-regulated:", drpipe_up, "\n")
    cat("  Down-regulated:", drpipe_down, "\n")
  }
  cat("\n")
}

# ============================================================================
# LIST TOMIKO-ONLY DRUGS
# ============================================================================

cat("════════════════════════════════════════════════════════════════\n")
cat("TOMIKO-ONLY DRUGS (sorted by q-value)\n")
cat("════════════════════════════════════════════════════════════════\n\n")

tomiko_only_sorted <- tomiko_only[order(tomiko_only$q), ]
cat("Drugs found by Tomiko but NOT by DRpipe (showing first 30):\n\n")

for (i in 1:min(30, nrow(tomiko_only_sorted))) {
  cat(sprintf("%2d. %-25s q=%.6f  score=%.4f  p=%.4f\n", 
              i, 
              tomiko_only_sorted$name[i], 
              tomiko_only_sorted$q[i],
              tomiko_only_sorted$cmap_score[i],
              tomiko_only_sorted$p[i]))
}

cat("\n")

# ============================================================================
# KEY INSIGHT: Check q-value threshold
# ============================================================================

cat("════════════════════════════════════════════════════════════════\n")
cat("KEY INSIGHT: Q-VALUE THRESHOLD ANALYSIS\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Both pipelines use q < 0.0001
threshold <- 0.0001

# How many Tomiko-only drugs have q very close to threshold?
near_threshold <- tomiko_only[tomiko_only$q > threshold * 0.1 & tomiko_only$q < threshold, ]
cat("Tomiko-only drugs with q between 0.00001 and 0.0001:", nrow(near_threshold), "\n")

very_low_q <- tomiko_only[tomiko_only$q < threshold * 0.1, ]
cat("Tomiko-only drugs with q < 0.00001:", nrow(very_low_q), "\n\n")

# This suggests randomness in permutation test!
cat("HYPOTHESIS: The difference may be due to:\n")
cat("  1. Different random seeds in permutation tests\n")
cat("  2. Different number of permutations\n")
cat("  3. Different disease signature gene counts\n")
cat("  4. Different CMap reference data\n\n")

# Save analysis
write.csv(tomiko_only, "endo_tomiko_code/replication/e2e_rawdata/ESE_tomiko_only_drugs.csv", row.names = FALSE)
cat("✓ Saved Tomiko-only drugs to: e2e_rawdata/ESE_tomiko_only_drugs.csv\n\n")
