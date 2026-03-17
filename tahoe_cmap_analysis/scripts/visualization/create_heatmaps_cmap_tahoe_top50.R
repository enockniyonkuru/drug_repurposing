#!/usr/bin/env Rscript

# This script creates heatmaps for CMAP v4 and TAHOE v5 results - TOP 50
# Replicating the style of heatmaps_by_signature_top20_replicated.pdf

library(pheatmap)
library(gplots)
library(ggplot2)
library(RColorBrewer)
library(reshape2)
library(tidyverse)
library(dplyr)

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

# ============================================================================
# CMAP v4 HEATMAP - TOP 50
# ============================================================================

cat("\n========================================\n")
cat("Creating CMAP v4 Heatmap (Top 50)\n")
cat("========================================\n")

# Load CMAP v4 hits files
cmap_base <- "scripts/results/endo_v4_cmap"

ESE_cmap <- read.csv(file.path(cmap_base, "endo_v4_ESE", "endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv"))
IIInIV_cmap <- read.csv(file.path(cmap_base, "endo_v4_IIInIV", "endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv"))
InII_cmap <- read.csv(file.path(cmap_base, "endo_v4_InII", "endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv"))
MSE_cmap <- read.csv(file.path(cmap_base, "endo_v4_MSE", "endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv"))
PE_cmap <- read.csv(file.path(cmap_base, "endo_v4_PE", "endomentriosis_pe_disease_signature_hits_logFC_1.1_q<0.00.csv"))
unstratified_cmap <- read.csv(file.path(cmap_base, "endo_v4_Unstratified", "endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv"))

cat("Loaded CMAP data:\n")
cat("  ESE:", nrow(ESE_cmap), "hits\n")
cat("  IIInIV:", nrow(IIInIV_cmap), "hits\n")
cat("  InII:", nrow(InII_cmap), "hits\n")
cat("  MSE:", nrow(MSE_cmap), "hits\n")
cat("  PE:", nrow(PE_cmap), "hits\n")
cat("  Unstratified:", nrow(unstratified_cmap), "hits\n")

# Extract name and cmap_score columns
unstratified_cmap <- dplyr::select(unstratified_cmap, name, cmap_score)
InII_cmap <- dplyr::select(InII_cmap, name, cmap_score)
IIInIV_cmap <- dplyr::select(IIInIV_cmap, name, cmap_score)
PE_cmap <- dplyr::select(PE_cmap, name, cmap_score)
ESE_cmap <- dplyr::select(ESE_cmap, name, cmap_score)
MSE_cmap <- dplyr::select(MSE_cmap, name, cmap_score)

# Sort by cmap_score (most negative first) and get top 50 from unstratified
unstratified_cmap <- unstratified_cmap[order(unstratified_cmap$cmap_score),]
unstratified_cmap <- unstratified_cmap[1:50,]

# Filter other signatures to only include the top 50 drugs from unstratified
InII_cmap_filt <- InII_cmap[InII_cmap$name %in% unstratified_cmap$name,]
IIInIV_cmap_filt <- IIInIV_cmap[IIInIV_cmap$name %in% unstratified_cmap$name,]
PE_cmap_filt <- PE_cmap[PE_cmap$name %in% unstratified_cmap$name,]
ESE_cmap_filt <- ESE_cmap[ESE_cmap$name %in% unstratified_cmap$name,]
MSE_cmap_filt <- MSE_cmap[MSE_cmap$name %in% unstratified_cmap$name,]

# Rename cmap_score columns to signature names
colnames(unstratified_cmap)[2] <- "Unstratified"
colnames(InII_cmap_filt)[2] <- "InII"
colnames(IIInIV_cmap_filt)[2] <- "IIInIV"
colnames(PE_cmap_filt)[2] <- "PE"
colnames(ESE_cmap_filt)[2] <- "ESE"
colnames(MSE_cmap_filt)[2] <- "MSE"

# Combine all signatures into one dataframe
colname_cmap <- list(unstratified_cmap, InII_cmap_filt, IIInIV_cmap_filt, PE_cmap_filt, ESE_cmap_filt, MSE_cmap_filt)
df_cmap <- Reduce(function(x,y) merge(x = x, y = y, by = "name", all.x = TRUE), 
                  colname_cmap)

# Convert to matrix
row.names(df_cmap) <- df_cmap$name
df_cmap <- df_cmap[,2:7]
df_cmap[is.na(df_cmap)] <- 0

# Rescale scores to 0-100 range (negative scores = greater reversal effect)
rescale <- function(x) {
  if (max(x) == min(x)) return(rep(50, length(x)))
  -(x - max(x)) / (max(x) - min(x)) * 100
}
dfr_cmap <- as.data.frame(apply(df_cmap, 2, rescale))
row.names(dfr_cmap) <- row.names(df_cmap)

