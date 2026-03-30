#!/usr/bin/env Rscript
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(gridExtra)

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

# ============ PRECISION DATA ============
precision_data <- data_filtered %>%
  filter(!is.na(tahoe_precision_numeric) | !is.na(cmap_precision_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    TAHOE = mean(tahoe_precision_numeric, na.rm = TRUE) * 100,
    CMAP = mean(cmap_precision_numeric, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = c("TAHOE", "CMAP"), names_to = "Pipeline", values_to = "Precision")

# ============ RECALL DATA ============
recall_data <- data_filtered %>%
  filter(!is.na(tahoe_recall_numeric) | !is.na(cmap_recall_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    TAHOE = mean(tahoe_recall_numeric, na.rm = TRUE) * 100,
    CMAP = mean(cmap_recall_numeric, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = c("TAHOE", "CMAP"), names_to = "Pipeline", values_to = "Recall")

# Print values
cat("PRECISION by Match Type (Name & Synonym only):\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
print(precision_data)

cat("\n\nRECALL by Match Type (Name & Synonym only):\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
print(recall_data)

# ============ CREATE PRECISION PLOT ============
plot1 <- ggplot(precision_data, aes(x = match_type, y = Precision, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "white", linewidth = 1.2, width = 0.65) +
  scale_fill_manual(
    values = c("CMAP" = "#FF6B6B", "TAHOE" = "#4ECDC4"),
    labels = c("CMAP", "TAHOE")
  ) +
  labs(
    title = "Precision by Match Type",
    x = "Match Type",
    y = "Average Precision (%)",
    fill = "Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "top",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA)
  ) +
  scale_y_continuous(
    breaks = seq(0, 3, by = 0.5),
    limits = c(0, 3),
    expand = c(0, 0),
    labels = function(x) paste0(x, "%")
  ) +
  geom_text(aes(label = sprintf("%.3f%%", Precision)), 
            position = position_dodge(width = 0.65),
            vjust = -0.6, size = 3.5, fontface = "bold", color = "#333333")

# ============ CREATE RECALL PLOT ============
plot2 <- ggplot(recall_data, aes(x = match_type, y = Recall, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "white", linewidth = 1.2, width = 0.65) +
  scale_fill_manual(
    values = c("CMAP" = "#FF6B6B", "TAHOE" = "#4ECDC4"),
    labels = c("CMAP", "TAHOE")
  ) +
  labs(
    title = "Recall by Match Type",
    x = "Match Type",
    y = "Average Recall (%)",
    fill = "Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "top",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA)
  ) +
  scale_y_continuous(
    breaks = seq(0, 60, by = 10),
    limits = c(0, 60),
    expand = c(0, 0),
    labels = function(x) paste0(x, "%")
  ) +
  geom_text(aes(label = sprintf("%.1f%%", Recall)), 
            position = position_dodge(width = 0.65),
            vjust = -0.6, size = 3.8, fontface = "bold", color = "#333333")

# ============ COMBINE PLOTS ============
combined <- grid.arrange(
  plot1, plot2,
  ncol = 1,
  heights = c(1, 1.2),
  top = grid::textGrob(
    "Pipeline Performance: Precision & Recall by Match Type",
    gp = grid::gpar(fontsize = 15, fontface = "bold", col = "#333333"),
    vjust = 0.5
  ),
  padding = unit(1, "lines")
)

# Save combined
ggsave("figures/Precision_Recall_Combined_Beautiful.pdf", 
        combined, width = 10, height = 10, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Precision_Recall_Combined_Beautiful.png", 
        combined, width = 10, height = 10, dpi = 300, bg = "#FAFAFA")

# ============ INDIVIDUAL PRECISION PLOT ============
ggsave("figures/Precision_by_Match_Type_Beautiful.pdf", 
        plot1, width = 9, height = 6, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Precision_by_Match_Type_Beautiful.png", 
        plot1, width = 9, height = 6, dpi = 300, bg = "#FAFAFA")

# ============ INDIVIDUAL RECALL PLOT ============
ggsave("figures/Recall_by_Match_Type_Beautiful.pdf", 
        plot2, width = 9, height = 6, dpi = 300, bg = "#FAFAFA")
ggsave("figures/Recall_by_Match_Type_Beautiful.png", 
        plot2, width = 9, height = 6, dpi = 300, bg = "#FAFAFA")

cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("✓ ALL PLOTS CREATED SUCCESSFULLY!\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")
cat("Files created:\n")
cat("  1. Precision_Recall_Combined_Beautiful.pdf (combined)\n")
cat("  2. Precision_Recall_Combined_Beautiful.png (combined)\n")
cat("  3. Precision_by_Match_Type_Beautiful.pdf\n")
cat("  4. Precision_by_Match_Type_Beautiful.png\n")
cat("  5. Recall_by_Match_Type_Beautiful.pdf\n")
cat("  6. Recall_by_Match_Type_Beautiful.png\n\n")

cat("Color Scheme:\n")
cat("  • TAHOE: Beautiful Teal (#4ECDC4)\n")
cat("  • CMAP:  Vibrant Coral Red (#FF6B6B)\n\n")
