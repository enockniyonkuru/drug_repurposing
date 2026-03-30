# Package Dependencies and Global Variables
#
# Declares global variables used across the CDRPipe package to avoid
# R CMD check warnings in tidy evaluation code paths.

utils::globalVariables(c(
  "name","value","exp_id","subset_comparison_id","q","cmap_score","Cell",
  "dir.out","dir.out.img","cmap_signatures","cmap_experiments_valid",
  "valid","DrugBank.ID","novelty_flag","your_score","count","chembl_known",
  "approval_status","withdrawn","black_box_warning","chembl_id",
  "drug_normalized","disease_normalized"
))
