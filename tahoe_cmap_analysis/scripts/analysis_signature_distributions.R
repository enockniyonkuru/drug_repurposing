#!/usr/bin/env Rscript
#
# Analyze Disease Signature Distributions
# Helps determine optimal percentile threshold for gene filtering
#

library(dplyr)
library(tidyr)
library(ggplot2)

# Configuration
DISEASE_DIR <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/endo_disease_sigatures_standardized"
OUTPUT_DIR <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/reports"

# Create output directory if needed
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Get all disease signature files
disease_files <- list.files(DISEASE_DIR, pattern = "_signature\\.csv$", full.names = TRUE)
disease_names <- gsub("_signature\\.csv$", "", basename(disease_files))

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("DISEASE SIGNATURE DISTRIBUTION ANALYSIS\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("Found", length(disease_files), "disease signatures\n\n")

# Initialize results storage
all_stats <- data.frame()

# Analyze each disease
for (i in seq_along(disease_files)) {
  file <- disease_files[i]
  name <- disease_names[i]
  
  # Read the signature
  df <- tryCatch(
    read.csv(file, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) {
      cat("ERROR reading", name, ":", e$message, "\n")
      return(NULL)
    }
  )
  
  if (is.null(df) || nrow(df) == 0) {
    cat("SKIP:", name, "(empty or unreadable)\n")
    next
  }
  
  # Find the gene name column (usually "SYMBOL", "gene", "Gene", etc.)
  gene_cols <- grep("^(SYMBOL|gene|Gene|GENE|GeneID|GeneSymbol)", colnames(df), 
                     ignore.case = TRUE, value = TRUE)
  
  # Find logFC columns (logfc, log2fc, logFC, etc.)
  logfc_cols <- grep("logfc|log2fc|fc|effect", colnames(df), 
                      ignore.case = TRUE, value = TRUE)
  logfc_cols <- setdiff(logfc_cols, gene_cols)  # Exclude gene columns
  
  if (length(logfc_cols) == 0) {
    cat("SKIP:", name, "(no logFC columns found)\n")
    next
  }
  
  # Get the first logFC column or average across multiple
  if (length(logfc_cols) == 1) {
    logfc <- abs(df[[logfc_cols[1]]])
  } else {
    logfc <- rowMeans(abs(df[, logfc_cols, drop = FALSE]), na.rm = TRUE)
  }
  
  # Calculate statistics
  n_genes <- length(logfc)
  mean_logfc <- mean(logfc, na.rm = TRUE)
  median_logfc <- median(logfc, na.rm = TRUE)
  sd_logfc <- sd(logfc, na.rm = TRUE)
  min_logfc <- min(logfc, na.rm = TRUE)
  max_logfc <- max(logfc, na.rm = TRUE)
  q25_logfc <- quantile(logfc, 0.25, na.rm = TRUE)
  q75_logfc <- quantile(logfc, 0.75, na.rm = TRUE)
  
  # Calculate what different percentile thresholds would keep
  percentiles <- c(50, 60, 70, 75, 80, 90, 95)
  kept_genes <- sapply(percentiles, function(p) {
    thresh <- quantile(logfc, probs = p/100, na.rm = TRUE)
    sum(logfc >= thresh, na.rm = TRUE)
  })
  
  stats_row <- data.frame(
    Disease = name,
    N_Genes = n_genes,
    Mean_LogFC = round(mean_logfc, 4),
    Median_LogFC = round(median_logfc, 4),
    SD_LogFC = round(sd_logfc, 4),
    Min_LogFC = round(min_logfc, 4),
    Max_LogFC = round(max_logfc, 4),
    Q25_LogFC = round(q25_logfc, 4),
    Q75_LogFC = round(q75_logfc, 4),
    stringsAsFactors = FALSE
  )
  
  # Add percentile columns
  for (j in seq_along(percentiles)) {
    col_name <- paste0("Keep_", percentiles[j], "pct")
    stats_row[[col_name]] <- kept_genes[j]
  }
  
  all_stats <- rbind(all_stats, stats_row)
  
  cat("[", i, "/", length(disease_files), "] PROCESSED: ", name, "\n", sep = "")
  cat("    Total genes: ", n_genes, "\n", sep = "")
  cat("    Mean logFC: ", round(mean_logfc, 4), " (Median: ", round(median_logfc, 4), ")\n", sep = "")
  cat("    Range: [", round(min_logfc, 4), ", ", round(max_logfc, 4), "]\n", sep = "")
  cat("    At 75th percentile: keep ", 
      round(100 * kept_genes[4] / n_genes, 1), "% of genes (", 
      kept_genes[4], " genes)\n", sep = "")
  cat("\n")
}

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("SUMMARY STATISTICS\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

print(all_stats)

# Summary statistics
cat("\n\nAVERAGE GENE COUNTS ACROSS ALL DISEASES:\n")
cat("  Total genes: ", round(mean(all_stats$N_Genes), 1), 
    " (range: ", min(all_stats$N_Genes), "-", max(all_stats$N_Genes), ")\n", sep = "")
cat("  Mean logFC: ", round(mean(all_stats$Mean_LogFC), 4), "\n", sep = "")
cat("  Median logFC: ", round(mean(all_stats$Median_LogFC), 4), "\n\n", sep = "")

# Percentile analysis
cat("GENES RETAINED AT DIFFERENT PERCENTILE THRESHOLDS:\n")
for (p in c(50, 60, 70, 75, 80, 90, 95)) {
  col <- paste0("Keep_", p, "pct")
  kept <- all_stats[[col]]
  cat("  ", p, "th percentile: mean ", round(mean(kept), 1), " genes per disease (range: ", 
      min(kept), "-", max(kept), ")\n", sep = "")
}

# Save detailed results
output_file <- file.path(OUTPUT_DIR, "disease_signature_analysis.csv")
write.csv(all_stats, output_file, row.names = FALSE)
cat("\n\nDetailed results saved to:", output_file, "\n")

# Create visualization
pdf(file.path(OUTPUT_DIR, "disease_signature_distributions.pdf"), width = 14, height = 10)

# Plot 1: Gene count by disease
p1 <- ggplot(all_stats, aes(x = reorder(Disease, N_Genes), y = N_Genes)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Gene Counts Per Disease Signature",
       x = "Disease", y = "Number of Genes") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Plot 2: LogFC statistics
p2 <- ggplot(all_stats, aes(x = reorder(Disease, Median_LogFC), y = Median_LogFC)) +
  geom_point(aes(color = "Median"), size = 3) +
  geom_point(aes(y = Mean_LogFC, color = "Mean"), size = 3) +
  coord_flip() +
  labs(title = "LogFC Statistics Per Disease",
       x = "Disease", y = "LogFC") +
  theme_minimal() +
  scale_color_manual(values = c("Median" = "darkred", "Mean" = "steelblue"))

# Plot 3: Percentile comparison
percentile_cols <- paste0("Keep_", c(50, 60, 70, 75, 80, 90, 95), "pct")
pct_data <- all_stats[, c("Disease", percentile_cols)] %>%
  pivot_longer(cols = percentile_cols, names_to = "Percentile", values_to = "Genes_Kept") %>%
  mutate(Percentile = as.numeric(gsub("Keep_|pct", "", Percentile)))

p3 <- ggplot(pct_data, aes(x = Percentile, y = Genes_Kept, color = Disease, group = Disease)) +
  geom_line() +
  geom_point() +
  labs(title = "Gene Retention at Different Percentile Thresholds",
       x = "Percentile Threshold", y = "Genes Retained") +
  theme_minimal() +
  theme(legend.position = "right", legend.text = element_text(size = 8))

# Print plots
print(p1)
print(p2)
print(p3)

dev.off()
cat("Visualizations saved to: ", file.path(OUTPUT_DIR, "disease_signature_distributions.pdf"), "\n", sep = "")

cat("\nAnalysis complete!\n")
