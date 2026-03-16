#!/usr/bin/env Rscript
# Manuscript Figures for Drug Repurposing Analysis
# Exp8 Analysis with Q-threshold 0.05

library(readxl)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(tidyr)
library(reshape2)

# Set publication-quality theme
theme_manuscript <- function() {
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "right",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major = element_line(color = "gray90", size = 0.3),
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 10, face = "bold")
  )
}

# Read data
file_path <- "tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Output directory
output_dir <- "tahoe_cmap_analysis/figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ============================================================================
# FIGURE 1: TAHOE vs CMAP Pipeline Performance Comparison
# ============================================================================

fig1_data <- data.frame(
  Pipeline = c("TAHOE", "CMAP"),
  Mean = c(mean(df$tahoe_hits_count, na.rm = T), mean(df$cmap_hits_count, na.rm = T)),
  Median = c(median(df$tahoe_hits_count, na.rm = T), median(df$cmap_hits_count, na.rm = T)),
  Max = c(max(df$tahoe_hits_count, na.rm = T), max(df$cmap_hits_count, na.rm = T))
)

fig1_data_long <- melt(fig1_data, id.vars = "Pipeline", 
                        variable.name = "Statistic", value.name = "DrugHits")

fig1 <- ggplot(fig1_data_long, aes(x = Pipeline, y = DrugHits, fill = Statistic)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6, color = "black", size = 0.5) +
  scale_fill_manual(values = c("Mean" = "#2E86AB", "Median" = "#A23B72", "Max" = "#F18F01")) +
  labs(
    title = "Pipeline Performance Comparison",
    subtitle = "Distribution of drug candidate hits (n=234 diseases)",
    x = "Pipeline",
    y = "Number of Drug Hits",
    fill = "Statistic"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1300)) +
  geom_text(aes(label = round(DrugHits, 0)), position = position_dodge(width = 0.6), 
            vjust = -0.3, size = 3.5, fontface = "bold")

ggsave(file.path(output_dir, "Fig1_Pipeline_Comparison.pdf"), fig1, width = 8, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig1_Pipeline_Comparison.png"), fig1, width = 8, height = 5.5, dpi = 300)

cat("✓ Figure 1 saved: Pipeline Performance Comparison\n")

# ============================================================================
# FIGURE 2: Known Drugs Recovery - TAHOE vs CMAP
# ============================================================================

fig2_data <- data.frame(
  Pipeline = c("TAHOE", "CMAP"),
  Known_Drugs_Mean = c(mean(df$tahoe_in_known_count, na.rm = T), mean(df$cmap_in_known_count, na.rm = T)),
  Known_Drugs_Median = c(median(df$tahoe_in_known_count, na.rm = T), median(df$cmap_in_known_count, na.rm = T))
)

fig2_data_long <- melt(fig2_data, id.vars = "Pipeline",
                        variable.name = "Statistic", value.name = "KnownDrugs")
fig2_data_long$Statistic <- factor(fig2_data_long$Statistic, 
                                   levels = c("Known_Drugs_Mean", "Known_Drugs_Median"))

fig2 <- ggplot(fig2_data_long, aes(x = Pipeline, y = KnownDrugs, fill = Statistic)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6, color = "black", size = 0.5) +
  scale_fill_manual(values = c("Known_Drugs_Mean" = "#06A77D", "Known_Drugs_Median" = "#D62828"),
                    labels = c("Mean", "Median")) +
  labs(
    title = "Known Drug Candidate Recovery",
    subtitle = "Average and median hits among established drug candidates",
    x = "Pipeline",
    y = "Number of Known Drug Hits",
    fill = "Statistic"
  ) +
  theme_manuscript() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 5)) +
  geom_text(aes(label = round(KnownDrugs, 2)), position = position_dodge(width = 0.6),
            vjust = -0.3, size = 3.5, fontface = "bold")

ggsave(file.path(output_dir, "Fig2_Known_Drugs_Recovery.pdf"), fig2, width = 8, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig2_Known_Drugs_Recovery.png"), fig2, width = 8, height = 5.5, dpi = 300)

cat("✓ Figure 2 saved: Known Drug Recovery\n")

# ============================================================================
# FIGURE 3: Distribution of Drug Hits by Pipeline (Violin Plots)
# ============================================================================

df_plot <- data.frame(
  Pipeline = c(rep("TAHOE", nrow(df)), rep("CMAP", nrow(df))),
  DrugHits = c(df$tahoe_hits_count, df$cmap_hits_count)
)

fig3 <- ggplot(df_plot, aes(x = Pipeline, y = DrugHits, fill = Pipeline)) +
  geom_violin(alpha = 0.7, color = "black", size = 0.6) +
  geom_boxplot(width = 0.15, fill = "white", alpha = 0.8, color = "black", size = 0.5) +
  geom_jitter(width = 0.1, alpha = 0.2, size = 1) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12")) +
  labs(
    title = "Distribution of Drug Candidate Hits",
    subtitle = "Violin plots showing spread and quartiles across 234 diseases",
    x = "Pipeline",
    y = "Number of Drug Hits"
  ) +
  theme_manuscript() +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "Fig3_Hit_Distribution_Violin.pdf"), fig3, width = 8, height = 5.5, dpi = 300)
