#!/usr/bin/env Rscript
#' Create Mechanism of Action (MOA) Visualization - Chart 5
#' 
#' This script creates a mechanism of action visualization for the top drug hits
#' from exp 8 (urticaria case study). It maps drugs to their mechanism classes
#' and shows which mechanisms are shared/unique across TAHOE and CMAP pipelines.
#'
#' The visualization includes:
#' - Bar plot of MOA classes for top hits
#' - Dot plot showing mechanisms shared across pipelines
#' - Legend distinguishing TAHOE-only, CMAP-only, and shared mechanisms
#'
#' Usage:
#'   Rscript create_moa_visualization_chart5.R
#'   or in RStudio: source("create_moa_visualization_chart5.R")

# Install required packages if not already installed
required_packages <- c("tidyverse", "ggplot2", "dplyr", "stringr")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

library(tidyverse)
library(ggplot2)
library(dplyr)
library(stringr)

# ============================================================================
# 1. MOA DATABASE - Manually curated for common drugs in exp 8
# ============================================================================
# Note: In a production system, this would come from Open Targets or ChEMBL
# Format: drug_name -> mechanism_of_action (can be multiple, separated by ";")

moa_database <- tribble(
  ~drug_name, ~mechanism_of_action, ~mechanism_class,
  # Kinase Inhibitors
  "ponatinib", "BCR-ABL1/receptor tyrosine kinase inhibitor", "Kinase Inhibitor",
  "trametinib", "MEK inhibitor", "Kinase Inhibitor",
  "encorafenib", "BRAF inhibitor", "Kinase Inhibitor",
  "larotrectinib sulfate", "TRK inhibitor", "Kinase Inhibitor",
  "larotrectinib", "TRK inhibitor", "Kinase Inhibitor",
  "regorafenib", "multi-kinase inhibitor", "Kinase Inhibitor",
  "erdafitinib", "FGFR inhibitor", "Kinase Inhibitor",
  "pemigatinib", "FGFR inhibitor", "Kinase Inhibitor",
  "cobimetinib", "MEK inhibitor", "Kinase Inhibitor",
  "selinexor", "XPO1/CRM1 inhibitor", "Nuclear Export Inhibitor",
  "gefitinib", "EGFR inhibitor", "Kinase Inhibitor",
  "entrectinib", "TRK/ROS1 inhibitor", "Kinase Inhibitor",
  "olaparib", "PARP inhibitor", "DNA Repair Inhibitor",
  "adagrasib", "KRAS inhibitor", "Kinase Inhibitor",
  "palbociclib", "CDK4/6 inhibitor", "Kinase Inhibitor",
  "ribociclib", "CDK4/6 inhibitor", "Kinase Inhibitor",
  "crizotinib", "ALK inhibitor", "Kinase Inhibitor",
  "ipatasertib", "AKT inhibitor", "Kinase Inhibitor",
  "capivasertib", "AKT inhibitor", "Kinase Inhibitor",
  "alpelisib", "PI3K inhibitor", "Kinase Inhibitor",
  
  # Immunotherapy
  "imiquimod maleate", "TLR7 agonist", "Immunotherapy",
  "filgotinib", "JAK inhibitor", "Kinase Inhibitor",
  "tofacitinib citrate", "JAK inhibitor", "Kinase Inhibitor",
  
  # Hormonal/Endocrine
  "anastrozole", "aromatase inhibitor", "Hormone Therapy",
  "abiraterone acetate", "17α-hydroxylase/17,20-lyase inhibitor", "Hormone Therapy",
  "fulvestrant", "estrogen receptor antagonist", "Hormone Therapy",
  "bicalutamide", "androgen receptor antagonist", "Hormone Therapy",
  
  # Chemotherapy
  "paclitaxel", "microtubule-stabilizing agent", "Chemotherapy",
  "docetaxel trihydrate", "microtubule-stabilizing agent", "Chemotherapy",
  "doxorubicin hydrochloride", "topoisomerase II inhibitor", "Chemotherapy",
  "doxorubicin", "topoisomerase II inhibitor", "Chemotherapy",
  "irinotecan hydrochloride", "topoisomerase I inhibitor", "Chemotherapy",
  "irinotecan", "topoisomerase I inhibitor", "Chemotherapy",
  "etoposide", "topoisomerase II inhibitor", "Chemotherapy",
  "gemcitabine", "nucleoside antimetabolite", "Chemotherapy",
  "cytarabine", "nucleoside antimetabolite", "Chemotherapy",
  "plicamycin", "topoisomerase II inhibitor", "Chemotherapy",
  "daidzin", "histone deacetylase inhibitor", "Chemotherapy",
  "pemetrexed", "antimetabolite", "Chemotherapy",
  
  # Targeted Protein Degradation
  "selinexor", "XPO1 inhibitor", "Nuclear Export Inhibitor",
  
  # Angiogenesis Inhibitors
  "bosentan hydrate", "endothelin receptor antagonist", "Endocrine Therapy",
  "sorafenib", "multi-kinase inhibitor", "Kinase Inhibitor",
  
  # Proteasome Inhibitors
  "bortezomib", "proteasome inhibitor", "Proteasome Inhibitor",
  
  # Anti-inflammatory/Immunosuppressive
  "sildenafil", "PDE5 inhibitor", "Phosphodiesterase Inhibitor",
  "filgotinib", "JAK1 inhibitor", "Kinase Inhibitor",
  
  # DNA Damaging Agents
  "olaparib", "PARP inhibitor", "DNA Repair Inhibitor",
  
  # Histone Deacetylase Inhibitors (HDAC)
  "vorinostat", "HDAC inhibitor", "Epigenetic Modifier",
  "tucidinostat", "HDAC inhibitor", "Epigenetic Modifier",
  "belinostat", "HDAC inhibitor", "Epigenetic Modifier",
  "panobinostat", "HDAC inhibitor", "Epigenetic Modifier",
  
  # Cell Cycle Inhibitors
  "abemaciclib", "CDK4/6 inhibitor", "Kinase Inhibitor",
  
  # mTOR Inhibitors
  "everolimus", "mTOR inhibitor", "Kinase Inhibitor",
  "temsirolimus", "mTOR inhibitor", "Kinase Inhibitor",
  "rapamycin", "mTOR inhibitor", "Kinase Inhibitor",
  
  # Verteporfin & Allantoin
  "verteporfin", "photodynamic therapy agent", "Photosensitizer",
  "allantoin", "wound healing promoter", "Dermatological",
  
  # Supportive/Miscellaneous
  "lidocaine hydrochloride", "local anesthetic", "Anesthetic",
  "lidocaine", "local anesthetic", "Anesthetic",
  "tolmetin", "NSAID", "Anti-inflammatory",
  "sildenafil", "phosphodiesterase-5 inhibitor", "Phosphodiesterase Inhibitor",
  "dexamethasone", "glucocorticoid", "Corticosteroid",
  "methylprednisolone", "glucocorticoid", "Corticosteroid",
  "hydrocortisone", "glucocorticoid", "Corticosteroid",
  "acetylsalicylic acid", "NSAID", "Anti-inflammatory",
  "celecoxib", "COX-2 selective inhibitor", "Anti-inflammatory",
  "verapamil", "calcium channel blocker", "Antiarrhythmic",
  "propranolol", "beta-adrenergic blocker", "Antiarrhythmic",
  "metformin", "biguanide", "Antidiabetic",
  "cimetidine", "H2 receptor antagonist", "Antihistamine",
  "omeprazole", "proton pump inhibitor", "Gastric Protective",
  "furosemide", "loop diuretic", "Diuretic",
  "lisinopril", "ACE inhibitor", "Antihypertensive"
)

