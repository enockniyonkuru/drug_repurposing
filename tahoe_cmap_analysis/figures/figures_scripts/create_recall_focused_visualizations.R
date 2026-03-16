#!/usr/bin/env Rscript
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

file_path <- "tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Convert metrics to numeric
df$tahoe_recall_numeric <- suppressWarnings(as.numeric(df$`Tahoe Recall`))
df$cmap_recall_numeric <- suppressWarnings(as.numeric(df$`CMAP Recall`))

# Filter for Name and Synonym only
data_filtered <- df %>%
  filter(match_type %in% c("name", "synonym"))

# Prepare recall-only data
recall_long <- data_filtered %>%
  filter(!is.na(tahoe_recall_numeric) | !is.na(cmap_recall_numeric)) %>%
  select(disease_name, disease_id, match_type, tahoe_recall_numeric, cmap_recall_numeric) %>%
  pivot_longer(
    cols = c(tahoe_recall_numeric, cmap_recall_numeric),
    names_to = "Pipeline",
    values_to = "Recall"
  ) %>%
  mutate(
    Pipeline = case_when(
      Pipeline == "tahoe_recall_numeric" ~ "Tahoe",
      Pipeline == "cmap_recall_numeric" ~ "CMap",
      TRUE ~ Pipeline
    ),
    Recall_pct = Recall * 100
  )

output_dir <- "tahoe_cmap_analysis/figures"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("Creating Recall-Focused Visualizations...\n\n")

# ============================================================
# CHART 1: RECALL-ONLY VIOLIN PLOT
# ============================================================
cat("Creating Chart 1: Recall Distribution - Violin Plot...\n")

p1 <- ggplot(recall_long, aes(x = Pipeline, y = Recall_pct, fill = Pipeline)) +
  geom_violin(alpha = 0.7, trim = FALSE, linewidth = 1) +
  geom_boxplot(width = 0.15, alpha = 0.5, color = "black", linewidth = 0.8) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 2, color = "#2C3E50") +
  scale_fill_manual(
    values = c(
      "Tahoe" = "#5DADE2",
      "CMap" = "#F39C12"
    )
  ) +
  labs(
    title = "Recall Distribution by Pipeline",
    subtitle = "Across all disease-drug associations (Name & Synonym matches)",
    x = "Pipeline",
    y = "Recall (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 20), color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "none",
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  ) +
  scale_y_continuous(limits = c(-5, 105), expand = c(0, 0))

ggsave(file.path(output_dir, "Recall_Violin_Plot.pdf"), p1, width = 10, height = 7, dpi = 300)
ggsave(file.path(output_dir, "Recall_Violin_Plot.png"), p1, width = 10, height = 7, dpi = 300)

cat("✓ Violin Plot created\n\n")

# ============================================================
# CHART 2: RECALL-ONLY BAR CHART BY MATCH TYPE
# ============================================================
cat("Creating Chart 2: Mean Recall by Match Type...\n")

recall_by_type <- recall_long %>%
  group_by(match_type, Pipeline) %>%
  summarise(
    Mean_Recall = mean(Recall_pct, na.rm = TRUE),
    SD_Recall = sd(Recall_pct, na.rm = TRUE),
    Count = n(),
    .groups = 'drop'
  )

