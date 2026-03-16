#!/usr/bin/env Rscript

# This script creates a side-by-side comparison of top 20 heatmaps
# Tomiko e2e_rawdata vs DRpipe endo_v2

library(gplots)
library(dplyr)

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("Loading data from both pipelines...\n\n")

# ============================================================================
# LOAD TOMIKO DATA
# ============================================================================
cat("Loading Tomiko e2e_rawdata...\n")

tomiko_InII <- read.csv("endo_tomiko_code/replication/e2e_rawdata/InII/drug_instances_InII.csv")
tomiko_IIInIV <- read.csv("endo_tomiko_code/replication/e2e_rawdata/IIInIV/drug_instances_IIInIV.csv")
tomiko_PE <- read.csv("endo_tomiko_code/replication/e2e_rawdata/PE/drug_instances_PE.csv")
tomiko_ESE <- read.csv("endo_tomiko_code/replication/e2e_rawdata/ESE/drug_instances_ESE.csv")
tomiko_MSE <- read.csv("endo_tomiko_code/replication/e2e_rawdata/MSE/drug_instances_MSE.csv")
tomiko_unstratified <- read.csv("endo_tomiko_code/replication/e2e_rawdata/Unstratified/drug_instances_Unstratified.csv")

# Extract and prepare Tomiko data
tomiko_unstratified <- dplyr::select(tomiko_unstratified, name, cmap_score)[1:20,]
tomiko_InII <- dplyr::select(tomiko_InII, name, cmap_score)
tomiko_IIInIV <- dplyr::select(tomiko_IIInIV, name, cmap_score)
tomiko_PE <- dplyr::select(tomiko_PE, name, cmap_score)
tomiko_ESE <- dplyr::select(tomiko_ESE, name, cmap_score)
tomiko_MSE <- dplyr::select(tomiko_MSE, name, cmap_score)

# Filter to top 20
tomiko_InII <- tomiko_InII[tomiko_InII$name %in% tomiko_unstratified$name,]
tomiko_IIInIV <- tomiko_IIInIV[tomiko_IIInIV$name %in% tomiko_unstratified$name,]
tomiko_PE <- tomiko_PE[tomiko_PE$name %in% tomiko_unstratified$name,]
tomiko_ESE <- tomiko_ESE[tomiko_ESE$name %in% tomiko_unstratified$name,]
tomiko_MSE <- tomiko_MSE[tomiko_MSE$name %in% tomiko_unstratified$name,]

colnames(tomiko_unstratified)[2] <- "unstratified"
colnames(tomiko_InII)[2] <- "InII"
colnames(tomiko_IIInIV)[2] <- "IIInIV"
colnames(tomiko_PE)[2] <- "PE"
colnames(tomiko_ESE)[2] <- "ESE"
colnames(tomiko_MSE)[2] <- "MSE"

tomiko_list <- list(tomiko_unstratified, tomiko_InII, tomiko_IIInIV, tomiko_PE, tomiko_ESE, tomiko_MSE)
tomiko_df <- Reduce(function(x,y) merge(x = x, y = y, by = "name", all.x = TRUE), tomiko_list)
row.names(tomiko_df) <- tomiko_df$name
tomiko_df <- tomiko_df[,2:7]
tomiko_df[is.na(tomiko_df)] <- 0

rescale <- function(x) -(x - max(x)) / (max(x) - min(x)) * 100
tomiko_dfr <- as.data.frame(apply(tomiko_df, 2, rescale))
row.names(tomiko_dfr) <- row.names(tomiko_df)
tomiko_dfr <- tomiko_dfr[order(-tomiko_dfr$unstratified),]
tomiko_matrix <- data.matrix(tomiko_dfr)

cat("  ✓ Tomiko top 20:", paste(row.names(tomiko_dfr)[1:5], collapse=", "), "...\n")

# ============================================================================
# LOAD DRPIPE DATA
# ============================================================================
cat("Loading DRpipe endo_v2...\n")

drpipe_InII <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_INII_Strict_20260121-161312/endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv")
drpipe_IIInIV <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_IIINIV_Strict_20260121-162222/endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv")
drpipe_PE <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_PE_Strict_20260121-163720/endomentriosis_pe_disease_signature_hits_logFC_1_q<0.00.csv")
drpipe_ESE <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_ESE_Strict_20260121-160656/endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv")
drpipe_MSE <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_MSE_Strict_20260121-162955/endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv")
drpipe_unstratified <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_Unstratified_Strict_20260121-164307/endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv")

# Sort by cmap_score
drpipe_unstratified <- drpipe_unstratified[order(drpipe_unstratified$cmap_score), ]
drpipe_InII <- drpipe_InII[order(drpipe_InII$cmap_score), ]
drpipe_IIInIV <- drpipe_IIInIV[order(drpipe_IIInIV$cmap_score), ]
drpipe_PE <- drpipe_PE[order(drpipe_PE$cmap_score), ]
drpipe_ESE <- drpipe_ESE[order(drpipe_ESE$cmap_score), ]
drpipe_MSE <- drpipe_MSE[order(drpipe_MSE$cmap_score), ]

