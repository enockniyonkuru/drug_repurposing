#!/usr/bin/env Rscript
# ============================================================================
# Generate Analysis Across Diseases Figures
#
# Outputs (to creeds/figures/analysis_across_diseases/):
#   - cmap_vs_tahoe_precision_recall_density.png
#   - recall_distribution_density.png
#   - precision_distribution_density.png
#   - precision_vs_recall_scatter.png
#
# Data source:
#   - creeds/analysis/CREEDS_Manual_All_Diseases_Analysis.xlsx
#     (sheet "all_diseases_q0.05")
# ============================================================================

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)

# Paths – relative to cdrpipe_comparative_analysis root
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
      if (dir.exists(file.path(cur, "shared")) &&
          dir.exists(file.path(cur, "creeds"))) {
        return(cur)
      }
      nested <- file.path(cur, "cdrpipe_comparative_analysis")
      if (dir.exists(file.path(nested, "shared")) &&
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

data_file  <- file.path(repo_root, "creeds", "analysis",
                        "CREEDS_Manual_All_Diseases_Analysis.xlsx")
output_dir <- file.path(repo_root, "creeds", "figures", "analysis_across_diseases")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

if (!file.exists(data_file)) {
  stop("Missing figure input: ", data_file, call. = FALSE)
}

# Load raw data
df <- read_excel(data_file, sheet = "all_diseases_q0.05")

# Calculate precision and recall
df <- df %>%
  mutate(
    tahoe_precision = ifelse(tahoe_hits_count > 0, (tahoe_in_known_count / tahoe_hits_count) * 100, NA),
    tahoe_recall    = ifelse(known_drugs_available_in_tahoe_count > 0, (tahoe_in_known_count / known_drugs_available_in_tahoe_count) * 100, NA),
    cmap_precision  = ifelse(cmap_hits_count > 0, (cmap_in_known_count / cmap_hits_count) * 100, NA),
    cmap_recall     = ifelse(known_drugs_available_in_cmap_count > 0, (cmap_in_known_count / known_drugs_available_in_cmap_count) * 100, NA)
  )

# Long-format for density plots
recall_data <- bind_rows(
  df %>% filter(!is.na(tahoe_recall)) %>% select(recall_pct = tahoe_recall) %>% mutate(Pipeline = "TAHOE"),
  df %>% filter(!is.na(cmap_recall))  %>% select(recall_pct = cmap_recall)  %>% mutate(Pipeline = "CMAP")
)

precision_data <- bind_rows(
  df %>% filter(!is.na(tahoe_precision)) %>% select(precision_pct = tahoe_precision) %>% mutate(Pipeline = "TAHOE"),
  df %>% filter(!is.na(cmap_precision))  %>% select(precision_pct = cmap_precision)  %>% mutate(Pipeline = "CMAP")
)

# Statistics for annotations
tahoe_recall_mean <- mean(df$tahoe_recall, na.rm = TRUE)
cmap_recall_mean  <- mean(df$cmap_recall,  na.rm = TRUE)
tahoe_prec_mean   <- mean(df$tahoe_precision, na.rm = TRUE)
cmap_prec_mean    <- mean(df$cmap_precision,  na.rm = TRUE)
tahoe_prec_median <- median(df$tahoe_precision, na.rm = TRUE)
cmap_prec_median  <- median(df$cmap_precision,  na.rm = TRUE)

# ------- Panel A: Recall Distribution Density -------
fig3a <- ggplot(recall_data, aes(x = recall_pct, fill = Pipeline, color = Pipeline)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  geom_vline(xintercept = tahoe_recall_mean, color = "#5DADE2", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = cmap_recall_mean,  color = "#F39C12", linetype = "dashed", linewidth = 1) +
  scale_fill_manual(values  = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  scale_color_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  labs(title = "A: Recall Distribution Density", x = "Recall (%)", y = "Density") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "inside", legend.position.inside = c(0.98, 0.97),
    legend.justification = c("right", "top"),
    legend.background = element_rect(fill = "white", color = "gray")
  ) +
  xlim(0, 105)

# ------- Panel B: Precision Distribution Density -------
fig3b <- ggplot(precision_data, aes(x = precision_pct, fill = Pipeline, color = Pipeline)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  geom_vline(xintercept = tahoe_prec_mean, color = "#5DADE2", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = cmap_prec_mean,  color = "#F39C12", linetype = "dashed", linewidth = 1) +
  scale_fill_manual(values  = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  scale_color_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  annotate("text", x = 22.5, y = Inf,
           label = paste0("CMAP: Mean=", round(cmap_prec_mean, 1), "%, Median=", round(cmap_prec_median, 1), "%\n",
                          "TAHOE: Mean=", round(tahoe_prec_mean, 1), "%, Median=", round(tahoe_prec_median, 1), "%"),
           fontface = "bold", size = 3.5, hjust = 0.5, vjust = 1.2) +
  labs(title = "B: Precision Distribution Density", x = "Precision (%)", y = "Density") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "none"
  ) +
  xlim(0, 45)

# ------- Panel C: Precision vs Recall Scatter -------
scatter_data <- df %>%
  select(disease_name, disease_id, tahoe_precision, tahoe_recall, cmap_precision, cmap_recall) %>%
  pivot_longer(
    cols = -c(disease_name, disease_id),
    names_to = c("Pipeline", "Metric"),
    names_sep = "_",
    values_to = "Value"
  ) %>%
  pivot_wider(names_from = Metric, values_from = Value) %>%
  filter(!is.na(precision) | !is.na(recall))

fig3c <- ggplot(scatter_data, aes(x = precision, y = recall, color = Pipeline)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_vline(xintercept = 50, linetype = "dotted", color = "gray", linewidth = 0.5) +
  geom_hline(yintercept = 50, linetype = "dotted", color = "gray", linewidth = 0.5) +
  scale_color_manual(values = c("tahoe" = "#5DADE2", "cmap" = "#F39C12")) +
  labs(
    title = "C: Precision Vs Recall by Disease",
    subtitle = "(Each point = one disease)",
    x = "Precision (%)", y = "Recall (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 10, color = "gray50"),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "inside", legend.position.inside = c(0.98, 0.98),
    legend.justification = c("right", "top"),
    legend.background = element_rect(fill = "white", color = "gray")
  ) +
  xlim(0, 100) + ylim(0, 105)

# ------- Combine and save -------
combined_figure <- gridExtra::grid.arrange(fig3a, fig3b, fig3c, ncol = 3, widths = c(1, 1, 1))

ggsave(file.path(output_dir, "cmap_vs_tahoe_precision_recall_density.png"), combined_figure, width = 16, height = 5, dpi = 300)

# ------- Save individual panels -------
ggsave(file.path(output_dir, "recall_distribution_density.png"), fig3a, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "precision_distribution_density.png"), fig3b, width = 7, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "precision_vs_recall_scatter.png"), fig3c, width = 7, height = 6, dpi = 300, bg = "white")

cat("\nAll analysis across diseases figures saved to:", output_dir, "\n")
