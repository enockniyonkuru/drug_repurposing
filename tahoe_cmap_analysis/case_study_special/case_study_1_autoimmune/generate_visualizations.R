#!/usr/bin/env Rscript
# ============================================================================
# Generate comprehensive visualizations for disease results
# Output: Individual disease visualizations + 4-disease comparative analysis
# ============================================================================

library(readxl)
library(tidyverse)
library(gridExtra)
library(ggplot2)
library(scales)
library(RColorBrewer)




# Setup paths and create output directory
base_dir <- "tahoe_cmap_analysis/case_study_special"
viz_dir <- file.path(base_dir, "visualizations")
dir.create(viz_dir, showWarnings = FALSE)

# ============================================================================
# 1. Load and prepare data
# ============================================================================
excel_file <- file.path(base_dir, "4_disease_results.xlsx")
results_df <- read_excel(excel_file, sheet = "Sheet1")

# Keep original column names and calculate recalls correctly
# Recall = Found by DRPipe / Total in OpenTarget for that method * 100
results_df <- results_df %>%
  mutate(
    # Calculate recalls as percentages
    tahoe_recall = (`Total Disease-Drug Pairs in Open Targets and also in TAHOE  that were found by DRPipe` / 
                    `Total Disease-Drug Pairs in Open Target and also in Tahoe  for this disease` * 100),
    cmap_recall = (`Total Disease-Drug Pairs in Open Targets and also in CMAP  that were found by DRPipe` / 
                   `Total Disease-Drug Pairs in Open Target and also in CMAP  for this disease` * 100),
    # Handle any NaN or Inf values
    tahoe_recall = ifelse(is.na(tahoe_recall) | is.infinite(tahoe_recall), 0, tahoe_recall),
    cmap_recall = ifelse(is.na(cmap_recall) | is.infinite(cmap_recall), 0, cmap_recall)
  ) %>%
  rename(
    disease_name = `disease_name`,
    tahoe_hits = `Total Tahoe Hits by DRPipe`,
    cmap_hits = `Total CMAP Hits by DRPipe`,
    common_hits = `Total Common Hits by DRPipe with TAHOE and CMAP`,
    ot_pairs_total = `Total Disease-Drug Pairs in Open Target for this disease`,
    ot_cmap_pairs = `Total Disease-Drug Pairs in Open Target and also in CMAP  for this disease`,
    ot_tahoe_pairs = `Total Disease-Drug Pairs in Open Target and also in Tahoe  for this disease`,
    ot_tahoe_drpipe_found = `Total Disease-Drug Pairs in Open Targets and also in TAHOE  that were found by DRPipe`,
    ot_cmap_drpipe_found = `Total Disease-Drug Pairs in Open Targets and also in CMAP  that were found by DRPipe`,
    ot_drpipe_total = `Total Disease-Drug Pairs in Open Target found by DRPipe`
  )

# Format disease names
results_df <- results_df %>%
  mutate(
    disease_name = str_to_title(disease_name),
    disease_name = str_replace(disease_name, "Pur.*", "Purpura"),
    disease_name = str_trim(disease_name)
  )

cat("Data loaded successfully!\n")
cat("Diseases:", paste(results_df$disease_name, collapse=", "), "\n\n")

# ============================================================================
# 2. Individual Disease Visualizations
# ============================================================================

