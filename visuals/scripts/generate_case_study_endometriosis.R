#!/usr/bin/env Rscript
# ============================================================================
# Generate Endometriosis Top-50 Drug Reversal Heatmaps
#
# Creates two heatmaps comparing drug reversal scores across endometriosis
# sub-signatures for CMap and Tahoe platforms.
#
# Outputs (to visuals/figures/case_study_endometriosis/):
#   - cmap_top50_reversal_scores_heatmap.png
#   - tahoe_top50_reversal_scores_heatmap.png
#
# Data sources (relative to repository root):
#   - scripts/results/endo_v4_cmap/endo_v4_{ESE,IIInIV,InII,MSE,PE,Unstratified}/*.csv
#   - scripts/results/endo_v5_tahoe/endo_tahoe_{ESE,IIInIV,InII,MSE,PE,Unstratified}/*.csv
# ============================================================================

library(gplots)
library(dplyr)

# ---------------------------------------------------------------------------
# Paths – relative to repository root
# ---------------------------------------------------------------------------
get_repo_root <- function() {
  # Method 1: Rscript --file argument
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), "..", "..")))
  }
  # Method 2: here package
  if (requireNamespace("here", quietly = TRUE)) return(here::here())
  # Method 3: working directory
  getwd()
}
repo_root <- get_repo_root()
output_dir <- file.path(repo_root, "visuals", "figures", "case_study_endometriosis")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Rescale helper
rescale <- function(x) {
  if (max(x) == min(x)) return(rep(50, length(x)))
  -(x - max(x)) / (max(x) - min(x)) * 100
}

# ===========================================================================
# CMAP TOP 50
# ===========================================================================
cat("\n=== Creating CMap Top 50 Heatmap ===\n")

cmap_base <- file.path(repo_root, "scripts", "results", "endo_v4_cmap")

ESE_cmap          <- read.csv(file.path(cmap_base, "endo_v4_ESE",          "endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv"))
IIInIV_cmap       <- read.csv(file.path(cmap_base, "endo_v4_IIInIV",      "endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv"))
InII_cmap         <- read.csv(file.path(cmap_base, "endo_v4_InII",        "endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv"))
MSE_cmap          <- read.csv(file.path(cmap_base, "endo_v4_MSE",         "endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv"))
PE_cmap           <- read.csv(file.path(cmap_base, "endo_v4_PE",          "endomentriosis_pe_disease_signature_hits_logFC_1.1_q<0.00.csv"))
unstratified_cmap <- read.csv(file.path(cmap_base, "endo_v4_Unstratified","endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv"))

# Select columns
unstratified_cmap <- dplyr::select(unstratified_cmap, name, cmap_score)
InII_cmap         <- dplyr::select(InII_cmap,         name, cmap_score)
IIInIV_cmap       <- dplyr::select(IIInIV_cmap,       name, cmap_score)
PE_cmap           <- dplyr::select(PE_cmap,           name, cmap_score)
ESE_cmap          <- dplyr::select(ESE_cmap,          name, cmap_score)
MSE_cmap          <- dplyr::select(MSE_cmap,          name, cmap_score)

# Top 50 by unstratified
unstratified_cmap <- unstratified_cmap[order(unstratified_cmap$cmap_score), ]
unstratified_cmap <- unstratified_cmap[1:50, ]

# Filter other signatures
InII_cmap_filt   <- InII_cmap[InII_cmap$name %in% unstratified_cmap$name, ]
IIInIV_cmap_filt <- IIInIV_cmap[IIInIV_cmap$name %in% unstratified_cmap$name, ]
PE_cmap_filt     <- PE_cmap[PE_cmap$name %in% unstratified_cmap$name, ]
ESE_cmap_filt    <- ESE_cmap[ESE_cmap$name %in% unstratified_cmap$name, ]
MSE_cmap_filt    <- MSE_cmap[MSE_cmap$name %in% unstratified_cmap$name, ]

# Rename
colnames(unstratified_cmap)[2] <- "Unstratified"
colnames(InII_cmap_filt)[2]    <- "InII"
colnames(IIInIV_cmap_filt)[2]  <- "IIInIV"
colnames(PE_cmap_filt)[2]      <- "PE"
colnames(ESE_cmap_filt)[2]     <- "ESE"
colnames(MSE_cmap_filt)[2]     <- "MSE"

