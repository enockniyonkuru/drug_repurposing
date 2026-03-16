#!/usr/bin/env Rscript

# CONNECTED SANKEY DIAGRAM WITH THREE NODES
# Node 1: Total Available Pairs
# Node 2: Total Availability Exclusivity
# Node 3: Recovered Pairs
# With flowing connections between nodes

library(tidyverse)
library(arrow)
library(ggplot2)
library(scales)

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap
COLOR_KNOWN <- "#27AE60"     # Green for Open Targets
COLOR_NOT_REC <- "#95A5A6"   # Gray for not recovered

figures_dir <- "tahoe_cmap_analysis/figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# DATA - USER SPECIFIED VALUES
# ============================================================================

cat("Creating Connected Three-Node Sankey Diagram...\n\n")

# NODE 1: Total Available Pairs
node1_cmap <- 2399
node1_tahoe <- 1866
node1_opentarget <- 118234

# NODE 2: Availability Exclusivity
node2_cmap_only <- 982
node2_tahoe_only <- 268
node2_both <- 1417

# NODE 3: Recovered Pairs
node3_cmap <- 437
node3_cmap_pct <- 19.8
node3_tahoe <- 812
node3_tahoe_pct <- 50.4
node3_both <- 37

# Calculate Node 1 total
node1_total <- node1_cmap + node1_tahoe + node1_opentarget

# Calculate Node 2 total
node2_total <- node2_cmap_only + node2_tahoe_only + node2_both

# Calculate Node 3 total (recovered)
node3_total <- node3_cmap + node3_tahoe + node3_both

cat("NODE 1 - Total Available Pairs:\n")
cat(sprintf("  CMap: %d\n", node1_cmap))
cat(sprintf("  Tahoe: %d\n", node1_tahoe))
cat(sprintf("  Open Targets: %d\n", node1_opentarget))
cat(sprintf("  TOTAL: %d\n\n", node1_total))

cat("NODE 2 - Availability Exclusivity:\n")
cat(sprintf("  CMap Only: %d\n", node2_cmap_only))
cat(sprintf("  Tahoe Only: %d\n", node2_tahoe_only))
cat(sprintf("  Both: %d\n", node2_both))
cat(sprintf("  TOTAL: %d\n\n", node2_total))

cat("NODE 3 - Recovered Pairs:\n")
cat(sprintf("  CMap Only: %d (%.1f%%)\n", node3_cmap, node3_cmap_pct))
cat(sprintf("  Tahoe Only: %d (%.1f%%)\n", node3_tahoe, node3_tahoe_pct))
cat(sprintf("  Both: %d\n", node3_both))
cat(sprintf("  TOTAL: %d\n\n", node3_total))

# ============================================================================
# CREATE BASE PLOT WITH THREE NODE BLOCKS
# ============================================================================

# Define node positions
node1_x <- 0.5
node1_width <- 0.3

node2_x <- 2.0
node2_width <- 0.3

node3_x <- 3.5
node3_width <- 0.3

# Y positions for node 1 (proportional heights)
# Total available pairs
node1_cmap_ymin <- 5.0
node1_cmap_ymax <- 5.0 + (node1_cmap / node1_total) * 6
node1_tahoe_ymin <- node1_cmap_ymax + 0.1
node1_tahoe_ymax <- node1_tahoe_ymin + (node1_tahoe / node1_total) * 6
node1_opentarget_ymin <- node1_tahoe_ymax + 0.1
node1_opentarget_ymax <- node1_opentarget_ymin + (node1_opentarget / node1_total) * 6

# Y positions for node 2 (proportional heights)
# Availability exclusivity
node2_cmap_only_ymin <- 5.0
node2_cmap_only_ymax <- 5.0 + (node2_cmap_only / node2_total) * 6
node2_tahoe_only_ymin <- node2_cmap_only_ymax + 0.1
node2_tahoe_only_ymax <- node2_tahoe_only_ymin + (node2_tahoe_only / node2_total) * 6
node2_both_ymin <- node2_tahoe_only_ymax + 0.1
node2_both_ymax <- node2_both_ymin + (node2_both / node2_total) * 6

# Y positions for node 3 (proportional heights)
# Recovered pairs
node3_cmap_ymin <- 5.0
node3_cmap_ymax <- 5.0 + (node3_cmap / node3_total) * 6
node3_tahoe_ymin <- node3_cmap_ymax + 0.1
node3_tahoe_ymax <- node3_tahoe_ymin + (node3_tahoe / node3_total) * 6
node3_both_ymin <- node3_tahoe_ymax + 0.1
node3_both_ymax <- node3_both_ymin + (node3_both / node3_total) * 6

# ============================================================================
# FUNCTION: CREATE FLOWING BEZIER CURVES
# ============================================================================

