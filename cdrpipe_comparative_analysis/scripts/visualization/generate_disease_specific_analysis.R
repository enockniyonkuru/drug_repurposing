#!/usr/bin/env Rscript
# Specialized Analysis: Disease-Type-Specific Strengths
# Figure Suite for showing when to use TAHOE, CMAP, or Both
# Exp8 Analysis with Q-threshold 0.05

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
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
# FIGURE 13: Pipeline Strength by Disease Category
# ============================================================================

perf_by_cat <- df %>%
  group_by(disease_category) %>%
  summarise(
    N_Diseases = n(),
    TAHOE_Avg_Hits = mean(tahoe_hits_count, na.rm = TRUE),
    TAHOE_SD_Hits = sd(tahoe_hits_count, na.rm = TRUE),
    TAHOE_SE_Hits = sd(tahoe_hits_count, na.rm = TRUE) / sqrt(n()),
    CMAP_Avg_Hits = mean(cmap_hits_count, na.rm = TRUE),
    CMAP_SD_Hits = sd(cmap_hits_count, na.rm = TRUE),
    CMAP_SE_Hits = sd(cmap_hits_count, na.rm = TRUE) / sqrt(n()),
    TAHOE_Known_Drugs = mean(tahoe_in_known_count, na.rm = TRUE),
    CMAP_Known_Drugs = mean(cmap_in_known_count, na.rm = TRUE),
    Common_Avg_Hits = mean(common_hits_count, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(N_Diseases)) %>%
  mutate(
    Advantage = ifelse(TAHOE_Avg_Hits > CMAP_Avg_Hits, "TAHOE", "CMAP"),
    Difference = abs(TAHOE_Avg_Hits - CMAP_Avg_Hits)
  )

fig13_data <- data.frame(
  disease_category = rep(perf_by_cat$disease_category, 2),
  Pipeline = c(rep("TAHOE", nrow(perf_by_cat)), rep("CMAP", nrow(perf_by_cat))),
  Mean = c(perf_by_cat$TAHOE_Avg_Hits, perf_by_cat$CMAP_Avg_Hits),
  SE = c(perf_by_cat$TAHOE_SE_Hits, perf_by_cat$CMAP_SE_Hits)
)

fig13 <- ggplot(fig13_data, aes(x = reorder(disease_category, Mean, FUN = function(x) max(x)), 
                                y = Mean, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  geom_errorbar(aes(ymin = Mean - SE, ymax = Mean + SE), 
                position = position_dodge(0.9), width = 0.2, linewidth = 0.5) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12"),
                    labels = c("TAHOE" = "TAHOE", "CMAP" = "CMAP")) +
  labs(
    title = "Pipeline Strength by Disease Category",
    subtitle = "Average drug hits across different disease types (error bars: standard error)",
    x = "Disease Category",
    y = "Average Drug Hits"
  ) +
  theme_manuscript() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(fig13_data$Mean + fig13_data$SE, na.rm = T) * 1.15))

