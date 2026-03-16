#!/usr/bin/env Rscript

# Three Alternative Horizontal Sankey Diagrams
# Based on: sankey_horizontal_known_drugs_flow.png
# Alternative 1: With curved flowing connections (ribbons)
# Alternative 2: With gradient fills and more elegant design
# Alternative 3: With connecting lines and minimalist approach

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

total_known_drugs <- length(unique(tolower(trimws(known_drugs$drug_common_name))))

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

found_in_tahoe <- sum(analysis$tahoe_in_known_count, na.rm=TRUE)
found_in_cmap <- sum(analysis$cmap_in_known_count, na.rm=TRUE)
found_in_both <- sum(analysis$common_in_known_count, na.rm=TRUE)

recovered_cmap_only <- found_in_cmap - found_in_both
recovered_tahoe_only <- found_in_tahoe - found_in_both

# ============================================================================
# ALTERNATIVE 1: CURVED RIBBON FLOWS
# ============================================================================

cat("Creating Alternative 1: Curved Ribbon Flows...\n")

# Function to create bezier curve points
create_bezier_ribbon <- function(x1, y1_top, y1_bottom, x2, y2_top, y2_bottom, resolution = 50) {
  t <- seq(0, 1, length.out = resolution)
  
  # Cubic bezier for smooth curves
  x <- (1-t)^3 * x1 + 3*(1-t)^2*t * (x1 + x2)/2 + 3*(1-t)*t^2 * (x1 + x2)/2 + t^3 * x2
  y_top <- (1-t)^3 * y1_top + 3*(1-t)^2*t * (y1_top + y2_top)/2 + 3*(1-t)*t^2 * (y1_top + y2_top)/2 + t^3 * y2_top
  y_bottom <- (1-t)^3 * y1_bottom + 3*(1-t)^2*t * (y1_bottom + y2_bottom)/2 + 3*(1-t)*t^2 * (y1_bottom + y2_bottom)/2 + t^3 * y2_bottom
  
  list(x = x, y_top = y_top, y_bottom = y_bottom, t = t)
}

# Create bezier curves for flows
ribbon_cmap_avail <- create_bezier_ribbon(0.5, 2.7, 3.3, 1.5, 3.3, 3.8)
ribbon_tahoe_avail <- create_bezier_ribbon(0.5, 1.8, 2.4, 1.5, 2.3, 2.8)
ribbon_both_avail <- create_bezier_ribbon(0.5, 0.7, 1.3, 1.5, 1.3, 1.8)

ribbon_cmap_rec <- create_bezier_ribbon(1.5, 3.3, 3.8, 2.5, 3.3, 3.6)
ribbon_tahoe_rec <- create_bezier_ribbon(1.5, 2.3, 2.8, 2.5, 2.3, 2.6)
ribbon_both_rec <- create_bezier_ribbon(1.5, 1.3, 1.8, 2.5, 1.3, 1.5)

