#!/usr/bin/env Rscript

#####################################################################
# FINAL INVESTIGATION: Why different gene counts after filtering?
# Tomiko: 197 genes, DRpipe: 194 genes
#####################################################################

library(dplyr)

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("INVESTIGATION: Gene Count Difference (197 vs 194)\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Load CMap gene list (used by both pipelines)
load('endo_tomiko_code/code/cmap data/cmap_signatures.RData')
tomiko_gene_list <- cmap_signatures[, 1]

cat("Tomiko CMap gene list:", length(tomiko_gene_list), "genes\n")

# Load DRpipe CMap gene list
load('scripts/data/drug_signatures/cmap_signatures.RData')
drpipe_gene_list <- cmap_signatures[, 1]

cat("DRpipe CMap gene list:", length(drpipe_gene_list), "genes\n\n")

# Are they the same?
cat("CMap gene list comparison:\n")
cat("  Common:", length(intersect(tomiko_gene_list, drpipe_gene_list)), "\n")
cat("  Tomiko only:", length(setdiff(tomiko_gene_list, drpipe_gene_list)), "\n")
cat("  DRpipe only:", length(setdiff(drpipe_gene_list, tomiko_gene_list)), "\n\n")

if (all(tomiko_gene_list == drpipe_gene_list)) {
  cat("✓ CMap gene lists are IDENTICAL\n\n")
} else {
  cat("✗ CMap gene lists are DIFFERENT\n\n")
}

# Load raw ESE signature
rawdata <- read.csv("endo_tomiko_code/code/by phase/ESE/rawdata.csv")
colnames(rawdata)[c(1,2)] <- c("GeneID", "log2FoldChange")

cat("════════════════════════════════════════════════════════════════\n")
cat("FILTERING STEP BY STEP\n")
cat("════════════════════════════════════════════════════════════════\n\n")

cat("Step 0 - Raw data:", nrow(rawdata), "genes\n")

# Step 1: adj.P.Val < 0.05
step1 <- rawdata[rawdata$adj.P.Val < 0.05, ]
cat("Step 1 - adj.P.Val < 0.05:", nrow(step1), "genes\n")

# Step 2: |log2FC| > 1.1
step2 <- step1[abs(step1$log2FoldChange) > 1.1, ]
cat("Step 2 - |log2FC| > 1.1:", nrow(step2), "genes\n")

# Step 3: Clean gene IDs
step2$GeneID <- gsub("_at", "", step2$GeneID)
cat("Step 3 - After cleaning gene IDs:", nrow(step2), "genes\n")

# Step 4: Filter to CMap genes (Tomiko)
step4_tomiko <- step2[step2$GeneID %in% tomiko_gene_list, ]
cat("Step 4a - In Tomiko CMap:", nrow(step4_tomiko), "genes\n")

# Step 4: Filter to CMap genes (DRpipe)
step4_drpipe <- step2[step2$GeneID %in% drpipe_gene_list, ]
cat("Step 4b - In DRpipe CMap:", nrow(step4_drpipe), "genes\n\n")

# The difference
if (nrow(step4_tomiko) != nrow(step4_drpipe)) {
  diff_genes <- setdiff(step4_tomiko$GeneID, step4_drpipe$GeneID)
  cat("Genes in Tomiko but not DRpipe:", length(diff_genes), "\n")
  cat("  ", paste(diff_genes, collapse=", "), "\n\n")
  
  diff_genes2 <- setdiff(step4_drpipe$GeneID, step4_tomiko$GeneID)
  cat("Genes in DRpipe but not Tomiko:", length(diff_genes2), "\n")
  cat("  ", paste(diff_genes2, collapse=", "), "\n\n")
}

# Up/down counts
cat("════════════════════════════════════════════════════════════════\n")
cat("UP/DOWN GENE COUNTS\n")
cat("════════════════════════════════════════════════════════════════\n\n")

tomiko_up <- sum(step4_tomiko$log2FoldChange > 0)
tomiko_down <- sum(step4_tomiko$log2FoldChange < 0)

cat("Tomiko filtered signature:\n")
cat("  Total:", nrow(step4_tomiko), "\n")
cat("  Up:", tomiko_up, "\n")
cat("  Down:", tomiko_down, "\n\n")

# Load DRpipe processed signature from results
load("scripts/results/endo_v2/CMAP_Endometriosis_ESE_Strict_20260121-160656/endomentriosis_ese_disease_signature_results.RData")
drpipe_sig <- results$signature_clean

cat("DRpipe filtered signature (from results.RData):\n")
cat("  Total:", nrow(drpipe_sig), "\n")
cat("  Up:", sum(drpipe_sig$log2FoldChange > 0), "\n")
cat("  Down:", sum(drpipe_sig$log2FoldChange < 0), "\n\n")

# This is the key difference!
cat("════════════════════════════════════════════════════════════════\n")
cat("ROOT CAUSE: GENE COUNT DIFFERENCE\n")
cat("════════════════════════════════════════════════════════════════\n\n")

cat("Tomiko ESE: 197 genes (156 up, 41 down)\n")
cat("DRpipe ESE: 194 genes (", sum(drpipe_sig$log2FoldChange > 0), " up, ", 
    sum(drpipe_sig$log2FoldChange < 0), " down)\n\n")

cat("The 3-gene difference affects the random distribution calculation!\n\n")

# Check what genes are different
tomiko_gene_ids <- step4_tomiko$GeneID
drpipe_gene_ids <- drpipe_sig$GeneID

cat("Gene ID comparison:\n")
cat("  Tomiko genes:", length(tomiko_gene_ids), "\n")
cat("  DRpipe genes:", length(drpipe_gene_ids), "\n")
cat("  Common:", length(intersect(tomiko_gene_ids, drpipe_gene_ids)), "\n")
cat("  Tomiko only:", length(setdiff(tomiko_gene_ids, drpipe_gene_ids)), "\n")
cat("  DRpipe only:", length(setdiff(drpipe_gene_ids, tomiko_gene_ids)), "\n\n")

missing_in_drpipe <- setdiff(tomiko_gene_ids, drpipe_gene_ids)
if (length(missing_in_drpipe) > 0) {
  cat("Genes in Tomiko but not in DRpipe signature:\n")
  for (g in missing_in_drpipe) {
    gene_row <- step4_tomiko[step4_tomiko$GeneID == g, ]
    cat(sprintf("  %s: logFC=%.3f, adj.P.Val=%.6f\n", 
                g, gene_row$log2FoldChange[1], gene_row$adj.P.Val[1]))
  }
}