ggsave(file.path(output_dir, "Fig13_Pipeline_Strength_by_Disease.pdf"), fig13, width = 11, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Fig13_Pipeline_Strength_by_Disease.png"), fig13, width = 11, height = 6, dpi = 300)

cat("✓ Figure 13 saved: Pipeline Strength by Disease Category\n")

# ============================================================================
# FIGURE 14: Pipeline Advantage Score (TAHOE vs CMAP Dominance)
# ============================================================================

advantage_data <- perf_by_cat %>%
  mutate(
    TAHOE_Score = TAHOE_Avg_Hits,
    CMAP_Score = CMAP_Avg_Hits,
    Dominance = ((TAHOE_Avg_Hits - CMAP_Avg_Hits) / pmax(TAHOE_Avg_Hits, CMAP_Avg_Hits)) * 100
  ) %>%
  arrange(Dominance) %>%
  filter(!is.na(disease_category))

# Create color scheme: positive = TAHOE wins, negative = CMAP wins
advantage_data$Color <- ifelse(advantage_data$Dominance > 0, "#2E86AB", "#A23B72")

fig14 <- ggplot(advantage_data, aes(x = reorder(disease_category, Dominance), y = Dominance, fill = Color)) +
  geom_bar(stat = "identity", color = "black", linewidth = 0.7) +
  geom_hline(yintercept = 0, color = "black", size = 0.8) +
  scale_fill_identity() +
  coord_flip() +
  labs(
    title = "Pipeline Dominance by Disease Category",
    subtitle = "Positive = TAHOE stronger | Negative = CMAP stronger",
    x = "Disease Category",
    y = "Dominance Score (%)"
  ) +
  theme_manuscript() +
  theme(legend.position = "none") +
  scale_y_continuous(expand = c(0.1, 0))

ggsave(file.path(output_dir, "Fig14_Pipeline_Dominance.pdf"), fig14, width = 9, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Fig14_Pipeline_Dominance.png"), fig14, width = 9, height = 6, dpi = 300)

cat("✓ Figure 14 saved: Pipeline Dominance Score\n")

# ============================================================================
# FIGURE 15: Complementarity Analysis - When to Use Both
# ============================================================================

complementarity <- perf_by_cat %>%
  mutate(
    Max_Pipeline_Hits = pmax(TAHOE_Avg_Hits, CMAP_Avg_Hits),
    Combined_Hits = TAHOE_Avg_Hits + CMAP_Avg_Hits - Common_Avg_Hits,
    Synergy_Gain = ((Combined_Hits - Max_Pipeline_Hits) / Max_Pipeline_Hits) * 100,
    Overlap_Percentage = (Common_Avg_Hits / Max_Pipeline_Hits) * 100
  ) %>%
  arrange(desc(Synergy_Gain))

fig15_data <- complementarity %>%
  select(disease_category, Common_Avg_Hits, Synergy_Gain, Overlap_Percentage) %>%
  pivot_longer(cols = c("Common_Avg_Hits", "Synergy_Gain"),
               names_to = "Metric", values_to = "Value")

fig15 <- ggplot(complementarity, aes(x = reorder(disease_category, Synergy_Gain), y = Synergy_Gain)) +
  geom_bar(stat = "identity", fill = "#F18F01", color = "black", linewidth = 0.7) +
  geom_text(aes(label = paste0(round(Overlap_Percentage, 1), "% overlap")), 
            hjust = 0.5, vjust = -0.3, size = 3, fontface = "bold") +
  coord_flip() +
  labs(
    title = "Synergy Gain from Using Both Pipelines",
    subtitle = "Extra candidates found by combining TAHOE + CMAP",
    x = "Disease Category",
    y = "Additional Hits from Combination (%)"
  ) +
  theme_manuscript() +
  theme(legend.position = "none") +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(complementarity$Synergy_Gain, na.rm = T) * 1.15))

