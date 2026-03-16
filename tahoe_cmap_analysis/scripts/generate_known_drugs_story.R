#!/usr/bin/env Rscript

# Known Drugs Story - Comprehensive Analysis
# Tells the complete story about drug coverage across platforms

library(tidyverse)
library(arrow)
library(ggplot2)
library(gridExtra)
library(scales)

# ============================================================================
# COLOR SCHEME
# ============================================================================
COLOR_CMAP <- "#F39C12"      # Warm Orange
COLOR_TAHOE <- "#5DADE2"     # Serene Blue
COLOR_KNOWN <- "#27AE60"     # Green for Known Drugs/Open Targets
COLOR_OVERLAP <- "#9B59B6"   # Purple for overlap
COLOR_MISSING <- "#E74C3C"   # Red for missing/gaps

figures_dir <- "tahoe_cmap_analysis/figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data...\n")

# Load known drugs from Open Targets
known_drugs <- read_parquet('tahoe_cmap_analysis/data/known_drugs/known_drug_info_data.parquet')
disease_info <- read_parquet('tahoe_cmap_analysis/data/known_drugs/disease.parquet')

# Load analysis summary (has our 233 diseases)
analysis <- read_csv('tahoe_cmap_analysis/data/analysis/creed_manual_analysis_exp_8/analysis_summary_creed_manual_standardised_results_OG_exp_8_q0.05.csv',
                     show_col_types = FALSE)

# Load CMap and Tahoe drug lists
cmap_drugs <- read.csv('tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_drug_experiments_new.csv')
tahoe_drugs_df <- read.csv('tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv')

cat("✓ Data loaded\n\n")

# ============================================================================
# ANALYSIS 1: Unique Drugs in Each Platform
# ============================================================================

cat("=== ANALYSIS 1: Unique Drugs Across Platforms ===\n")

# Get unique drugs
unique_known <- unique(known_drugs$drug_common_name)
unique_cmap <- unique(tolower(trimws(cmap_drugs$name)))  # Normalize for matching
unique_tahoe <- unique(tolower(trimws(tahoe_drugs_df$name)))     # Normalize for matching
unique_known_normalized <- unique(tolower(trimws(unique_known)))

cat("Unique drugs in Open Targets:", length(unique_known), "\n")
cat("Unique drugs in CMap:", length(unique_cmap), "\n")
cat("Unique drugs in Tahoe:", length(unique_tahoe), "\n\n")

# Overlap between platforms and known drugs
cmap_in_known <- sum(unique_cmap %in% unique_known_normalized)
tahoe_in_known <- sum(unique_tahoe %in% unique_known_normalized)
both_platforms <- intersect(unique_cmap, unique_tahoe)
both_in_known <- sum(both_platforms %in% unique_known_normalized)

cat("CMap drugs also in Known Drugs:", cmap_in_known, "/", length(unique_cmap), 
    sprintf("(%.1f%%)\n", 100*cmap_in_known/length(unique_cmap)))
cat("Tahoe drugs also in Known Drugs:", tahoe_in_known, "/", length(unique_tahoe), 
    sprintf("(%.1f%%)\n", 100*tahoe_in_known/length(unique_tahoe)))
cat("Drugs in both CMap & Tahoe that are in Known:", both_in_known, "\n\n")

# ============================================================================
# ANALYSIS 2: Disease-Drug Relationships
# ============================================================================

cat("=== ANALYSIS 2: Disease Matching for 233 Diseases ===\n")

# Count diseases by match type
match_summary <- analysis %>%
  group_by(match_type) %>%
  summarize(
    count = n(),
    avg_known_drugs = mean(known_drugs_in_database_count, na.rm=TRUE),
    .groups = 'drop'
  )

cat("\nDisease matching breakdown:\n")
print(match_summary)

diseases_with_known <- sum(analysis$known_drugs_in_database_count > 0, na.rm=TRUE)
cat("\nDiseases with known drugs:", diseases_with_known, "/", nrow(analysis), 
    sprintf("(%.1f%%)\n\n", 100*diseases_with_known/nrow(analysis)))

# ============================================================================
# ANALYSIS 3: Disease-Drug Pairs Coverage
# ============================================================================

cat("=== ANALYSIS 3: Disease-Drug Pair Coverage ===\n")

# Total known disease-drug pairs for our 233 diseases
total_pairs <- sum(analysis$known_drugs_in_database_count, na.rm=TRUE)
pairs_in_cmap <- sum(analysis$known_drugs_available_in_cmap_count, na.rm=TRUE)
pairs_in_tahoe <- sum(analysis$known_drugs_available_in_tahoe_count, na.rm=TRUE)