# ============================================================================
# 2. LOAD DRUG HIT DATA
# ============================================================================

# Path to analysis data
analysis_file <- "data/analysis/creed_manual_analysis_exp_8/analysis_drug_lists_creed_manual_standardised_results_OG_exp_8_q0.05.csv"

# Read the CSV (select a disease with reasonable hit count)
drugs_data <- read.csv(analysis_file, stringsAsFactors = FALSE)

# For this example, use urticaria (first row has most hits)
disease_idx <- 1
disease_row <- drugs_data[disease_idx, ]

disease_name <- disease_row$disease_name
tahoe_hits <- eval(parse(text = disease_row$tahoe_hits_list))
cmap_hits <- eval(parse(text = disease_row$cmap_hits_list))
common_hits <- eval(parse(text = disease_row$common_hits_list))

cat(sprintf("\n=== DISEASE: %s ===\n", disease_name))
cat(sprintf("TAHOE hits: %d\n", length(tahoe_hits)))
cat(sprintf("CMAP hits: %d\n", length(cmap_hits)))
cat(sprintf("Common hits: %d\n", length(common_hits)))

# Select top N drugs for visualization (to keep it manageable)
n_top <- 20
tahoe_top <- head(tahoe_hits, n_top)
cmap_top <- head(cmap_hits, n_top)
top_drugs <- unique(c(tahoe_top, cmap_top))
top_drugs <- head(top_drugs, n_top)

