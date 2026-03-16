#!/usr/bin/env Rscript
#' Simple Alternative Visualization Approaches - 5 Visualizations

library(tidyverse)
library(ggplot2)

base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special"

diseases <- data.frame(
  id = c("01_autoimmune_thrombocytopenic_purpura", "02_cerebral_palsy", "03_Eczema", 
         "04_chronic_lymphocytic_leukemia", "05_endometriosis_of_ovary"),
  name = c("ATP", "CP", "Eczema", "CLL", "Endometriosis"),
  stringsAsFactors = FALSE
)

cat("\n========================================\n")
cat("GENERATING ALTERNATIVE VISUALIZATIONS\n")
cat("========================================\n\n")

# Load and prepare data
all_data <- data.frame()
for (i in 1:nrow(diseases)) {
  disease_id <- diseases$id[i]
  disease_name <- diseases$name[i]
  
  cmap_file <- file.path(base_dir, disease_id, "results_pipeline/cmap", paste0("cmap_results_", disease_id, ".csv"))
  tahoe_file <- file.path(base_dir, disease_id, "results_pipeline/tahoe", paste0("tahoe_results_", disease_id, ".csv"))
  
  cmap_df <- if (file.exists(cmap_file)) read.csv(cmap_file, stringsAsFactors = FALSE) else NULL
  tahoe_df <- if (file.exists(tahoe_file)) read.csv(tahoe_file, stringsAsFactors = FALSE) else NULL
  
  cmap_drugs <- if (!is.null(cmap_df)) tolower(unique(cmap_df$drug_name)) else c()
  tahoe_drugs <- if (!is.null(tahoe_df)) tolower(unique(tahoe_df$drug_name)) else c()
  
  cmap_only <- length(setdiff(cmap_drugs, tahoe_drugs))
  tahoe_only <- length(setdiff(tahoe_drugs, cmap_drugs))
  both <- length(intersect(cmap_drugs, tahoe_drugs))
  
  all_data <- rbind(all_data, data.frame(
    Disease = disease_name,
    CMap_Only = cmap_only,
    TAHOE_Only = tahoe_only,
    Both = both,
    CMap_Total = length(cmap_drugs),
    TAHOE_Total = length(tahoe_drugs),
    Union = length(union(cmap_drugs, tahoe_drugs))
  ))
}

cat("DATA SUMMARY:\n")
print(all_data)
cat("\n")

# ============================================
# VIZ 1: Stacked Bars
# ============================================
cat("Creating: Stacked Bar Chart\n")
stacked_data <- all_data %>%
  pivot_longer(cols = c(CMap_Only, TAHOE_Only, Both), 
               names_to = "Category", values_to = "Count")

p1 <- ggplot(stacked_data, aes(x = reorder(Disease, Union), y = Count, fill = Category)) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_manual(values = c("CMap_Only" = "#3498DB", "TAHOE_Only" = "#E74C3C", "Both" = "#2ECC71")) +
  coord_flip() +
  labs(title = "Drug Hit Composition", x = "", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(size = 13, face = "bold"))

ggsave(file.path(base_dir, "viz_01_stacked.png"), p1, width = 9, height = 6, dpi = 150)
cat("  ✓ viz_01_stacked.png\n\n")

# ============================================
# VIZ 2: Side-by-side Bars
# ============================================
cat("Creating: Side-by-Side Bars\n")
comparison_data <- all_data %>%
  select(Disease, CMap_Total, TAHOE_Total) %>%
  pivot_longer(cols = c(CMap_Total, TAHOE_Total), names_to = "Platform", values_to = "Hits") %>%
  mutate(Platform = gsub("_Total", "", Platform))

