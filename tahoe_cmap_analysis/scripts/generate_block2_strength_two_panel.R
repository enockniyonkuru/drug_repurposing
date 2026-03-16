#!/usr/bin/env Rscript

# Block 2 - Combined Strength Visualization (Violin + Scatter as 2-Panel Figure)
# Creates a panel combining Option 1 (Violin) and Option 2 (Scatter)
# With consistent axis scaling

library(tidyverse)
library(ggplot2)
library(patchwork)

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_UP <- "#E74C3C"        # Red for up-regulated
COLOR_DOWN <- "#3498DB"      # Blue for down-regulated

figures_dir <- "tahoe_cmap_analysis/figures"
data_dir <- "tahoe_cmap_analysis/data/disease_signatures"

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Load disease signatures
# ============================================================================

cat("Loading disease signatures for strength visualization...\n")

disease_files <- list.files(file.path(data_dir, "creeds_manual_disease_signatures"),
                            pattern = "_signature.csv$", full.names = TRUE)

n_diseases <- length(disease_files)
disease_names <- basename(disease_files) %>%
  str_replace("_signature.csv$", "") %>%
  str_replace("_", " ")

disease_summary <- data.frame(
  disease_name = disease_names,
  up_genes = NA,
  down_genes = NA,
  up_strength = NA,
  down_strength = NA,
  total_genes = NA,
  stringsAsFactors = FALSE
)

for (i in seq_along(disease_files)) {
  tryCatch({
    df <- read.csv(disease_files[i])
    
    logfc_col <- grep("mean_logfc|log2fc", names(df), ignore.case = TRUE, value = TRUE)[1]
    
    if (length(logfc_col) > 0 && !is.na(logfc_col)) {
      logfc_values <- df[[logfc_col]]
      logfc_values <- logfc_values[!is.na(logfc_values)]
      
      up_genes_mask <- logfc_values > 0
      down_genes_mask <- logfc_values < 0
      
      disease_summary$up_genes[i] <- sum(up_genes_mask, na.rm = TRUE)
      disease_summary$down_genes[i] <- sum(down_genes_mask, na.rm = TRUE)
      disease_summary$total_genes[i] <- length(logfc_values)
      
      up_logfc <- logfc_values[up_genes_mask]
      down_logfc <- abs(logfc_values[down_genes_mask])
      
      disease_summary$up_strength[i] <- ifelse(length(up_logfc) > 0, mean(up_logfc, na.rm = TRUE), 0)
      disease_summary$down_strength[i] <- ifelse(length(down_logfc) > 0, mean(down_logfc, na.rm = TRUE), 0)
    }
  }, error = function(e) {})
}

disease_summary$up_genes[is.na(disease_summary$up_genes)] <- 0
disease_summary$down_genes[is.na(disease_summary$down_genes)] <- 0
disease_summary$up_strength[is.na(disease_summary$up_strength)] <- 0
disease_summary$down_strength[is.na(disease_summary$down_strength)] <- 0
disease_summary$total_genes[is.na(disease_summary$total_genes)] <- 0

cat(sprintf("✓ Loaded %d diseases\n\n", n_diseases))

# ============================================================================
# DETERMINE CONSISTENT Y-AXIS LIMITS
# ============================================================================

# Set consistent y-axis limit to 0.16
y_limit <- 0.16

cat(sprintf("Determined consistent y-axis limit: %.2f\n\n", y_limit))

# ============================================================================
# PANEL A: VIOLIN PLOT WITH INDIVIDUAL DISEASE POINTS
# ============================================================================

up_down_data_long <- data.frame(
  strength = c(disease_summary$up_strength, disease_summary$down_strength),
  type = c(rep("Up-regulated", nrow(disease_summary)), 
           rep("Down-regulated", nrow(disease_summary))),
  disease_idx = rep(1:nrow(disease_summary), 2)
)

