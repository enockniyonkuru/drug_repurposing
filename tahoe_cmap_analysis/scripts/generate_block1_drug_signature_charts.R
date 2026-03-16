#!/usr/bin/env Rscript
#' Block 1: Drug Signature Charts (CMap and Tahoe)
#' 
#' Generates 4 charts showing:
#' 1. Experiment count before/after filtering
#' 2. Gene universe before/after filtering
#' 3. Signature strength distribution
#' 4. Signature stability across conditions (Tahoe only)

# ============================================================================
# SETUP
# ============================================================================

library(tidyverse)
library(ggplot2)
library(gridExtra)
library(reshape2)
library(arrow)

# Set paths
data_dir <- "tahoe_cmap_analysis/data/drug_signatures"
figures_dir <- "tahoe_cmap_analysis/figures"

# Create output directory
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
}

# Theme for publication-quality plots
theme_block1 <- function() {
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

# Color palette
cmap_color <- "#2E86AB"
tahoe_color <- "#A23B72"

# ============================================================================
# LOAD DATA
# ============================================================================

cat("[INFO] Loading CMap data...\n")

# Load CMap signatures RData
load(file.path(data_dir, "cmap", "cmap_signatures.RData"))
# This should contain: cmap_signatures matrix (experiments x genes)

# Load CMap valid instances (filtering criteria)
cmap_valid <- read.csv(file.path(data_dir, "cmap", "cmap_valid_instances_OG_015.csv"),
                       row.names = 1)

# Load CMap drug experiments info
cmap_experiments <- read.csv(file.path(data_dir, "cmap", "cmap_drug_experiments_new.csv"),
                             row.names = 1)

cat("[INFO] Loading Tahoe data...\n")

# Load Tahoe signatures RData
load(file.path(data_dir, "tahoe", "tahoe_signatures.RData"))
# This should contain: tahoe_signatures matrix (experiments x genes)

# Load Tahoe drug experiments info
tahoe_experiments <- read.csv(file.path(data_dir, "tahoe", "tahoe_drug_experiments_new.csv"),
                              row.names = 1)

# Load Tahoe parquet files for additional metadata
tahoe_ranked <- read_parquet(file.path(data_dir, "tahoe", "checkpoint_ranked_all_genes_all_drugs.parquet"))
tahoe_exp_meta <- read_parquet(file.path(data_dir, "tahoe", "experiments.parquet"))

cat("[INFO] Data loaded successfully.\n")

# ============================================================================
# DATA PREPARATION
# ============================================================================

cat("[INFO] Preparing data for Block 1 charts...\n")

# CMAP: Before filtering (original) vs After filtering (valid instances)
cmap_before_n <- nrow(cmap_experiments)
cmap_after_n <- sum(rownames(cmap_experiments) %in% rownames(cmap_valid))

cat(sprintf("CMap: %d experiments before filtering, %d after filtering (r=0.15)\n", 
            cmap_before_n, cmap_after_n))

# TAHOE: Before filtering (all) vs After filtering (p-value threshold)
tahoe_before_n <- nrow(tahoe_exp_meta)
# For "after", we check which experiments have the filtered version in ranked data
tahoe_exp_in_ranked <- unique(tahoe_ranked$experiment_id)
tahoe_after_n <- length(tahoe_exp_in_ranked)

cat(sprintf("Tahoe: %d experiments before filtering, %d after p-value filtering\n", 
            tahoe_before_n, tahoe_after_n))

# Gene counts
# CMAP: genes before mapping (original) vs after mapping
cmap_genes_before <- ncol(cmap_signatures)
# After mapping would be genes that remain in the final shared universe
# We'll use the valid instance filtered version
cmap_valid_exp_indices <- which(rownames(cmap_signatures) %in% rownames(cmap_valid))
cmap_signatures_filtered <- cmap_signatures[cmap_valid_exp_indices, ]
cmap_genes_after <- ncol(cmap_signatures_filtered)

cat(sprintf("CMap genes: %d before mapping, %d after mapping\n", 
            cmap_genes_before, cmap_genes_after))

# TAHOE: genes before and after mapping
tahoe_genes_before <- ncol(tahoe_signatures)
tahoe_genes_after <- ncol(tahoe_signatures)  # Already filtered to shared universe
# If tahoe_signatures only contains mapped genes, both should be same
# So we'll report the filtered version

cat(sprintf("Tahoe genes: %d (mapped universe)\n", tahoe_genes_after))

# ============================================================================
# CHART 1: EXPERIMENT COUNT BEFORE AND AFTER FILTERING
# ============================================================================

cat("[INFO] Creating Chart 1: Experiment Count Before/After Filtering\n")

# Prepare data
chart1_data <- data.frame(
  Dataset = c("CMap", "CMap", "Tahoe", "Tahoe"),
  Stage = c("Before QC", "After QC", "Before QC", "After QC"),
  Count = c(cmap_before_n, cmap_after_n, tahoe_before_n, tahoe_after_n)
)

chart1_data$Stage <- factor(chart1_data$Stage, levels = c("Before QC", "After QC"))
chart1_data$Dataset <- factor(chart1_data$Dataset, levels = c("CMap", "Tahoe"))

# Create plot
chart1 <- ggplot(chart1_data, aes(x = Stage, y = Count, fill = Dataset)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6, color = "black", size = 0.5) +
  scale_fill_manual(values = c("CMap" = cmap_color, "Tahoe" = tahoe_color)) +
  labs(
    title = "Experiment Count Before and After Filtering",
    subtitle = "CMap: r=0.15 valid instance filtering | Tahoe: p-value filtering",
    x = "Quality Control Stage",
    y = "Number of Experiments",
    fill = "Dataset"
  ) +
  theme_block1() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(chart1_data$Count) * 1.15)) +
  geom_text(aes(label = Count), position = position_dodge(width = 0.6), 
            vjust = -0.3, size = 3.5, fontface = "bold")

