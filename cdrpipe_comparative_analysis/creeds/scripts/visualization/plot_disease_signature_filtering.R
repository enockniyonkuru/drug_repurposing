#!/usr/bin/env Rscript
# ============================================================================
# Generate Disease Signature Analysis Panels
#
# Generates 4 panels using actual CREEDS standardized disease signatures:
#   Panel A: Distribution of Signature Strength (Violin Plot)
#   Panel B: Up vs Down Regulated Gene Strength (Scatter Plot)
#   Panel C: Signature Size Before/After Filtering (Box Plot)
#   Panel D: Distribution of Up/Down Regulated Genes (Histogram)
#
# Outputs (to creeds/figures/disease_signature_analysis/):
#   - disease_signature_four_panel_combined.png
#   - signature_strength_violin.png
#   - up_vs_down_strength_scatter.png
#   - signature_size_before_after_filtering.png
#   - up_down_gene_count_histogram.png
#
# Data sources:
#   - creeds/data/manual_signatures_standardized/*_signature.csv
#   - creeds/data/signature_gene_counts_across_stages.csv
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(cowplot)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
get_repo_root <- function() {
  candidates <- character()
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    candidates <- c(candidates, dirname(sub("^--file=", "", file_arg)))
  }
  if (!is.null(sys.frames()[[1]]$ofile)) {
    candidates <- c(candidates, dirname(sys.frames()[[1]]$ofile))
  }
  candidates <- c(candidates, getwd())

  for (start in unique(candidates)) {
    cur <- normalizePath(start, winslash = "/", mustWork = FALSE)
    repeat {
      if (dir.exists(file.path(cur, "scripts")) &&
          dir.exists(file.path(cur, "creeds"))) {
        return(cur)
      }
      nested <- file.path(cur, "cdrpipe_comparative_analysis")
      if (dir.exists(file.path(nested, "scripts")) &&
          dir.exists(file.path(nested, "creeds"))) {
        return(normalizePath(nested, winslash = "/", mustWork = FALSE))
      }
      parent <- dirname(cur)
      if (identical(parent, cur)) break
      cur <- parent
    }
  }

  stop("Could not locate cdrpipe_comparative_analysis root", call. = FALSE)
}
repo_root <- get_repo_root()

output_dir <- file.path(repo_root, "creeds", "figures", "disease_signature_analysis")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

sig_dir <- file.path(repo_root, "creeds", "data", "manual_signatures_standardized")
gene_counts_file <- file.path(repo_root, "creeds", "data",
                              "signature_gene_counts_across_stages.csv")

if (!dir.exists(sig_dir)) {
  stop("Missing figure input directory: ", sig_dir, call. = FALSE)
}
if (!file.exists(gene_counts_file)) {
  stop("Missing figure input file: ", gene_counts_file, call. = FALSE)
}

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
COLOR_UP      <- "#E74C3C"
COLOR_DOWN    <- "#3498DB"
COLOR_BEFORE  <- "#5DADE2"
COLOR_AFTER   <- "#2E86AB"
COLOR_BALANCED <- "#BDC3C7"

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
cat("Loading disease signature data...\n")

sig_files <- list.files(sig_dir, pattern = "_signature\\.csv$", full.names = TRUE)
cat(sprintf("Found %d signature files\n", length(sig_files)))

gene_counts <- read.csv(gene_counts_file, stringsAsFactors = FALSE)

disease_stats <- lapply(sig_files, function(f) {
  tryCatch({
    sig <- read.csv(f, stringsAsFactors = FALSE)
    disease_name <- gsub("_signature\\.csv$", "", basename(f))

    up_genes   <- sum(sig$signature_type == "UP", na.rm = TRUE)
    down_genes <- sum(sig$signature_type == "DOWN", na.rm = TRUE)
    total      <- nrow(sig)

    up_logfc   <- sig$mean_logfc[sig$signature_type == "UP"]
    down_logfc <- sig$mean_logfc[sig$signature_type == "DOWN"]

    data.frame(
      disease         = disease_name,
      up_genes        = up_genes,
      down_genes      = down_genes,
      total_genes     = total,
      mean_up_logfc   = if (length(up_logfc) > 0) mean(abs(up_logfc), na.rm = TRUE) else NA_real_,
      mean_down_logfc = if (length(down_logfc) > 0) mean(abs(down_logfc), na.rm = TRUE) else NA_real_,
      stringsAsFactors = FALSE
    )
  }, error = function(e) NULL)
})

disease_df <- do.call(rbind, disease_stats[!sapply(disease_stats, is.null)])
cat(sprintf("Successfully processed %d diseases\n", nrow(disease_df)))

disease_df <- disease_df %>%
  left_join(gene_counts, by = "disease") %>%
  mutate(
    up_ratio = up_genes / (up_genes + down_genes),
    regulation_pattern = case_when(
      up_ratio > 0.6 ~ "Strong Up",
      up_ratio < 0.4 ~ "Strong Down",
      TRUE ~ "Balanced"
    )
  )

# ============================================================================
# Panel A: Signature Strength (Violin)
# ============================================================================
cat("Creating Panel A...\n")

violin_data <- disease_df %>%
  select(disease, mean_up_logfc, mean_down_logfc) %>%
  pivot_longer(c(mean_up_logfc, mean_down_logfc), names_to = "direction", values_to = "mean_logfc") %>%
  filter(!is.na(mean_logfc)) %>%
  mutate(direction = factor(ifelse(direction == "mean_up_logfc", "Up-regulated", "Down-regulated"),
                            levels = c("Down-regulated", "Up-regulated")))

