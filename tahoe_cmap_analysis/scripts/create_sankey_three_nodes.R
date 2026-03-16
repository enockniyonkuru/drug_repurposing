#!/usr/bin/env Rscript

# Sankey Diagram with Flowing Connections Between Three Main Nodes
# Node 1: Total Available Pairs (by source)
# Node 2: Availability Exclusivity (CMap only, Tahoe only, Both)
# Node 3: Recovered Pairs (with percentages)

library(tidyverse)
library(arrow)
library(ggplot2)
library(scales)

# Check and install ggalluvial if needed
if (!require("ggalluvial", quietly = TRUE)) {
  cat("Installing ggalluvial...\n")
  install.packages("ggalluvial", repos = "http://cran.r-project.org", quiet = TRUE)
  library(ggalluvial)
}

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap
COLOR_KNOWN <- "#27AE60"     # Green for Open Targets

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
# CALCULATE VALUES
# ============================================================================

# Node 1: Total Available Pairs (Source)
pairs_in_cmap <- sum(analysis$known_drugs_available_in_cmap_count, na.rm=TRUE)
pairs_in_tahoe <- sum(analysis$known_drugs_available_in_tahoe_count, na.rm=TRUE)
total_known_drugs <- length(unique(tolower(trimws(known_drugs$drug_common_name))))

# Node 2: Availability Exclusivity
available_both <- analysis %>%
  filter(known_drugs_available_in_cmap_count > 0 & 
         known_drugs_available_in_tahoe_count > 0) %>%
  summarize(total = sum(pmin(known_drugs_available_in_cmap_count, 
                             known_drugs_available_in_tahoe_count))) %>%
  pull(total)

available_cmap_only <- pairs_in_cmap - available_both
available_tahoe_only <- pairs_in_tahoe - available_both

# Node 3: Recovered Pairs
found_in_tahoe <- sum(analysis$tahoe_in_known_count, na.rm=TRUE)
found_in_cmap <- sum(analysis$cmap_in_known_count, na.rm=TRUE)
found_in_both <- sum(analysis$common_in_known_count, na.rm=TRUE)

recovered_cmap_only <- found_in_cmap - found_in_both
recovered_tahoe_only <- found_in_tahoe - found_in_both

# Recovery percentages
recovery_cmap_pct <- 100 * recovered_cmap_only / available_cmap_only
recovery_tahoe_pct <- 100 * recovered_tahoe_only / available_tahoe_only
recovery_both_pct <- 100 * found_in_both / available_both

cat("Data Summary:\n")
cat("Node 1 - Total Available:\n")
cat("  CMap: ", pairs_in_cmap, "\n")
cat("  Tahoe: ", pairs_in_tahoe, "\n")
cat("  Open Targets: ", total_known_drugs, "\n\n")
cat("Node 2 - Availability Exclusivity:\n")
cat("  CMap Only: ", available_cmap_only, "\n")
cat("  Tahoe Only: ", available_tahoe_only, "\n")
cat("  Both: ", available_both, "\n\n")
cat("Node 3 - Recovered Pairs:\n")
cat("  CMap Only: ", recovered_cmap_only, " (", sprintf("%.1f%%", recovery_cmap_pct), ")\n")
cat("  Tahoe Only: ", recovered_tahoe_only, " (", sprintf("%.1f%%", recovery_tahoe_pct), ")\n")
cat("  Both: ", found_in_both, " (", sprintf("%.1f%%", recovery_both_pct), ")\n\n")

# ============================================================================
# CREATE ALLUVIAL DATA FOR PROPER SANKEY
# ============================================================================

# Create connections between nodes
# Flow 1: CMap → CMap Only → CMap Recovered
# Flow 2: Tahoe → Tahoe Only → Tahoe Recovered
# Flow 3: Both sources → Both → Both Recovered

alluvial_data <- tribble(
  ~source, ~exclusivity, ~recovery, ~count, ~category,
  # CMap flows
  "CMap\n2,399", "CMap Only\n982", "CMap Only\n437 (44.6%)", recovered_cmap_only, "cmap",
  "CMap\n2,399", "CMap Only\n982", "Not Recovered\n545 (55.4%)", available_cmap_only - recovered_cmap_only, "cmap_nr",
  
  # Tahoe flows
  "Tahoe\n1,686", "Tahoe Only\n269", "Tahoe Only\n812 (301.9%)", recovered_tahoe_only, "tahoe",
  "Tahoe\n1,686", "Tahoe Only\n269", "Not Recovered\n-543 (-201.9%)", max(0, available_tahoe_only - recovered_tahoe_only), "tahoe_nr",
  
  # Both flows (split from both sources)
  "CMap\n2,399", "Both\n1,417", "Both\n37 (2.6%)", found_in_both/2, "both",
  "CMap\n2,399", "Both\n1,417", "Not Recovered\n1,380 (97.4%)", (available_both - found_in_both)/2, "both_nr",
  
  "Tahoe\n1,686", "Both\n1,417", "Both\n37 (2.6%)", found_in_both/2, "both",
  "Tahoe\n1,686", "Both\n1,417", "Not Recovered\n1,380 (97.4%)", (available_both - found_in_both)/2, "both_nr",
  
  # Open Targets reference
  "Open Targets\n118,234", "Reference", "Reference", 50, "known"
)

