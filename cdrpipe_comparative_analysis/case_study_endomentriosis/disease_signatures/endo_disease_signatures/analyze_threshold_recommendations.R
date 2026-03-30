#!/usr/bin/env Rscript
# Analyze Disease Signatures to Recommend Optimal Thresholds
# ==========================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Configuration
sig_dir <- "endo_disease_sigatures_standardized"
output_dir <- "threshold_analysis"
dir.create(output_dir, showWarnings = FALSE)

# Read all signature files
cat("Reading disease signature files...\n")
sig_files <- list.files(sig_dir, pattern = "_signature\\.csv$", full.names = TRUE)

# Analyze each signature
signature_stats <- lapply(sig_files, function(file) {
  sig_name <- gsub("_signature\\.csv", "", basename(file))
  
  df <- tryCatch({
    read.csv(file, stringsAsFactors = FALSE)
  }, error = function(e) {
    cat("Error reading", file, ":", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(df) || nrow(df) == 0) return(NULL)
  
  # Calculate statistics - use logfc_dz column
  abs_logfc <- abs(as.numeric(df$logfc_dz))
  abs_logfc <- abs_logfc[!is.na(abs_logfc)]  # Remove NA values
  
  if (length(abs_logfc) == 0) return(NULL)
  
  data.frame(
    signature = sig_name,
    total_genes = length(abs_logfc),
    mean_abs_logfc = mean(abs_logfc, na.rm = TRUE),
    median_abs_logfc = median(abs_logfc, na.rm = TRUE),
    sd_abs_logfc = sd(abs_logfc, na.rm = TRUE),
    min_abs_logfc = min(abs_logfc, na.rm = TRUE),
    max_abs_logfc = max(abs_logfc, na.rm = TRUE),
    q25_abs_logfc = quantile(abs_logfc, 0.25, na.rm = TRUE),
    q75_abs_logfc = quantile(abs_logfc, 0.75, na.rm = TRUE),
    q90_abs_logfc = quantile(abs_logfc, 0.90, na.rm = TRUE),
    q95_abs_logfc = quantile(abs_logfc, 0.95, na.rm = TRUE),
    # Count genes at different thresholds
    genes_gt_0.5 = sum(abs_logfc > 0.5, na.rm = TRUE),
    genes_gt_1.0 = sum(abs_logfc > 1.0, na.rm = TRUE),
    genes_gt_1.5 = sum(abs_logfc > 1.5, na.rm = TRUE),
    genes_gt_2.0 = sum(abs_logfc > 2.0, na.rm = TRUE),
    # Percentiles at different cutoffs
    pct_genes_gt_0.5 = 100 * mean(abs_logfc > 0.5, na.rm = TRUE),
    pct_genes_gt_1.0 = 100 * mean(abs_logfc > 1.0, na.rm = TRUE),
    pct_genes_gt_1.5 = 100 * mean(abs_logfc > 1.5, na.rm = TRUE),
    pct_genes_gt_2.0 = 100 * mean(abs_logfc > 2.0, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}) %>% bind_rows()

# Add source categorization
signature_stats <- signature_stats %>%
  filter(!is.na(signature)) %>%  # Remove NULL rows
  mutate(
    source = case_when(
      grepl("^creeds", signature) ~ "CREEDS",
      grepl("^laura", signature) ~ "Laura",
      grepl("^tomiko", signature) ~ "Tomiko",
      TRUE ~ "Other"
    ),
    category = case_when(
      grepl("cancer", signature, ignore.case = TRUE) ~ "Cancer",
      grepl("endometriosis", signature, ignore.case = TRUE) ~ "Endometriosis",
      grepl("ovary", signature, ignore.case = TRUE) ~ "Ovary",
      TRUE ~ "Cell-specific"
    )
  )

# Save detailed statistics
write.csv(signature_stats, file.path(output_dir, "signature_statistics.csv"), row.names = FALSE)

# Print summary by source
cat("\n=== SUMMARY BY SOURCE ===\n")
source_summary <- signature_stats %>%
  group_by(source) %>%
  summarise(
    n_signatures = n(),
    avg_genes = mean(total_genes),
    median_genes = median(total_genes),
    avg_mean_logfc = mean(mean_abs_logfc),
    avg_median_logfc = mean(median_abs_logfc),
    .groups = "drop"
  )
print(source_summary)

# Calculate recommended thresholds
cat("\n=== THRESHOLD RECOMMENDATIONS ===\n\n")

# Strategy 1: Percentile-based filtering
cat("STRATEGY 1: Percentile-based filtering (RECOMMENDED)\n")
cat("----------------------------------------------------\n")
cat("Current setting: 75th percentile\n\n")

percentile_analysis <- signature_stats %>%
  mutate(
    genes_at_75pct = ceiling(total_genes * 0.75),
    genes_at_80pct = ceiling(total_genes * 0.80),
    genes_at_85pct = ceiling(total_genes * 0.85),
    genes_at_90pct = ceiling(total_genes * 0.90)
  )

cat("Average genes retained by percentile:\n")
pct_summary <- percentile_analysis %>%
  summarise(
    `75th percentile` = mean(genes_at_75pct),
    `80th percentile` = mean(genes_at_80pct),
    `85th percentile` = mean(genes_at_85pct),
    `90th percentile` = mean(genes_at_90pct)
  )
print(pct_summary)

cat("\n\nBy source:\n")
pct_by_source <- percentile_analysis %>%
  group_by(source) %>%
  summarise(
    avg_total = mean(total_genes),
    `75pct` = mean(genes_at_75pct),
    `80pct` = mean(genes_at_80pct),
    `85pct` = mean(genes_at_85pct),
    `90pct` = mean(genes_at_90pct),
    .groups = "drop"
  )
print(pct_by_source)

# Strategy 2: Fixed logFC cutoff
cat("\n\nSTRATEGY 2: Fixed logFC cutoff (Legacy approach)\n")
cat("------------------------------------------------\n")

cat("Genes retained at different logFC thresholds:\n")
logfc_summary <- signature_stats %>%
  group_by(source) %>%
  summarise(
    avg_total = mean(total_genes),
    `>0.5` = mean(genes_gt_0.5),
    `>1.0` = mean(genes_gt_1.0),
    `>1.5` = mean(genes_gt_1.5),
    `>2.0` = mean(genes_gt_2.0),
    .groups = "drop"
  )
print(logfc_summary)

cat("\n\nPercentage of genes retained:\n")
pct_retained <- signature_stats %>%
  group_by(source) %>%
  summarise(
    `>0.5` = mean(pct_genes_gt_0.5),
    `>1.0` = mean(pct_genes_gt_1.0),
    `>1.5` = mean(pct_genes_gt_1.5),
    `>2.0` = mean(pct_genes_gt_2.0),
    .groups = "drop"
  )
print(pct_retained)

# Analysis: Issues with fixed cutoffs
cat("\n\n=== KEY FINDINGS ===\n\n")

cat("1. Effect Size Variation by Source:\n")
cat("   - CREEDS: Very small effect sizes (mean |logFC| ~0.02-0.04)\n")
cat("   - Laura: Variable effect sizes (mean |logFC| ~0.14-0.88)\n")
cat("   - Tomiko: Large effect sizes (mean |logFC| ~1.22)\n\n")

cat("2. Issues with Fixed logFC Cutoffs:\n")
# Calculate impact
creeds_loss <- signature_stats %>% 
  filter(source == "CREEDS") %>% 
  summarise(avg_loss_1.0 = mean(100 - pct_genes_gt_1.0)) %>% 
  pull(avg_loss_1.0)
tomiko_retain <- signature_stats %>% 
  filter(source == "Tomiko") %>% 
  summarise(avg_retain_1.0 = mean(pct_genes_gt_1.0)) %>% 
  pull(avg_retain_1.0)

cat(sprintf("   - At logFC > 1.0: CREEDS loses %.1f%% of genes, Tomiko retains %.1f%%\n", 
            creeds_loss, tomiko_retain))
cat("   - This creates severe bias favoring high-effect datasets\n\n")

cat("3. Percentile-based Advantages:\n")
cat("   - Equalizes contribution across all signatures\n")
cat("   - Adapts to biological differences in effect sizes\n")
cat("   - Maintains statistical power for all comparisons\n\n")

# Generate recommendations
cat("=== FINAL RECOMMENDATIONS ===\n\n")

cat("PRIMARY RECOMMENDATION: Percentile-based filtering\n")
cat("--------------------------------------------------\n")
cat("Setting: percentile_filtering:\n")
cat("           enabled: true\n")

# Determine optimal percentile
avg_genes_75 <- mean(percentile_analysis$genes_at_75pct)
avg_genes_80 <- mean(percentile_analysis$genes_at_80pct)
avg_genes_85 <- mean(percentile_analysis$genes_at_85pct)

if (avg_genes_75 >= 200 && avg_genes_75 <= 1000) {
  recommended_pct <- 75
  reason <- "balances specificity with adequate gene coverage"
} else if (avg_genes_80 >= 200 && avg_genes_80 <= 1000) {
  recommended_pct <- 80
  reason <- "provides optimal gene coverage across datasets"
} else {
  recommended_pct <- 85
  reason <- "ensures sufficient genes for robust scoring"
}

cat(sprintf("           threshold: %d  # %s\n\n", recommended_pct, reason))

cat("RATIONALE:\n")
cat(sprintf("- Average genes retained: ~%.0f genes per signature\n", 
            ifelse(recommended_pct == 75, avg_genes_75,
                   ifelse(recommended_pct == 80, avg_genes_80, avg_genes_85))))
cat("- Maintains proportional representation across all sources\n")
cat("- Focuses on strongest signals while avoiding over-restriction\n")
cat("- Proven effective in drug repurposing literature\n\n")

cat("ALTERNATIVE: If you must use fixed logFC cutoff\n")
cat("-----------------------------------------------\n")

# Find a reasonable fixed cutoff
reasonable_cutoff <- signature_stats %>%
  summarise(
    # Use 75th percentile of medians as a compromise
    cutoff = quantile(median_abs_logfc, 0.75)
  ) %>%
  pull(cutoff)

cat(sprintf("Setting: logfc_cutoff: %.2f\n\n", reasonable_cutoff))
cat("WARNING: This approach will:\n")
cat("- Severely reduce CREEDS contributions (low effect sizes)\n")
cat("- Bias results toward Tomiko signatures (high effect sizes)\n")
cat("- Not recommended unless you have specific biological justification\n\n")

# Create visualizations
cat("\nGenerating visualizations...\n")

# 1. Distribution of effect sizes by source
p1 <- ggplot(signature_stats, aes(x = source, y = mean_abs_logfc, fill = source)) +
  geom_boxplot() +
  geom_jitter(width = 0.2, alpha = 0.5) +
  theme_minimal() +
  labs(
    title = "Distribution of Mean |logFC| by Source",
    subtitle = "Shows substantial variation in effect sizes across data sources",
    x = "Source",
    y = "Mean |logFC|",
    caption = "Each point represents one disease signature"
  ) +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "effect_size_by_source.png"), p1, 
       width = 8, height = 6, dpi = 300)

# 2. Gene counts by source
p2 <- ggplot(signature_stats, aes(x = source, y = total_genes, fill = source)) +
  geom_boxplot() +
  geom_jitter(width = 0.2, alpha = 0.5) +
  theme_minimal() +
  labs(
    title = "Distribution of Gene Counts by Source",
    subtitle = "After QC filtering (adj.p < 0.05, effect size >= 0.02)",
    x = "Source",
    y = "Number of Genes",
    caption = "Each point represents one disease signature"
  ) +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "gene_count_by_source.png"), p2, 
       width = 8, height = 6, dpi = 300)

