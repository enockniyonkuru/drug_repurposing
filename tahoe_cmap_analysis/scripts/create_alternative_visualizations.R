#!/usr/bin/env Rscript

# Alternative Visualizations for Known Drug Pairs
# 1. UpSet Plot
# 2. Grouped Bar Chart
# 3. Sankey Diagram
# 4. Stacked Bar Chart

library(tidyverse)
library(arrow)
library(ggplot2)
library(scales)
suppressPackageStartupMessages({
  library(UpSetR, warn.conflicts = FALSE)
})

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap

figures_dir <- "tahoe_cmap_analysis/figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data...\n")

analysis <- read_csv('tahoe_cmap_analysis/data/analysis/creed_manual_analysis_exp_8/analysis_summary_creed_manual_standardised_results_OG_exp_8_q0.05.csv',
                     show_col_types = FALSE)

cat("✓ Data loaded\n\n")

# ============================================================================
# PREPARE DATA
# ============================================================================

# Available pairs
pairs_in_cmap <- sum(analysis$known_drugs_available_in_cmap_count, na.rm=TRUE)
pairs_in_tahoe <- sum(analysis$known_drugs_available_in_tahoe_count, na.rm=TRUE)

available_both <- analysis %>%
  filter(known_drugs_available_in_cmap_count > 0 & 
         known_drugs_available_in_tahoe_count > 0) %>%
  summarize(total = sum(pmin(known_drugs_available_in_cmap_count, 
                             known_drugs_available_in_tahoe_count))) %>%
  pull(total)

available_cmap_only <- pairs_in_cmap - available_both
available_tahoe_only <- pairs_in_tahoe - available_both

# Recovered pairs
found_in_tahoe <- sum(analysis$tahoe_in_known_count, na.rm=TRUE)
found_in_cmap <- sum(analysis$cmap_in_known_count, na.rm=TRUE)
found_in_both <- sum(analysis$common_in_known_count, na.rm=TRUE)

recovered_cmap_only <- found_in_cmap - found_in_both
recovered_tahoe_only <- found_in_tahoe - found_in_both

cat("Data prepared:\n")
cat("  Available - CMap only: ", available_cmap_only, "\n")
cat("  Available - Tahoe only: ", available_tahoe_only, "\n")
cat("  Available - Both: ", available_both, "\n")
cat("  Recovered - CMap only: ", recovered_cmap_only, "\n")
cat("  Recovered - Tahoe only: ", recovered_tahoe_only, "\n")
cat("  Recovered - Both: ", found_in_both, "\n\n")

# ============================================================================
# 1. UPSET PLOT - AVAILABLE PAIRS
# ============================================================================

cat("Creating UpSet Plot 1: Available Known Drug Pairs...\n")

# Create binary matrix for UpSet
available_upset_data <- data.frame(
  CMap = c(1, 1, 0),
  Tahoe = c(1, 0, 1)
)
rownames(available_upset_data) <- c("Both", "CMap Only", "Tahoe Only")
available_upset_data$value <- c(available_both, available_cmap_only, available_tahoe_only)

png(file.path(figures_dir, "upset_available_known_drugs.png"),
    width = 1200, height = 700, res = 150, bg = "white")

upset(fromList(list(
  CMap = rep(1, pairs_in_cmap),
  Tahoe = rep(1, pairs_in_tahoe)
)),
order.by = "freq",
sets = c("CMap", "Tahoe"),
keep.order = TRUE,
text.scale = c(1.5, 1.3, 1.2, 1.3, 1.5, 1.2))

dev.off()

cat("✓ UpSet Plot 1 (Available) complete\n\n")

# ============================================================================
# 2. UPSET PLOT - RECOVERED PAIRS
# ============================================================================

cat("Creating UpSet Plot 2: Recovered Known Drug Pairs...\n")

png(file.path(figures_dir, "upset_recovered_known_drugs.png"),
    width = 1200, height = 700, res = 150, bg = "white")

upset(fromList(list(
  CMap = rep(1, found_in_cmap),
  Tahoe = rep(1, found_in_tahoe)
)),
order.by = "freq",
sets = c("CMap", "Tahoe"),
keep.order = TRUE,
text.scale = c(1.5, 1.3, 1.2, 1.3, 1.5, 1.2))

dev.off()

cat("✓ UpSet Plot 2 (Recovered) complete\n\n")

# ============================================================================
# 3. GROUPED BAR CHART
# ============================================================================

cat("Creating Grouped Bar Chart...\n")

bar_data <- data.frame(
  Category = c("CMap Only", "Tahoe Only", "Both Platforms"),
  Available = c(available_cmap_only, available_tahoe_only, available_both),
  Recovered = c(recovered_cmap_only, recovered_tahoe_only, found_in_both)
) %>%
  pivot_longer(cols = c(Available, Recovered), names_to = "Type", values_to = "Count")

bar_data$Category <- factor(bar_data$Category, levels = c("CMap Only", "Tahoe Only", "Both Platforms"))