ggsave(file.path(output_dir, "Fig15_Synergy_Analysis.pdf"), fig15, width = 9, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Fig15_Synergy_Analysis.png"), fig15, width = 9, height = 6, dpi = 300)

cat("✓ Figure 15 saved: Synergy Analysis (When to Use Both)\n")

# ============================================================================
# FIGURE 16: Decision Matrix - Pipeline Recommendation
# ============================================================================

recommendations <- perf_by_cat %>%
  mutate(
    TAHOE_Dominant = ifelse(TAHOE_Avg_Hits > CMAP_Avg_Hits, "TAHOE Dominant", ""),
    CMAP_Dominant = ifelse(CMAP_Avg_Hits > TAHOE_Avg_Hits, "CMAP Dominant", ""),
    Known_Drug_TAHOE = TAHOE_Known_Drugs > CMAP_Known_Drugs,
    Known_Drug_CMAP = CMAP_Known_Drugs > TAHOE_Known_Drugs,
    Recommendation = case_when(
      TAHOE_Avg_Hits > CMAP_Avg_Hits & TAHOE_Known_Drugs > CMAP_Known_Drugs ~ "Use TAHOE Only",
      CMAP_Avg_Hits > TAHOE_Avg_Hits & CMAP_Known_Drugs > TAHOE_Known_Drugs ~ "Use CMAP Only",
      abs(TAHOE_Avg_Hits - CMAP_Avg_Hits) < 50 ~ "Use BOTH - High Complementarity",
      TRUE ~ "Primary + Secondary"
    )
  ) %>%
  arrange(disease_category)

fig16_data <- recommendations %>%
  select(disease_category, N_Diseases, TAHOE_Avg_Hits, CMAP_Avg_Hits, Recommendation)

# Create color mapping for recommendations
rec_colors <- c(
  "Use TAHOE Only" = "#2E86AB",
  "Use CMAP Only" = "#A23B72",
  "Use BOTH - High Complementarity" = "#F18F01",
  "Primary + Secondary" = "#06A77D"
)

fig16_data$rec_color <- rec_colors[fig16_data$Recommendation]

fig16 <- ggplot(fig16_data, aes(x = TAHOE_Avg_Hits, y = CMAP_Avg_Hits, 
                                size = N_Diseases, color = Recommendation, fill = Recommendation)) +
  geom_point(alpha = 0.7, stroke = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.8) +
  scale_color_manual(values = rec_colors) +
  scale_fill_manual(values = rec_colors) +
  scale_size_continuous(name = "Num. Diseases", range = c(3, 12)) +
  geom_text(aes(label = disease_category), size = 3, fontface = "bold", vjust = 0.5, hjust = 0.5) +
  labs(
    title = "Pipeline Selection Matrix",
    subtitle = "Recommendation based on disease category performance (diagonal = equal performance)",
    x = "TAHOE Average Hits",
    y = "CMAP Average Hits"
  ) +
  theme_manuscript() +
  theme(legend.box = "vertical", legend.position = "right") +
  scale_x_continuous(limits = c(0, max(fig16_data$TAHOE_Avg_Hits) * 1.15)) +
  scale_y_continuous(limits = c(0, max(fig16_data$CMAP_Avg_Hits) * 1.15))

ggsave(file.path(output_dir, "Fig16_Pipeline_Decision_Matrix.pdf"), fig16, width = 12, height = 7, dpi = 300)
ggsave(file.path(output_dir, "Fig16_Pipeline_Decision_Matrix.png"), fig16, width = 12, height = 7, dpi = 300)

cat("✓ Figure 16 saved: Pipeline Decision Matrix\n")

# ============================================================================
# FIGURE 17: Known Drug Recovery Effectiveness by Disease Type
# ============================================================================

fig17_data <- perf_by_cat %>%
  select(disease_category, TAHOE_Known_Drugs, CMAP_Known_Drugs) %>%
  pivot_longer(cols = -disease_category,
               names_to = "Pipeline", values_to = "Known_Drugs")

fig17 <- ggplot(fig17_data, aes(x = reorder(disease_category, Known_Drugs, FUN = max), 
                                y = Known_Drugs, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  scale_fill_manual(values = c("TAHOE_Known_Drugs" = "#06A77D", "CMAP_Known_Drugs" = "#D62828"),
                    labels = c("TAHOE", "CMAP")) +
  labs(
    title = "Known Drug Recovery by Disease Type",
    subtitle = "Average hits within validated known drug candidates",
    x = "Disease Category",
    y = "Average Known Drug Hits"
  ) +
  theme_manuscript() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(fig17_data$Known_Drugs, na.rm = T) * 1.15))

ggsave(file.path(output_dir, "Fig17_Known_Drug_Recovery_by_Disease.pdf"), fig17, width = 11, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Fig17_Known_Drug_Recovery_by_Disease.png"), fig17, width = 11, height = 6, dpi = 300)

cat("✓ Figure 17 saved: Known Drug Recovery by Disease Type\n")

# ============================================================================
# SUMMARY TABLE
# ============================================================================

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("DISEASE-TYPE-SPECIFIC ANALYSIS SUMMARY\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("PIPELINE RECOMMENDATIONS BY DISEASE CATEGORY:\n")
cat(paste(rep("-", 80), collapse = ""), "\n")

summary_table <- recommendations %>%
  select(disease_category, N_Diseases, TAHOE_Avg_Hits, CMAP_Avg_Hits, Recommendation)

for (i in 1:nrow(summary_table)) {
  row <- summary_table[i,]
  cat(sprintf("\n%s (n=%d diseases)\n", row$disease_category, row$N_Diseases))
  cat(sprintf("  TAHOE: %.1f avg hits | CMAP: %.1f avg hits\n", 
              row$TAHOE_Avg_Hits, row$CMAP_Avg_Hits))
  cat(sprintf("  RECOMMENDATION: %s\n", row$Recommendation))
}

cat("\n\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("WHEN TO USE BOTH PIPELINES:\n")
cat(paste(rep("-", 80), collapse = ""), "\n")

both_recommended <- recommendations %>% filter(str_detect(Recommendation, "BOTH"))
if (nrow(both_recommended) > 0) {
  for (i in 1:nrow(both_recommended)) {
    row <- both_recommended[i,]
    cat(sprintf("\n✓ %s\n", row$disease_category))
    cat(sprintf("  - Both pipelines have similar effectiveness\n"))
    cat(sprintf("  - Combined approach maximizes candidate discovery\n"))
  }
}

cat("\n\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

EOF
