#!/usr/bin/env Rscript
#' Load Execution Configuration
#'
#' Helper functions to load and parse execution configuration from YAML files.
#' Provides utilities for loading profile-specific configurations and resolving
#' file paths for pipeline execution.

load_execution_config <- function(config_file = "config.yml") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required but not available")
  }
  
  # Load the full configuration using yaml for raw parsing
  full_config <- yaml::read_yaml(config_file)
  
  # Return the execution section, or empty list if not found
  execution_config <- full_config$execution %||% list()
  
  return(execution_config)
}

# Helper function to load a specific profile configuration
# Uses yaml for raw parsing which is more reliable than config package
load_profile_config <- function(profile = "default", config_file = "config.yml") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required but not available")
  }
  
  # Load raw config
  full_config <- yaml::read_yaml(config_file)
  
  # Get the profile
  if (!profile %in% names(full_config)) {
    stop("Profile '", profile, "' not found in ", config_file)
  }
  
  cfg <- full_config[[profile]]
  
  # Apply path resolution like the original function
  if (!is.null(cfg$paths)) {
    for (nm in names(cfg$paths)) {
      if (!is.null(cfg$paths[[nm]])) {
        # Simple path expansion and normalization
        cfg$paths[[nm]] <- tryCatch({
          path <- path.expand(cfg$paths[[nm]])
          normalizePath(path, winslash = "/", mustWork = FALSE)
        }, error = function(e) cfg$paths[[nm]])
      }
    }
  }
  
  return(cfg)
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x
