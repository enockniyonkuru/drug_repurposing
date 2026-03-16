#!/usr/bin/env Rscript
#' Case Study Extraction and Analysis Pipeline
#' 
#' Automates all 9 steps of case study extraction for 5 diseases:
#' 1. Extract disease signatures (raw, standardized)
#' 2. Create volcano plots and gene count plots
#' 3. Extract pipeline results
#' 4. Compute hit statistics
#' 5. Create top 10 hits bar plots
#' 6. Create Venn diagrams
#' 7. Create MOA comparison plots
#' 8. Create known drug rank comparison plots
#' 9. Create summary text files

library(tidyverse)
library(ggplot2)
library(venn)
library(ggrepel)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Base directories
base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis"
case_study_dir <- file.path(base_dir, "case_study_special")
sig_raw_dir <- file.path(base_dir, "data/disease_signatures/creeds_manual_disease_signatures")
sig_std_dir <- file.path(base_dir, "data/disease_signatures/creeds_manual_disease_signatures_standardised")
sig_plots_dir <- file.path(base_dir, "data/disease_signatures/creeds_manual_disease_signatures_plots")
analysis_dir <- file.path(base_dir, "data/analysis/creed_manual_analysis_exp_8")
results_base_dir <- file.path(base_dir, "results/creed_manual_standardised_results_OG_exp_8")

# Five case study diseases
diseases <- data.frame(
  id = c("01_autoimmune_thrombocytopenic_purpura", 
         "02_cerebral_palsy", 
         "03_Eczema", 
         "04_chronic_lymphocytic_leukemia", 
         "05_endometriosis_of_ovary"),
  name_raw = c("autoimmune_thrombocytopenic_purpura",
               "cerebral_palsy",
               "Eczema",
               "chronic_lymphocytic_leukemia",
               "endometriosis_of_ovary"),
  name_std = c("autoimmune_thrombocytopenic_purpura",
               "cerebral_palsy",
               "Eczema",
               "chronic_lymphocytic_leukemia",
               "endometriosis_of_ovary"),
  stringsAsFactors = FALSE
)

# MOA database (from Chart 5 work)
moa_database <- tribble(
  ~drug_name, ~mechanism_of_action, ~mechanism_class,
  "acetylsalicylic acid", "COX inhibitor", "Anti-inflammatory",
  "amiodarone", "Antiarrhythmic", "Cardiovascular",
  "baclofen", "GABA-B agonist", "Neurological",
  "bendroflumethiazide", "Diuretic", "Cardiovascular",
  "benzonatate", "Local anesthetic", "Other",
  "benzthiazide", "Diuretic", "Cardiovascular",
  "bisacodyl", "Laxative", "Other",
  "bupropion", "Norepinephrine-dopamine reuptake inhibitor", "Neurological",
  "buspirone", "5-HT1A agonist", "Neurological",
  "capsaicin", "TRPV1 agonist", "Anti-inflammatory",
  "dexamethasone", "Glucocorticoid receptor agonist", "Hormone Therapy",
  "estrogen", "Estrogen receptor agonist", "Hormone Therapy",
  "hydrocortisone", "Glucocorticoid receptor agonist", "Hormone Therapy",
  "ibuprofen", "COX inhibitor", "Anti-inflammatory",
  "methotrexate", "DHFR inhibitor", "Chemotherapy",
  "warfarin", "Vitamin K antagonist", "Cardiovascular",
  "aspirin", "COX inhibitor", "Anti-inflammatory",
  "geldanamycin", "HSP90 inhibitor", "Chemotherapy",
  "staurosporine", "Kinase inhibitor", "Kinase Inhibitor",
  "tamoxifen", "Estrogen receptor antagonist", "Hormone Therapy",
  "trichostatin A", "HDAC inhibitor", "Epigenetic Modifier",
  "vorinostat", "HDAC inhibitor", "Epigenetic Modifier",
  "anisomycin", "Translation inhibitor", "Chemotherapy",
  "cycloheximide", "Translation inhibitor", "Chemotherapy",
  "tunicamycin", "N-glycosylation inhibitor", "Other",
  "dexamethasone acetate", "Glucocorticoid receptor agonist", "Hormone Therapy",
  "theophylline", "Phosphodiesterase inhibitor", "Other",
  "caffeine", "Phosphodiesterase inhibitor", "Other",
  "penicillin G", "Beta-lactam antibiotic", "Other",
  "tetracycline", "Protein synthesis inhibitor", "Other"
) %>%
  mutate(drug_name = tolower(drug_name))