p2 <- ggplot(comparison_data, aes(x = reorder(Disease, -Hits), y = Hits, fill = Platform)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  scale_fill_manual(values = c("CMap" = "#3498DB", "TAHOE" = "#E74C3C")) +
  geom_text(aes(label = Hits), position = position_dodge(width = 0.9), vjust = -0.3, size = 3) +
  labs(title = "Platform Comparison: Total Hits", x = "", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(size = 13, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(base_dir, "viz_02_sidebyside.png"), p2, width = 9, height = 6, dpi = 150)
cat("  ✓ viz_02_sidebyside.png\n\n")

# ============================================
# VIZ 3: Overlap Percentage
# ============================================
cat("Creating: Overlap Percentage\n")
overlap_data <- all_data %>%
  mutate(Overlap_Pct = 100 * Both / Union) %>%
  arrange(Overlap_Pct)

p3 <- ggplot(overlap_data, aes(x = reorder(Disease, Overlap_Pct), y = Overlap_Pct, fill = Disease)) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_manual(values = c("ATP" = "#E74C3C", "CP" = "#3498DB", "Eczema" = "#9B59B6", 
                               "CLL" = "#E67E22", "Endometriosis" = "#1ABC9C"), guide = "none") +
  geom_text(aes(label = sprintf("%.0f%%", Overlap_Pct)), vjust = -0.3, size = 3.5) +
  labs(title = "Platform Agreement", x = "", y = "Overlap (%)") +
  ylim(0, 100) +
  coord_flip() +
  theme_minimal() +
  theme(plot.title = element_text(size = 13, face = "bold"))

ggsave(file.path(base_dir, "viz_03_overlap_pct.png"), p3, width = 9, height = 6, dpi = 150)
cat("  ✓ viz_03_overlap_pct.png\n\n")

# ============================================
# VIZ 4: Scatter Plot
# ============================================
cat("Creating: Scatter Plot with Bubble Size\n")
p4 <- ggplot(all_data, aes(x = CMap_Total, y = TAHOE_Total, size = Both, color = Disease)) +
  geom_point(alpha = 0.6) +
  geom_text(aes(label = Disease), vjust = -1, size = 3, show.legend = FALSE) +
  scale_size_continuous(name = "Overlap", range = c(4, 12)) +
  scale_color_manual(values = c("ATP" = "#E74C3C", "CP" = "#3498DB", "Eczema" = "#9B59B6", 
                                "CLL" = "#E67E22", "Endometriosis" = "#1ABC9C"), guide = "none") +
  labs(title = "CMap vs TAHOE Relationship", x = "CMap Total", y = "TAHOE Total",
       subtitle = "Bubble size = Platform overlap") +
  theme_minimal() +
  theme(plot.title = element_text(size = 13, face = "bold"),
        plot.subtitle = element_text(size = 10))

ggsave(file.path(base_dir, "viz_04_scatter.png"), p4, width = 8, height = 7, dpi = 150)
cat("  ✓ viz_04_scatter.png\n\n")

# ============================================
# VIZ 5: Faceted Breakdown
# ============================================
cat("Creating: Faceted Breakdown by Disease\n")
facet_data <- all_data %>%
  pivot_longer(cols = c(CMap_Only, TAHOE_Only, Both), names_to = "Category", values_to = "Count") %>%
  mutate(Category = factor(Category, levels = c("CMap_Only", "TAHOE_Only", "Both"),
                           labels = c("CMap", "TAHOE", "Both")))

p5 <- ggplot(facet_data, aes(x = Category, y = Count, fill = Category)) +
  geom_bar(stat = "identity", color = "black") +
  geom_text(aes(label = Count), vjust = -0.2, size = 3) +
  scale_fill_manual(values = c("CMap" = "#3498DB", "TAHOE" = "#E74C3C", "Both" = "#2ECC71"), guide = "none") +
  facet_wrap(~reorder(Disease, -Count)) +
  labs(title = "Drug Breakdown by Disease", x = "", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(size = 13, face = "bold"))

ggsave(file.path(base_dir, "viz_05_faceted.png"), p5, width = 12, height = 6, dpi = 150)
cat("  ✓ viz_05_faceted.png\n\n")

cat("========================================\n")
cat("SUCCESS: All visualizations created!\n")
cat("========================================\n\n")
cat("RECOMMENDED FOR PUBLICATION:\n")
cat("  Primary:   viz_02_sidebyside.png\n")
cat("  Secondary: viz_03_overlap_pct.png\n")
cat("  Optional:  viz_05_faceted.png\n\n")