panel_a <- ggplot(violin_data, aes(x = direction, y = mean_logfc, fill = direction)) +
  geom_violin(alpha = 0.7, color = "white", scale = "width", trim = FALSE) +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8, outlier.shape = NA) +
  geom_jitter(width = 0.1, alpha = 0.3, size = 1.2, color = "#2C3E50") +
  scale_fill_manual(values = c("Down-regulated" = COLOR_DOWN, "Up-regulated" = COLOR_UP), guide = "none") +
  labs(title = "Distribution of Signature Strength",
       subtitle = sprintf("Up vs Down Regulated (n=%d diseases)", nrow(disease_df)),
       x = "Gene Regulation Direction", y = "Mean Absolute Log2 Fold Change") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
        panel.grid.major.x = element_blank())

# ============================================================================
# Panel B: Up vs Down Scatter
# ============================================================================
cat("Creating Panel B...\n")

panel_b <- ggplot(disease_df, aes(x = mean_up_logfc, y = mean_down_logfc)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#888", linewidth = 0.8) +
  geom_point(aes(size = total_genes, color = regulation_pattern), alpha = 0.7) +
  scale_color_manual(values = c("Balanced" = COLOR_BALANCED, "Strong Up" = COLOR_UP, "Strong Down" = COLOR_DOWN),
                     name = "Regulation\nPattern") +
  scale_size_continuous(name = "Total Genes", range = c(2, 10), breaks = c(500, 1000, 2000, 3000)) +
  labs(title = "Up vs Down Regulated Gene Strength",
       subtitle = "Each point is one disease; dashed line indicates balance",
       x = "Up-regulated (Mean Log2FC)", y = "Down-regulated (Mean Log2FC)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
        legend.position = "right")

# ============================================================================
# Panel C: Signature Size Before/After (Box)
# ============================================================================
cat("Creating Panel C...\n")

boxplot_data <- disease_df %>%
  select(disease, genes_before_standardization, genes_after_standardization) %>%
  filter(!is.na(genes_before_standardization), !is.na(genes_after_standardization)) %>%
  pivot_longer(c(genes_before_standardization, genes_after_standardization),
               names_to = "stage", values_to = "size") %>%
  mutate(stage = factor(ifelse(stage == "genes_before_standardization", "Before Filtering", "After Filtering"),
                        levels = c("Before Filtering", "After Filtering")))

panel_c <- ggplot(boxplot_data, aes(x = stage, y = size, fill = stage)) +
  geom_boxplot(alpha = 0.85, color = "white", linewidth = 0.8, outlier.size = 2) +
  geom_jitter(width = 0.15, alpha = 0.25, size = 1.5, color = "#34495E") +
  scale_fill_manual(values = c("Before Filtering" = COLOR_BEFORE, "After Filtering" = COLOR_AFTER), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.1)), breaks = seq(0, 5000, 1000)) +
  labs(title = "Signature Size Before and After Filtering",
       subtitle = sprintf("Distribution across %d diseases", nrow(disease_df)),
       x = "Stage", y = "Total Number of Genes") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
        panel.grid.major.x = element_blank())

# ============================================================================
# Panel D: Up/Down Gene Distribution (Histogram)
# ============================================================================
cat("Creating Panel D...\n")

hist_data <- disease_df %>%
  select(disease, up_genes, down_genes) %>%
  pivot_longer(c(up_genes, down_genes), names_to = "direction", values_to = "count") %>%
  mutate(direction = factor(ifelse(direction == "up_genes", "Up-regulated", "Down-regulated"),
                            levels = c("Up-regulated", "Down-regulated")))

panel_d <- ggplot(hist_data, aes(x = count, fill = direction)) +
  geom_histogram(position = "identity", alpha = 0.7, bins = 40, color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("Up-regulated" = COLOR_UP, "Down-regulated" = COLOR_DOWN), name = "Direction") +
  scale_x_continuous(breaks = seq(0, 2500, 500)) +
  labs(title = "Distribution of Up and Down Regulated Genes",
       subtitle = sprintf("Across %d disease signatures", nrow(disease_df)),
       x = "Number of Genes", y = "Number of Diseases") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, color = "#666", hjust = 0.5),
        legend.position = c(0.85, 0.85),
        legend.background = element_rect(fill = "white", color = NA))

# ============================================================================
# Combine
# ============================================================================
cat("Combining panels...\n")

combined <- plot_grid(
  panel_a + theme(plot.margin = margin(10, 10, 10, 10)),
  panel_b + theme(plot.margin = margin(10, 10, 10, 10)),
  panel_c + theme(plot.margin = margin(10, 10, 10, 10)),
  panel_d + theme(plot.margin = margin(10, 10, 10, 10)),
  labels = c("A", "B", "C", "D"),
  label_size = 16, label_fontface = "bold",
  ncol = 2, nrow = 2, align = "hv"
)

ggsave(file.path(output_dir, "disease_signature_four_panel_combined.png"), combined,
       width = 14, height = 12, dpi = 300, bg = "white")

ggsave(file.path(output_dir, "signature_strength_violin.png"), panel_a, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "up_vs_down_strength_scatter.png"), panel_b, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "signature_size_before_after_filtering.png"), panel_c, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "up_down_gene_count_histogram.png"), panel_d, width = 7, height = 6, dpi = 300, bg = "white")

cat("\nAll disease signature panels generated!\n")