# Merge
df_cmap <- Reduce(function(x, y) merge(x, y, by = "name", all.x = TRUE),
                  list(unstratified_cmap, InII_cmap_filt, IIInIV_cmap_filt, PE_cmap_filt, ESE_cmap_filt, MSE_cmap_filt))
row.names(df_cmap) <- df_cmap$name
df_cmap <- df_cmap[, 2:7]
df_cmap[is.na(df_cmap)] <- 0

# Rescale & sort
dfr_cmap <- as.data.frame(apply(df_cmap, 2, rescale))
row.names(dfr_cmap) <- row.names(df_cmap)
dfr_cmap <- dfr_cmap[order(-dfr_cmap$Unstratified), ]
matrix_cmap <- data.matrix(dfr_cmap)

# Color palette
my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

# Overlap drugs
overlap_drugs <- c("irinotecan", "terfenadine")
row_labels_cmap <- row.names(matrix_cmap)
row_labels_cmap <- ifelse(tolower(row_labels_cmap) %in% overlap_drugs,
                          paste0(">>> ", row_labels_cmap, " <<<"), row_labels_cmap)

# Custom key-tick function
key_tick_fn <- function() {
  cex  <- par("cex") * par("cex.axis")
  line <- 0; col <- par("col.axis"); font <- par("font.axis")
  mtext("No Reversal\n Effect", side = 1, at = 0.5, adj = 0.5, line = line, cex = cex, col = col, font = font, padj = 1)
  mtext("Maximum Reversal\n Effect", side = 3, at = 0.5, adj = 0.5, line = line, cex = cex, col = col, font = font, padj = -0.1)
  return(list(labels = FALSE, tick = FALSE))
}

# --- PNG ---
png(file.path(output_dir, "cmap_top50_reversal_scores_heatmap.png"), width = 10, height = 15, units = "in", res = 300, bg = "white")
par(oma = c(0, 0, 2.5, 0))
heatmap.2(matrix_cmap, main = "", labRow = row_labels_cmap,
          notecol = "black", density.info = "none", trace = "none",
          margins = c(6, 18), col = my_palette, dendrogram = "none",
          cexRow = 0.8, cexCol = 1.4,
          lmat = rbind(c(0, 3), c(4, 1), c(0, 2)), lhei = c(1, 5, 0.8), lwid = c(0.7, 3),
          Colv = FALSE, Rowv = FALSE, key = TRUE, srtCol = 0, adjCol = 0.5,
          key.title = NA, key.xlab = "", keysize = 0.15, key.xtickfun = key_tick_fn)
mtext("CMap: Reversal Scores for Top 50 Drug Candidates\nAcross All Endometriosis Signatures",
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)
dev.off()
cat("  Saved cmap_top50_reversal_scores_heatmap.png\n")

# ===========================================================================
# TAHOE TOP 50 (or all available)
# ===========================================================================
cat("\n=== Creating Tahoe Top 50 Heatmap ===\n")

tahoe_base <- file.path(repo_root, "scripts", "results", "endo_v5_tahoe")

ESE_tahoe          <- read.csv(file.path(tahoe_base, "endo_tahoe_ESE",          "endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv"))
IIInIV_tahoe       <- read.csv(file.path(tahoe_base, "endo_tahoe_IIInIV",      "endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv"))
InII_tahoe         <- read.csv(file.path(tahoe_base, "endo_tahoe_InII",        "endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv"))
MSE_tahoe          <- read.csv(file.path(tahoe_base, "endo_tahoe_MSE",         "endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv"))
PE_tahoe           <- read.csv(file.path(tahoe_base, "endo_tahoe_PE",          "endomentriosis_pe_disease_signature_hits_logFC_1.1_q<0.00.csv"))
unstratified_tahoe <- read.csv(file.path(tahoe_base, "endo_tahoe_Unstratified","endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv"))

