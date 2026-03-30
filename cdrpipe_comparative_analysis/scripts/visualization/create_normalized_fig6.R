#!/usr/bin/env Rscript
# Normalized Precision vs Recall Scatter Plot (Fig6)
# Accounts for different drug pool sizes between TAHOE and CMAP

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
file_path <- "creeds_diseases/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Convert precision/recall columns from character to numeric
df$tahoe_precision_numeric <- suppressWarnings(as.numeric(df$`Tahoe Precision`))
df$tahoe_recall_numeric <- suppressWarnings(as.numeric(df$`Tahoe Recall`))
df$cmap_precision_numeric <- suppressWarnings(as.numeric(df$`CMAP Precision`))
df$cmap_recall_numeric <- suppressWarnings(as.numeric(df$`CMAP Recall`))
df$common_precision_numeric <- suppressWarnings(as.numeric(df$`Common Precision`))

# ============================================================
# COMPUTE NORMALIZATION FACTOR
# ============================================================
tahoe_total_candidates <- sum(df$tahoe_hits_count, na.rm = TRUE)
cmap_total_candidates <- sum(df$cmap_hits_count, na.rm = TRUE)

normalization_factor <- tahoe_total_candidates / cmap_total_candidates

cat("Normalization for Fair Comparison:\n")
cat("  TAHOE total candidates:", tahoe_total_candidates, "\n")
cat("  CMAP total candidates: ", cmap_total_candidates, "\n")
cat("  Normalization factor (TAHOE/CMAP):", round(normalization_factor, 3), "\n")
cat("  Interpretation: CMAP has", round(cmap_total_candidates/tahoe_total_candidates, 1), 
    "x more candidate drugs than TAHOE\n\n")

# Apply normalization: adjust CMAP recall to match TAHOE's drug pool
df <- df %>%
  mutate(
    cmap_recall_normalized = cmap_recall_numeric * normalization_factor
  )

# ============================================================================
# FIGURE 6: Precision vs Recall Scatter Plot (NORMALIZED - TAHOE vs CMAP)
# ============================================================================

fig6_data_normalized <- data.frame(
  Pipeline = c(rep("TAHOE", nrow(df)), rep("CMAP", nrow(df))),
  Precision = c(df$tahoe_precision_numeric, df$cmap_precision_numeric),
  Recall_Normalized = c(df$tahoe_recall_numeric, df$cmap_recall_normalized)
)

# Remove NAs
fig6_data_normalized <- fig6_data_normalized %>% na.omit()

fig6_normalized <- ggplot(fig6_data_normalized, aes(x = Recall_Normalized, y = Precision, color = Pipeline, fill = Pipeline)) +
  geom_point(size = 3, alpha = 0.6, stroke = 1.2) +
  scale_color_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  facet_wrap(~Pipeline) +
  labs(
    title = "Precision vs Recall Performance (NORMALIZED)",
    subtitle = "Fair comparison: Recall adjusted for different drug pool sizes",
    x = "Recall (Normalized)",
    y = "Precision"
  ) +
  theme_manuscript() +
  theme(legend.position = "bottom") +
  scale_x_continuous(limits = c(0, max(fig6_data_normalized$Recall_Normalized, na.rm = TRUE) * 1.1)) +
  scale_y_continuous(limits = c(0, 1.05))

output_dir <- "figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

ggsave(file.path(output_dir, "Fig6_Precision_vs_Recall_Scatter_NORMALIZED.pdf"), fig6_normalized, width = 10, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig6_Precision_vs_Recall_Scatter_NORMALIZED.png"), fig6_normalized, width = 10, height = 5.5, dpi = 300)

cat("✓ Figure 6 Normalized saved: Precision vs Recall Scatter\n")

# Print summary statistics
cat("\n=== SUMMARY STATISTICS (Normalized) ===\n")
fig6_summary <- fig6_data_normalized %>%
  group_by(Pipeline) %>%
  summarise(
    N = n(),
    Mean_Precision = mean(Precision, na.rm = TRUE),
    Median_Precision = median(Precision, na.rm = TRUE),
    Mean_Recall = mean(Recall_Normalized, na.rm = TRUE),
    Median_Recall = median(Recall_Normalized, na.rm = TRUE),
    .groups = 'drop'
  )

print(fig6_summary)
