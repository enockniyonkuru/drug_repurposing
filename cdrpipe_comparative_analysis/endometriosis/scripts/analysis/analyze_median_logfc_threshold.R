#!/usr/bin/env Rscript
# Analyze median logFC distribution to recommend QC threshold

library(dplyr)

stats <- read.csv('threshold_analysis/signature_statistics.csv')

cat('\n=== MEDIAN |logFC| DISTRIBUTION ===\n\n')

# Overall distribution
cat('Overall statistics:\n')
cat(sprintf('  Min:    %.4f\n', min(stats$median_abs_logfc)))
cat(sprintf('  Q1:     %.4f\n', quantile(stats$median_abs_logfc, 0.25)))
cat(sprintf('  Median: %.4f\n', median(stats$median_abs_logfc)))
cat(sprintf('  Q3:     %.4f\n', quantile(stats$median_abs_logfc, 0.75)))
cat(sprintf('  Max:    %.4f\n\n', max(stats$median_abs_logfc)))

# By source
cat('By source:\n')
source_stats <- stats %>%
  group_by(source) %>%
  summarise(
    n = n(),
    min_median = min(median_abs_logfc),
    q1_median = quantile(median_abs_logfc, 0.25),
    median_median = median(median_abs_logfc),
    q3_median = quantile(median_abs_logfc, 0.75),
    max_median = max(median_abs_logfc),
    .groups = 'drop'
  )
print(source_stats)

cat('\n\n=== IMPACT OF DIFFERENT THRESHOLDS ===\n\n')

# Show what would be excluded at different thresholds
thresholds <- c(0.015, 0.02, 0.025, 0.03, 0.05)
for (thresh in thresholds) {
  n_excluded <- sum(stats$median_abs_logfc < thresh)
  pct_excluded <- 100 * n_excluded / nrow(stats)
  excluded_sigs <- stats$signature[stats$median_abs_logfc < thresh]
  
  cat(sprintf('Threshold %.3f:\n', thresh))
  cat(sprintf('  Excluded: %d/%d signatures (%.1f%%)\n', n_excluded, nrow(stats), pct_excluded))
  if (n_excluded > 0) {
    cat('  Would exclude:\n')
    for (sig in excluded_sigs) {
      median_val <- stats$median_abs_logfc[stats$signature == sig]
      source <- stats$source[stats$signature == sig]
      cat(sprintf('    - %s [%s] (median |logFC| = %.4f)\n', sig, source, median_val))
    }
  }
  cat('\n')
}

cat('\n=== LITERATURE STANDARDS ===\n\n')
cat('Common thresholds in drug repurposing studies:\n')
cat('  - 0.01: Very permissive (captures subtle effects)\n')
cat('  - 0.02: Standard for microarray data (used by CREEDS)\n')
cat('  - 0.025-0.03: Conservative (stronger effects only)\n')
cat('  - 0.05+: Very conservative (risk losing real signals)\n\n')

cat('For RNA-seq data (typical range):\n')
cat('  - log2FC > 0.5 (1.4-fold change) = |logFC| ~ 0.5\n')
cat('  - log2FC > 1.0 (2-fold change) = |logFC| ~ 1.0\n\n')

cat('=== RECOMMENDATION ===\n\n')

# Calculate how many are between 0.02 and 0.03
borderline <- sum(stats$median_abs_logfc >= 0.02 & stats$median_abs_logfc < 0.03)
very_low <- sum(stats$median_abs_logfc < 0.02)

cat(sprintf('Your data:\n'))
cat(sprintf('  - %d signatures have median |logFC| < 0.02\n', very_low))
cat(sprintf('  - %d signatures have median |logFC| between 0.02-0.03\n', borderline))
cat(sprintf('  - %d signatures have median |logFC| >= 0.03\n\n', sum(stats$median_abs_logfc >= 0.03)))

if (borderline == 0) {
  cat('KEEP 0.02 threshold:\n')
  cat('  ✓ No signatures fall in borderline range (0.02-0.03)\n')
  cat('  ✓ Standard for microarray studies\n')
  cat('  ✓ Captures biologically meaningful subtle effects\n')
} else {
  cat('Consider threshold based on your data source:\n')
  cat('  - Keep 0.02: If you trust CREEDS/microarray subtle effects\n')
  cat('  - Use 0.025: Slightly more conservative, still includes most data\n')
  cat('  - Use 0.03: More stringent, may lose some real signals\n\n')
  
  # Show specific signatures in question
  borderline_sigs <- stats %>%
    filter(median_abs_logfc >= 0.02 & median_abs_logfc < 0.03) %>%
    select(signature, source, median_abs_logfc, total_genes) %>%
    arrange(median_abs_logfc)
  
  if (nrow(borderline_sigs) > 0) {
    cat('\nSignatures in borderline range (0.02-0.03):\n')
    print(borderline_sigs)
  }
}
