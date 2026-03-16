#!/usr/bin/env Rscript
#' Case Study Extraction and Analysis Pipeline - Simplified
#' Automates all 9 steps for 5 diseases

library(tidyverse)
library(ggplot2)
library(venn)
library(ggrepel)

# Configuration
base_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis"
case_study_dir <- file.path(base_dir, "case_study_special")
sig_raw_dir <- file.path(base_dir, "data/disease_signatures/creeds_manual_disease_signatures")
sig_std_dir <- file.path(base_dir, "data/disease_signatures/creeds_manual_disease_signatures_standardised")
sig_plots_dir <- file.path(base_dir, "data/disease_signatures/creeds_manual_disease_signatures_plots")
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
  stringsAsFactors = FALSE
)

# MOA database
moa_database <- tribble(
  ~drug_name, ~mechanism_of_action, ~mechanism_class,
  "acetylsalicylic acid", "COX inhibitor", "Anti-inflammatory",
  "amiodarone", "Antiarrhythmic", "Cardiovascular",
  "baclofen", "GABA-B agonist", "Neurological",
  "bendroflumethiazide", "Diuretic", "Cardiovascular",
  "benzonatate", "Local anesthetic", "Other",
  "bisacodyl", "Laxative", "Other",
  "bupropion", "NDRI", "Neurological",
  "buspirone", "5-HT1A agonist", "Neurological",
  "capsaicin", "TRPV1 agonist", "Anti-inflammatory",
  "dexamethasone", "Glucocorticoid agonist", "Hormone Therapy",
  "hydrocortisone", "Glucocorticoid agonist", "Hormone Therapy",
  "methotrexate", "Antimetabolite", "Chemotherapy",
  "warfarin", "Vitamin K antagonist", "Cardiovascular",
  "tamoxifen", "ER antagonist", "Hormone Therapy",
  "trichostatin A", "HDAC inhibitor", "Epigenetic Modifier"
) %>% mutate(drug_name = tolower(drug_name))

known_drugs <- list(
  "autoimmune_thrombocytopenic_purpura" = c("dexamethasone", "hydrocortisone"),
  "cerebral_palsy" = c("baclofen"),
  "Eczema" = c("hydrocortisone"),
  "chronic_lymphocytic_leukemia" = c("methotrexate"),
  "endometriosis_of_ovary" = c("dienogest")
)

# Utility Functions
create_dirs <- function(disease_id) {
  dirs <- c(
    file.path(case_study_dir, disease_id, "signature"),
    file.path(case_study_dir, disease_id, "results_pipeline/cmap"),
    file.path(case_study_dir, disease_id, "results_pipeline/tahoe"),
    file.path(case_study_dir, disease_id, "figures")
  )
  sapply(dirs, function(d) dir.create(d, recursive = TRUE, showWarnings = FALSE))
}

find_result_dir <- function(disease_name, platform) {
  pattern <- paste0("^", disease_name, "_", platform, "_")
  dirs <- list.dirs(results_base_dir, recursive = FALSE, full.names = TRUE)
  matching <- dirs[grepl(pattern, basename(dirs))]
  if (length(matching) > 0) return(matching[1])
  return(NULL)
}

read_signature <- function(filepath) {
  if (!file.exists(filepath)) return(NULL)
  tryCatch(read.csv(filepath, stringsAsFactors = FALSE), error = function(e) NULL)
}

