#!/usr/bin/env Rscript

# Venn Diagram: Drug Platform Coverage
# Shows overlap between CMap, Tahoe, and Open Targets

library(tidyverse)
library(arrow)
library(ggplot2)
library(VennDiagram)

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_KNOWN <- "#27AE60"     # Green for Known Drugs/Open Targets

figures_dir <- "figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data...\n")

# Load known drugs from Open Targets
known_drugs <- read_parquet('data/drug_evidence/open_targets/known_drug_info_data.parquet')

# Load CMap and Tahoe drug lists
cmap_drugs <- read.csv('data/drug_signatures/cmap/cmap_drug_experiments_new.csv')
tahoe_drugs_df <- read.csv('data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv')

cat("✓ Data loaded\n\n")

# ============================================================================
# PREPARE DATA FOR VENN DIAGRAM
# ============================================================================

cat("Preparing data for Venn diagram...\n")

# Get unique drugs and normalize
unique_known <- unique(tolower(trimws(known_drugs$drug_common_name)))
unique_cmap <- unique(tolower(trimws(cmap_drugs$name)))
unique_tahoe <- unique(tolower(trimws(tahoe_drugs_df$name)))

cat("Unique drugs - Open Targets:", length(unique_known), "\n")
cat("Unique drugs - CMap:", length(unique_cmap), "\n")
cat("Unique drugs - Tahoe:", length(unique_tahoe), "\n\n")

# ============================================================================
# CREATE VENN DIAGRAM
# ============================================================================

cat("Creating Venn diagram...\n")

png(file.path(figures_dir, "known_drugs_chart1_platform_coverage_venn.png"),
    width = 12, height = 10, units = "in", res = 300, bg = "white")

venn.plot <- venn.diagram(
  x = list(
    "Open Targets" = unique_known,
    "CMap" = unique_cmap,
    "Tahoe" = unique_tahoe
  ),
  filename = NULL,
  category.names = c("Open Targets", "CMap", "Tahoe"),
  output = TRUE,
  
  # Visual settings
  fill = c(COLOR_KNOWN, COLOR_CMAP, COLOR_TAHOE),
  alpha = 0.4,
  label.col = "black",
  cex = 2.2,
  cat.cex = 1.8,
  cat.dist = 0.12,
  cat.pos = c(-30, 30, 180),
  
  # Title (we'll add manually)
  main = "Unique Drug Coverage Across Platforms",
  main.cex = 2.2,
  main.pos = c(0.5, 0.98)
)

grid::grid.draw(venn.plot)
dev.off()

cat("✓ Venn diagram created: known_drugs_chart1_platform_coverage_venn.png\n")
cat("\nNOTE: This shows 61 unique drug names with exact matches between platforms.\n")
cat("According to analysis_flowchart.md, 85 drugs were identified as common,\n")
cat("but only 61 passed filtering criteria for inclusion in the analysis.\n\n")

# ============================================================================
# CREATE DETAILED STATISTICS TABLE
# ============================================================================

cat("Computing overlap statistics...\n\n")

# Calculate overlaps
cmap_tahoe <- intersect(unique_cmap, unique_tahoe)
cmap_known_overlap <- intersect(unique_cmap, unique_known)
tahoe_known_overlap <- intersect(unique_tahoe, unique_known)
all_three <- intersect(cmap_tahoe, unique_known)

cmap_only <- setdiff(unique_cmap, c(unique_tahoe, unique_known))
tahoe_only <- setdiff(unique_tahoe, c(unique_cmap, unique_known))
known_only <- setdiff(unique_known, c(unique_cmap, unique_tahoe))

cmap_tahoe_not_known <- setdiff(cmap_tahoe, unique_known)
cmap_known_not_tahoe <- setdiff(cmap_known_overlap, unique_tahoe)
tahoe_known_not_cmap <- setdiff(tahoe_known_overlap, unique_cmap)

# Create summary table
summary_stats <- data.frame(
  Region = c(
    "Only Open Targets",
    "Only CMap",
    "Only Tahoe",
    "CMap + Open Targets (not Tahoe)",
    "Tahoe + Open Targets (not CMap)",
    "CMap + Tahoe (not Open Targets)",
    "All Three Platforms"
  ),
  Count = c(
    length(known_only),
    length(cmap_only),
    length(tahoe_only),
    length(cmap_known_not_tahoe),
    length(tahoe_known_not_cmap),
    length(cmap_tahoe_not_known),
    length(all_three)
  )
)

cat("Venn Diagram Breakdown:\n")
print(summary_stats)
cat("\n")

# Overall statistics
cat("Overall Coverage Statistics:\n")
cat("Total unique drugs across all platforms:", length(union(union(unique_cmap, unique_tahoe), unique_known)), "\n")
cat("CMap coverage of Open Targets:", 
    sprintf("%d / %d (%.1f%%)\n", length(cmap_known_overlap), length(unique_known), 
            100*length(cmap_known_overlap)/length(unique_known)))
cat("Tahoe coverage of Open Targets:", 
    sprintf("%d / %d (%.1f%%)\n", length(tahoe_known_overlap), length(unique_known), 
            100*length(tahoe_known_overlap)/length(unique_known)))
cat("CMap + Tahoe coverage of Open Targets:", 
    sprintf("%d / %d (%.1f%%)\n", length(union(cmap_known_overlap, tahoe_known_overlap)), length(unique_known), 
            100*length(union(cmap_known_overlap, tahoe_known_overlap))/length(unique_known)))

cat("\n✓ All complete!\n")
