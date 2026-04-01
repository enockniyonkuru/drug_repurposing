#!/usr/bin/env Rscript
library(readxl)
library(dplyr)

# Load the all-diseases CREEDS manual workbook with disease-level metrics
df <- read_excel("creeds/analysis/CREEDS_Manual_All_Diseases_Analysis.xlsx", sheet = "all_diseases_q0.05")

# Define I, S, P from the data
# - I: total unique predictions for that disease
# - S: predictions that match known drugs (validated)
# - P: known drugs available in the pipeline for that disease

df <- df %>%
  mutate(
    tahoe_I = tahoe_hits_count,
    tahoe_S = tahoe_in_known_count,
    tahoe_P = known_drugs_available_in_tahoe_count,
    cmap_I = cmap_hits_count,
    cmap_S = cmap_in_known_count,
    cmap_P = known_drugs_available_in_cmap_count,
    # Calculate precision and recall
    tahoe_precision = ifelse(tahoe_I > 0, (tahoe_S / tahoe_I) * 100, NA),
    tahoe_recall = ifelse(tahoe_P > 0, (tahoe_S / tahoe_P) * 100, NA),
    cmap_precision = ifelse(cmap_I > 0, (cmap_S / cmap_I) * 100, NA),
    cmap_recall = ifelse(cmap_P > 0, (cmap_S / cmap_P) * 100, NA)
  )

cat("=== RAW DATA ANALYSIS ===\n")
cat("Total rows in creeds/analysis/CREEDS_Manual_All_Diseases_Analysis.xlsx:", nrow(df), "\n")

# Analyze ALL diseases (regardless of P value)
cat("\n=== ALL DISEASES (no filtering) ===\n")
cat("TAHOE Precision: n =", sum(!is.na(df$tahoe_precision)), 
    "Mean =", round(mean(df$tahoe_precision, na.rm=TRUE), 1), "% SD =", 
    round(sd(df$tahoe_precision, na.rm=TRUE), 1), "%\n")
cat("CMAP Precision:  n =", sum(!is.na(df$cmap_precision)), 
    "Mean =", round(mean(df$cmap_precision, na.rm=TRUE), 1), "% SD =", 
    round(sd(df$cmap_precision, na.rm=TRUE), 1), "%\n")

cat("\nTAHOE Recall:    n =", sum(!is.na(df$tahoe_recall)), 
    "Mean =", round(mean(df$tahoe_recall, na.rm=TRUE), 1), "% SD =", 
    round(sd(df$tahoe_recall, na.rm=TRUE), 1), "%\n")
cat("CMAP Recall:     n =", sum(!is.na(df$cmap_recall)), 
    "Mean =", round(mean(df$cmap_recall, na.rm=TRUE), 1), "% SD =", 
    round(sd(df$cmap_recall, na.rm=TRUE), 1), "%\n")

# Analyze diseases with P > 0 (recoverable drugs)
cat("\n=== WITH P > 0 FILTER (recoverable diseases) ===\n")
df_p_gt_0 <- df %>% filter(tahoe_P > 0 | cmap_P > 0)

tahoe_p_gt_0 <- df_p_gt_0 %>% filter(tahoe_P > 0)
cmap_p_gt_0 <- df_p_gt_0 %>% filter(cmap_P > 0)

cat("TAHOE Precision: n =", sum(!is.na(tahoe_p_gt_0$tahoe_precision)), 
    "Mean =", round(mean(tahoe_p_gt_0$tahoe_precision, na.rm=TRUE), 1), "% SD =", 
    round(sd(tahoe_p_gt_0$tahoe_precision, na.rm=TRUE), 1), "%\n")
cat("CMAP Precision:  n =", sum(!is.na(cmap_p_gt_0$cmap_precision)), 
    "Mean =", round(mean(cmap_p_gt_0$cmap_precision, na.rm=TRUE), 1), "% SD =", 
    round(sd(cmap_p_gt_0$cmap_precision, na.rm=TRUE), 1), "%\n")