# Known drugs for each disease (placeholder - expand as needed)
known_drugs <- list(
  "autoimmune_thrombocytopenic_purpura" = c("dexamethasone", "hydrocortisone", "methotrexate"),
  "cerebral_palsy" = c("baclofen", "diazepam"),
  "Eczema" = c("hydrocortisone", "betamethasone", "tacrolimus"),
  "chronic_lymphocytic_leukemia" = c("fludarabine", "rituximab", "ibrutinib"),
  "endometriosis_of_ovary" = c("leuprolide", "norethindrone", "dienogest")
)

# Q-value threshold for significance
q_threshold <- 0.05

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

#' Create all necessary directories
create_dirs <- function(disease_id) {
  disease_dir <- file.path(case_study_dir, disease_id)
  dirs <- c(
    file.path(disease_dir, "signature"),
    file.path(disease_dir, "results_pipeline/cmap"),
    file.path(disease_dir, "results_pipeline/tahoe"),
    file.path(disease_dir, "figures")
  )
  sapply(dirs, function(d) {
    if (!dir.exists(d)) {
      dir.create(d, recursive = TRUE, showWarnings = FALSE)
    }
  })
}

#' Find result directory with wildcard matching
find_result_dir <- function(disease_name, platform) {
  pattern <- paste0("^", disease_name, "_", platform, "_")
  dirs <- list.dirs(results_base_dir, recursive = FALSE, full.names = TRUE)
  matching <- dirs[grepl(pattern, basename(dirs))]
  if (length(matching) > 0) {
    return(matching[1])  # Return first match
  }
  return(NULL)
}

#' Read and standardize signature files
read_signature <- function(filepath) {
  if (!file.exists(filepath)) {
    return(NULL)
  }
  tryCatch({
    df <- read.csv(filepath, stringsAsFactors = FALSE)
    df
  }, error = function(e) {
    cat("Error reading", filepath, ":", conditionMessage(e), "\n")
    return(NULL)
  })
}

#' Compute signature summary statistics
compute_signature_stats <- function(raw_sig, std_sig, disease_name) {
  raw_total <- nrow(raw_sig)
  raw_up <- sum(raw_sig[, ncol(raw_sig)] > 0, na.rm = TRUE)
  raw_down <- sum(raw_sig[, ncol(raw_sig)] < 0, na.rm = TRUE)
  
  std_total <- nrow(std_sig)
  std_up <- sum(std_sig[, ncol(std_sig)] > 0, na.rm = TRUE)
  std_down <- sum(std_sig[, ncol(std_sig)] < 0, na.rm = TRUE)
  
  data.frame(
    disease_name = disease_name,
    genes_initial_total = raw_total,
    genes_initial_up = raw_up,
    genes_initial_down = raw_down,
    genes_final_total = std_total,
    genes_final_up = std_up,
    genes_final_down = std_down,
    stringsAsFactors = FALSE
  )
}

#' Create volcano plot
create_volcano_plot <- function(std_sig, output_path) {
  # Assume columns: gene names, logFC, p-value
  # Adjust column indices based on your file structure
  
  if (ncol(std_sig) < 3) {
    warning("Insufficient columns for volcano plot")
    return(FALSE)
  }
  
  logFC_col <- which(grepl("logfc|log_fc|log_fold|fc", names(std_sig), ignore.case = TRUE))[1]
  pval_col <- which(grepl("pval|p_val|p.value|p-value", names(std_sig), ignore.case = TRUE))[1]
  
  if (is.na(logFC_col)) logFC_col <- 2
  if (is.na(pval_col)) pval_col <- 3
  
  df <- data.frame(
    logFC = std_sig[[logFC_col]],
    pval = std_sig[[pval_col]],
    stringsAsFactors = FALSE
  )
  
  df$neg_log_pval <- -log10(df$pval + 1e-300)
  df$direction <- ifelse(df$logFC > 0, "up", "down")
  
  # Remove infinite values
  df <- df %>%
    filter(is.finite(neg_log_pval) & is.finite(logFC))
  
  p <- ggplot(df, aes(x = logFC, y = neg_log_pval, color = direction)) +
    geom_point(alpha = 0.6, size = 2) +
    scale_color_manual(values = c("up" = "#d73027", "down" = "#4575b4")) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      text = element_text(size = 11)
    ) +
    labs(
      x = "Log Fold Change",
      y = "-Log10(P-value)",
      color = "Direction",
      title = "Volcano Plot"
    )
  
  ggsave(output_path, p, width = 8, height = 6, dpi = 300)
  return(TRUE)
}

