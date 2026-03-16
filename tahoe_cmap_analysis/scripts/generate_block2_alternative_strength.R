#!/usr/bin/env Rscript

# Block 2 - Alternative Signature Strength Visualizations
# Option 1: Violin plot with individual disease points
# Option 2: 2D scatter plot (Up vs Down strength per disease)

library(tidyverse)
library(ggplot2)

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
# OPTION 1: VIOLIN PLOT WITH INDIVIDUAL DISEASE POINTS
# ============================================================================
# This shows the distribution more clearly and allows seeing each disease

up_down_data_long <- data.frame(
  strength = c(disease_summary$up_strength, disease_summary$down_strength),
  type = c(rep("Up-regulated", nrow(disease_summary)), 
           rep("Down-regulated", nrow(disease_summary))),
  disease_idx = rep(1:nrow(disease_summary), 2)
)

p_option1 <- ggplot(up_down_data_long, aes(x = type, y = strength, fill = type)) +
  geom_violin(alpha = 0.6, color = NA) +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8, color = "black", linewidth = 0.6) +
  geom_jitter(width = 0.12, alpha = 0.4, size = 2.5, color = "#2C3E50") +
  scale_fill_manual(
    values = c("Up-regulated" = COLOR_UP, "Down-regulated" = COLOR_DOWN),
    guide = "none"
  ) +
  labs(
    title = "Disease Signature Strength: Up vs Down Regulated Genes",
    subtitle = "Violin plot with individual disease points (n=233)",
    x = "Gene Regulation Direction",
    y = "Mean Absolute Log2 Fold Change"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 12, color = "#555", hjust = 0.5, margin = margin(b = 15)),
    axis.text = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.title.x = element_text(margin = margin(t = 12)),
    axis.title.y = element_text(margin = margin(r = 12)),
    panel.grid.major.y = element_line(color = "gray92"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

ggsave(file.path(figures_dir, "block2_chart6b_option1_violin_strength.png"), 
       p_option1, width = 10, height = 7.5, dpi = 300, bg = "white")

cat("✓ Option 1: Violin plot with jittered disease points created\n")

# ============================================================================
# OPTION 2: 2D SCATTER PLOT (UP vs DOWN STRENGTH PER DISEASE)
# ============================================================================
# This shows the relationship between up and down strength per disease
# and reveals which diseases have stronger up vs down regulation

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

p_option2 <- ggplot(scatter_data, aes(x = up_strength, y = down_strength, 
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
  labs(
    title = "Up vs Down Regulated Signature Strength Per Disease",
    subtitle = "Each point is one disease; dashed line indicates perfect balance",
    x = "Up-regulated Gene Strength (Mean Log2FC)",
    y = "Down-regulated Gene Strength (Mean Log2FC)",
    color = "Regulation Pattern"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 12, color = "#555", hjust = 0.5, margin = margin(b = 15)),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 13, face = "bold"),
    axis.title.x = element_text(margin = margin(t = 12)),
    axis.title.y = element_text(margin = margin(r = 12)),
    panel.grid.major = element_line(color = "gray92"),
    legend.position = "right",
    legend.text = element_text(size = 11),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

ggsave(file.path(figures_dir, "block2_chart6b_option2_scatter_updwn.png"), 
       p_option2, width = 11, height = 8, dpi = 300, bg = "white")

cat("✓ Option 2: 2D scatter plot (Up vs Down strength) created\n\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("=== SIGNATURE STRENGTH SUMMARY ===\n")
cat(sprintf("Up-regulated: Median=%.3f, Mean=%.3f, SD=%.3f\n", 
            median(disease_summary$up_strength[disease_summary$up_strength > 0], na.rm = TRUE),
            mean(disease_summary$up_strength[disease_summary$up_strength > 0], na.rm = TRUE),
            sd(disease_summary$up_strength[disease_summary$up_strength > 0], na.rm = TRUE)))

cat(sprintf("Down-regulated: Median=%.3f, Mean=%.3f, SD=%.3f\n\n", 
            median(disease_summary$down_strength[disease_summary$down_strength > 0], na.rm = TRUE),
            mean(disease_summary$down_strength[disease_summary$down_strength > 0], na.rm = TRUE),
            sd(disease_summary$down_strength[disease_summary$down_strength > 0], na.rm = TRUE)))

cat("=== REGULATION PATTERN BREAKDOWN ===\n")
cat(sprintf("Strong Up regulation (>1.3x more up genes): %d diseases (%.1f%%)\n",
            sum(scatter_data$balance_pct > 56.5), 
            100 * sum(scatter_data$balance_pct > 56.5) / nrow(scatter_data)))
cat(sprintf("Strong Down regulation (>1.3x more down genes): %d diseases (%.1f%%)\n",
            sum(scatter_data$balance_pct < 43.5),
            100 * sum(scatter_data$balance_pct < 43.5) / nrow(scatter_data)))
cat(sprintf("Balanced regulation: %d diseases (%.1f%%)\n\n",
            sum(scatter_data$color_group == "Balanced"),
            100 * sum(scatter_data$color_group == "Balanced") / nrow(scatter_data)))