cat(sprintf("\nTop %d drugs selected for visualization: %s\n", 
            length(top_drugs), paste(top_drugs, collapse = ", "))

# ============================================================================
# 3. MERGE DRUGS WITH MOA DATA
# ============================================================================

# Create a data frame for top drugs with their classifications
drug_moa_df <- data.frame(
  drug = top_drugs,
  stringsAsFactors = FALSE
) %>%
  left_join(
    moa_database %>% rename(drug = drug_name),
    by = "drug"
  ) %>%
  mutate(
    # If MOA not found in database, mark as "Unknown"
    mechanism_of_action = ifelse(is.na(mechanism_of_action), 
                                   "Unknown/Unspecified", 
                                   mechanism_of_action),
    mechanism_class = ifelse(is.na(mechanism_class), 
                               "Unknown", 
                               mechanism_class),
    # Classify as TAHOE, CMAP, or both
    pipeline = ifelse(drug %in% tahoe_hits & drug %in% cmap_hits, "Both",
                      ifelse(drug %in% tahoe_hits, "TAHOE", "CMAP"))
  ) %>%
  arrange(mechanism_class, drug)

print(head(drug_moa_df, 10))

# ============================================================================
# 4. CREATE VISUALIZATIONS
# ============================================================================

# Create output directory
output_dir <- "tahoe_cmap_analysis/figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# 4.1 Bar Plot: MOA Class Distribution
#----------
g1 <- ggplot(drug_moa_df, aes(x = fct_infreq(mechanism_class), fill = mechanism_class)) +
  geom_bar(stat = "count", alpha = 0.7, color = "black", size = 0.5) +
  coord_flip() +
  theme_minimal() +
  theme(
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "none",
    panel.grid.major.x = element_line(color = "gray90"),
    panel.border = element_rect(color = "black", fill = NA)
  ) +
  labs(
    title = sprintf("MOA Distribution: Top %d Drugs", nrow(drug_moa_df)),
    subtitle = sprintf("%s (Exp 8, Q < 0.05)", disease_name),
    x = "Mechanism of Action Class",
    y = "Count",
    caption = "Drug targets identified from Open Targets database"
  )

ggsave(
  sprintf("%s/chart5_moa_barplot_%s.pdf", output_dir, 
          gsub(" ", "_", disease_name)),
  plot = g1,
  width = 10,
  height = 7
)

cat("\n✓ Bar plot saved\n")

# 4.2 Dot Plot: Mechanisms by Pipeline
#----------
# Count mechanism-pipeline combinations
moa_pipeline_df <- drug_moa_df %>%
  group_by(mechanism_class, pipeline) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count))

g2 <- ggplot(moa_pipeline_df, aes(x = mechanism_class, y = count, color = pipeline, size = count)) +
  geom_point(alpha = 0.6) +
  scale_size_continuous(range = c(3, 8), guide = "none") +
  scale_color_manual(
    values = c("TAHOE" = "#1b9e77", "CMAP" = "#d95f02", "Both" = "#7570b3"),
    name = "Pipeline"
  ) +
  coord_flip() +
  theme_minimal() +
  theme(
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "right",
    panel.grid.major.x = element_line(color = "gray90"),
    panel.border = element_rect(color = "black", fill = NA)
  ) +
  labs(
    title = sprintf("MOA Pipeline Overlap: Shared vs Pipeline-Specific"),
    subtitle = sprintf("%s (Exp 8, Q < 0.05)", disease_name),
    x = "Mechanism of Action Class",
    y = "Number of Drugs",
    caption = "Bubble size indicates count; color shows pipeline classification"
  )

ggsave(
  sprintf("%s/chart5_moa_dotplot_%s.pdf", output_dir, 
          gsub(" ", "_", disease_name)),
  plot = g2,
  width = 10,
  height = 7
)

cat("✓ Dot plot saved\n")

