#!/usr/bin/env Rscript

#####################################################################
# COMPARISON: Tomiko e2e_rawdata vs scripts/results/endo_v2
# Compares all 6 signatures
#####################################################################

library(dplyr)

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("COMPARISON: Tomiko e2e_rawdata vs DRpipe endo_v2\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Define file mappings
comparisons <- list(
  list(
    name = "Unstratified",
    tomiko = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/Unstratified/drug_instances_Unstratified.csv",
    drpipe = "~/Desktop/drug_repurposing/scripts/results/endo_v2/CMAP_Endometriosis_Unstratified_Strict_20260121-164307/endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv"
  ),
  list(
    name = "ESE",
    tomiko = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/ESE/drug_instances_ESE.csv",
    drpipe = "~/Desktop/drug_repurposing/scripts/results/endo_v2/CMAP_Endometriosis_ESE_Strict_20260121-160656/endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv"
  ),
  list(
    name = "MSE",
    tomiko = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/MSE/drug_instances_MSE.csv",
    drpipe = "~/Desktop/drug_repurposing/scripts/results/endo_v2/CMAP_Endometriosis_MSE_Strict_20260121-162955/endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv"
  ),
  list(
    name = "PE",
    tomiko = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/PE/drug_instances_PE.csv",
    drpipe = "~/Desktop/drug_repurposing/scripts/results/endo_v2/CMAP_Endometriosis_PE_Strict_20260121-163720/endomentriosis_pe_disease_signature_hits_logFC_1_q<0.00.csv"
  ),
  list(
    name = "IIInIV",
    tomiko = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/IIInIV/drug_instances_IIInIV.csv",
    drpipe = "~/Desktop/drug_repurposing/scripts/results/endo_v2/CMAP_Endometriosis_IIINIV_Strict_20260121-162222/endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv"
  ),
  list(
    name = "InII",
    tomiko = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/InII/drug_instances_InII.csv",
    drpipe = "~/Desktop/drug_repurposing/scripts/results/endo_v2/CMAP_Endometriosis_INII_Strict_20260121-161312/endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv"
  )
)

# Summary dataframe
summary_df <- data.frame()
top20_comparison <- list()

for (comp in comparisons) {
  cat("════════════════════════════════════════════════════════════════\n")
  cat("SIGNATURE:", comp$name, "\n")
  cat("════════════════════════════════════════════════════════════════\n\n")
  
  # Check if files exist
  tomiko_exists <- file.exists(comp$tomiko)
  drpipe_exists <- file.exists(comp$drpipe)
  
  if (!tomiko_exists) {
    cat("  ✗ Tomiko file not found:", comp$tomiko, "\n\n")
    next
  }
  if (!drpipe_exists) {
    cat("  ✗ DRpipe file not found:", comp$drpipe, "\n\n")
    next
  }
  
  # Load data
  tomiko_df <- read.csv(comp$tomiko)
  drpipe_df <- read.csv(comp$drpipe)
  
  # Sort DRpipe by cmap_score (ascending - more negative = better)
  drpipe_df <- drpipe_df[order(drpipe_df$cmap_score), ]
  
  # Get drug names
  tomiko_drugs <- unique(tomiko_df$name)
  drpipe_drugs <- unique(drpipe_df$name)
  
  cat("Total drugs:\n")
  cat("  Tomiko:", length(tomiko_drugs), "\n")
  cat("  DRpipe:", length(drpipe_drugs), "\n\n")
  
  # Overlap
  overlap <- intersect(tomiko_drugs, drpipe_drugs)
  tomiko_only <- setdiff(tomiko_drugs, drpipe_drugs)
  drpipe_only <- setdiff(drpipe_drugs, tomiko_drugs)
  
  cat("Overlap:\n")
  cat("  Common drugs:", length(overlap), "\n")
  cat("  Tomiko only:", length(tomiko_only), "\n")
  cat("  DRpipe only:", length(drpipe_only), "\n")
  cat("  Jaccard index:", round(length(overlap) / length(union(tomiko_drugs, drpipe_drugs)) * 100, 1), "%\n\n")
  
  # Top 20 comparison
  tomiko_top20 <- head(tomiko_df$name, 20)
  drpipe_top20 <- head(drpipe_df$name, 20)
  
  top20_overlap <- intersect(tomiko_top20, drpipe_top20)
  
  cat("Top 20 comparison:\n")
  cat("  Overlap in top 20:", length(top20_overlap), "drugs\n")
  cat("  Common drugs:", paste(top20_overlap, collapse = ", "), "\n\n")
  
  cat("Top 20 - Tomiko:\n")
  for (i in 1:20) {
    marker <- if (tomiko_top20[i] %in% drpipe_top20) "✓" else " "
    cat(sprintf("  %2d. %s %s\n", i, marker, tomiko_top20[i]))
  }
  cat("\n")
  
  cat("Top 20 - DRpipe:\n")
  for (i in 1:20) {
    marker <- if (drpipe_top20[i] %in% tomiko_top20) "✓" else " "
    cat(sprintf("  %2d. %s %s\n", i, marker, drpipe_top20[i]))
  }
  cat("\n")
  
  # Record summary
  summary_df <- rbind(summary_df, data.frame(
    Signature = comp$name,
    Tomiko_Total = length(tomiko_drugs),
    DRpipe_Total = length(drpipe_drugs),
    Overlap = length(overlap),
    Tomiko_Only = length(tomiko_only),
    DRpipe_Only = length(drpipe_only),
    Jaccard_Pct = round(length(overlap) / length(union(tomiko_drugs, drpipe_drugs)) * 100, 1),
    Top20_Overlap = length(top20_overlap)
  ))
  
  top20_comparison[[comp$name]] <- list(
    tomiko = tomiko_top20,
    drpipe = drpipe_top20,
    overlap = top20_overlap
  )
}

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("SUMMARY TABLE\n")
cat("════════════════════════════════════════════════════════════════\n\n")

print(summary_df)

# Save summary
write.csv(summary_df, "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/comparison_summary.csv", row.names = FALSE)

cat("\n✓ Summary saved to: e2e_rawdata/comparison_summary.csv\n\n")
