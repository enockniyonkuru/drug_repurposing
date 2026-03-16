#!/usr/bin/env Rscript
#' Simple diagnostic to understand Venn diagram similarity

base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special"

diseases <- data.frame(
  id = c("01_autoimmune_thrombocytopenic_purpura", "02_cerebral_palsy", "03_Eczema", 
         "04_chronic_lymphocytic_leukemia", "05_endometriosis_of_ovary"),
  name = c("ATP", "CP", "Eczema", "CLL", "Endometriosis"),
  stringsAsFactors = FALSE
)

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("VENN DIAGRAM DATA INSPECTION\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

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
  total_union <- length(union(cmap_drugs, tahoe_drugs))
  
  cat(sprintf("Disease: %s\n", disease_name))
  cat(sprintf("  CMap Total:       %3d\n", length(cmap_drugs)))
  cat(sprintf("  TAHOE Total:      %3d\n", length(tahoe_drugs)))
  cat(sprintf("  CMap Only:        %3d (%5.1f%%)\n", length(cmap_only), 100*length(cmap_only)/total_union))
  cat(sprintf("  TAHOE Only:       %3d (%5.1f%%)\n", length(tahoe_only), 100*length(tahoe_only)/total_union))
  cat(sprintf("  Intersection:     %3d (%5.1f%%)\n", length(both), 100*length(both)/total_union))
  cat(sprintf("  Union:            %3d\n", total_union))
  cat("\n")
}

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("ANALYSIS:\n")
cat("The Venn diagrams may look alike because:\n")
cat("1. They all use the same venn() function with identical styling\n")
cat("2. No disease-specific titles or annotations\n")
cat("3. Same color scheme and layout for all 5 diagrams\n")
cat("4. The visual proportions might be similar across diseases\n\n")

cat("SOLUTION:\n")
cat("Create enhanced Venn diagrams with:\n")
cat("✓ Individual disease titles\n")
cat("✓ Different color palettes per disease\n")
cat("✓ Larger fonts for better visibility\n")
cat("✓ Statistical annotations\n")
cat("✓ Side-by-side comparison figure\n\n")

cat(paste(rep("=", 80), collapse = ""), "\n")