# Sort by unstratified signature (descending)
dfr_cmap <- dfr_cmap[order(-dfr_cmap$Unstratified),]

# Save rescaled data
write.csv(dfr_cmap, "scripts/results/cmap_v4_top50_heatmap_data.csv")

# Convert to matrix
matrix_cmap <- data.matrix(dfr_cmap)

# Create color palette
my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

# Define overlapping drugs (appear in both CMAP and TAHOE top 50)
overlap_drugs_cmap <- c("irinotecan", "terfenadine")

# Create row side colors to highlight overlapping drugs
row_colors_cmap <- ifelse(tolower(row.names(matrix_cmap)) %in% overlap_drugs_cmap, "#FF6B6B", "white")

# Modify row labels to add marker for overlapping drugs
row_labels_cmap <- row.names(matrix_cmap)
row_labels_cmap <- ifelse(tolower(row_labels_cmap) %in% overlap_drugs_cmap, 
                          paste0(">>> ", row_labels_cmap, " <<<"), row_labels_cmap)

# Generate CMAP PDF heatmap - adjusted height for 50 drugs
pdf("scripts/results/heatmap_cmap_v4_top50.pdf", width = 10, height = 15)

# Add outer margin for title
par(oma = c(0, 0, 2.5, 0))

heatmap.2(matrix_cmap,
          main = "",
          labRow = row_labels_cmap,
          
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(6,18),
          col = my_palette,
          dendrogram="none",
          cexRow = 0.8,
          cexCol = 1.4,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1,5,0.8),
          lwid = c(1.5,3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 0,
          adjCol = 0.5,
          key.title=NA,
          key.xlab="",
          keysize=0.15,
          key.xtickfun=function() {
            trace="none"
            cex <- par("cex")*par("cex.axis")
            line <- 0
            col <- par("col.axis")
            font <- par("font.axis")
            mtext("No Reversal\n Effect", 
                  side=1, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=1)
            mtext("Maximum Reversal\n Effect", 
                  side=3, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=-0.1)
            return(list(labels=FALSE, tick=FALSE))
          }
)

# Add title in outer margin - centered across full page
mtext("CMap: Reversal Scores for Top 50 Drug Candidates\nAcross All Endometriosis Signatures", 
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)

dev.off()

# Generate CMAP JPG heatmap
jpeg("scripts/results/heatmap_cmap_v4_top50.jpg", width = 10, height = 15, units = "in", res = 300, quality = 100)

par(oma = c(0, 0, 2.5, 0))

heatmap.2(matrix_cmap,
          main = "",
          labRow = row_labels_cmap,
          
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(6,18),
          col = my_palette,
          dendrogram="none",
          cexRow = 0.8,
          cexCol = 1.4,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1,5,0.8),
          lwid = c(1.5,3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 0,
          adjCol = 0.5,
          key.title=NA,
          key.xlab="",
          keysize=0.15,
          key.xtickfun=function() {
            trace="none"
            cex <- par("cex")*par("cex.axis")
            line <- 0
            col <- par("col.axis")
            font <- par("font.axis")
            mtext("No Reversal\n Effect", 
                  side=1, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=1)
            mtext("Maximum Reversal\n Effect", 
                  side=3, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=-0.1)
            return(list(labels=FALSE, tick=FALSE))
          }
)

mtext("CMap: Reversal Scores for Top 50 Drug Candidates\nAcross All Endometriosis Signatures", 
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)

dev.off()

cat("✓ CMAP v4 heatmap (Top 50) saved to: scripts/results/heatmap_cmap_v4_top50.pdf\n")
cat("✓ CMAP v4 heatmap (Top 50) saved to: scripts/results/heatmap_cmap_v4_top50.jpg\n")
cat("✓ CMAP v4 data saved to: scripts/results/cmap_v4_top50_heatmap_data.csv\n")

# Print top 50 drugs
cat("\nTop 50 drugs (CMAP v4):\n")
print(row.names(dfr_cmap))


# ============================================================================
# TAHOE v5 HEATMAP - TOP 50 (or all available if less than 50)
# ============================================================================

cat("\n========================================\n")
cat("Creating TAHOE v5 Heatmap (Top 50)\n")
cat("========================================\n")

# Load TAHOE v5 hits files
tahoe_base <- "scripts/results/endo_v5_tahoe"

ESE_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_ESE", "endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv"))
IIInIV_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_IIInIV", "endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv"))
InII_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_InII", "endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv"))
MSE_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_MSE", "endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv"))
PE_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_PE", "endomentriosis_pe_disease_signature_hits_logFC_1.1_q<0.00.csv"))
unstratified_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_Unstratified", "endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv"))