create_individual_disease_viz <- function(df, disease_idx) {
  disease_data <- df[disease_idx, ]
  disease_name <- disease_data$disease_name
  
  cat("Creating visualizations for:", disease_name, "\n")
  
  # Create output folder for this disease
  disease_dir <- file.path(viz_dir, paste0("0", disease_idx, "_", 
                                            gsub(" ", "_", tolower(disease_name))))
  dir.create(disease_dir, showWarnings = FALSE)
  
  # ---- Visualization 1: Hit Distribution (Tahoe vs CMAP + Common) ----
  hits_data <- data.frame(
    method = c("TAHOE", "CMAP", "Common"),
    hits = c(disease_data$tahoe_hits, disease_data$cmap_hits, disease_data$common_hits)
  )
  
  p1 <- ggplot(hits_data, aes(x = reorder(method, -hits), y = hits, fill = method)) +
    geom_col(width = 0.6, alpha = 0.8) +
    geom_text(aes(label = hits), vjust = -0.5, size = 5, fontface = "bold") +
    scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12", "Common" = "#9B59B6")) +
    theme_minimal() +
    labs(
      title = paste0("Hit Comparison - ", disease_name),
      y = "Number of Hits",
      x = ""
    ) +
    scale_y_continuous(limits = c(0, max(hits_data$hits) * 1.2)) +
    theme(
      legend.position = "none", 
      axis.text.x = element_text(size = 11),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # ---- Visualization 2: Recall Metrics ----
  recall_data <- data.frame(
    method = c("TAHOE", "CMAP"),
    recall = c(disease_data$tahoe_recall, disease_data$cmap_recall)
  )
  
  p2 <- ggplot(recall_data, aes(x = reorder(method, -recall), y = recall, fill = method)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = paste0(round(recall, 1), "%")), 
              vjust = -0.5, size = 4, fontface = "bold") +
    scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
    theme_minimal() +
    labs(
      title = paste0("Recall Metrics (%) - ", disease_name),
      y = "Recall (%)",
      x = ""
    ) +
    scale_y_continuous(limits = c(0, 100)) +
    theme(
      legend.position = "none", 
      axis.text.x = element_text(size = 11),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # ---- Visualization 3: OpenTarget Coverage ----
  ot_data <- data.frame(
    category = c("Total OT Pairs", "OT + TAHOE\n(DRPipe Found)", "OT + CMAP\n(DRPipe Found)"),
    count = c(
      disease_data$ot_pairs_total,
      disease_data$ot_tahoe_drpipe_found,
      disease_data$ot_cmap_drpipe_found
    )
  )
  
  p3 <- ggplot(ot_data, aes(x = reorder(category, -count), y = count, fill = category)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = count), vjust = -0.5, size = 4, fontface = "bold") +
    scale_fill_manual(values = c(
      "Total OT Pairs" = "#9B59B6",
      "OT + TAHOE\n(DRPipe Found)" = "#5DADE2",
      "OT + CMAP\n(DRPipe Found)" = "#F39C12"
    )) +
    theme_minimal() +
    labs(
      title = paste0("OpenTarget Coverage - ", disease_name),
      y = "Count",
      x = ""
    ) +
    scale_y_continuous(limits = c(0, disease_data$ot_pairs_total * 1.15)) +
    theme(
      legend.position = "none", 
      axis.text.x = element_text(size = 10, angle = 0),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # ---- Visualization 4: Method Overlap ----
  overlap_data <- data.frame(
    category = c("TAHOE Only", "CMAP Only", "Common"),
    count = c(
      disease_data$tahoe_hits - disease_data$common_hits,
      disease_data$cmap_hits - disease_data$common_hits,
      disease_data$common_hits
    )
  )
  
  p4 <- ggplot(overlap_data, aes(x = "", y = count, fill = category)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    coord_polar("y", start = 0) +
    scale_fill_manual(values = c(
      "TAHOE Only" = "#5DADE2",
      "CMAP Only" = "#F39C12",
      "Common" = "#9B59B6"
    )) +
    theme_void() +
    labs(title = paste0("Method Overlap - ", disease_name), fill = "Category") +
    geom_text(aes(label = count), position = position_stack(vjust = 0.5), 
              fontface = "bold", size = 4) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 12))
  
  # Combine into grid
  combined <- gridExtra::grid.arrange(p1, p2, p3, p4, ncol = 2)
  
  ggsave(
    file.path(disease_dir, "01_comprehensive_overview.png"),
    combined, width = 14, height = 10, dpi = 300
  )
  
  # Save individual plots
  ggsave(file.path(disease_dir, "01a_hit_comparison.png"), p1, width = 6, height = 4, dpi = 300)
  ggsave(file.path(disease_dir, "01b_recall_metrics.png"), p2, width = 6, height = 4, dpi = 300)
  ggsave(file.path(disease_dir, "01c_ot_coverage.png"), p3, width = 6, height = 4, dpi = 300)
  ggsave(file.path(disease_dir, "01d_method_overlap.png"), p4, width = 6, height = 4, dpi = 300)
  
  # ---- NEW Visualization 5: OpenTarget Metrics Breakdown ----
  ot_metrics_data <- data.frame(
    category = c(
      "OT + CMAP",
      "OT + TAHOE",
      "OT + TAHOE\n(DRPipe)",
      "OT + CMAP\n(DRPipe)",
      "OT Total\n(DRPipe)"
    ),
    count = c(
      disease_data$ot_cmap_pairs,
      disease_data$ot_tahoe_pairs,
      disease_data$ot_tahoe_drpipe_found,
      disease_data$ot_cmap_drpipe_found,
      disease_data$ot_drpipe_total
    )
  )
  
  p5 <- ggplot(ot_metrics_data, aes(x = reorder(category, -count), y = count, fill = category)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = count), vjust = -0.5, size = 4, fontface = "bold") +
    scale_fill_manual(values = c(
      "OT + CMAP" = "#F39C12",
      "OT + TAHOE" = "#5DADE2",
      "OT + TAHOE\n(DRPipe)" = "#4A90E2",
      "OT + CMAP\n(DRPipe)" = "#E8A838",
      "OT Total\n(DRPipe)" = "#9B59B6"
    )) +
    theme_minimal() +
    labs(
      title = paste0("OpenTarget Metrics Breakdown - ", disease_name),
      y = "Count",
      x = ""
    ) +
    theme(
      legend.position = "none",
      axis.text.x = element_text(size = 9, angle = 0),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  ggsave(file.path(disease_dir, "01e_ot_metrics_breakdown.png"), p5, width = 10, height = 5, dpi = 300)
  
  # ---- NEW Visualization 6: Comprehensive OpenTarget + Recall Analysis ----
  summary_metrics <- data.frame(
    metric = c(
      "OT+CMAP", "OT+TAHOE", "OT+TAHOE(DP)", 
      "OT+CMAP(DP)", "OT Total(DP)", "TAHOE%", "CMAP%"
    ),
    value = c(
      disease_data$ot_cmap_pairs,
      disease_data$ot_tahoe_pairs,
      disease_data$ot_tahoe_drpipe_found,
      disease_data$ot_cmap_drpipe_found,
      disease_data$ot_drpipe_total,
      disease_data$tahoe_recall,
      disease_data$cmap_recall
    ),
    type = c(
      "Pairs", "Pairs", "Pairs", "Pairs", "Pairs", "Recall", "Recall"
    )
  )
  
  p6 <- ggplot(summary_metrics, aes(x = reorder(metric, -value), y = value, fill = type)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = round(value, 1)), vjust = -0.5, size = 3.5, fontface = "bold") +
    scale_fill_manual(values = c(
      "Pairs" = "#9B59B6",
      "Recall" = "#5DADE2"
    )) +
    theme_minimal() +
    labs(
      title = paste0("Complete Analysis: OpenTarget Pairs & Recall - ", disease_name),
      y = "Count / Percentage",
      x = "",
      fill = "Type"
    ) +
    theme(
      axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    )
  
  ggsave(file.path(disease_dir, "01f_complete_analysis.png"), p6, width = 11, height = 6, dpi = 300)
  
  cat("  ✓ Saved individual visualizations\n")
  
  return(disease_dir)
}

