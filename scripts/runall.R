#!/usr/bin/env Rscript
#' Run Complete Drug Repurposing Pipeline
#'
#' Executes the full drug repurposing analysis pipeline using configuration
#' from YAML file. Supports single and sweep modes for parameter exploration
#' and generates comprehensive ranked drug candidate results.
library(DRpipe)
source("load_execution_config.R")
exec_cfg <- load_execution_config("config.yml")
profile_to_use <- exec_cfg$runall_profile %||% "default"
cat("Using profile:", profile_to_use, "\n")

# Load config for the specified profile using our fixed function
cfg <- load_profile_config(profile = profile_to_use, config_file = "config.yml")

# 1) Resolve output dir and make a timestamped subfolder with profile name
ts    <- format(Sys.time(), "%Y%m%d-%H%M%S")
root  <- cfg$paths$out_dir %||% "results"
folder_name <- paste0(profile_to_use, "_", ts)
out   <- file.path(root, folder_name)
io_ensure_dir(out)

# 2) Derive disease inputs (file or dir+pattern)
disease_path    <- cfg$paths$disease_file %||% cfg$paths$disease_dir
disease_pattern <- if (is.null(cfg$paths$disease_file)) cfg$paths$disease_pattern else NULL

# 3) Run the pipeline using DRP class to access all new parameters
drp <- DRP$new(
  signatures_rdata = cfg$paths$signatures,
  disease_path     = disease_path,
  disease_pattern  = disease_pattern,
  # Handle both old and new parameter names for backward compatibility
  cmap_meta_path   = cfg$paths$cmap_meta %||% NULL,
  cmap_valid_path  = cfg$paths$cmap_valid %||% NULL,
  drug_meta_path   = cfg$paths$drug_meta %||% NULL,
  drug_valid_path  = cfg$paths$drug_valid %||% NULL,
  out_dir          = out,
  gene_key         = cfg$params$gene_key %||% "SYMBOL",
  logfc_cols_pref  = cfg$params$logfc_cols_pref %||% "log2FC",
  logfc_cutoff     = cfg$params$logfc_cutoff %||% 1,
  pval_key         = cfg$params$pval_key %||% NULL,
  pval_cutoff      = cfg$params$pval_cutoff %||% 0.05,
  q_thresh         = cfg$params$q_thresh %||% 0.05,
  reversal_only    = isTRUE(cfg$params$reversal_only %||% TRUE),
  seed             = cfg$params$seed %||% 123,
  verbose          = TRUE,
  analysis_id      = cfg$params$analysis_id %||% "cmap",
  # New sweep mode parameters
  mode             = cfg$params$mode %||% "single",
  sweep_cutoffs    = cfg$params$sweep_cutoffs %||% NULL,
  sweep_auto_grid  = isTRUE(cfg$params$sweep_auto_grid %||% TRUE),
  sweep_step       = cfg$params$sweep_step %||% 0.1,
  sweep_min_frac   = cfg$params$sweep_min_frac %||% 0.20,
  sweep_min_genes  = cfg$params$sweep_min_genes %||% 200,
  sweep_stop_on_small = isTRUE(cfg$params$sweep_stop_on_small %||% FALSE),
  combine_log2fc   = cfg$params$combine_log2fc %||% "average",
  robust_rule      = cfg$params$robust_rule %||% "all",
  robust_k         = cfg$params$robust_k %||% NULL,
  aggregate        = cfg$params$aggregate %||% "mean",
  weights          = cfg$params$weights %||% NULL,
  # Original script functionality parameters
  apply_meta_filters    = isTRUE(cfg$params$apply_meta_filters %||% FALSE),
  min_studies           = cfg$params$min_studies %||% 2,
  effect_fdr_thresh     = cfg$params$effect_fdr_thresh %||% 0.05,
  heterogeneity_thresh  = cfg$params$heterogeneity_thresh %||% 0.05,
  gene_conversion_table = cfg$params$gene_conversion_table %||% NULL,
  percentile_filtering  = cfg$params$percentile_filtering %||% NULL,
  save_count_files      = isTRUE(cfg$params$save_count_files %||% FALSE),
  n_permutations        = cfg$params$n_permutations %||% 100000,
  save_null_scores      = isTRUE(cfg$params$save_null_scores %||% FALSE),
  per_threshold_dirs    = isTRUE(cfg$params$per_threshold_dirs %||% FALSE),
  blood_label           = cfg$params$blood_label %||% "blood"
)

# Run the pipeline with plots
drp$run_all(make_plots = TRUE)

# 4) Provenance: save effective config + session info
yaml_path <- file.path(out, "config_effective.yml")
try({
  # write a minimal effective config snapshot
  eff <- list(paths = cfg$paths, params = cfg$params)
  # cheap YAML writer without extra deps
  capture_yaml <- function(x, indent = 0) {
    pad <- paste(rep(" ", indent), collapse = "")
    if (is.list(x)) {
      out <- ""
      for (nm in names(x)) {
        out <- paste0(out, pad, nm, ":\n", capture_yaml(x[[nm]], indent + 2))
      }
      return(out)
    } else {
      return(paste0(pad, x, "\n"))
    }
  }
  cat(capture_yaml(eff), file = yaml_path)
}, silent = TRUE)

sink(file.path(out, "sessionInfo.txt")); print(sessionInfo()); sink()

cat("[runall] Finished. Results in: ", out, "\n")

`%||%` <- function(x, y) if (is.null(x)) y else x
