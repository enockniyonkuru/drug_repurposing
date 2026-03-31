# Package Dependencies and Global Variables
#
# Declares global variables used across the CDRPipe package to avoid
# R CMD check warnings in tidy evaluation code paths.

utils::globalVariables(c(
  "name","value","exp_id","subset_comparison_id","q","cmap_score","Cell",
  "dir.out","dir.out.img","cmap_signatures","cmap_experiments_valid",
  "valid","DrugBank.ID"
))
