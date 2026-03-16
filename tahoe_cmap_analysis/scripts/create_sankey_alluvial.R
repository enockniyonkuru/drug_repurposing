#!/usr/bin/env Rscript

# Sankey Diagram with ggalluvial-style flowing ribbons
# Shows flow: Source Datasets -> Available Pairs -> Recovered Pairs

library(tidyverse)
library(arrow)
library(ggplot2)
library(scales)

# ============================================================================
# Install ggalluvial if needed
# ============================================================================

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
COLOR_KNOWN <- "#27AE60"     # Green for Open Targets
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap
COLOR_NOT_REC <- "#95A5A6"   # Gray for not recovered

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

# Total known drugs
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
not_recovered <- (available_cmap_only + available_tahoe_only + available_both) - (recovered_cmap_only + recovered_tahoe_only + found_in_both)

cat("Data Summary:\n")
cat("Total Known Drugs: ", total_known_drugs, "\n")
cat("Available Pairs: ", available_cmap_only + available_tahoe_only + available_both, "\n")
cat("Recovered Pairs: ", recovered_cmap_only + recovered_tahoe_only + found_in_both, "\n\n")

# ============================================================================
# CREATE ALLUVIAL DATA
# ============================================================================

# Create flow data with categories for each stage
alluvial_data <- tribble(
  ~source, ~available, ~recovered, ~count, ~stratum,
  
  # CMap flows
  "CMap", "CMap Only", "Recovered", recovered_cmap_only, "cmap",
  "CMap", "CMap Only", "Not Recovered", available_cmap_only - recovered_cmap_only, "cmap_nr",
  
  # Tahoe flows
  "Tahoe", "Tahoe Only", "Recovered", recovered_tahoe_only, "tahoe",
  "Tahoe", "Tahoe Only", "Not Recovered", available_tahoe_only - recovered_tahoe_only, "tahoe_nr",
  
  # Both flows
  "Both CMap\n& Tahoe", "Both", "Recovered", found_in_both, "both",
  "Both CMap\n& Tahoe", "Both", "Not Recovered", available_both - found_in_both, "both_nr",
  
  # Open Targets reference (small flow)
  "Open Targets\n(4,262 drugs)", "Reference", "Reference", 100, "known"
)

# Rename for alluvial
alluvial_data <- alluvial_data %>%
  mutate(
    source = factor(source, levels = c("CMap", "Tahoe", "Both CMap\n& Tahoe", "Open Targets\n(4,262 drugs)")),
    available = factor(available, levels = c("CMap Only", "Tahoe Only", "Both", "Reference")),
    recovered = factor(recovered, levels = c("Recovered", "Not Recovered", "Reference")),
    fill = case_when(
      stratum == "cmap" ~ COLOR_CMAP,
      stratum == "cmap_nr" ~ COLOR_NOT_REC,
      stratum == "tahoe" ~ COLOR_TAHOE,
      stratum == "tahoe_nr" ~ COLOR_NOT_REC,
      stratum == "both" ~ COLOR_OVERLAP,
      stratum == "both_nr" ~ COLOR_NOT_REC,
      stratum == "known" ~ COLOR_KNOWN,
      TRUE ~ "gray70"
    )
  )

cat("Creating Sankey Diagram with ggalluvial...\n")

p_sankey <- ggplot(alluvial_data, aes(x = source, stratum = recovered, alluvium = stratum,
                                       y = count, fill = fill, label = recovered)) +
  geom_flow(stat = "flow", lodes = "backward", color = "white", alpha = 0.6, linewidth = 0.8) +
  geom_stratum(color = "white", linewidth = 1.2, alpha = 0.85) +
  scale_fill_identity() +
  labs(
    title = "Known Drug Pairs: From Source Datasets to Recovery",
    subtitle = "Flow of disease-drug pairs through integration and ranking stages",
    x = "",
    y = "Number of Pairs"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "#555", margin = margin(b = 20)),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 11),
    axis.title.y = element_text(size = 12, face = "bold"),
    legend.position = "none",
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(20, 20, 20, 20)
  )

ggsave(file.path(figures_dir, "sankey_alluvial_known_drugs.png"),
       p_sankey, width = 14, height = 9, dpi = 300, bg = "white")

cat("✓ Sankey Diagram complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== SANKEY DIAGRAM COMPLETE ===\n\n")
cat("File created:\n")
cat("  sankey_alluvial_known_drugs.png\n\n")
cat("Flow Summary:\n")
cat("  Source: CMap (", pairs_in_cmap, ") + Tahoe (", pairs_in_tahoe, ") + Open Targets (", total_known_drugs, ")\n")
cat("  Available: CMap Only (", available_cmap_only, ") + Tahoe Only (", available_tahoe_only, ") + Both (", available_both, ")\n")
cat("  Recovered: ", recovered_cmap_only + recovered_tahoe_only + found_in_both, "\n")
cat("  Not Recovered: ", not_recovered, "\n\n")
cat("Recovery Rates:\n")
cat("  CMap: ", sprintf("%.1f%%", 100*recovered_cmap_only/available_cmap_only), "\n")
cat("  Tahoe: ", sprintf("%.1f%%", 100*recovered_tahoe_only/available_tahoe_only), "\n")
cat("  Both: ", sprintf("%.1f%%", 100*found_in_both/available_both), "\n\n")
cat("Color Scheme:\n")
cat("  CMap (Orange):     #F39C12\n")
cat("  Tahoe (Blue):      #5DADE2\n")
cat("  Overlap (Purple):  #9B59B6\n")
cat("  Open Targets (Green): #27AE60\n")
cat("  Not Recovered (Gray): #95A5A6\n")