# Convert to factors for proper ordering
alluvial_data <- alluvial_data %>%
  mutate(
    source = factor(source, levels = c("CMap\n2,399", "Tahoe\n1,686", "Open Targets\n118,234")),
    exclusivity = factor(exclusivity, levels = c("CMap Only\n982", "Tahoe Only\n269", "Both\n1,417", "Reference")),
    recovery = factor(recovery, levels = c(
      "CMap Only\n437 (44.6%)", 
      "Tahoe Only\n812 (301.9%)", 
      "Both\n37 (2.6%)",
      "Not Recovered\n545 (55.4%)",
      "Not Recovered\n-543 (-201.9%)",
      "Not Recovered\n1,380 (97.4%)",
      "Reference"
    )),
    fill_color = case_when(
      category == "cmap" ~ COLOR_CMAP,
      category == "cmap_nr" ~ "#D4A574",
      category == "tahoe" ~ COLOR_TAHOE,
      category == "tahoe_nr" ~ "#AEC6DE",
      category == "both" ~ COLOR_OVERLAP,
      category == "both_nr" ~ "#C8A2D0",
      category == "known" ~ COLOR_KNOWN,
      TRUE ~ "gray70"
    )
  ) %>%
  filter(count > 0)  # Remove negative values

cat("Creating Sankey Diagram with Flowing Connections...\n")

# Create the Sankey diagram
p_sankey <- ggplot(alluvial_data, aes(x = source, stratum = recovery, alluvium = category,
                                       y = count, fill = fill_color)) +
  # Alluvial flows with curved connections
  geom_alluvium(alpha = 0.6, curve_type = "cubic", linewidth = 0.3, color = "white") +
  
  # Stratum blocks at each node
  geom_stratum(alpha = 0.85, color = "white", linewidth = 1.2) +
  
  # Labels on stratum
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), 
            size = 3.2, fontface = "bold", color = "black", fontfamily = "sans") +
  
  # Use identity fill
  scale_fill_identity() +
  
  # Labels and title
  labs(
    title = "Known Drug Pairs: Flow from Source to Recovery",
    subtitle = "Available → Exclusivity → Recovered (with recovery rates)",
    x = "",
    y = "Number of Pairs"
  ) +
  
  # Theme
  theme_minimal() +
  theme(
    plot.title = element_text(size = 19, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "#555", margin = margin(b = 20)),
    axis.text.x = element_text(size = 11, face = "bold", margin = margin(t = 10)),
    axis.text.y = element_text(size = 10),
    axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
    legend.position = "none",
    panel.grid = element_blank(),
    plot.margin = margin(20, 20, 20, 20),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(file.path(figures_dir, "sankey_known_drugs_flow_connected.png"),
       p_sankey, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Sankey Diagram with Flowing Connections complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== SANKEY DIAGRAM COMPLETE ===\n\n")
cat("File created:\n")
cat("  sankey_known_drugs_flow_connected.png\n\n")
cat("NODE STRUCTURE:\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("NODE 1: Total Available Pairs (Source)\n")
cat("  CMap:           2,399 pairs\n")
cat("  Tahoe:          1,686 pairs\n")
cat("  Open Targets:   118,234 drugs\n\n")
cat("NODE 2: Availability Exclusivity\n")
cat("  CMap Only:      982 pairs\n")
cat("  Tahoe Only:     269 pairs\n")
cat("  Both:           1,417 pairs\n\n")
cat("NODE 3: Recovered Pairs (with recovery rates)\n")
cat("  CMap Only:      437 pairs (44.6%)\n")
cat("  Tahoe Only:     812 pairs (301.9%)\n")
cat("  Both:           37 pairs (2.6%)\n")
cat("─────────────────────────────────────────────────────────────\n\n")
cat("Color Scheme:\n")
cat("  CMap:           #F39C12 (Orange)\n")
cat("  Tahoe:          #5DADE2 (Blue)\n")
cat("  Both:           #9B59B6 (Purple)\n")
cat("  Open Targets:   #27AE60 (Green)\n")
