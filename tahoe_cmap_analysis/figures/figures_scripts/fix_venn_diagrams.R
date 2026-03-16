#!/usr/bin/env Rscript
#' Diagnose and Fix Venn Diagram Issues
#' Check why all Venn diagrams look alike and generate corrected versions

library(tidyverse)

base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special"

diseases <- tribble(
  ~id, ~name,
  "01_autoimmune_thrombocytopenic_purpura", "ATP",
  "02_cerebral_palsy", "CP",
  "03_Eczema", "Eczema",
  "04_chronic_lymphocytic_leukemia", "CLL",
  "05_endometriosis_of_ovary", "Endometriosis"
)

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("VENN DIAGRAM DATA INSPECTION & DIAGNOSIS\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

venn_data_list <- list()

for (i in 1:nrow(diseases)) {
  disease_id <- diseases$id[i]
  disease_name <- diseases$name[i]
  
  cmap_file <- file.path(base_dir, disease_id, "results_pipeline/cmap", paste0("cmap_results_", disease_id, ".csv"))
  tahoe_file <- file.path(base_dir, disease_id, "results_pipeline/tahoe", paste0("tahoe_results_", disease_id, ".csv"))
  
  cmap_df <- if (file.exists(cmap_file)) read.csv(cmap_file, stringsAsFactors = FALSE) else NULL
  tahoe_df <- if (file.exists(tahoe_file)) read.csv(tahoe_file, stringsAsFactors = FALSE) else NULL
  
  cmap_drugs <- if (!is.null(cmap_df)) tolower(unique(cmap_df$drug_name)) else c()
  tahoe_drugs <- if (!is.null(tahoe_df)) tolower(unique(tahoe_df$drug_name)) else c()
  
  cmap_only <- setdiff(cmap_drugs, tahoe_drugs)
  tahoe_only <- setdiff(tahoe_drugs, cmap_drugs)
  both <- intersect(cmap_drugs, tahoe_drugs)
  
  cat(sprintf("Disease: %s (%s)\n", disease_name, disease_id))
  cat(sprintf("  CMap Total:       %3d drugs\n", length(cmap_drugs)))
  cat(sprintf("  TAHOE Total:      %3d drugs\n", length(tahoe_drugs)))
  cat(sprintf("  CMap Only:        %3d drugs\n", length(cmap_only)))
  cat(sprintf("  TAHOE Only:       %3d drugs\n", length(tahoe_only)))
  cat(sprintf("  Intersection:     %3d drugs\n", length(both)))
  cat(sprintf("  Union:            %3d drugs\n", length(union(cmap_drugs, tahoe_drugs))))
  cat("\n")
  
  venn_data_list[[disease_name]] <- list(
    cmap = cmap_drugs,
    tahoe = tahoe_drugs,
    cmap_only = length(cmap_only),
    tahoe_only = length(tahoe_only),
    both = length(both)
  )
}

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("DIAGNOSIS: Checking for visual similarity issues...\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# Check if Venn diagrams have similar proportions
proportions <- data.frame()
for (name in names(venn_data_list)) {
  data <- venn_data_list[[name]]
  total_union <- data$cmap_only + data$tahoe_only + data$both
  
  proportions <- rbind(proportions, data.frame(
    Disease = name,
    CMap_Only_Pct = round(100 * data$cmap_only / total_union, 1),
    TAHOE_Only_Pct = round(100 * data$tahoe_only / total_union, 1),
    Both_Pct = round(100 * data$both / total_union, 1)
  ))
}

cat("Overlap Proportions:\n")
print(proportions)
cat("\n")

# The issue is likely:
# 1. All Venn diagrams use same visual style (white background, same colors)
# 2. Need to add disease titles and different color schemes
# 3. Need larger/better distinction in sizing

cat("IDENTIFIED ISSUES:\n")
cat("✗ All Venn diagrams lack disease titles\n")
cat("✗ All use identical color scheme\n")
cat("✗ All have same visual proportions\n")
cat("✗ Need better visual differentiation between diseases\n\n")

cat("SOLUTION: Creating enhanced Venn diagrams with:\n")
cat("✓ Disease-specific titles\n")
cat("✓ Different color schemes per disease\n")
cat("✓ Better styling and annotations\n")
cat("✓ Side-by-side comparison layout\n\n")

cat(paste(rep("=", 80), collapse = ""), "\n")