# Generate visualizations for each disease
disease_dirs <- list()
for (i in 1:nrow(results_df)) {
  disease_dirs[[i]] <- create_individual_disease_viz(results_df, i)
}

# ============================================================================
# 3. 4-Disease Comparative Visualizations
# ============================================================================

cat("\n\nCreating 4-disease comparative visualizations...\n")

# ---- Comparison 1: Stacked Bar Chart (Hit Distribution) ----
hits_long <- results_df %>%
  select(disease_name, tahoe_hits, cmap_hits) %>%
  pivot_longer(cols = c(tahoe_hits, cmap_hits), 
               names_to = "method", values_to = "hits") %>%
  mutate(method = str_replace(method, "_hits", "") %>% str_to_upper())

  p_stacked <- ggplot(hits_long, aes(x = reorder(disease_name, -hits), y = hits, fill = method)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("#F39C12", "#5DADE2")) +
  theme_minimal() +
  labs(
    title = "Hit Distribution Across All Diseases",
    y = "Number of Hits",
    x = "Disease",
    fill = "Method"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    legend.position = "right"
  )

ggsave(file.path(viz_dir, "02_all_diseases_hit_distribution.png"), 
       p_stacked, width = 10, height = 6, dpi = 300)

# ---- Comparison 2: Recall Metrics All Diseases ----
recall_long <- results_df %>%
  select(disease_name, tahoe_recall, cmap_recall) %>%
  pivot_longer(cols = c(tahoe_recall, cmap_recall), 
               names_to = "method", values_to = "recall") %>%
  mutate(method = str_replace(method, "_recall", "") %>% str_to_upper())

  p_recall <- ggplot(recall_long, aes(x = reorder(disease_name, -recall), y = recall, fill = method)) +
  geom_col(position = "dodge", alpha = 0.8) +
  geom_text(aes(label = paste0(round(recall, 0), "%")), 
            position = position_dodge(width = 0.9), vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = c("#F39C12", "#5DADE2")) +
  theme_minimal() +
  labs(
    title = "Recall Performance Across All Diseases",
    y = "Recall (%)",
    x = "Disease",
    fill = "Method"
  ) +
  scale_y_continuous(limits = c(0, 100)) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    legend.position = "right"
  )

