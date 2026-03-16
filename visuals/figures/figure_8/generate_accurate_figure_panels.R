#!/usr/bin/env Rscript
# ============================================================================
# ACCURATE FIGURE PANELS FOR DISEASE SIGNATURE ANALYSIS
# Generates all 4 panels using actual CREEDS data
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(cowplot)

# Set working directory
setwd("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis")

# ============================================================================
# COLOR PALETTE
# ============================================================================
COLOR_UP <- "#E74C3C"       # Red for upregulated
COLOR_DOWN <- "#3498DB"     # Blue for downregulated
COLOR_BEFORE <- "#5DADE2"   # Light blue for before filtering
COLOR_AFTER <- "#2E86AB"    # Darker blue for after filtering
COLOR_BALANCED <- "#BDC3C7" # Gray for balanced
COLOR_STRONG_UP <- "#E74C3C"
COLOR_STRONG_DOWN <- "#3498DB"

# ============================================================================
# LOAD AND PROCESS DATA
# ============================================================================

cat("Loading disease signature data...\n")

# Path to standardized signatures
sig_dir <- "data/disease_signatures/creeds_manual_disease_signatures_standardised"
sig_files <- list.files(sig_dir, pattern = "_signature\\.csv$", full.names = TRUE)

cat(sprintf("Found %d signature files\n", length(sig_files)))

# Load gene counts across stages
gene_counts <- read.csv("data/disease_signatures/creeds_disease_gene_counts_across_stages.csv",
                        stringsAsFactors = FALSE)

