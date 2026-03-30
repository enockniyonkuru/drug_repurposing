#!/usr/bin/env Rscript
library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)

# Load raw data
df <- read_excel("creeds_diseases/analysis/Exp8_Analysis.xlsx", sheet = "exp_8_0.05")

# Calculate precision and recall
df <- df %>%
  mutate(
    tahoe_precision = ifelse(tahoe_hits_count > 0, (tahoe_in_known_count / tahoe_hits_count) * 100, NA),
    tahoe_recall = ifelse(known_drugs_available_in_tahoe_count > 0, (tahoe_in_known_count / known_drugs_available_in_tahoe_count) * 100, NA),
    cmap_precision = ifelse(cmap_hits_count > 0, (cmap_in_known_count / cmap_hits_count) * 100, NA),
    cmap_recall = ifelse(known_drugs_available_in_cmap_count > 0, (cmap_in_known_count / known_drugs_available_in_cmap_count) * 100, NA)
  )

# For recall analysis, filter for diseases with P > 0
df_recall <- df %>% 
  mutate(
    has_tahoe = !is.na(tahoe_recall),
    has_cmap = !is.na(cmap_recall)
  )

# Create long format for density plots
recall_data <- bind_rows(
  df_recall %>% filter(has_tahoe) %>% select(recall_pct = tahoe_recall) %>% mutate(Pipeline = "TAHOE"),
  df_recall %>% filter(has_cmap) %>% select(recall_pct = cmap_recall) %>% mutate(Pipeline = "CMAP")
)

precision_data <- bind_rows(
  df %>% filter(!is.na(tahoe_precision)) %>% select(precision_pct = tahoe_precision) %>% mutate(Pipeline = "TAHOE"),
  df %>% filter(!is.na(cmap_precision)) %>% select(precision_pct = cmap_precision) %>% mutate(Pipeline = "CMAP")
)

# Calculate statistics for annotations
tahoe_recall_mean <- mean(df_recall$tahoe_recall, na.rm=TRUE)
tahoe_recall_median <- median(df_recall$tahoe_recall, na.rm=TRUE)
cmap_recall_mean <- mean(df_recall$cmap_recall, na.rm=TRUE)
cmap_recall_median <- median(df_recall$cmap_recall, na.rm=TRUE)

tahoe_prec_mean <- mean(df$tahoe_precision, na.rm=TRUE)
tahoe_prec_median <- median(df$tahoe_precision, na.rm=TRUE)
cmap_prec_mean <- mean(df$cmap_precision, na.rm=TRUE)
cmap_prec_median <- median(df$cmap_precision, na.rm=TRUE)

cat("=== STATISTICS FOR ANNOTATIONS ===\n")
cat("TAHOE Recall:  Mean =", round(tahoe_recall_mean, 1), "% Median =", round(tahoe_recall_median, 1), "%\n")
cat("CMAP Recall:   Mean =", round(cmap_recall_mean, 1), "% Median =", round(cmap_recall_median, 1), "%\n")
cat("TAHOE Precision: Mean =", round(tahoe_prec_mean, 1), "% Median =", round(tahoe_prec_median, 1), "%\n")
cat("CMAP Precision:  Mean =", round(cmap_prec_mean, 1), "% Median =", round(cmap_prec_median, 1), "%\n")
cat("\nTAHOE Recall n =", sum(!is.na(df_recall$tahoe_recall)), "\n")
cat("CMAP Recall n =", sum(!is.na(df_recall$cmap_recall)), "\n")
cat("TAHOE Precision n =", sum(!is.na(df$tahoe_precision)), "\n")
cat("CMAP Precision n =", sum(!is.na(df$cmap_precision)), "\n")