p_grouped <- ggplot(bar_data, aes(x = Category, y = Count, fill = Type)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7, color = "white", linewidth = 1) +
  scale_fill_manual(values = c("Available" = "#E8F4F8", "Recovered" = "#2C5282")) +
  labs(
    title = "Available vs Recovered Known Drug Pairs",
    subtitle = "Comparison across CMap and Tahoe platforms",
    x = "",
    y = "Number of Disease-Drug Pairs",
    fill = "Status"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#555", margin = margin(b = 20)),
    axis.text.x = element_text(size = 12, face = "bold", color = "#333"),
    axis.text.y = element_text(size = 11),
    axis.title.y = element_text(size = 12, face = "bold"),
    legend.position = "top",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.y = element_line(color = "gray92", linewidth = 0.3),
    panel.grid.major.x = element_blank()
  ) +
  geom_text(aes(label = format(Count, big.mark = ",")), 
            position = position_dodge(width = 0.7), vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)))

ggsave(file.path(figures_dir, "grouped_bar_available_recovered.png"),
       p_grouped, width = 12, height = 8, dpi = 300, bg = "white")

cat("✓ Grouped Bar Chart complete\n\n")

# ============================================================================
# 4. SANKEY DIAGRAM - FLOW FROM AVAILABLE TO RECOVERED
# ============================================================================

cat("Creating Sankey Diagram...\n")

# Create simple flow visualization
sankey_data <- data.frame(
  Stage = c(rep("Available", 3), rep("Recovered", 3)),
  Platform = c("CMap", "Tahoe", "Both", "CMap", "Tahoe", "Both"),
  Count = c(available_cmap_only, available_tahoe_only, available_both,
            recovered_cmap_only, recovered_tahoe_only, found_in_both)
)

sankey_data$Platform <- factor(sankey_data$Platform, levels = c("CMap", "Tahoe", "Both"))

p_sankey <- ggplot(sankey_data, aes(x = Stage, y = Count, fill = Platform)) +
  geom_col(position = "stack", width = 0.6, color = "white", linewidth = 1.5) +
  scale_fill_manual(values = c("CMap" = COLOR_CMAP, "Tahoe" = COLOR_TAHOE, "Both" = COLOR_OVERLAP)) +
  labs(
    title = "Flow: Available to Recovered Known Drug Pairs",
    subtitle = "How many available pairs were successfully recovered in top hits",
    x = "",
    y = "Number of Disease-Drug Pairs",
    fill = "Platform"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#555", margin = margin(b = 20)),
    axis.text.x = element_text(size = 12, face = "bold", color = "#333"),
    axis.text.y = element_text(size = 11),
    axis.title.y = element_text(size = 12, face = "bold"),
    legend.position = "right",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.y = element_line(color = "gray92", linewidth = 0.3),
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))

ggsave(file.path(figures_dir, "sankey_available_to_recovered.png"),
       p_sankey, width = 12, height = 8, dpi = 300, bg = "white")

cat("✓ Sankey Diagram complete\n\n")

# ============================================================================
# 5. STACKED BAR CHART
# ============================================================================

cat("Creating Stacked Bar Chart...\n")

stacked_data <- data.frame(
  Stage = c("Available Pairs", "Recovered Pairs"),
  "CMap Only" = c(available_cmap_only, recovered_cmap_only),
  "Tahoe Only" = c(available_tahoe_only, recovered_tahoe_only),
  "Both Platforms" = c(available_both, found_in_both),
  check.names = FALSE
) %>%
  pivot_longer(cols = c("CMap Only", "Tahoe Only", "Both Platforms"), 
               names_to = "Category", values_to = "Count")

stacked_data$Category <- factor(stacked_data$Category, 
                                 levels = c("CMap Only", "Tahoe Only", "Both Platforms"))

p_stacked <- ggplot(stacked_data, aes(x = Stage, y = Count, fill = Category)) +
  geom_bar(stat = "identity", width = 0.5, color = "white", linewidth = 1.5) +
  scale_fill_manual(values = c(
    "CMap Only" = COLOR_CMAP,
    "Tahoe Only" = COLOR_TAHOE,
    "Both Platforms" = COLOR_OVERLAP
  )) +
  labs(
    title = "Known Drug Pairs: Available vs Recovered",
    subtitle = "Distribution across platform combinations",
    x = "",
    y = "Number of Disease-Drug Pairs",
    fill = "Category"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#555", margin = margin(b = 20)),
    axis.text.x = element_text(size = 12, face = "bold", color = "#333"),
    axis.text.y = element_text(size = 11),
    axis.title.y = element_text(size = 12, face = "bold"),
    legend.position = "right",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major.y = element_line(color = "gray92", linewidth = 0.3),
    panel.grid.major.x = element_blank()
  ) +
  geom_text(aes(label = format(Count, big.mark = ",")), 
            position = position_stack(vjust = 0.5), size = 4, fontface = "bold", color = "white") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))

ggsave(file.path(figures_dir, "stacked_bar_available_recovered.png"),
       p_stacked, width = 12, height = 8, dpi = 300, bg = "white")

cat("✓ Stacked Bar Chart complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== ALTERNATIVE VISUALIZATIONS COMPLETE ===\n\n")
cat("Files created:\n")
cat("  1. upset_available_known_drugs.png\n")
cat("  2. upset_recovered_known_drugs.png\n")
cat("  3. grouped_bar_available_recovered.png\n")
cat("  4. sankey_available_to_recovered.png\n")
cat("  5. stacked_bar_available_recovered.png\n\n")
cat("Color Scheme:\n")
cat("  CMap (Orange):   #F39C12\n")
cat("  Tahoe (Blue):    #5DADE2\n")
cat("  Overlap (Purple):#9B59B6\n")