#' Create gene count bar plot
create_gene_count_plot <- function(std_sig, output_path) {
  logFC_col <- which(grepl("logfc|log_fc|log_fold|fc", names(std_sig), ignore.case = TRUE))[1]
  if (is.na(logFC_col)) logFC_col <- 2
  
  up_count <- sum(std_sig[[logFC_col]] > 0, na.rm = TRUE)
  down_count <- sum(std_sig[[logFC_col]] < 0, na.rm = TRUE)
  
  df <- data.frame(
    direction = c("Up-regulated", "Down-regulated"),
    count = c(up_count, down_count),
    stringsAsFactors = FALSE
  )
  
  p <- ggplot(df, aes(x = direction, y = count, fill = direction)) +
    geom_bar(stat = "identity", color = "black", size = 0.5) +
    scale_fill_manual(values = c("Up-regulated" = "#d73027", "Down-regulated" = "#4575b4")) +
    theme_minimal() +
    theme(
      legend.position = "none",
      text = element_text(size = 11)
    ) +
    labs(
      x = "",
      y = "Number of Genes",
      title = "Gene Count Distribution"
    ) +
    geom_text(aes(label = count), vjust = -0.5, size = 4)
  
  ggsave(output_path, p, width = 6, height = 5, dpi = 300)
  return(TRUE)
}

#' Extract results CSV from result directory
extract_results_csv <- function(result_dir) {
  if (is.null(result_dir) || !dir.exists(result_dir)) {
    return(NULL)
  }
  
  csv_files <- list.files(result_dir, pattern = "\\.csv$", full.names = TRUE)
  
  if (length(csv_files) == 0) {
    return(NULL)
  }
  
  # Prefer hits files
  hits_file <- csv_files[grepl("hits", csv_files)]
  if (length(hits_file) > 0) {
    return(read.csv(hits_file[1], stringsAsFactors = FALSE))
  }
  
  return(read.csv(csv_files[1], stringsAsFactors = FALSE))
}

#' Extract images from result directory
extract_images <- function(result_dir, platform, disease_id, output_dir) {
  if (is.null(result_dir) || !dir.exists(result_dir)) {
    return(list(success = FALSE, message = "Result directory not found"))
  }
  
  img_dir <- file.path(result_dir, "img")
  if (!dir.exists(img_dir)) {
    return(list(success = FALSE, message = "Image directory not found"))
  }
  
  # Copy score image
  score_src <- file.path(img_dir, paste0(tolower(platform), "_score.jpg"))
  if (file.exists(score_src)) {
    score_dst <- file.path(output_dir, paste0(tolower(platform), "_score_", disease_id, ".jpg"))
    file.copy(score_src, score_dst, overwrite = TRUE)
  }
  
  # Copy heatmap image
  heatmap_files <- list.files(img_dir, pattern = "heatmap", full.names = TRUE)
  if (length(heatmap_files) > 0) {
    heatmap_src <- heatmap_files[1]
    heatmap_dst <- file.path(output_dir, paste0("heatmap_", tolower(platform), "_hits_", disease_id, ".jpg"))
    file.copy(heatmap_src, heatmap_dst, overwrite = TRUE)
  }
  
  return(list(success = TRUE, message = "Images extracted"))
}

#' Create preview CSV (first 10 rows)
create_preview_csv <- function(results_df, output_path) {
  if (is.null(results_df)) {
    return(FALSE)
  }
  
  preview <- head(results_df, 10)
  write.csv(preview, output_path, row.names = FALSE)
  return(TRUE)
}

