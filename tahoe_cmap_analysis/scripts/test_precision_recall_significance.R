#!/usr/bin/env Rscript
# Statistical significance tests for precision and recall
# Comparing Tahoe-100M vs CMap
# Matches manuscript methodology: 233 diseases, P>0 filter for recall

library(readxl)
library(dplyr)

# Load the data
file_path <- "tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Convert metrics to numeric
df$tahoe_precision <- suppressWarnings(as.numeric(df$`Tahoe Precision`))
df$cmap_precision <- suppressWarnings(as.numeric(df$`CMAP Precision`))
df$tahoe_recall <- suppressWarnings(as.numeric(df$`Tahoe Recall`))
df$cmap_recall <- suppressWarnings(as.numeric(df$`CMAP Recall`))

# Use ALL data (manuscript says 233 diseases)
data_filtered <- df

# Get precision data (converted to percentage)
tahoe_prec <- data_filtered$tahoe_precision[!is.na(data_filtered$tahoe_precision)] * 100
cmap_prec <- data_filtered$cmap_precision[!is.na(data_filtered$cmap_precision)] * 100

# Get recall data (converted to percentage)
tahoe_rec <- data_filtered$tahoe_recall[!is.na(data_filtered$tahoe_recall)] * 100
cmap_rec <- data_filtered$cmap_recall[!is.na(data_filtered$cmap_recall)] * 100

cat("\n====================================================\n")
cat("PRECISION & RECALL STATISTICAL SIGNIFICANCE ANALYSIS\n")
cat("====================================================\n")

cat("\n=== PRECISION STATISTICS ===\n")
cat(sprintf("TAHOE Precision: n=%d, Mean=%.2f%%, SD=%.2f%%, Median=%.2f%%\n", 
    length(tahoe_prec), mean(tahoe_prec), sd(tahoe_prec), median(tahoe_prec)))
cat(sprintf("CMAP Precision:  n=%d, Mean=%.2f%%, SD=%.2f%%, Median=%.2f%%\n", 
    length(cmap_prec), mean(cmap_prec), sd(cmap_prec), median(cmap_prec)))

cat("\n=== RECALL STATISTICS ===\n")
cat(sprintf("TAHOE Recall: n=%d, Mean=%.2f%%, SD=%.2f%%, Median=%.2f%%\n", 
    length(tahoe_rec), mean(tahoe_rec), sd(tahoe_rec), median(tahoe_rec)))
cat(sprintf("CMAP Recall:  n=%d, Mean=%.2f%%, SD=%.2f%%, Median=%.2f%%\n", 
    length(cmap_rec), mean(cmap_rec), sd(cmap_rec), median(cmap_rec)))

cat("\n=== STATISTICAL TESTS ===\n")

# For precision - Wilcoxon rank-sum test (Mann-Whitney U)
cat("\n--- Precision: Wilcoxon rank-sum test (unpaired) ---\n")
prec_test <- wilcox.test(tahoe_prec, cmap_prec, alternative = "two.sided")
print(prec_test)

# Also Welch t-test for reference
cat("\n--- Precision: Welch t-test (unpaired) ---\n")
prec_ttest <- t.test(tahoe_prec, cmap_prec, alternative = "two.sided")
print(prec_ttest)

# For recall - Wilcoxon rank-sum test (Mann-Whitney U)
cat("\n--- Recall: Wilcoxon rank-sum test (unpaired) ---\n")
rec_test <- wilcox.test(tahoe_rec, cmap_rec, alternative = "two.sided")
print(rec_test)

# Also Welch t-test for reference
cat("\n--- Recall: Welch t-test (unpaired) ---\n")
rec_ttest <- t.test(tahoe_rec, cmap_rec, alternative = "two.sided")
print(rec_ttest)

cat("\n=== SUMMARY ===\n")
cat(sprintf("Precision difference: Wilcoxon p = %.4f, t-test p = %.4f\n", 
    prec_test$p.value, prec_ttest$p.value))
cat(sprintf("Recall difference:    Wilcoxon p = %.4f, t-test p = %.4f\n", 
    rec_test$p.value, rec_ttest$p.value))

cat("\nInterpretation:\n")
if (prec_test$p.value < 0.05) {
  cat("- Precision: SIGNIFICANT difference (p < 0.05)\n")
} else {
  cat("- Precision: NOT significant (p >= 0.05)\n")
}
if (rec_test$p.value < 0.05) {
  cat("- Recall: SIGNIFICANT difference (p < 0.05)\n")
} else {
  cat("- Recall: NOT significant (p >= 0.05)\n")
}