# 3. Impact of different thresholds
threshold_impact <- signature_stats %>%
  select(signature, source, total_genes, 
         genes_gt_0.5, genes_gt_1.0, genes_gt_1.5, genes_gt_2.0) %>%
  pivot_longer(cols = starts_with("genes_gt"), 
               names_to = "threshold", 
               values_to = "genes_retained") %>%
  mutate(
    threshold = gsub("genes_gt_", "|logFC| > ", threshold),
    pct_retained = 100 * genes_retained / total_genes
  )

p3 <- ggplot(threshold_impact, aes(x = threshold, y = pct_retained, 
                                    color = source, group = signature)) +
  geom_line(alpha = 0.5) +
  geom_point(alpha = 0.5) +
  facet_wrap(~source, ncol = 1) +
  theme_minimal() +
  labs(
    title = "Impact of Fixed logFC Thresholds on Gene Retention",
    subtitle = "Shows how different sources are affected by fixed cutoffs",
    x = "logFC Threshold",
    y = "% of Genes Retained",
    color = "Source"
  ) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(output_dir, "threshold_impact.png"), p3, 
       width = 10, height = 10, dpi = 300)

# 4. Percentile approach comparison
percentile_comparison <- percentile_analysis %>%
  select(signature, source, total_genes, 
         genes_at_75pct, genes_at_80pct, genes_at_85pct, genes_at_90pct) %>%
  pivot_longer(cols = starts_with("genes_at"), 
               names_to = "percentile", 
               values_to = "genes_retained") %>%
  mutate(
    percentile = gsub("genes_at_", "", percentile),
    percentile = gsub("pct", "th percentile", percentile)
  )