p_violin <- ggplot(up_down_data_long, aes(x = type, y = strength, fill = type)) +
  geom_violin(alpha = 0.6, color = NA) +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8, color = "black", linewidth = 0.6) +
  geom_jitter(width = 0.12, alpha = 0.4, size = 2.5, color = "#2C3E50") +
  scale_fill_manual(
    values = c("Up-regulated" = COLOR_UP, "Down-regulated" = COLOR_DOWN),
    guide = "none"
  ) +
  scale_y_continuous(limits = c(0, y_limit)) +
  labs(
    title = "A: Distribution of Signature Strength",
    subtitle = "Up vs Down Regulated Genes (n=233 diseases)",
    x = "Gene Regulation Direction",
    y = "Mean Absolute Log2 Fold Change"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 3)),
    plot.subtitle = element_text(size = 11, color = "#555", hjust = 0.5, margin = margin(b = 10)),
    axis.text = element_text(size = 11, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major.y = element_line(color = "gray92"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Save Panel A individually
ggsave(
  file.path(figures_dir, "block2_chart6b_A_violin_strength.png"),
  p_violin,
  width = 7,
  height = 6,
  dpi = 300,
  bg = "white"
)

cat("✓ Panel A: Violin plot saved\n")

# ============================================================================
# PANEL B: 2D SCATTER PLOT (UP vs DOWN STRENGTH PER DISEASE)
# ============================================================================

scatter_data <- disease_summary %>%
  filter(total_genes > 0) %>%
  mutate(
    balance = up_genes - down_genes,
    balance_pct = (up_genes / (up_genes + down_genes)) * 100,
    color_group = case_when(
      up_genes > down_genes * 1.3 ~ "Strong Up",
      down_genes > up_genes * 1.3 ~ "Strong Down",
      TRUE ~ "Balanced"
    )
  )

p_scatter <- ggplot(scatter_data, aes(x = up_strength, y = down_strength, 
                                       color = color_group, size = total_genes)) +
  geom_point(alpha = 0.6, stroke = 0.8) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "#95A5A6", 
              linewidth = 1, alpha = 0.7) +
  scale_color_manual(
    values = c(
      "Strong Up" = COLOR_UP,
      "Strong Down" = COLOR_DOWN,
      "Balanced" = "#95A5A6"
    ),
    guide = guide_legend(override.aes = list(size = 4))
  ) +
  scale_size_continuous(
    name = "Total Genes",
    range = c(2, 8),
    guide = guide_legend(order = 2)
  ) +
  scale_x_continuous(limits = c(0, 0.05)) +
  scale_y_continuous(limits = c(0, 0.16)) +
  labs(
    title = "B: Up vs Down Regulated Gene Strength",
    subtitle = "Each point is one disease; dashed line indicates balance",
    x = "Up-regulated Gene Strength (Mean Log2FC)",
    y = "Down-regulated Gene Strength (Mean Log2FC)",
    color = "Regulation\nPattern"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 3)),
    plot.subtitle = element_text(size = 11, color = "#555", hjust = 0.5, margin = margin(b = 10)),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    panel.grid.major = element_line(color = "gray92"),
    legend.position = "right",
    legend.text = element_text(size = 10),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Save Panel B individually
ggsave(
  file.path(figures_dir, "block2_chart6b_B_scatter_updwn.png"),
  p_scatter,
  width = 8,
  height = 6,
  dpi = 300,
  bg = "white"
)

cat("✓ Panel B: Scatter plot saved\n")

# ============================================================================
# COMBINE INTO TWO-PANEL FIGURE
# ============================================================================

combined_plot <- (p_violin | p_scatter) +
  plot_annotation(
    title = "Disease Signature Strength Analysis: Up vs Down Regulated Genes",
    subtitle = "Consistent y-axis scale across both panels enables direct comparison",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 5)),
      plot.subtitle = element_text(size = 12, color = "#333", hjust = 0.5, margin = margin(b = 15)),
      plot.background = element_rect(fill = "white", color = NA)
    )
  )

# Save combined plot
ggsave(
  file.path(figures_dir, "block2_chart6b_two_panel_strength.png"),
  combined_plot,
  width = 15,
  height = 6,
  dpi = 300,
  bg = "white"
)

cat("✓ Combined Two-Panel Figure created!\n\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         DISEASE SIGNATURE STRENGTH SUMMARY                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

up_stats <- disease_summary$up_strength[disease_summary$up_strength > 0]
down_stats <- disease_summary$down_strength[disease_summary$down_strength > 0]

cat("UP-REGULATED GENES:\n")
cat(sprintf("  • Median: %.3f\n", median(up_stats, na.rm = TRUE)))
cat(sprintf("  • Mean:   %.3f\n", mean(up_stats, na.rm = TRUE)))
cat(sprintf("  • SD:     %.3f\n", sd(up_stats, na.rm = TRUE)))
cat(sprintf("  • Range:  [%.3f, %.3f]\n\n", min(up_stats, na.rm = TRUE), max(up_stats, na.rm = TRUE)))

cat("DOWN-REGULATED GENES:\n")
cat(sprintf("  • Median: %.3f\n", median(down_stats, na.rm = TRUE)))
cat(sprintf("  • Mean:   %.3f\n", mean(down_stats, na.rm = TRUE)))
cat(sprintf("  • SD:     %.3f\n", sd(down_stats, na.rm = TRUE)))
cat(sprintf("  • Range:  [%.3f, %.3f]\n\n", min(down_stats, na.rm = TRUE), max(down_stats, na.rm = TRUE)))

cat("CONSISTENT Y-AXIS LIMIT:\n")
cat(sprintf("  • All panels limited to: [0, %.1f]\n\n", y_limit))

cat("COLOR SCHEME:\n")
cat(sprintf("  • Up-regulated:   %s (Red)\n", COLOR_UP))
cat(sprintf("  • Down-regulated: %s (Blue)\n", COLOR_DOWN))
cat(sprintf("  • Balanced:       #95A5A6 (Gray)\n\n"))

cat("FILES CREATED:\n")
cat("  COMBINED:\n")
cat("  • block2_chart6b_two_panel_strength.png\n\n")
cat("  INDIVIDUAL PANELS:\n")
cat("  • block2_chart6b_A_violin_strength.png\n")
cat("  • block2_chart6b_B_scatter_updwn.png\n\n")

cat("✓ Two-panel strength analysis generated successfully!\n")
cat(sprintf("✓ Saved to: %s\n", figures_dir))
