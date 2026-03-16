#!/usr/bin/env Rscript

# Enhanced Horizontal Sankey Diagram
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
COLOR_RECOVERED <- "#E74C3C" # Red for recovered

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
# CREATE HORIZONTAL SANKEY DIAGRAM
# ============================================================================

cat("Creating Enhanced Horizontal Sankey Diagram...\n")

# Create flow data for alluvial/sankey
# Structure: Source -> Available -> Recovered

# Stage 1: Source datasets
source_data <- data.frame(
  stage = "Source",
  platform = c("CMap", "Tahoe", "Open Targets"),
  count = c(pairs_in_cmap, pairs_in_tahoe, total_known_drugs),
  color = c(COLOR_CMAP, COLOR_TAHOE, COLOR_KNOWN)
)

# Stage 2: Available pairs (split by platform combination)
available_data <- data.frame(
  stage = "Available",
  platform = c("CMap Only", "Tahoe Only", "Both"),
  count = c(available_cmap_only, available_tahoe_only, available_both),
  color = c(COLOR_CMAP, COLOR_TAHOE, COLOR_OVERLAP)
)

# Stage 3: Recovered pairs
recovered_data <- data.frame(
  stage = "Recovered",
  platform = c("CMap Only", "Tahoe Only", "Both"),
  count = c(recovered_cmap_only, recovered_tahoe_only, found_in_both),
  color = c(COLOR_CMAP, COLOR_TAHOE, COLOR_OVERLAP)
)

# Combine all stages
sankey_data <- bind_rows(source_data, available_data, recovered_data)
sankey_data$stage <- factor(sankey_data$stage, levels = c("Source", "Available", "Recovered"))

# Create connections for flow
# From Source to Available
connections_1 <- data.frame(
  from = c("CMap", "CMap", "Tahoe", "Tahoe", "Open Targets"),
  to = c("CMap Only", "Both", "Tahoe Only", "Both", "CMap Only"),
  value = c(available_cmap_only, available_both/2, available_tahoe_only, available_both/2, 0),
  stringsAsFactors = FALSE
)

# From Available to Recovered
connections_2 <- data.frame(
  from = c("CMap Only", "CMap Only", "Tahoe Only", "Tahoe Only", "Both", "Both"),
  to = c("CMap Only", "Both", "Tahoe Only", "Both", "CMap Only", "Both"),
  value = c(min(recovered_cmap_only, available_cmap_only),
            min(found_in_both, available_both),
            min(recovered_tahoe_only, available_tahoe_only),
            min(found_in_both, available_both),
            max(0, recovered_cmap_only - available_cmap_only),
            max(0, recovered_tahoe_only - available_tahoe_only)),
  stringsAsFactors = FALSE
)

