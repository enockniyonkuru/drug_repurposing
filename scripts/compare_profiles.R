#!/usr/bin/env Rscript
# ------------------------------------------------------------------------------
# Script: compare_profiles.R
#
# This script performs automated comparison across multiple configuration
# profiles (e.g., different logfc_cutoff values). It runs the pipeline with
# each profile, then performs cross-profile analysis similar to DR_analysis.R
# but focused on parameter comparison rather than dataset comparison.
# ------------------------------------------------------------------------------

suppressPackageStartupMessages(library(DRpipe))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(gplots))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(pheatmap))
suppressPackageStartupMessages(library(UpSetR))
suppressPackageStartupMessages(library(grid))

# Configuration
config_file <- "config.yml"

# Load helper function
source("load_execution_config.R")

# Load execution configuration to get profiles to compare
exec_cfg <- load_execution_config(config_file)
profiles_to_compare <- exec_cfg$compare_profiles %||% c("default")
cat("Profiles to compare:", paste(profiles_to_compare, collapse = ", "), "\n")

# Function to run pipeline with a specific profile
run_profile <- function(profile_name, config_file) {
  cat("Running pipeline with profile:", profile_name, "\n")

  # Load config for this profile using our fixed function
  cfg <- load_profile_config(profile = profile_name, config_file = config_file)

  # Create timestamped output directory
  ts <- format(Sys.time(), "%Y%m%d-%H%M%S")
  root <- cfg$paths$out_dir %||% "results"
  out <- file.path(root, paste0(profile_name, "_", ts))
  io_ensure_dir(out)

  # Run pipeline
  run_dr(
    signatures_rdata = cfg$paths$signatures,
    disease_path     = cfg$paths$disease_file %||% cfg$paths$disease_dir,
    disease_pattern  = if (is.null(cfg$paths$disease_file)) cfg$paths$disease_pattern else NULL,
    cmap_meta_path   = cfg$paths$cmap_meta,
    cmap_valid_path  = cfg$paths$cmap_valid,
    out_dir          = out,
    gene_key         = cfg$params$gene_key %||% "SYMBOL",
    logfc_cols_pref  = cfg$params$logfc_cols_pref %||% "log2FC",
    logfc_cutoff     = cfg$params$logfc_cutoff %||% 1,
    q_thresh         = cfg$params$q_thresh %||% 0.05,
    reversal_only    = isTRUE(cfg$params$reversal_only %||% TRUE),
    seed             = cfg$params$seed %||% 123,
    verbose          = TRUE,
    make_plots       = TRUE
  )

  return(list(profile = profile_name, output_dir = out, config = cfg))
}

# Function to load results from a profile run
load_profile_results <- function(output_dir, profile_name) {
  # Find the results RData file
  result_files <- list.files(output_dir, pattern = "_results\\.RData$", full.names = TRUE)

  if (length(result_files) == 0) {
    warning("No results file found in ", output_dir)
    return(NULL)
  }

  # Load the results
  load(result_files[1])  # loads 'results' object

  # Extract drug predictions and disease signatures
  drugs <- results[[1]]
  dz_signature <- results[[2]]

  # Add profile identifier
  drugs$profile <- profile_name
  drugs$subset_comparison_id <- profile_name

  return(list(drugs = drugs, dz_signature = dz_signature))
}

# Main execution
cat("=== Multi-Profile Drug Repurposing Comparison ===\n")

# Step 1: Run pipeline with each profile
profile_results <- list()
for (profile in profiles_to_compare) {
  tryCatch({
    run_info <- run_profile(profile, config_file)
    profile_results[[profile]] <- run_info
    cat("Completed profile:", profile, "\n")
  }, error = function(e) {
    cat("Error running profile", profile, ":", e$message, "\n")
  })
}

# Step 2: Load and process results
cat("\n=== Loading and Processing Results ===\n")

# Set up output directories for comparison analysis
comparison_dir <- file.path("results", "profile_comparison", format(Sys.time(), "%Y%m%d-%H%M%S"))
io_ensure_dir(comparison_dir)
img_dir <- file.path(comparison_dir, "img")
io_ensure_dir(img_dir)

# Load results from each profile
drugs_list <- list()
dz_signatures_list <- list()

for (profile in names(profile_results)) {
  if (!is.null(profile_results[[profile]])) {
    results_data <- load_profile_results(profile_results[[profile]]$output_dir, profile)
    if (!is.null(results_data)) {
      drugs_list[[profile]] <- results_data$drugs
      dz_signatures_list[[profile]] <- results_data$dz_signature
    }
  }
}

if (length(drugs_list) == 0) {
  stop("No valid results loaded. Check profile configurations and pipeline execution.")
}

