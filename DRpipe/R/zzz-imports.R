#' Package Dependencies and Global Variables
#'
#' Declares package dependencies via roxygen imports. The 'zzz-' naming prefix
#' ensures this file is processed last. Defines global variables used across
#' the DRpipe package to avoid R CMD check warnings.

utils::globalVariables(c(
  "name","value","exp_id","subset_comparison_id","q","cmap_score","Cell",
  "dir.out","dir.out.img","cmap_signatures","cmap_experiments_valid"
))
