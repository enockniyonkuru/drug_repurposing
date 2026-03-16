# ============================================================================
# Create Heatmaps for Tomiko's Study - Top 20 and Top 50
# Uses data from endo_tomiko_code/replication/drug_hits_comparison
# ============================================================================

library(gplots)
library(ggplot2)
library(tidyverse)
library(scales)

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

# ============================================================================
# Load Tomiko's data
# ============================================================================

tomiko_base <- "endo_tomiko_code/replication/drug_hits_comparison"

ESE_tomiko <- read.csv(paste0(tomiko_base, "/drug_instances_ESE.csv"))
IIInIV_tomiko <- read.csv(paste0(tomiko_base, "/drug_instances_IIInIV.csv"))
InII_tomiko <- read.csv(paste0(tomiko_base, "/drug_instances_InII.csv"))
MSE_tomiko <- read.csv(paste0(tomiko_base, "/drug_instances_MSE.csv"))
PE_tomiko <- read.csv(paste0(tomiko_base, "/drug_instances_PE.csv"))
unstratified_tomiko <- read.csv(paste0(tomiko_base, "/drug_instances_unstratified.csv"))

cat("Loaded Tomiko data:\n")
cat("  ESE:", nrow(ESE_tomiko), "hits\n")
cat("  IIInIV:", nrow(IIInIV_tomiko), "hits\n")
cat("  InII:", nrow(InII_tomiko), "hits\n")
cat("  MSE:", nrow(MSE_tomiko), "hits\n")
cat("  PE:", nrow(PE_tomiko), "hits\n")
cat("  Unstratified:", nrow(unstratified_tomiko), "hits\n")

# ============================================================================
# Helper function to create heatmap
# ============================================================================