ggsave(file.path(viz_dir, "03_all_diseases_recall.png"), 
       p_recall, width = 10, height = 6, dpi = 300)

# ---- Comparison 3: Common Hits Heatmap ----
heatmap_data <- results_df %>%
  select(disease_name, tahoe_hits, cmap_hits, common_hits) %>%
  pivot_longer(cols = c(tahoe_hits, cmap_hits, common_hits),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = factor(metric, 
                         levels = c("tahoe_hits", "cmap_hits", "common_hits"),
                         labels = c("TAHOE Hits", "CMAP Hits", "Common Hits")))

p_heatmap <- ggplot(heatmap_data, aes(x = disease_name, y = metric, fill = value)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = value), fontface = "bold", size = 4) +
  scale_fill_gradient(low = "#FFF7FB", high = "#49006A", name = "Count") +
  theme_minimal() +
  labs(
    title = "Hit Distribution Heatmap",
    x = "Disease",
    y = "Metric"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5)
  )

ggsave(file.path(viz_dir, "04_all_diseases_heatmap.png"), 
       p_heatmap, width = 10, height = 5, dpi = 300)

# ---- Comparison 4: OpenTarget Coverage Comparison ----
ot_comparison <- results_df %>%
  select(disease_name, ot_pairs_total, ot_tahoe_drpipe_found, ot_cmap_drpipe_found) %>%
  pivot_longer(cols = c(ot_tahoe_drpipe_found, ot_cmap_drpipe_found),
               names_to = "method", values_to = "found") %>%
  mutate(method = str_replace(method, "ot_", "") %>% 
           str_replace("_drpipe_found", "") %>% 
           str_to_upper())

  p_ot <- ggplot(ot_comparison, aes(x = reorder(disease_name, -found), y = found, fill = method)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("#F39C12", "#5DADE2")) +
  theme_minimal() +
  labs(
    title = "OpenTarget Coverage: DRPipe-Found Pairs",
    y = "Number of Pairs Found",
    x = "Disease",
    fill = "Method"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    legend.position = "right"
  )

ggsave(file.path(viz_dir, "05_all_diseases_ot_coverage.png"), 
       p_ot, width = 10, height = 6, dpi = 300)