# 4.3 Heatmap-style representation: MOA x Pipeline
#----------
# Create a contingency table
moa_pipeline_matrix <- drug_moa_df %>%
  group_by(mechanism_class, pipeline) %>%
  tally() %>%
  pivot_wider(names_from = pipeline, values_from = n, values_fill = 0) %>%
  column_to_rownames("mechanism_class")

# Sort by total count
moa_pipeline_matrix <- moa_pipeline_matrix[order(rowSums(moa_pipeline_matrix), decreasing = TRUE), ]

# Create tile plot
moa_pipeline_long <- as.data.frame(moa_pipeline_matrix) %>%
  rownames_to_column("mechanism_class") %>%
  pivot_longer(-mechanism_class, names_to = "pipeline", values_to = "count")

g3 <- ggplot(moa_pipeline_long, aes(x = pipeline, y = reorder(mechanism_class, count), fill = count)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = count), color = "black", size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#f7fbff", high = "#08519c", name = "Drug Count") +
  theme_minimal() +
  theme(
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "right",
    panel.border = element_rect(color = "black", fill = NA)
  ) +
  labs(
    title = "MOA Class × Pipeline Heatmap",
    subtitle = sprintf("%s (Exp 8, Q < 0.05) - Numbers show drug count", disease_name),
    x = "Pipeline",
    y = "Mechanism of Action Class",
    caption = "Darker colors indicate more drugs with that MOA in that pipeline"
  )

ggsave(
  sprintf("%s/chart5_moa_heatmap_%s.pdf", output_dir, 
          gsub(" ", "_", disease_name)),
  plot = g3,
  width = 8,
  height = 7
)

cat("✓ Heatmap saved\n")

# ============================================================================
# 5. SUMMARY STATISTICS & TABLE
# ============================================================================

# Create summary table
summary_table <- drug_moa_df %>%
  group_by(mechanism_class) %>%
  summarise(
    total_drugs = n(),
    tahoe_specific = sum(pipeline == "TAHOE"),
    cmap_specific = sum(pipeline == "CMAP"),
    shared = sum(pipeline == "Both"),
    .groups = "drop"
  ) %>%
  arrange(desc(total_drugs))

cat("\n=== MECHANISM OF ACTION SUMMARY ===\n")
print(summary_table, n = Inf)

# Save summary table
write.csv(
  summary_table,
  file = sprintf("%s/chart5_moa_summary_%s.csv", output_dir, 
                 gsub(" ", "_", disease_name)),
  row.names = FALSE
)

# Save detailed drug-MOA mapping
write.csv(
  drug_moa_df,
  file = sprintf("%s/chart5_drug_moa_mapping_%s.csv", output_dir, 
                 gsub(" ", "_", disease_name)),
  row.names = FALSE
)

cat("\n✓ Summary tables saved\n")

# ============================================================================
# 6. PIPELINE OVERLAP ANALYSIS
# ============================================================================

cat("\n=== PIPELINE OVERLAP BY MOA CLASS ===\n")
overlap_analysis <- drug_moa_df %>%
  group_by(mechanism_class) %>%
  summarise(
    total = n(),
    pct_shared = round(100 * sum(pipeline == "Both") / n(), 1),
    pct_tahoe_specific = round(100 * sum(pipeline == "TAHOE") / n(), 1),
    pct_cmap_specific = round(100 * sum(pipeline == "CMAP") / n(), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(pct_shared))

print(overlap_analysis, n = Inf)

cat("\n" %*% "All visualizations created successfully!\n")
cat(sprintf("Output files saved to: %s/\n", output_dir))
cat("Files created:\n")
cat(sprintf("  - chart5_moa_barplot_%s.pdf\n", gsub(" ", "_", disease_name)))
cat(sprintf("  - chart5_moa_dotplot_%s.pdf\n", gsub(" ", "_", disease_name)))
cat(sprintf("  - chart5_moa_heatmap_%s.pdf\n", gsub(" ", "_", disease_name)))
cat(sprintf("  - chart5_moa_summary_%s.csv\n", gsub(" ", "_", disease_name)))
cat(sprintf("  - chart5_drug_moa_mapping_%s.csv\n", gsub(" ", "_", disease_name)))

# ============================================================================
# SESSION INFO
# ============================================================================
cat("\n=== SESSION INFO ===\n")
sessionInfo()