# Create a more visual representation using ggplot
p_sankey <- ggplot() +
  # Source stage
  geom_rect(aes(xmin = 0, xmax = 1, ymin = 0, ymax = pairs_in_cmap/total_known_drugs),
            fill = COLOR_CMAP, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 0.5, y = pairs_in_cmap/(2*total_known_drugs), label = "CMap"),
            size = 4, fontface = "bold", color = "white") +
  geom_text(aes(x = 0.5, y = pairs_in_cmap/(2*total_known_drugs), label = format(pairs_in_cmap, big.mark = ",")),
            size = 3.5, fontface = "bold", color = "white", vjust = 1.8) +
  
  geom_rect(aes(xmin = 0, xmax = 1, ymin = pairs_in_cmap/total_known_drugs, 
                ymax = (pairs_in_cmap + pairs_in_tahoe)/total_known_drugs),
            fill = COLOR_TAHOE, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 0.5, y = (pairs_in_cmap + pairs_in_tahoe/2)/total_known_drugs, label = "Tahoe"),
            size = 4, fontface = "bold", color = "white") +
  geom_text(aes(x = 0.5, y = (pairs_in_cmap + pairs_in_tahoe/2)/total_known_drugs, label = format(pairs_in_tahoe, big.mark = ",")),
            size = 3.5, fontface = "bold", color = "white", vjust = 1.8) +
  
  geom_rect(aes(xmin = 0, xmax = 1, ymin = (pairs_in_cmap + pairs_in_tahoe)/total_known_drugs, 
                ymax = 1),
            fill = COLOR_KNOWN, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 0.5, y = (pairs_in_cmap + pairs_in_tahoe + total_known_drugs/2)/total_known_drugs, 
                label = "Open Targets"),
            size = 4, fontface = "bold", color = "white") +
  geom_text(aes(x = 0.5, y = (pairs_in_cmap + pairs_in_tahoe + total_known_drugs/2)/total_known_drugs, 
                label = format(total_known_drugs, big.mark = ",")),
            size = 3.5, fontface = "bold", color = "white", vjust = 1.8) +
  
  # Available stage
  geom_rect(aes(xmin = 2, xmax = 3, ymin = 0, ymax = available_cmap_only/total_known_drugs),
            fill = COLOR_CMAP, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 2.5, y = available_cmap_only/(2*total_known_drugs), label = "CMap Only"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 2.5, y = available_cmap_only/(2*total_known_drugs), label = format(available_cmap_only, big.mark = ",")),
            size = 3, fontface = "bold", color = "white", vjust = 1.8) +
  
  geom_rect(aes(xmin = 2, xmax = 3, ymin = available_cmap_only/total_known_drugs, 
                ymax = (available_cmap_only + available_tahoe_only)/total_known_drugs),
            fill = COLOR_TAHOE, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 2.5, y = (available_cmap_only + available_tahoe_only/2)/total_known_drugs, label = "Tahoe Only"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 2.5, y = (available_cmap_only + available_tahoe_only/2)/total_known_drugs, label = format(available_tahoe_only, big.mark = ",")),
            size = 3, fontface = "bold", color = "white", vjust = 1.8) +
  
  geom_rect(aes(xmin = 2, xmax = 3, ymin = (available_cmap_only + available_tahoe_only)/total_known_drugs, 
                ymax = (available_cmap_only + available_tahoe_only + available_both)/total_known_drugs),
            fill = COLOR_OVERLAP, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 2.5, y = (available_cmap_only + available_tahoe_only + available_both/2)/total_known_drugs, label = "Both"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 2.5, y = (available_cmap_only + available_tahoe_only + available_both/2)/total_known_drugs, label = format(available_both, big.mark = ",")),
            size = 3, fontface = "bold", color = "white", vjust = 1.8) +
  
  # Recovered stage
  geom_rect(aes(xmin = 4, xmax = 5, ymin = 0, ymax = recovered_cmap_only/total_known_drugs),
            fill = COLOR_CMAP, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 4.5, y = recovered_cmap_only/(2*total_known_drugs), label = "CMap Only"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 4.5, y = recovered_cmap_only/(2*total_known_drugs), label = format(recovered_cmap_only, big.mark = ",")),
            size = 3, fontface = "bold", color = "white", vjust = 1.8) +
  
  geom_rect(aes(xmin = 4, xmax = 5, ymin = recovered_cmap_only/total_known_drugs, 
                ymax = (recovered_cmap_only + recovered_tahoe_only)/total_known_drugs),
            fill = COLOR_TAHOE, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 4.5, y = (recovered_cmap_only + recovered_tahoe_only/2)/total_known_drugs, label = "Tahoe Only"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 4.5, y = (recovered_cmap_only + recovered_tahoe_only/2)/total_known_drugs, label = format(recovered_tahoe_only, big.mark = ",")),
            size = 3, fontface = "bold", color = "white", vjust = 1.8) +
  
  geom_rect(aes(xmin = 4, xmax = 5, ymin = (recovered_cmap_only + recovered_tahoe_only)/total_known_drugs, 
                ymax = (recovered_cmap_only + recovered_tahoe_only + found_in_both)/total_known_drugs),
            fill = COLOR_OVERLAP, alpha = 0.8, color = "white", linewidth = 1.5) +
  geom_text(aes(x = 4.5, y = (recovered_cmap_only + recovered_tahoe_only + found_in_both/2)/total_known_drugs, label = "Both"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 4.5, y = (recovered_cmap_only + recovered_tahoe_only + found_in_both/2)/total_known_drugs, label = format(found_in_both, big.mark = ",")),
            size = 3, fontface = "bold", color = "white", vjust = 1.8) +
  
  # Stage labels
  geom_text(aes(x = 0.5, y = 1.08, label = "SOURCE DATASETS"),
            size = 4.5, fontface = "bold", hjust = 0.5) +
  geom_text(aes(x = 2.5, y = 1.08, label = "AVAILABLE PAIRS"),
            size = 4.5, fontface = "bold", hjust = 0.5) +
  geom_text(aes(x = 4.5, y = 1.08, label = "RECOVERED PAIRS"),
            size = 4.5, fontface = "bold", hjust = 0.5) +
  
  # Title and subtitle
  labs(
    title = "Known Drug Pairs: From Source Datasets to Recovery",
    subtitle = "Flow through data integration and ranking stages"
  ) +
  
  # Theme
  theme_void() +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "#555", margin = margin(b = 30)),
    plot.margin = margin(20, 20, 20, 20)
  ) +
  xlim(-0.5, 5.5) +
  ylim(-0.1, 1.15)

ggsave(file.path(figures_dir, "sankey_horizontal_known_drugs_flow.png"),
       p_sankey, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Enhanced Horizontal Sankey Diagram complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== SANKEY DIAGRAM COMPLETE ===\n\n")
cat("File created:\n")
cat("  sankey_horizontal_known_drugs_flow.png\n\n")
cat("Flow:\n")
cat("  Source: CMap (", pairs_in_cmap, ") → Tahoe (", pairs_in_tahoe, ") → Open Targets (", total_known_drugs, ")\n")
cat("  Available: CMap Only (", available_cmap_only, ") → Tahoe Only (", available_tahoe_only, ") → Both (", available_both, ")\n")
cat("  Recovered: CMap Only (", recovered_cmap_only, ") → Tahoe Only (", recovered_tahoe_only, ") → Both (", found_in_both, ")\n\n")
cat("Color Scheme:\n")
cat("  CMap (Orange):     #F39C12\n")
cat("  Tahoe (Blue):      #5DADE2\n")
cat("  Open Targets (Green): #27AE60\n")
cat("  Overlap (Purple):  #9B59B6\n")
