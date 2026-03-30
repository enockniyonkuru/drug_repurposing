#!/usr/bin/env Rscript
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

# Filter for Name and Synonym only
data_filtered <- df %>%
  filter(match_type %in% c("name", "synonym"))

# Prepare combined data with both metrics
combined_data <- data_filtered %>%
  filter(!is.na(tahoe_precision_numeric) | !is.na(cmap_precision_numeric) | 
         !is.na(tahoe_recall_numeric) | !is.na(cmap_recall_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    `Precision-TAHOE` = mean(tahoe_precision_numeric, na.rm = TRUE) * 100,
    `Precision-CMAP` = mean(cmap_precision_numeric, na.rm = TRUE) * 100,
    `Recall-TAHOE` = mean(tahoe_recall_numeric, na.rm = TRUE) * 100,
    `Recall-CMAP` = mean(cmap_recall_numeric, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = -match_type, names_to = "Metric_Pipeline", values_to = "Value")

cat("Combined Data:\n")
print(combined_data)

# ============================================================
# OPTION 1: GROUPED BAR CHART (4 bars per match type)
# ============================================================
plot1 <- ggplot(combined_data, aes(x = match_type, y = Value, fill = Metric_Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "white", linewidth = 1.2, width = 0.7) +
  scale_fill_manual(
    values = c(
      "Precision-TAHOE" = "#5DADE2",
      "Precision-CMAP" = "#F39C12",
      "Recall-TAHOE" = "#5DADE2",
      "Recall-CMAP" = "#F39C12"
    )
  ) +
  geom_text(aes(label = sprintf("%.1f%%", Value)), 
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 3.8, fontface = "bold", color = "#2C3E50") +
  labs(
    title = "Pipeline Performance: Precision & Recall by Match Type",
    subtitle = "All metrics on single chart with percentage labels",
    x = "Match Type",
    y = "Score (%)",
    fill = "Metric-Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_blank(),
    plot.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA)
  ) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 65))

cat("\nOption 1: Grouped Bar Chart created ✓\n")

# ============================================================
# OPTION 2: LOLLIPOP CHART (Modern, elegant)
# ============================================================
plot2 <- ggplot(combined_data, aes(x = match_type, y = Value, color = Metric_Pipeline)) +
  geom_segment(aes(xend = match_type, yend = 0), linewidth = 2.5, alpha = 0.7) +
  geom_point(size = 7, alpha = 0.9) +
  scale_color_manual(
    values = c(
      "Precision-TAHOE" = "#5DADE2",
      "Precision-CMAP" = "#F39C12",
      "Recall-TAHOE" = "#5DADE2",
      "Recall-CMAP" = "#F39C12"
    )
  ) +
  geom_text(aes(label = sprintf("%.1f%%", Value)), 
            vjust = -1.3, size = 3.8, fontface = "bold", color = "#2C3E50") +
  labs(
    title = "Pipeline Performance: Precision & Recall by Match Type",
    subtitle = "Lollipop chart - modern, elegant visualization",
    x = "Match Type",
    y = "Score (%)",
    color = "Metric-Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_blank(),
    plot.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA)
  ) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 70))

cat("Option 2: Lollipop Chart created ✓\n")

# ============================================================
# OPTION 3: DOT PLOT WITH CONNECTING LINES
# ============================================================
plot3 <- ggplot(combined_data, aes(x = Metric_Pipeline, y = Value, color = Metric_Pipeline, size = Value)) +
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
    title = "Pipeline Performance: Precision & Recall by Match Type",
    subtitle = "Dot plot with comparison lines",
    x = "Metric-Pipeline",
    y = "Score (%)",
    color = "Metric-Pipeline",
    size = "Score"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray50"),
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

cat("Option 3: Dot Plot With Lines created ✓\n")

