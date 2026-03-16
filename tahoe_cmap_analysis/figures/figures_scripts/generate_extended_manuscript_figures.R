#!/usr/bin/env Rscript
# Extended Manuscript Figures for Drug Repurposing Analysis
# Part 2: Precision/Recall Analysis and Advanced Metrics
# Exp8 Analysis with Q-threshold 0.05

library(readxl)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(tidyr)
library(reshape2)

# Set publication-quality theme
theme_manuscript <- function() {
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "right",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 10, face = "bold")
  )
}

# Read data
file_path <- "tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Convert precision/recall columns from character to numeric
# Handle #DIV/0! errors
df$tahoe_precision_numeric <- suppressWarnings(as.numeric(df$`Tahoe Precision`))
df$tahoe_recall_numeric <- suppressWarnings(as.numeric(df$`Tahoe Recall`))
df$cmap_precision_numeric <- suppressWarnings(as.numeric(df$`CMAP Precision`))
df$cmap_recall_numeric <- suppressWarnings(as.numeric(df$`CMAP Recall`))
df$common_precision_numeric <- suppressWarnings(as.numeric(df$`Common Precision`))

# Output directory
output_dir <- "tahoe_cmap_analysis/figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ============================================================================
# FIGURE 6: Precision vs Recall Scatter Plot (TAHOE vs CMAP)
# ============================================================================

fig6_data <- data.frame(
  Pipeline = c(rep("TAHOE", nrow(df)), rep("CMAP", nrow(df))),
  Precision = c(df$tahoe_precision_numeric, df$cmap_precision_numeric),
  Recall = c(df$tahoe_recall_numeric, df$cmap_recall_numeric)
)

# Remove NAs
fig6_data <- fig6_data %>% na.omit()

fig6 <- ggplot(fig6_data, aes(x = Recall, y = Precision, color = Pipeline, fill = Pipeline)) +
  geom_point(size = 3, alpha = 0.6, stroke = 1.2) +
  scale_color_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  facet_wrap(~Pipeline) +
  labs(
    title = "Precision vs Recall Performance",
    subtitle = "Trade-off analysis across all diseases",
    x = "Recall",
    y = "Precision"
  ) +
  theme_manuscript() +
  theme(legend.position = "bottom") +
  scale_x_continuous(limits = c(0, 1.05)) +
  scale_y_continuous(limits = c(0, 1.05))

