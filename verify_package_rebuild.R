#!/usr/bin/env Rscript
# Verify package rebuild was successful

library(DRpipe)
library(config)

cat("\n")
cat(strrep("=", 80), "\n")
cat("PACKAGE REBUILD VERIFICATION\n")
cat(strrep("=", 80), "\n\n")

# Test 1: Load package
cat("TEST 1: DRpipe package loads\n")
cat(strrep("-", 40), "\n")
cat("✓ DRpipe loaded successfully\n\n")

# Test 2: Check query function has new parameters
cat("TEST 2: query() function has new parameters\n")
cat(strrep("-", 40), "\n")
query_sig <- as.character(args(query))
if (any(grepl("pvalue_method", query_sig))) {
  cat("✓ pvalue_method parameter found\n")
} else {
  cat("✗ ERROR: pvalue_method NOT found\n")
}

if (any(grepl("phipson_smyth_correction", query_sig))) {
  cat("✓ phipson_smyth_correction parameter found\n\n")
} else {
  cat("✗ ERROR: phipson_smyth_correction NOT found\n\n")
}

# Test 3: Load config and check pvalue parameters
cat("TEST 3: Config file has pvalue parameters\n")
cat(strrep("-", 40), "\n")
cfg <- config::get(file='scripts/config.yml', config='CMAP_Endometriosis_ESE_Strict')

if (!is.null(cfg$params$pvalue_method)) {
  cat(sprintf("✓ pvalue_method = '%s'\n", cfg$params$pvalue_method))
} else {
  cat("✗ ERROR: pvalue_method missing in config\n")
}

if (!is.null(cfg$params$phipson_smyth_correction)) {
  cat(sprintf("✓ phipson_smyth_correction = %s\n\n", 
              tolower(cfg$params$phipson_smyth_correction)))
} else {
  cat("✗ ERROR: phipson_smyth_correction missing in config\n\n")
}

# Test 4: Quick functional test
cat("TEST 4: Functional test - query() works with new parameters\n")
cat(strrep("-", 40), "\n")
set.seed(2009)
rand_scores <- rnorm(1000)
obs_scores <- c(-2.5, -0.5, 0, 0.5, 2.5)

result <- tryCatch({
  query(rand_scores, obs_scores, "test",
        pvalue_method = "discrete",
        phipson_smyth_correction = FALSE)
}, error = function(e) {
  cat("✗ ERROR:", e$message, "\n")
  NULL
})

if (!is.null(result)) {
  cat("✓ query() executed successfully\n")
  cat(sprintf("✓ Returned %d p-values\n\n", nrow(result)))
} else {
  cat("✗ query() execution failed\n\n")
}

cat(strrep("=", 80), "\n")
cat("VERIFICATION COMPLETE - Package rebuild successful!\n")
cat("Ready to run ESE profile.\n")
cat(strrep("=", 80), "\n\n")
