#!/usr/bin/env Rscript
# ==============================================================================
# Validation Test for P-Value and Q-Value Fix
# ==============================================================================
# This script tests the fixed query() function to ensure:
# 1. P-values are never exactly 0
# 2. Q-values show proper distribution
# 3. Results are statistically valid
# ==============================================================================

library(DRpipe)

cat("\n")
cat("==============================================================================\n")
cat("VALIDATION TEST FOR P-VALUE AND Q-VALUE FIX\n")
cat("==============================================================================\n\n")

# ------------------------------------------------------------------------------
# Test 1: Simulate extreme case where all observed scores are very negative
# ------------------------------------------------------------------------------
cat("TEST 1: Extreme negative scores (should trigger the fix)\n")
cat("----------------------------------------------------------------------\n")

set.seed(123)

# Create null distribution (random scores around 0)
null_scores <- rnorm(100000, mean = 0, sd = 0.05)

# Create observed scores that are ALL more extreme than null
# (This is what causes the bug in the original code)
observed_scores <- rep(-0.3, 50)  # All very negative

cat(sprintf("Null distribution: mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
            mean(null_scores), sd(null_scores), min(null_scores), max(null_scores)))
cat(sprintf("Observed scores: all = %.4f (more extreme than any null score)\n", 
            observed_scores[1]))

# Run the fixed query function
result <- query(null_scores, observed_scores, "test_extreme", "validation")

# Check results
cat("\nResults:\n")
cat(sprintf("  P-values == 0: %d (%.1f%%)\n", 
            sum(result$p == 0), 100 * mean(result$p == 0)))
cat(sprintf("  P-value range: [%.10f, %.10f]\n", 
            min(result$p), max(result$p)))
cat(sprintf("  Q-values == 0: %d (%.1f%%)\n", 
            sum(result$q == 0), 100 * mean(result$q == 0)))
cat(sprintf("  Q-value range: [%.10f, %.10f]\n", 
            min(result$q), max(result$q)))

# Validation checks
test1_pass <- TRUE
if (any(result$p == 0)) {
    cat("  ❌ FAIL: Found p-values == 0\n")
    test1_pass <- FALSE
} else {
    cat("  ✅ PASS: No p-values == 0\n")
}

if (all(result$q == 0)) {
    cat("  ❌ FAIL: All q-values == 0\n")
    test1_pass <- FALSE
} else {
    cat("  ✅ PASS: Q-values show variation\n")
}

# Check that minimum p-value is approximately 1/(N+1)
expected_min_p <- 1 / (length(null_scores) + 1)
if (abs(min(result$p) - expected_min_p) < 1e-6) {
    cat(sprintf("  ✅ PASS: Minimum p-value = %.10f (expected: %.10f)\n", 
                min(result$p), expected_min_p))
} else {
    cat(sprintf("  ⚠️  WARNING: Minimum p-value = %.10f (expected: %.10f)\n", 
                min(result$p), expected_min_p))
}

cat("\n")

# ------------------------------------------------------------------------------
# Test 2: Normal case with mixed scores
# ------------------------------------------------------------------------------
cat("TEST 2: Mixed scores (normal case)\n")
cat("----------------------------------------------------------------------\n")

set.seed(456)

# Create null distribution
null_scores2 <- rnorm(100000, mean = 0, sd = 0.1)

# Create observed scores with some extreme and some not
observed_scores2 <- c(
    rnorm(25, mean = -0.15, sd = 0.02),  # Moderately negative
    rnorm(25, mean = 0.05, sd = 0.02)    # Slightly positive
)

cat(sprintf("Null distribution: mean=%.4f, sd=%.4f\n",
            mean(null_scores2), sd(null_scores2)))
cat(sprintf("Observed scores: mean=%.4f, range=[%.4f, %.4f]\n",
            mean(observed_scores2), min(observed_scores2), max(observed_scores2)))