#' Compute hit statistics
compute_hit_statistics <- function(cmap_results, tahoe_results, disease_name, known_drugs_list) {
  # Get significant hits (based on q-value or p-value)
  
  cmap_hits <- c()
  tahoe_hits <- c()
  
  if (!is.null(cmap_results) && "drug_name" %in% names(cmap_results)) {
    cmap_hits <- tolower(unique(cmap_results$drug_name))
  }
  
  if (!is.null(tahoe_results) && "drug_name" %in% names(tahoe_results)) {
    tahoe_hits <- tolower(unique(tahoe_results$drug_name))
  }
  
  # Known drugs
  known <- tolower(known_drugs_list)
  
  # Compute overlaps
  cmap_known <- intersect(cmap_hits, known)
  tahoe_known <- intersect(tahoe_hits, known)
  both_known <- intersect(cmap_known, tahoe_known)
  
  summary_df <- data.frame(
    platform = c("cmap", "tahoe", "both"),
    total_hits = c(length(cmap_hits), length(tahoe_hits), length(union(cmap_hits, tahoe_hits))),
    known_hits = c(length(cmap_known), length(tahoe_known), length(union(cmap_known, tahoe_known))),
    total_known_for_disease = length(known),
    overlap_known_hits_both = length(both_known),
    stringsAsFactors = FALSE
  )
  
  return(summary_df)
}

#' Create top 10 hits bar plot
create_top10_plot <- function(results_df, platform, disease_id, output_dir, known_drugs_list) {
  if (is.null(results_df) || nrow(results_df) == 0) {
    return(FALSE)
  }
  
  # Get top 10
  score_col <- which(grepl("score|connectivity|rank", names(results_df), ignore.case = TRUE))[1]
  if (is.na(score_col)) score_col <- 2
  
  results_df$score <- abs(results_df[[score_col]])
  top10 <- results_df %>%
    slice_max(score, n = 10) %>%
    arrange(desc(score))
  
  if (nrow(top10) == 0) return(FALSE)
  
  top10$drug_name <- tolower(top10$drug_name)
  top10$is_known <- top10$drug_name %in% tolower(known_drugs_list)
  top10 <- top10 %>%
    mutate(drug_label = str_wrap(drug_name, width = 12))
  
  # Color based on platform
  platform_color <- ifelse(platform == "cmap", "#1f77b4", "#ff7f0e")
  
  p <- ggplot(top10, aes(x = reorder(drug_label, score), y = score, 
                         fill = is_known, color = is_known)) +
    geom_bar(stat = "identity", size = 0.7) +
    scale_fill_manual(values = c("TRUE" = platform_color, "FALSE" = "lightgray")) +
    scale_color_manual(values = c("TRUE" = "darkred", "FALSE" = "black")) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      legend.position = "bottom"
    ) +
    labs(
      x = "Drug Name",
      y = "Score",
      fill = "Known Drug",
      color = "Known Drug",
      title = paste("Top 10", toupper(platform), "Hits")
    ) +
    coord_flip()
  
  output_path <- file.path(output_dir, paste0("top10_", tolower(platform), "_", disease_id, ".png"))
  ggsave(output_path, p, width = 8, height = 6, dpi = 300)
  return(TRUE)
}

#' Create Venn diagram
create_venn_diagram <- function(cmap_hits, tahoe_hits, disease_id, output_dir) {
  cmap_set <- tolower(unique(cmap_hits))
  tahoe_set <- tolower(unique(tahoe_hits))
  
  if (length(cmap_set) == 0 || length(tahoe_set) == 0) {
    return(FALSE)
  }
  
  # Create Venn diagram
  png_path <- file.path(output_dir, paste0("venn_", disease_id, ".png"))
  png(png_path, width = 800, height = 600, res = 100)
  
  venn(list(CMap = cmap_set, TAHOE = tahoe_set), 
       borders = FALSE,
       ilabels = TRUE,
       ellipse = TRUE)
  
  dev.off()
  return(TRUE)
}

