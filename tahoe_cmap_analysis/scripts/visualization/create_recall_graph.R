#!/usr/bin/env Rscript
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

file_path <- "tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Convert recall to numeric
df$tahoe_recall_numeric <- suppressWarnings(as.numeric(df$`Tahoe Recall`))
df$cmap_recall_numeric <- suppressWarnings(as.numeric(df$`CMAP Recall`))

# Filter for Name and Synonym only, calculate averages
recall_data <- df %>%
  filter(match_type %in% c("name", "synonym")) %>%
  filter(!is.na(tahoe_recall_numeric) | !is.na(cmap_recall_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    TAHOE = mean(tahoe_recall_numeric, na.rm = TRUE) * 100,
    CMAP = mean(cmap_recall_numeric, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = c("TAHOE", "CMAP"), names_to = "Pipeline", values_to = "Recall")

# Print values for reference
cat("Average Recall by Match Type (Name & Synonym only):\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
print(recall_data)

# Create the graph
fig <- ggplot(recall_data, aes(x = match_type, y = Recall, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.8, width = 0.6) +
  scale_fill_manual(
    values = c("CMAP" = "#FF6B6B", "TAHOE" = "#4ECDC4"),
    labels = c("CMAP", "TAHOE")
  ) +
  labs(
    title = "Average Recall by Match Type",
    subtitle = "Comparison of TAHOE and CMAP pipeline sensitivity",
    x = "Match Type",
    y = "Average Recall (%)",
    fill = "Pipeline"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.position = "top",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.y = element_line(color = "gray80", linewidth = 0.4),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6)
  ) +
  scale_y_continuous(
    breaks = seq(0, 60, by = 10),
    limits = c(0, 60),
    expand = c(0, 0),
    labels = function(x) paste0(x, "%")
  ) +
  # Add value labels on bars
  geom_text(aes(label = sprintf("%.2f%%", Recall)), 
            position = position_dodge(width = 0.6),
            vjust = -0.5, size = 4, fontface = "bold", color = "black")

# Save as PDF and PNG
ggsave("tahoe_cmap_analysis/figures/Average_Recall_by_Match_Type.pdf", 
        fig, width = 9, height = 6, dpi = 300, bg = "white")
ggsave("tahoe_cmap_analysis/figures/Average_Recall_by_Match_Type.png", 
        fig, width = 9, height = 6, dpi = 300, bg = "white")

cat("\n✓ Graph saved successfully!\n")
cat("Files created:\n")
cat("  • Average_Recall_by_Match_Type.pdf\n")
cat("  • Average_Recall_by_Match_Type.png\n")

EOF