compute_signature_stats <- function(raw_sig, std_sig, disease_name) {
  data.frame(
    disease_name = disease_name,
    genes_initial_total = nrow(raw_sig),
    genes_initial_up = sum(raw_sig[[ncol(raw_sig)]] > 0, na.rm = TRUE),
    genes_initial_down = sum(raw_sig[[ncol(raw_sig)]] < 0, na.rm = TRUE),
    genes_final_total = nrow(std_sig),
    genes_final_up = sum(std_sig[[ncol(std_sig)]] > 0, na.rm = TRUE),
    genes_final_down = sum(std_sig[[ncol(std_sig)]] < 0, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

create_volcano_plot <- function(std_sig, output_path) {
  if (ncol(std_sig) < 3) return(FALSE)
  
  logFC_col <- which(grepl("logfc|log_fc|fc", names(std_sig), ignore.case = TRUE))[1]
  pval_col <- which(grepl("pval|p_val|p.value", names(std_sig), ignore.case = TRUE))[1]
  if (is.na(logFC_col)) logFC_col <- 2
  if (is.na(pval_col)) pval_col <- 3
  
  df <- data.frame(
    logFC = std_sig[[logFC_col]],
    pval = std_sig[[pval_col]]
  ) %>%
    mutate(
      neg_log_pval = -log10(pval + 1e-300),
      direction = ifelse(logFC > 0, "up", "down")
    ) %>%
    filter(is.finite(neg_log_pval) & is.finite(logFC))
  
  p <- ggplot(df, aes(x = logFC, y = neg_log_pval, color = direction)) +
    geom_point(alpha = 0.6, size = 2) +
    scale_color_manual(values = c("up" = "#d73027", "down" = "#4575b4")) +
    theme_minimal() + labs(x = "Log Fold Change", y = "-Log10(P-value)", title = "Volcano Plot")
  
  ggsave(output_path, p, width = 8, height = 6, dpi = 300)
  return(TRUE)
}

create_gene_count_plot <- function(std_sig, output_path) {
  logFC_col <- which(grepl("logfc|log_fc|fc", names(std_sig), ignore.case = TRUE))[1]
  if (is.na(logFC_col)) logFC_col <- 2
  
  df <- data.frame(
    direction = c("Up-regulated", "Down-regulated"),
    count = c(sum(std_sig[[logFC_col]] > 0, na.rm = TRUE), sum(std_sig[[logFC_col]] < 0, na.rm = TRUE))
  )
  
  p <- ggplot(df, aes(x = direction, y = count, fill = direction)) +
    geom_bar(stat = "identity", color = "black", size = 0.5) +
    scale_fill_manual(values = c("Up-regulated" = "#d73027", "Down-regulated" = "#4575b4")) +
    theme_minimal() + theme(legend.position = "none") +
    labs(x = "", y = "Number of Genes", title = "Gene Count Distribution") +
    geom_text(aes(label = count), vjust = -0.5, size = 4)
  
  ggsave(output_path, p, width = 6, height = 5, dpi = 300)
  return(TRUE)
}

extract_results_csv <- function(result_dir) {
  if (is.null(result_dir) || !dir.exists(result_dir)) return(NULL)
  csv_files <- list.files(result_dir, pattern = "\\.csv$", full.names = TRUE)
  if (length(csv_files) == 0) return(NULL)
  hits_file <- csv_files[grepl("hits", csv_files)]
  if (length(hits_file) > 0) return(read.csv(hits_file[1], stringsAsFactors = FALSE))
  return(read.csv(csv_files[1], stringsAsFactors = FALSE))
}

extract_images <- function(result_dir, platform, disease_id, output_dir) {
  if (is.null(result_dir) || !dir.exists(result_dir)) return(list(success = FALSE, message = "Dir not found"))
  img_dir <- file.path(result_dir, "img")
  if (!dir.exists(img_dir)) return(list(success = FALSE, message = "Img dir not found"))
  
  score_src <- file.path(img_dir, paste0(tolower(platform), "_score.jpg"))
  if (file.exists(score_src)) {
    score_dst <- file.path(output_dir, paste0(tolower(platform), "_score_", disease_id, ".jpg"))
    file.copy(score_src, score_dst, overwrite = TRUE)
  }
  
  heatmap_files <- list.files(img_dir, pattern = "heatmap", full.names = TRUE)
  if (length(heatmap_files) > 0) {
    heatmap_dst <- file.path(output_dir, paste0("heatmap_", tolower(platform), "_hits_", disease_id, ".jpg"))
    file.copy(heatmap_files[1], heatmap_dst, overwrite = TRUE)
  }
  
  return(list(success = TRUE, message = "Images extracted"))
}

create_preview_csv <- function(results_df, output_path) {
  if (is.null(results_df)) return(FALSE)
  write.csv(head(results_df, 10), output_path, row.names = FALSE)
  return(TRUE)
}

compute_hit_statistics <- function(cmap_results, tahoe_results, disease_name, known_drugs_list) {
  cmap_hits <- if (!is.null(cmap_results) && "drug_name" %in% names(cmap_results)) {
    tolower(unique(cmap_results$drug_name))
  } else c()
  
  tahoe_hits <- if (!is.null(tahoe_results) && "drug_name" %in% names(tahoe_results)) {
    tolower(unique(tahoe_results$drug_name))
  } else c()
  
  known <- tolower(known_drugs_list)
  cmap_known <- intersect(cmap_hits, known)
  tahoe_known <- intersect(tahoe_hits, known)
  both_known <- intersect(cmap_known, tahoe_known)
  
  data.frame(
    platform = c("cmap", "tahoe", "both"),
    total_hits = c(length(cmap_hits), length(tahoe_hits), length(union(cmap_hits, tahoe_hits))),
    known_hits = c(length(cmap_known), length(tahoe_known), length(union(cmap_known, tahoe_known))),
    total_known_for_disease = length(known),
    overlap_known_hits_both = length(both_known),
    stringsAsFactors = FALSE
  )
}

create_top30_plot <- function(results_df, platform, disease_id, output_dir, known_drugs_list) {
  if (is.null(results_df) || nrow(results_df) == 0) return(FALSE)
  
  # Normalize column names
  if ("name" %in% names(results_df) && !("drug_name" %in% names(results_df))) {
    results_df <- results_df %>% rename(drug_name = name)
  }
  
  score_col <- which(grepl("score|connectivity|rank", names(results_df), ignore.case = TRUE))[1]
  if (is.na(score_col)) score_col <- 2
  
  top30 <- results_df %>%
    mutate(score = abs(.[[score_col]])) %>%
    slice_max(score, n = 30) %>%
    arrange(desc(score)) %>%
    mutate(
      drug_name = tolower(drug_name),
      is_known = drug_name %in% tolower(known_drugs_list),
      drug_label = str_wrap(drug_name, width = 12)
    )
  
  if (nrow(top30) == 0) return(FALSE)
  
  platform_color <- ifelse(platform == "cmap", "#F39C12", "#5DADE2")
  p <- ggplot(top30, aes(x = reorder(drug_label, score), y = score, fill = is_known, color = is_known)) +
    geom_bar(stat = "identity", linewidth = 0.7) +
    scale_fill_manual(values = c("TRUE" = platform_color, "FALSE" = "lightgray")) +
    scale_color_manual(values = c("TRUE" = "darkred", "FALSE" = "black")) +
    theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9)) +
    labs(x = "Drug Name", y = "Score", title = paste("Top 30", toupper(platform), "Hits")) +
    coord_flip()
  
  output_path <- file.path(output_dir, paste0("top30_", tolower(platform), "_", disease_id, ".png"))
  ggsave(output_path, p, width = 8, height = 8, dpi = 300)
  return(TRUE)
}

create_venn_diagram <- function(cmap_results, tahoe_results, disease_id, output_dir, known_drugs_list) {
  if (is.null(cmap_results) || is.null(tahoe_results)) return(FALSE)
  
  cmap_col <- if ("drug_name" %in% names(cmap_results)) "drug_name" else "name"
  tahoe_col <- if ("drug_name" %in% names(tahoe_results)) "drug_name" else "name"
  
  # Use ALL hits from each platform (all results, not just top 30)
  cmap_all <- cmap_results %>%
    pull(all_of(cmap_col)) %>%
    tolower() %>%
    unique()
  
  tahoe_all <- tahoe_results %>%
    pull(all_of(tahoe_col)) %>%
    tolower() %>%
    unique()
  
  if (length(cmap_all) == 0 || length(tahoe_all) == 0) return(FALSE)
  
  png_path <- file.path(output_dir, paste0("venn_", disease_id, ".png"))
  png(png_path, width = 800, height = 600, res = 100)
  venn(list(CMap = cmap_all, TAHOE = tahoe_all), borders = FALSE, ilabels = TRUE, ellipse = TRUE)
  dev.off()
  return(TRUE)
}

create_moa_plot <- function(cmap_results, tahoe_results, disease_id, output_dir) {
  if ((is.null(cmap_results) || nrow(cmap_results) == 0) && (is.null(tahoe_results) || nrow(tahoe_results) == 0)) {
    return(FALSE)
  }
  
  # Normalize column names
  cmap_col <- if ("drug_name" %in% names(cmap_results)) "drug_name" else "name"
  tahoe_col <- if ("drug_name" %in% names(tahoe_results)) "drug_name" else "name"
  
  cmap_drugs <- tolower(unique(head(cmap_results[[cmap_col]], 20)))
  tahoe_drugs <- tolower(unique(head(tahoe_results[[tahoe_col]], 20)))
  all_drugs <- unique(c(cmap_drugs, tahoe_drugs))
  
  drug_moa <- data.frame(drug = all_drugs, stringsAsFactors = FALSE) %>%
    left_join(moa_database %>% rename(drug = drug_name), by = "drug") %>%
    mutate(
      mechanism_class = ifelse(is.na(mechanism_class), "Unknown", mechanism_class),
      in_cmap = drug %in% cmap_drugs,
      in_tahoe = drug %in% tahoe_drugs
    )
  
  moa_counts <- drug_moa %>%
    pivot_longer(cols = c(in_cmap, in_tahoe), names_to = "platform", values_to = "present") %>%
    filter(present) %>%
    mutate(platform = ifelse(platform == "in_cmap", "CMap", "TAHOE")) %>%
    group_by(mechanism_class, platform) %>%
    summarise(count = n(), .groups = "drop")
  
  if (nrow(moa_counts) == 0) return(FALSE)
  
  p <- ggplot(moa_counts, aes(x = mechanism_class, y = count, fill = platform)) +
    geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.5) +
    scale_fill_manual(values = c("CMap" = "#F39C12", "TAHOE" = "#5DADE2")) +
    theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) +
    labs(x = "Mechanism of Action Class", y = "Number of Hits", title = "Mechanism of Action Comparison")
  
  output_path <- file.path(output_dir, paste0("moa_", disease_id, ".png"))
  ggsave(output_path, p, width = 10, height = 6, dpi = 300)
  return(TRUE)
}

