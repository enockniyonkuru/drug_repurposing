#!/usr/bin/env Rscript

# This script creates the heatmaps_by_signature_top20.pdf visualization
# Using DRpipe endo_v2 results

library(pheatmap)
library(gplots)
library(ggplot2)
library(RColorBrewer)
library(reshape2)
library(tidyverse)
library(dplyr)

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("Loading drug instances from DRpipe endo_v2...\n")

# Import the drug instances data from DRpipe endo_v2
InII <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_INII_Strict_20260121-161312/endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv")
IIInIV <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_IIINIV_Strict_20260121-162222/endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv")
PE <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_PE_Strict_20260121-163720/endomentriosis_pe_disease_signature_hits_logFC_1_q<0.00.csv")
ESE <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_ESE_Strict_20260121-160656/endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv")
MSE <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_MSE_Strict_20260121-162955/endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv")
unstratified <- read.csv("scripts/results/endo_v2/CMAP_Endometriosis_Unstratified_Strict_20260121-164307/endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv")

# Sort all by cmap_score (ascending - more negative = better)
unstratified <- unstratified[order(unstratified$cmap_score), ]
InII <- InII[order(InII$cmap_score), ]
IIInIV <- IIInIV[order(IIInIV$cmap_score), ]
PE <- PE[order(PE$cmap_score), ]
ESE <- ESE[order(ESE$cmap_score), ]
MSE <- MSE[order(MSE$cmap_score), ]

cat("  ✓ Loaded all 6 signatures\n")
cat("    Unstratified:", nrow(unstratified), "drugs\n")
cat("    ESE:", nrow(ESE), "drugs\n")
cat("    MSE:", nrow(MSE), "drugs\n")
cat("    PE:", nrow(PE), "drugs\n")
cat("    IIInIV:", nrow(IIInIV), "drugs\n")
cat("    InII:", nrow(InII), "drugs\n\n")

# Extract name and cmap_score columns
unstratified <- dplyr::select(unstratified, name, cmap_score)
InII <- dplyr::select(InII, name, cmap_score)
IIInIV <- dplyr::select(IIInIV, name, cmap_score)
PE <- dplyr::select(PE, name, cmap_score)
ESE <- dplyr::select(ESE, name, cmap_score)
MSE <- dplyr::select(MSE, name, cmap_score)

# Get top 20 from unstratified
unstratified <- unstratified[1:20,]
cat("Top 20 drugs from Unstratified:\n")
print(unstratified$name)
cat("\n")

# Filter other signatures to only include the top 20 drugs from unstratified
InII <- InII[InII$name %in% unstratified$name,]
IIInIV <- IIInIV[IIInIV$name %in% unstratified$name,]
PE <- PE[PE$name %in% unstratified$name,]
ESE <- ESE[ESE$name %in% unstratified$name,]
MSE <- MSE[MSE$name %in% unstratified$name,]

cat("Overlap with top 20:\n")
cat("  ESE:", nrow(ESE), "drugs\n")
cat("  MSE:", nrow(MSE), "drugs\n")
cat("  PE:", nrow(PE), "drugs\n")
cat("  IIInIV:", nrow(IIInIV), "drugs\n")
cat("  InII:", nrow(InII), "drugs\n\n")

# Rename cmap_score columns to signature names
colnames(unstratified)[2] <- "unstratified"
colnames(InII)[2] <- "InII"
colnames(IIInIV)[2] <- "IIInIV"
colnames(PE)[2] <- "PE"
colnames(ESE)[2] <- "ESE"
colnames(MSE)[2] <- "MSE"

# Combine all signatures into one dataframe
colname <- list(unstratified, InII, IIInIV, PE, ESE, MSE)
df <- Reduce(function(x,y) merge(x = x, y = y, by = "name", all.x = TRUE), 
             colname)

# Convert to matrix
row.names(df) <- df$name
df <- df[,2:7]
df[is.na(df)] <- 0

cat("Combined dataframe:\n")
print(head(df))
cat("\n")

# Rescale scores to 0-100 range (negative scores = greater reversal effect)
rescale <- function(x) -(x - max(x)) / (max(x) - min(x)) * 100
dfr <- as.data.frame(apply(df, 2, rescale))
row.names(dfr) <- row.names(df)

# Sort by unstratified signature (descending)
dfr <- dfr[order(-dfr$unstratified),]

# Save rescaled data for reference
write.csv(dfr, "endo_tomiko_code/replication/e2e_rawdata/dfr_top20_drpipe.csv")

# Convert to matrix
matrix <- data.matrix(dfr)

# Create color palette
my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

# Generate PDF heatmap
pdf("endo_tomiko_code/replication/e2e_rawdata/heatmaps_by_signature_top20_drpipe.pdf", width = 9, height = 7)

heatmap.2(matrix,
          main = "Reversal Scores for Top 20 Drug Candidates\nAcross All Endometriosis Signatures (DRpipe)",
          notecol="black",
          density.info="none",
          trace="none",
          margins = c(5,15),
          col = my_palette,
          dendrogram="none",
          cexRow = 1.4,
          cexCol = 1.4,
          lmat = rbind(c(0,3),c(4,1),c(0,2)),
          lhei = c(1.5,3,1),
          lwid = c(1.5,3),
          Colv=FALSE,
          Rowv=FALSE,
          key=TRUE,
          srtCol = 0,
          adjCol = 0.5,
          key.title=NA,
          key.xlab="",
          keysize=0.25,
          key.xtickfun=function() {
            trace="none"
            cex <- par("cex")*par("cex.axis")
            line <- 0
            col <- par("col.axis")
            font <- par("font.axis")
            mtext("No Reversal\n Effect (reversal\nscore > 0, or\nq-value > 0.0001)", 
                  side=1, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=1)
            mtext("Maximum Reversal\n Effect (reversal\nscore <= 0)", 
                  side=3, at=0.5, adj=0.5,
                  line=line, cex=cex, col=col, font=font, padj=-0.1)
            return(list(labels=FALSE, tick=FALSE))
          }
)

dev.off()

cat("════════════════════════════════════════════════════════════════\n")
cat("✓ Heatmap saved to: endo_tomiko_code/replication/e2e_rawdata/heatmaps_by_signature_top20_drpipe.pdf\n")
cat("✓ Rescaled data saved to: endo_tomiko_code/replication/e2e_rawdata/dfr_top20_drpipe.csv\n")
cat("════════════════════════════════════════════════════════════════\n")
