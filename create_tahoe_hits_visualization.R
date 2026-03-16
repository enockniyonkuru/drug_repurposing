# ============================================================================
# Drug Hits Visualization by Disease Signature - TAHOE v5
# ============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(tidyverse)
  library(RColorBrewer)
  library(gridExtra)
})

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("=======================================================\n")
cat("TAHOE v5 Drug Hits Analysis - All Disease Signatures\n")
cat("=======================================================\n\n")

# ============================================================================
# Load Results from all 6 disease signatures
# ============================================================================

disease_signatures <- list(
  Unstratified = "scripts/results/endo_v5_tahoe/endo_tahoe_Unstratified/endomentriosis_unstratified_disease_signature.csv_results.RData",
  `Stage I/II` = "scripts/results/endo_v5_tahoe/endo_tahoe_InII/endomentriosis_inii_disease_signature_results.RData",
  `Stage III/IV` = "scripts/results/endo_v5_tahoe/endo_tahoe_IIInIV/endomentriosis_iiiniv_disease_signature_results.RData",
  PE = "scripts/results/endo_v5_tahoe/endo_tahoe_PE/endomentriosis_pe_disease_signature_results.RData",
  ESE = "scripts/results/endo_v5_tahoe/endo_tahoe_ESE/endomentriosis_ese_disease_signature_results.RData",
  MSE = "scripts/results/endo_v5_tahoe/endo_tahoe_MSE/endomentriosis_mse_disease_signature_results.RData"
)

# Load experiments metadata for drug names
tahoe_experiments <- read.csv("scripts/data/drug_signatures/tahoe_drug_experiments_new.csv", stringsAsFactors = FALSE)

# ============================================================================
# Count Drug Hits with Different Thresholds
# ============================================================================

cat("Loading drug hits data...\n\n")

hit_summary <- data.frame(
  Signature = names(disease_signatures),
  Total_Experiments = 0,
  Q_0.05 = 0,
  Q_0.01 = 0,
  Q_0.001 = 0,
  Q_0.0001 = 0,
  CmapScore_neg = 0,
  CmapScore_neg_and_Q005 = 0,
  stringsAsFactors = FALSE
)

for (i in 1:length(disease_signatures)) {
  sig_name <- names(disease_signatures)[i]
  file_path <- disease_signatures[[i]]
  
  cat("Loading:", sig_name, "...\n")
  load(file_path)
  
  drug_results <- results$drugs
  
  # Count different thresholds
  total <- nrow(drug_results)
  q05 <- sum(drug_results$q < 0.05)
  q01 <- sum(drug_results$q < 0.01)
  q001 <- sum(drug_results$q < 0.001)
  q0001 <- sum(drug_results$q < 0.0001)
  neg_score <- sum(drug_results$cmap_score < 0)
  neg_and_q05 <- sum(drug_results$cmap_score < 0 & drug_results$q < 0.05)
  
  hit_summary[i, "Total_Experiments"] <- total
  hit_summary[i, "Q_0.05"] <- q05
  hit_summary[i, "Q_0.01"] <- q01
  hit_summary[i, "Q_0.001"] <- q001
  hit_summary[i, "Q_0.0001"] <- q0001
  hit_summary[i, "CmapScore_neg"] <- neg_score
  hit_summary[i, "CmapScore_neg_and_Q005"] <- neg_and_q05
  
  cat(sprintf("  Q < 0.05: %d hits | Q < 0.0001: %d hits | Neg score + Q < 0.05: %d hits\n",
              q05, q0001, neg_and_q05))
}

cat("\n")
print(hit_summary)

# ============================================================================
# Prepare Data for Visualization
# ============================================================================

# Create long format data for plotting
plot_data <- hit_summary %>%
  select(Signature, Q_0.05, Q_0.01, Q_0.001, Q_0.0001) %>%
  pivot_longer(cols = -Signature, names_to = "Threshold", values_to = "Hits")

plot_data$Threshold <- factor(plot_data$Threshold, 
                               levels = c("Q_0.05", "Q_0.01", "Q_0.001", "Q_0.0001"),
                               labels = c("q < 0.05", "q < 0.01", "q < 0.001", "q < 0.0001"))
plot_data$Signature <- factor(plot_data$Signature,
                              levels = c("Unstratified", "Stage I/II", "Stage III/IV", "PE", "ESE", "MSE"))

# ============================================================================
# Plot 1: Grouped Bar Chart by Threshold
# ============================================================================

cat("\nGenerating visualizations...\n")

p1 <- ggplot(plot_data, aes(x = Signature, y = Hits, fill = Threshold)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  geom_text(aes(label = Hits), 
            position = position_dodge(width = 0.7), 
            vjust = -0.3, size = 3) +
  scale_fill_brewer(palette = "Set1", direction = -1) +
  labs(title = "Drug Hits by Q-value Threshold",
       subtitle = "TAHOE v5 Drug Repurposing Results",
       x = "Disease Signature",
       y = "Number of Drug Hits",
       fill = "FDR Threshold") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.y = element_line(color = "gray90"),
    legend.position = "top"
  ) +
  ylim(0, max(plot_data$Hits) * 1.15)

ggsave("scripts/results/tahoe_v5_hits_by_threshold.pdf", p1, width = 10, height = 6)
ggsave("scripts/results/tahoe_v5_hits_by_threshold.jpg", p1, width = 10, height = 6, dpi = 300)

# ============================================================================
# Plot 2: Most Stringent Threshold (Q < 0.0001)
# ============================================================================