# ---- Comparison 5: Method Performance Summary (Scatter) ----
p_scatter <- ggplot(results_df, aes(x = tahoe_recall, y = cmap_recall, size = tahoe_hits + cmap_hits)) +
  geom_point(aes(color = disease_name), alpha = 0.7) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray", alpha = 0.5) +
  scale_size_continuous(name = "Total Hits", range = c(3, 8)) +
  theme_minimal() +
  labs(
    title = "Method Performance Comparison",
    x = "TAHOE Recall (%)",
    y = "CMAP Recall (%)",
    color = "Disease"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    legend.position = "right"
  )

ggsave(file.path(viz_dir, "06_performance_scatter.png"), 
       p_scatter, width = 10, height = 6, dpi = 300)

# ---- Comparison 6: Common Hits by Disease ----
common_summary <- results_df %>%
  select(disease_name, tahoe_hits, cmap_hits, common_hits) %>%
  arrange(desc(common_hits))

p_common <- ggplot(common_summary, aes(x = reorder(disease_name, common_hits), y = common_hits)) +
  geom_col(fill = "#9B59B6", alpha = 0.8, color = "black", linewidth = 0.7) +
  geom_text(aes(label = common_hits), hjust = -0.3, fontface = "bold") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Common Hits Between TAHOE and CMAP",
    x = "Disease",
    y = "Common Hits"
  ) +
  scale_y_continuous(limits = c(0, max(common_summary$common_hits) * 1.15)) +
  theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))

ggsave(file.path(viz_dir, "07_common_hits.png"), 
       p_common, width = 10, height = 6, dpi = 300)

# ---- Comparison 7: Comprehensive Summary Table ----
summary_table <- results_df %>%
  select(disease_name, tahoe_hits, cmap_hits, common_hits, tahoe_recall, cmap_recall) %>%
  mutate(
    tahoe_recall = paste0(round(tahoe_recall, 2), "%"),
    cmap_recall = paste0(round(cmap_recall, 2), "%")
  ) %>%
  rename(
    "Disease" = disease_name,
    "TAHOE Hits" = tahoe_hits,
    "CMAP Hits" = cmap_hits,
    "Common Hits" = common_hits,
    "TAHOE Recall" = tahoe_recall,
    "CMAP Recall" = cmap_recall
  )

# Create a table plot
p_table <- ggplot() +
  annotation_custom(tableGrob(summary_table, theme = ttheme_default(base_size = 11))) +
  theme_void()

ggsave(file.path(viz_dir, "08_summary_table.png"), 
       p_table, width = 12, height = 5, dpi = 300)

# ---- Comparison 8: 2x2 Grid of Disease Performance ----
disease_viz_list <- list()
for (i in 1:nrow(results_df)) {
  d <- results_df[i, ]
  
  # Create mini plot for each disease
  p_mini <- ggplot(d, aes(x = 1, y = 1)) +
    annotate("text", x = 1.5, y = 0.8, label = d$disease_name, 
             size = 5, fontface = "bold", hjust = 0) +
    annotate("text", x = 1.5, y = 0.6, 
             label = paste0("TAHOE: ", d$tahoe_hits, " hits | ", d$tahoe_recall, "% recall"),
             size = 4, hjust = 0, color = "#5DADE2") +
    annotate("text", x = 1.5, y = 0.4, 
             label = paste0("CMAP: ", d$cmap_hits, " hits | ", d$cmap_recall, "% recall"),
             size = 4, hjust = 0, color = "#F39C12") +
    annotate("text", x = 1.5, y = 0.2, 
             label = paste0("Common: ", d$common_hits, " hits"),
             size = 4, hjust = 0, color = "#9B59B6", fontface = "bold") +
    xlim(0, 3) + ylim(0, 1) +
    theme_void() +
    theme(plot.background = element_rect(fill = ifelse(i %% 2 == 0, "#F0F0F0", "white"), 
                                         color = "black", size = 1))
  
  disease_viz_list[[i]] <- p_mini
}