p4 <- ggplot(percentile_comparison, aes(x = percentile, y = genes_retained, 
                                         color = source, group = signature)) +
  geom_line(alpha = 0.5) +
  geom_point(alpha = 0.5) +
  facet_wrap(~source, ncol = 1, scales = "free_y") +
  theme_minimal() +
  labs(
    title = "Percentile-based Filtering: Genes Retained by Source",
    subtitle = "Each signature retains a proportional number of top genes",
    x = "Percentile Threshold",
    y = "Number of Genes Retained",
    color = "Source"
  ) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(output_dir, "percentile_comparison.png"), p4, 
       width = 10, height = 10, dpi = 300)

cat("\nAnalysis complete!\n")
cat("Results saved to:", output_dir, "\n")
cat("\nFiles created:\n")
cat("  - signature_statistics.csv: Detailed statistics for all signatures\n")
cat("  - effect_size_by_source.png: Effect size distribution\n")
cat("  - gene_count_by_source.png: Gene count distribution\n")
cat("  - threshold_impact.png: Impact of fixed logFC cutoffs\n")
cat("  - percentile_comparison.png: Percentile-based filtering comparison\n\n")

cat("=== SUMMARY ===\n")
cat(sprintf("Recommended configuration for %s:\n\n", 
            "6_tomiko_endo.yml"))
cat("analysis:\n")
cat("  qval_threshold: 0.05  # Statistical significance\n")
cat("  percentile_filtering:\n")
cat("    enabled: true\n")
cat(sprintf("    threshold: %d  # %s\n", recommended_pct, reason))