# ============================================================
# FIGURE 3A: RECALL DISTRIBUTION DENSITY
# ============================================================
fig3a <- ggplot(recall_data, aes(x = recall_pct, fill = Pipeline, color = Pipeline)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  geom_vline(aes(xintercept = tahoe_recall_mean, color = "TAHOE"), linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = cmap_recall_mean, color = "CMAP"), linetype = "dashed", linewidth = 1) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  scale_color_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  labs(
    title = "A: Recall Distribution Density",
    x = "Recall (%)",
    y = "Density"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "inside",
    legend.position.inside = c(0.98, 0.97),
    legend.justification = c("right", "top"),
    legend.background = element_rect(fill = "white", color = "gray"),
    panel.grid.major = element_line(color = "#E0E0E0", linewidth = 0.3)
  ) +
  xlim(0, 105)

# ============================================================
# FIGURE 3B: PRECISION DISTRIBUTION DENSITY
# ============================================================
fig3b <- ggplot(precision_data, aes(x = precision_pct, fill = Pipeline, color = Pipeline)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  geom_vline(aes(xintercept = tahoe_prec_mean, color = "TAHOE"), linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = cmap_prec_mean, color = "CMAP"), linetype = "dashed", linewidth = 1) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  scale_color_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  annotate("text", x = 22.5, y = Inf, 
           label = paste0("CMAP: Mean=", round(cmap_prec_mean, 1), "%, Median=", round(cmap_prec_median, 1), "%\n",
                         "TAHOE: Mean=", round(tahoe_prec_mean, 1), "%, Median=", round(tahoe_prec_median, 1), "%"),
           fontface = "bold", size = 3.5, hjust = 0.5, vjust = 1.2) +
  labs(
    title = "B: Precision Distribution Density",
    x = "Precision (%)",
    y = "Density"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "none",
    panel.grid.major = element_line(color = "#E0E0E0", linewidth = 0.3)
  ) +
  xlim(0, 45)

# ============================================================
# FIGURE 3C: PRECISION VS RECALL SCATTER
# ============================================================
scatter_data <- df %>%
  select(disease_name, disease_id, tahoe_precision, tahoe_recall, cmap_precision, cmap_recall) %>%
  bind_rows(
    data.frame(
      disease_name = NA,
      disease_id = NA,
      tahoe_precision = NA,
      tahoe_recall = NA,
      cmap_precision = NA,
      cmap_recall = NA
    )
  ) %>%
  pivot_longer(
    cols = -c(disease_name, disease_id),
    names_to = c("Pipeline", "Metric"),
    names_sep = "_",
    values_to = "Value"
  ) %>%
  pivot_wider(
    names_from = Metric,
    values_from = Value
  ) %>%
  filter(!is.na(precision) | !is.na(recall))

fig3c <- ggplot(scatter_data, aes(x = precision, y = recall, color = Pipeline)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray", linewidth = 0.8, alpha = 0.5) +
  geom_vline(xintercept = 50, linetype = "dotted", color = "gray", linewidth = 0.5, alpha = 0.5) +
  geom_hline(yintercept = 50, linetype = "dotted", color = "gray", linewidth = 0.5, alpha = 0.5) +
  scale_color_manual(values = c("tahoe" = "#5DADE2", "cmap" = "#F39C12")) +
  labs(
    title = "C: Precision Vs Recall by Disease",
    subtitle = "(Each point = one disease)",
    x = "Precision (%)",
    y = "Recall (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 10, color = "gray50"),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "inside",
    legend.position.inside = c(0.98, 0.98),
    legend.justification = c("right", "top"),
    legend.background = element_rect(fill = "white", color = "gray"),
    panel.grid.major = element_line(color = "#E0E0E0", linewidth = 0.3)
  ) +
  xlim(0, 100) +
  ylim(0, 105)

# Combine figures
combined_figure <- gridExtra::grid.arrange(fig3a, fig3b, fig3c, ncol = 3, widths = c(1, 1, 1))

# Save
ggsave("figures/Figure_3_Raw_Data.pdf", combined_figure, width = 16, height = 5, dpi = 300)
ggsave("figures/Figure_3_Raw_Data.png", combined_figure, width = 16, height = 5, dpi = 300)

cat("\n✓ Figure 3 created and saved:\n")
cat("  - figures/Figure_3_Raw_Data.pdf\n")
cat("  - figures/Figure_3_Raw_Data.png\n")