# Drugs that were found in results
found_in_tahoe <- sum(analysis$tahoe_in_known_count, na.rm=TRUE)
found_in_cmap <- sum(analysis$cmap_in_known_count, na.rm=TRUE)
found_in_both <- sum(analysis$common_in_known_count, na.rm=TRUE)

cat("Total disease-drug pairs (from known drugs):", total_pairs, "\n")
cat("Pairs where drug available in CMap:", pairs_in_cmap, sprintf("(%.1f%% of total)\n", 100*pairs_in_cmap/total_pairs))
cat("Pairs where drug available in Tahoe:", pairs_in_tahoe, sprintf("(%.1f%% of total)\n", 100*pairs_in_tahoe/total_pairs))
cat("\nDrugs found in top hits:\n")
cat("  Found by Tahoe:", found_in_tahoe, sprintf("(%.1f%% of available)\n", 100*found_in_tahoe/pairs_in_tahoe))
cat("  Found by CMap:", found_in_cmap, sprintf("(%.1f%% of available)\n", 100*found_in_cmap/pairs_in_cmap))
cat("  Found by both:", found_in_both, "\n\n")

# ============================================================================
# CHART 1: Drug Platform Coverage (Venn-style)
# ============================================================================

cat("Creating Chart 1: Drug Platform Coverage...\n")

# Calculate all combinations
both_platforms_drugs <- length(intersect(unique_cmap, unique_tahoe))
cmap_only <- length(unique_cmap) - cmap_in_known
tahoe_only <- length(unique_tahoe) - tahoe_in_known
known_only <- length(unique_known) - cmap_in_known - tahoe_in_known + both_in_known
cmap_known <- cmap_in_known - both_in_known
tahoe_known <- tahoe_in_known - both_in_known
all_three <- both_in_known
cmap_tahoe <- both_platforms_drugs  # All drugs in both CMap and Tahoe (including those in Open Targets)

# Create comprehensive drug coverage data with all combinations
drug_coverage_data <- data.frame(
  Category = c("Open Targets\nOnly", "Tahoe\nOnly", "CMap\nOnly",
               "CMap &\nOpen Targets", "Tahoe &\nOpen Targets", 
               "CMap, Tahoe &\nOpen Targets", "CMap &\nTahoe"),
  Count = c(known_only, tahoe_only, cmap_only,
            cmap_known, tahoe_known, all_three, cmap_tahoe),
  Group = c("Open Targets Only", "Tahoe Only", "CMap Only",
            "CMap + Known", "Tahoe + Known", "All Three", "CMap + Tahoe")
)

drug_coverage_data$Category <- factor(drug_coverage_data$Category, 
                                       levels = drug_coverage_data$Category)

p1 <- ggplot(drug_coverage_data, aes(x = Category, y = Count, fill = Group)) +
  geom_bar(stat = "identity", width = 0.65, color = "white", linewidth = 1.2) +
  scale_fill_manual(values = c(
    "CMap Only" = paste0(COLOR_CMAP, "CC"),
    "Tahoe Only" = paste0(COLOR_TAHOE, "CC"),
    "Open Targets Only" = COLOR_KNOWN,
    "CMap + Known" = COLOR_CMAP,
    "Tahoe + Known" = COLOR_TAHOE,
    "All Three" = COLOR_OVERLAP,
    "CMap + Tahoe" = COLOR_OVERLAP
  )) +
  labs(
    title = "Unique Drug Coverage Across Platforms",
    subtitle = NULL,
    x = "",
    y = "Number of Unique Drugs"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 25)),
    axis.text.x = element_text(size = 10, face = "bold", color = "#333"),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "right",
    legend.title = element_blank(),
    legend.text = element_text(size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "gray92", linewidth = 0.3)
  ) +
  geom_text(aes(label = format(Count, big.mark = ",")), 
            vjust = -0.5, size = 3.8, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)))

ggsave(file.path(figures_dir, "known_drugs_chart1_platform_coverage.png"),
       p1, width = 14, height = 8, dpi = 300, bg = "white")

cat("✓ Chart 1 complete\n\n")

# ============================================================================
# CHART 2: Disease Matching Quality
# ============================================================================

cat("Creating Chart 2: Disease Matching Quality...\n")

match_data <- analysis %>%
  mutate(
    has_known_drugs = ifelse(known_drugs_in_database_count > 0, "Has Known Drugs", "No Known Drugs"),
    match_type = tools::toTitleCase(match_type)
  ) %>%
  group_by(match_type, has_known_drugs) %>%
  summarize(count = n(), .groups = 'drop')

