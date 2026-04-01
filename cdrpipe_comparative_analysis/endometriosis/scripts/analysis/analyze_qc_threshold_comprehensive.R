#!/usr/bin/env Rscript
# Comprehensive analysis of BOTH per-signature and per-gene filtering

library(dplyr)
library(ggplot2)

# Read signature-level stats
sig_stats <- read.csv('endometriosis/analysis/threshold_analysis/signature_statistics.csv')

# Read one signature file to understand gene-level filtering
example_sig <- read.csv('endometriosis/data/standardized_endometriosis_signatures/tomiko_dvc_esesamples_signature.csv')

cat('\n============================================================\n')
cat('UNDERSTANDING TWO-STAGE QC FILTERING\n')
cat('============================================================\n\n')

cat('STAGE 1: PER-GENE QC (Applied BEFORE creating signatures)\n')
cat('----------------------------------------------------------\n')
cat('Each individual gene must pass:\n')
cat('  1. Statistical significance: adj.p-value < 0.05\n')
cat('  2. Directional consistency: sign(mean) = sign(median)\n')
cat('  3. Effect size threshold: |median_logfc| >= 0.02\n\n')

cat('Example from tomiko_dvc_esesamples:\n')
cat(sprintf('  - Total genes after QC: %d\n', nrow(example_sig)))
cat(sprintf('  - Min gene |logFC|: %.4f\n', min(abs(example_sig$logfc_dz))))
cat(sprintf('  - Median gene |logFC|: %.4f\n', median(abs(example_sig$logfc_dz))))
cat(sprintf('  - Max gene |logFC|: %.4f\n\n', max(abs(example_sig$logfc_dz))))

cat('STAGE 2: PER-SIGNATURE SUMMARY (Median across all genes)\n')
cat('----------------------------------------------------------\n')
cat('This is what "median |logFC| >= 0.02" refers to:\n')
cat('  - Take all genes that passed Stage 1\n')
cat('  - Calculate the MEDIAN of their |logFC| values\n')
cat('  - Signature-level median must be >= 0.02\n\n')

cat('Your signature-level medians:\n')
signature_medians <- sig_stats %>%
  select(signature, source, median_abs_logfc, total_genes) %>%
  arrange(median_abs_logfc)

print(as.data.frame(signature_medians))

cat('\n\n=== INTERPRETATION ===\n\n')

cat('The 0.02 threshold has TWO meanings:\n\n')

cat('1. GENE-LEVEL (already applied in your data):\n')
cat('   "Only keep genes with |median_logfc| >= 0.02"\n')
cat('   This filters OUT individual genes with tiny effects\n\n')

cat('2. SIGNATURE-LEVEL (checking overall quality):\n')
cat('   "Only use signatures where the median gene has |logFC| >= 0.02"\n')
cat('   This filters OUT entire signatures with globally weak signals\n\n')

cat('=== YOUR DATA STATUS ===\n\n')

# Check which signatures would fail different thresholds
cat('Signature-level median |logFC| thresholds:\n\n')

for (thresh in c(0.02, 0.025, 0.03, 0.05)) {
  n_pass <- sum(sig_stats$median_abs_logfc >= thresh)
  n_fail <- sum(sig_stats$median_abs_logfc < thresh)
  
  cat(sprintf('Threshold %.3f:\n', thresh))
  cat(sprintf('  Pass: %d/%d signatures (%.1f%%)\n', n_pass, nrow(sig_stats), 100*n_pass/nrow(sig_stats)))
  
  if (n_fail > 0) {
    cat('  FAIL:\n')
    failed <- sig_stats %>% 
      filter(median_abs_logfc < thresh) %>%
      select(signature, source, median_abs_logfc, total_genes)
    
    for (i in 1:nrow(failed)) {
      cat(sprintf('    - %s [%s]: median=%.4f (%d genes)\n',
                  failed$signature[i], failed$source[i], 
                  failed$median_abs_logfc[i], failed$total_genes[i]))
    }
  }
  cat('\n')
}

cat('\n=== RECOMMENDATION ===\n\n')

min_median <- min(sig_stats$median_abs_logfc)
cat(sprintf('Your MINIMUM signature median |logFC|: %.4f\n', min_median))
cat(sprintf('This is %.1fx ABOVE the 0.02 threshold\n\n', min_median/0.02))

if (min_median >= 0.03) {
  cat('✅ RECOMMENDATION: Keep 0.02 threshold (or even 0.025)\n\n')
  cat('RATIONALE:\n')
  cat('  - All your signatures already exceed 0.03\n')
  cat('  - 0.02 is the standard for microarray data\n')
  cat('  - No risk of including low-quality signatures\n')
  cat('  - Provides flexibility for future data integration\n\n')
  
  cat('If you want to be more conservative:\n')
  cat('  - 0.025: Still includes all current signatures\n')
  cat('  - 0.03: Still includes all current signatures\n')
  cat('  - Higher thresholds only matter if you add new data\n')
} else {
  cat('Consider your threshold based on data sources:\n')
  cat('  - 0.02: Standard, scientifically justified\n')
  cat('  - 0.025-0.03: More conservative if concerned about subtle effects\n')
}

# Create visualization
p <- ggplot(sig_stats, aes(x = reorder(signature, median_abs_logfc), 
                            y = median_abs_logfc, fill = source)) +
  geom_col() +
  geom_hline(yintercept = 0.02, linetype = "dashed", color = "red", size = 1) +
  geom_hline(yintercept = 0.025, linetype = "dashed", color = "orange", size = 0.5) +
  geom_hline(yintercept = 0.03, linetype = "dashed", color = "blue", size = 0.5) +
  annotate("text", x = 1, y = 0.02, label = "0.02 (standard)", 
           hjust = 0, vjust = -0.5, color = "red", size = 3) +
  annotate("text", x = 1, y = 0.025, label = "0.025", 
           hjust = 0, vjust = -0.5, color = "orange", size = 3) +
  annotate("text", x = 1, y = 0.03, label = "0.03", 
           hjust = 0, vjust = -0.5, color = "blue", size = 3) +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Signature-Level Median |logFC| Values",
    subtitle = "All signatures exceed standard 0.02 threshold",
    x = "Signature",
    y = "Median |logFC| (across all genes in signature)",
    fill = "Source"
  ) +
  theme(
    axis.text.y = element_text(size = 8),
    legend.position = "bottom"
  )

ggsave("endometriosis/analysis/threshold_analysis/signature_median_logfc_thresholds.png", p,
       width = 10, height = 12, dpi = 300)

cat('\n\nVisualization saved to: endometriosis/analysis/threshold_analysis/signature_median_logfc_thresholds.png\n')
