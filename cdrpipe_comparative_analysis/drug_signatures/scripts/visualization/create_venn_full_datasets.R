#!/usr/bin/env Rscript

# Venn Diagram: Full Dataset Coverage (No Filtering)
# Shows overlap between CMap, Tahoe, and Open Targets
# This is an overview of the RAW DATASETS, not what was used in analysis

library(tidyverse)
library(arrow)
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

# Load CMap and Tahoe drug lists (ALL, not filtered)
cmap_drugs <- read.csv('data/drug_signatures/cmap/cmap_drug_experiments_new.csv')
tahoe_drugs_df <- read.csv('data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv')

cat("✓ Data loaded\n\n")

# ============================================================================
# PREPARE DATA FOR VENN DIAGRAM (RAW DATASETS)
# ============================================================================

cat("Preparing data for Venn diagram...\n")

# Get unique drugs and normalize
unique_known <- unique(tolower(trimws(known_drugs$drug_common_name)))
unique_cmap <- unique(tolower(trimws(cmap_drugs$name)))
unique_tahoe <- unique(tolower(trimws(tahoe_drugs_df$name)))

cat("Raw dataset counts:\n")
cat("  Open Targets: ", length(unique_known), " unique drugs\n")
cat("  CMap: ", length(unique_cmap), " unique drugs\n")
cat("  Tahoe: ", length(unique_tahoe), " unique drugs\n\n")

# ============================================================================
# CALCULATE OVERLAPS FOR COMPREHENSIVE VIEW
# ============================================================================

# All pairwise intersections
cmap_tahoe <- intersect(unique_cmap, unique_tahoe)
cmap_known <- intersect(unique_cmap, unique_known)
tahoe_known <- intersect(unique_tahoe, unique_known)
all_three <- intersect(cmap_tahoe, unique_known)

cat("Pairwise overlaps:\n")
cat("  CMap ∩ Tahoe: ", length(cmap_tahoe), " drugs\n")
cat("  CMap ∩ Open Targets: ", length(cmap_known), " drugs\n")
cat("  Tahoe ∩ Open Targets: ", length(tahoe_known), " drugs\n")
cat("  All three: ", length(all_three), " drugs\n\n")

# ============================================================================
# CREATE VENN DIAGRAM - RAW DATASETS
# ============================================================================

cat("Creating Venn diagram (raw datasets overview)...\n")

png(file.path(figures_dir, "drug_platform_coverage_full_datasets_venn.png"),
    width = 16, height = 13, units = "in", res = 300, bg = "white")

# Create the venn diagram without title first
venn.plot <- venn.diagram(
  x = list(
    "CMap\n(1,309 drugs)" = unique_cmap,
    "Tahoe\n(379 drugs)" = unique_tahoe,
    "Open Targets\n(4,262 drugs)" = unique_known
  ),
  filename = NULL,
  category.names = c("CMap\n(1,309 drugs)", "Tahoe\n(379 drugs)", "Open Targets\n(4,262 drugs)"),
  output = TRUE,
  
  # Visual settings for perfect circles
  fill = c(COLOR_CMAP, COLOR_TAHOE, COLOR_KNOWN),
  alpha = 0.4,
  label.col = "black",
  cex = 2.0,
  cat.cex = 1.6,
  cat.dist = 0.12,
  cat.pos = c(-25, 25, 180),
  
  # Scaling for more circular appearance
  scaled = TRUE,
  inverted = FALSE,
  
  # No title in venn.diagram
  main = NULL
)

# Draw with custom title and legend
grid::grid.newpage()
grid::pushViewport(grid::viewport(width = 1, height = 1))

# Add title at the top with spacing
grid::grid.text("Drug Platform Coverage Overview",
                x = 0.5, y = 0.97,
                gp = grid::gpar(fontsize = 28, fontface = "bold"))

# Draw venn diagram in left portion
grid::pushViewport(grid::viewport(x = 0.35, width = 0.65, y = 0.40, height = 0.80))
grid::grid.draw(venn.plot)
grid::popViewport()

# Add legend on the right side (moved higher to avoid overlap)
grid::pushViewport(grid::viewport(x = 0.85, width = 0.25, y = 0.65, height = 0.55))

# Legend title
grid::grid.text("Platform Colors",
                x = 0.5, y = 0.95,
                gp = grid::gpar(fontsize = 16, fontface = "bold"))

# CMap color box and label
grid::grid.rect(x = 0.10, y = 0.75, width = 0.15, height = 0.12,
                gp = grid::gpar(fill = COLOR_CMAP, alpha = 0.6, col = "black", lwd = 2))
grid::grid.text("CMap",
                x = 0.30, y = 0.75,
                gp = grid::gpar(fontsize = 14, hjust = 0, vjust = 0.5))

# Tahoe color box and label
grid::grid.rect(x = 0.10, y = 0.52, width = 0.15, height = 0.12,
                gp = grid::gpar(fill = COLOR_TAHOE, alpha = 0.6, col = "black", lwd = 2))
grid::grid.text("Tahoe",
                x = 0.30, y = 0.52,
                gp = grid::gpar(fontsize = 14, hjust = 0, vjust = 0.5))