unstratified_tahoe <- dplyr::select(unstratified_tahoe, name, cmap_score)
InII_tahoe         <- dplyr::select(InII_tahoe,         name, cmap_score)
IIInIV_tahoe       <- dplyr::select(IIInIV_tahoe,       name, cmap_score)
PE_tahoe           <- dplyr::select(PE_tahoe,           name, cmap_score)
ESE_tahoe          <- dplyr::select(ESE_tahoe,          name, cmap_score)
MSE_tahoe          <- dplyr::select(MSE_tahoe,          name, cmap_score)

unstratified_tahoe <- unstratified_tahoe[order(unstratified_tahoe$cmap_score), ]
n_drugs <- min(50, nrow(unstratified_tahoe))
unstratified_tahoe <- unstratified_tahoe[1:n_drugs, ]

InII_tahoe_filt   <- InII_tahoe[InII_tahoe$name %in% unstratified_tahoe$name, ]
IIInIV_tahoe_filt <- IIInIV_tahoe[IIInIV_tahoe$name %in% unstratified_tahoe$name, ]
PE_tahoe_filt     <- PE_tahoe[PE_tahoe$name %in% unstratified_tahoe$name, ]
ESE_tahoe_filt    <- ESE_tahoe[ESE_tahoe$name %in% unstratified_tahoe$name, ]
MSE_tahoe_filt    <- MSE_tahoe[MSE_tahoe$name %in% unstratified_tahoe$name, ]

colnames(unstratified_tahoe)[2] <- "Unstratified"
colnames(InII_tahoe_filt)[2]    <- "InII"
colnames(IIInIV_tahoe_filt)[2]  <- "IIInIV"
colnames(PE_tahoe_filt)[2]      <- "PE"
colnames(ESE_tahoe_filt)[2]     <- "ESE"
colnames(MSE_tahoe_filt)[2]     <- "MSE"

df_tahoe <- Reduce(function(x, y) merge(x, y, by = "name", all.x = TRUE),
                   list(unstratified_tahoe, InII_tahoe_filt, IIInIV_tahoe_filt, PE_tahoe_filt, ESE_tahoe_filt, MSE_tahoe_filt))
row.names(df_tahoe) <- df_tahoe$name
df_tahoe <- df_tahoe[, 2:7]
df_tahoe[is.na(df_tahoe)] <- 0

dfr_tahoe <- as.data.frame(apply(df_tahoe, 2, rescale))
row.names(dfr_tahoe) <- row.names(df_tahoe)
dfr_tahoe <- dfr_tahoe[order(-dfr_tahoe$Unstratified), ]
matrix_tahoe <- data.matrix(dfr_tahoe)
height_tahoe <- max(8, n_drugs * 0.30)

row_labels_tahoe <- row.names(matrix_tahoe)
row_labels_tahoe <- ifelse(grepl("irinotecan|terfenadine", tolower(row_labels_tahoe)),
                           paste0(">>> ", row_labels_tahoe, " <<<"), row_labels_tahoe)

# --- PNG ---
png(file.path(output_dir, "tahoe_top50_reversal_scores_heatmap.png"), width = 10, height = height_tahoe, units = "in", res = 300, bg = "white")
par(oma = c(0, 0, 2.5, 0))
heatmap.2(matrix_tahoe, main = "", labRow = row_labels_tahoe,
          notecol = "black", density.info = "none", trace = "none",
          margins = c(6, 22), col = my_palette, dendrogram = "none",
          cexRow = 0.8, cexCol = 1.4,
          lmat = rbind(c(0, 3), c(4, 1), c(0, 2)), lhei = c(1, 5, 0.8), lwid = c(0.7, 3),
          Colv = FALSE, Rowv = FALSE, key = TRUE, srtCol = 0, adjCol = 0.5,
          key.title = NA, key.xlab = "", keysize = 0.15, key.xtickfun = key_tick_fn)
mtext(paste0("Tahoe-100M: Reversal Scores for Top ", n_drugs, " Drug Candidates\nAcross All Endometriosis Signatures"),
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)
dev.off()
cat("  Saved tahoe_top50_reversal_scores_heatmap.png\n")

cat("\nAll endometriosis top-50 heatmaps generated!\n")