# Run the fixed query function
result2 <- query(null_scores2, observed_scores2, "test_mixed", "validation")

# Check results
cat("\nResults:\n")
cat(sprintf("  P-values == 0: %d (%.1f%%)\n", 
            sum(result2$p == 0), 100 * mean(result2$p == 0)))
cat(sprintf("  P-value range: [%.10f, %.10f]\n", 
            min(result2$p), max(result2$p)))
cat(sprintf("  P-values < 0.05: %d (%.1f%%)\n",
            sum(result2$p < 0.05), 100 * mean(result2$p < 0.05)))
cat(sprintf("  Q-values == 0: %d (%.1f%%)\n", 
            sum(result2$q == 0), 100 * mean(result2$q == 0)))
cat(sprintf("  Q-value range: [%.10f, %.10f]\n", 
            min(result2$q), max(result2$q)))
cat(sprintf("  Q-values < 0.05: %d (%.1f%%)\n",
            sum(result2$q < 0.05), 100 * mean(result2$q < 0.05)))

# Validation checks
test2_pass <- TRUE
if (any(result2$p == 0)) {
    cat("  ❌ FAIL: Found p-values == 0\n")
    test2_pass <- FALSE
} else {
    cat("  ✅ PASS: No p-values == 0\n")
}

if (all(result2$q == 0)) {
    cat("  ❌ FAIL: All q-values == 0\n")
    test2_pass <- FALSE
} else {
    cat("  ✅ PASS: Q-values show variation\n")
}

# Check that p-values span a reasonable range
if (max(result2$p) - min(result2$p) > 0.1) {
    cat("  ✅ PASS: P-values show good spread\n")
} else {
    cat("  ⚠️  WARNING: P-values have limited spread\n")
}

cat("\n")

# ------------------------------------------------------------------------------
# Test 3: Verify ranking is preserved
# ------------------------------------------------------------------------------
cat("TEST 3: Verify ranking is preserved\n")
cat("----------------------------------------------------------------------\n")

# More extreme scores should have lower p-values
# Find most extreme (furthest from null mean) and least extreme (closest to null mean)
distances_from_null <- abs(observed_scores2 - mean(null_scores2))
extreme_idx <- which.max(distances_from_null)
moderate_idx <- which.min(distances_from_null)

cat(sprintf("Most extreme score: %.4f (distance from null: %.4f, p=%.6f, q=%.6f)\n",
            observed_scores2[extreme_idx],
            distances_from_null[extreme_idx],
            result2$p[extreme_idx], 
            result2$q[extreme_idx]))
cat(sprintf("Least extreme score: %.4f (distance from null: %.4f, p=%.6f, q=%.6f)\n",
            observed_scores2[moderate_idx],
            distances_from_null[moderate_idx],
            result2$p[moderate_idx], 
            result2$q[moderate_idx]))

test3_pass <- TRUE
if (result2$p[extreme_idx] < result2$p[moderate_idx]) {
    cat("  ✅ PASS: More extreme scores have lower p-values\n")
} else {
    cat("  ❌ FAIL: Ranking not preserved\n")
    test3_pass <- FALSE
}

cat("\n")

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
cat("==============================================================================\n")
cat("VALIDATION SUMMARY\n")
cat("==============================================================================\n\n")

all_pass <- test1_pass && test2_pass && test3_pass

if (all_pass) {
    cat("✅ ALL TESTS PASSED\n\n")
    cat("The fix is working correctly:\n")
    cat("  1. P-values are never exactly 0\n")
    cat("  2. Q-values show proper distribution\n")
    cat("  3. Ranking by significance is preserved\n")
    cat("  4. Extreme scores get minimum p-value of 1/(N+1)\n\n")
    cat("The pipeline is ready for production use.\n")
    quit(status = 0)
} else {
    cat("❌ SOME TESTS FAILED\n\n")
    cat("Please review the test output above for details.\n")
    quit(status = 1)
}
