#!/usr/bin/env Rscript
# Specialized Analysis: Disease-Type-Specific Strengths (KNOWN DRUGS ONLY)
# Figure Suite for showing when to use TAHOE, CMAP, or Both
# Filtering to ONLY hits that are in known drugs database
# Exp8 Analysis with Q-threshold 0.05

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(reshape2)
library(ggrepel)

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
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 10, face = "bold")
  )
}

# Read data
file_path <- "creeds_diseases/analysis/Exp8_Analysis.xlsx"
df <- read_excel(file_path, sheet = "exp_8_0.05")

# Categorize diseases
df <- df %>%
  mutate(disease_category = case_when(
    str_detect(tolower(disease_name), "cancer|carcinoma|melanoma|lymphoma|leukemia|sarcoma|tumor") ~ "Oncology",
    str_detect(tolower(disease_name), "diabetes|glucose|insulin") ~ "Metabolic",
    str_detect(tolower(disease_name), "alzheimer|parkinson|dementia|neurodegeneration|autism") ~ "Neurodegenerative",
    str_detect(tolower(disease_name), "heart|cardiac|cardiovascular|arrhythmia|hypertension") ~ "Cardiovascular",
    str_detect(tolower(disease_name), "infection|bacterial|viral|fungal|sepsis|salmonella|tuberculosis") ~ "Infectious",
    str_detect(tolower(disease_name), "autoimmune|lupus|rheumatoid|crohn|colitis|psoriasis") ~ "Autoimmune",
    str_detect(tolower(disease_name), "allergy|asthma|eczema|urticaria") ~ "Allergic/Respiratory",
    str_detect(tolower(disease_name), "rare|orphan|genetic|syndrom") ~ "Rare/Genetic",
    TRUE ~ "Other"
  ))

# Output directory
output_dir <- "figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ============================================================================
# FIGURE 13B: Pipeline Strength by Disease Category (KNOWN DRUGS ONLY)
# ============================================================================

cat("Creating Figure 13B: Pipeline Strength - Known Drugs Only\n")

perf_by_cat_known <- df %>%
  group_by(disease_category) %>%
  summarise(
    N_Diseases = n(),
    TAHOE_Known_Drugs_Mean = mean(tahoe_in_known_count, na.rm = TRUE),
    TAHOE_Known_Drugs_SD = sd(tahoe_in_known_count, na.rm = TRUE),
    TAHOE_Known_Drugs_SE = sd(tahoe_in_known_count, na.rm = TRUE) / sqrt(n()),
    CMAP_Known_Drugs_Mean = mean(cmap_in_known_count, na.rm = TRUE),
    CMAP_Known_Drugs_SD = sd(cmap_in_known_count, na.rm = TRUE),
    CMAP_Known_Drugs_SE = sd(cmap_in_known_count, na.rm = TRUE) / sqrt(n()),
    Common_Known_Drugs = mean(common_in_known_count, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(N_Diseases)) %>%
  mutate(
    Advantage = ifelse(TAHOE_Known_Drugs_Mean > CMAP_Known_Drugs_Mean, "TAHOE", "CMAP"),
    Difference = abs(TAHOE_Known_Drugs_Mean - CMAP_Known_Drugs_Mean)
  )

fig13b_data <- data.frame(
  disease_category = rep(perf_by_cat_known$disease_category, 2),
  Pipeline = c(rep("TAHOE", nrow(perf_by_cat_known)), rep("CMAP", nrow(perf_by_cat_known))),
  Mean = c(perf_by_cat_known$TAHOE_Known_Drugs_Mean, perf_by_cat_known$CMAP_Known_Drugs_Mean),
  SE = c(perf_by_cat_known$TAHOE_Known_Drugs_SE, perf_by_cat_known$CMAP_Known_Drugs_SE)
)

fig13b <- ggplot(fig13b_data, aes(x = reorder(disease_category, Mean, FUN = function(x) max(x)), 
                                  y = Mean, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  geom_errorbar(aes(ymin = Mean - SE, ymax = Mean + SE), 
                position = position_dodge(0.9), width = 0.2, linewidth = 0.5) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12"),
                    labels = c("TAHOE" = "TAHOE", "CMAP" = "CMAP")) +
  labs(
    title = "Pipeline Strength by Disease Category (Known Drugs Only)",
    subtitle = "Average known drug hits across different disease types (error bars: standard error)",
    x = "Disease Category",
    y = "Average Known Drug Hits"
  ) +
  theme_manuscript() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(fig13b_data$Mean + fig13b_data$SE, na.rm = T) * 1.15))