create_tomiko_heatmap <- function(top_n = 20) {
  
  cat("\n========================================\n")
  cat("Creating Tomiko Heatmap (Top", top_n, ")\n")
  cat("========================================\n")
  
  # Get top drugs from unstratified (sorted by cmap_score ascending - more negative = better)
  unstratified_sorted <- unstratified_tomiko[order(unstratified_tomiko$cmap_score),]
  n_drugs <- min(top_n, nrow(unstratified_sorted))
  top_drugs <- unstratified_sorted[1:n_drugs,]
  
  cat("Top", n_drugs, "drugs from Unstratified\n")
  
  # Filter other signatures to only include the top drugs
  ESE_filt <- ESE_tomiko[ESE_tomiko$name %in% top_drugs$name,]
  IIInIV_filt <- IIInIV_tomiko[IIInIV_tomiko$name %in% top_drugs$name,]
  InII_filt <- InII_tomiko[InII_tomiko$name %in% top_drugs$name,]
  MSE_filt <- MSE_tomiko[MSE_tomiko$name %in% top_drugs$name,]
  PE_filt <- PE_tomiko[PE_tomiko$name %in% top_drugs$name,]
  
  # Rename cmap_score columns to signature names
  colnames(top_drugs)[which(colnames(top_drugs) == "cmap_score")] <- "Unstratified"
  colnames(ESE_filt)[which(colnames(ESE_filt) == "cmap_score")] <- "ESE"
  colnames(IIInIV_filt)[which(colnames(IIInIV_filt) == "cmap_score")] <- "IIInIV"
  colnames(InII_filt)[which(colnames(InII_filt) == "cmap_score")] <- "InII"
  colnames(MSE_filt)[which(colnames(MSE_filt) == "cmap_score")] <- "MSE"
  colnames(PE_filt)[which(colnames(PE_filt) == "cmap_score")] <- "PE"
  
  # Select only name and score columns
  top_drugs_sel <- top_drugs[, c("name", "Unstratified")]
  ESE_sel <- ESE_filt[, c("name", "ESE")]
  IIInIV_sel <- IIInIV_filt[, c("name", "IIInIV")]
  InII_sel <- InII_filt[, c("name", "InII")]
  MSE_sel <- MSE_filt[, c("name", "MSE")]
  PE_sel <- PE_filt[, c("name", "PE")]
  
  # Combine all signatures into one dataframe
  colname_list <- list(top_drugs_sel, InII_sel, IIInIV_sel, PE_sel, ESE_sel, MSE_sel)
  df_combined <- Reduce(function(x, y) merge(x = x, y = y, by = "name", all.x = TRUE), colname_list)
  
  # Convert to matrix
  row.names(df_combined) <- df_combined$name
  df_combined <- df_combined[, 2:7]
  df_combined[is.na(df_combined)] <- 0
  
  # Rescale scores to 0-100 range (more negative = higher score for visualization)
  dfr <- as.data.frame(apply(df_combined, 2, rescale))
  row.names(dfr) <- row.names(df_combined)
  
  # Sort by unstratified signature (descending - highest rescaled score first)
  dfr <- dfr[order(-dfr$Unstratified),]
  
  # Save rescaled data
  write.csv(dfr, paste0("scripts/results/tomiko_top", top_n, "_heatmap_data.csv"))
  
  # Convert to matrix
  matrix_data <- data.matrix(dfr)
  
  # Create color palette
  my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)
  
  # Define overlapping drugs with CMAP/TAHOE (irinotecan and terfenadine)
  overlap_drugs <- c("irinotecan", "terfenadine")
  
  # Modify row labels to add marker for overlapping drugs
  row_labels <- row.names(matrix_data)
  row_labels <- ifelse(tolower(row_labels) %in% overlap_drugs, 
                       paste0(">>> ", row_labels, " <<<"), row_labels)
  
  # Calculate dimensions
  if (top_n <= 20) {
    pdf_width <- 9
    pdf_height <- 7
    cex_row <- 1.2
    margins <- c(5, 15)
    keysize <- 0.25
    lhei <- c(1, 3, 1)
  } else {
    pdf_width <- 10
    pdf_height <- 15
    cex_row <- 0.8
    margins <- c(6, 18)
    keysize <- 0.15
    lhei <- c(1, 5, 0.8)
  }
  
  # Generate PDF heatmap
  pdf(paste0("scripts/results/heatmap_tomiko_top", top_n, ".pdf"), width = pdf_width, height = pdf_height)
  
  par(oma = c(0, 0, 2.5, 0))
  
  heatmap.2(matrix_data,
            main = "",
            labRow = row_labels,
            notecol = "black",
            density.info = "none",
            trace = "none",
            margins = margins,
            col = my_palette,
            dendrogram = "none",
            cexRow = cex_row,
            cexCol = 1.4,
            lmat = rbind(c(0, 3), c(4, 1), c(0, 2)),
            lhei = lhei,
            lwid = c(1.5, 3),
            Colv = FALSE,
            Rowv = FALSE,
            key = TRUE,
            srtCol = 0,
            adjCol = 0.5,
            key.title = NA,
            key.xlab = "",
            keysize = keysize,
            key.xtickfun = function() {
              trace = "none"
              cex <- par("cex") * par("cex.axis")
              line <- 0
              col <- par("col.axis")
              font <- par("font.axis")
              mtext("No Reversal\n Effect", 
                    side = 1, at = 0.5, adj = 0.5,
                    line = line, cex = cex, col = col, font = font, padj = 1)
              mtext("Maximum Reversal\n Effect", 
                    side = 3, at = 0.5, adj = 0.5,
                    line = line, cex = cex, col = col, font = font, padj = -0.1)
              return(list(labels = FALSE, tick = FALSE))
            }
  )
  
  mtext(paste0("Tomiko et al.: Reversal Scores for Top ", n_drugs, " Drug Candidates\nAcross All Endometriosis Signatures"), 
        outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)
  
  dev.off()
  
  # Generate JPG heatmap
  jpeg(paste0("scripts/results/heatmap_tomiko_top", top_n, ".jpg"), 
       width = pdf_width, height = pdf_height, units = "in", res = 300, quality = 100)
  
  par(oma = c(0, 0, 2.5, 0))
  
  heatmap.2(matrix_data,
            main = "",
            labRow = row_labels,
            notecol = "black",
            density.info = "none",
            trace = "none",
            margins = margins,
            col = my_palette,
            dendrogram = "none",
            cexRow = cex_row,
            cexCol = 1.4,
            lmat = rbind(c(0, 3), c(4, 1), c(0, 2)),
            lhei = lhei,
            lwid = c(1.5, 3),
            Colv = FALSE,
            Rowv = FALSE,
            key = TRUE,
            srtCol = 0,
            adjCol = 0.5,
            key.title = NA,
            key.xlab = "",
            keysize = keysize,
            key.xtickfun = function() {
              trace = "none"
              cex <- par("cex") * par("cex.axis")
              line <- 0
              col <- par("col.axis")
              font <- par("font.axis")
              mtext("No Reversal\n Effect", 
                    side = 1, at = 0.5, adj = 0.5,
                    line = line, cex = cex, col = col, font = font, padj = 1)
              mtext("Maximum Reversal\n Effect", 
                    side = 3, at = 0.5, adj = 0.5,
                    line = line, cex = cex, col = col, font = font, padj = -0.1)
              return(list(labels = FALSE, tick = FALSE))
            }
  )
  
  mtext(paste0("Tomiko et al.: Reversal Scores for Top ", n_drugs, " Drug Candidates\nAcross All Endometriosis Signatures"), 
        outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)
  
  dev.off()
  
  cat("✓ Tomiko heatmap (Top", n_drugs, ") saved to: scripts/results/heatmap_tomiko_top", top_n, ".pdf\n", sep = "")
  cat("✓ Tomiko heatmap (Top", n_drugs, ") saved to: scripts/results/heatmap_tomiko_top", top_n, ".jpg\n", sep = "")
  cat("✓ Tomiko data saved to: scripts/results/tomiko_top", top_n, "_heatmap_data.csv\n", sep = "")
  
  cat("\nTop", n_drugs, "drugs (Tomiko):\n")
  print(row.names(dfr))
  
  return(dfr)
}

# ============================================================================
# Create Top 20 Heatmap
# ============================================================================

dfr_top20 <- create_tomiko_heatmap(top_n = 20)

# ============================================================================
# Create Top 50 Heatmap
# ============================================================================

dfr_top50 <- create_tomiko_heatmap(top_n = 50)

# ============================================================================
# Summary
# ============================================================================

cat("\n========================================\n")
cat("TOMIKO HEATMAP GENERATION COMPLETE\n")
cat("========================================\n")

cat("\nGenerated files:\n")
cat("  - scripts/results/heatmap_tomiko_top20.pdf\n")
cat("  - scripts/results/heatmap_tomiko_top20.jpg\n")
cat("  - scripts/results/heatmap_tomiko_top50.pdf\n")
cat("  - scripts/results/heatmap_tomiko_top50.jpg\n")

# Check for overlap with CMAP/TAHOE top drugs
overlap_drugs <- c("irinotecan", "terfenadine")
cat("\nDrugs overlapping with CMAP/TAHOE (marked with >>>):\n")
for (drug in overlap_drugs) {
  if (drug %in% tolower(row.names(dfr_top50))) {
    cat("  -", drug, "✓ (found in Tomiko top 50)\n")
  } else {
    cat("  -", drug, "✗ (not in Tomiko top 50)\n")
  }
}

cat("\n✓ Analysis complete!\n")
