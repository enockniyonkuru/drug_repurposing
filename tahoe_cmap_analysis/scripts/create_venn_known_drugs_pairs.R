#!/usr/bin/env Rscript

# Create Venn Diagrams for Available and Recovered Known Drug Pairs
# Follows color consistency: TAHOE (Serene Blue), CMAP (Warm Orange)

library(tidyverse)
library(arrow)
suppressPackageStartupMessages({
  library(VennDiagram, warn.conflicts = FALSE)
})
library(scales)

# ============================================================================
# COLOR SCHEME (Matching additional_figures.txt)
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap

figures_dir <- "tahoe_cmap_analysis/figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data...\n")

# Load analysis summary with disease-drug pair information
analysis <- read_csv('tahoe_cmap_analysis/data/analysis/creed_manual_analysis_exp_8/analysis_summary_creed_manual_standardised_results_OG_exp_8_q0.05.csv',
                     show_col_types = FALSE)

cat("✓ Data loaded\n\n")

# ============================================================================
# PREPARE DATA FOR VENN DIAGRAMS
# ============================================================================

cat("=== Preparing Venn Diagram Data ===\n")

# Calculate available pairs
pairs_in_cmap <- sum(analysis$known_drugs_available_in_cmap_count, na.rm=TRUE)
pairs_in_tahoe <- sum(analysis$known_drugs_available_in_tahoe_count, na.rm=TRUE)

# For available pairs in both platforms, we need to identify which diseases have both
available_both <- analysis %>%
  filter(known_drugs_available_in_cmap_count > 0 & 
         known_drugs_available_in_tahoe_count > 0) %>%
  summarize(total = sum(pmin(known_drugs_available_in_cmap_count, 
                             known_drugs_available_in_tahoe_count))) %>%
  pull(total)

# For recovered pairs
found_in_tahoe <- sum(analysis$tahoe_in_known_count, na.rm=TRUE)
found_in_cmap <- sum(analysis$cmap_in_known_count, na.rm=TRUE)
found_in_both <- sum(analysis$common_in_known_count, na.rm=TRUE)

# Calculate only and both for recovered
recovered_cmap_only <- found_in_cmap - found_in_both
recovered_tahoe_only <- found_in_tahoe - found_in_both
recovered_both <- found_in_both

# Calculate available only
available_cmap_only <- pairs_in_cmap - available_both
available_tahoe_only <- pairs_in_tahoe - available_both

cat("AVAILABLE KNOWN DRUG PAIRS:\n")
cat("  CMap only:", available_cmap_only, "\n")
cat("  Tahoe only:", available_tahoe_only, "\n")
cat("  Both platforms:", available_both, "\n")
cat("  Total CMap:", pairs_in_cmap, "\n")
cat("  Total Tahoe:", pairs_in_tahoe, "\n\n")

cat("RECOVERED KNOWN DRUG PAIRS:\n")
cat("  CMap only:", recovered_cmap_only, "\n")
cat("  Tahoe only:", recovered_tahoe_only, "\n")
cat("  Both platforms:", recovered_both, "\n")
cat("  Total CMap:", found_in_cmap, "\n")
cat("  Total Tahoe:", found_in_tahoe, "\n\n")

# ============================================================================
# VENN DIAGRAM 1: AVAILABLE KNOWN DRUG PAIRS
# ============================================================================

cat("Creating Venn Diagram 1: Available Known Drug Pairs...\n")

png(file.path(figures_dir, "venn_available_known_drugs.png"),
    width = 1000, height = 900, res = 150, bg = "white")

VennDiagram::draw.pairwise.venn(
  area1 = pairs_in_cmap,
  area2 = pairs_in_tahoe,
  cross.area = available_both,
  category = c("CMap", "Tahoe"),
  lwd = 2.5,
  fill = c(COLOR_CMAP, COLOR_TAHOE),
  alpha = c(0.4, 0.4),
  cex = 1.8,
  cat.cex = 1.6,
  cat.col = c(COLOR_CMAP, COLOR_TAHOE),
  main = "Available Known Drug Pairs Across Platforms",
  sub = "Disease-drug pairs where both platforms have the signature"
)

dev.off()

cat("✓ Venn Diagram 1 (Available) complete\n\n")

# ============================================================================
# VENN DIAGRAM 2: RECOVERED KNOWN DRUG PAIRS
# ============================================================================

cat("Creating Venn Diagram 2: Recovered Known Drug Pairs...\n")

png(file.path(figures_dir, "venn_recovered_known_drugs.png"),
    width = 1000, height = 900, res = 150, bg = "white")

VennDiagram::draw.pairwise.venn(
  area1 = found_in_cmap,
  area2 = found_in_tahoe,
  cross.area = recovered_both,
  category = c("CMap", "Tahoe"),
  lwd = 2.5,
  fill = c(COLOR_CMAP, COLOR_TAHOE),
  alpha = c(0.4, 0.4),
  cex = 1.8,
  cat.cex = 1.6,
  cat.col = c(COLOR_CMAP, COLOR_TAHOE),
  main = "Recovered Known Drug Pairs in Top Hits",
  sub = "Known drug pairs found in the top-ranked candidates"
)

dev.off()

cat("✓ Venn Diagram 2 (Recovered) complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== VENN DIAGRAMS COMPLETE ===\n")
cat("\nFiles created:\n")
cat("  1. venn_available_known_drugs.png\n")
cat("  2. venn_recovered_known_drugs.png\n")
cat("\nColor Scheme:\n")
cat("  CMap (Orange): #F39C12\n")
cat("  Tahoe (Blue):  #5DADE2\n")
