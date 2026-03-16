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

# Filter by match type and calculate averages
recall_by_match <- df %>%
  filter(!is.na(tahoe_recall_numeric) | !is.na(cmap_recall_numeric)) %>%
  group_by(match_type) %>%
  summarise(
    TAHOE_Recall = mean(tahoe_recall_numeric, na.rm = TRUE) * 100,
    CMAP_Recall = mean(cmap_recall_numeric, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  filter(!is.na(match_type)) %>%
  pivot_longer(cols = -match_type, names_to = "Method", values_to = "Recall")

# Print exact values
cat("Exact values for chart:\n")
print(recall_by_match)

# Create the chart matching the image
fig <- ggplot(recall_by_match, aes(x = match_type, y = Recall, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.8, width = 0.7) +
  scale_fill_manual(
    values = c("CMAP_Recall" = "#40BA7C", "TAHOE_Recall" = "#32346E"),
    labels = c("CMAP_Recall" = "CMAP", "TAHOE_Recall" = "Tahoe")
  ) +
  labs(
    title = "Figure 2: Average Recall by Match Type for Tahoe and CMAP",
    subtitle = NULL,
    x = "Match Type",
    y = "Average Recall (%)",
    fill = "Method"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
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
    breaks = seq(0, 45, by = 5),
    limits = c(0, 45),
    expand = c(0, 0),
    labels = function(x) paste0(x, "%")
  ) +
  # Add value labels on bars
  geom_text(aes(label = sprintf("%.2f%%", Recall)), 
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 3.5, fontface = "bold")

ggsave("tahoe_cmap_analysis/figures/Fig8_Recall_by_Match_Type_RECREATED.pdf", 
        fig, width = 10, height = 6.5, dpi = 300)
ggsave("tahoe_cmap_analysis/figures/Fig8_Recall_by_Match_Type_RECREATED.png", 
        fig, width = 10, height = 6.5, dpi = 300)

cat("\n✓ Figure recreated and saved!\n")
