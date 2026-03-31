#!/usr/bin/env Rscript
#' Run Complete Drug Repurposing Pipeline
#'
#' Executes the full drug repurposing analysis pipeline using configuration
#' from YAML file. Supports single and sweep modes for parameter exploration
#' and generates comprehensive ranked drug candidate results.
suppressPackageStartupMessages(library(CDRPipe))

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
source(file.path(script_dir, "load_execution_config.R"), chdir = FALSE)

config_file <- file.path(script_dir, "config.yml")
exec_cfg <- load_execution_config(config_file)
profile_to_use <- exec_cfg$runall_profile %||% "default"
cat("Using profile:", profile_to_use, "\n")

# Load config for the specified profile
cfg <- load_profile_config(profile = profile_to_use, config_file = config_file)

# 1) Resolve output dir and make a timestamped subfolder with profile name
ts    <- format(Sys.time(), "%Y%m%d-%H%M%S")
root  <- cfg$paths$out_dir %||% "results"
folder_name <- paste0(profile_to_use, "_", ts)
out   <- file.path(root, folder_name)
io_ensure_dir(out)

drp <- new_drp_from_config(cfg, out_dir = out, verbose = TRUE)

# Run the pipeline with plots
drp$run_all(make_plots = TRUE)

# 4) Provenance: save effective config + session info
yaml_path <- file.path(out, "config_effective.yml")
try({
  # write a minimal effective config snapshot
  eff <- list(
    profile = profile_to_use,
    config_file = config_file,
    paths = cfg$paths,
    params = cfg$params
  )
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