create_rank_comparison_plot <- function(cmap_results, tahoe_results, disease_id, output_dir, known_drugs_list) {
  if (is.null(cmap_results) || is.null(tahoe_results)) return(FALSE)
  
  # Normalize column names
  cmap_col <- if ("drug_name" %in% names(cmap_results)) "drug_name" else "name"
  tahoe_col <- if ("drug_name" %in% names(tahoe_results)) "drug_name" else "name"
  
  cmap_results <- cmap_results %>% rename(drug_name = all_of(cmap_col))
  tahoe_results <- tahoe_results %>% rename(drug_name = all_of(tahoe_col))
  
  cmap_results$drug_name <- tolower(cmap_results$drug_name)
  tahoe_results$drug_name <- tolower(tahoe_results$drug_name)
  known_drugs_lower <- tolower(known_drugs_list)
  
  cmap_results$rank <- rank(-abs(cmap_results[[2]]), ties.method = "average")
  tahoe_results$rank <- rank(-abs(tahoe_results[[2]]), ties.method = "average")
  
  cmap_known <- cmap_results %>% filter(drug_name %in% known_drugs_lower) %>% select(drug_name, rank) %>% rename(cmap_rank = rank)
  tahoe_known <- tahoe_results %>% filter(drug_name %in% known_drugs_lower) %>% select(drug_name, rank) %>% rename(tahoe_rank = rank)
  
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
    geom_text_repel(size = 3) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
    theme_minimal() + labs(x = "CMap Rank Percentile", y = "TAHOE Rank Percentile", title = "Known Drug Rank Comparison") +
    xlim(0, 1) + ylim(0, 1)
  
  output_path <- file.path(output_dir, paste0("rank_comparison_", disease_id, ".png"))
  ggsave(output_path, p, width = 7, height = 6, dpi = 300)
  return(TRUE)
}

