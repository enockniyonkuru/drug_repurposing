#!/usr/bin/env Rscript

# Combined Two-Panel Figure: Fig13B and Fig16B
# Panel A: Pipeline Strength by Disease Category (Known Drugs Only)
# Panel B: Pipeline Decision Matrix (Known Drugs Only)

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(reshape2)
library(patchwork)
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
file_path <- "tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx"
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
output_dir <- "tahoe_cmap_analysis/figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ============================================================================
# PANEL A: Pipeline Strength by Disease Category (KNOWN DRUGS ONLY)
# ============================================================================

cat("Creating Panel A: Pipeline Strength - Known Drugs Only\n")

perf_by_cat_known <- df %>%
  group_by(disease_category) %>%
  summarise(
    N_Diseases = n(),
    TAHOE_Known_Drugs_Mean = mean(tahoe_in_known_count, na.rm = TRUE),
    TAHOE_Known_Drugs_SE = sd(tahoe_in_known_count, na.rm = TRUE) / sqrt(n()),
    CMAP_Known_Drugs_Mean = mean(cmap_in_known_count, na.rm = TRUE),
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

p_panel_a <- ggplot(fig13b_data, aes(x = reorder(disease_category, Mean, FUN = function(x) max(x)), 
                                  y = Mean, fill = Pipeline)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.6) +
  geom_errorbar(aes(ymin = Mean - SE, ymax = Mean + SE), 
                position = position_dodge(0.9), width = 0.2, linewidth = 0.5) +
  scale_fill_manual(values = c("TAHOE" = "#5DADE2", "CMAP" = "#F39C12"),
                    labels = c("TAHOE" = "TAHOE", "CMAP" = "CMAP")) +
  labs(
    title = "A: Pipeline Strength by Disease Category",
    subtitle = "Average known drug hits (error bars: SE)",
    x = "Disease Category",
    y = "Average Known Drug Hits"
  ) +
  theme_manuscript() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, max(fig13b_data$Mean + fig13b_data$SE, na.rm = T) * 1.15))

cat("✓ Panel A created\n")

# ============================================================================
# PANEL B: Decision Matrix (KNOWN DRUGS ONLY)
# ============================================================================

cat("Creating Panel B: Pipeline Decision Matrix - Known Drugs Only\n")

recommendations_known <- perf_by_cat_known %>%
  mutate(
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

p_panel_b <- ggplot(fig16b_data, aes(x = TAHOE_Known_Drugs_Mean, y = CMAP_Known_Drugs_Mean, 
                                  size = N_Diseases, color = Recommendation, fill = Recommendation)) +
  geom_point(alpha = 0.7, stroke = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.8) +
  scale_color_manual(values = rec_colors, name = "Recommendation") +
  scale_fill_manual(values = rec_colors, name = "Recommendation") +
  scale_size_continuous(name = "Num. Diseases", range = c(3, 12)) +
  ggrepel::geom_text_repel(aes(label = disease_category), size = 3.5, fontface = "bold", 
                  color = "#1A1A1A", box.padding = 0.5, point.padding = 0.3,
                  min.segment.length = 0, segment.size = 0.5, segment.color = "gray70",
                  force = 2, max.overlaps = Inf) +
  labs(
    title = "B: Pipeline Selection Matrix",
    subtitle = "When to use TAHOE, CMAP, or both (diagonal = equal performance)",
    x = "TAHOE Average Known Drug Hits",
    y = "CMAP Average Known Drug Hits"
  ) +
  theme_manuscript() +
  theme(legend.box = "vertical", legend.position = "right") +
  scale_x_continuous(limits = c(0, max(fig16b_data$TAHOE_Known_Drugs_Mean, na.rm = TRUE) * 1.15)) +
  scale_y_continuous(limits = c(0, max(fig16b_data$CMAP_Known_Drugs_Mean, na.rm = TRUE) * 1.15))

cat("✓ Panel B created\n")

# ============================================================================
# COMBINE INTO TWO-PANEL FIGURE
# ============================================================================

combined_plot <- (p_panel_a | p_panel_b) +
  plot_annotation(
    title = "Known Drug Recovery Pipeline Analysis: Strength and Recommendations",
    subtitle = "Panel A shows average known drug hits; Panel B shows decision matrix for pipeline selection",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 5)),
      plot.subtitle = element_text(size = 12, color = "#333", hjust = 0.5, margin = margin(b = 15)),
      plot.background = element_rect(fill = "white", color = NA)
    )
  )

# Save combined plot
ggsave(
  file.path(output_dir, "Fig13B_16B_combined_known_drugs_analysis.png"),
  combined_plot,
  width = 16,
  height = 7,
  dpi = 300,
  bg = "white"
)

# Save PDF version
ggsave(
  file.path(output_dir, "Fig13B_16B_combined_known_drugs_analysis.pdf"),
  combined_plot,
  width = 16,
  height = 7,
  dpi = 300,
  bg = "white"
)

cat("✓ Combined Two-Panel Figure created!\n\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║     KNOWN DRUG RECOVERY ANALYSIS - PANEL SUMMARY              ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("PANEL A: Pipeline Strength Statistics\n")
cat(sprintf("  Total Disease Categories: %d\n", nrow(perf_by_cat_known)))
cat(sprintf("  TAHOE Mean Known Drugs: %.2f (SD=%.2f)\n", 
            mean(perf_by_cat_known$TAHOE_Known_Drugs_Mean, na.rm = TRUE),
            sd(perf_by_cat_known$TAHOE_Known_Drugs_Mean, na.rm = TRUE)))
cat(sprintf("  CMAP Mean Known Drugs:  %.2f (SD=%.2f)\n\n", 
            mean(perf_by_cat_known$CMAP_Known_Drugs_Mean, na.rm = TRUE),
            sd(perf_by_cat_known$CMAP_Known_Drugs_Mean, na.rm = TRUE)))

cat("PANEL B: Recommendation Distribution\n")
for (rec in unique(recommendations_known$Recommendation)) {
  count <- sum(recommendations_known$Recommendation == rec)
  cat(sprintf("  • %s: %d categories\n", rec, count))
}

cat("\n\nCOLOR SCHEME:\n")
cat("  Panel A: TAHOE = #5DADE2 (Blue), CMAP = #F39C12 (Orange)\n")
cat("  Panel B: Use TAHOE Only = #2E86AB\n")
cat("           Use CMAP Only = #A23B72\n")
cat("           Use BOTH = #F18F01\n")
cat("           Primary + Secondary = #C73E1D\n\n")

cat("FILES CREATED:\n")
cat("  • Fig13B_16B_combined_known_drugs_analysis.png (16\" × 7\", 300 DPI)\n")
cat("  • Fig13B_16B_combined_known_drugs_analysis.pdf (16\" × 7\", 300 DPI)\n\n")

cat("✓ Combined analysis generated successfully!\n")
cat(sprintf("✓ Saved to: %s\n", output_dir))
