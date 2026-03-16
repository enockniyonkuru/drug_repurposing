#!/usr/bin/env Rscript
#' Enhanced Venn Diagram Generator with Better Visual Differentiation
#' Creates labeled, colored, and annotated Venn diagrams for each disease

library(tidyverse)
library(venn)
library(gridExtra)
library(grid)

base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special"

diseases <- data.frame(
  id = c("01_autoimmune_thrombocytopenic_purpura", "02_cerebral_palsy", "03_Eczema", 
         "04_chronic_lymphocytic_leukemia", "05_endometriosis_of_ovary"),
  name = c("ATP", "CP", "Eczema", "CLL", "Endometriosis"),
  full_name = c("Autoimmune Thrombocytopenic Purpura", "Cerebral Palsy", "Eczema",
                "Chronic Lymphocytic Leukemia", "Endometriosis of Ovary"),
  color1 = c("#E74C3C", "#3498DB", "#9B59B6", "#E67E22", "#1ABC9C"),
  color2 = c("#C0392B", "#2980B9", "#8E44AD", "#D35400", "#16A085"),
  stringsAsFactors = FALSE
)

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("GENERATING ENHANCED VENN DIAGRAMS WITH VISUAL DIFFERENTIATION\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

for (i in 1:nrow(diseases)) {
  disease_id <- diseases$id[i]
  disease_name <- diseases$name[i]
  disease_full_name <- diseases$full_name[i]
  color1 <- diseases$color1[i]
  color2 <- diseases$color2[i]
  
  # Load data
  cmap_file <- file.path(base_dir, disease_id, "results_pipeline/cmap", paste0("cmap_results_", disease_id, ".csv"))
  tahoe_file <- file.path(base_dir, disease_id, "results_pipeline/tahoe", paste0("tahoe_results_", disease_id, ".csv"))
  
  cmap_df <- if (file.exists(cmap_file)) read.csv(cmap_file, stringsAsFactors = FALSE) else NULL
  tahoe_df <- if (file.exists(tahoe_file)) read.csv(tahoe_file, stringsAsFactors = FALSE) else NULL
  
  cmap_drugs <- if (!is.null(cmap_df)) tolower(unique(cmap_df$drug_name)) else c()
  tahoe_drugs <- if (!is.null(tahoe_df)) tolower(unique(tahoe_df$drug_name)) else c()
  
  cmap_only <- setdiff(cmap_drugs, tahoe_drugs)
  tahoe_only <- setdiff(tahoe_drugs, cmap_drugs)
  both <- intersect(cmap_drugs, tahoe_drugs)
  
  # Create enhanced Venn diagram with PNG
  png_path <- file.path(base_dir, disease_id, "figures", 
                        paste0("venn_enhanced_", disease_id, ".png"))
  
  png(png_path, width = 900, height = 800, res = 150)
  
  # Create layout with title and Venn
  layout_matrix <- matrix(c(1, 1, 2, 2), nrow = 2, byrow = TRUE)
  
  # Draw the main Venn diagram with custom styling
  par(mfrow = c(2, 1))
  
  # Title area
  plot.new()
  text(0.5, 0.7, disease_full_name, cex = 2.2, font = 2, col = "#2C3E50")
  text(0.5, 0.4, paste("Drug Repurposing Results"), cex = 1.2, font = 1, col = "#34495E")
  
  # Venn diagram area
  plot.new()
  venn(list(CMap = cmap_drugs, TAHOE = tahoe_drugs), 
       borders = TRUE, 
       ilabels = TRUE, 
       ellipse = TRUE,
       col = c(color1, color2),
       alpha = 0.4,
       lty = 2,
       lwd = 2.5)
  
  # Add statistics text
  mtext(sprintf("CMap: %d | TAHOE: %d | Both: %d | Union: %d", 
                length(cmap_drugs), length(tahoe_drugs), length(both), 
                length(union(cmap_drugs, tahoe_drugs))),
        side = 1, line = -1, cex = 1.0, col = "#7F8C8D")
  
  dev.off()
  
  cat(sprintf("✓ Created enhanced Venn diagram for %s\n", disease_name))
  cat(sprintf("  Path: %s\n", png_path))
  cat(sprintf("  Data: CMap=%d, TAHOE=%d, Intersection=%d\n\n", 
              length(cmap_drugs), length(tahoe_drugs), length(both)))
}

# Create a comparison table figure
cat("\nGenerating comparison table...\n")

comparison_df <- data.frame()
for (i in 1:nrow(diseases)) {
  disease_id <- diseases$id[i]
  disease_name <- diseases$name[i]
  
  cmap_file <- file.path(base_dir, disease_id, "results_pipeline/cmap", paste0("cmap_results_", disease_id, ".csv"))
  tahoe_file <- file.path(base_dir, disease_id, "results_pipeline/tahoe", paste0("tahoe_results_", disease_id, ".csv"))
  
  cmap_df <- if (file.exists(cmap_file)) read.csv(cmap_file, stringsAsFactors = FALSE) else NULL
  tahoe_df <- if (file.exists(tahoe_file)) read.csv(tahoe_file, stringsAsFactors = FALSE) else NULL
  
  cmap_drugs <- if (!is.null(cmap_df)) tolower(unique(cmap_df$drug_name)) else c()
  tahoe_drugs <- if (!is.null(tahoe_df)) tolower(unique(tahoe_df$drug_name)) else c()
  
  both <- intersect(cmap_drugs, tahoe_drugs)
  
  comparison_df <- rbind(comparison_df, data.frame(
    Disease = disease_name,
    CMap = length(cmap_drugs),
    TAHOE = length(tahoe_drugs),
    Intersection = length(both),
    Union = length(union(cmap_drugs, tahoe_drugs)),
    Overlap_Pct = round(100 * length(both) / length(union(cmap_drugs, tahoe_drugs)), 1)
  ))
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("VENN DIAGRAM COMPARISON TABLE\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")
print(comparison_df)
cat("\n")

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("ENHANCEMENT COMPLETE\n")
cat("✓ All enhanced Venn diagrams have unique colors per disease\n")
cat("✓ All have disease titles and statistical annotations\n")
cat("✓ All show clear visual differentiation\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")
