#!/usr/bin/env Rscript
#' Load Execution Configuration
#'
#' Helper functions to load and parse execution configuration from YAML files.
#' Provides utilities for loading profile-specific configurations and resolving
#' file paths for pipeline execution.

`%||%` <- function(x, y) if (is.null(x)) y else x

resolve_config_file <- function(config_file = "config.yml") {
  config_path <- normalizePath(path.expand(config_file), winslash = "/", mustWork = FALSE)
  if (!file.exists(config_path)) {
    stop("Configuration file not found: ", config_file, call. = FALSE)
  }
  config_path
}

resolve_path_from_config <- function(path, base_dir) {
  if (is.null(path) || !nzchar(path)) {
    return(path)
  }

  expanded <- path.expand(path)
  if (!grepl("^(/|[A-Za-z]:|~)", expanded)) {
    expanded <- file.path(base_dir, expanded)
  }

  normalizePath(expanded, winslash = "/", mustWork = FALSE)
}

validate_profile_config <- function(cfg, profile = "default", config_file = "config.yml") {
  if (is.null(cfg$paths)) {
    stop("Profile '", profile, "' in ", config_file, " is missing a `paths` section.", call. = FALSE)
  }

  required_paths <- c("signatures")
  missing_required <- required_paths[vapply(required_paths, function(name) {
    is.null(cfg$paths[[name]]) || !nzchar(cfg$paths[[name]])
  }, logical(1))]

  if (length(missing_required) > 0) {
    stop(
      "Profile '", profile, "' in ", config_file,
      " is missing required path settings: ", paste(missing_required, collapse = ", "),
      call. = FALSE
    )
  }

  if (is.null(cfg$paths$disease_file) && is.null(cfg$paths$disease_dir)) {
    stop(
      "Profile '", profile, "' in ", config_file,
      " must define either `paths$disease_file` or `paths$disease_dir`.",
      call. = FALSE
    )
  }

  existing_paths <- c(
    signatures = cfg$paths$signatures,
    disease_file = cfg$paths$disease_file,
    disease_dir = cfg$paths$disease_dir,
    drug_meta = cfg$paths$drug_meta,
    drug_valid = cfg$paths$drug_valid,
    cmap_meta = cfg$paths$cmap_meta,
    cmap_valid = cfg$paths$cmap_valid
  )

  for (name in names(existing_paths)) {
    path <- existing_paths[[name]]
    if (is.null(path) || !nzchar(path)) {
      next
    }

    exists_on_disk <- if (identical(name, "disease_dir")) dir.exists(path) else file.exists(path)
    if (!exists_on_disk) {
      stop(
        "Profile '", profile, "' in ", config_file,
        " points to a missing ", name, ": ", path,
        call. = FALSE
      )
    }
  }

  conversion_table <- cfg$params$gene_conversion_table %||% NULL
  if (!is.null(conversion_table) && nzchar(conversion_table) && !file.exists(conversion_table)) {
    stop(
      "Profile '", profile, "' in ", config_file,
      " points to a missing gene_conversion_table: ", conversion_table,
      call. = FALSE
    )
  }

  cfg
}

load_execution_config <- function(config_file = "config.yml") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required but not available")
  }

  config_file <- resolve_config_file(config_file)
  full_config <- yaml::read_yaml(config_file)
  full_config$execution %||% list()
}

load_profile_config <- function(profile = "default", config_file = "config.yml") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required but not available")
  }

  config_file <- resolve_config_file(config_file)
  config_dir <- dirname(config_file)
  full_config <- yaml::read_yaml(config_file)

  if (!profile %in% names(full_config)) {
    stop("Profile '", profile, "' not found in ", config_file, call. = FALSE)
  }

  cfg <- full_config[[profile]]

  if (!is.null(cfg$paths)) {
    for (nm in names(cfg$paths)) {
      if (!is.null(cfg$paths[[nm]])) {
        cfg$paths[[nm]] <- resolve_path_from_config(cfg$paths[[nm]], config_dir)
      }
    }
  }

  if (!is.null(cfg$params$gene_conversion_table)) {
    cfg$params$gene_conversion_table <- resolve_path_from_config(
      cfg$params$gene_conversion_table,
      config_dir
    )
  }

  validate_profile_config(cfg, profile = profile, config_file = config_file)
}

