#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(DRpipe))

# 0) Load helper function and execution config to get profile
source("load_execution_config.R")
exec_cfg <- load_execution_config("config.yml")
profile_to_use <- exec_cfg$runall_profile %||% "default"
cat("Using profile:", profile_to_use, "\n")

# Load config for the specified profile using our fixed function
cfg <- load_profile_config(profile = profile_to_use, config_file = "config.yml")

# 1) Resolve output dir and make a timestamped subfolder
ts    <- format(Sys.time(), "%Y%m%d-%H%M%S")
root  <- cfg$paths$out_dir %||% "results"
out   <- file.path(root, ts)
io_ensure_dir(out)

# 2) Derive disease inputs (file or dir+pattern)
disease_path    <- cfg$paths$disease_file %||% cfg$paths$disease_dir
disease_pattern <- if (is.null(cfg$paths$disease_file)) cfg$paths$disease_pattern else NULL

# 3) Run the pipeline
run_dr(
  signatures_rdata = cfg$paths$signatures,
  disease_path     = disease_path,
  disease_pattern  = disease_pattern,
  cmap_meta_path   = cfg$paths$cmap_meta %||% NULL,
  cmap_valid_path  = cfg$paths$cmap_valid %||% NULL,
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
