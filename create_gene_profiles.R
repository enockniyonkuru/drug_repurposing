# ============================================================================
# Create Gene Profile Heatmaps for Fenoprofen and Pentoxifylline
# Comparing CMAP v4 and TAHOE v5 drug signatures with disease signatures
# ============================================================================

library(gplots)
library(ggplot2)
library(tidyverse)
library(scales)
library(RColorBrewer)
library(reshape2)

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

# ============================================================================
# Load CMAP and TAHOE data
# ============================================================================

# Load drug signatures
load("scripts/data/drug_signatures/cmap_signatures.RData")
load("scripts/data/drug_signatures/tahoe_signatures.RData")

# Load drug experiments metadata
cmap_experiments <- read.csv("scripts/data/drug_signatures/cmap_drug_experiments_new.csv", stringsAsFactors = FALSE)
tahoe_experiments <- read.csv("scripts/data/drug_signatures/tahoe_drug_experiments_new.csv", stringsAsFactors = FALSE)

# Load disease signatures from results
load("scripts/results/endo_v4_cmap/endo_v4_Unstratified/endomentriosis_unstratified_disease_signature.csv_results.RData")
dz_signature_unstrat <- results$signature_clean
colnames(dz_signature_unstrat)[1:2] <- c("GeneID", "log2FoldChange")

load("scripts/results/endo_v4_cmap/endo_v4_InII/endomentriosis_inii_disease_signature_results.RData")
dz_signature_InII <- results$signature_clean
colnames(dz_signature_InII)[1:2] <- c("GeneID", "log2FoldChange")

load("scripts/results/endo_v4_cmap/endo_v4_IIInIV/endomentriosis_iiiniv_disease_signature_results.RData")
dz_signature_IIInIV <- results$signature_clean
colnames(dz_signature_IIInIV)[1:2] <- c("GeneID", "log2FoldChange")

load("scripts/results/endo_v4_cmap/endo_v4_PE/endomentriosis_pe_disease_signature_results.RData")
dz_signature_PE <- results$signature_clean
colnames(dz_signature_PE)[1:2] <- c("GeneID", "log2FoldChange")