p2 <- ggplot(match_data, aes(x = match_type, y = count, fill = has_known_drugs)) +
  geom_bar(stat = "identity", position = "stack", width = 0.6, color = "white", linewidth = 1) +
  scale_fill_manual(values = c("Has Known Drugs" = COLOR_KNOWN, "No Known Drugs" = "#BDC3C7")) +
  labs(
    title = "Disease Matching Quality for 233 Diseases",
    subtitle = sprintf("%d diseases (%.1f%%) have known drug associations", 
                      diseases_with_known, 100*diseases_with_known/nrow(analysis)),
    x = "Match Type",
    y = "Number of Diseases",
    fill = "Known Drug Status"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 20), color = "#555555"),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "top",
    panel.grid.major.x = element_blank()
  ) +
  geom_text(aes(label = count), position = position_stack(vjust = 0.5), 
            size = 5, fontface = "bold", color = "white")

ggsave(file.path(figures_dir, "known_drugs_chart2_disease_matching.png"),
       p2, width = 10, height = 8, dpi = 300, bg = "white")

cat("✓ Chart 2 complete\n\n")

# ============================================================================
# CHART 3: Disease-Drug Pair Availability and Recovery
# ============================================================================

cat("Creating Chart 3: Disease-Drug Pair Coverage...\n")

# Calculate pairs available in both platforms
# For each disease, the overlap is the minimum of cmap and tahoe counts
pairs_in_both_available <- 0
for(i in 1:nrow(analysis)) {
  cmap_count <- analysis$known_drugs_available_in_cmap_count[i]
  tahoe_count <- analysis$known_drugs_available_in_tahoe_count[i]
  both_count <- min(cmap_count, tahoe_count)
  pairs_in_both_available <- pairs_in_both_available + both_count
}

pairs_only_cmap <- pairs_in_cmap - pairs_in_both_available
pairs_only_tahoe <- pairs_in_tahoe - pairs_in_both_available

# Recovered pairs
pairs_found_only_cmap <- found_in_cmap - found_in_both
pairs_found_only_tahoe <- found_in_tahoe - found_in_both

pair_data <- data.frame(
  StageLabel = c("Total Available\nin CMap", "Total Available\nin Tahoe",
                 "Available\nCMap Only", "Available\nTahoe Only", 
                 "Available in\nBoth CMap & Tahoe",
                 "Recovered\nby CMap Only", "Recovered\nby Tahoe Only", "Recovered\nby Both"),
  Count = c(pairs_in_cmap, pairs_in_tahoe,
            pairs_only_cmap, pairs_only_tahoe, pairs_in_both_available,
            pairs_found_only_cmap, pairs_found_only_tahoe, found_in_both),
  Stage = c("Total", "Total", "Available", "Available", "Available", "Recovered", "Recovered", "Recovered"),
  Platform = c("CMap", "Tahoe", "CMap", "Tahoe", "Both", "CMap", "Tahoe", "Both"),
  RecoveryRate = c(NA, NA, NA, NA, NA,
                   sprintf("%.1f%%", 100*found_in_cmap/(pairs_in_cmap)),
                   sprintf("%.1f%%", 100*found_in_tahoe/(pairs_in_tahoe)),
                   NA)
)

pair_data$StageLabel <- factor(pair_data$StageLabel, levels = pair_data$StageLabel)

p3 <- ggplot(pair_data, aes(x = StageLabel, y = Count, fill = Platform)) +
  geom_bar(stat = "identity", width = 0.65, color = "white", linewidth = 1.2) +
  scale_fill_manual(values = c(
    "CMap" = COLOR_CMAP,
    "Tahoe" = COLOR_TAHOE,
    "Both" = COLOR_OVERLAP
  )) +
  labs(
    title = "Disease-Drug Pair Recovery: Known Drug Signatures",
    subtitle = NULL,
    x = "",
    y = "Number of Disease-Drug Pairs"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 25)),
    axis.text.x = element_text(size = 9, face = "bold", color = "#333"),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "top",
    legend.title = element_blank(),
    legend.text = element_text(size = 11),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "gray92", linewidth = 0.3)
  ) +
  geom_text(aes(label = format(Count, big.mark = ",")), 
            vjust = -0.5, size = 3.5, fontface = "bold") +
  # Add recovery rate labels above recovered bars
  geom_text(data = pair_data %>% filter(Stage == "Recovered" & Platform != "Both"),
            aes(label = RecoveryRate), 
            vjust = -2, size = 3.5, fontface = "italic", color = "#555") +
  annotate("text", 
           x = 5.5, 
           y = max(pair_data$Count) * 0.75, 
           label = sprintf("Total Pairs in Known Drugs: %s\nFrom %d diseases", 
                          format(total_pairs, big.mark = ","), nrow(analysis)),
           size = 4.5, hjust = 0, color = "#333",
           fontface = "bold", family = "sans") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)))

