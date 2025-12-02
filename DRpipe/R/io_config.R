#' Configuration Loading and Path Resolution
#'
#' Functions for loading YAML configuration files and resolving file paths.
#' Supports multiple resolution strategies including environment variables
#' and package-shipped defaults.
#'
#' @param profile     A config profile (e.g., "default", "production"). If NULL, uses env var DRPIPE_PROFILE or "default".
#' @param config_file Optional path to a YAML config file
#' @return A named list (config sections like $paths, $params)
#' @export
load_dr_config <- function(profile = "default", config_file = NULL) {
  # allow env overrides
  env_cfg     <- Sys.getenv("DRPIPE_CONFIG", unset = NA_character_)
  env_profile <- Sys.getenv("DRPIPE_PROFILE", unset = NA_character_)
  if (isTRUE(nzchar(env_profile))) profile <- env_profile

  # prefer explicit argument; else env var; else packaged; else repo fallback
  candidate <- config_file
  if (is.null(candidate) || !file.exists(candidate)) candidate <- if (isTRUE(nzchar(env_cfg))) env_cfg else NULL
  if (is.null(candidate) || !file.exists(candidate)) {
    pkg_cfg <- system.file("config.yml", package = utils::packageName())
    if (!nzchar(pkg_cfg)) pkg_cfg <- system.file("config.yml", package = "DRpipe")
    if (nzchar(pkg_cfg) && file.exists(pkg_cfg)) candidate <- pkg_cfg
  }
  if (is.null(candidate) || !file.exists(candidate)) {
    repo_cfg <- file.path("scripts", "config.yml")
    if (file.exists(repo_cfg)) candidate <- repo_cfg
  }

  if (is.null(candidate) || !file.exists(candidate)) {
    stop("Could not find a config.yml. Provide `config_file`, set DRPIPE_CONFIG, ",
         "or place one at inst/config.yml or scripts/config.yml.")
  }

  # load via {config}
  cfg <- config::get(config = profile %||% "default", file = candidate)

  # expand ~ and make common path fields absolute if present
  if (!is.null(cfg$paths)) {
    for (nm in names(cfg$paths)) {
      cfg$paths[[nm]] <- io_resolve_path(cfg$paths[[nm]])
    }
  }
  cfg
}

#' Get the `paths` section with optional required-key checks
#' @param cfg config list
#' @param required character vector of keys that must exist
#' @return named list
#' @export
cfg_paths <- function(cfg, required = NULL) {
  paths <- cfg$paths %||% list()
  if (!is.null(required)) io_require_keys(paths, required, section = "paths")
  paths
}

#' Get the `params` section with defaults
#' @param cfg config list
#' @param defaults named list of default values
#' @return named list
#' @export
cfg_params <- function(cfg, defaults = list()) {
  params <- cfg$params %||% list()
  for (nm in names(defaults)) if (is.null(params[[nm]])) params[[nm]] <- defaults[[nm]]
  params
}

#' Validate presence of required keys in a section
#' @keywords internal
#' @export
io_require_keys <- function(section_list, keys, section = "section") {
  missing <- setdiff(keys, names(section_list))
  if (length(missing)) {
    stop("Missing required keys in config.", " Section: ", section,
         ". Missing: ", paste(missing, collapse = ", "))
  }
  invisible(TRUE)
}

#' Normalize/resolve a path (tilde-expand, absolute if possible)
#' @keywords internal
#' @export
io_resolve_path <- function(x) {
  if (is.null(x) || is.na(x)) return(NULL)
  x <- tryCatch(path.expand(x), error = function(e) x)
  tryCatch(normalizePath(x, winslash = "/", mustWork = FALSE), error = function(e) x)
}

#' Ensure a directory exists
#' @keywords internal
#' @export
io_ensure_dir <- function(path) {
  if (is.null(path)) return(invisible(FALSE))
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(TRUE)
}

#' List disease files given a directory + pattern OR a single CSV path
#' @param disease_path A directory or a single CSV path
#' @param disease_pattern Pattern to search when `disease_path` is a directory
#' @keywords internal
#' @export
io_list_disease_files <- function(disease_path, disease_pattern = NULL) {
  stopifnot(!is.null(disease_path))
  disease_path <- io_resolve_path(disease_path)
  if (dir.exists(disease_path)) {
    if (is.null(disease_pattern)) stop("When `disease_path` is a directory, supply `disease_pattern`.")
    list.files(disease_path, pattern = disease_pattern, full.names = TRUE)
  } else {
    if (!file.exists(disease_path)) stop("Disease path not found: ", disease_path)
    disease_path
  }
}

#' List result RData files produced by run_dr()
#' @param results_dir directory to search
#' @param pattern regex to match files (default: *_results.RData)
#' @return character vector of file paths
#' @export
io_list_result_files <- function(results_dir = "scripts/results", pattern = "_results\\.RData$") {
  results_dir <- io_resolve_path(results_dir)
  if (!dir.exists(results_dir)) stop("Results dir not found: ", results_dir)
  list.files(results_dir, pattern = pattern, full.names = TRUE)
}

#' Save a data.frame safely to CSV in an output directory
#' @keywords internal
#' @export
io_save_table <- function(df, out_dir, filename) {
  io_ensure_dir(out_dir)
  fp <- file.path(out_dir, filename)
  utils::write.csv(df, fp, row.names = FALSE)
  invisible(fp)
}

# small infix helper (kept local)
`%||%` <- function(x, y) if (is.null(x)) y else x
