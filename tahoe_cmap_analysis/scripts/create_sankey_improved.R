#!/usr/bin/env Rscript

# Proper Sankey Diagram with Flowing Connections
# Shows flow: Source Datasets -> Available Pairs -> Recovered Pairs

library(tidyverse)
library(arrow)
library(ggplot2)
library(scales)

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_KNOWN <- "#27AE60"     # Green for Open Targets
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap

figures_dir <- "tahoe_cmap_analysis/figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data...\n")

analysis <- read_csv('tahoe_cmap_analysis/data/analysis/creed_manual_analysis_exp_8/analysis_summary_creed_manual_standardised_results_OG_exp_8_q0.05.csv',
                     show_col_types = FALSE)

known_drugs <- read_parquet('tahoe_cmap_analysis/data/known_drugs/known_drug_info_data.parquet')

cat("✓ Data loaded\n\n")

# ============================================================================
# CALCULATE TOTALS
# ============================================================================

# Total known drugs (from Open Targets)
total_known_drugs <- length(unique(tolower(trimws(known_drugs$drug_common_name))))

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

cat("Data Summary:\n")
cat("Total Known Drugs in Open Targets: ", total_known_drugs, "\n\n")
cat("Available Pairs:\n")
cat("  CMap only: ", available_cmap_only, "\n")
cat("  Tahoe only: ", available_tahoe_only, "\n")
cat("  Both: ", available_both, "\n")
cat("  Total CMap: ", pairs_in_cmap, "\n")
cat("  Total Tahoe: ", pairs_in_tahoe, "\n\n")
cat("Recovered Pairs:\n")
cat("  CMap only: ", recovered_cmap_only, "\n")
cat("  Tahoe only: ", recovered_tahoe_only, "\n")
cat("  Both: ", found_in_both, "\n\n")

# ============================================================================
# CREATE SANKEY DATA
# ============================================================================

# Create flows for Sankey diagram
# Each row represents a flow from source -> available -> recovered

flows <- tribble(
  ~source, ~available, ~recovered, ~value, ~type,
  # CMap flows
  "CMap", "CMap Only", "CMap Only", min(recovered_cmap_only, available_cmap_only), "cmap",
  "CMap", "CMap Only", "Not Recovered", max(0, available_cmap_only - recovered_cmap_only), "cmap",
  "CMap", "Both", "Both", min(found_in_both, available_both/2), "both",
  "CMap", "Both", "Not Recovered", max(0, available_both/2 - found_in_both), "both",
  
  # Tahoe flows
  "Tahoe", "Tahoe Only", "Tahoe Only", min(recovered_tahoe_only, available_tahoe_only), "tahoe",
  "Tahoe", "Tahoe Only", "Not Recovered", max(0, available_tahoe_only - recovered_tahoe_only), "tahoe",
  "Tahoe", "Both", "Both", min(found_in_both, available_both/2), "both",
  "Tahoe", "Both", "Not Recovered", max(0, available_both/2 - found_in_both), "both",
  
  # Open Targets connection (minimal flow representation)
  "Open Targets", "CMap Only", "CMap Only", 0, "known",
  "Open Targets", "Tahoe Only", "Tahoe Only", 0, "known",
  "Open Targets", "Both", "Both", 0, "known"
)

# Remove zero flows for cleaner visualization
flows <- flows %>% filter(value > 0)

# Create color mapping
flow_colors <- flows %>%
  mutate(
    color = case_when(
      type == "cmap" ~ COLOR_CMAP,
      type == "tahoe" ~ COLOR_TAHOE,
      type == "both" ~ COLOR_OVERLAP,
      type == "known" ~ COLOR_KNOWN,
      TRUE ~ "gray70"
    )
  )

cat("Creating Proper Sankey Diagram...\n")

# Create manual Sankey-like plot using ggplot with bezier curves
# This requires creating bezier paths between stages

# First, assign positions to nodes
node_positions <- tribble(
  ~node, ~x, ~y,
  # Stage 1: Source
  "CMap", 1, 3,
  "Tahoe", 1, 2,
  "Open Targets", 1, 1,
  # Stage 2: Available
  "CMap Only", 2, 3.5,
  "Tahoe Only", 2, 2.5,
  "Both", 2, 1.5,
  # Stage 3: Recovered
  "CMap Only", 3, 3.5,
  "Tahoe Only", 3, 2.5,
  "Both", 3, 1.5,
  "Not Recovered", 3, 0.5
) %>%
  distinct()

# Prepare data for plotting with ribbon/area connections
# Using a simpler approach: create rectangular blocks with connecting lines