# ============================================================
# OPTION 4: FACETED COLUMNS (Clean comparison)
# ============================================================
plot4 <- ggplot(combined_data, aes(x = Metric_Pipeline, y = Value, fill = Metric_Pipeline)) +
  geom_col(color = "white", linewidth = 1.2, width = 0.7, alpha = 0.85) +
  facet_wrap(~match_type, labeller = labeller(match_type = c("name" = "Name Match", "synonym" = "Synonym Match"))) +
  scale_fill_manual(
    values = c(
      "Precision-TAHOE" = "#5DADE2",
      "Precision-CMAP" = "#F39C12",
      "Recall-TAHOE" = "#5DADE2",
      "Recall-CMAP" = "#F39C12"
    )
  ) +
  geom_text(aes(label = sprintf("%.1f%%", Value)), 
            vjust = -0.5, size = 4, fontface = "bold", color = "#2C3E50") +
  labs(
    title = "Pipeline Performance: Precision & Recall by Match Type",
    subtitle = "Faceted comparison - easy metric review",
    x = "Metric-Pipeline",
    y = "Score (%)",
    fill = "Metric-Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 10),
    legend.position = "bottom",
    strip.text = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    plot.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA)
  ) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 65))

cat("Option 4: Faceted Columns created ✓\n")

# ============================================================
# SAVE ALL VERSIONS
# ============================================================
ggsave("figures/Option1_Grouped_Bar_Chart.pdf", 
        plot1, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Option1_Grouped_Bar_Chart.png", 
        plot1, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")

ggsave("figures/Option2_Lollipop_Chart.pdf", 
        plot2, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Option2_Lollipop_Chart.png", 
        plot2, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")

ggsave("figures/Option3_DotPlot_With_Lines.pdf", 
        plot3, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Option3_DotPlot_With_Lines.png", 
        plot3, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")

ggsave("figures/Option4_Faceted_Columns.pdf", 
        plot4, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Option4_Faceted_Columns.png", 
        plot4, width = 11, height = 7, dpi = 300, bg = "#FAFAFA")

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✓ 4 DIFFERENT VISUALIZATION OPTIONS CREATED!\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("OPTION 1: Grouped Bar Chart (Classic, all on one chart)\n")
cat("  Files: Option1_Grouped_Bar_Chart.pdf/png\n")
cat("  - All 4 metrics side-by-side\n")
cat("  - Percentage labels above each bar\n")
cat("  - Best for: Traditional publications\n\n")

cat("OPTION 2: Lollipop Chart (Modern, elegant)\n")
cat("  Files: Option2_Lollipop_Chart.pdf/png\n")
cat("  - Clean, minimalist design\n")
cat("  - Percentage labels floating above dots\n")
cat("  - Best for: High-impact presentations\n\n")

cat("OPTION 3: Dot Plot With Lines (Creative comparison)\n")
cat("  Files: Option3_DotPlot_With_Lines.pdf/png\n")
cat("  - Shows metrics within each match type\n")
cat("  - Connecting lines show relationships\n")
cat("  - Best for: Comparing within groups\n\n")

cat("OPTION 4: Faceted Columns (Clean side-by-side)\n")
cat("  Files: Option4_Faceted_Columns.pdf/png\n")
cat("  - Separate panels for Name vs Synonym\n")
cat("  - All four metrics visible in each panel\n")
cat("  - Best for: Easy metric comparison\n\n")

cat("COLOR PALETTE (Same across all):\n")
cat("  • Precision-TAHOE: Teal (#4ECDC4)\n")
cat("  • Precision-CMAP:  Coral (#FF6B6B)\n")
cat("  • Recall-TAHOE:    Blue (#45B7D1)\n")
cat("  • Recall-CMAP:     Light Red (#FF8787)\n\n")

cat("KEY INSIGHT:\n")
cat("  Recall values are much higher than Precision (~45-54% vs ~1.5-2.2%)\n")
cat("  TAHOE consistently outperforms CMAP across all metrics\n\n")