p2 <- ggplot(hit_summary, aes(x = reorder(Signature, -Q_0.0001), y = Q_0.0001, fill = Signature)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = Q_0.0001), vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Significant Drug Hits (q < 0.0001)",
       subtitle = "TAHOE v5 - Most Stringent Threshold",
       x = "Disease Signature",
       y = "Number of Drug Hits") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.y = element_line(color = "gray90"),
    legend.position = "none"
  ) +
  ylim(0, max(hit_summary$Q_0.0001) * 1.2)

ggsave("scripts/results/tahoe_v5_hits_q0001.pdf", p2, width = 8, height = 5)
ggsave("scripts/results/tahoe_v5_hits_q0001.jpg", p2, width = 8, height = 5, dpi = 300)

# ============================================================================
# Plot 3: Heatmap of All Thresholds
# ============================================================================

# Prepare data for heatmap
heatmap_data <- hit_summary %>%
  select(Signature, Q_0.05, Q_0.01, Q_0.001, Q_0.0001) %>%
  column_to_rownames("Signature") %>%
  as.matrix()

# Normalize for better visualization
heatmap_scaled <- t(apply(heatmap_data, 1, function(x) x / max(x)))

heatmap_df <- as.data.frame(heatmap_scaled) %>%
  rownames_to_column("Signature") %>%
  pivot_longer(-Signature, names_to = "Threshold", values_to = "Scaled_Hits")

heatmap_df$Threshold <- factor(heatmap_df$Threshold,
                               levels = c("Q_0.05", "Q_0.01", "Q_0.001", "Q_0.0001"),
                               labels = c("q < 0.05", "q < 0.01", "q < 0.001", "q < 0.0001"))
heatmap_df$Signature <- factor(heatmap_df$Signature,
                               levels = c("Unstratified", "Stage I/II", "Stage III/IV", "PE", "ESE", "MSE"))

# Add actual values as labels
actual_data <- hit_summary %>%
  select(Signature, Q_0.05, Q_0.01, Q_0.001, Q_0.0001) %>%
  pivot_longer(-Signature, names_to = "Threshold", values_to = "Hits")

actual_data$Threshold <- factor(actual_data$Threshold,
                                levels = c("Q_0.05", "Q_0.01", "Q_0.001", "Q_0.0001"),
                                labels = c("q < 0.05", "q < 0.01", "q < 0.001", "q < 0.0001"))

heatmap_df$Hits <- actual_data$Hits

p3 <- ggplot(heatmap_df, aes(x = Threshold, y = Signature, fill = Scaled_Hits)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = Hits), color = "black", fontface = "bold", size = 4) +
  scale_fill_gradient(low = "#E8F4F8", high = "#DC143C", name = "Relative\nIntensity") +
  labs(title = "Drug Hits Heatmap Across All Thresholds",
       subtitle = "TAHOE v5 Results",
       x = "FDR Threshold",
       y = "Disease Signature") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  )

ggsave("scripts/results/tahoe_v5_hits_heatmap.pdf", p3, width = 9, height = 5)
ggsave("scripts/results/tahoe_v5_hits_heatmap.jpg", p3, width = 9, height = 5, dpi = 300)

# ============================================================================
# Plot 4: Comparison Across All Thresholds (Line Plot)
# ============================================================================

p4 <- ggplot(plot_data, aes(x = Threshold, y = Hits, color = Signature, group = Signature)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = Hits), vjust = -0.7, size = 3) +
  scale_color_brewer(palette = "Set2") +
  labs(title = "Drug Hits Trend Across Threshold Stringency",
       subtitle = "TAHOE v5 Results",
       x = "FDR Threshold Stringency",
       y = "Number of Drug Hits",
       color = "Disease\nSignature") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    panel.grid.major = element_line(color = "gray90"),
    legend.position = "right"
  ) +
  ylim(0, max(plot_data$Hits) * 1.1)

ggsave("scripts/results/tahoe_v5_hits_trend.pdf", p4, width = 10, height = 6)
ggsave("scripts/results/tahoe_v5_hits_trend.jpg", p4, width = 10, height = 6, dpi = 300)

# ============================================================================
# Plot 5: Combined Faceted View
# ============================================================================

p5 <- ggplot(plot_data, aes(x = reorder(Signature, -Hits), y = Hits, fill = Threshold)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  scale_fill_brewer(palette = "RdYlGn", direction = -1) +
  facet_wrap(~Threshold, scales = "free_y", ncol = 2) +
  labs(title = "Drug Hits Distribution by Threshold",
       subtitle = "TAHOE v5 Results",
       x = "Disease Signature",
       y = "Number of Drug Hits") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold", size = 10),
    legend.position = "none"
  )

ggsave("scripts/results/tahoe_v5_hits_faceted.pdf", p5, width = 11, height = 8)
ggsave("scripts/results/tahoe_v5_hits_faceted.jpg", p5, width = 11, height = 8, dpi = 300)

# ============================================================================
# Summary Statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")
cat("Average drug hits per signature (q < 0.0001):", mean(hit_summary$Q_0.0001), "\n")
cat("Range:", min(hit_summary$Q_0.0001), "-", max(hit_summary$Q_0.0001), "\n")
cat("Total hits across all signatures (q < 0.0001):", sum(hit_summary$Q_0.0001), "\n")

cat("\n=======================================================\n")
cat("VISUALIZATION COMPLETE\n")
cat("=======================================================\n")
cat("\nOutput files saved in: scripts/results/\n")
cat("  ✓ tahoe_v5_hits_by_threshold.pdf/jpg\n")
cat("  ✓ tahoe_v5_hits_q0001.pdf/jpg\n")
cat("  ✓ tahoe_v5_hits_heatmap.pdf/jpg\n")
cat("  ✓ tahoe_v5_hits_trend.pdf/jpg\n")
cat("  ✓ tahoe_v5_hits_faceted.pdf/jpg\n")
cat("\nSummary table:\n")
print(hit_summary)