# Process each signature to extract detailed statistics
disease_stats <- lapply(sig_files, function(f) {
  tryCatch({
    sig <- read.csv(f, stringsAsFactors = FALSE)
    disease_name <- gsub("_signature\\.csv$", "", basename(f))
    
    # Count up and down regulated genes
    up_genes <- sum(sig$signature_type == "UP", na.rm = TRUE)
    down_genes <- sum(sig$signature_type == "DOWN", na.rm = TRUE)
    total_genes <- nrow(sig)
    
    # Calculate mean absolute log2FC for up and down separately
    up_logfc <- sig$mean_logfc[sig$signature_type == "UP"]
    down_logfc <- sig$mean_logfc[sig$signature_type == "DOWN"]
    
    mean_up_logfc <- if(length(up_logfc) > 0) mean(abs(up_logfc), na.rm = TRUE) else NA
    mean_down_logfc <- if(length(down_logfc) > 0) mean(abs(down_logfc), na.rm = TRUE) else NA
    
    data.frame(
      disease = disease_name,
      up_genes = up_genes,
      down_genes = down_genes,
      total_genes = total_genes,
      mean_up_logfc = mean_up_logfc,
      mean_down_logfc = mean_down_logfc,
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    NULL
  })
})

# Combine into data frame
disease_df <- do.call(rbind, disease_stats[!sapply(disease_stats, is.null)])

cat(sprintf("Successfully processed %d diseases\n", nrow(disease_df)))

# Merge with gene counts data
disease_df <- disease_df %>%
  left_join(gene_counts, by = "disease")

# Calculate regulation pattern
disease_df <- disease_df %>%
  mutate(
    up_ratio = up_genes / (up_genes + down_genes),
    regulation_pattern = case_when(
      up_ratio > 0.6 ~ "Strong Up",
      up_ratio < 0.4 ~ "Strong Down",
      TRUE ~ "Balanced"
    )
  )

# ============================================================================
# PANEL A: Distribution of Signature Strength (Violin Plot)
# ============================================================================

cat("Creating Panel A: Signature Strength Distribution...\n")

# Prepare data for violin plot
violin_data <- disease_df %>%
  select(disease, mean_up_logfc, mean_down_logfc) %>%
  pivot_longer(cols = c(mean_up_logfc, mean_down_logfc),
               names_to = "direction",
               values_to = "mean_logfc") %>%
  filter(!is.na(mean_logfc)) %>%
  mutate(
    direction = ifelse(direction == "mean_up_logfc", "Up-regulated", "Down-regulated"),
    direction = factor(direction, levels = c("Down-regulated", "Up-regulated"))
  )

panel_a <- ggplot(violin_data, aes(x = direction, y = mean_logfc, fill = direction)) +
  geom_violin(alpha = 0.7, color = "white", scale = "width", trim = FALSE) +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8, outlier.shape = NA) +
  geom_jitter(width = 0.1, alpha = 0.3, size = 1.2, color = "#2C3E50") +
  scale_fill_manual(values = c("Down-regulated" = COLOR_DOWN, "Up-regulated" = COLOR_UP),
                    guide = "none") +
  labs(
    title = "Distribution of Signature Strength",
    subtitle = sprintf("Up vs Down Regulated Genes (n=%d diseases)", nrow(disease_df)),
    x = "Gene Regulation Direction",
    y = "Mean Absolute Log2 Fold Change"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

# ============================================================================
# PANEL B: Up vs Down Regulated Gene Strength (Scatter Plot)
# ============================================================================

cat("Creating Panel B: Up vs Down Gene Strength Scatter...\n")

panel_b <- ggplot(disease_df, aes(x = mean_up_logfc, y = mean_down_logfc)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#888", linewidth = 0.8) +
  geom_point(aes(size = total_genes, color = regulation_pattern), alpha = 0.7) +
  scale_color_manual(
    values = c("Balanced" = COLOR_BALANCED, "Strong Up" = COLOR_STRONG_UP, "Strong Down" = COLOR_STRONG_DOWN),
    name = "Regulation\nPattern"
  ) +
  scale_size_continuous(
    name = "Total Genes",
    range = c(2, 10),
    breaks = c(500, 1000, 2000, 3000)
  ) +
  scale_x_continuous(breaks = seq(0, 0.05, 0.01), limits = c(0, 0.05)) +
  labs(
    title = "Up vs Down Regulated Gene Strength",
    subtitle = "Each point is one disease; dashed line indicates balance",
    x = "Up-regulated Gene Strength (Mean Log2FC)",
    y = "Down-regulated Gene Strength (Mean Log2FC)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
    axis.title = element_text(size = 11),
    legend.position = "right",
    legend.box = "vertical",
    panel.grid.minor = element_blank()
  ) +
  guides(
    size = guide_legend(order = 1),
    color = guide_legend(order = 2)
  )

# ============================================================================
# PANEL C: Total Signature Size Before and After Filtering (Box Plot)
# ============================================================================

cat("Creating Panel C: Signature Size Before/After Filtering...\n")

# Prepare data for box plot - using actual data
boxplot_data <- disease_df %>%
  select(disease, genes_before_standardization, genes_after_standardization) %>%
  filter(!is.na(genes_before_standardization) & !is.na(genes_after_standardization)) %>%
  pivot_longer(
    cols = c(genes_before_standardization, genes_after_standardization),
    names_to = "stage",
    values_to = "size"
  ) %>%
  mutate(
    stage = ifelse(stage == "genes_before_standardization", "Before Filtering", "After Filtering"),
    stage = factor(stage, levels = c("Before Filtering", "After Filtering"))
  )

# Calculate statistics for subtitle
before_stats <- disease_df %>% 
  summarise(
    mean = mean(genes_before_standardization, na.rm = TRUE),
    min = min(genes_before_standardization, na.rm = TRUE),
    max = max(genes_before_standardization, na.rm = TRUE)
  )

after_stats <- disease_df %>%
  summarise(
    mean = mean(genes_after_standardization, na.rm = TRUE),
    min = min(genes_after_standardization, na.rm = TRUE),
    max = max(genes_after_standardization, na.rm = TRUE)
  )

panel_c <- ggplot(boxplot_data, aes(x = stage, y = size, fill = stage)) +
  geom_boxplot(alpha = 0.85, color = "white", linewidth = 0.8, 
               outlier.size = 2, outlier.alpha = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.25, size = 1.5, color = "#34495E") +
  scale_fill_manual(
    values = c("Before Filtering" = COLOR_BEFORE, "After Filtering" = COLOR_AFTER),
    guide = "none"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.02, 0.1)),
    breaks = seq(0, 5000, 1000)
  ) +
  labs(
    title = "Total Signature Size Before and After Filtering",
    subtitle = sprintf("Distribution across %d diseases", nrow(disease_df)),
    x = "Stage",
    y = "Total Number of Genes"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

# ============================================================================
# PANEL D: Distribution of Up and Down Regulated Genes (Histogram)
# ============================================================================

cat("Creating Panel D: Up/Down Gene Distribution Histogram...\n")

# Prepare histogram data
hist_data <- disease_df %>%
  select(disease, up_genes, down_genes) %>%
  pivot_longer(cols = c(up_genes, down_genes),
               names_to = "direction",
               values_to = "count") %>%
  mutate(
    direction = ifelse(direction == "up_genes", "Up-regulated", "Down-regulated"),
    direction = factor(direction, levels = c("Up-regulated", "Down-regulated"))
  )

panel_d <- ggplot(hist_data, aes(x = count, fill = direction)) +
  geom_histogram(position = "identity", alpha = 0.7, bins = 40, color = "white", linewidth = 0.3) +
  scale_fill_manual(
    values = c("Up-regulated" = COLOR_UP, "Down-regulated" = COLOR_DOWN),
    name = "Gene Direction"
  ) +
  scale_x_continuous(
    breaks = seq(0, 2500, 500),
    expand = expansion(mult = c(0, 0.02))
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Distribution of Up and Down Regulated Genes",
    subtitle = sprintf("Across %d disease signatures", nrow(disease_df)),
    x = "Number of Genes",
    y = "Number of Diseases"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
    axis.title = element_text(size = 11),
    legend.position = c(0.85, 0.85),
    legend.background = element_rect(fill = "white", color = NA),
    panel.grid.minor = element_blank()
  )

# ============================================================================
# COMBINE ALL PANELS
# ============================================================================

cat("Combining all panels...\n")

# Create combined figure
combined_figure <- plot_grid(
  panel_a + theme(plot.margin = margin(10, 10, 10, 10)),
  panel_b + theme(plot.margin = margin(10, 10, 10, 10)),
  panel_c + theme(plot.margin = margin(10, 10, 10, 10)),
  panel_d + theme(plot.margin = margin(10, 10, 10, 10)),
  labels = c("A", "B", "C", "D"),
  label_size = 16,
  label_fontface = "bold",
  ncol = 2,
  nrow = 2,
  align = "hv"
)

# Save combined figure
output_dir <- "figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

ggsave(
  file.path(output_dir, "disease_signature_analysis_accurate.png"),
  combined_figure,
  width = 14,
  height = 12,
  dpi = 300,
  bg = "white"
)

ggsave(
  file.path(output_dir, "disease_signature_analysis_accurate.pdf"),
  combined_figure,
  width = 14,
  height = 12,
  bg = "white"
)

# Also save individual panels
ggsave(file.path(output_dir, "panel_A_signature_strength.png"), panel_a, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "panel_B_up_vs_down_strength.png"), panel_b, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "panel_C_size_before_after.png"), panel_c, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "panel_D_up_down_distribution.png"), panel_d, width = 7, height = 6, dpi = 300, bg = "white")