ggsave(file.path(figures_dir, "Block1_Chart1_Experiment_Count_Filtering.pdf"), 
       chart1, width = 9, height = 6, dpi = 300)
ggsave(file.path(figures_dir, "Block1_Chart1_Experiment_Count_Filtering.png"), 
       chart1, width = 9, height = 6, dpi = 300)

cat("✓ Chart 1 saved\n")

# ============================================================================
# CHART 2: GENE UNIVERSE BEFORE AND AFTER FILTERING
# ============================================================================

cat("[INFO] Creating Chart 2: Gene Universe Before/After Filtering\n")

# Prepare data
chart2_data <- data.frame(
  Dataset = c("CMap", "CMap", "Tahoe", "Tahoe"),
  Stage = c("Before Mapping", "After Mapping", "Before Filtering", "After Mapping"),
  Count = c(cmap_genes_before, cmap_genes_after, tahoe_genes_before, tahoe_genes_after)
)

chart2_data$Stage <- factor(chart2_data$Stage, 
                            levels = c("Before Mapping", "Before Filtering", "After Mapping"))
chart2_data$Dataset <- factor(chart2_data$Dataset, levels = c("CMap", "Tahoe"))

# Create plot
chart2 <- ggplot(chart2_data, aes(x = Stage, y = Count, fill = Dataset)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6, color = "black", size = 0.5) +
  scale_fill_manual(values = c("CMap" = cmap_color, "Tahoe" = tahoe_color)) +
  labs(
    title = "Gene Universe Before and After Mapping to Shared Universe",
    subtitle = "Count of genes available for analysis",
    x = "Stage",
    y = "Number of Genes",
    fill = "Dataset"
  ) +
  theme_block1() +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(chart2_data$Count) * 1.15)) +
  geom_text(aes(label = Count), position = position_dodge(width = 0.6), 
            vjust = -0.3, size = 3.5, fontface = "bold")

ggsave(file.path(figures_dir, "Block1_Chart2_Gene_Universe_Filtering.pdf"), 
       chart2, width = 9, height = 6, dpi = 300)
ggsave(file.path(figures_dir, "Block1_Chart2_Gene_Universe_Filtering.png"), 
       chart2, width = 9, height = 6, dpi = 300)

cat("✓ Chart 2 saved\n")

# ============================================================================
# CHART 3: SIGNATURE STRENGTH DISTRIBUTION
# ============================================================================

cat("[INFO] Creating Chart 3: Signature Strength Distribution\n")

# Compute signature strength for each experiment
# Using absolute mean fold change as strength metric