ggsave(file.path(output_dir, "Fig6_Precision_vs_Recall_Scatter.pdf"), fig6, width = 10, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig6_Precision_vs_Recall_Scatter.png"), fig6, width = 10, height = 5.5, dpi = 300)

cat("✓ Figure 6 saved: Precision vs Recall Scatter\n")

# ============================================================================
# FIGURE 7: Average Precision by Match Type
# ============================================================================

fig7_data <- df %>%
  filter(!is.na(tahoe_precision_numeric) | !is.na(cmap_precision_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    TAHOE_Precision = mean(tahoe_precision_numeric, na.rm = TRUE),
    CMAP_Precision = mean(cmap_precision_numeric, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = -match_type, names_to = "Pipeline", values_to = "Precision") %>%
  filter(!is.na(Precision))

fig7 <- ggplot(fig7_data, aes(x = match_type, y = Precision, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("TAHOE_Precision" = "#2E86AB", "CMAP_Precision" = "#A23B72")) +
  labs(
    title = "Average Precision by Match Type",
    subtitle = "Disease matching strategy impact on precision",
    x = "Match Type",
    y = "Average Precision"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(fig7_data$Precision, na.rm = T) * 1.15)) +
  geom_text(aes(label = sprintf("%.4f", Precision)), position = position_dodge(width = 0.9),
            vjust = -0.3, size = 3.2, fontface = "bold")

ggsave(file.path(output_dir, "Fig7_Precision_by_Match_Type.pdf"), fig7, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig7_Precision_by_Match_Type.png"), fig7, width = 9, height = 5.5, dpi = 300)

cat("✓ Figure 7 saved: Average Precision by Match Type\n")

# ============================================================================
# FIGURE 8: Average Recall by Match Type for TAHOE and CMAP (USER REQUEST)
# ============================================================================

fig8_data <- df %>%
  filter(!is.na(tahoe_recall_numeric) | !is.na(cmap_recall_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    TAHOE_Recall = mean(tahoe_recall_numeric, na.rm = TRUE),
    CMAP_Recall = mean(cmap_recall_numeric, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = -match_type, names_to = "Pipeline", values_to = "Recall") %>%
  filter(!is.na(Recall))

fig8 <- ggplot(fig8_data, aes(x = match_type, y = Recall, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("TAHOE_Recall" = "#06A77D", "CMAP_Recall" = "#D62828")) +
  labs(
    title = "Average Recall by Match Type",
    subtitle = "Disease matching strategy impact on recall (sensitivity)",
    x = "Match Type",
    y = "Average Recall"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1.1)) +
  geom_text(aes(label = sprintf("%.4f", Recall)), position = position_dodge(width = 0.9),
            vjust = -0.3, size = 3.2, fontface = "bold")

ggsave(file.path(output_dir, "Fig8_Recall_by_Match_Type.pdf"), fig8, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig8_Recall_by_Match_Type.png"), fig8, width = 9, height = 5.5, dpi = 300)

cat("✓ Figure 8 saved: Average Recall by Match Type\n")

# ============================================================================
# FIGURE 9: Comparison of Average Overall Recall (USER REQUEST)
# ============================================================================

overall_recall <- data.frame(
  Pipeline = c("TAHOE", "CMAP"),
  AvgRecall = c(
    mean(df$tahoe_recall_numeric, na.rm = TRUE),
    mean(df$cmap_recall_numeric, na.rm = TRUE)
  ),
  MedianRecall = c(
    median(df$tahoe_recall_numeric, na.rm = TRUE),
    median(df$cmap_recall_numeric, na.rm = TRUE)
  )
)

overall_recall_long <- melt(overall_recall, id.vars = "Pipeline",
                            variable.name = "Statistic", value.name = "Recall")

fig9 <- ggplot(overall_recall_long, aes(x = Pipeline, y = Recall, fill = Statistic)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("AvgRecall" = "#F18F01", "MedianRecall" = "#C73E1D")) +
  labs(
    title = "Overall Recall Comparison",
    subtitle = "Average vs median sensitivity to identify known drugs",
    x = "Pipeline",
    y = "Recall"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  geom_text(aes(label = sprintf("%.4f", Recall)), position = position_dodge(width = 0.9),
            vjust = -0.3, size = 3.5, fontface = "bold")

ggsave(file.path(output_dir, "Fig9_Overall_Recall_Comparison.pdf"), fig9, width = 8, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig9_Overall_Recall_Comparison.png"), fig9, width = 8, height = 5.5, dpi = 300)

cat("✓ Figure 9 saved: Overall Recall Comparison\n")

# ============================================================================
# FIGURE 10: Hit Efficiency by Pipeline (Hits per Known Drug)
# ============================================================================

# Calculate efficiency metrics
df$tahoe_efficiency <- ifelse(df$known_drugs_available_in_tahoe_count > 0,
                              df$tahoe_hits_count / df$known_drugs_available_in_tahoe_count,
                              NA)
df$cmap_efficiency <- ifelse(df$known_drugs_available_in_cmap_count > 0,
                             df$cmap_hits_count / df$known_drugs_available_in_cmap_count,
                             NA)

eff_data <- data.frame(
  Pipeline = c("TAHOE", "CMAP"),
  MeanEfficiency = c(mean(df$tahoe_efficiency, na.rm = TRUE), mean(df$cmap_efficiency, na.rm = TRUE)),
  MedianEfficiency = c(median(df$tahoe_efficiency, na.rm = TRUE), median(df$cmap_efficiency, na.rm = TRUE)),
  MaxEfficiency = c(max(df$tahoe_efficiency, na.rm = TRUE), max(df$cmap_efficiency, na.rm = TRUE))
)

eff_data_long <- melt(eff_data, id.vars = "Pipeline",
                      variable.name = "Statistic", value.name = "Efficiency")

fig10 <- ggplot(eff_data_long, aes(x = Pipeline, y = Efficiency, fill = Statistic)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("MeanEfficiency" = "#2E86AB", "MedianEfficiency" = "#A23B72", "MaxEfficiency" = "#F18F01")) +
  labs(
    title = "Hit Efficiency Ratio",
    subtitle = "Average drug candidate hits per available known drug",
    x = "Pipeline",
    y = "Efficiency (Hits per Known Drug)"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(eff_data_long$Efficiency, na.rm = T) * 1.15)) +
  geom_text(aes(label = sprintf("%.1f", Efficiency)), position = position_dodge(width = 0.9),
            vjust = -0.3, size = 3.2, fontface = "bold")

ggsave(file.path(output_dir, "Fig10_Hit_Efficiency.pdf"), fig10, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig10_Hit_Efficiency.png"), fig10, width = 9, height = 5.5, dpi = 300)

cat("✓ Figure 10 saved: Hit Efficiency\n")

# ============================================================================
# FIGURE 11: Match Type Distribution and Performance
# ============================================================================

match_summary <- df %>%
  group_by(match_type) %>%
  summarise(
    Count = n(),
    AvgTahoeHits = mean(tahoe_hits_count, na.rm = TRUE),
    AvgCmapHits = mean(cmap_hits_count, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  filter(!is.na(match_type))

match_summary_long <- melt(match_summary, id.vars = c("match_type", "Count"),
                           variable.name = "Pipeline", value.name = "AvgHits")

fig11 <- ggplot(match_summary_long, aes(x = reorder(match_type, -Count), y = AvgHits, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("AvgTahoeHits" = "#2E86AB", "AvgCmapHits" = "#A23B72")) +
  labs(
    title = "Average Performance by Match Type",
    subtitle = "Disease matching strategy effectiveness",
    x = "Match Type (ordered by frequency)",
    y = "Average Drug Hits"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(match_summary_long$AvgHits, na.rm = T) * 1.15)) +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

# Add count labels
match_counts <- match_summary %>% arrange(desc(Count))
fig11 <- fig11 + annotate("text", x = 1:nrow(match_counts), y = -20,
                          label = paste0("n=", match_counts$Count),
                          size = 3, hjust = 0.5)

ggsave(file.path(output_dir, "Fig11_Match_Type_Performance.pdf"), fig11, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig11_Match_Type_Performance.png"), fig11, width = 9, height = 5.5, dpi = 300)

cat("✓ Figure 11 saved: Match Type Performance\n")

# ============================================================================
# FIGURE 12: F1-Score Comparison (Harmonic Mean of Precision and Recall)
# ============================================================================

df$tahoe_f1 <- 2 * (df$tahoe_precision_numeric * df$tahoe_recall_numeric) / 
               (df$tahoe_precision_numeric + df$tahoe_recall_numeric)
df$cmap_f1 <- 2 * (df$cmap_precision_numeric * df$cmap_recall_numeric) / 
              (df$cmap_precision_numeric + df$cmap_recall_numeric)

f1_data <- data.frame(
  Pipeline = c("TAHOE", "CMAP"),
  MeanF1 = c(mean(df$tahoe_f1, na.rm = TRUE), mean(df$cmap_f1, na.rm = TRUE)),
  MedianF1 = c(median(df$tahoe_f1, na.rm = TRUE), median(df$cmap_f1, na.rm = TRUE))
)

f1_data_long <- melt(f1_data, id.vars = "Pipeline",
                     variable.name = "Statistic", value.name = "F1Score")

fig12 <- ggplot(f1_data_long, aes(x = Pipeline, y = F1Score, fill = Statistic)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("MeanF1" = "#06A77D", "MedianF1" = "#D62828")) +
  labs(
    title = "F1-Score: Balanced Performance",
    subtitle = "Harmonic mean of precision and recall",
    x = "Pipeline",
    y = "F1-Score"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(f1_data_long$F1Score, na.rm = T) * 1.15)) +
  geom_text(aes(label = sprintf("%.4f", F1Score)), position = position_dodge(width = 0.9),
            vjust = -0.3, size = 3.5, fontface = "bold")

ggsave(file.path(output_dir, "Fig12_F1_Score_Comparison.pdf"), fig12, width = 8, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig12_F1_Score_Comparison.png"), fig12, width = 8, height = 5.5, dpi = 300)

cat("✓ Figure 12 saved: F1-Score Comparison\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("\nADDITIONAL FIGURES GENERATED SUCCESSFULLY\n\n")

cat("Generated Figures:\n")
cat("  6. Fig6_Precision_vs_Recall_Scatter.pdf/png\n")
cat("     → Scatter plot showing precision-recall trade-off\n\n")
cat("  7. Fig7_Precision_by_Match_Type.pdf/png\n")
cat("     → How disease matching strategy affects precision\n\n")
cat("  8. Fig8_Recall_by_Match_Type.pdf/png [USER REQUEST]\n")
cat("     → Average recall by match type for both pipelines\n\n")
cat("  9. Fig9_Overall_Recall_Comparison.pdf/png [USER REQUEST]\n")
cat("     → Overall recall comparison across pipelines\n\n")
cat("  10. Fig10_Hit_Efficiency.pdf/png\n")
cat("      → Efficiency ratio (hits per known drug)\n\n")
cat("  11. Fig11_Match_Type_Performance.pdf/png\n")
cat("      → Average performance stratified by match type\n\n")
cat("  12. Fig12_F1_Score_Comparison.pdf/png\n")
cat("      → Balanced metric combining precision and recall\n\n")

cat("All figures include both PDF and PNG formats\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Print summary statistics
cat("SUMMARY STATISTICS\n")
cat(paste(rep("-", 70), collapse = ""), "\n")

cat("\nPRECISION ANALYSIS\n")
cat("TAHOE - Mean:", sprintf("%.6f", mean(df$tahoe_precision_numeric, na.rm = TRUE)),
    "| Median:", sprintf("%.6f", median(df$tahoe_precision_numeric, na.rm = TRUE)), "\n")
cat("CMAP  - Mean:", sprintf("%.6f", mean(df$cmap_precision_numeric, na.rm = TRUE)),
    "| Median:", sprintf("%.6f", median(df$cmap_precision_numeric, na.rm = TRUE)), "\n")

cat("\nRECALL ANALYSIS\n")
cat("TAHOE - Mean:", sprintf("%.6f", mean(df$tahoe_recall_numeric, na.rm = TRUE)),
    "| Median:", sprintf("%.6f", median(df$tahoe_recall_numeric, na.rm = TRUE)), "\n")
cat("CMAP  - Mean:", sprintf("%.6f", mean(df$cmap_recall_numeric, na.rm = TRUE)),
    "| Median:", sprintf("%.6f", median(df$cmap_recall_numeric, na.rm = TRUE)), "\n")

cat("\nF1-SCORE ANALYSIS\n")
cat("TAHOE - Mean:", sprintf("%.6f", mean(df$tahoe_f1, na.rm = TRUE)),
    "| Median:", sprintf("%.6f", median(df$tahoe_f1, na.rm = TRUE)), "\n")
cat("CMAP  - Mean:", sprintf("%.6f", mean(df$cmap_f1, na.rm = TRUE)),
    "| Median:", sprintf("%.6f", median(df$cmap_f1, na.rm = TRUE)), "\n")

cat("\nEFFICIENCY ANALYSIS\n")
cat("TAHOE - Mean:", sprintf("%.2f", mean(df$tahoe_efficiency, na.rm = TRUE)),
    "| Median:", sprintf("%.2f", median(df$tahoe_efficiency, na.rm = TRUE)), "\n")
cat("CMAP  - Mean:", sprintf("%.2f", mean(df$cmap_efficiency, na.rm = TRUE)),
    "| Median:", sprintf("%.2f", median(df$cmap_efficiency, na.rm = TRUE)), "\n")

EOF