create_summary_text <- function(disease_name, disease_id, raw_sig, std_sig, hit_stats, cmap_results, tahoe_results, output_path) {
  sink(output_path)
  cat("CASE STUDY SUMMARY:", disease_name, "\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  cat("DISEASE SIGNATURE SUMMARY\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat("Initial genes (raw):", nrow(raw_sig), "\n")
  cat("  Up-regulated:", sum(raw_sig[[ncol(raw_sig)]] > 0, na.rm = TRUE), "\n")
  cat("  Down-regulated:", sum(raw_sig[[ncol(raw_sig)]] < 0, na.rm = TRUE), "\n")
  cat("Final genes (standardized):", nrow(std_sig), "\n")
  cat("  Up-regulated:", sum(std_sig[[ncol(std_sig)]] > 0, na.rm = TRUE), "\n")
  cat("  Down-regulated:", sum(std_sig[[ncol(std_sig)]] < 0, na.rm = TRUE), "\n\n")
  cat("PIPELINE RESULTS SUMMARY\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  if (!is.null(hit_stats)) print(hit_stats)
  cat("\n")
  cat("METHODOLOGY\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat("Disease signature: CREEDS manual standardized signatures\n")
  cat("CMap database: L1000 connectivity map\n")
  cat("TAHOE pipeline: In-house transcriptomic matching\n")
  cat("Significance threshold: q < 0.05 (FDR-corrected)\n")
  cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  sink()
}

# Main Pipeline
cat("Starting Case Study Extraction Pipeline...\n")
cat("Base directory:", case_study_dir, "\n\n")

for (i in seq_len(nrow(diseases))) {
  disease_id <- diseases$id[i]
  disease_name_raw <- diseases$name_raw[i]
  
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("Processing:", disease_id, "\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  create_dirs(disease_id)
  sig_dir <- file.path(case_study_dir, disease_id, "signature")
  results_dir <- file.path(case_study_dir, disease_id, "results_pipeline")
  figures_dir <- file.path(case_study_dir, disease_id, "figures")
  
  # STEP 1
  cat("[STEP 1] Extracting disease signatures...\n")
  raw_files <- list.files(sig_raw_dir, pattern = disease_name_raw, full.names = TRUE)
  std_files <- list.files(sig_std_dir, pattern = disease_name_raw, full.names = TRUE)
  plot_files <- list.files(sig_plots_dir, pattern = disease_name_raw, full.names = TRUE)
  
  raw_sig <- if (length(raw_files) > 0) read_signature(raw_files[1]) else NULL
  std_sig <- if (length(std_files) > 0) read_signature(std_files[1]) else NULL
  
  if (!is.null(raw_sig)) {
    file.copy(raw_files[1], file.path(sig_dir, "disease_signature_raw.csv"), overwrite = TRUE)
    cat("  Copied raw signature\n")
  }
  if (!is.null(std_sig)) {
    file.copy(std_files[1], file.path(sig_dir, "disease_signature_standardized.csv"), overwrite = TRUE)
    cat("  Copied standardized signature\n")
  }
  if (length(plot_files) > 0) {
    file.copy(plot_files[1], file.path(sig_dir, "original_signature_plot.png"), overwrite = TRUE)
  }
  
  if (!is.null(raw_sig) && !is.null(std_sig)) {
    sig_stats <- compute_signature_stats(raw_sig, std_sig, disease_id)
    write.csv(sig_stats, file.path(sig_dir, "disease_signature_summary.csv"), row.names = FALSE)
    cat("  Saved signature statistics\n")
  }
  
  # STEP 2
  cat("\n[STEP 2] Creating visualization plots...\n")
  if (!is.null(std_sig)) {
    if (create_volcano_plot(std_sig, file.path(figures_dir, paste0("volcano_", disease_id, ".png")))) {
      cat("  Created volcano plot\n")
    }
    if (create_gene_count_plot(std_sig, file.path(figures_dir, paste0("gene_counts_", disease_id, ".png")))) {
      cat("  Created gene count plot\n")
    }
  }
  
  # STEP 3
  cat("\n[STEP 3] Extracting pipeline results...\n")
  cmap_result_dir <- find_result_dir(disease_name_raw, "CMAP")
  tahoe_result_dir <- find_result_dir(disease_name_raw, "TAHOE")
  
  cmap_results <- if (!is.null(cmap_result_dir)) extract_results_csv(cmap_result_dir) else NULL
  tahoe_results <- if (!is.null(tahoe_result_dir)) extract_results_csv(tahoe_result_dir) else NULL
  
  # Normalize column names: ensure drug_name column exists
  if (!is.null(cmap_results) && "name" %in% names(cmap_results) && !("drug_name" %in% names(cmap_results))) {
    cmap_results <- cmap_results %>% rename(drug_name = name)
  }
  if (!is.null(tahoe_results) && "name" %in% names(tahoe_results) && !("drug_name" %in% names(tahoe_results))) {
    tahoe_results <- tahoe_results %>% rename(drug_name = name)
  }
  
  if (!is.null(cmap_result_dir)) extract_images(cmap_result_dir, "CMAP", disease_id, file.path(results_dir, "cmap"))
  if (!is.null(tahoe_result_dir)) extract_images(tahoe_result_dir, "TAHOE", disease_id, file.path(results_dir, "tahoe"))
  
  if (!is.null(cmap_results)) {
    write.csv(cmap_results, file.path(results_dir, "cmap", paste0("cmap_results_", disease_id, ".csv")), row.names = FALSE)
    cat("  Saved CMap results\n")
  }
  if (!is.null(tahoe_results)) {
    write.csv(tahoe_results, file.path(results_dir, "tahoe", paste0("tahoe_results_", disease_id, ".csv")), row.names = FALSE)
    cat("  Saved TAHOE results\n")
  }
  
  if (!is.null(cmap_results)) {
    create_preview_csv(cmap_results, file.path(results_dir, "cmap", paste0("cmap_preview_", disease_id, ".csv")))
    cat("  Created CMap preview CSV\n")
  }
  if (!is.null(tahoe_results)) {
    create_preview_csv(tahoe_results, file.path(results_dir, "tahoe", paste0("tahoe_preview_", disease_id, ".csv")))
    cat("  Created TAHOE preview CSV\n")
  }
  
  # STEP 4
  cat("\n[STEP 4] Computing hit statistics...\n")
  known_drugs_for_disease <- known_drugs[[disease_name_raw]]
  if (is.null(known_drugs_for_disease)) known_drugs_for_disease <- c()
  
  hit_stats <- compute_hit_statistics(cmap_results, tahoe_results, disease_id, known_drugs_for_disease)
  write.csv(hit_stats, file.path(results_dir, paste0("hit_summary_", disease_id, ".csv")), row.names = FALSE)
  cat("  Saved hit statistics\n")
  
  # STEP 5
  cat("\n[STEP 5] Creating top 30 hits plots...\n")
  if (!is.null(cmap_results) && nrow(cmap_results) > 0) {
    if (create_top30_plot(cmap_results, "cmap", disease_id, figures_dir, known_drugs_for_disease)) {
      cat("  Created CMap top 30 plot\n")
    }
  }
  if (!is.null(tahoe_results) && nrow(tahoe_results) > 0) {
    if (create_top30_plot(tahoe_results, "tahoe", disease_id, figures_dir, known_drugs_for_disease)) {
      cat("  Created TAHOE top 30 plot\n")
    }
  }
  
  # STEP 6
  cat("\n[STEP 6] Creating Venn diagram...\n")
  if (!is.null(cmap_results) && !is.null(tahoe_results)) {
    if (create_venn_diagram(cmap_results, tahoe_results, disease_id, figures_dir, known_drugs_for_disease)) {
      cat("  Created Venn diagram\n")
    }
  }
  
  # STEP 7
  cat("\n[STEP 7] Creating MOA comparison plot...\n")
  if (!is.null(cmap_results) && !is.null(tahoe_results)) {
    if (create_moa_plot(cmap_results, tahoe_results, disease_id, figures_dir)) {
      cat("  Created MOA comparison plot\n")
    }
  }
  
  # STEP 8
  cat("\n[STEP 8] Creating known drug rank comparison plot...\n")
  if (!is.null(cmap_results) && !is.null(tahoe_results) && length(known_drugs_for_disease) > 0) {
    if (create_rank_comparison_plot(cmap_results, tahoe_results, disease_id, figures_dir, known_drugs_for_disease)) {
      cat("  Created rank comparison plot\n")
    }
  }
  
  # STEP 9
  cat("\n[STEP 9] Creating summary text file...\n")
  create_summary_text(disease_id, disease_id, raw_sig, std_sig, hit_stats, cmap_results, tahoe_results, 
                      file.path(results_dir, paste0("case_summary_", disease_id, ".txt")))
  cat("  Created summary text file\n")
  
  cat("\n")
}

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("CASE STUDY EXTRACTION COMPLETE!\n")
cat("All outputs saved to:", case_study_dir, "\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