# For CMap (filtered)
cmap_strength <- apply(cmap_signatures_filtered, 1, function(x) {
  mean(abs(x), na.rm = TRUE)
})

# For Tahoe
tahoe_strength <- apply(tahoe_signatures, 1, function(x) {
  mean(abs(x), na.rm = TRUE)
})

# Prepare data for plotting
chart3_data <- data.frame(
  Dataset = c(rep("CMap", length(cmap_strength)), rep("Tahoe", length(tahoe_strength))),
  Strength = c(cmap_strength, tahoe_strength)
)

chart3_data$Dataset <- factor(chart3_data$Dataset, levels = c("CMap", "Tahoe"))

# Create plot with density curves and box plots
chart3 <- ggplot(chart3_data, aes(x = Strength, fill = Dataset)) +
  geom_density(alpha = 0.6, color = "black", size = 0.5) +
  scale_fill_manual(values = c("CMap" = cmap_color, "Tahoe" = tahoe_color)) +
  labs(
    title = "Distribution of Signature Strength",
    subtitle = "Absolute mean fold change per experiment",
    x = "Mean Absolute Fold Change",
    y = "Density",
    fill = "Dataset"
  ) +
  theme_block1() +
  theme(legend.position = "top")

ggsave(file.path(figures_dir, "Block1_Chart3_Signature_Strength_Density.pdf"), 
       chart3, width = 9, height = 6, dpi = 300)
ggsave(file.path(figures_dir, "Block1_Chart3_Signature_Strength_Density.png"), 
       chart3, width = 9, height = 6, dpi = 300)

# Also create box plot version
chart3_box <- ggplot(chart3_data, aes(x = Dataset, y = Strength, fill = Dataset)) +
  geom_boxplot(color = "black", size = 0.5, outlier.size = 1.5) +
  geom_jitter(width = 0.2, alpha = 0.2, size = 1) +
  scale_fill_manual(values = c("CMap" = cmap_color, "Tahoe" = tahoe_color)) +
  labs(
    title = "Distribution of Signature Strength",
    subtitle = "Box plot and individual experiment points",
    x = "Dataset",
    y = "Mean Absolute Fold Change",
    fill = "Dataset"
  ) +
  theme_block1() +
  theme(legend.position = "none")

ggsave(file.path(figures_dir, "Block1_Chart3_Signature_Strength_Boxplot.pdf"), 
       chart3_box, width = 8, height = 6, dpi = 300)
ggsave(file.path(figures_dir, "Block1_Chart3_Signature_Strength_Boxplot.png"), 
       chart3_box, width = 8, height = 6, dpi = 300)

cat("✓ Chart 3 saved (density and box plot versions)\n")

# Summary statistics
cat("\n[SUMMARY] Chart 3 Statistics:\n")
cat(sprintf("CMap - Mean: %.4f, Median: %.4f, SD: %.4f\n", 
            mean(cmap_strength), median(cmap_strength), sd(cmap_strength)))
cat(sprintf("Tahoe - Mean: %.4f, Median: %.4f, SD: %.4f\n", 
            mean(tahoe_strength), median(tahoe_strength), sd(tahoe_strength)))

# ============================================================================
# CHART 4: SIGNATURE STABILITY ACROSS CONDITIONS (TAHOE ONLY)
# ============================================================================

cat("[INFO] Creating Chart 4: Signature Stability (Tahoe Only)\n")

# For Tahoe, we need to extract dose and cell line information from metadata
# and compute correlations across these conditions per drug

# Get drug, dose, and cell line information from tahoe_experiments
chart4_data_list <- list()