ggsave(file.path(output_dir, "Fig3_Hit_Distribution_Violin.png"), fig3, width = 8, height = 5.5, dpi = 300)

cat("✓ Figure 3 saved: Hit Distribution (Violin Plots)\n")

# ============================================================================
# FIGURE 4: Top 10 Diseases by Pipeline Consensus (Common Hits)
# ============================================================================

top_common <- df %>%
  select(disease_name, common_hits_count, tahoe_hits_count, cmap_hits_count, common_in_known_count) %>%
  arrange(desc(common_hits_count)) %>%
  head(10) %>%
  mutate(disease_name = factor(disease_name, levels = rev(disease_name)))

fig4 <- ggplot(top_common, aes(x = disease_name, y = common_hits_count, fill = common_in_known_count)) +
  geom_bar(stat = "identity", color = "black", size = 0.5) +
  scale_fill_gradient(low = "#FFF5E1", high = "#D62828", name = "Known Drugs") +
  coord_flip() +
  labs(
    title = "Top 10 Diseases by Pipeline Consensus",
    subtitle = "Common drug hits identified by both TAHOE and CMAP",
    x = "Disease",
    y = "Number of Common Hits"
  ) +
  theme_manuscript() +
  theme(axis.text.y = element_text(size = 9)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 60)) +
  geom_text(aes(label = round(common_hits_count, 0)), hjust = -0.2, size = 3, fontface = "bold")

ggsave(file.path(output_dir, "Fig4_Top_Consensus_Diseases.pdf"), fig4, width = 10, height = 6.5, dpi = 300)
ggsave(file.path(output_dir, "Fig4_Top_Consensus_Diseases.png"), fig4, width = 10, height = 6.5, dpi = 300)

cat("✓ Figure 4 saved: Top Consensus Diseases\n")

# ============================================================================
# FIGURE 5: Clinical Trial Phase Distribution
# ============================================================================

phase_cols <- c("phase_0.5", "phase_1.0", "phase_2.0", "phase_3.0", "phase_4.0")
phase_sums <- sapply(phase_cols, function(x) sum(df[[x]], na.rm = TRUE))

# Clean phase names
phase_labels <- c("Phase 0.5\n(Early Exploration)", 
                  "Phase 1\n(Safety)", 
                  "Phase 2\n(Efficacy)", 
                  "Phase 3\n(Confirmation)", 
                  "Phase 4\n(Post-market)")

fig5_data <- data.frame(
  Phase = factor(phase_labels, levels = phase_labels),
  Trials = as.numeric(phase_sums),
  Percentage = round(100 * as.numeric(phase_sums) / sum(phase_sums), 1)
)

fig5 <- ggplot(fig5_data, aes(x = Phase, y = Trials, fill = Phase)) +
  geom_bar(stat = "identity", color = "black", size = 0.6, alpha = 0.85) +
  scale_fill_manual(values = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd")) +
  labs(
    title = "Clinical Trial Phase Distribution",
    subtitle = "Aggregated across all drug candidates and diseases",
    x = "Trial Phase",
    y = "Number of Trials"
  ) +
  theme_manuscript() +
  theme(legend.position = "none", axis.text.x = element_text(size = 9)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1600)) +
  geom_text(aes(label = paste0(round(Trials, 0), "\n(", Percentage, "%)")), 
            vjust = -0.2, size = 3.2, fontface = "bold")

ggsave(file.path(output_dir, "Fig5_Clinical_Trial_Phases.pdf"), fig5, width = 9, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Fig5_Clinical_Trial_Phases.png"), fig5, width = 9, height = 6, dpi = 300)

cat("✓ Figure 5 saved: Clinical Trial Phase Distribution\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n")
cat("=" %|% rep("=", 70) %|% "\n")
cat("\n✅ ALL FIGURES GENERATED SUCCESSFULLY\n")
cat("\nFigures saved to:", output_dir, "\n\n")

cat("Generated Figures:\n")
cat("  1. Fig1_Pipeline_Comparison.pdf/png\n")
cat("     → Compares mean, median, and max drug hits between pipelines\n\n")
cat("  2. Fig2_Known_Drugs_Recovery.pdf/png\n")
cat("     → Known drug candidate recovery effectiveness\n\n")
cat("  3. Fig3_Hit_Distribution_Violin.pdf/png\n")
cat("     → Full distribution comparison across 234 diseases\n\n")
cat("  4. Fig4_Top_Consensus_Diseases.pdf/png\n")
cat("     → Top 10 diseases by both-pipeline agreement\n\n")
cat("  5. Fig5_Clinical_Trial_Phases.pdf/png\n")
cat("     → Development stage of identified candidates\n\n")

cat("All figures include both PDF (for publication) and PNG (for preview)\n")
cat("\n" %|% rep("=", 70) %|% "\n")