ggsave(file.path(output_dir, "Fig13B_Pipeline_Strength_Known_Drugs_Only.pdf"), fig13b, width = 11, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Fig13B_Pipeline_Strength_Known_Drugs_Only.png"), fig13b, width = 11, height = 6, dpi = 300)

cat("✓ Figure 13B saved: Pipeline Strength by Disease Category (Known Drugs Only)\n\n")

# ============================================================================
# FIGURE 16B: Decision Matrix (KNOWN DRUGS ONLY)
# ============================================================================

cat("Creating Figure 16B: Decision Matrix - Known Drugs Only\n")

recommendations_known <- perf_by_cat_known %>%
  mutate(
    TAHOE_Dominant = ifelse(TAHOE_Known_Drugs_Mean > CMAP_Known_Drugs_Mean, "TAHOE Dominant", ""),
    CMAP_Dominant = ifelse(CMAP_Known_Drugs_Mean > TAHOE_Known_Drugs_Mean, "CMAP Dominant", ""),
    Recommendation = case_when(
      TAHOE_Known_Drugs_Mean > CMAP_Known_Drugs_Mean & TAHOE_Known_Drugs_Mean - CMAP_Known_Drugs_Mean > 2 ~ "Use TAHOE Only",
      CMAP_Known_Drugs_Mean > TAHOE_Known_Drugs_Mean & CMAP_Known_Drugs_Mean - TAHOE_Known_Drugs_Mean > 2 ~ "Use CMAP Only",
      abs(TAHOE_Known_Drugs_Mean - CMAP_Known_Drugs_Mean) <= 2 ~ "Use BOTH - Complementary",
      TRUE ~ "Primary + Secondary"
    )
  ) %>%
  arrange(disease_category)

fig16b_data <- recommendations_known %>%
  select(disease_category, N_Diseases, TAHOE_Known_Drugs_Mean, CMAP_Known_Drugs_Mean, Recommendation)

# Create color mapping for recommendations
rec_colors <- c(
  "Use TAHOE Only" = "#2E86AB",
  "Use CMAP Only" = "#A23B72",
  "Use BOTH - Complementary" = "#F18F01",
  "Primary + Secondary" = "#06A77D"
)

fig16b_data$rec_color <- rec_colors[fig16b_data$Recommendation]

fig16b <- ggplot(fig16b_data, aes(x = TAHOE_Known_Drugs, y = CMAP_Known_Drugs, 
                                  size = N_Diseases, color = Recommendation, fill = Recommendation)) +
  geom_point(alpha = 0.7, stroke = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.8) +
  scale_color_manual(values = rec_colors) +
  scale_fill_manual(values = rec_colors) +
  scale_size_continuous(name = "Num. Diseases", range = c(3, 12)) +
  geom_text_repel(aes(label = disease_category), size = 3.5, fontface = "bold", 
                  color = "#1A1A1A", box.padding = 0.5, point.padding = 0.3,
                  min.segment.length = 0, segment.size = 0.5, segment.color = "gray70",
                  force = 2, max.overlaps = Inf) +
  labs(
    title = "Pipeline Selection Matrix (Known Drugs Only)",
    subtitle = "Recommendation based on known drug recovery (diagonal = equal performance)",
    x = "TAHOE Average Known Drug Hits",
    y = "CMAP Average Known Drug Hits"
  ) +
  theme_manuscript() +
  theme(legend.box = "vertical", legend.position = "right") +
  scale_x_continuous(limits = c(0, max(fig16b_data$TAHOE_Known_Drugs) * 1.15)) +
  scale_y_continuous(limits = c(0, max(fig16b_data$CMAP_Known_Drugs) * 1.15))

ggsave(file.path(output_dir, "Fig16B_Pipeline_Decision_Matrix_Known_Drugs_Only.pdf"), fig16b, width = 12, height = 7, dpi = 300)
ggsave(file.path(output_dir, "Fig16B_Pipeline_Decision_Matrix_Known_Drugs_Only.png"), fig16b, width = 12, height = 7, dpi = 300)

cat("✓ Figure 16B saved: Pipeline Decision Matrix (Known Drugs Only)\n\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("\n╔════════════════════════════════════════════════════════════╗\n")
cat("║    KNOWN DRUGS ONLY ANALYSIS - SUMMARY REPORT              ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

cat("PIPELINE RECOMMENDATIONS BY DISEASE CATEGORY (KNOWN DRUGS ONLY):\n")
cat(paste(rep("-", 80), collapse = ""), "\n")

summary_table <- recommendations_known %>%
  select(disease_category, N_Diseases, TAHOE_Known_Drugs, CMAP_Known_Drugs, Recommendation)

for (i in 1:nrow(summary_table)) {
  row <- summary_table[i,]
  cat(sprintf("\n%s (n=%d diseases)\n", row$disease_category, row$N_Diseases))
  cat(sprintf("  TAHOE: %.2f avg known drug hits | CMAP: %.2f avg known drug hits\n", 
              row$TAHOE_Known_Drugs, row$CMAP_Known_Drugs))
  cat(sprintf("  RECOMMENDATION: %s\n", row$Recommendation))
}

cat("\n\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("KEY DIFFERENCES: ALL HITS vs KNOWN DRUGS ONLY\n")
cat(paste(rep("-", 80), collapse = ""), "\n\n")

comparison <- perf_by_cat_known %>%
  select(disease_category, N_Diseases, TAHOE_Known_Drugs, CMAP_Known_Drugs)

cat("Disease categories where TAHOE shows stronger advantage in known drugs:\n")
tahoe_advantage <- recommendations_known %>% 
  filter(str_detect(Recommendation, "TAHOE")) %>%
  arrange(desc(TAHOE_Known_Drugs))

if (nrow(tahoe_advantage) > 0) {
  for (i in 1:nrow(tahoe_advantage)) {
    row <- tahoe_advantage[i,]
    cat(sprintf("  • %s (TAHOE: %.2f vs CMAP: %.2f)\n", 
                row$disease_category, row$TAHOE_Known_Drugs, row$CMAP_Known_Drugs))
  }
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("FILES CREATED:\n")
cat("  1. Fig13B_Pipeline_Strength_Known_Drugs_Only.pdf / .png\n")
cat("  2. Fig16B_Pipeline_Decision_Matrix_Known_Drugs_Only.pdf / .png\n\n")

cat("✓ All known drugs-only visualizations created successfully!\n")