p1 <- ggplot() +
  # Ribbon flows between stages
  geom_ribbon(aes(x = ribbon_cmap_avail$x, ymin = ribbon_cmap_avail$y_bottom, ymax = ribbon_cmap_avail$y_top),
              fill = COLOR_CMAP, alpha = 0.5, color = NA) +
  geom_ribbon(aes(x = ribbon_tahoe_avail$x, ymin = ribbon_tahoe_avail$y_bottom, ymax = ribbon_tahoe_avail$y_top),
              fill = COLOR_TAHOE, alpha = 0.5, color = NA) +
  geom_ribbon(aes(x = ribbon_both_avail$x, ymin = ribbon_both_avail$y_bottom, ymax = ribbon_both_avail$y_top),
              fill = COLOR_OVERLAP, alpha = 0.5, color = NA) +
  
  geom_ribbon(aes(x = ribbon_cmap_rec$x, ymin = ribbon_cmap_rec$y_bottom, ymax = ribbon_cmap_rec$y_top),
              fill = COLOR_CMAP, alpha = 0.5, color = NA) +
  geom_ribbon(aes(x = ribbon_tahoe_rec$x, ymin = ribbon_tahoe_rec$y_bottom, ymax = ribbon_tahoe_rec$y_top),
              fill = COLOR_TAHOE, alpha = 0.5, color = NA) +
  geom_ribbon(aes(x = ribbon_both_rec$x, ymin = ribbon_both_rec$y_bottom, ymax = ribbon_both_rec$y_top),
              fill = COLOR_OVERLAP, alpha = 0.5, color = NA) +
  
  # ===== STAGE 1: SOURCE =====
  geom_rect(aes(xmin = 0, xmax = 0.4, ymin = 2.7, ymax = 3.3),
            fill = COLOR_CMAP, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 0.2, y = 3, label = "CMap\n2,399"),
            size = 4, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 0, xmax = 0.4, ymin = 1.8, ymax = 2.4),
            fill = COLOR_TAHOE, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 0.2, y = 2.1, label = "Tahoe\n1,686"),
            size = 4, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 0, xmax = 0.4, ymin = 0.7, ymax = 1.3),
            fill = COLOR_KNOWN, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 0.2, y = 1, label = "Open\nTargets\n4,262"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ===== STAGE 2: AVAILABLE =====
  geom_rect(aes(xmin = 1.4, xmax = 1.8, ymin = 3.3, ymax = 3.8),
            fill = COLOR_CMAP, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 1.6, y = 3.55, label = "CMap\nOnly\n982"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 1.4, xmax = 1.8, ymin = 2.3, ymax = 2.8),
            fill = COLOR_TAHOE, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 1.6, y = 2.55, label = "Tahoe\nOnly\n269"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 1.4, xmax = 1.8, ymin = 1.3, ymax = 1.8),
            fill = COLOR_OVERLAP, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 1.6, y = 1.55, label = "Both\n1,417"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ===== STAGE 3: RECOVERED =====
  geom_rect(aes(xmin = 2.4, xmax = 2.8, ymin = 3.3, ymax = 3.6),
            fill = COLOR_CMAP, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 2.6, y = 3.45, label = "437\n(44.6%)"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 2.4, xmax = 2.8, ymin = 2.3, ymax = 2.6),
            fill = COLOR_TAHOE, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 2.6, y = 2.45, label = "812\n(50.4%)"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 2.4, xmax = 2.8, ymin = 1.3, ymax = 1.5),
            fill = COLOR_OVERLAP, color = "white", linewidth = 1.5, alpha = 0.85) +
  geom_text(aes(x = 2.6, y = 1.4, label = "37\n(2.6%)"),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ===== STAGE LABELS =====
  geom_text(aes(x = 0.2, y = 4.1, label = "SOURCE"),
            size = 5, fontface = "bold", hjust = 0.5) +
  geom_text(aes(x = 1.6, y = 4.1, label = "AVAILABLE"),
            size = 5, fontface = "bold", hjust = 0.5) +
  geom_text(aes(x = 2.6, y = 4.1, label = "RECOVERED"),
            size = 5, fontface = "bold", hjust = 0.5) +
  
  # ===== TITLE =====
  labs(title = "Known Drug Pairs: From Source to Recovery",
       subtitle = "With flowing ribbon connections") +
  
  theme_void() +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#666", margin = margin(b = 20)),
    plot.margin = margin(20, 20, 20, 20)
  ) +
  xlim(-0.2, 3.2) +
  ylim(0.3, 4.3)