#' Create MOA comparison plot
create_moa_plot <- function(cmap_results, tahoe_results, disease_id, output_dir) {
  if ((is.null(cmap_results) || nrow(cmap_results) == 0) &&
      (is.null(tahoe_results) || nrow(tahoe_results) == 0)) {
    return(FALSE)
  }
  
  # Extract drug names and map to MOA
  cmap_drugs <- tolower(unique(head(cmap_results$drug_name, 20)))
  tahoe_drugs <- tolower(unique(head(tahoe_results$drug_name, 20)))
  
  all_drugs <- unique(c(cmap_drugs, tahoe_drugs))
  
  # Map to MOA
  drug_moa <- data.frame(
    drug = all_drugs,
    stringsAsFactors = FALSE
  ) %>%
    left_join(
      moa_database %>% rename(drug = drug_name),
      by = "drug"
    ) %>%
    mutate(
      mechanism_class = ifelse(is.na(mechanism_class), "Unknown", mechanism_class),
      in_cmap = drug %in% cmap_drugs,
      in_tahoe = drug %in% tahoe_drugs
    )
  
  # Count by mechanism and platform
  moa_counts <- drug_moa %>%
    pivot_longer(cols = c(in_cmap, in_tahoe), names_to = "platform", values_to = "present") %>%
    filter(present) %>%
    mutate(platform = ifelse(platform == "in_cmap", "CMap", "TAHOE")) %>%
    group_by(mechanism_class, platform) %>%
    summarise(count = n(), .groups = "drop")
  
  if (nrow(moa_counts) == 0) return(FALSE)
  
  p <- ggplot(moa_counts, aes(x = mechanism_class, y = count, fill = platform)) +
    geom_bar(stat = "identity", position = "dodge", color = "black", size = 0.5) +
    scale_fill_manual(values = c("CMap" = "#1f77b4", "TAHOE" = "#ff7f0e")) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
      legend.position = "bottom"
    ) +
    labs(
      x = "Mechanism of Action Class",
      y = "Number of Hits",
      fill = "Platform",
      title = "Mechanism of Action Comparison"
    )
  
  output_path <- file.path(output_dir, paste0("moa_", disease_id, ".png"))
  ggsave(output_path, p, width = 10, height = 6, dpi = 300)
  return(TRUE)
}

#' Create known drug rank comparison plot
create_rank_comparison_plot <- function(cmap_results, tahoe_results, disease_id, 
                                        output_dir, known_drugs_list) {
  if (is.null(cmap_results) || is.null(tahoe_results)) {
    return(FALSE)
  }
  
  cmap_results$drug_name <- tolower(cmap_results$drug_name)
  tahoe_results$drug_name <- tolower(tahoe_results$drug_name)
  known_drugs_lower <- tolower(known_drugs_list)
  
  # Add rank
  cmap_results$rank <- rank(-abs(cmap_results[[2]]), ties.method = "average")
  tahoe_results$rank <- rank(-abs(tahoe_results[[2]]), ties.method = "average")
  
  # Get known drugs
  cmap_known <- cmap_results %>%
    filter(drug_name %in% known_drugs_lower) %>%
    select(drug_name, rank) %>%
    rename(cmap_rank = rank)
  
  tahoe_known <- tahoe_results %>%
    filter(drug_name %in% known_drugs_lower) %>%
    select(drug_name, rank) %>%
    rename(tahoe_rank = rank)
  
  # Merge
  rank_df <- cmap_known %>%
    full_join(tahoe_known, by = "drug_name") %>%
    mutate(
      cmap_rank = ifelse(is.na(cmap_rank), max(cmap_results$rank) + 1, cmap_rank),
      tahoe_rank = ifelse(is.na(tahoe_rank), max(tahoe_results$rank) + 1, tahoe_rank),
      cmap_percentile = cmap_rank / max(cmap_results$rank),
      tahoe_percentile = tahoe_rank / max(tahoe_results$rank)
    )
  
  if (nrow(rank_df) == 0) return(FALSE)
  
  p <- ggplot(rank_df, aes(x = cmap_percentile, y = tahoe_percentile, label = drug_name)) +
    geom_point(size = 3, color = "#2ca02c", alpha = 0.6) +
    ggrepel::geom_text_repel(size = 3) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
    theme_minimal() +
    theme(legend.position = "none") +
    labs(
      x = "CMap Rank Percentile",
      y = "TAHOE Rank Percentile",
      title = "Known Drug Rank Comparison"
    ) +
    xlim(0, 1) +
    ylim(0, 1)
  
  output_path <- file.path(output_dir, paste0("rank_comparison_", disease_id, ".png"))
  ggsave(output_path, p, width = 7, height = 6, dpi = 300)
  return(TRUE)
}

