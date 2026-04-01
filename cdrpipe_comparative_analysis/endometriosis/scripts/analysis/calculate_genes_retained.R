#!/usr/bin/env Rscript
# Calculate exact genes retained for 6 Tomiko signatures at threshold: 80

library(dplyr)

# Disease signature directory
disease_dir <- "endometriosis/data/tomiko_v3_signatures"

# Tomiko signatures
tomiko_files <- c(
  "tomiko_dvc_esesamples_signature.csv",
  "tomiko_dvc_msesamples_signature.csv",
  "tomiko_dvc_pesamples_signature.csv",
  "tomiko_dvc_unstratified_signature.csv",
  "tomiko_stages_i_ii_vs_control_signature.csv",
  "tomiko_stages_iii_iv_vs_control_signature.csv"
)

cat("\n=== GENES RETAINED AT THRESHOLD: 85 (TOP 15%) ===\n\n")

results <- data.frame()

for (file in tomiko_files) {
  filepath <- file.path(disease_dir, file)
  
  if (!file.exists(filepath)) {
    cat(sprintf("⚠️  File not found: %s\n", file))
    next
  }
  
  # Read signature
  sig <- read.csv(filepath, stringsAsFactors = FALSE)
  
  # Get total genes
  total_genes <- nrow(sig)
  
  # Calculate 85th percentile of |logFC|
  logfc_vals <- abs(sig$logfc_dz)
  percentile_80 <- quantile(logfc_vals, probs = 0.85)
  
  # Count genes >= 80th percentile
  retained_genes <- sum(logfc_vals >= percentile_80)
  
  # Percentage retained
  pct_retained <- (retained_genes / total_genes) * 100
  
  # Signature name
  sig_name <- gsub(".csv", "", file)
  
  cat(sprintf("%-30s  Total: %4d  →  Retained: %4d  (%.1f%%)\n", 
              sig_name, total_genes, retained_genes, pct_retained))
  
  results <- rbind(results, data.frame(
    signature = sig_name,
    total_genes = total_genes,
    retained_genes = retained_genes,
    percentile_cutoff = round(percentile_80, 3),
    pct_retained = round(pct_retained, 1)
  ))
}

cat("\n")
cat(sprintf("Total genes across all 6 signatures: %d\n", sum(results$total_genes)))
cat(sprintf("Total retained genes: %d\n", sum(results$retained_genes)))
cat(sprintf("Average retention per signature: %.0f genes\n", mean(results$retained_genes)))
cat(sprintf("Median retention per signature: %.0f genes\n", median(results$retained_genes)))
cat("\n")

# Save summary
out_file <- "endometriosis/data/tomiko_signature_processing_workspace/genes_retained_threshold85.csv"
write.csv(results, out_file, row.names = FALSE)
cat(sprintf("Summary saved to: %s\n", out_file))
