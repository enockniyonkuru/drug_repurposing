# ============================================================================
# Create Gene Profile Heatmaps for Fenoprofen and Pentoxifylline
# Comparing CMAP v4 and TAHOE v5 drug signatures with disease signatures
# ============================================================================

suppressPackageStartupMessages({
  library(gplots)
  library(ggplot2)
  library(tidyverse)
  library(scales)
  library(RColorBrewer)
})

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("=======================================================\n")
cat("Gene Profile Heatmap Generator\n")
cat("=======================================================\n\n")

# ============================================================================
# Load Data
# ============================================================================

cat("Loading CMAP signatures...\n")
load("scripts/data/drug_signatures/cmap_signatures.RData")
cat("  CMAP: ", dim(cmap_signatures)[1], "genes x", dim(cmap_signatures)[2] - 1, "experiments\n")

cat("Loading CMAP experiments metadata...\n")
cmap_experiments <- read.csv("scripts/data/drug_signatures/cmap_drug_experiments_new.csv", stringsAsFactors = FALSE)

cat("Loading TAHOE signatures (this may take a moment)...\n")
load("scripts/data/drug_signatures/tahoe_signatures.RData")
cat("  TAHOE: ", dim(tahoe_signatures)[1], "genes x", dim(tahoe_signatures)[2] - 1, "experiments\n")

cat("Loading TAHOE experiments metadata...\n")
tahoe_experiments <- read.csv("scripts/data/drug_signatures/tahoe_drug_experiments_new.csv", stringsAsFactors = FALSE)

# ============================================================================
# Load Disease Signatures from CMAP v4 Results
# ============================================================================

cat("\nLoading disease signatures (CMAP v4)...\n")

# Unstratified
load("scripts/results/endo_v4_cmap/endo_v4_Unstratified/endomentriosis_unstratified_disease_signature.csv_results.RData")
dz_unstrat <- results$signature_clean
colnames(dz_unstrat)[1:2] <- c("GeneID", "log2FC")

# InII
load("scripts/results/endo_v4_cmap/endo_v4_InII/endomentriosis_inii_disease_signature_results.RData")
dz_inii <- results$signature_clean
colnames(dz_inii)[1:2] <- c("GeneID", "log2FC")

# IIInIV
load("scripts/results/endo_v4_cmap/endo_v4_IIInIV/endomentriosis_iiiniv_disease_signature_results.RData")
dz_iiiniv <- results$signature_clean
colnames(dz_iiiniv)[1:2] <- c("GeneID", "log2FC")

# PE
load("scripts/results/endo_v4_cmap/endo_v4_PE/endomentriosis_pe_disease_signature_results.RData")
dz_pe <- results$signature_clean
colnames(dz_pe)[1:2] <- c("GeneID", "log2FC")