cat("Loaded TAHOE data:\n")
cat("  ESE:", nrow(ESE_tahoe), "hits\n")
cat("  IIInIV:", nrow(IIInIV_tahoe), "hits\n")
cat("  InII:", nrow(InII_tahoe), "hits\n")
cat("  MSE:", nrow(MSE_tahoe), "hits\n")
cat("  PE:", nrow(PE_tahoe), "hits\n")
cat("  Unstratified:", nrow(unstratified_tahoe), "hits\n")

# Extract name and cmap_score columns
unstratified_tahoe <- dplyr::select(unstratified_tahoe, name, cmap_score)
InII_tahoe <- dplyr::select(InII_tahoe, name, cmap_score)
IIInIV_tahoe <- dplyr::select(IIInIV_tahoe, name, cmap_score)
PE_tahoe <- dplyr::select(PE_tahoe, name, cmap_score)
ESE_tahoe <- dplyr::select(ESE_tahoe, name, cmap_score)
MSE_tahoe <- dplyr::select(MSE_tahoe, name, cmap_score)

# Sort by cmap_score (most negative first) and get top 50 from unstratified
unstratified_tahoe <- unstratified_tahoe[order(unstratified_tahoe$cmap_score),]
n_drugs <- min(50, nrow(unstratified_tahoe))
unstratified_tahoe <- unstratified_tahoe[1:n_drugs,]

cat("\nTop drugs from Unstratified TAHOE:", n_drugs, "(requested 50)\n")

# Filter other signatures to only include the top drugs from unstratified
InII_tahoe_filt <- InII_tahoe[InII_tahoe$name %in% unstratified_tahoe$name,]
IIInIV_tahoe_filt <- IIInIV_tahoe[IIInIV_tahoe$name %in% unstratified_tahoe$name,]
PE_tahoe_filt <- PE_tahoe[PE_tahoe$name %in% unstratified_tahoe$name,]
ESE_tahoe_filt <- ESE_tahoe[ESE_tahoe$name %in% unstratified_tahoe$name,]
MSE_tahoe_filt <- MSE_tahoe[MSE_tahoe$name %in% unstratified_tahoe$name,]

# Rename cmap_score columns to signature names
colnames(unstratified_tahoe)[2] <- "Unstratified"
colnames(InII_tahoe_filt)[2] <- "InII"
colnames(IIInIV_tahoe_filt)[2] <- "IIInIV"
colnames(PE_tahoe_filt)[2] <- "PE"
colnames(ESE_tahoe_filt)[2] <- "ESE"
colnames(MSE_tahoe_filt)[2] <- "MSE"

# Combine all signatures into one dataframe
colname_tahoe <- list(unstratified_tahoe, InII_tahoe_filt, IIInIV_tahoe_filt, PE_tahoe_filt, ESE_tahoe_filt, MSE_tahoe_filt)
df_tahoe <- Reduce(function(x,y) merge(x = x, y = y, by = "name", all.x = TRUE), 
                   colname_tahoe)

# Convert to matrix
row.names(df_tahoe) <- df_tahoe$name
df_tahoe <- df_tahoe[,2:7]
df_tahoe[is.na(df_tahoe)] <- 0

# Rescale scores to 0-100 range
dfr_tahoe <- as.data.frame(apply(df_tahoe, 2, rescale))
row.names(dfr_tahoe) <- row.names(df_tahoe)

# Sort by unstratified signature (descending)
dfr_tahoe <- dfr_tahoe[order(-dfr_tahoe$Unstratified),]

# Save rescaled data
write.csv(dfr_tahoe, "scripts/results/tahoe_v5_top50_heatmap_data.csv")

# Convert to matrix
matrix_tahoe <- data.matrix(dfr_tahoe)

# Calculate height based on number of drugs
height_tahoe <- max(8, n_drugs * 0.30)

# Define overlapping drugs (appear in both CMAP and TAHOE top 50)
overlap_drugs_tahoe <- c("irinotecan", "terfenadine")

# Create row side colors to highlight overlapping drugs (match partial names)
row_colors_tahoe <- ifelse(grepl("irinotecan|terfenadine", tolower(row.names(matrix_tahoe))), "#FF6B6B", "white")

# Modify row labels to add marker for overlapping drugs
row_labels_tahoe <- row.names(matrix_tahoe)
row_labels_tahoe <- ifelse(grepl("irinotecan|terfenadine", tolower(row_labels_tahoe)), 
                           paste0(">>> ", row_labels_tahoe, " <<<"), row_labels_tahoe)