load("scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
dz_signature_ESE <- results$signature_clean
colnames(dz_signature_ESE)[1:2] <- c("GeneID", "log2FoldChange")

load("scripts/results/endo_v4_cmap/endo_v4_MSE/endomentriosis_mse_disease_signature_results.RData")
dz_signature_MSE <- results$signature_clean
colnames(dz_signature_MSE)[1:2] <- c("GeneID", "log2FoldChange")

cat("Loaded disease signatures:\n")
cat("  Unstratified:", nrow(dz_signature_unstrat), "genes\n")
cat("  InII:", nrow(dz_signature_InII), "genes\n")
cat("  IIInIV:", nrow(dz_signature_IIInIV), "genes\n")
cat("  PE:", nrow(dz_signature_PE), "genes\n")
cat("  ESE:", nrow(dz_signature_ESE), "genes\n")
cat("  MSE:", nrow(dz_signature_MSE), "genes\n")

# ============================================================================
# Find shared genes across all 6 signatures
# ============================================================================

# Get gene IDs from each signature
genes_unstrat <- dz_signature_unstrat$GeneID
genes_InII <- dz_signature_InII$GeneID
genes_IIInIV <- dz_signature_IIInIV$GeneID
genes_PE <- dz_signature_PE$GeneID
genes_ESE <- dz_signature_ESE$GeneID
genes_MSE <- dz_signature_MSE$GeneID

# Find genes present in all 6 signatures
all_genes <- c(genes_unstrat, genes_InII, genes_IIInIV, genes_PE, genes_ESE, genes_MSE)
gene_freq <- as.data.frame(table(all_genes))
colnames(gene_freq) <- c("GeneID", "Freq")
shared_genes <- gene_freq[gene_freq$Freq == 6, "GeneID"]

cat("\nShared genes across all 6 signatures:", length(shared_genes), "\n")

# ============================================================================
# Function to create gene profile heatmap
# ============================================================================

create_gene_profile <- function(drug_name, database = "cmap") {
  
  cat("\n========================================\n")
  cat("Creating Gene Profile for:", drug_name, "(", toupper(database), ")\n")
  cat("========================================\n")
  
  if (database == "cmap") {
    signatures <- cmap_signatures
    experiments <- cmap_experiments
    results_base <- "scripts/results/endo_v4_cmap"
    db_label <- "CMap"
  } else {
    signatures <- tahoe_signatures
    experiments <- tahoe_experiments
    results_base <- "scripts/results/endo_v5_tahoe"
    db_label <- "Tahoe-100M"
  }
  
  # Find drug experiment ID
  drug_matches <- experiments[grep(drug_name, tolower(experiments$name), ignore.case = TRUE), ]
  
  if (nrow(drug_matches) == 0) {
    cat("WARNING: Drug", drug_name, "not found in", toupper(database), "\n")
    return(NULL)
  }
  
  cat("Found", nrow(drug_matches), "experiments for", drug_name, "\n")
  
  # Get gene list from signatures
  gene_list <- signatures[, 1]
  
  # Filter shared genes to those in the database
  shared_genes_db <- shared_genes[shared_genes %in% gene_list]
  cat("Shared genes in", toupper(database), ":", length(shared_genes_db), "\n")
  
  if (length(shared_genes_db) < 10) {
    cat("WARNING: Too few shared genes. Skipping.\n")
    return(NULL)
  }
  
  # Get the first drug experiment (or best one)
  drug_exp_id <- drug_matches$id[1]
  cat("Using experiment ID:", drug_exp_id, "\n")
  
  # Get drug signature for this experiment
  # Column index = exp_id + 1 (first column is gene ID)
  if (drug_exp_id + 1 > ncol(signatures)) {
    cat("WARNING: Experiment ID out of range\n")
    return(NULL)
  }
  
  drug_sig <- data.frame(
    GeneID = signatures[, 1],
    drug_rank = signatures[, drug_exp_id + 1]
  )
  colnames(drug_sig)[2] <- drug_name
  
  # Filter to shared genes
  drug_sig_shared <- drug_sig[drug_sig$GeneID %in% shared_genes_db, ]
  
  # Get disease signatures for shared genes
  unstrat_shared <- dz_signature_unstrat[dz_signature_unstrat$GeneID %in% shared_genes_db, c("GeneID", "log2FoldChange")]
  InII_shared <- dz_signature_InII[dz_signature_InII$GeneID %in% shared_genes_db, c("GeneID", "log2FoldChange")]
  IIInIV_shared <- dz_signature_IIInIV[dz_signature_IIInIV$GeneID %in% shared_genes_db, c("GeneID", "log2FoldChange")]
  PE_shared <- dz_signature_PE[dz_signature_PE$GeneID %in% shared_genes_db, c("GeneID", "log2FoldChange")]
  ESE_shared <- dz_signature_ESE[dz_signature_ESE$GeneID %in% shared_genes_db, c("GeneID", "log2FoldChange")]
  MSE_shared <- dz_signature_MSE[dz_signature_MSE$GeneID %in% shared_genes_db, c("GeneID", "log2FoldChange")]
  
  # Rename log2FoldChange columns
  colnames(unstrat_shared)[2] <- "Unstratified"
  colnames(InII_shared)[2] <- "Stage_1_2"
  colnames(IIInIV_shared)[2] <- "Stage_3_4"
  colnames(PE_shared)[2] <- "PE"
  colnames(ESE_shared)[2] <- "ESE"
  colnames(MSE_shared)[2] <- "MSE"
  
  # Merge all signatures
  combined <- drug_sig_shared
  combined <- merge(combined, unstrat_shared, by = "GeneID", all.x = TRUE)
  combined <- merge(combined, InII_shared, by = "GeneID", all.x = TRUE)
  combined <- merge(combined, IIInIV_shared, by = "GeneID", all.x = TRUE)
  combined <- merge(combined, PE_shared, by = "GeneID", all.x = TRUE)
  combined <- merge(combined, ESE_shared, by = "GeneID", all.x = TRUE)
  combined <- merge(combined, MSE_shared, by = "GeneID", all.x = TRUE)
  
  # Remove rows with NA
  combined <- na.omit(combined)
  cat("Final genes in heatmap:", nrow(combined), "\n")
  
  if (nrow(combined) < 10) {
    cat("WARNING: Too few genes after merging. Skipping.\n")
    return(NULL)
  }
  
  # Sort by drug rank (lower rank = more downregulated by drug)
  combined <- combined[order(combined[, 2]), ]
  
  # Set row names
  row.names(combined) <- combined$GeneID
  combined <- combined[, -1]  # Remove GeneID column
  
  # Scale columns for visualization
  combined_scaled <- as.data.frame(scale(combined))
  
  # Create color palette (blue = downregulated, red = upregulated)
  my_palette <- colorRampPalette(c("blue4", "white", "red3"))(n = 100)
  
  # Column labels
  col_labels <- c(paste0(tools::toTitleCase(drug_name), "\n(", db_label, ")"), 
                  "Unstratified", "Stage 1/2", "Stage 3/4", "PE", "ESE", "MSE")
  
  # Create heatmap matrix
  mat <- as.matrix(combined_scaled)
  
  # Generate PDF
  pdf_file <- paste0("scripts/results/gene_profile_", drug_name, "_", database, ".pdf")
  pdf(pdf_file, width = 8, height = 12)
  
  par(oma = c(0, 0, 3, 0))
  
  heatmap.2(mat,
            main = "",
            notecol = "black",
            density.info = "none",
            trace = "none",
            margins = c(8, 8),
            col = my_palette,
            dendrogram = "none",
            cexRow = 0.5,
            cexCol = 1.0,
            labCol = col_labels,
            Colv = FALSE,
            Rowv = FALSE,
            key = TRUE,
            key.title = NA,
            keysize = 1.2,
            srtCol = 45)
  
  mtext(paste0(db_label, ": ", tools::toTitleCase(drug_name), " Gene Expression Profile\nvs. Endometriosis Signatures"),
        outer = TRUE, side = 3, line = 0.5, cex = 1.2, font = 2)
  
  dev.off()
  
  # Generate JPG
  jpg_file <- paste0("scripts/results/gene_profile_", drug_name, "_", database, ".jpg")
  jpeg(jpg_file, width = 8, height = 12, units = "in", res = 300, quality = 100)
  
  par(oma = c(0, 0, 3, 0))
  
  heatmap.2(mat,
            main = "",
            notecol = "black",
            density.info = "none",
            trace = "none",
            margins = c(8, 8),
            col = my_palette,
            dendrogram = "none",
            cexRow = 0.5,
            cexCol = 1.0,
            labCol = col_labels,
            Colv = FALSE,
            Rowv = FALSE,
            key = TRUE,
            key.title = NA,
            keysize = 1.2,
            srtCol = 45)
  
  mtext(paste0(db_label, ": ", tools::toTitleCase(drug_name), " Gene Expression Profile\nvs. Endometriosis Signatures"),
        outer = TRUE, side = 3, line = 0.5, cex = 1.2, font = 2)
  
  dev.off()
  
  cat("✓ Saved:", pdf_file, "\n")
  cat("✓ Saved:", jpg_file, "\n")
  
  return(combined)
}

# ============================================================================
# Create Gene Profiles for Fenoprofen and Pentoxifylline
# ============================================================================

# Fenoprofen - CMAP (top drug in CMAP)
fenoprofen_cmap <- create_gene_profile("fenoprofen", "cmap")

# Fenoprofen - TAHOE (check if exists)
fenoprofen_tahoe <- create_gene_profile("fenoprofen", "tahoe")

# Pentoxifylline - CMAP (check if exists)
pentoxifylline_cmap <- create_gene_profile("pentoxifylline", "cmap")

# Pentoxifylline - TAHOE (top drug in TAHOE)
pentoxifylline_tahoe <- create_gene_profile("pentoxifylline", "tahoe")

cat("\n========================================\n")
cat("GENE PROFILE GENERATION COMPLETE\n")
cat("========================================\n")