# ESE
load("scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
dz_ese <- results$signature_clean
colnames(dz_ese)[1:2] <- c("GeneID", "log2FC")

# MSE
load("scripts/results/endo_v4_cmap/endo_v4_MSE/endomentriosis_mse_disease_signature_results.RData")
dz_mse <- results$signature_clean
colnames(dz_mse)[1:2] <- c("GeneID", "log2FC")

cat("  Unstratified:", nrow(dz_unstrat), "genes\n")
cat("  Stage I/II:", nrow(dz_inii), "genes\n")
cat("  Stage III/IV:", nrow(dz_iiiniv), "genes\n")
cat("  PE:", nrow(dz_pe), "genes\n")
cat("  ESE:", nrow(dz_ese), "genes\n")
cat("  MSE:", nrow(dz_mse), "genes\n")

# ============================================================================
# Find shared genes across all 6 disease signatures
# ============================================================================

all_dz_genes <- c(dz_unstrat$GeneID, dz_inii$GeneID, dz_iiiniv$GeneID, 
                  dz_pe$GeneID, dz_ese$GeneID, dz_mse$GeneID)
gene_freq <- as.data.frame(table(all_dz_genes))
shared_genes <- as.character(gene_freq[gene_freq$Freq == 6, 1])

cat("\nShared genes across all 6 signatures:", length(shared_genes), "\n")

# ============================================================================
# Function to Create Gene Profile Heatmap
# ============================================================================

create_gene_profile_heatmap <- function(drug_name, database = "cmap") {
  
  cat("\n========================================\n")
  cat("Creating Gene Profile for:", toupper(drug_name), "(", toupper(database), ")\n")
  cat("========================================\n")
  
  # Select database
  if (database == "cmap") {
    signatures <- cmap_signatures
    experiments <- cmap_experiments
    db_label <- "CMap"
    gene_col <- "V1"
  } else {
    signatures <- tahoe_signatures
    experiments <- tahoe_experiments
    db_label <- "Tahoe-100M"
    gene_col <- colnames(tahoe_signatures)[1]
  }
  
  # Find drug in experiments
  drug_idx <- grep(paste0("^", drug_name, "$"), tolower(experiments$name), ignore.case = TRUE)
  
  if (length(drug_idx) == 0) {
    # Try partial match
    drug_idx <- grep(drug_name, experiments$name, ignore.case = TRUE)
  }
  
  if (length(drug_idx) == 0) {
    cat("  WARNING: Drug", drug_name, "not found in", toupper(database), "\n")
    return(NULL)
  }
  
  cat("  Found", length(drug_idx), "experiments for", drug_name, "\n")
  
  # Use first matching experiment
  drug_exp_id <- experiments$id[drug_idx[1]]
  drug_exp_name <- experiments$name[drug_idx[1]]
  cat("  Using experiment ID:", drug_exp_id, "(", drug_exp_name, ")\n")
  
  # Get gene IDs from signatures
  gene_ids <- signatures[, 1]
  
  # Find shared genes that exist in this database
  shared_in_db <- shared_genes[shared_genes %in% gene_ids]
  cat("  Shared genes in", database, ":", length(shared_in_db), "\n")
  
  if (length(shared_in_db) < 10) {
    cat("  WARNING: Too few shared genes. Skipping.\n")
    return(NULL)
  }
  
  # Get drug signature column
  # Column index = exp_id + 1 (first column is gene ID)
  col_idx <- drug_exp_id + 1
  
  if (col_idx > ncol(signatures)) {
    cat("  WARNING: Experiment ID", drug_exp_id, "out of range\n")
    return(NULL)
  }
  
  drug_sig <- data.frame(
    GeneID = gene_ids,
    DrugRank = signatures[, col_idx]
  )
  
  # Filter to shared genes
  drug_sig <- drug_sig[drug_sig$GeneID %in% shared_in_db, ]
  cat("  Drug signature genes:", nrow(drug_sig), "\n")
  
  # Merge with disease signatures
  merged <- drug_sig
  colnames(merged)[2] <- drug_exp_name
  
  # Helper function to add disease signature
  add_dz_sig <- function(merged_df, dz_df, dz_name) {
    dz_subset <- dz_df[dz_df$GeneID %in% shared_in_db, c("GeneID", "log2FC")]
    colnames(dz_subset)[2] <- dz_name
    merge(merged_df, dz_subset, by = "GeneID", all.x = FALSE)
  }
  
  merged <- add_dz_sig(merged, dz_unstrat, "Unstratified")
  merged <- add_dz_sig(merged, dz_inii, "Stage_1_2")
  merged <- add_dz_sig(merged, dz_iiiniv, "Stage_3_4")
  merged <- add_dz_sig(merged, dz_pe, "PE")
  merged <- add_dz_sig(merged, dz_ese, "ESE")
  merged <- add_dz_sig(merged, dz_mse, "MSE")
  
  # Remove NAs
  merged <- na.omit(merged)
  cat("  Final genes after merging:", nrow(merged), "\n")
  
  if (nrow(merged) < 10) {
    cat("  WARNING: Too few genes after merging. Skipping.\n")
    return(NULL)
  }
  
  # Order by drug signature (most downregulated by drug at top)
  merged <- merged[order(merged[, 2], decreasing = FALSE), ]
  
  # Prepare matrix for heatmap
  row_names <- merged$GeneID
  mat <- as.matrix(merged[, -1])
  rownames(mat) <- row_names
  
  # Rename drug column
  colnames(mat)[1] <- tools::toTitleCase(drug_name)
  colnames(mat)[2:7] <- c("Unstratified", "Stage 1/2", "Stage 3/4", "PE", "ESE", "MSE")
  
  # Scale columns
  mat_scaled <- apply(mat, 2, scale)
  rownames(mat_scaled) <- row_names
  
  # Color palette (blue = downregulated, red = upregulated)
  my_palette <- colorRampPalette(c("blue4", "white", "#EE0000"))(n = 100)
  
  # Output paths
  pdf_file <- paste0("scripts/results/gene_profile_", drug_name, "_", database, ".pdf")
  jpg_file <- paste0("scripts/results/gene_profile_", drug_name, "_", database, ".jpg")
  
  # Create PDF
  pdf(pdf_file, width = 9, height = 14)
  
  par(oma = c(0, 0, 3, 0))
  
  heatmap.2(mat_scaled,
            density.info = "none",
            trace = "none",
            margins = c(8, 6),
            col = my_palette,
            dendrogram = "none",
            cexRow = 0.3,
            cexCol = 1.0,
            Colv = FALSE,
            Rowv = FALSE,
            key = TRUE,
            keysize = 1.0,
            key.title = NA,
            key.xlab = "Scaled Expression",
            srtCol = 45)
  
  mtext(paste0(db_label, ": ", tools::toTitleCase(drug_name), " Gene Expression Profile\nvs. Endometriosis Disease Signatures"),
        outer = TRUE, side = 3, line = 0.5, cex = 1.3, font = 2)
  
  dev.off()
  
  # Create JPG
  jpeg(jpg_file, width = 9, height = 14, units = "in", res = 300, quality = 100)
  
  par(oma = c(0, 0, 3, 0))
  
  heatmap.2(mat_scaled,
            density.info = "none",
            trace = "none",
            margins = c(8, 6),
            col = my_palette,
            dendrogram = "none",
            cexRow = 0.3,
            cexCol = 1.0,
            Colv = FALSE,
            Rowv = FALSE,
            key = TRUE,
            keysize = 1.0,
            key.title = NA,
            key.xlab = "Scaled Expression",
            srtCol = 45)
  
  mtext(paste0(db_label, ": ", tools::toTitleCase(drug_name), " Gene Expression Profile\nvs. Endometriosis Disease Signatures"),
        outer = TRUE, side = 3, line = 0.5, cex = 1.3, font = 2)
  
  dev.off()
  
  cat("  ✓ Saved:", pdf_file, "\n")
  cat("  ✓ Saved:", jpg_file, "\n")
  
  return(merged)
}

# ============================================================================
# Check Drug Availability
# ============================================================================

cat("\n=== Checking Drug Availability ===\n")

# Check fenoprofen
cat("\nFenoprofen:\n")
feno_cmap <- grep("fenoprofen", cmap_experiments$name, ignore.case = TRUE)
cat("  CMAP:", length(feno_cmap), "experiments\n")
feno_tahoe <- grep("fenoprofen", tahoe_experiments$name, ignore.case = TRUE)
cat("  TAHOE:", length(feno_tahoe), "experiments\n")

# Check pentoxifylline
cat("\nPentoxifylline:\n")
pento_cmap <- grep("pentoxifylline", cmap_experiments$name, ignore.case = TRUE)
cat("  CMAP:", length(pento_cmap), "experiments\n")
pento_tahoe <- grep("pentoxifylline", tahoe_experiments$name, ignore.case = TRUE)
cat("  TAHOE:", length(pento_tahoe), "experiments\n")

# ============================================================================
# Generate Gene Profile Heatmaps
# ============================================================================

cat("\n=== Generating Gene Profile Heatmaps ===\n")

# Fenoprofen - CMAP
result_feno_cmap <- create_gene_profile_heatmap("fenoprofen", "cmap")

# Fenoprofen - TAHOE
result_feno_tahoe <- create_gene_profile_heatmap("fenoprofen", "tahoe")

# Pentoxifylline - CMAP
result_pento_cmap <- create_gene_profile_heatmap("pentoxifylline", "cmap")

# Pentoxifylline - TAHOE
result_pento_tahoe <- create_gene_profile_heatmap("pentoxifylline", "tahoe")

cat("\n=======================================================\n")
cat("GENE PROFILE GENERATION COMPLETE\n")
cat("=======================================================\n")
cat("\nOutput files in: scripts/results/\n")
cat("  - gene_profile_fenoprofen_cmap.pdf/jpg\n")
cat("  - gene_profile_fenoprofen_tahoe.pdf/jpg (if available)\n")
cat("  - gene_profile_pentoxifylline_cmap.pdf/jpg (if available)\n")
cat("  - gene_profile_pentoxifylline_tahoe.pdf/jpg\n")