new_drp_from_config <- function(cfg, out_dir, verbose = TRUE) {
  if (!requireNamespace("CDRPipe", quietly = TRUE)) {
    stop("Package 'CDRPipe' must be installed before running these scripts.", call. = FALSE)
  }

  drp_class <- getExportedValue("CDRPipe", "DRP")

  drp_class$new(
    signatures_rdata = cfg$paths$signatures,
    disease_path = cfg$paths$disease_file %||% cfg$paths$disease_dir,
    disease_pattern = if (is.null(cfg$paths$disease_file)) cfg$paths$disease_pattern else NULL,
    cmap_meta_path = cfg$paths$cmap_meta %||% NULL,
    cmap_valid_path = cfg$paths$cmap_valid %||% NULL,
    drug_meta_path = cfg$paths$drug_meta %||% NULL,
    drug_valid_path = cfg$paths$drug_valid %||% NULL,
    out_dir = out_dir,
    gene_key = cfg$params$gene_key %||% "SYMBOL",
    logfc_cols_pref = cfg$params$logfc_cols_pref %||% "log2FC",
    logfc_cutoff = cfg$params$logfc_cutoff %||% 1,
    pval_key = cfg$params$pval_key %||% NULL,
    pval_cutoff = cfg$params$pval_cutoff %||% 0.05,
    q_thresh = cfg$params$q_thresh %||% 0.05,
    reversal_only = isTRUE(cfg$params$reversal_only %||% TRUE),
    seed = cfg$params$seed %||% 123,
    verbose = verbose,
    analysis_id = cfg$params$analysis_id %||% "cmap",
    mode = cfg$params$mode %||% "single",
    sweep_cutoffs = cfg$params$sweep_cutoffs %||% NULL,
    sweep_auto_grid = isTRUE(cfg$params$sweep_auto_grid %||% TRUE),
    sweep_step = cfg$params$sweep_step %||% 0.1,
    sweep_min_frac = cfg$params$sweep_min_frac %||% 0.20,
    sweep_min_genes = cfg$params$sweep_min_genes %||% 200,
    sweep_stop_on_small = isTRUE(cfg$params$sweep_stop_on_small %||% FALSE),
    combine_log2fc = cfg$params$combine_log2fc %||% "average",
    robust_rule = cfg$params$robust_rule %||% "all",
    robust_k = cfg$params$robust_k %||% NULL,
    aggregate = cfg$params$aggregate %||% "mean",
    weights = cfg$params$weights %||% NULL,
    apply_meta_filters = isTRUE(cfg$params$apply_meta_filters %||% FALSE),
    min_studies = cfg$params$min_studies %||% 2,
    effect_fdr_thresh = cfg$params$effect_fdr_thresh %||% 0.05,
    heterogeneity_thresh = cfg$params$heterogeneity_thresh %||% 0.05,
    gene_conversion_table = cfg$params$gene_conversion_table %||% NULL,
    probe_id_key = cfg$params$probe_id_key %||% NULL,
    probe_id_fallback = if (!is.null(cfg$params$probe_id_fallback)) cfg$params$probe_id_fallback else TRUE,
    percentile_filtering = cfg$params$percentile_filtering %||% NULL,
    save_count_files = isTRUE(cfg$params$save_count_files %||% FALSE),
    n_permutations = cfg$params$n_permutations %||% 100000,
    save_null_scores = isTRUE(cfg$params$save_null_scores %||% FALSE),
    per_threshold_dirs = isTRUE(cfg$params$per_threshold_dirs %||% FALSE),
    blood_label = cfg$params$blood_label %||% "blood",
    ncores = cfg$params$ncores %||% NULL,
    pvalue_method = cfg$params$pvalue_method %||% "continuous",
    phipson_smyth_correction = if (!is.null(cfg$params$phipson_smyth_correction)) cfg$params$phipson_smyth_correction else TRUE
  )
}
