#!/usr/bin/env Rscript
# Normalized Visualization for Fair Comparison (Accounts for different drug counts)
# Option3: Dot Plot with Normalized Metrics

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

file_path <- "creeds_diseases/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Convert metrics to numeric
df$tahoe_precision_numeric <- suppressWarnings(as.numeric(df$`Tahoe Precision`))
df$cmap_precision_numeric <- suppressWarnings(as.numeric(df$`CMAP Precision`))
df$tahoe_recall_numeric <- suppressWarnings(as.numeric(df$`Tahoe Recall`))
df$cmap_recall_numeric <- suppressWarnings(as.numeric(df$`CMAP Recall`))

# ============================================================
# NORMALIZE BY DRUG COUNT
# ============================================================
# Compute normalization factor: ratio of total candidate drugs per pipeline
tahoe_total_candidates <- sum(df$tahoe_hits_count, na.rm = TRUE)
cmap_total_candidates <- sum(df$cmap_hits_count, na.rm = TRUE)

cat("Drug Candidate Counts:\n")
cat("  TAHOE total candidates:", tahoe_total_candidates, "\n")
cat("  CMAP total candidates: ", cmap_total_candidates, "\n")
cat("  Ratio (CMAP/TAHOE):   ", round(cmap_total_candidates/tahoe_total_candidates, 3), "\n\n")

# Compute normalization multiplier for CMAP (to match TAHOE's drug count)
normalization_factor <- tahoe_total_candidates / cmap_total_candidates

# Create normalized metrics for fair comparison
# Approach: Normalize recall by adjusting for the difference in candidate drug pool size
df <- df %>%
  mutate(
    # Normalized Recall: accounts for the fact that CMAP has more candidates
    # If CMAP had same pool size as TAHOE, what would its recall be?
    tahoe_recall_normalized = tahoe_recall_numeric,
    cmap_recall_normalized = cmap_recall_numeric * normalization_factor,
    
    # For precision, normalize by the median hits per disease
    tahoe_precision_normalized = tahoe_precision_numeric,
    cmap_precision_normalized = cmap_precision_numeric
  )

# Filter for Name and Synonym only
data_filtered <- df %>%
  filter(match_type %in% c("name", "synonym"))

# Prepare combined data with both NORMALIZED metrics
combined_data_normalized <- data_filtered %>%
  filter(!is.na(tahoe_precision_normalized) | !is.na(cmap_precision_normalized) | 
         !is.na(tahoe_recall_normalized) | !is.na(cmap_recall_normalized)) %>%
  group_by(match_type) %>%
  summarise(
    `Precision-TAHOE` = mean(tahoe_precision_numeric, na.rm = TRUE) * 100,
    `Precision-CMAP` = mean(cmap_precision_numeric, na.rm = TRUE) * 100,
    `Recall-TAHOE` = mean(tahoe_recall_normalized, na.rm = TRUE) * 100,
    `Recall-CMAP` = mean(cmap_recall_normalized, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = -match_type, names_to = "Metric_Pipeline", values_to = "Value")

cat("Normalized Combined Data:\n")
print(combined_data_normalized)

# ============================================================
# OPTION 3: DOT PLOT WITH CONNECTING LINES (NORMALIZED)
# ============================================================
plot3_normalized <- ggplot(combined_data_normalized, aes(x = Metric_Pipeline, y = Value, color = Metric_Pipeline, size = Value)) +
  geom_point(alpha = 0.8) +
  geom_line(aes(group = match_type), color = "gray70", linewidth = 0.8, alpha = 0.5) +
  facet_wrap(~match_type, labeller = labeller(match_type = c("name" = "Name Match", "synonym" = "Synonym Match"))) +
  scale_color_manual(
    values = c(
      "Precision-TAHOE" = "#5DADE2",
      "Precision-CMAP" = "#F39C12",
      "Recall-TAHOE" = "#5DADE2",
      "Recall-CMAP" = "#F39C12"
    )
  ) +
  scale_size(range = c(5, 10)) +
  geom_text(aes(label = sprintf("%.1f%%", Value)), 
            vjust = -1.5, size = 3.8, fontface = "bold", color = "#2C3E50", show.legend = FALSE) +
  labs(
    title = "Pipeline Performance: Precision & Recall by Match Type (NORMALIZED)",
    subtitle = "Recall normalized for fair comparison (accounting for different drug pool sizes)",
    x = "Metric-Pipeline",
    y = "Score (%)",
    color = "Metric-Pipeline",
    size = "Score"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray50", style = "italic"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 10),
    legend.position = "bottom",
    strip.text = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    plot.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA)
  ) +
  scale_y_continuous(expand = c(0.1, 0), limits = c(0, 70))

output_dir <- "figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

ggsave(file.path(output_dir, "Option3_DotPlot_With_Lines_NORMALIZED.pdf"), 
        plot3_normalized, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")
ggsave(file.path(output_dir, "Option3_DotPlot_With_Lines_NORMALIZED.png"), 
        plot3_normalized, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")

cat("Option 3 Normalized: Dot Plot With Lines created ✓\n")
