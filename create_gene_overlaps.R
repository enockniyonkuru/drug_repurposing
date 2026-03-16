# ============================================================================
# Create Gene Overlaps Visualization
# Comparing CMAP v4 and TAHOE v5 gene coverage
# ============================================================================

suppressPackageStartupMessages({
  library(gplots)
  library(ggplot2)
  library(tidyverse)
  library(RColorBrewer)
})

# Try to load eulerr for Venn diagrams
if (!require("eulerr", quietly = TRUE)) {
  cat("Installing eulerr package...\n")
  install.packages("eulerr", repos = "https://cloud.r-project.org/")
  library(eulerr)
} else {
  library(eulerr)
}

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("=======================================================\n")
cat("Gene Overlaps Visualization Generator\n")
cat("=======================================================\n\n")

# ============================================================================
# Load Data
# ============================================================================

cat("Loading CMAP signatures...\n")
load("scripts/data/drug_signatures/cmap_signatures.RData")
cmap_genes <- as.character(cmap_signatures[, 1])
cat("  CMAP genes:", length(cmap_genes), "\n")

cat("Loading TAHOE signatures...\n")
load("scripts/data/drug_signatures/tahoe_signatures.RData")
tahoe_genes <- as.character(tahoe_signatures[, 1])
cat("  TAHOE genes:", length(tahoe_genes), "\n")

# ============================================================================
# Load Disease Signatures
# ============================================================================

cat("\nLoading disease signatures...\n")

# Unstratified
load("scripts/results/endo_v4_cmap/endo_v4_Unstratified/endomentriosis_unstratified_disease_signature.csv_results.RData")
dz_unstrat <- as.character(results$signature_clean$GeneID)

# InII
load("scripts/results/endo_v4_cmap/endo_v4_InII/endomentriosis_inii_disease_signature_results.RData")
dz_inii <- as.character(results$signature_clean$GeneID)

# IIInIV
load("scripts/results/endo_v4_cmap/endo_v4_IIInIV/endomentriosis_iiiniv_disease_signature_results.RData")
dz_iiiniv <- as.character(results$signature_clean$GeneID)

# PE
load("scripts/results/endo_v4_cmap/endo_v4_PE/endomentriosis_pe_disease_signature_results.RData")
dz_pe <- as.character(results$signature_clean$GeneID)

