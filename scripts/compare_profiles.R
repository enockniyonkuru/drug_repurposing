#!/usr/bin/env Rscript
#' Compare Pipeline Profiles
#'
#' Performs automated comparison across multiple configuration profiles.
#' Runs the pipeline with different parameters and performs cross-profile
#' analysis to evaluate impact of parameter variations on results.

suppressPackageStartupMessages(library(CDRPipe))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(gplots))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(pheatmap))
suppressPackageStartupMessages(library(UpSetR))
suppressPackageStartupMessages(library(grid))

find_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE)))
  }

  frame_files <- vapply(sys.frames(), function(frame) {
    if (is.null(frame$ofile)) NA_character_ else frame$ofile
  }, character(1))
  frame_files <- frame_files[!is.na(frame_files)]
  if (length(frame_files) > 0) {
    return(dirname(normalizePath(frame_files[[length(frame_files)]], winslash = "/", mustWork = FALSE)))
  }

  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

script_dir <- find_script_dir()
config_file <- file.path(script_dir, "config.yml")

# Load helper function
source(file.path(script_dir, "load_execution_config.R"), chdir = FALSE)

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

  drp <- new_drp_from_config(cfg, out_dir = out, verbose = TRUE)
  drp$run_all(make_plots = TRUE)

  return(list(profile = profile_name, output_dir = out, config = cfg))
}

# Function to load results from a profile run
load_profile_results <- function(output_dir, profile_name) {
  csv_files <- list.files(output_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  hit_files <- csv_files[
    grepl("(_hits_logFC_.*\\.csv$|_hits_q<.*\\.csv$|_hits\\.csv$|robust_hits\\.csv$)", basename(csv_files))
  ]

  if (length(hit_files) > 1) {
    hit_priority <- c(
      "_hits_logFC_.*\\.csv$",
      "_hits_q<.*\\.csv$",
      "_hits\\.csv$",
      "robust_hits\\.csv$"
    )
    priority_rank <- rep(length(hit_priority) + 1L, length(hit_files))
    hit_names <- basename(hit_files)
    for (i in seq_along(hit_priority)) {
      priority_rank[grepl(hit_priority[[i]], hit_names)] <- i
    }
    hit_files <- hit_files[order(priority_rank, hit_names)]
  }
  
  if (length(hit_files) > 0) {
    cat("Loading filtered hits from CSV:", hit_files[1], "\n")
    drugs <- read.csv(hit_files[1], stringsAsFactors = FALSE)
    cat("Loaded", nrow(drugs), "significant hits for", profile_name, "\n")
  } else {
    # Fallback: load from RData file
    result_files <- list.files(output_dir, pattern = "_results\\.RData$", full.names = TRUE)

    if (length(result_files) == 0) {
      warning("No results file found in ", output_dir)
      return(NULL)
    }

    result_env <- new.env(parent = emptyenv())
    load(result_files[1], envir = result_env)
    if (!exists("results", envir = result_env, inherits = FALSE)) {
      warning("Results object not found in ", result_files[1])
      return(NULL)
    }

    # Extract drug predictions and disease signatures
    drugs <- result_env$results[[1]]
    dz_signature <- result_env$results[[2]]
  }

  # Add profile identifier if not already present
  if (!"profile" %in% names(drugs)) {
    drugs$profile <- profile_name
  }
  if (!"subset_comparison_id" %in% names(drugs)) {
    drugs$subset_comparison_id <- profile_name
  }

  return(list(drugs = drugs, dz_signature = NULL))
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
comparison_dir <- file.path(script_dir, "results", "profile_comparison", format(Sys.time(), "%Y%m%d-%H%M%S"))
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

# Get first profile's config to load metadata
first_profile <- names(profile_results)[1]
if (is.null(first_profile) || !exists("first_profile")) {
  warning("No valid profiles found. Skipping filtering.")
  drugs_filtered <- drugs_list
} else {
  # The CSV files already contain filtered, valid drugs with metadata
  # We just need to ensure consistent column names and remove any NAs
  drugs_filtered <- lapply(names(drugs_list), function(profile_name) {
    x <- drugs_list[[profile_name]]
    cat("Debug: Profile", profile_name, "has", nrow(x), "drugs\n")
    
    # Update subset_comparison_id to match profile name for grouping
    if (nrow(x) > 0) {
      x$subset_comparison_id <- profile_name
      x$profile <- profile_name
      
      # Remove rows with missing name or cmap_score
      if ("name" %in% names(x)) {
        x <- x[!is.na(x$name) & x$name != "", ]
      }
      if ("cmap_score" %in% names(x)) {
        x <- x[!is.na(x$cmap_score), ]
      }
      cat("Debug: Profile", profile_name, "after cleanup:", nrow(x), "drugs\n")
    }
    x
  })
  names(drugs_filtered) <- names(drugs_list)
}

# Step 4: Generate comparison visualizations
cat("Generating comparison visualizations...\n")

# Plot score distributions across profiles
pl_hist_revsc(drugs_filtered, save = "profile_comparison_score_dist.jpg", path = paste0(img_dir, "/"))

# Combine results for cross-profile analysis
drugs_combined <- do.call("rbind", drugs_filtered)

# Remove rows with missing critical columns
drugs_combined <- drugs_combined[!is.na(drugs_combined$name) & drugs_combined$name != "" &
                                 !is.na(drugs_combined$subset_comparison_id) & 
                                 !is.na(drugs_combined$cmap_score), ]

cat("Combined dataset has", nrow(drugs_combined), "rows after removing NAs\n")

if (nrow(drugs_combined) > 0) {
  # Overlap analysis across profiles
  pl_overlap(drugs_combined, save = "profile_overlap_heatmap.jpg", path = paste0(img_dir, "/"))
  pl_overlap(drugs_combined, at_least2 = TRUE, width = 7,
             save = "profile_overlap_atleast2.jpg", path = paste0(img_dir, "/"))

  # UpSet plot for profile intersections
  profile_drug_sets <- prepare_upset_drug(drugs_combined)
  pl_upset(profile_drug_sets, title = "Drug Overlap Across Profiles",
           save = "profile_upset.jpg", path = paste0(img_dir, "/"))

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
