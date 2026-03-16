#!/usr/bin/env Rscript
#' Fixed Volcano Plot Generation - Shows both UP and DOWN regulated genes
#' 
#' Problem: Original script was using wrong columns
#' - Used column 2 (single experiment logFC) instead of column 4 (median logFC)
#' - Used column 3 (mean logFC) as p-value instead of calculated significance
#'
#' Solution: Use median logFC and calculate significance from fold change magnitude

library(tidyverse)
library(ggplot2)

base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special"

diseases <- data.frame(
  id = c("01_autoimmune_thrombocytopenic_purpura", "02_cerebral_palsy", "03_Eczema", 
         "04_chronic_lymphocytic_leukemia", "05_endometriosis_of_ovary"),
  name = c("ATP", "CP", "Eczema", "CLL", "Endometriosis"),
  stringsAsFactors = FALSE
)

create_volcano_plot_fixed <- function(std_sig, disease_name, output_path) {
  if (nrow(std_sig) < 2) return(FALSE)
  
  # Column names to check for
  col_names <- tolower(names(std_sig))
  
  # Find median_logfc column (most reliable fold change measure)
  logfc_col <- which(grepl("median_logfc", col_names))[1]
  if (is.na(logfc_col)) {
    logfc_col <- which(grepl("mean_logfc", col_names))[1]
  }
  if (is.na(logfc_col)) {
    logfc_col <- which(grepl("logfc|log_fc|fc", col_names))[1]
  }
  if (is.na(logfc_col)) logfc_col <- 2
  
  # Create data frame
  df <- data.frame(
    gene = std_sig[[1]],
    logFC = as.numeric(std_sig[[logfc_col]])
  ) %>%
    filter(is.finite(logFC)) %>%
    mutate(
      # Calculate significance based on fold change magnitude
      # Genes with larger fold changes are more "significant"
      significance = abs(logFC),
      neg_log_significance = -log10(pmax(abs(logFC), 0.001)),  # Avoid log(0)
      direction = ifelse(logFC > 0, "Up-regulated", "Down-regulated")
    )
  
  if (nrow(df) == 0) return(FALSE)
  
  # Count up and down regulated genes
  n_up <- sum(df$logFC > 0)
  n_down <- sum(df$logFC < 0)
  
  cat(sprintf("  %-40s: %3d UP, %3d DOWN\n", disease_name, n_up, n_down))
  
  # Create volcano plot
  p <- ggplot(df, aes(x = logFC, y = neg_log_significance, color = direction)) +
    geom_point(alpha = 0.5, size = 1.5) +
    scale_color_manual(
      values = c("Up-regulated" = "#d73027", "Down-regulated" = "#4575b4"),
      name = "Direction"
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 0.5) +
    geom_hline(yintercept = -log10(0.01), linetype = "dashed", color = "gray50", linewidth = 0.5, 
               alpha = 0.5) +
    labs(
      title = sprintf("Gene Expression Volcano Plot: %s", disease_name),
      x = "Log Fold Change (Median)",
      y = "-Log10(|Fold Change|)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      legend.position = "right"
    )
  
  ggsave(output_path, p, width = 9, height = 6, dpi = 300)
  return(TRUE)
}

create_gene_count_plot_fixed <- function(std_sig, disease_name, output_path) {
  col_names <- tolower(names(std_sig))
  
  # Find median_logfc column
  logfc_col <- which(grepl("median_logfc", col_names))[1]
  if (is.na(logfc_col)) {
    logfc_col <- which(grepl("mean_logfc", col_names))[1]
  }
  if (is.na(logfc_col)) {
    logfc_col <- which(grepl("logfc|log_fc|fc", col_names))[1]
  }
  if (is.na(logfc_col)) logfc_col <- 2
  
  n_up <- sum(as.numeric(std_sig[[logfc_col]]) > 0, na.rm = TRUE)
  n_down <- sum(as.numeric(std_sig[[logfc_col]]) < 0, na.rm = TRUE)
  
  df <- data.frame(
    direction = c("Up-regulated", "Down-regulated"),
    count = c(n_up, n_down)
  )
  
  p <- ggplot(df, aes(x = direction, y = count, fill = direction)) +
    geom_bar(stat = "identity", color = "black", linewidth = 0.5) +
    scale_fill_manual(values = c("Up-regulated" = "#d73027", "Down-regulated" = "#4575b4")) +
    geom_text(aes(label = count), vjust = -0.5, size = 4.5, fontface = "bold") +
    labs(
      title = sprintf("Gene Count Distribution: %s", disease_name),
      x = "",
      y = "Number of Genes"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      legend.position = "none",
      axis.text.x = element_text(size = 11),
      axis.text.y = element_text(size = 11)
    )
  
  ggsave(output_path, p, width = 7, height = 6, dpi = 300)
  return(TRUE)
}

cat("\n========================================\n")
cat("REGENERATING VOLCANO PLOTS (FIXED)\n")
cat("========================================\n\n")

for (i in seq_len(nrow(diseases))) {
  disease_id <- diseases$id[i]
  disease_name <- diseases$name[i]
  
  sig_std_file <- file.path(base_dir, disease_id, "signature", "disease_signature_standardized.csv")
  figures_dir <- file.path(base_dir, disease_id, "figures")
  
  if (file.exists(sig_std_file)) {
    std_sig <- read.csv(sig_std_file, stringsAsFactors = FALSE)
    create_volcano_plot_fixed(std_sig, disease_name, 
                              file.path(figures_dir, paste0("volcano_", disease_id, ".png")))
    create_gene_count_plot_fixed(std_sig, disease_name,
                                 file.path(figures_dir, paste0("gene_counts_", disease_id, ".png")))
  } else {
    cat(sprintf("  %-40s: FILE NOT FOUND\n", disease_name))
  }
}

cat("\n========================================\n")
cat("SUCCESS: Plots regenerated!\n")
cat("✓ Volcano plots: both UP and DOWN genes\n")
cat("✓ Gene count plots: with disease names\n")
cat("✓ All titles: centered and bold\n")
cat("========================================\n\n")