cat("\nTAHOE Recall:    n =", sum(!is.na(tahoe_p_gt_0$tahoe_recall)), 
    "Mean =", round(mean(tahoe_p_gt_0$tahoe_recall, na.rm=TRUE), 1), "% SD =", 
    round(sd(tahoe_p_gt_0$tahoe_recall, na.rm=TRUE), 1), "%\n")
cat("CMAP Recall:     n =", sum(!is.na(cmap_p_gt_0$cmap_recall)), 
    "Mean =", round(mean(cmap_p_gt_0$cmap_recall, na.rm=TRUE), 1), "% SD =", 
    round(sd(cmap_p_gt_0$cmap_recall, na.rm=TRUE), 1), "%\n")

# Compare to manuscript
cat("\n=== MANUSCRIPT VALUES vs CALCULATED ===\n")
cat("MANUSCRIPT (stated in document):\n")
cat("  Precision: TAHOE 4.2% (SD 7.2%) vs CMAP 3.2% (SD 5.5%)\n")
cat("  Recall (P>0): TAHOE 20.3% (SD 20.5%) vs CMAP 8.9% (SD 12.0%)\n")

cat("\nCALCULATED (P>0 diseases only):\n")
cat("  Precision: TAHOE", round(mean(tahoe_p_gt_0$tahoe_precision, na.rm=TRUE), 1), 
    "% (SD", round(sd(tahoe_p_gt_0$tahoe_precision, na.rm=TRUE), 1), 
    "%) vs CMAP", round(mean(cmap_p_gt_0$cmap_precision, na.rm=TRUE), 1),
    "% (SD", round(sd(cmap_p_gt_0$cmap_precision, na.rm=TRUE), 1), "%)\n")
cat("  Recall:    TAHOE", round(mean(tahoe_p_gt_0$tahoe_recall, na.rm=TRUE), 1), 
    "% (SD", round(sd(tahoe_p_gt_0$tahoe_recall, na.rm=TRUE), 1), 
    "%) vs CMAP", round(mean(cmap_p_gt_0$cmap_recall, na.rm=TRUE), 1),
    "% (SD", round(sd(cmap_p_gt_0$cmap_recall, na.rm=TRUE), 1), "%)\n")

cat("\n=== STATISTICAL SIGNIFICANCE (P > 0 diseases) ===\n")

# Wilcoxon rank-sum test for precision
wilcox_prec <- wilcox.test(tahoe_p_gt_0$tahoe_precision, cmap_p_gt_0$cmap_precision, alternative="two.sided")
cat("Precision - Wilcoxon rank-sum test:\n")
cat("  p-value:", format(wilcox_prec$p.value, scientific=TRUE), "\n")
cat("  Significant at α=0.05?", ifelse(wilcox_prec$p.value < 0.05, "YES", "NO"), "\n")

# t-test for precision
t_prec <- t.test(tahoe_p_gt_0$tahoe_precision, cmap_p_gt_0$cmap_precision)
cat("\nPrecision - Welch's t-test:\n")
cat("  p-value:", format(t_prec$p.value, scientific=TRUE), "\n")
cat("  Significant at α=0.05?", ifelse(t_prec$p.value < 0.05, "YES", "NO"), "\n")

# Wilcoxon rank-sum test for recall
wilcox_rec <- wilcox.test(tahoe_p_gt_0$tahoe_recall, cmap_p_gt_0$cmap_recall, alternative="two.sided")
cat("\nRecall - Wilcoxon rank-sum test:\n")
cat("  p-value:", format(wilcox_rec$p.value, scientific=TRUE), "\n")
cat("  Significant at α=0.05?", ifelse(wilcox_rec$p.value < 0.05, "YES", "NO"), "\n")

# t-test for recall
t_rec <- t.test(tahoe_p_gt_0$tahoe_recall, cmap_p_gt_0$cmap_recall)
cat("\nRecall - Welch's t-test:\n")
cat("  p-value:", format(t_rec$p.value, scientific=TRUE), "\n")
cat("  Significant at α=0.05?", ifelse(t_rec$p.value < 0.05, "YES", "NO"), "\n")
