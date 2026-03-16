# ============================================================================
# Drug Hits Visualization - Unique Drug Counts per Disease Signature
# TAHOE v5
# ============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(tidyverse)
  library(RColorBrewer)
})

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("=======================================================\n")
cat("TAHOE v5 Drug Hit Counts - Unique Drugs\n")
cat("=======================================================\n\n")

# ============================================================================
# Load and Count Unique Drugs from Hits Files
# ============================================================================

results_dir <- "scripts/results/endo_v5_tahoe"

signatures <- list(
  Unstratified = file.path(results_dir, "endo_tahoe_Unstratified", 
                          "endomentriosis_unstratified_disease_signature.csv_hits_logFC_1.1_q<0.00.csv"),
  `Stage I/II` = file.path(results_dir, "endo_tahoe_InII", 
                          "endomentriosis_inii_disease_signature_hits_logFC_1.1_q<0.00.csv"),
  `Stage III/IV` = file.path(results_dir, "endo_tahoe_IIInIV", 
                            "endomentriosis_iiiniv_disease_signature_hits_logFC_1.1_q<0.00.csv"),
  PE = file.path(results_dir, "endo_tahoe_PE", 
               "endomentriosis_pe_disease_signature_hits_logFC_1.1_q<0.00.csv"),
  ESE = file.path(results_dir, "endo_tahoe_ESE", 
              "endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv"),
  MSE = file.path(results_dir, "endo_tahoe_MSE", 
              "endomentriosis_mse_disease_signature_hits_logFC_1.1_q<0.00.csv")
)

cat("Counting unique drugs per signature:\n\n")

drug_counts_list <- list()
unique_drugs_list <- list()

for (i in 1:length(signatures)) {
  sig_name <- names(signatures)[i]
  file_path <- signatures[[i]]
  
  if (file.exists(file_path)) {
    hits_data <- read.csv(file_path, stringsAsFactors = FALSE)
    unique_drugs <- unique(hits_data$name)
    drug_count <- length(unique_drugs)
    
    drug_counts_list[[sig_name]] <- drug_count
    unique_drugs_list[[sig_name]] <- unique_drugs
    
    cat(sprintf("%-15s: %3d unique drugs\n", sig_name, drug_count))
  } else {
    cat(sprintf("%-15s: FILE NOT FOUND\n", sig_name))
    drug_counts_list[[sig_name]] <- 0
    unique_drugs_list[[sig_name]] <- c()
  }
}

drug_counts <- data.frame(
  Signature = names(drug_counts_list),
  Drug_Count = unlist(drug_counts_list),
  stringsAsFactors = FALSE
)

cat("\n")
print(drug_counts[, c("Signature", "Drug_Count")])

# ============================================================================
# Plot 1: Simple Bar Chart
# ============================================================================

cat("\nGenerating visualizations...\n")

p1 <- ggplot(drug_counts, aes(x = reorder(Signature, -Drug_Count), y = Drug_Count, fill = Signature)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = Drug_Count), vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Drug Hits by Disease Signature",
       subtitle = "TAHOE v5 - Unique Drug Candidates",
       x = "Disease Signature",
       y = "Number of Drug Hits") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
    legend.position = "none"
  ) +
  ylim(0, max(drug_counts$Drug_Count) * 1.2)

ggsave("scripts/results/tahoe_v5_drug_hits_bar.pdf", p1, width = 9, height = 6)
ggsave("scripts/results/tahoe_v5_drug_hits_bar.jpg", p1, width = 9, height = 6, dpi = 300)

# ============================================================================
# Plot 2: Horizontal Bar Chart (easier to read drug counts)
# ============================================================================

p2 <- ggplot(drug_counts, aes(x = Drug_Count, y = reorder(Signature, Drug_Count), fill = Signature)) +
  geom_bar(stat = "identity", height = 0.6) +
  geom_text(aes(label = Drug_Count), hjust = -0.3, size = 5, fontface = "bold") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Drug Hit Counts",
       subtitle = "TAHOE v5 - Ranked by Hit Count",
       x = "Number of Drug Hits",
       y = "Disease Signature") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    panel.grid.major.x = element_line(color = "gray90", linewidth = 0.3),
    legend.position = "none"
  ) +
  xlim(0, max(drug_counts$Drug_Count) * 1.15)

ggsave("scripts/results/tahoe_v5_drug_hits_horizontal.pdf", p2, width = 9, height = 6)
ggsave("scripts/results/tahoe_v5_drug_hits_horizontal.jpg", p2, width = 9, height = 6, dpi = 300)

# ============================================================================
# Plot 3: Donut Chart
# ============================================================================