create_bezier_flow <- function(x1, y1, x2, y2, resolution = 100, alpha = 0.5) {
  t <- seq(0, 1, length.out = resolution)
  
  # Control points for smooth cubic bezier
  cx1 <- x1 + (x2 - x1) * 0.3
  cx2 <- x1 + (x2 - x1) * 0.7
  
  x <- (1-t)^3 * x1 + 3*(1-t)^2*t * cx1 + 3*(1-t)*t^2 * cx2 + t^3 * x2
  y <- (1-t)^3 * y1 + 3*(1-t)^2*t * ((y1 + y2)/2) + 3*(1-t)*t^2 * ((y1 + y2)/2) + t^3 * y2
  
  data.frame(x = x, y = y, t = t, alpha = alpha)
}

# ============================================================================
# CREATE GGPLOT
# ============================================================================

p <- ggplot() +
  
  # ========================================================================
  # NODE 1: TOTAL AVAILABLE PAIRS
  # ========================================================================
  
  # CMap block
  geom_rect(aes(xmin = node1_x - node1_width/2, xmax = node1_x + node1_width/2,
                ymin = node1_cmap_ymin, ymax = node1_cmap_ymax),
            fill = COLOR_CMAP, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node1_x, y = (node1_cmap_ymin + node1_cmap_ymax) / 2,
                label = sprintf("CMap\n%d", node1_cmap)),
            size = 4, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # Tahoe block
  geom_rect(aes(xmin = node1_x - node1_width/2, xmax = node1_x + node1_width/2,
                ymin = node1_tahoe_ymin, ymax = node1_tahoe_ymax),
            fill = COLOR_TAHOE, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node1_x, y = (node1_tahoe_ymin + node1_tahoe_ymax) / 2,
                label = sprintf("Tahoe\n%d", node1_tahoe)),
            size = 4, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # Open Targets block
  geom_rect(aes(xmin = node1_x - node1_width/2, xmax = node1_x + node1_width/2,
                ymin = node1_opentarget_ymin, ymax = node1_opentarget_ymax),
            fill = COLOR_KNOWN, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node1_x, y = (node1_opentarget_ymin + node1_opentarget_ymax) / 2,
                label = sprintf("Open Targets\n%d", node1_opentarget)),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ========================================================================
  # NODE 2: AVAILABILITY EXCLUSIVITY
  # ========================================================================
  
  # CMap Only block
  geom_rect(aes(xmin = node2_x - node2_width/2, xmax = node2_x + node2_width/2,
                ymin = node2_cmap_only_ymin, ymax = node2_cmap_only_ymax),
            fill = COLOR_CMAP, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node2_x, y = (node2_cmap_only_ymin + node2_cmap_only_ymax) / 2,
                label = sprintf("CMap Only\n%d", node2_cmap_only)),
            size = 3.8, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # Tahoe Only block
  geom_rect(aes(xmin = node2_x - node2_width/2, xmax = node2_x + node2_width/2,
                ymin = node2_tahoe_only_ymin, ymax = node2_tahoe_only_ymax),
            fill = COLOR_TAHOE, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node2_x, y = (node2_tahoe_only_ymin + node2_tahoe_only_ymax) / 2,
                label = sprintf("Tahoe Only\n%d", node2_tahoe_only)),
            size = 3.8, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # Both block
  geom_rect(aes(xmin = node2_x - node2_width/2, xmax = node2_x + node2_width/2,
                ymin = node2_both_ymin, ymax = node2_both_ymax),
            fill = COLOR_OVERLAP, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node2_x, y = (node2_both_ymin + node2_both_ymax) / 2,
                label = sprintf("Both\n%d", node2_both)),
            size = 3.8, fontface = "bold", color = "white", lineheight = 0.8) +
  
  # ========================================================================
  # NODE 3: RECOVERED PAIRS
  # ========================================================================
  
  # CMap Recovered block
  geom_rect(aes(xmin = node3_x - node3_width/2, xmax = node3_x + node3_width/2,
                ymin = node3_cmap_ymin, ymax = node3_cmap_ymax),
            fill = COLOR_CMAP, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node3_x, y = (node3_cmap_ymin + node3_cmap_ymax) / 2,
                label = sprintf("CMap Only\n%d\n(%.1f%%)", node3_cmap, node3_cmap_pct)),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.75) +
  
  # Tahoe Recovered block
  geom_rect(aes(xmin = node3_x - node3_width/2, xmax = node3_x + node3_width/2,
                ymin = node3_tahoe_ymin, ymax = node3_tahoe_ymax),
            fill = COLOR_TAHOE, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node3_x, y = (node3_tahoe_ymin + node3_tahoe_ymax) / 2,
                label = sprintf("Tahoe\n%d\n(%.1f%%)", node3_tahoe, node3_tahoe_pct)),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.75) +
  
  # Both Recovered block
  geom_rect(aes(xmin = node3_x - node3_width/2, xmax = node3_x + node3_width/2,
                ymin = node3_both_ymin, ymax = node3_both_ymax),
            fill = COLOR_OVERLAP, color = "white", linewidth = 1.2, alpha = 0.9) +
  geom_text(aes(x = node3_x, y = (node3_both_ymin + node3_both_ymax) / 2,
                label = sprintf("Both\n%d", node3_both)),
            size = 3.5, fontface = "bold", color = "white", lineheight = 0.75) +
  
  # ========================================================================
  # FLOWING CONNECTIONS: NODE 1 → NODE 2
  # ========================================================================
  
  # CMap flows (simplified proportional connections)
  geom_segment(aes(x = node1_x + node1_width/2, xend = node2_x - node2_width/2,
                   y = (node1_cmap_ymin + node1_cmap_ymax) / 2,
                   yend = (node2_cmap_only_ymin + node2_cmap_only_ymax) / 2),
               color = COLOR_CMAP, linewidth = 1.2, alpha = 0.6, arrow = arrow(length = unit(0.15, "inches"), type = "closed")) +
  
  # Tahoe flows
  geom_segment(aes(x = node1_x + node1_width/2, xend = node2_x - node2_width/2,
                   y = (node1_tahoe_ymin + node1_tahoe_ymax) / 2,
                   yend = (node2_tahoe_only_ymin + node2_tahoe_only_ymax) / 2),
               color = COLOR_TAHOE, linewidth = 1.2, alpha = 0.6, arrow = arrow(length = unit(0.15, "inches"), type = "closed")) +
  
  # Open Targets to Both (partial overlap)
  geom_segment(aes(x = node1_x + node1_width/2, xend = node2_x - node2_width/2,
                   y = (node1_opentarget_ymin + node1_opentarget_ymax) / 2,
                   yend = (node2_both_ymin + node2_both_ymax) / 2),
               color = COLOR_KNOWN, linewidth = 1.2, alpha = 0.6, arrow = arrow(length = unit(0.15, "inches"), type = "closed")) +
  
  # ========================================================================
  # FLOWING CONNECTIONS: NODE 2 → NODE 3
  # ========================================================================
  
  # CMap Only to Recovered
  geom_segment(aes(x = node2_x + node2_width/2, xend = node3_x - node3_width/2,
                   y = (node2_cmap_only_ymin + node2_cmap_only_ymax) / 2,
                   yend = (node3_cmap_ymin + node3_cmap_ymax) / 2),
               color = COLOR_CMAP, linewidth = 1.2, alpha = 0.6, arrow = arrow(length = unit(0.15, "inches"), type = "closed")) +
  
  # Tahoe Only to Recovered
  geom_segment(aes(x = node2_x + node2_width/2, xend = node3_x - node3_width/2,
                   y = (node2_tahoe_only_ymin + node2_tahoe_only_ymax) / 2,
                   yend = (node3_tahoe_ymin + node3_tahoe_ymax) / 2),
               color = COLOR_TAHOE, linewidth = 1.2, alpha = 0.6, arrow = arrow(length = unit(0.15, "inches"), type = "closed")) +
  
  # Both to Both Recovered
  geom_segment(aes(x = node2_x + node2_width/2, xend = node3_x - node3_width/2,
                   y = (node2_both_ymin + node2_both_ymax) / 2,
                   yend = (node3_both_ymin + node3_both_ymax) / 2),
               color = COLOR_OVERLAP, linewidth = 1.2, alpha = 0.6, arrow = arrow(length = unit(0.15, "inches"), type = "closed")) +
  
  # ========================================================================
  # NODE LABELS
  # ========================================================================
  
  geom_text(aes(x = node1_x, y = 4.3, label = "Node 1\nTotal Available Pairs"),
            size = 5.5, fontface = "bold", hjust = 0.5, color = "#222222") +
  
  geom_text(aes(x = node2_x, y = 4.3, label = "Node 2\nAvailability Exclusivity"),
            size = 5.5, fontface = "bold", hjust = 0.5, color = "#222222") +
  
  geom_text(aes(x = node3_x, y = 4.3, label = "Node 3\nRecovered Pairs"),
            size = 5.5, fontface = "bold", hjust = 0.5, color = "#222222") +
  
  # ========================================================================
  # TITLE AND THEME
  # ========================================================================
  
  labs(title = "Connected Three-Node Sankey: Drug Pair Analysis",
       subtitle = "Source → Availability Exclusivity → Recovery Status") +
  
  theme_void() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 5), color = "#111111"),
    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "#666666", margin = margin(b = 15)),
    plot.margin = margin(20, 30, 20, 30),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  xlim(-0.3, 4.0) +
  ylim(3.8, 12)

# ============================================================================
# SAVE PLOT
# ============================================================================

ggsave(file.path(figures_dir, "sankey_known_drugs_flow.png"),
       p, width = 18, height = 12, dpi = 300, bg = "white")

cat("\n✓ Connected three-node Sankey diagram complete!\n")
cat(sprintf("✓ File saved: %s/sankey_known_drugs_flow.png\n\n", figures_dir))

cat("SUMMARY:\n")
cat("========================================\n")
cat(sprintf("Node 1 → Node 2 → Node 3 connections\n"))
cat(sprintf("CMap: %d → %d → %d (%.1f%%)\n", node1_cmap, node2_cmap_only, node3_cmap, node3_cmap_pct))
cat(sprintf("Tahoe: %d → %d → %d (%.1f%%)\n", node1_tahoe, node2_tahoe_only, node3_tahoe, node3_tahoe_pct))
cat(sprintf("Open Targets: %d → %d (Both) → %d\n", node1_opentarget, node2_both, node3_both))
cat("========================================\n")
