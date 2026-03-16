#!/usr/bin/env Rscript
# Test config file loading for ESE profile

library(DRpipe)
source("load_execution_config.R")

cat("============================================\n")
cat("Config File Loading Validation\n")
cat("============================================\n\n")

# Load the ESE profile
profile_name <- "CMAP_Endometriosis_ESE_Strict"
cfg <- load_profile_config(profile = profile_name, config_file = "config.yml")

cat("Profile:", profile_name, "\n\n")
cat("Parameters from config.yml:\n")
cat("--------------------------------------------\n")
cat("seed:", cfg$params$seed, "\n")
cat("n_permutations:", cfg$params$n_permutations, "\n")
cat("pvalue_method:", cfg$params$pvalue_method, "\n")
cat("phipson_smyth_correction:", cfg$params$phipson_smyth_correction, "\n")

cat("\n============================================\n")
cat("VALIDATION\n")
cat("============================================\n")

pass <- cfg$params$seed == 2009 && 
        cfg$params$n_permutations == 1000 && 
        cfg$params$pvalue_method == "discrete" && 
        cfg$params$phipson_smyth_correction == FALSE

if (pass) {
  cat("✅ CONFIG FILE CORRECTLY LOADED!\n")
  cat("   All ESE parameters match expected values.\n")
} else {
  cat("❌ CONFIG LOADING FAILED\n")
  cat("   Expected: seed=2009, n_permutations=1000, pvalue_method=discrete, phipson_smyth_correction=FALSE\n")
}
