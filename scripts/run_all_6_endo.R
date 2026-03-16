#!/usr/bin/env Rscript
# Run all 6 endometriosis profiles with probe_id_fallback fix
# Compares results with Tomiko's original pipeline

library(DRpipe)

cat("================================================================\n")
cat("Running all 6 Endometriosis signatures with DRpipe\n")
cat("================================================================\n\n")

# All 6 endometriosis profiles
profiles <- c(
  "CMAP_Endometriosis_ESE_Strict",
  "CMAP_Endometriosis_INII_Strict",
  "CMAP_Endometriosis_IIINIV_Strict",
  "CMAP_Endometriosis_MSE_Strict",
  "CMAP_Endometriosis_PE_Strict",
  "CMAP_Endometriosis_Unstratified_Strict"
)

# Tomiko result files for comparison
tomiko_files <- c(
  ESE = "../endo_tomiko_code/replication/drug_instances_ESE_replicated.csv",
  InII = "../endo_tomiko_code/replication/drug_instances_InII_replicated.csv",
  IIInIV = "../endo_tomiko_code/replication/drug_instances_IIInIV_replicated.csv",
  MSE = "../endo_tomiko_code/replication/drug_instances_MSE_replicated.csv",
  PE = "../endo_tomiko_code/replication/drug_instances_PE_replicated.csv",
  Unstratified = "../endo_tomiko_code/replication/drug_instances_Unstratified_replicated.csv"
)

# Short names for output
short_names <- c("ESE", "InII", "IIInIV", "MSE", "PE", "Unstratified")

# Results summary
results_summary <- data.frame(
  Signature = character(),
  Tomiko_Drugs = integer(),
  DRpipe_Drugs = integer(),
  Overlap = integer(),
  Jaccard = numeric(),
  Top20_Overlap = integer(),
  stringsAsFactors = FALSE
)

for (i in seq_along(profiles)) {
  profile <- profiles[i]
  short_name <- short_names[i]
  
  cat("\n================================================================\n")
  cat(sprintf("Processing: %s\n", short_name))
  cat("================================================================\n")
  
  # Load config for this profile
  cfg <- config::get(config = profile)
  
  # Create output directory
  out_dir <- file.path("results", paste0("endo_v3_", short_name))
  
  # Run DRpipe
  drp <- DRP$new(
    signatures_rdata    = cfg$paths$signatures,
    disease_path        = cfg$paths$disease_file,
    drug_meta_path      = cfg$paths$drug_meta,
    drug_valid_path     = cfg$paths$drug_valid,
    out_dir             = out_dir,
    gene_key            = cfg$params$gene_key,
    logfc_cols_pref     = cfg$params$logfc_cols_pref,
    gene_conversion_table = cfg$params$gene_conversion_table,
    logfc_cutoff        = cfg$params$logfc_cutoff,
    percentile_filtering = cfg$params$percentile_filtering,
    pval_key            = cfg$params$pval_key,
    pval_cutoff         = cfg$params$pval_cutoff,
    q_thresh            = cfg$params$q_thresh,
    reversal_only       = cfg$params$reversal_only,
    seed                = cfg$params$seed,
    n_permutations      = cfg$params$n_permutations,
    pvalue_method       = cfg$params$pvalue_method,
    phipson_smyth_correction = cfg$params$phipson_smyth_correction,
    mode                = cfg$params$mode,
    combine_log2fc      = cfg$params$combine_log2fc,
    probe_id_key        = cfg$params$probe_id_key,
    probe_id_fallback   = if (!is.null(cfg$params$probe_id_fallback)) cfg$params$probe_id_fallback else TRUE,
    analysis_id         = "cmap",
    verbose             = TRUE
  )
  
  # Run pipeline
  drp$run_all(make_plots = FALSE)
  
  # Load DRpipe results
  drpipe_file <- list.files(out_dir, pattern = "_hits_.*\\.csv$", full.names = TRUE)[1]
  drpipe <- read.csv(drpipe_file)
  drpipe_rev <- drpipe[drpipe$q == 0 & drpipe$cmap_score < 0, ]
  
  # Load Tomiko results
  tomiko_file <- tomiko_files[short_name]
  if (file.exists(tomiko_file)) {
    tomiko <- read.csv(tomiko_file)
    tomiko_rev <- tomiko[tomiko$q == 0 & tomiko$cmap_score < 0, ]
    
    # Compare
    overlap <- length(intersect(tomiko_rev$exp_id, drpipe_rev$exp_id))
    jaccard <- overlap / length(union(tomiko_rev$exp_id, drpipe_rev$exp_id))
    
    # Top 20
    tomiko_top20 <- head(tomiko_rev[order(tomiko_rev$cmap_score), ], 20)$exp_id
    drpipe_top20 <- head(drpipe_rev[order(drpipe_rev$cmap_score), ], 20)$exp_id
    top20_overlap <- length(intersect(tomiko_top20, drpipe_top20))
    
    results_summary <- rbind(results_summary, data.frame(
      Signature = short_name,
      Tomiko_Drugs = nrow(tomiko_rev),
      DRpipe_Drugs = nrow(drpipe_rev),
      Overlap = overlap,
      Jaccard = round(jaccard * 100, 1),
      Top20_Overlap = top20_overlap
    ))
    
    cat(sprintf("\n%s: Tomiko=%d, DRpipe=%d, Overlap=%d, Jaccard=%.1f%%, Top20=%d/20\n",
                short_name, nrow(tomiko_rev), nrow(drpipe_rev), overlap, jaccard*100, top20_overlap))
  } else {
    cat(sprintf("Warning: Tomiko file not found for %s\n", short_name))
  }
}

cat("\n\n================================================================\n")
cat("FINAL SUMMARY\n")
cat("================================================================\n\n")
print(results_summary)

# Save summary
write.csv(results_summary, "results/endo_v3_comparison_summary.csv", row.names = FALSE)
cat("\nSummary saved to: results/endo_v3_comparison_summary.csv\n")