ggsave(file.path(figures_dir, "known_drugs_chart3_pair_recovery.png"),
       p3, width = 14, height = 8, dpi = 300, bg = "white")

cat("✓ Chart 3 complete\n\n")

# ============================================================================
# CHART 4: Per-Disease Known Drug Distribution
# ============================================================================

cat("Creating Chart 4: Per-Disease Known Drug Distribution...\n")

disease_drug_dist <- analysis %>%
  filter(known_drugs_in_database_count > 0) %>%
  select(disease_name, known_drugs_in_database_count, 
         known_drugs_available_in_cmap_count, 
         known_drugs_available_in_tahoe_count) %>%
  arrange(desc(known_drugs_in_database_count)) %>%
  slice(1:30) %>%  # Top 30 diseases
  pivot_longer(cols = c(known_drugs_available_in_cmap_count,
                       known_drugs_available_in_tahoe_count),
              names_to = "metric", values_to = "count") %>%
  mutate(
    metric = case_when(
      metric == "known_drugs_available_in_cmap_count" ~ "Available in CMap",
      metric == "known_drugs_available_in_tahoe_count" ~ "Available in Tahoe"
    ),
    metric = factor(metric, levels = c("Available in CMap", "Available in Tahoe"))
  )

p4 <- ggplot(disease_drug_dist, aes(x = reorder(disease_name, count), y = count, fill = metric)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7, color = "white", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "Available in CMap" = COLOR_CMAP,
    "Available in Tahoe" = COLOR_TAHOE
  )) +
  coord_flip() +
  labs(
    title = "Top 30 Diseases by Known Drug Count",
    subtitle = "Comparison of total known drugs vs. platform availability",
    x = "",
    y = "Number of Known Drugs",
    fill = ""
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 20)),
    axis.text.y = element_text(size = 8),
    axis.text.x = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "top",
    panel.grid.major.y = element_blank()
  )

ggsave(file.path(figures_dir, "known_drugs_chart4_top_diseases.png"),
       p4, width = 12, height = 10, dpi = 300, bg = "white")

cat("✓ Chart 4 complete\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║              KNOWN DRUGS STORY - SUMMARY REPORT               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("DRUG PLATFORM COVERAGE:\n")
cat(sprintf("  Open Targets unique drugs: %s\n", format(length(unique_known), big.mark=",")))
cat(sprintf("  CMap unique drugs: %s (%d in Open Targets, %.1f%%)\n", 
           format(length(unique_cmap), big.mark=","), cmap_in_known, 100*cmap_in_known/length(unique_cmap)))
cat(sprintf("  Tahoe unique drugs: %s (%d in Open Targets, %.1f%%)\n", 
           format(length(unique_tahoe), big.mark=","), tahoe_in_known, 100*tahoe_in_known/length(unique_tahoe)))
cat(sprintf("  Drugs in all three: %d\n\n", both_in_known))

cat("DISEASE MATCHING (233 diseases):\n")
cat(sprintf("  Matched by name: %d diseases\n", sum(analysis$match_type == "name")))
cat(sprintf("  Matched by synonym: %d diseases\n", sum(analysis$match_type == "synonym")))
cat(sprintf("  No match: %d diseases\n", sum(analysis$match_type == "no match")))
cat(sprintf("  Diseases with known drugs: %d (%.1f%%)\n\n", 
           diseases_with_known, 100*diseases_with_known/nrow(analysis)))

cat("DISEASE-DRUG PAIRS:\n")
cat(sprintf("  Total known pairs: %s\n", format(total_pairs, big.mark=",")))
cat(sprintf("  Available in CMap: %s (%.1f%%)\n", 
           format(pairs_in_cmap, big.mark=","), 100*pairs_in_cmap/total_pairs))
cat(sprintf("  Available in Tahoe: %s (%.1f%%)\n", 
           format(pairs_in_tahoe, big.mark=","), 100*pairs_in_tahoe/total_pairs))
cat(sprintf("  Found by CMap: %s (%.1f%% recovery)\n", 
           format(found_in_cmap, big.mark=","), 100*found_in_cmap/pairs_in_cmap))
cat(sprintf("  Found by Tahoe: %s (%.1f%% recovery)\n", 
           format(found_in_tahoe, big.mark=","), 100*found_in_tahoe/pairs_in_tahoe))
cat(sprintf("  Found by both: %s\n\n", format(found_in_both, big.mark=",")))

cat("FILES CREATED:\n")
cat("  1. known_drugs_chart1_platform_coverage.png\n")
cat("  2. known_drugs_chart2_disease_matching.png\n")
cat("  3. known_drugs_chart3_pair_recovery.png\n")
cat("  4. known_drugs_chart4_top_diseases.png\n\n")

cat("✓ All known drugs story charts generated successfully!\n")