p2 <- ggplot(recall_by_type, aes(x = match_type, y = Mean_Recall, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "white", linewidth = 1.2, width = 0.7) +
  geom_errorbar(aes(ymin = Mean_Recall - SD_Recall, ymax = Mean_Recall + SD_Recall),
                position = position_dodge(width = 0.7), width = 0.2, linewidth = 1, alpha = 0.7) +
  scale_fill_manual(
    values = c(
      "Tahoe" = "#5DADE2",
      "CMap" = "#F39C12"
    )
  ) +
  geom_text(aes(label = sprintf("%.1f%%", Mean_Recall)),
            position = position_dodge(width = 0.7),
            vjust = -0.8, size = 4.2, fontface = "bold", color = "#2C3E50") +
  labs(
    title = "Mean Recall Performance by Disease Match Type",
    subtitle = "Error bars show ±1 standard deviation",
    x = "Match Type",
    y = "Mean Recall (%)",
    fill = "Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 20), color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "top",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  ) +
  scale_y_continuous(limits = c(0, 105), expand = c(0, 0))

ggsave(file.path(output_dir, "Recall_By_Match_Type_Bar.pdf"), p2, width = 11, height = 7, dpi = 300)
ggsave(file.path(output_dir, "Recall_By_Match_Type_Bar.png"), p2, width = 11, height = 7, dpi = 300)

cat("✓ Bar Chart created\n\n")

# ============================================================
# CHART 3: RECALL-ONLY DENSITY PLOT
# ============================================================
cat("Creating Chart 3: Recall Density Distribution...\n")

p3 <- ggplot(recall_long, aes(x = Recall_pct, fill = Pipeline, color = Pipeline)) +
  geom_density(alpha = 0.5, linewidth = 1.2) +
  scale_fill_manual(
    values = c(
      "Tahoe" = "#5DADE2",
      "CMap" = "#F39C12"
    )
  ) +
  scale_color_manual(
    values = c(
      "Tahoe" = "#1F618D",
      "CMap" = "#B8860B"
    )
  ) +
  labs(
    title = "Recall Distribution Density",
    subtitle = "Comparing recall performance across pipelines",
    x = "Recall (%)",
    y = "Density",
    fill = "Pipeline",
    color = "Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 20), color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "top",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.3),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  ) +
  scale_x_continuous(limits = c(-5, 105), expand = c(0, 0))

ggsave(file.path(output_dir, "Recall_Density_Plot.pdf"), p3, width = 11, height = 7, dpi = 300)
ggsave(file.path(output_dir, "Recall_Density_Plot.png"), p3, width = 11, height = 7, dpi = 300)

cat("✓ Density Plot created\n\n")

# ============================================================
# CHART 4: RECALL-ONLY DOT PLOT WITH LINES (per disease)
# ============================================================
cat("Creating Chart 4: Per-Disease Recall Comparison...\n")

# Prepare data for per-disease comparison
recall_wide <- recall_long %>%
  pivot_wider(
    id_cols = c(disease_name, match_type),
    names_from = Pipeline,
    values_from = Recall_pct
  ) %>%
  arrange(match_type, Tahoe)

# Select top and bottom diseases for visualization (to avoid overcrowding)
top_diseases <- recall_wide %>%
  mutate(diff = abs(Tahoe - CMap)) %>%
  arrange(desc(diff)) %>%
  slice(1:20)

p4 <- ggplot(top_diseases, aes(x = reorder(disease_name, Tahoe), y = Tahoe, color = "Tahoe")) +
  geom_point(size = 4, alpha = 0.8) +
  geom_point(aes(y = CMap, color = "CMap"), size = 4, alpha = 0.8) +
  geom_segment(aes(xend = disease_name, y = Tahoe, yend = CMap), 
               color = "#95A5A6", linewidth = 0.8, alpha = 0.6) +
  scale_color_manual(
    values = c(
      "Tahoe" = "#5DADE2",
      "CMap" = "#F39C12"
    )
  ) +
  coord_flip() +
  labs(
    title = "Top 20 Diseases: Recall Divergence Between Pipelines",
    subtitle = "Lines connect Tahoe and CMap recall for each disease",
    x = "Disease",
    y = "Recall (%)",
    color = "Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 20), color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text.y = element_text(size = 9),
    axis.text.x = element_text(size = 11),
    legend.position = "top",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.y = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  ) +
  scale_y_continuous(limits = c(-5, 105), expand = c(0, 0))

ggsave(file.path(output_dir, "Recall_Top_Diseases_DotPlot.pdf"), p4, width = 12, height = 9, dpi = 300)
ggsave(file.path(output_dir, "Recall_Top_Diseases_DotPlot.png"), p4, width = 12, height = 9, dpi = 300)

cat("✓ Dot Plot created\n\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================

cat("\n╔════════════════════════════════════════════════════════════╗\n")
cat("║         RECALL-FOCUSED ANALYSIS - SUMMARY REPORT           ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

overall_stats <- recall_long %>%
  group_by(Pipeline) %>%
  summarise(
    Mean_Recall = mean(Recall_pct, na.rm = TRUE),
    Median_Recall = median(Recall_pct, na.rm = TRUE),
    SD_Recall = sd(Recall_pct, na.rm = TRUE),
    Min_Recall = min(Recall_pct, na.rm = TRUE),
    Max_Recall = max(Recall_pct, na.rm = TRUE),
    Count = n(),
    .groups = 'drop'
  )

cat("OVERALL RECALL STATISTICS:\n")
print(overall_stats)

cat("\n\nRECALL BY MATCH TYPE:\n")
recall_by_type_full <- recall_long %>%
  group_by(match_type, Pipeline) %>%
  summarise(
    Mean_Recall = mean(Recall_pct, na.rm = TRUE),
    Median_Recall = median(Recall_pct, na.rm = TRUE),
    SD_Recall = sd(Recall_pct, na.rm = TRUE),
    Count = n(),
    .groups = 'drop'
  )
print(recall_by_type_full)

cat("\n\nFILES CREATED:\n")
cat("  1. Recall_Violin_Plot.pdf / .png\n")
cat("  2. Recall_By_Match_Type_Bar.pdf / .png\n")
cat("  3. Recall_Density_Plot.pdf / .png\n")
cat("  4. Recall_Top_Diseases_DotPlot.pdf / .png\n\n")

cat("✓ All Recall-focused visualizations created successfully!\n")