p3 <- ggplot(drug_counts, aes(x = "", y = Drug_Count, fill = Signature)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  geom_text(aes(label = paste0(Signature, "\n(", Drug_Count, ")")), 
            position = position_stack(vjust = 0.5), 
            size = 4, fontface = "bold") +
  scale_fill_brewer(palette = "Set2") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12, margin = margin(b = 10)),
    legend.position = "none"
  ) +
  ggtitle("Distribution of Drug Hits",
          subtitle = "TAHOE v5 - All Disease Signatures")

ggsave("scripts/results/tahoe_v5_drug_hits_donut.pdf", p3, width = 8, height = 8)
ggsave("scripts/results/tahoe_v5_drug_hits_donut.jpg", p3, width = 8, height = 8, dpi = 300)

# ============================================================================
# Plot 4: Lollipop Chart
# ============================================================================

p4 <- ggplot(drug_counts, aes(x = reorder(Signature, Drug_Count), y = Drug_Count)) +
  geom_segment(aes(xend = reorder(Signature, Drug_Count), yend = 0), color = "gray60", linewidth = 1.2) +
  geom_point(aes(color = Signature), size = 8) +
  geom_text(aes(label = Drug_Count), vjust = -1, size = 5, fontface = "bold") +
  scale_color_brewer(palette = "Set2") +
  labs(title = "Drug Hits Lollipop Chart",
       subtitle = "TAHOE v5 - Unique Drug Candidates",
       x = "Disease Signature",
       y = "Number of Drug Hits") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    panel.grid.major.y = element_line(color = "gray90"),
    legend.position = "none"
  ) +
  ylim(0, max(drug_counts$Drug_Count) * 1.2)

ggsave("scripts/results/tahoe_v5_drug_hits_lollipop.pdf", p4, width = 9, height = 6)
ggsave("scripts/results/tahoe_v5_drug_hits_lollipop.jpg", p4, width = 9, height = 6, dpi = 300)

# ============================================================================
# Plot 5: Comparison with Total Experiments
# ============================================================================

# Also get total experiments count (all have same 56827)
drug_counts$Total_Experiments <- 56827

comparison_data <- drug_counts %>%
  select(Signature, Drug_Count) %>%
  mutate(
    Experiments_per_Drug = 56827 / Drug_Count,
    Signature = factor(Signature, levels = Signature)
  )

p5 <- ggplot(drug_counts, aes(x = reorder(Signature, -Drug_Count), y = Drug_Count)) +
  geom_col(aes(fill = Drug_Count), width = 0.6) +
  scale_fill_gradient(low = "#3498db", high = "#e74c3c", name = "Drug Hits") +
  geom_text(aes(label = Drug_Count), vjust = -0.5, size = 5, fontface = "bold") +
  geom_text(aes(label = paste0("(", round(56827/Drug_Count, 0), " exp/drug)")), 
            vjust = -1.5, size = 3, color = "gray40") +
  labs(title = "Drug Hit Counts with Experiment-to-Drug Ratio",
       subtitle = "TAHOE v5 Results",
       x = "Disease Signature",
       y = "Number of Drug Hits") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.y = element_line(color = "gray90"),
    legend.position = "right"
  ) +
  ylim(0, max(drug_counts$Drug_Count) * 1.25)

ggsave("scripts/results/tahoe_v5_drug_hits_with_ratio.pdf", p5, width = 10, height = 6)
ggsave("scripts/results/tahoe_v5_drug_hits_with_ratio.jpg", p5, width = 10, height = 6, dpi = 300)

# ============================================================================
# Summary and Statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")
cat("Total unique drugs across all signatures:", sum(unique(unlist(drug_counts$Unique_Drugs))), "\n")
cat("Average hits per signature:", round(mean(drug_counts$Drug_Count), 1), "\n")
cat("Median hits per signature:", median(drug_counts$Drug_Count), "\n")
cat("Range:", min(drug_counts$Drug_Count), "-", max(drug_counts$Drug_Count), "\n")
cat("Total experiments:", 56827, "\n")

cat("\n=== Drug Hits Summary ===\n")
for (i in 1:nrow(drug_counts)) {
  exp_per_drug <- round(56827 / drug_counts[i, "Drug_Count"])
  cat(sprintf("%-15s: %3d drugs (%d experiments per drug)\n", 
              drug_counts[i, "Signature"], 
              drug_counts[i, "Drug_Count"],
              exp_per_drug))
}

cat("\n=======================================================\n")
cat("VISUALIZATION COMPLETE\n")
cat("=======================================================\n")
cat("\nOutput files saved in: scripts/results/\n")
cat("  ✓ tahoe_v5_drug_hits_bar.pdf/jpg\n")
cat("  ✓ tahoe_v5_drug_hits_horizontal.pdf/jpg\n")
cat("  ✓ tahoe_v5_drug_hits_donut.pdf/jpg\n")
cat("  ✓ tahoe_v5_drug_hits_lollipop.pdf/jpg\n")
cat("  ✓ tahoe_v5_drug_hits_with_ratio.pdf/jpg\n")