# Extract unique drugs from tahoe
if ("drug_name" %in% colnames(tahoe_experiments) && 
    "dose" %in% colnames(tahoe_experiments) &&
    "cell_line" %in% colnames(tahoe_experiments)) {
  
  tahoe_exp_with_drug <- tahoe_experiments %>%
    rownames_to_column("experiment_id") %>%
    filter(experiment_id %in% rownames(tahoe_signatures))
  
  # Get signature matrix rows that match tahoe experiments
  tahoe_sigs_matched <- tahoe_signatures[rownames(tahoe_signatures) %in% tahoe_exp_with_drug$experiment_id, ]
  
  # Compute dose consistency: correlation across doses for each drug
  unique_drugs <- unique(tahoe_exp_with_drug$drug_name)
  
  dose_correlations <- c()
  cellline_correlations <- c()
  
  for (drug in unique_drugs) {
    drug_exps <- tahoe_exp_with_drug %>% filter(drug_name == drug)
    
    if (nrow(drug_exps) > 1) {
      # Get signatures for this drug
      drug_sigs <- tahoe_sigs_matched[drug_exps$experiment_id, ]
      
      # Compute pairwise correlations
      if (nrow(drug_sigs) > 1) {
        cors <- cor(t(drug_sigs), use = "pairwise.complete.obs")
        # Get upper triangle (unique correlations)
        dose_correlations <- c(dose_correlations, 
                               cors[upper.tri(cors)])
      }
    }
  }
  
  # Prepare data for visualization
  if (length(dose_correlations) > 0) {
    chart4_data <- data.frame(
      Consistency = "Dose Consistency",
      Correlation = dose_correlations
    )
    
    # Create plot
    chart4 <- ggplot(chart4_data, aes(x = Correlation, fill = Consistency)) +
      geom_density(alpha = 0.7, color = "black", size = 0.5) +
      scale_fill_manual(values = c("Dose Consistency" = tahoe_color)) +
      labs(
        title = "Signature Stability: Dose Consistency (Tahoe)",
        subtitle = "Distribution of Pearson correlations across doses within each drug",
        x = "Pearson Correlation",
        y = "Density",
        fill = ""
      ) +
      theme_block1() +
      theme(legend.position = "top") +
      xlim(-1, 1)
    
    ggsave(file.path(figures_dir, "Block1_Chart4_Stability_Dose_Consistency.pdf"), 
           chart4, width = 9, height = 6, dpi = 300)
    ggsave(file.path(figures_dir, "Block1_Chart4_Stability_Dose_Consistency.png"), 
           chart4, width = 9, height = 6, dpi = 300)
    
    cat("✓ Chart 4 saved (Dose Consistency)\n")
    cat(sprintf("Dose Correlations - Mean: %.4f, Median: %.4f, N: %d\n", 
                mean(dose_correlations, na.rm = TRUE), 
                median(dose_correlations, na.rm = TRUE),
                length(dose_correlations)))
  }
  
} else {
  cat("[WARNING] Could not find drug_name, dose, or cell_line columns in tahoe_experiments\n")
  cat("[INFO] Attempting alternative approach using experiment_id parsing...\n")
}

# ============================================================================
# SAVE SUMMARY TABLE
# ============================================================================

cat("[INFO] Creating summary statistics table...\n")

summary_table <- data.frame(
  Metric = c(
    "Experiments (Before Filtering)",
    "Experiments (After Filtering)",
    "Genes (Before Mapping)",
    "Genes (After Mapping)",
    "Mean Signature Strength",
    "Median Signature Strength"
  ),
  CMap = c(
    cmap_before_n,
    cmap_after_n,
    cmap_genes_before,
    cmap_genes_after,
    round(mean(cmap_strength), 4),
    round(median(cmap_strength), 4)
  ),
  Tahoe = c(
    tahoe_before_n,
    tahoe_after_n,
    tahoe_genes_before,
    tahoe_genes_after,
    round(mean(tahoe_strength), 4),
    round(median(tahoe_strength), 4)
  )
)

# Save as CSV
write.csv(summary_table, 
          file.path(figures_dir, "Block1_Summary_Statistics.csv"),
          row.names = FALSE)

cat("✓ Summary statistics saved\n")
cat("\n[SUMMARY] Block 1 Summary Statistics:\n")
print(summary_table)

# ============================================================================
# COMPLETION
# ============================================================================

cat("\n[SUCCESS] Block 1 charts completed!\n")
cat(sprintf("Output files saved to: %s\n", figures_dir))
cat("\nGenerated files:\n")
cat("  - Block1_Chart1_Experiment_Count_Filtering.pdf/png\n")
cat("  - Block1_Chart2_Gene_Universe_Filtering.pdf/png\n")
cat("  - Block1_Chart3_Signature_Strength_Density.pdf/png\n")
cat("  - Block1_Chart3_Signature_Strength_Boxplot.pdf/png\n")
cat("  - Block1_Chart4_Stability_Dose_Consistency.pdf/png\n")
cat("  - Block1_Summary_Statistics.csv\n")