# Step 3: Filter for valid instances
cat("Filtering for valid drug instances...\n")

# Load CMAP metadata
cmap_experiments <- read.csv(profile_results[[1]]$config$paths$cmap_meta, stringsAsFactors = FALSE)
valid_instances <- read.csv(profile_results[[1]]$config$paths$cmap_valid, stringsAsFactors = FALSE)

# Merge and filter valid experiments
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by = "id")
cmap_experiments_valid <- subset(cmap_experiments_valid, valid == 1 & DrugBank.ID != "NULL")

# Apply filtering to each profile's results
drugs_filtered <- lapply(drugs_list, function(x) {
  if (nrow(x) > 0) {
    valid_instance(x, cmap_experiments_valid)
  } else {
    x
  }
})

# Step 4: Generate comparison visualizations
cat("Generating comparison visualizations...\n")

# Plot score distributions across profiles
pl_hist_revsc(drugs_filtered, save = "profile_comparison_score_dist.jpg", path = img_dir)

# Combine results for cross-profile analysis
drugs_combined <- do.call("rbind", drugs_filtered)

if (nrow(drugs_combined) > 0) {
  # Overlap analysis across profiles
  pl_overlap(drugs_combined, save = "profile_overlap_heatmap.jpg", path = img_dir)
  pl_overlap(drugs_combined, at_least2 = TRUE, width = 7,
             save = "profile_overlap_atleast2.jpg", path = img_dir)

  # UpSet plot for profile intersections
  profile_drug_sets <- prepare_upset_drug(drugs_combined)
  pl_upset(profile_drug_sets, title = "Drug Overlap Across Profiles",
           save = "profile_upset.jpg", path = img_dir)

  # Export individual profile results
  for (profile in names(drugs_filtered)) {
    if (nrow(drugs_filtered[[profile]]) > 0) {
      write.csv(drugs_filtered[[profile]],
                file = file.path(comparison_dir, paste0(profile, "_hits.csv")),
                row.names = FALSE)
    }
  }

  # Export combined results
  write.csv(drugs_combined,
            file = file.path(comparison_dir, "combined_profile_hits.csv"),
            row.names = FALSE)

  # Generate summary statistics
  summary_stats <- drugs_combined %>%
    group_by(profile) %>%
    summarise(
      total_hits = n(),
      significant_hits = sum(q < 0.05, na.rm = TRUE),
      mean_cmap_score = mean(cmap_score, na.rm = TRUE),
      median_cmap_score = median(cmap_score, na.rm = TRUE),
      .groups = 'drop'
    )

  write.csv(summary_stats,
            file = file.path(comparison_dir, "profile_summary_stats.csv"),
            row.names = FALSE)

  cat("Summary Statistics:\n")
  print(summary_stats)

} else {
  cat("No valid drug hits found across profiles.\n")
}

# Step 5: Generate comparison report
cat("\n=== Generating Comparison Report ===\n")

report_file <- file.path(comparison_dir, "profile_comparison_report.md")
cat("# Profile Comparison Report\n\n", file = report_file)
cat("Generated on:", format(Sys.time()), "\n\n", file = report_file, append = TRUE)

cat("## Profiles Compared\n\n", file = report_file, append = TRUE)
for (profile in names(profile_results)) {
  cfg <- profile_results[[profile]]$config
  cat("### ", profile, "\n", file = report_file, append = TRUE)
  cat("- logfc_cutoff:", cfg$params$logfc_cutoff, "\n", file = report_file, append = TRUE)
  cat("- q_thresh:", cfg$params$q_thresh, "\n", file = report_file, append = TRUE)
  cat("- Output directory:", profile_results[[profile]]$output_dir, "\n\n", file = report_file, append = TRUE)
}

if (exists("summary_stats")) {
  cat("## Summary Statistics\n\n", file = report_file, append = TRUE)
  cat("```\n", file = report_file, append = TRUE)
  capture.output(print(summary_stats), file = report_file, append = TRUE)
  cat("```\n\n", file = report_file, append = TRUE)
}

cat("## Output Files\n\n", file = report_file, append = TRUE)
cat("- Individual profile hits: `*_hits.csv`\n", file = report_file, append = TRUE)
cat("- Combined results: `combined_profile_hits.csv`\n", file = report_file, append = TRUE)
cat("- Summary statistics: `profile_summary_stats.csv`\n", file = report_file, append = TRUE)
cat("- Visualizations: `img/` directory\n\n", file = report_file, append = TRUE)

cat("Profile comparison completed successfully!\n")
cat("Results saved to:", comparison_dir, "\n")

# Helper function (define at end to avoid conflicts)
`%||%` <- function(x, y) if (is.null(x)) y else x