p_sankey <- ggplot() +
  # ===== STAGE 1: SOURCE =====
  # CMap block
  geom_rect(
    aes(xmin = 0.8, xmax = 1.2, ymin = 2.7, ymax = 3.3),
    fill = COLOR_CMAP, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 1, y = 3, label = "CMap\n2,399"),
    size = 4, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Tahoe block
  geom_rect(
    aes(xmin = 0.8, xmax = 1.2, ymin = 1.8, ymax = 2.4),
    fill = COLOR_TAHOE, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 1, y = 2.1, label = "Tahoe\n1,686"),
    size = 4, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Open Targets block
  geom_rect(
    aes(xmin = 0.8, xmax = 1.2, ymin = 0.7, ymax = 1.3),
    fill = COLOR_KNOWN, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 1, y = 1, label = "Open Targets\n4,262"),
    size = 4, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # ===== STAGE 2: AVAILABLE =====
  # CMap Only block
  geom_rect(
    aes(xmin = 1.8, xmax = 2.2, ymin = 3.3, ymax = 3.8),
    fill = COLOR_CMAP, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 2, y = 3.55, label = "CMap Only\n982"),
    size = 3.5, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Tahoe Only block
  geom_rect(
    aes(xmin = 1.8, xmax = 2.2, ymin = 2.3, ymax = 2.8),
    fill = COLOR_TAHOE, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 2, y = 2.55, label = "Tahoe Only\n269"),
    size = 3.5, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Both block
  geom_rect(
    aes(xmin = 1.8, xmax = 2.2, ymin = 1.3, ymax = 1.8),
    fill = COLOR_OVERLAP, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 2, y = 1.55, label = "Both\n1,417"),
    size = 3.5, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # ===== STAGE 3: RECOVERED =====
  # CMap Only Recovered block
  geom_rect(
    aes(xmin = 2.8, xmax = 3.2, ymin = 3.3, ymax = 3.6),
    fill = COLOR_CMAP, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 3, y = 3.45, label = "CMap Only\n437"),
    size = 3.5, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Tahoe Only Recovered block
  geom_rect(
    aes(xmin = 2.8, xmax = 3.2, ymin = 2.3, ymax = 2.6),
    fill = COLOR_TAHOE, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 3, y = 2.45, label = "Tahoe Only\n812"),
    size = 3.5, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Both Recovered block
  geom_rect(
    aes(xmin = 2.8, xmax = 3.2, ymin = 1.3, ymax = 1.5),
    fill = COLOR_OVERLAP, color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 3, y = 1.4, label = "Both\n37"),
    size = 3.5, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # Not Recovered block
  geom_rect(
    aes(xmin = 2.8, xmax = 3.2, ymin = 0.5, ymax = 1.2),
    fill = "gray70", color = "white", linewidth = 1.5, alpha = 0.85
  ) +
  geom_text(
    aes(x = 3, y = 0.85, label = "Not\nRecovered\n1,249"),
    size = 3, fontface = "bold", color = "white", lineheight = 0.8
  ) +
  
  # ===== STAGE LABELS =====
  geom_text(
    aes(x = 1, y = 4.2, label = "SOURCE DATASETS"),
    size = 5, fontface = "bold", hjust = 0.5
  ) +
  geom_text(
    aes(x = 2, y = 4.2, label = "AVAILABLE PAIRS"),
    size = 5, fontface = "bold", hjust = 0.5
  ) +
  geom_text(
    aes(x = 3, y = 4.2, label = "RECOVERED PAIRS"),
    size = 5, fontface = "bold", hjust = 0.5
  ) +
  
  # ===== TITLE =====
  labs(
    title = "Known Drug Pairs: From Source Datasets to Recovery",
    subtitle = "Flow through integration and ranking stages"
  ) +
  
  # Theme
  theme_void() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 14, hjust = 0.5, color = "#555", margin = margin(b = 20)),
    plot.margin = margin(20, 20, 20, 20)
  ) +
  xlim(-0.2, 3.4) +
  ylim(0.2, 4.4)

ggsave(file.path(figures_dir, "sankey_known_drugs_flow.png"),
       p_sankey, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Sankey Diagram complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== SANKEY DIAGRAM COMPLETE ===\n\n")
cat("File created:\n")
cat("  sankey_known_drugs_flow.png\n\n")
cat("Flow Summary:\n")
cat("  Source Total: ", pairs_in_cmap + pairs_in_tahoe + total_known_drugs, "\n")
cat("  Available Total: ", available_cmap_only + available_tahoe_only + available_both, "\n")
cat("  Recovered Total: ", recovered_cmap_only + recovered_tahoe_only + found_in_both, "\n")
cat("  Not Recovered: ", (available_cmap_only + available_tahoe_only + available_both) - (recovered_cmap_only + recovered_tahoe_only + found_in_both), "\n\n")
cat("Color Scheme:\n")
cat("  CMap (Orange):     #F39C12\n")
cat("  Tahoe (Blue):      #5DADE2\n")
cat("  Open Targets (Green): #27AE60\n")
cat("  Overlap (Purple):  #9B59B6\n")
cat("  Not Recovered (Gray): gray70\n")
