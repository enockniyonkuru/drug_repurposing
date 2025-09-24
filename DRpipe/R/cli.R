#' Command-line interface entrypoint
#'
#' Examples:
#' \preformatted{
#'   # Run a single pipeline execution from config
#'   Rscript -e "DRpipe::dr_cli()" run --config scripts/config.yml --profile default --make-plots --verbose
#'
#'   # Analyze all *_results.RData in scripts/results and write reports
#'   Rscript -e "DRpipe::dr_cli()" analyze --config scripts/config.yml --profile default --verbose
#'
#'   # Print the merged config the CLI is using (for debugging)
#'   Rscript -e "DRpipe::dr_cli()" run --config scripts/config.yml --profile default --print-config
#' }
#'
#' If you ship an executable under inst/scripts (see README), you can also do:
#' \preformatted{
#'   drugrep run --config scripts/config.yml --profile default
#'   drugrep analyze --config scripts/config.yml --profile default
#' }
#'
#' @export
dr_cli <- function() {
  if (!requireNamespace("docopt", quietly = TRUE)) {
    stop("Please install 'docopt' to use the CLI: install.packages('docopt')")
  }

  doc <- "
Drug Repurposing CLI

Usage:
  drugrep run      [--config=<path>] [--profile=<name>] [--make-plots] [--verbose] [--print-config]
  drugrep analyze  [--config=<path>] [--profile=<name>] [--results-dir=<path>] [--analysis-dir=<path>] [--pattern=<regex>] [--verbose] [--print-config]
  drugrep help
  drugrep (-h | --help)
  drugrep --version

Options:
  --config=<path>       Path to config.yml (defaults: inst/config.yml or scripts/config.yml)
  --profile=<name>      Config profile name [default: default]
  --make-plots          Generate standard plots for 'run' [default: false]
  --results-dir=<path>  Directory containing *_results.RData [default: scripts/results]
  --analysis-dir=<path> Output directory for analysis reports [default: scripts/results/analysis]
  --pattern=<regex>     Regex to select result files [default: _results\\.RData$]
  --verbose             Verbose logs [default: false]
  --print-config        Print the merged config the CLI will use and exit
  -h --help             Show this screen.
  --version             Show version.

Config schema (YAML):
  paths:
    signatures:      path/to/cmap_signatures.RData
    disease_file:    path/to/disease.csv      # OR: disease_dir + disease_pattern
    disease_dir:     path/to/folder
    disease_pattern: CoreFibroidSignature_All_Datasets.csv
    cmap_meta:       path/to/cmap_drug_experiments_new.csv
    cmap_valid:      path/to/cmap_valid_instances.csv
    out_dir:         scripts/results
  params:
    gene_key:        SYMBOL
    logfc_cols_pref: log2FC
    logfc_cutoff:    1
    q_thresh:        0.05
    reversal_only:   true
    seed:            123
"

  args <- docopt::docopt(doc, version = "drugrep CLI 0.2.0")

  # Helper for null-coalescing without masking other definitions
  or_null <- function(x, y) if (is.null(x)) y else x

  # Subcommand: help/version handled by docopt; just return
  if (!is.null(args$help) && isTRUE(args$help)) {
    cat(doc, "\n")
    return(invisible(TRUE))
  }

  # Load config (shared)
  cfg <- tryCatch(
    load_dr_config(profile = args$profile, config_file = args$config),
    error = function(e) stop("Failed to load config: ", e$message)
  )

  # If requested, show the merged config (useful for debugging CI/paths)
  if (isTRUE(args$`print-config`)) {
    pretty <- function(x, indent = 0) {
      pad <- paste(rep(" ", indent), collapse = "")
      if (is.list(x)) {
        for (nm in names(x)) {
          cat(pad, nm, ":\n", sep = "")
          pretty(x[[nm]], indent + 2)
        }
      } else {
        cat(pad, x, "\n", sep = "")
      }
    }
    cat("----- Merged config (profile = ", args$profile, ") -----\n", sep = "")
    pretty(cfg)
    cat("-------------------------------------------------------\n")
    return(invisible(TRUE))
  }

  # Route by subcommand
  if (isTRUE(args$run)) {
    # Support either disease_file OR disease_dir+pattern
    disease_path    <- cfg$paths$disease_file %||% cfg$paths$disease_dir
    disease_pattern <- if (is.null(cfg$paths$disease_file)) cfg$paths$disease_pattern else NULL

    # Basic validation & friendly messages
    must_keys <- c("signatures")
    missing <- setdiff(must_keys, names(cfg$paths %||% list()))
    if (length(missing)) stop("Missing required config.paths key(s): ", paste(missing, collapse = ", "))

    invisible(run_dr(
      signatures_rdata = cfg$paths$signatures,
      disease_path     = disease_path,
      disease_pattern  = disease_pattern,
      cmap_meta_path   = cfg$paths$cmap_meta %||% NULL,
      cmap_valid_path  = cfg$paths$cmap_valid %||% NULL,
      out_dir          = cfg$paths$out_dir %||% "scripts/results",
      gene_key         = cfg$params$gene_key %||% "SYMBOL",
      logfc_cols_pref  = cfg$params$logfc_cols_pref %||% "log2FC",
      logfc_cutoff     = cfg$params$logfc_cutoff %||% 1,
      q_thresh         = cfg$params$q_thresh %||% 0.05,
      reversal_only    = isTRUE(cfg$params$reversal_only %||% TRUE),
      seed             = cfg$params$seed %||% 123,
      verbose          = isTRUE(args$verbose),
      make_plots       = isTRUE(args$`make-plots`)
    ))
    return(invisible(TRUE))
  }

  if (isTRUE(args$analyze)) {
    # Pull defaults from config but allow CLI overrides for dirs/pattern
    results_dir  <- or_null(args$`results-dir`, cfg$paths$out_dir %||% "scripts/results")
    analysis_dir <- or_null(args$`analysis-dir`, file.path(results_dir, "analysis"))
    pattern      <- args$pattern %||% "_results\\.RData$"

    # Validate analysis essentials
    need <- c("cmap_meta", "cmap_valid", "signatures")
    have <- names(cfg$paths %||% list())
    miss <- setdiff(need, have)
    if (length(miss)) {
      stop("For 'analyze', config.paths must include: ", paste(need, collapse = ", "),
           ". Missing: ", paste(miss, collapse = ", "))
    }

    # Run batch analysis (requires you added analyze_runs() in pipeline_analysis.R)
    invisible(analyze_runs(
      results_dir          = results_dir,
      analysis_dir         = analysis_dir,
      cmap_meta_path       = cfg$paths$cmap_meta,
      cmap_valid_path      = cfg$paths$cmap_valid,
      cmap_signatures_path = cfg$paths$signatures,
      q_thresh             = cfg$params$q_thresh %||% 0.05,
      reversal_only        = isTRUE(cfg$params$reversal_only %||% TRUE),
      verbose              = isTRUE(args$verbose)
    ))

    # Note: file selection by pattern happens inside DRA$load_runs (default pattern),
    # but if you want to enforce here, you could pass pattern through analyze_runs/DRA.
    return(invisible(TRUE))
  }

  # Fallback: show usage
  cat(doc, "\n")
  invisible(TRUE)
}

# Keep a small null-coalesce helper visible for this file
`%||%` <- function(x, y) if (is.null(x)) y else x