# Extract and prepare DRpipe data
drpipe_unstratified <- dplyr::select(drpipe_unstratified, name, cmap_score)[1:20,]
drpipe_InII <- dplyr::select(drpipe_InII, name, cmap_score)
drpipe_IIInIV <- dplyr::select(drpipe_IIInIV, name, cmap_score)
drpipe_PE <- dplyr::select(drpipe_PE, name, cmap_score)
drpipe_ESE <- dplyr::select(drpipe_ESE, name, cmap_score)
drpipe_MSE <- dplyr::select(drpipe_MSE, name, cmap_score)

# Filter to top 20
drpipe_InII <- drpipe_InII[drpipe_InII$name %in% drpipe_unstratified$name,]
drpipe_IIInIV <- drpipe_IIInIV[drpipe_IIInIV$name %in% drpipe_unstratified$name,]
drpipe_PE <- drpipe_PE[drpipe_PE$name %in% drpipe_unstratified$name,]
drpipe_ESE <- drpipe_ESE[drpipe_ESE$name %in% drpipe_unstratified$name,]
drpipe_MSE <- drpipe_MSE[drpipe_MSE$name %in% drpipe_unstratified$name,]

colnames(drpipe_unstratified)[2] <- "unstratified"
colnames(drpipe_InII)[2] <- "InII"
colnames(drpipe_IIInIV)[2] <- "IIInIV"
colnames(drpipe_PE)[2] <- "PE"
colnames(drpipe_ESE)[2] <- "ESE"
colnames(drpipe_MSE)[2] <- "MSE"

drpipe_list <- list(drpipe_unstratified, drpipe_InII, drpipe_IIInIV, drpipe_PE, drpipe_ESE, drpipe_MSE)
drpipe_df <- Reduce(function(x,y) merge(x = x, y = y, by = "name", all.x = TRUE), drpipe_list)
row.names(drpipe_df) <- drpipe_df$name
drpipe_df <- drpipe_df[,2:7]
drpipe_df[is.na(drpipe_df)] <- 0

drpipe_dfr <- as.data.frame(apply(drpipe_df, 2, rescale))
row.names(drpipe_dfr) <- row.names(drpipe_df)
drpipe_dfr <- drpipe_dfr[order(-drpipe_dfr$unstratified),]
drpipe_matrix <- data.matrix(drpipe_dfr)

cat("  ✓ DRpipe top 20:", paste(row.names(drpipe_dfr)[1:5], collapse=", "), "...\n\n")

# ============================================================================
# CREATE COMBINED PDF
# ============================================================================
cat("Creating combined heatmap PDF...\n")

my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

pdf("endo_tomiko_code/replication/e2e_rawdata/heatmaps_comparison_tomiko_vs_drpipe.pdf", 
    width = 16, height = 8)

par(mfrow = c(1, 2), mar = c(5, 10, 4, 2))

# Tomiko heatmap
heatmap.2(tomiko_matrix,
          main = "TOMIKO Pipeline\nTop 20 Drug Candidates",
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(5, 12),
          col = my_palette,
          dendrogram="none",
          cexRow = 1.0,
          cexCol = 1.0,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1.5, 4, 0.8),
          lwid = c(1, 3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 45,
          adjCol = c(1, 0.5),
          key.title=NA,
          key.xlab="Reversal Score",
          keysize=1
)

# DRpipe heatmap
heatmap.2(drpipe_matrix,
          main = "DRPIPE Pipeline\nTop 20 Drug Candidates",
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(5, 12),
          col = my_palette,
          dendrogram="none",
          cexRow = 1.0,
          cexCol = 1.0,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1.5, 4, 0.8),
          lwid = c(1, 3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 45,
          adjCol = c(1, 0.5),
          key.title=NA,
          key.xlab="Reversal Score",
          keysize=1
)

dev.off()

# ============================================================================
# SUMMARY
# ============================================================================
cat("\n════════════════════════════════════════════════════════════════\n")
cat("TOP 20 COMPARISON\n")
cat("════════════════════════════════════════════════════════════════\n\n")

tomiko_top20 <- row.names(tomiko_dfr)
drpipe_top20 <- row.names(drpipe_dfr)
common <- intersect(tomiko_top20, drpipe_top20)

cat("Tomiko Top 20:\n")
for (i in 1:20) {
  marker <- if (tomiko_top20[i] %in% drpipe_top20) "✓" else " "
  cat(sprintf("  %2d. %s %s\n", i, marker, tomiko_top20[i]))
}

cat("\nDRpipe Top 20:\n")
for (i in 1:20) {
  marker <- if (drpipe_top20[i] %in% tomiko_top20) "✓" else " "
  cat(sprintf("  %2d. %s %s\n", i, marker, drpipe_top20[i]))
}

cat("\n════════════════════════════════════════════════════════════════\n")
cat("Common drugs:", length(common), "/ 20\n")
cat("Common:", paste(common, collapse = ", "), "\n")
cat("════════════════════════════════════════════════════════════════\n")

cat("\n✓ Combined heatmap saved to: endo_tomiko_code/replication/e2e_rawdata/heatmaps_comparison_tomiko_vs_drpipe.pdf\n\n")
