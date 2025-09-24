#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(DRpipe))

# 1) Load helper function and execution config to get profile
source("load_execution_config.R")
exec_cfg <- load_execution_config("config.yml")
profile_to_use <- exec_cfg$analyze_profile %||% "default"
cat("Using profile:", profile_to_use, "\n")

# Load config for the specified profile using our fixed function
cfg <- load_profile_config(profile_to_use, "config.yml")

results_dir  <- cfg$analysis$results_dir  %||% "results"
analysis_root<- cfg$analysis$analysis_dir %||% file.path(results_dir, "analysis")
pattern      <- cfg$analysis$pattern      %||% "_results\\.RData$"

# 2) Timestamped analysis folder to avoid overwrites
ts  <- format(Sys.time(), "%Y%m%d-%H%M%S")
out <- file.path(analysis_root, ts)
io_ensure_dir(out)

# 3) Quick sanity check: do we have any results?
# Use recursive search to find files in timestamped subdirectories
files <- list.files(results_dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
if (!length(files)) stop("No result files matching '", pattern, "' found in ", results_dir)

# 4) Run cross-run analysis
analyze_runs(
  results_dir          = results_dir,
  analysis_dir         = out,
  cmap_meta_path       = cfg$paths$cmap_meta,
  cmap_valid_path      = cfg$paths$cmap_valid,
  cmap_signatures_path = cfg$paths$signatures,
  q_thresh             = cfg$params$q_thresh %||% 0.05,
  reversal_only        = isTRUE(cfg$params$reversal_only %||% TRUE),
  verbose              = TRUE
)

# 5) Provenance
sink(file.path(out, "sessionInfo.txt")); print(sessionInfo()); sink()
cat("results_dir: ", results_dir,  "\n", file = file.path(out, "inputs.txt"))
cat("pattern:     ", pattern,      "\n", file = file.path(out, "inputs.txt"), append = TRUE)
cat("[analyze] Done. Outputs in: ", out, "\n")

`%||%` <- function(x, y) if (is.null(x)) y else x