# ESE
load("scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
dz_ese <- as.character(results$signature_clean$GeneID)

# MSE
load("scripts/results/endo_v4_cmap/endo_v4_MSE/endomentriosis_mse_disease_signature_results.RData")
dz_mse <- as.character(results$signature_clean$GeneID)

cat("  Unstratified:", length(dz_unstrat), "genes\n")
cat("  Stage I/II:", length(dz_inii), "genes\n")
cat("  Stage III/IV:", length(dz_iiiniv), "genes\n")
cat("  PE:", length(dz_pe), "genes\n")
cat("  ESE:", length(dz_ese), "genes\n")
cat("  MSE:", length(dz_mse), "genes\n")

# ============================================================================
# Calculate Overlaps
# ============================================================================

cat("\n=== Gene Coverage Analysis ===\n\n")

# Disease signature genes in CMAP
unstrat_in_cmap <- sum(dz_unstrat %in% cmap_genes)
inii_in_cmap <- sum(dz_inii %in% cmap_genes)
iiiniv_in_cmap <- sum(dz_iiiniv %in% cmap_genes)
pe_in_cmap <- sum(dz_pe %in% cmap_genes)
ese_in_cmap <- sum(dz_ese %in% cmap_genes)
mse_in_cmap <- sum(dz_mse %in% cmap_genes)

# Disease signature genes in TAHOE
unstrat_in_tahoe <- sum(dz_unstrat %in% tahoe_genes)
inii_in_tahoe <- sum(dz_inii %in% tahoe_genes)
iiiniv_in_tahoe <- sum(dz_iiiniv %in% tahoe_genes)
pe_in_tahoe <- sum(dz_pe %in% tahoe_genes)
ese_in_tahoe <- sum(dz_ese %in% tahoe_genes)
mse_in_tahoe <- sum(dz_mse %in% tahoe_genes)

cat("Disease Signature Gene Coverage:\n")
cat(sprintf("  %-15s CMAP: %4d/%4d (%.1f%%)  TAHOE: %4d/%4d (%.1f%%)\n", 
            "Unstratified", unstrat_in_cmap, length(dz_unstrat), 100*unstrat_in_cmap/length(dz_unstrat),
            unstrat_in_tahoe, length(dz_unstrat), 100*unstrat_in_tahoe/length(dz_unstrat)))
cat(sprintf("  %-15s CMAP: %4d/%4d (%.1f%%)  TAHOE: %4d/%4d (%.1f%%)\n", 
            "Stage I/II", inii_in_cmap, length(dz_inii), 100*inii_in_cmap/length(dz_inii),
            inii_in_tahoe, length(dz_inii), 100*inii_in_tahoe/length(dz_inii)))
cat(sprintf("  %-15s CMAP: %4d/%4d (%.1f%%)  TAHOE: %4d/%4d (%.1f%%)\n", 
            "Stage III/IV", iiiniv_in_cmap, length(dz_iiiniv), 100*iiiniv_in_cmap/length(dz_iiiniv),
            iiiniv_in_tahoe, length(dz_iiiniv), 100*iiiniv_in_tahoe/length(dz_iiiniv)))
cat(sprintf("  %-15s CMAP: %4d/%4d (%.1f%%)  TAHOE: %4d/%4d (%.1f%%)\n", 
            "PE", pe_in_cmap, length(dz_pe), 100*pe_in_cmap/length(dz_pe),
            pe_in_tahoe, length(dz_pe), 100*pe_in_tahoe/length(dz_pe)))
cat(sprintf("  %-15s CMAP: %4d/%4d (%.1f%%)  TAHOE: %4d/%4d (%.1f%%)\n", 
            "ESE", ese_in_cmap, length(dz_ese), 100*ese_in_cmap/length(dz_ese),
            ese_in_tahoe, length(dz_ese), 100*ese_in_tahoe/length(dz_ese)))
cat(sprintf("  %-15s CMAP: %4d/%4d (%.1f%%)  TAHOE: %4d/%4d (%.1f%%)\n", 
            "MSE", mse_in_cmap, length(dz_mse), 100*mse_in_cmap/length(dz_mse),
            mse_in_tahoe, length(dz_mse), 100*mse_in_tahoe/length(dz_mse)))

# CMAP vs TAHOE gene overlap
cmap_tahoe_overlap <- sum(cmap_genes %in% tahoe_genes)
cmap_only <- sum(!cmap_genes %in% tahoe_genes)
tahoe_only <- sum(!tahoe_genes %in% cmap_genes)

cat("\nCMAP vs TAHOE Gene Database Overlap:\n")
cat("  Genes in CMAP:", length(cmap_genes), "\n")
cat("  Genes in TAHOE:", length(tahoe_genes), "\n")
cat("  Overlap:", cmap_tahoe_overlap, "\n")
cat("  CMAP only:", cmap_only, "\n")
cat("  TAHOE only:", tahoe_only, "\n")

# ============================================================================
# Create Bar Plot Comparison
# ============================================================================

# Create data frame for plotting
coverage_data <- data.frame(
  Signature = rep(c("Unstratified", "Stage I/II", "Stage III/IV", "PE", "ESE", "MSE"), 2),
  Database = rep(c("CMap", "Tahoe-100M"), each = 6),
  TotalGenes = rep(c(length(dz_unstrat), length(dz_inii), length(dz_iiiniv), 
                     length(dz_pe), length(dz_ese), length(dz_mse)), 2),
  CoveredGenes = c(unstrat_in_cmap, inii_in_cmap, iiiniv_in_cmap, 
                   pe_in_cmap, ese_in_cmap, mse_in_cmap,
                   unstrat_in_tahoe, inii_in_tahoe, iiiniv_in_tahoe, 
                   pe_in_tahoe, ese_in_tahoe, mse_in_tahoe)
)

coverage_data$Coverage <- 100 * coverage_data$CoveredGenes / coverage_data$TotalGenes
coverage_data$Signature <- factor(coverage_data$Signature, 
                                   levels = c("Unstratified", "Stage I/II", "Stage III/IV", "PE", "ESE", "MSE"))

# Bar plot
p1 <- ggplot(coverage_data, aes(x = Signature, y = Coverage, fill = Database)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  geom_text(aes(label = sprintf("%d", CoveredGenes)), 
            position = position_dodge(width = 0.7), vjust = -0.3, size = 3) +
  scale_fill_manual(values = c("CMap" = "#4169E1", "Tahoe-100M" = "#DC143C")) +
  labs(title = "Disease Signature Gene Coverage\nin CMap vs Tahoe-100M",
       x = "Endometriosis Signature",
       y = "Gene Coverage (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top"
  ) +
  ylim(0, 110)

ggsave("scripts/results/gene_coverage_comparison.pdf", p1, width = 10, height = 6)
ggsave("scripts/results/gene_coverage_comparison.jpg", p1, width = 10, height = 6, dpi = 300)

cat("\n✓ Saved: scripts/results/gene_coverage_comparison.pdf\n")
cat("✓ Saved: scripts/results/gene_coverage_comparison.jpg\n")

# ============================================================================
# Create Venn Diagram for CMAP vs TAHOE genes
# ============================================================================

set.seed(42)

# Create lists for Euler diagram
gene_sets <- list(
  CMap = cmap_genes,
  `Tahoe-100M` = tahoe_genes
)

# Calculate Euler fit
euler_fit <- euler(gene_sets)

# PDF output
pdf("scripts/results/gene_overlap_cmap_tahoe_venn.pdf", width = 8, height = 8)

plot(euler_fit, 
     quantities = list(type = c("counts", "percent"), fontsize = 12),
     fills = list(fill = c("#4169E1", "#DC143C"), alpha = 0.6),
     labels = list(fontsize = 14),
     main = list(label = "Gene Coverage: CMap vs Tahoe-100M", fontsize = 16, fontface = "bold"))

dev.off()

# JPG output
jpeg("scripts/results/gene_overlap_cmap_tahoe_venn.jpg", width = 8, height = 8, units = "in", res = 300)

plot(euler_fit, 
     quantities = list(type = c("counts", "percent"), fontsize = 12),
     fills = list(fill = c("#4169E1", "#DC143C"), alpha = 0.6),
     labels = list(fontsize = 14),
     main = list(label = "Gene Coverage: CMap vs Tahoe-100M", fontsize = 16, fontface = "bold"))

dev.off()

cat("✓ Saved: scripts/results/gene_overlap_cmap_tahoe_venn.pdf\n")
cat("✓ Saved: scripts/results/gene_overlap_cmap_tahoe_venn.jpg\n")

# ============================================================================
# Create Disease Signature Venn Diagrams (6 signatures)
# ============================================================================

cat("\nCreating disease signature overlap diagrams...\n")

# Prepare gene lists for all 6 disease signatures
sig_sets <- list(
  Unstratified = dz_unstrat,
  `Stage I/II` = dz_inii,
  `Stage III/IV` = dz_iiiniv,
  PE = dz_pe,
  ESE = dz_ese,
  MSE = dz_mse
)

# Create UpSet-style bar plot for disease signatures
all_genes <- unique(c(dz_unstrat, dz_inii, dz_iiiniv, dz_pe, dz_ese, dz_mse))
gene_presence <- data.frame(
  Gene = all_genes,
  Unstratified = all_genes %in% dz_unstrat,
  Stage_I_II = all_genes %in% dz_inii,
  Stage_III_IV = all_genes %in% dz_iiiniv,
  PE = all_genes %in% dz_pe,
  ESE = all_genes %in% dz_ese,
  MSE = all_genes %in% dz_mse
)
gene_presence$Count <- rowSums(gene_presence[, -1])

# Count genes by frequency
freq_table <- as.data.frame(table(gene_presence$Count))
colnames(freq_table) <- c("Signatures", "Genes")
freq_table$Signatures <- as.numeric(as.character(freq_table$Signatures))

p2 <- ggplot(freq_table, aes(x = factor(Signatures), y = Genes, fill = factor(Signatures))) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = Genes), vjust = -0.3, size = 4) +
  scale_fill_brewer(palette = "RdYlBu", direction = -1) +
  labs(title = "Gene Overlap Across 6 Endometriosis Signatures",
       x = "Number of Signatures Containing Gene",
       y = "Number of Genes") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    legend.position = "none"
  ) +
  ylim(0, max(freq_table$Genes) * 1.1)

ggsave("scripts/results/gene_overlap_disease_signatures.pdf", p2, width = 8, height = 6)
ggsave("scripts/results/gene_overlap_disease_signatures.jpg", p2, width = 8, height = 6, dpi = 300)

cat("✓ Saved: scripts/results/gene_overlap_disease_signatures.pdf\n")
cat("✓ Saved: scripts/results/gene_overlap_disease_signatures.jpg\n")

# ============================================================================
# Summary Statistics
# ============================================================================

shared_all_6 <- sum(gene_presence$Count == 6)
cat("\n=== Summary ===\n")
cat("Total unique genes across all signatures:", length(all_genes), "\n")
cat("Genes shared by ALL 6 signatures:", shared_all_6, "\n")
cat("Genes in only 1 signature:", sum(gene_presence$Count == 1), "\n")

cat("\n=======================================================\n")
cat("GENE OVERLAP VISUALIZATION COMPLETE\n")
cat("=======================================================\n")
cat("\nOutput files in: scripts/results/\n")
cat("  - gene_coverage_comparison.pdf/jpg\n")
cat("  - gene_overlap_cmap_tahoe_venn.pdf/jpg\n")
cat("  - gene_overlap_disease_signatures.pdf/jpg\n")