p_grid_all <- gridExtra::grid.arrange(
  disease_viz_list[[1]], disease_viz_list[[2]],
  disease_viz_list[[3]], disease_viz_list[[4]],
  ncol = 2, nrow = 2,
  top = grid::textGrob("Disease-by-Disease Summary", 
                       gp = grid::gpar(fontsize = 16, fontface = "bold"))
)

ggsave(file.path(viz_dir, "09_disease_summary_grid.png"), 
       p_grid_all, width = 12, height = 10, dpi = 300)

# ============================================================================
# 4. Create Summary Report
# ============================================================================

summary_text <- sprintf(
  "
=============================================================================
          COMPREHENSIVE DISEASE RESULTS VISUALIZATION SUMMARY
=============================================================================

Analysis Date: %s
Number of Diseases: %d
Diseases Analyzed: %s

KEY METRICS ACROSS ALL DISEASES
==============================

TAHOE Method:
  - Total Hits: %d (Range: %d - %d)
  - Average Recall: %.2f%%
  
CMAP Method:
  - Total Hits: %d (Range: %d - %d)
  - Average Recall: %.2f%%

Common Findings:
  - Total Common Hits: %d
  - Average Common Hits per Disease: %.1f

OpenTarget Coverage:
  - Average OT Pairs per Disease: %.1f
  - Average OT-TAHOE Pairs Found: %.1f
  - Average OT-CMAP Pairs Found: %.1f

VISUALIZATIONS CREATED
======================

Individual Disease Visualizations (for each of %d diseases):
  ✓ Comprehensive overview (4-panel plot)
  ✓ Hit comparison
  ✓ Recall metrics
  ✓ OpenTarget coverage
  ✓ Method overlap

4-Disease Comparative Visualizations:
  ✓ Hit distribution across all diseases (dodged bar chart)
  ✓ Recall performance comparison
  ✓ Hit distribution heatmap
  ✓ OpenTarget coverage comparison
  ✓ Method performance scatter plot
  ✓ Common hits summary
  ✓ Comprehensive summary table
  ✓ Disease-by-disease summary grid

OUTPUT STRUCTURE
================
visualizations/
  ├── 01_*/ (Individual disease folders)
  │   ├── 01_comprehensive_overview.png
  │   ├── 01a_hit_comparison.png
  │   ├── 01b_recall_metrics.png
  │   ├── 01c_ot_coverage.png
  │   └── 01d_method_overlap.png
  │
  ├── 02_all_diseases_hit_distribution.png
  ├── 03_all_diseases_recall.png
  ├── 04_all_diseases_heatmap.png
  ├── 05_all_diseases_ot_coverage.png
  ├── 06_performance_scatter.png
  ├── 07_common_hits.png
  ├── 08_summary_table.png
  └── 09_disease_summary_grid.png

=============================================================================
  All visualizations ready for manuscript inclusion!
=============================================================================
",
  Sys.Date(),
  nrow(results_df),
  paste(results_df$disease_name, collapse = ", "),
  sum(results_df$tahoe_hits), min(results_df$tahoe_hits), max(results_df$tahoe_hits),
  mean(results_df$tahoe_recall),
  sum(results_df$cmap_hits), min(results_df$cmap_hits), max(results_df$cmap_hits),
  mean(results_df$cmap_recall),
  sum(results_df$common_hits), mean(results_df$common_hits),
  mean(results_df$ot_pairs_total),
  mean(results_df$ot_tahoe_drpipe_found),
  mean(results_df$ot_cmap_drpipe_found),
  nrow(results_df)
)

cat(summary_text)

# Save summary report
summary_file <- file.path(viz_dir, "VISUALIZATION_SUMMARY.txt")
writeLines(summary_text, summary_file)

cat("\n✓ Summary report saved to:", summary_file, "\n")

# ============================================================================
# 5. Print final statistics
# ============================================================================

cat("\n\n")
cat(strrep("=", 80), "\n")
cat("VISUALIZATION GENERATION COMPLETE\n")
cat(strrep("=", 80), "\n")
cat("Output directory:", viz_dir, "\n")
cat("Total files created:", length(list.files(viz_dir, recursive = TRUE)), "\n\n")
