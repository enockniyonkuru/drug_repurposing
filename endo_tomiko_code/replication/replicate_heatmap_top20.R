#!/usr/bin/env Rscript

# This script replicates the heatmaps_by_signature_top20.pdf visualization
# It uses the end-to-end replicated drug_instances files

library(pheatmap)
library(gplots)
library(ggplot2)
library(RColorBrewer)
library(reshape2)
library(tidyverse)
library(dplyr)

# Set working directory to workspace root
setwd("/Users/enockniyonkuru/Desktop/endo_tomiko_code")

# Import the replicated drug instances data
# These are generated from end-to-end pipeline with set.seed(2009)
InII <- read.csv("replication/drug_instances_InII_replicated.csv")
IIInIV <- read.csv("replication/drug_instances_IIInIV_replicated.csv")
PE <- read.csv("replication/drug_instances_PE_replicated.csv")
ESE <- read.csv("replication/drug_instances_ESE_replicated.csv")
MSE <- read.csv("replication/drug_instances_MSE_replicated.csv")
unstratified <- read.csv("replication/drug_instances_unstratified_replicated.csv")

# Extract name and cmap_score columns
unstratified <- dplyr::select(unstratified, name, cmap_score)
InII <- dplyr::select(InII, name, cmap_score)
IIInIV <- dplyr::select(IIInIV, name, cmap_score)
PE <- dplyr::select(PE, name, cmap_score)
ESE <- dplyr::select(ESE, name, cmap_score)
MSE <- dplyr::select(MSE, name, cmap_score)

# Get top 20 from unstratified
unstratified <- unstratified[1:20,]

# Filter other signatures to only include the top 20 drugs from unstratified
InII <- InII[InII$name %in% unstratified$name,]
IIInIV <- IIInIV[IIInIV$name %in% unstratified$name,]
PE <- PE[PE$name %in% unstratified$name,]
ESE <- ESE[ESE$name %in% unstratified$name,]
MSE <- MSE[MSE$name %in% unstratified$name,]

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

# Rescale scores to 0-100 range (negative scores = greater reversal effect)
rescale <- function(x) -(x - max(x)) / (max(x) - min(x)) * 100
dfr <- as.data.frame(apply(df, 2, rescale))
row.names(dfr) <- row.names(df)

# Sort by unstratified signature (descending)
dfr <- dfr[order(-dfr$unstratified),]

# Save rescaled data for reference
write.csv(dfr, "replication/dfr_replicated.csv")

# Convert to matrix
matrix <- data.matrix(dfr)

# Create color palette
my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

# Generate PDF heatmap
pdf("replication/heatmaps_by_signature_top20_replicated.pdf", width = 9, height = 7)

heatmap.2(matrix,
          main = "Reversal Scores for Top 20 Drug Candidates\nAcross All Endometriosis Signatures",
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

cat("✓ Heatmap replicated and saved to: replication/heatmaps_by_signature_top20_replicated.pdf\n")
cat("✓ Rescaled data saved to: replication/dfr_replicated.csv\n")
