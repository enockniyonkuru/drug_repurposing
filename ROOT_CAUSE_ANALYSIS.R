#!/usr/bin/env Rscript
# Deep Dive Analysis: Why ESE Results Don't Match

cat("\n")
cat("=" %*% 100, "\n")
cat("ROOT CAUSE ANALYSIS: ESE MISMATCH BETWEEN DRPIPE AND TOMIKO\n")
cat("=" %*% 100, "\n\n")

# ============================================================================
# 1. THE FUNDAMENTAL DIFFERENCE
# ============================================================================

cat("1. THE FUNDAMENTAL DIFFERENCE IN P-VALUE CALCULATION\n")
cat("-" %*% 100, "\n\n")

cat("TOMIKO'S CODE (end_to_end_all_5_signatures.R, line 166-168):\n")
cat("───────────────────────────────────────────────────────────\n")
cat("p_values <- sapply(dz_cmap_scores, function(score) {\n")
cat("  length(which(abs(random_scores) >= abs(score))) / length(random_scores)\n")
cat("})\n\n")

cat("DRPIPE'S CODE (processing.R, line 288-300):\n")
cat("───────────────────────────────────────────────────────────\n")
cat("p_values <- sapply(dz_cmap_scores, function(score) {\n")
cat("    count_extreme <- sum(abs(rand_cmap_scores) >= abs(score))\n")
cat("    p_val <- count_extreme / length(rand_cmap_scores)\n")
cat("    \n")
cat("    if (p_val == 0) {  # <-- ALWAYS EXECUTED\n")
cat("        p_val <- 1 / (length(rand_cmap_scores) + 1)\n")
cat("    }\n")
cat("    return(p_val)\n")
cat("})\n\n")

cat("THE CRITICAL DIFFERENCE:\n")
cat("  • Tomiko: When count = 0 → p_value = 0 (exact zero)\n")
cat("  • DRpipe: When count = 0 → p_value = 1/(1000+1) = 0.000999...\n\n")

# ============================================================================
# 2. CONFIG PARAMETER THAT ISN'T WORKING
# ============================================================================

cat("2. THE IGNORED CONFIG PARAMETER\n")
cat("-" %*% 100, "\n\n")

cat("Your config.yml has (ESE profile, line 692):\n")
cat("  phipson_smyth_correction: false\n\n")

cat("BUT: DRpipe's query() function signature (processing.R, line 284) is:\n")
cat("  query <- function(rand_cmap_scores, dz_cmap_scores, subset_comparison_id, analysis_id = \"cmap\")\n\n")

cat("  ⚠️  The phipson_smyth_correction parameter does NOT exist!\n")
cat("  ⚠️  The hardcoded correction (line 294-297) is ALWAYS applied!\n")
cat("  ⚠️  Your config setting is being silently IGNORED!\n\n")

# ============================================================================
# 3. THE IMPACT ON RESULTS
# ============================================================================

cat("3. IMPACT ON RESULTS\n")
cat("-" %*% 100, "\n\n")

cat("When count_extreme = 0 (out of 1000 permutations):\n\n")
cat("Tomiko's method:\n")
cat("  p_value = 0/1000 = 0\n")
cat("  After BH q-value correction: q ≈ 0 (for strong signals)\n")
cat("  Result: PASSES q < 0.0001 threshold ✓\n\n")

cat("DRpipe's method:\n")
cat("  p_value = 1/1001 = 0.000999...\n")
cat("  After BH q-value correction: q ≈ 0.0008-0.001 (depending on FDR)\n")
cat("  Result: DEPENDS on other drugs' p-values (FDR context)\n\n")

cat("For boundary drugs with very weak signals:\n")
cat("Tomiko: Gets p=0, may pass q < 0.0001\n")
cat("DRpipe: Gets p=0.001, more likely to FAIL q < 0.0001\n\n")

# ============================================================================
# 4. WHAT HAPPENED IN YOUR RUN
# ============================================================================

cat("4. WHAT HAPPENED IN YOUR RECENT RUN\n")
cat("-" %*% 100, "\n\n")

cat("Configuration used:\n")
cat("  n_permutations: 1000\n")
cat("  seed: 2009\n")
cat("  phipson_smyth_correction: false (IGNORED - DRpipe applied correction anyway)\n")
cat("  pvalue_method: \"discrete\" (currently not implemented in DRpipe)\n\n")

cat("Results:\n")
cat("  DRpipe: 138 drugs with q < 0.0001\n")
cat("  Tomiko: 236 drugs with q < 0.0001\n")
cat("  Gap: 98 missing drugs\n\n")

cat("These 98 missing drugs are likely boundary cases where:\n")
cat("  • Tomiko gets p=0 from 0 permutations → passes q threshold\n")
cat("  • DRpipe gets p=0.001 from same 0 permutations → fails q threshold\n\n")

# ============================================================================
# 5. THE FIX
# ============================================================================

cat("5. THE FIX REQUIRED\n")
cat("-" %*% 100, "\n\n")

cat("You must modify DRpipe's query() function in processing.R:\n\n")

cat("CURRENT (lines 288-300):\n")
cat("────────────────────────────────────────────────────────\n")
cat("p_values <- sapply(dz_cmap_scores, function(score) {\n")
cat("    count_extreme <- sum(abs(rand_cmap_scores) >= abs(score))\n")
cat("    p_val <- count_extreme / length(rand_cmap_scores)\n")
cat("    if (p_val == 0) {\n")
cat("        p_val <- 1 / (length(rand_cmap_scores) + 1)\n")
cat("    }\n")
cat("    return(p_val)\n")
cat("})\n\n")

cat("WHAT IT SHOULD BE:\n")
cat("────────────────────────────────────────────────────────\n")
cat("query <- function(rand_cmap_scores, dz_cmap_scores, subset_comparison_id,\n")
cat("                  analysis_id = \"cmap\", phipson_smyth_correction = TRUE) {\n")
cat("  p_values <- sapply(dz_cmap_scores, function(score) {\n")
cat("      count_extreme <- sum(abs(rand_cmap_scores) >= abs(score))\n")
cat("      p_val <- count_extreme / length(rand_cmap_scores)\n")
cat("      \n")
cat("      if (phipson_smyth_correction && p_val == 0) {\n")
cat("          p_val <- 1 / (length(rand_cmap_scores) + 1)\n")
cat("      }\n")
cat("      return(p_val)\n")
cat("  })\n")
cat("}\n\n")

cat("Then update pipeline_processing.R to pass the parameter:\n")
cat("  self$drugs <- query(\n")
cat("    self$rand_scores,\n")
cat("    self$obs_scores,\n")
cat("    subset_comparison_id = ...,\n")
cat("    phipson_smyth_correction = self$params$phipson_smyth_correction  # ADD THIS\n")
cat("  )\n\n")

# ============================================================================
# 6. VERIFICATION
# ============================================================================

cat("6. HOW TO VERIFY THE FIX\n")
cat("-" %*% 100, "\n\n")

cat("After implementing the fix:\n")
cat("1. Set phipson_smyth_correction: false for ESE profile\n")
cat("2. Re-run ESE with n_permutations: 1000\n")
cat("3. Should get ~236 drugs (matching Tomiko)\n\n")

cat("Or test with higher permutations to match DRpipe default:\n")
cat("1. Keep phipson_smyth_correction: true (or remove, uses default)\n")
cat("2. Set n_permutations: 100000 (DRpipe standard)\n")
cat("3. Should get similar hit count but better p-value resolution\n\n")

cat("=" %*% 100, "\n\n")