# Generate TAHOE PDF heatmap
pdf("scripts/results/heatmap_tahoe_v5_top50.pdf", width = 10, height = height_tahoe)

# Add outer margin for title
par(oma = c(0, 0, 2.5, 0))

heatmap.2(matrix_tahoe,
          main = "",
          labRow = row_labels_tahoe,
          
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(6,22),
          col = my_palette,
          dendrogram="none",
          cexRow = 0.8,
          cexCol = 1.4,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1,5,0.8),
          lwid = c(1.5,3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 0,
          adjCol = 0.5,
          key.title=NA,
          key.xlab="",
          keysize=0.15,
          key.xtickfun=function() {
            trace="none"
            cex <- par("cex")*par("cex.axis")
            line <- 0
            col <- par("col.axis")
            font <- par("font.axis")
            mtext("No Reversal\n Effect", 
                  side=1, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=1)
            mtext("Maximum Reversal\n Effect", 
                  side=3, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=-0.1)
            return(list(labels=FALSE, tick=FALSE))
          }
)

# Add title in outer margin - centered across full page
mtext(paste0("Tahoe-100M: Reversal Scores for Top ", n_drugs, " Drug Candidates\nAcross All Endometriosis Signatures"), 
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)

dev.off()

# Generate TAHOE JPG heatmap
jpeg("scripts/results/heatmap_tahoe_v5_top50.jpg", width = 10, height = height_tahoe, units = "in", res = 300, quality = 100)

par(oma = c(0, 0, 2.5, 0))

heatmap.2(matrix_tahoe,
          main = "",
          labRow = row_labels_tahoe,
          
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(6,22),
          col = my_palette,
          dendrogram="none",
          cexRow = 0.8,
          cexCol = 1.4,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1,5,0.8),
          lwid = c(1.5,3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 0,
          adjCol = 0.5,
          key.title=NA,
          key.xlab="",
          keysize=0.15,
          key.xtickfun=function() {
            trace="none"
            cex <- par("cex")*par("cex.axis")
            line <- 0
            col <- par("col.axis")
            font <- par("font.axis")
            mtext("No Reversal\n Effect", 
                  side=1, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=1)
            mtext("Maximum Reversal\n Effect", 
                  side=3, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=-0.1)
            return(list(labels=FALSE, tick=FALSE))
          }
)

mtext(paste0("Tahoe-100M: Reversal Scores for Top ", n_drugs, " Drug Candidates\nAcross All Endometriosis Signatures"), 
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)

dev.off()

cat("✓ TAHOE v5 heatmap (Top", n_drugs, ") saved to: scripts/results/heatmap_tahoe_v5_top50.pdf\n")
cat("✓ TAHOE v5 heatmap (Top", n_drugs, ") saved to: scripts/results/heatmap_tahoe_v5_top50.jpg\n")
cat("✓ TAHOE v5 data saved to: scripts/results/tahoe_v5_top50_heatmap_data.csv\n")

# Print top drugs
cat("\nTop", n_drugs, "drugs (TAHOE v5):\n")
print(row.names(dfr_tahoe))


# ============================================================================
# SUMMARY COMPARISON
# ============================================================================

cat("\n========================================\n")
cat("COMPARISON SUMMARY (Top 50)\n")
cat("========================================\n")

cmap_drugs <- row.names(dfr_cmap)
tahoe_drugs <- row.names(dfr_tahoe)

# Normalize drug names for comparison
normalize_name <- function(x) {
  x <- tolower(x)
  x <- gsub(" \\(.*\\)", "", x)  # Remove parenthetical suffixes
  x <- gsub(" hydrochloride| sodium| calcium| maleate| dihydrochloride", "", x)
  trimws(x)
}

cmap_norm <- sapply(cmap_drugs, normalize_name)
tahoe_norm <- sapply(tahoe_drugs, normalize_name)

overlap_norm <- intersect(cmap_norm, tahoe_norm)

cat("\nCMAP v4 Top 50 drugs:", length(cmap_drugs), "\n")
cat("TAHOE v5 Top drugs:", length(tahoe_drugs), "\n")
cat("Overlapping drugs (normalized):", length(overlap_norm), "\n")

if (length(overlap_norm) > 0) {
  cat("\nOverlapping drugs:\n")
  for (norm_name in overlap_norm) {
    cmap_name <- cmap_drugs[cmap_norm == norm_name]
    tahoe_name <- tahoe_drugs[tahoe_norm == norm_name]
    cat("  -", cmap_name, "(CMAP) /", tahoe_name, "(TAHOE)\n")
  }
}

cat("\n✓ Analysis complete!\n")