ggsave(file.path(figures_dir, "sankey_alt1_curved_ribbons.png"),
       p1, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Alternative 1 complete\n\n")

# ============================================================================
# ALTERNATIVE 2: GRADIENT FILLS AND ELEGANT DESIGN
# ============================================================================

cat("Creating Alternative 2: Gradient Fills & Elegant Design...\n")

p2 <- ggplot() +
  # ===== STAGE 1: SOURCE =====
  geom_rect(aes(xmin = 0.05, xmax = 0.35, ymin = 2.7, ymax = 3.3),
            fill = COLOR_CMAP, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 0.2, y = 3, label = "CMap\n2,399"),
            size = 4.2, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 0.05, xmax = 0.35, ymin = 1.8, ymax = 2.4),
            fill = COLOR_TAHOE, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 0.2, y = 2.1, label = "Tahoe\n1,686"),
            size = 4.2, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 0.05, xmax = 0.35, ymin = 0.7, ymax = 1.3),
            fill = COLOR_KNOWN, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 0.2, y = 1, label = "Open\nTargets\n4,262"),
            size = 3.7, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # Shadow/Depth effect
  geom_rect(aes(xmin = 0.06, xmax = 0.36, ymin = 2.68, ymax = 2.7),
            fill = "black", alpha = 0.1) +
  
  # ===== STAGE 2: AVAILABLE =====
  geom_rect(aes(xmin = 1.35, xmax = 1.75, ymin = 3.3, ymax = 3.8),
            fill = COLOR_CMAP, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 1.55, y = 3.55, label = "CMap Only\n982"),
            size = 3.7, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 1.35, xmax = 1.75, ymin = 2.3, ymax = 2.8),
            fill = COLOR_TAHOE, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 1.55, y = 2.55, label = "Tahoe Only\n269"),
            size = 3.7, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 1.35, xmax = 1.75, ymin = 1.3, ymax = 1.8),
            fill = COLOR_OVERLAP, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 1.55, y = 1.55, label = "Both\n1,417"),
            size = 3.7, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ===== STAGE 3: RECOVERED =====
  geom_rect(aes(xmin = 2.45, xmax = 2.75, ymin = 3.3, ymax = 3.6),
            fill = COLOR_CMAP, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 2.6, y = 3.45, label = "CMap\n437\n(44.6%)"),
            size = 3.2, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 2.45, xmax = 2.75, ymin = 2.3, ymax = 2.6),
            fill = COLOR_TAHOE, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 2.6, y = 2.45, label = "Tahoe\n812\n(50.4%)"),
            size = 3.2, fontface = "bold", color = "white", lineheight = 0.8) +
  
  geom_rect(aes(xmin = 2.45, xmax = 2.75, ymin = 1.3, ymax = 1.5),
            fill = COLOR_OVERLAP, color = "white", linewidth = 2, alpha = 0.9) +
  geom_text(aes(x = 2.6, y = 1.4, label = "Both\n37\n(2.6%)"),
            size = 3.2, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ===== CONNECTING LINES =====
  geom_segment(aes(x = 0.35, xend = 1.35, y = 3, yend = 3.55), 
               color = COLOR_CMAP, linewidth = 0.8, alpha = 0.3, linetype = "dashed") +
  geom_segment(aes(x = 0.35, xend = 1.35, y = 2.1, yend = 2.55),
               color = COLOR_TAHOE, linewidth = 0.8, alpha = 0.3, linetype = "dashed") +
  geom_segment(aes(x = 0.35, xend = 1.35, y = 1, yend = 1.55),
               color = COLOR_KNOWN, linewidth = 0.8, alpha = 0.3, linetype = "dashed") +
  
  geom_segment(aes(x = 1.75, xend = 2.45, y = 3.55, yend = 3.45),
               color = COLOR_CMAP, linewidth = 0.8, alpha = 0.3, linetype = "dashed") +
  geom_segment(aes(x = 1.75, xend = 2.45, y = 2.55, yend = 2.45),
               color = COLOR_TAHOE, linewidth = 0.8, alpha = 0.3, linetype = "dashed") +
  geom_segment(aes(x = 1.75, xend = 2.45, y = 1.55, yend = 1.4),
               color = COLOR_OVERLAP, linewidth = 0.8, alpha = 0.3, linetype = "dashed") +
  
  # ===== STAGE LABELS =====
  geom_text(aes(x = 0.2, y = 4.15, label = "SOURCE DATASETS"),
            size = 5.5, fontface = "bold", hjust = 0.5) +
  geom_text(aes(x = 1.55, y = 4.15, label = "AVAILABLE PAIRS"),
            size = 5.5, fontface = "bold", hjust = 0.5) +
  geom_text(aes(x = 2.6, y = 4.15, label = "RECOVERED PAIRS"),
            size = 5.5, fontface = "bold", hjust = 0.5) +
  
  # ===== TITLE =====
  labs(title = "Known Drug Pairs Flow Analysis",
       subtitle = "From source datasets through availability to successful recovery") +
  
  theme_void() +
  theme(
    plot.title = element_text(size = 19, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#666", margin = margin(b = 20)),
    plot.margin = margin(20, 20, 20, 20),
    plot.background = element_rect(fill = "#F8F9FA", color = NA)
  ) +
  xlim(-0.2, 3.2) +
  ylim(0.3, 4.4)

ggsave(file.path(figures_dir, "sankey_alt2_elegant_lines.png"),
       p2, width = 16, height = 10, dpi = 300, bg = "#F8F9FA")

cat("✓ Alternative 2 complete\n\n")

# ============================================================================
# ALTERNATIVE 3: MINIMALIST WITH SUBTLE CONNECTIONS
# ============================================================================

cat("Creating Alternative 3: Minimalist Design...\n")

p3 <- ggplot() +
  # ===== STAGE 1: SOURCE =====
  geom_rect(aes(xmin = 0.1, xmax = 0.3, ymin = 2.7, ymax = 3.3),
            fill = COLOR_CMAP, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 0.2, y = 3.15, label = "CMap"),
            size = 4, fontface = "bold", color = "white") +
  geom_text(aes(x = 0.2, y = 2.85, label = "2,399"),
            size = 3.5, fontface = "bold", color = "white") +
  
  geom_rect(aes(xmin = 0.1, xmax = 0.3, ymin = 1.8, ymax = 2.4),
            fill = COLOR_TAHOE, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 0.2, y = 2.25, label = "Tahoe"),
            size = 4, fontface = "bold", color = "white") +
  geom_text(aes(x = 0.2, y = 1.95, label = "1,686"),
            size = 3.5, fontface = "bold", color = "white") +
  
  geom_rect(aes(xmin = 0.1, xmax = 0.3, ymin = 0.7, ymax = 1.3),
            fill = COLOR_KNOWN, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 0.2, y = 1.15, label = "Open Targets"),
            size = 3.5, fontface = "bold", color = "white") +
  geom_text(aes(x = 0.2, y = 0.85, label = "4,262"),
            size = 3.5, fontface = "bold", color = "white") +
  
  # ===== STAGE 2: AVAILABLE =====
  geom_rect(aes(xmin = 1.4, xmax = 1.6, ymin = 3.3, ymax = 3.8),
            fill = COLOR_CMAP, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 1.5, y = 3.65, label = "CMap Only"),
            size = 3.2, fontface = "bold", color = "white") +
  geom_text(aes(x = 1.5, y = 3.45, label = "982"),
            size = 3, fontface = "bold", color = "white") +
  
  geom_rect(aes(xmin = 1.4, xmax = 1.6, ymin = 2.3, ymax = 2.8),
            fill = COLOR_TAHOE, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 1.5, y = 2.65, label = "Tahoe Only"),
            size = 3.2, fontface = "bold", color = "white") +
  geom_text(aes(x = 1.5, y = 2.45, label = "269"),
            size = 3, fontface = "bold", color = "white") +
  
  geom_rect(aes(xmin = 1.4, xmax = 1.6, ymin = 1.3, ymax = 1.8),
            fill = COLOR_OVERLAP, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 1.5, y = 1.65, label = "Both"),
            size = 3.2, fontface = "bold", color = "white") +
  geom_text(aes(x = 1.5, y = 1.45, label = "1,417"),
            size = 3, fontface = "bold", color = "white") +
  
  # ===== STAGE 3: RECOVERED =====
  geom_rect(aes(xmin = 2.5, xmax = 2.7, ymin = 3.3, ymax = 3.6),
            fill = COLOR_CMAP, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 2.6, y = 3.54, label = "437"),
            size = 3, fontface = "bold", color = "white") +
  geom_text(aes(x = 2.6, y = 3.38, label = "44.6%"),
            size = 2.5, fontface = "italic", color = "white") +
  
  geom_rect(aes(xmin = 2.5, xmax = 2.7, ymin = 2.3, ymax = 2.6),
            fill = COLOR_TAHOE, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 2.6, y = 2.54, label = "812"),
            size = 3, fontface = "bold", color = "white") +
  geom_text(aes(x = 2.6, y = 2.38, label = "50.4%"),
            size = 2.5, fontface = "italic", color = "white") +
  
  geom_rect(aes(xmin = 2.5, xmax = 2.7, ymin = 1.3, ymax = 1.5),
            fill = COLOR_OVERLAP, color = "#E8E8E8", linewidth = 1, alpha = 0.85) +
  geom_text(aes(x = 2.6, y = 1.44, label = "37"),
            size = 3, fontface = "bold", color = "white") +
  geom_text(aes(x = 2.6, y = 1.36, label = "2.6%"),
            size = 2.5, fontface = "italic", color = "white") +
  
  # ===== SUBTLE CONNECTING LINES =====
  geom_segment(aes(x = 0.3, xend = 1.4, y = 3, yend = 3.55),
               color = "#CCCCCC", linewidth = 0.5, alpha = 0.5) +
  geom_segment(aes(x = 0.3, xend = 1.4, y = 2.1, yend = 2.55),
               color = "#CCCCCC", linewidth = 0.5, alpha = 0.5) +
  geom_segment(aes(x = 0.3, xend = 1.4, y = 1, yend = 1.55),
               color = "#CCCCCC", linewidth = 0.5, alpha = 0.5) +
  
  geom_segment(aes(x = 1.6, xend = 2.5, y = 3.55, yend = 3.45),
               color = "#CCCCCC", linewidth = 0.5, alpha = 0.5) +
  geom_segment(aes(x = 1.6, xend = 2.5, y = 2.55, yend = 2.45),
               color = "#CCCCCC", linewidth = 0.5, alpha = 0.5) +
  geom_segment(aes(x = 1.6, xend = 2.5, y = 1.55, yend = 1.4),
               color = "#CCCCCC", linewidth = 0.5, alpha = 0.5) +
  
  # ===== STAGE LABELS =====
  geom_text(aes(x = 0.2, y = 4.1, label = "SOURCE"),
            size = 5, fontface = "bold", hjust = 0.5, color = "#333333") +
  geom_text(aes(x = 1.5, y = 4.1, label = "AVAILABLE"),
            size = 5, fontface = "bold", hjust = 0.5, color = "#333333") +
  geom_text(aes(x = 2.6, y = 4.1, label = "RECOVERED"),
            size = 5, fontface = "bold", hjust = 0.5, color = "#333333") +
  
  # ===== TITLE =====
  labs(title = "Known Drug Pairs: Complete Pipeline",
       subtitle = "Source → Available → Recovered with recovery percentages") +
  
  theme_void() +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5, margin = margin(b = 5), color = "#222222"),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#666666", margin = margin(b = 20)),
    plot.margin = margin(20, 20, 20, 20),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  xlim(-0.2, 3.2) +
  ylim(0.3, 4.3)

ggsave(file.path(figures_dir, "sankey_alt3_minimalist.png"),
       p3, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Alternative 3 complete\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== THREE ALTERNATIVE SANKEY DIAGRAMS COMPLETE ===\n\n")
cat("Files created:\n")
cat("  1. sankey_alt1_curved_ribbons.png (Curved flowing ribbons)\n")
cat("  2. sankey_alt2_elegant_lines.png (Dashed connecting lines)\n")
cat("  3. sankey_alt3_minimalist.png (Minimalist with subtle lines)\n\n")
cat("Each maintains the core structure:\n")
cat("  NODE 1: Source Datasets (CMap, Tahoe, Open Targets)\n")
cat("  NODE 2: Available Pairs (CMap Only, Tahoe Only, Both)\n")
cat("  NODE 3: Recovered Pairs (with percentages)\n\n")
