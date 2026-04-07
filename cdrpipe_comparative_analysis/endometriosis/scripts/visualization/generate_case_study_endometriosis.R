#!/usr/bin/env Rscript
# ============================================================================
# Generate Endometriosis Top-50 Drug Reversal Heatmaps
#
# Creates two heatmaps comparing drug reversal scores across endometriosis
# sub-signatures for CMap and Tahoe platforms.
#
# Outputs (to endometriosis/figures/):
#   - cmap_top50_reversal_scores_heatmap.png
#   - tahoe_top50_reversal_scores_heatmap.png
#
# Data sources:
#   - CMap: reads from endometriosis/results/microarray/cmap_hit_tables/
#     (hit tables with name + cmap_score columns)
#   - Tahoe: reads from endometriosis/results/microarray/tahoe_hit_tables/
#     (must be regenerated — see README for instructions)
# ============================================================================

library(gplots)
library(dplyr)

# ---------------------------------------------------------------------------
# Paths – relative to repository root
# ---------------------------------------------------------------------------
get_repo_root <- function() {
  candidates <- character()
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    candidates <- c(candidates, dirname(sub("^--file=", "", file_arg)))
  }
  if (!is.null(sys.frames()[[1]]$ofile)) {
    candidates <- c(candidates, dirname(sys.frames()[[1]]$ofile))
  }
  candidates <- c(candidates, getwd())

  for (start in unique(candidates)) {
    cur <- normalizePath(start, winslash = "/", mustWork = FALSE)
    repeat {
      if (dir.exists(file.path(cur, "shared")) &&
          dir.exists(file.path(cur, "creeds"))) {
        return(cur)
      }
      nested <- file.path(cur, "cdrpipe_comparative_analysis")
      if (dir.exists(file.path(nested, "shared")) &&
          dir.exists(file.path(nested, "creeds"))) {
        return(normalizePath(nested, winslash = "/", mustWork = FALSE))
      }
      parent <- dirname(cur)
      if (identical(parent, cur)) break
      cur <- parent
    }
  }

  stop("Could not locate cdrpipe_comparative_analysis root", call. = FALSE)
}
repo_root <- get_repo_root()
output_dir <- file.path(repo_root, "endometriosis", "figures")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Source data directories
cmap_source <- file.path(repo_root, "endometriosis", "results", "microarray", "cmap_hit_tables")
tahoe_source <- file.path(repo_root, "endometriosis", "results", "microarray", "tahoe_hit_tables")

# Rescale helper
rescale <- function(x) {
  if (max(x) == min(x)) return(rep(50, length(x)))
  -(x - max(x)) / (max(x) - min(x)) * 100
}

# Color palette (shared by both heatmaps)
my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

# Overlap drugs to highlight
overlap_drugs <- c("irinotecan", "terfenadine")

# Custom key-tick function
key_tick_fn <- function() {
  cex  <- par("cex") * par("cex.axis")
  line <- 0; col <- par("col.axis"); font <- par("font.axis")
  mtext("No Reversal\n Effect", side = 1, at = 0.5, adj = 0.5, line = line, cex = cex, col = col, font = font, padj = 1)
  mtext("Maximum Reversal\n Effect", side = 3, at = 0.5, adj = 0.5, line = line, cex = cex, col = col, font = font, padj = -0.1)
  return(list(labels = FALSE, tick = FALSE))
}

# ===========================================================================
# CMAP TOP 50
# ===========================================================================
cat("\n=== Creating CMap Top 50 Heatmap ===\n")

if (!dir.exists(cmap_source)) {
  stop("CMap source data not found at: ", cmap_source, call. = FALSE)
}

ESE_cmap          <- read.csv(file.path(cmap_source, "cmap_hits_ESE.csv"))
IIInIV_cmap       <- read.csv(file.path(cmap_source, "cmap_hits_IIInIV.csv"))
InII_cmap         <- read.csv(file.path(cmap_source, "cmap_hits_InII.csv"))
MSE_cmap          <- read.csv(file.path(cmap_source, "cmap_hits_MSE.csv"))
PE_cmap           <- read.csv(file.path(cmap_source, "cmap_hits_PE.csv"))
unstratified_cmap <- read.csv(file.path(cmap_source, "cmap_hits_unstratified.csv"))

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
          lmat = rbind(c(0, 3), c(4, 1), c(0, 2)), lhei = c(2, 8, 1.1), lwid = c(0.4, 3),
          Colv = FALSE, Rowv = FALSE, key = TRUE, srtCol = 0, adjCol = 0.5,
          key.title = NA, key.xlab = "", keysize = 0.1, key.xtickfun = key_tick_fn)
mtext("CMap: Reversal Scores for Top 50 Drug Candidates\nAcross All Endometriosis Signatures",
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)
dev.off()
cat("  Saved cmap_top50_reversal_scores_heatmap.png\n")

# ===========================================================================
# TAHOE TOP 50 (or all available)
# ===========================================================================
cat("\n=== Creating Tahoe Top 50 Heatmap ===\n")

tahoe_files <- file.path(tahoe_source, c(
  "tahoe_hits_ESE.csv", "tahoe_hits_IIInIV.csv", "tahoe_hits_InII.csv",
  "tahoe_hits_MSE.csv", "tahoe_hits_PE.csv", "tahoe_hits_unstratified.csv"
))

if (!all(file.exists(tahoe_files))) {
  cat(paste0(
    "  SKIPPED: Tahoe hit tables not found in:\n",
    "    ", tahoe_source, "/\n\n",
    "  To regenerate, run CDRPipe with the strict-filter config (TAHOE only):\n",
    "    Rscript shared/scripts/execute/run_batch_from_config.R \\\n",
    "      --config_file endometriosis/scripts/execute/microarray_strict_config.yml\n\n",
    "  Then copy the per-signature hit CSVs into:\n",
    "    endometriosis/results/microarray/tahoe_hit_tables/\n",
    "  using the naming convention: tahoe_hits_{ESE,IIInIV,InII,MSE,PE,unstratified}.csv\n",
    "  Each file needs at minimum 'name' and 'cmap_score' columns.\n"
  ))
} else {

ESE_tahoe          <- read.csv(file.path(tahoe_source, "tahoe_hits_ESE.csv"))
IIInIV_tahoe       <- read.csv(file.path(tahoe_source, "tahoe_hits_IIInIV.csv"))
InII_tahoe         <- read.csv(file.path(tahoe_source, "tahoe_hits_InII.csv"))
MSE_tahoe          <- read.csv(file.path(tahoe_source, "tahoe_hits_MSE.csv"))
PE_tahoe           <- read.csv(file.path(tahoe_source, "tahoe_hits_PE.csv"))
unstratified_tahoe <- read.csv(file.path(tahoe_source, "tahoe_hits_unstratified.csv"))

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
          lmat = rbind(c(0, 3), c(4, 1), c(0, 2)), lhei = c(1, 8, 0.8), lwid = c(0.4, 3),
          Colv = FALSE, Rowv = FALSE, key = TRUE, srtCol = 0, adjCol = 0.5,
          key.title = NA, key.xlab = "", keysize = 0.1, key.xtickfun = key_tick_fn)
mtext(paste0("Tahoe-100M: Reversal Scores for Top ", n_drugs, " Drug Candidates\nAcross All Endometriosis Signatures"),
      outer = TRUE, side = 3, line = 0, cex = 1.2, font = 2)
dev.off()
cat("  Saved tahoe_top50_reversal_scores_heatmap.png\n")

} # end tahoe else block

cat("\nDone! Check endometriosis/figures/ for output.\n")
