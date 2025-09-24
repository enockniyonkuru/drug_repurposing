# Helper function to load execution configuration from YAML
load_execution_config <- function(config_file = "config.yml") {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required but not available")
  }
  
  # Read the entire YAML file
  full_config <- yaml::read_yaml(config_file)
  
  # Return the execution section, or empty list if not found
  execution_config <- full_config$execution %||% list()
  
  return(execution_config)
}

# Helper function to load a specific profile configuration
# This bypasses the buggy load_dr_config function and uses config::get directly
load_profile_config <- function(profile = "default", config_file = "config.yml") {
  if (!requireNamespace("config", quietly = TRUE)) {
    stop("Package 'config' is required but not available")
  }
  
  # Use config::get directly which works correctly
  cfg <- config::get(config = profile, file = config_file)
  
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