#' Create summary text file
create_summary_text <- function(disease_name, disease_id, raw_sig, std_sig,
                                hit_stats, cmap_results, tahoe_results,
                                moa_info, output_path) {
  
  sink(output_path)
  
  cat("CASE STUDY SUMMARY: ", disease_name, "\n")
  cat("=", strrep("70), "\n\n")
  
  cat("DISEASE SIGNATURE SUMMARY\n")
  cat("-", strrep("70), "\n")
  cat("Initial genes (raw):", nrow(raw_sig), "\n")
  cat("  - Up-regulated:", sum(raw_sig[[ncol(raw_sig)]] > 0, na.rm = TRUE), "\n")
  cat("  - Down-regulated:", sum(raw_sig[[ncol(raw_sig)]] < 0, na.rm = TRUE), "\n")
  cat("Final genes (standardized):", nrow(std_sig), "\n")
  cat("  - Up-regulated:", sum(std_sig[[ncol(std_sig)]] > 0, na.rm = TRUE), "\n")
  cat("  - Down-regulated:", sum(std_sig[[ncol(std_sig)]] < 0, na.rm = TRUE), "\n\n")
  
  cat("PIPELINE RESULTS SUMMARY\n")
  cat("-", strrep("70), "\n")
  if (!is.null(hit_stats)) {
    print(hit_stats)
  }
  cat("\n")
  
  cat("INTERPRETATION NOTES\n")
  cat("-", strrep("70), "\n")
  cat("This case study examines", disease_name, "using two complementary\n")
  cat("drug repurposing pipelines: CMap and TAHOE. Both identify small molecule\n")
  cat("compounds predicted to reverse or mimic disease-associated transcriptomic\n")
  cat("signatures.\n\n")
  
  cat("Key observations:\n")
  cat("- Number of significant CMap hits (q<0.05):", 
      ifelse(is.null(cmap_results), "N/A", nrow(cmap_results)), "\n")
  cat("- Number of significant TAHOE hits (q<0.05):", 
      ifelse(is.null(tahoe_results), "N/A", nrow(tahoe_results)), "\n")
  cat("\n")
  
  cat("METHODOLOGY\n")
  cat("-", strrep("70), "\n")
  cat("Disease signature: CREEDS manual standardized signatures\n")
  cat("CMap database: L1000 connectivity map\n")
  cat("TAHOE pipeline: In-house transcriptomic matching\n")
  cat("Significance threshold: q < 0.05 (FDR-corrected)\n\n")
  
  cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  
  sink()
}

# =============================================================================
# MAIN PIPELINE
# =============================================================================

cat("Starting Case Study Extraction Pipeline...\n")
cat("Base directory:", case_study_dir, "\n\n")

# Process each disease
for (i in seq_len(nrow(diseases))) {
  disease_id <- diseases$id[i]
  disease_name_raw <- diseases$name_raw[i]
  disease_name_std <- diseases$name_std[i]
  
  cat(strrep("=", 70), "\n")
  cat("Processing:", disease_id, "\n")
  cat(strrep("=", 70), "\n")
  
  # Create directories
  create_dirs(disease_id)
  sig_dir <- file.path(case_study_dir, disease_id, "signature")
  results_dir <- file.path(case_study_dir, disease_id, "results_pipeline")
  figures_dir <- file.path(case_study_dir, disease_id, "figures")
  
  cat("\n[STEP 1] Extracting disease signatures...\n")
  
  # Find raw signature file
  raw_files <- list.files(sig_raw_dir, pattern = disease_name_raw, full.names = TRUE)
  raw_sig_path <- if (length(raw_files) > 0) raw_files[1] else NULL
  
  # Find standardized signature file
  std_files <- list.files(sig_std_dir, pattern = disease_name_std, full.names = TRUE)
  std_sig_path <- if (length(std_files) > 0) std_files[1] else NULL
  
  # Find plot file
  plot_files <- list.files(sig_plots_dir, pattern = disease_name_raw, full.names = TRUE)
  plot_src <- if (length(plot_files) > 0) plot_files[1] else NULL
  
  # Read signatures
  raw_sig <- if (!is.null(raw_sig_path)) read_signature(raw_sig_path) else NULL
  std_sig <- if (!is.null(std_sig_path)) read_signature(std_sig_path) else NULL
  
  if (!is.null(raw_sig)) {
    cat("  Copied raw signature from:", basename(raw_sig_path), "\n")
    file.copy(raw_sig_path, file.path(sig_dir, "disease_signature_raw.csv"), overwrite = TRUE)
  } else {
    cat("  WARNING: Raw signature not found\n")
  }
  
  if (!is.null(std_sig)) {
    cat("  Copied standardized signature from:", basename(std_sig_path), "\n")
    file.copy(std_sig_path, file.path(sig_dir, "disease_signature_standardized.csv"), overwrite = TRUE)
  } else {
    cat("  WARNING: Standardized signature not found\n")
  }
  
  if (!is.null(plot_src) && file.exists(plot_src)) {
    cat("  Copied signature plot\n")
    file.copy(plot_src, file.path(sig_dir, "original_signature_plot.png"), overwrite = TRUE)
  }
  
  # Compute and save statistics
  if (!is.null(raw_sig) && !is.null(std_sig)) {
    sig_stats <- compute_signature_stats(raw_sig, std_sig, disease_id)
    write.csv(sig_stats, file.path(sig_dir, "disease_signature_summary.csv"), row.names = FALSE)
    cat("  Saved signature statistics\n")
  }
  
  # ==========================================================================
  # STEP 2: Create volcano plot and gene count plot
  # ==========================================================================
  cat("\n[STEP 2] Creating visualization plots...\n")
  
  if (!is.null(std_sig)) {
    if (create_volcano_plot(std_sig, file.path(figures_dir, paste0("volcano_", disease_id, ".png")))) {
      cat("  Created volcano plot\n")
    }
    if (create_gene_count_plot(std_sig, file.path(figures_dir, paste0("gene_counts_", disease_id, ".png")))) {
      cat("  Created gene count plot\n")
    }
  }
  
  # ==========================================================================
  # STEP 3: Extract pipeline results
  # ==========================================================================
  cat("\n[STEP 3] Extracting pipeline results...\n")
  
  # Find CMap results
  cmap_result_dir <- find_result_dir(disease_name_raw, "CMAP")
  cmap_results <- if (!is.null(cmap_result_dir)) {
    extract_results_csv(cmap_result_dir)
  } else {
    cat("  WARNING: CMap results not found\n")
    NULL
  }
  
  # Find TAHOE results
  tahoe_result_dir <- find_result_dir(disease_name_raw, "TAHOE")
  tahoe_results <- if (!is.null(tahoe_result_dir)) {
    extract_results_csv(tahoe_result_dir)
  } else {
    cat("  WARNING: TAHOE results not found\n")
    NULL
  }
  
  # Extract images
  if (!is.null(cmap_result_dir)) {
    result <- extract_images(cmap_result_dir, "CMAP", disease_id, file.path(results_dir, "cmap"))
    cat("  ", result$message, " (CMap)\n")
  }
  
  if (!is.null(tahoe_result_dir)) {
    result <- extract_images(tahoe_result_dir, "TAHOE", disease_id, file.path(results_dir, "tahoe"))
    cat("  ", result$message, " (TAHOE)\n")
  }
  
  # Save full result CSVs
  if (!is.null(cmap_results)) {
    write.csv(cmap_results, 
              file.path(results_dir, "cmap", paste0("cmap_results_", disease_id, ".csv")),
              row.names = FALSE)
    cat("  Saved CMap results CSV\n")
  }
  
  if (!is.null(tahoe_results)) {
    write.csv(tahoe_results, 
              file.path(results_dir, "tahoe", paste0("tahoe_results_", disease_id, ".csv")),
              row.names = FALSE)
    cat("  Saved TAHOE results CSV\n")
  }
  
  # Create preview CSVs
  if (!is.null(cmap_results)) {
    create_preview_csv(head(cmap_results, 10), 
                       file.path(results_dir, "cmap", paste0("cmap_preview_", disease_id, ".csv")))
    cat("  Created CMap preview CSV\n")
  }
  
  if (!is.null(tahoe_results)) {
    create_preview_csv(head(tahoe_results, 10), 
                       file.path(results_dir, "tahoe", paste0("tahoe_preview_", disease_id, ".csv")))
    cat("  Created TAHOE preview CSV\n")
  }
  
  # ==========================================================================
  # STEP 4: Compute hit statistics
  # ==========================================================================
  cat("\n[STEP 4] Computing hit statistics...\n")
  
  known_drugs_for_disease <- known_drugs[[disease_name_raw]]
  if (is.null(known_drugs_for_disease)) {
    known_drugs_for_disease <- c()  # Empty if not found
  }
  
  hit_stats <- compute_hit_statistics(cmap_results, tahoe_results, 
                                      disease_id, known_drugs_for_disease)
  write.csv(hit_stats, 
            file.path(results_dir, paste0("hit_summary_", disease_id, ".csv")),
            row.names = FALSE)
  cat("  Saved hit statistics\n")
  
  # ==========================================================================
  # STEP 5: Create top 10 hits bar plots
  # ==========================================================================
  cat("\n[STEP 5] Creating top 10 hits plots...\n")
  
  if (!is.null(cmap_results) && nrow(cmap_results) > 0) {
    if (create_top10_plot(cmap_results, "cmap", disease_id, figures_dir, known_drugs_for_disease)) {
      cat("  Created CMap top 10 plot\n")
    }
  }
  
  if (!is.null(tahoe_results) && nrow(tahoe_results) > 0) {
    if (create_top10_plot(tahoe_results, "tahoe", disease_id, figures_dir, known_drugs_for_disease)) {
      cat("  Created TAHOE top 10 plot\n")
    }
  }
  
  # ==========================================================================
  # STEP 6: Create Venn diagram
  # ==========================================================================
  cat("\n[STEP 6] Creating Venn diagram...\n")
  
  if (!is.null(cmap_results) && !is.null(tahoe_results)) {
    if (create_venn_diagram(cmap_results$drug_name, tahoe_results$drug_name, 
                            disease_id, figures_dir)) {
      cat("  Created Venn diagram\n")
    }
  }
  
  # ==========================================================================
  # STEP 7: Create MOA comparison plot
  # ==========================================================================
  cat("\n[STEP 7] Creating MOA comparison plot...\n")
  
  if (!is.null(cmap_results) && !is.null(tahoe_results)) {
    if (create_moa_plot(cmap_results, tahoe_results, disease_id, figures_dir)) {
      cat("  Created MOA comparison plot\n")
    }
  }
  
  # ==========================================================================
  # STEP 8: Create rank comparison plot
  # ==========================================================================
  cat("\n[STEP 8] Creating known drug rank comparison plot...\n")
  
  if (!is.null(cmap_results) && !is.null(tahoe_results) && length(known_drugs_for_disease) > 0) {
    if (create_rank_comparison_plot(cmap_results, tahoe_results, disease_id,
                                    figures_dir, known_drugs_for_disease)) {
      cat("  Created rank comparison plot\n")
    }
  }
  
  # ==========================================================================
  # STEP 9: Create summary text file
  # ==========================================================================
  cat("\n[STEP 9] Creating summary text file...\n")
  
  moa_info <- NULL  # Can be enhanced with actual MOA summary
  
  create_summary_text(disease_id, disease_id, raw_sig, std_sig, hit_stats,
                      cmap_results, tahoe_results, moa_info,
                      file.path(results_dir, paste0("case_summary_", disease_id, ".txt")))
  cat("  Created summary text file\n")
  
  cat("\n")
}

cat("\n", strrep("70), "\n")
cat("CASE STUDY EXTRACTION COMPLETE!\n")
cat("All outputs saved to:", case_study_dir, "\n")
cat("=", strrep("70), "\n")
