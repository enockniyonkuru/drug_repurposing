#!/usr/bin/env Rscript
#' Launch Drug Repurposing Shiny App
#'
#' Dependency checker and launcher for the interactive drug repurposing interface.
#' Verifies all required packages are installed and starts the Shiny application
#' for user-friendly pipeline access.

cat("=================================================\n")
cat("Drug Repurposing Pipeline - Shiny App Launcher\n")
cat("=================================================\n\n")

# Define required packages
required_packages <- c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "tidyverse",
  "yaml",
  "DRpipe"
)

# Function to check and install packages
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (pkg == "DRpipe") {
      # Check if DRpipe is installed
      if (!requireNamespace("DRpipe", quietly = TRUE)) {
        cat("ERROR: DRpipe package not found!\n")
        cat("Please install DRpipe first:\n")
        cat("  devtools::install('../DRpipe')\n\n")
        stop("DRpipe package is required but not installed.")
      }
    } else {
      # Check CRAN packages
      if (!requireNamespace(pkg, quietly = TRUE)) {
        cat(sprintf("Installing missing package: %s\n", pkg))
        install.packages(pkg, repos = "https://cloud.r-project.org")
      }
    }
  }
}

# Check and install missing packages
cat("Checking required packages...\n")
tryCatch({
  install_if_missing(required_packages)
  cat("All required packages are installed.\n\n")
}, error = function(e) {
  cat("Error installing packages:\n")
  cat(e$message, "\n")
  stop("Failed to install required packages.")
})

# Load required libraries
cat("Loading libraries...\n")
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(DT)
  library(plotly)
  library(tidyverse)
  library(yaml)
  library(DRpipe)
})
cat("Libraries loaded successfully.\n\n")

# Check for required data files
cat("Checking for required data files...\n")
data_dir <- "../scripts/data/drug_signatures"

# CMAP files
cat("\n  CMAP Database:\n")
cmap_files <- c(
  "cmap_signatures.RData",
  "cmap_drug_experiments_new.csv",
  "cmap_valid_instances.csv"
)

cmap_missing <- c()
for (file in cmap_files) {
  file_path <- file.path(data_dir, file)
  if (!file.exists(file_path)) {
    cmap_missing <- c(cmap_missing, file)
    cat(sprintf("    [MISSING] %s\n", file))
  } else {
    cat(sprintf("    [OK] %s\n", file))
  }
}

# TAHOE files
cat("\n  TAHOE Database:\n")
tahoe_files <- c(
  "tahoe_signatures.RData",
  "tahoe_drug_experiments_new.csv"
)

tahoe_missing <- c()
for (file in tahoe_files) {
  file_path <- file.path(data_dir, file)
  if (!file.exists(file_path)) {
    tahoe_missing <- c(tahoe_missing, file)
    cat(sprintf("    [MISSING] %s\n", file))
  } else {
    cat(sprintf("    [OK] %s\n", file))
  }
}

if (length(cmap_missing) > 0 || length(tahoe_missing) > 0) {
  cat("\nWARNING: Some data files are missing!\n")
  if ("cmap_signatures.RData" %in% cmap_missing || "tahoe_signatures.RData" %in% tahoe_missing) {
    cat("\nIMPORTANT: At least one signatures file is required for the app to function.\n")
    cat("Download from: https://drive.google.com/drive/folders/1LvKiT0u3DGf5sW5bYVJk7scbM5rLmBx-?usp=sharing\n")
    cat("Place files in: scripts/data/drug_signatures/\n\n")
  }
} else {
  cat("\nAll required data files found.\n\n")
}

# Check for example disease signature files
cat("Checking for example disease signature files...\n")
disease_dir <- "../scripts/data/disease_signatures"
example_files <- c(
  "acne_signature.csv",
  "arthritis_signature.csv",
  "glaucoma_signature.csv"
)

for (file in example_files) {
  file_path <- file.path(disease_dir, file)
  if (file.exists(file_path)) {
    cat(sprintf("  [OK] %s\n", file))
  } else {
    cat(sprintf("  [OPTIONAL] %s not found\n", file))
  }
}

cat("\n=================================================\n")
cat("Launching Shiny App...\n")
cat("=================================================\n\n")

# Get the directory where this script is located
# Works with both source() and Rscript
get_script_dir <- function() {
  # Try different methods to get script directory
  if (exists("ofile") && !is.null(ofile <- sys.frame(1)$ofile)) {
    return(dirname(ofile))
  }
  
  # For Rscript
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(sub("^--file=", "", file_arg)))
  }
  
  # Fallback to current directory
  return(getwd())
}

app_dir <- get_script_dir()
cat(sprintf("App directory: %s\n", app_dir))

# Check if app.R exists
app_file <- file.path(app_dir, "app.R")
if (!file.exists(app_file)) {
  cat(sprintf("ERROR: app.R not found at: %s\n", app_file))
  cat("Please ensure you're running this script from the shiny_app directory.\n")
  stop("app.R not found")
}

# Launch the Shiny app
tryCatch({
  shiny::runApp(
    appDir = app_file,
    launch.browser = TRUE,
    host = "127.0.0.1",
    port = NULL  # Let Shiny choose an available port
  )
}, error = function(e) {
  cat("\nError launching app:\n")
  cat(e$message, "\n")
  cat("\nTroubleshooting:\n")
  cat("1. Ensure you're in the correct directory\n")
  cat("2. Check that app.R exists in the current directory\n")
  cat("3. Verify all required packages are installed\n")
  cat("4. Check that required data files are present\n")
})