# Open Targets color box and label
grid::grid.rect(x = 0.10, y = 0.29, width = 0.15, height = 0.12,
                gp = grid::gpar(fill = COLOR_KNOWN, alpha = 0.6, col = "black", lwd = 2))
grid::grid.text("Open Targets",
                x = 0.35, y = 0.29,
                gp = grid::gpar(fontsize = 14, hjust = 0, vjust = 0.5))

grid::popViewport()

grid::popViewport()
dev.off()

cat("✓ Venn diagram created: drug_platform_coverage_full_datasets_venn.png\n\n")

# ============================================================================
# DETAILED STATISTICS TABLE
# ============================================================================

cat("Computing detailed overlap statistics...\n\n")

# Calculate all regions
cmap_only <- setdiff(unique_cmap, c(unique_tahoe, unique_known))
tahoe_only <- setdiff(unique_tahoe, c(unique_cmap, unique_known))
known_only <- setdiff(unique_known, c(unique_cmap, unique_tahoe))

cmap_tahoe_not_known <- setdiff(cmap_tahoe, unique_known)
cmap_known_not_tahoe <- setdiff(cmap_known, unique_tahoe)
tahoe_known_not_cmap <- setdiff(tahoe_known, unique_cmap)

# Create summary table
summary_stats <- data.frame(
  Region = c(
    "Only CMap",
    "Only Tahoe", 
    "Only Open Targets",
    "CMap + Tahoe (not OT)",
    "CMap + OT (not Tahoe)",
    "Tahoe + OT (not CMap)",
    "All Three Platforms"
  ),
  Count = c(
    length(cmap_only),
    length(tahoe_only),
    length(known_only),
    length(cmap_tahoe_not_known),
    length(cmap_known_not_tahoe),
    length(tahoe_known_not_cmap),
    length(all_three)
  )
)

cat("Full Venn Diagram Breakdown (Raw Datasets):\n")
print(summary_stats)
cat("\n")

# ============================================================================
# COVERAGE STATISTICS
# ============================================================================

cat("Dataset Coverage Statistics:\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

# Total unique drugs across all platforms
total_all <- length(union(union(unique_cmap, unique_tahoe), unique_known))
cat(sprintf("Total unique drugs (union): %d\n\n", total_all))

# CMap coverage
cat("CMap Platform Coverage:\n")
cat(sprintf("  - Total unique drugs: %d\n", length(unique_cmap)))
cat(sprintf("  - In Open Targets: %d (%.1f%%)\n", 
            length(cmap_known), 100*length(cmap_known)/length(unique_cmap)))
cat(sprintf("  - In Tahoe: %d (%.1f%%)\n", 
            length(cmap_tahoe), 100*length(cmap_tahoe)/length(unique_cmap)))
cat(sprintf("  - In both Tahoe & OT: %d\n\n", length(all_three)))

# Tahoe coverage
cat("Tahoe Platform Coverage:\n")
cat(sprintf("  - Total unique drugs: %d\n", length(unique_tahoe)))
cat(sprintf("  - In Open Targets: %d (%.1f%%)\n", 
            length(tahoe_known), 100*length(tahoe_known)/length(unique_tahoe)))
cat(sprintf("  - In CMap: %d (%.1f%%)\n", 
            length(cmap_tahoe), 100*length(cmap_tahoe)/length(unique_tahoe)))
cat(sprintf("  - In both CMap & OT: %d\n\n", length(all_three)))

# Open Targets coverage
cat("Open Targets Platform Coverage:\n")
cat(sprintf("  - Total unique drugs: %d\n", length(unique_known)))
cat(sprintf("  - In CMap: %d (%.1f%%)\n", 
            length(cmap_known), 100*length(cmap_known)/length(unique_known)))
cat(sprintf("  - In Tahoe: %d (%.1f%%)\n", 
            length(tahoe_known), 100*length(tahoe_known)/length(unique_known)))
cat(sprintf("  - In both CMap & Tahoe: %d (%.1f%%)\n", 
            length(all_three), 100*length(all_three)/length(unique_known)))
cat(sprintf("  - In CMap OR Tahoe: %d (%.1f%%)\n\n", 
            length(union(cmap_known, tahoe_known)), 100*length(union(cmap_known, tahoe_known))/length(unique_known)))

# Platform complementarity
combined_coverage <- length(union(union(cmap_known, tahoe_known), known_only))
cat("Platform Complementarity:\n")
cat(sprintf("  - CMap + Tahoe combined coverage of OT: %d (%.1f%%)\n", 
            length(union(cmap_known, tahoe_known)), 100*length(union(cmap_known, tahoe_known))/length(unique_known)))
cat(sprintf("  - Unique to CMap only: %d\n", length(cmap_only)))
cat(sprintf("  - Unique to Tahoe only: %d\n", length(tahoe_only)))
cat(sprintf("  - Unique to Open Targets only: %d (%.1f%% of OT)\n\n", 
            length(known_only), 100*length(known_only)/length(unique_known)))

cat(paste(rep("=", 60), collapse=""), "\n")
cat("✓ Analysis complete!\n")