# ============================================================================
# PRINT SUMMARY STATISTICS
# ============================================================================

cat("\n")
cat("============================================================\n")
cat("SUMMARY STATISTICS FOR MANUSCRIPT\n")
cat("============================================================\n")
cat(sprintf("\nTotal diseases analyzed: %d\n", nrow(disease_df)))

cat("\n--- Signature Size (Before Filtering) ---\n")
cat(sprintf("  Mean: %.0f genes\n", mean(disease_df$genes_before_standardization, na.rm = TRUE)))
cat(sprintf("  Median: %.0f genes\n", median(disease_df$genes_before_standardization, na.rm = TRUE)))
cat(sprintf("  Range: %.0f - %.0f genes\n", 
            min(disease_df$genes_before_standardization, na.rm = TRUE),
            max(disease_df$genes_before_standardization, na.rm = TRUE)))
cat(sprintf("  SD: %.0f genes\n", sd(disease_df$genes_before_standardization, na.rm = TRUE)))

cat("\n--- Signature Size (After Filtering) ---\n")
cat(sprintf("  Mean: %.0f genes\n", mean(disease_df$genes_after_standardization, na.rm = TRUE)))
cat(sprintf("  Median: %.0f genes\n", median(disease_df$genes_after_standardization, na.rm = TRUE)))
cat(sprintf("  Range: %.0f - %.0f genes\n", 
            min(disease_df$genes_after_standardization, na.rm = TRUE),
            max(disease_df$genes_after_standardization, na.rm = TRUE)))
cat(sprintf("  SD: %.0f genes\n", sd(disease_df$genes_after_standardization, na.rm = TRUE)))

cat("\n--- Up-regulated Genes ---\n")
cat(sprintf("  Mean: %.0f genes\n", mean(disease_df$up_genes, na.rm = TRUE)))
cat(sprintf("  Median: %.0f genes\n", median(disease_df$up_genes, na.rm = TRUE)))
cat(sprintf("  Range: %.0f - %.0f genes\n", 
            min(disease_df$up_genes, na.rm = TRUE),
            max(disease_df$up_genes, na.rm = TRUE)))

cat("\n--- Down-regulated Genes ---\n")
cat(sprintf("  Mean: %.0f genes\n", mean(disease_df$down_genes, na.rm = TRUE)))
cat(sprintf("  Median: %.0f genes\n", median(disease_df$down_genes, na.rm = TRUE)))
cat(sprintf("  Range: %.0f - %.0f genes\n", 
            min(disease_df$down_genes, na.rm = TRUE),
            max(disease_df$down_genes, na.rm = TRUE)))

cat("\n--- Mean Log2FC (Up-regulated) ---\n")
cat(sprintf("  Mean: %.4f\n", mean(disease_df$mean_up_logfc, na.rm = TRUE)))
cat(sprintf("  Range: %.4f - %.4f\n", 
            min(disease_df$mean_up_logfc, na.rm = TRUE),
            max(disease_df$mean_up_logfc, na.rm = TRUE)))

cat("\n--- Mean Log2FC (Down-regulated) ---\n")
cat(sprintf("  Mean: %.4f\n", mean(disease_df$mean_down_logfc, na.rm = TRUE)))
cat(sprintf("  Range: %.4f - %.4f\n", 
            min(disease_df$mean_down_logfc, na.rm = TRUE),
            max(disease_df$mean_down_logfc, na.rm = TRUE)))

cat("\n============================================================\n")
cat("Figures saved to: tahoe_cmap_analysis/figures/\n")
cat("  - disease_signature_analysis_accurate.png\n")
cat("  - disease_signature_analysis_accurate.pdf\n")
cat("  - panel_A_signature_strength.png\n")
cat("  - panel_B_up_vs_down_strength.png\n")
cat("  - panel_C_size_before_after.png\n")
cat("  - panel_D_up_down_distribution.png\n")
cat("============================================================\n")
