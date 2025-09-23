# Test core functions of DRpipe package
cat("Testing DRpipe core functions...\n")

library(DRpipe)

# Test 1: Check function documentation
cat("\n=== Testing Function Documentation ===\n")
tryCatch({
  # Test if help is available for key functions
  cat("Checking help for clean_table...\n")
  help_content <- capture.output(help(clean_table))
  if (length(help_content) > 0) {
    cat("✓ clean_table documentation available\n")
  } else {
    cat("✗ clean_table documentation not found\n")
  }
}, error = function(e) {
  cat("Error checking documentation:", e$message, "\n")
})

# Test 2: Test clean_table function with sample data
cat("\n=== Testing clean_table Function ===\n")
tryCatch({
  # Create sample disease signature data
  sample_data <- data.frame(
    SYMBOL = c("TP53", "BRCA1", "MYC", "EGFR", "KRAS"),
    log2FC = c(2.5, -1.8, 3.2, -2.1, 1.5),
    p_val_adj = c(0.001, 0.01, 0.0001, 0.005, 0.02)
  )
  
  # Create sample gene universe (simulating CMap genes)
  sample_gene_universe <- c("7157", "672", "4609", "1956", "3845")  # Entrez IDs
  
  cat("Sample data created:\n")
  print(sample_data)
  
  # Test clean_table function
  cat("\nTesting clean_table function...\n")
  cleaned_data <- clean_table(
    sample_data,
    gene_key = "SYMBOL",
    logFC_key = "log2FC",
    logFC_cutoff = 1,
    pval_key = "p_val_adj",
    pval_cutoff = 0.05,
    db_gene_list = sample_gene_universe
  )
  
  cat("✓ clean_table function executed successfully\n")
  cat("Cleaned data structure:\n")
  print(str(cleaned_data))
  
}, error = function(e) {
  cat("✗ Error testing clean_table:", e$message, "\n")
})

# Test 3: Test cmap_score function
cat("\n=== Testing cmap_score Function ===\n")
tryCatch({
  # Create sample data for cmap_score
  sig_up <- data.frame(GeneID = c("7157", "4609"))  # TP53, MYC
  sig_down <- data.frame(GeneID = c("672", "1956"))  # BRCA1, EGFR
  
  # Create sample drug signature
  drug_signature <- data.frame(
    ids = c("7157", "672", "4609", "1956", "3845"),
    rank = c(1, 2, 3, 4, 5)
  )
  
  cat("Testing cmap_score function...\n")
  score <- cmap_score(sig_up, sig_down, drug_signature)
  
  cat("✓ cmap_score function executed successfully\n")
  cat("Connectivity score:", score, "\n")
  
}, error = function(e) {
  cat("✗ Error testing cmap_score:", e$message, "\n")
})

# Test 4: Test random_score function (with small parameters)
cat("\n=== Testing random_score Function ===\n")
tryCatch({
  # Create minimal CMap signatures for testing
  test_signatures <- data.frame(
    V1 = c("7157", "672", "4609", "1956", "3845"),
    exp1 = c(1, 2, 3, 4, 5),
    exp2 = c(5, 4, 3, 2, 1)
  )
  
  cat("Testing random_score function with small parameters...\n")
  rand_scores <- random_score(
    test_signatures, 
    n_up = 2, 
    n_down = 2,
    N_PERMUTATIONS = 10,  # Small number for testing
    seed = 123
  )
  
  cat("✓ random_score function executed successfully\n")
  cat("Number of random scores generated:", length(rand_scores), "\n")
  cat("Sample random scores:", head(rand_scores, 3), "\n")
  
}, error = function(e) {
  cat("✗ Error testing random_score:", e$message, "\n")
})

# Test 5: Check package structure and exports
cat("\n=== Testing Package Structure ===\n")
tryCatch({
  # List all exported functions
  exported_funcs <- ls("package:DRpipe")
  cat("Number of exported functions:", length(exported_funcs), "\n")
  
  # Check for key functions
  key_functions <- c("clean_table", "cmap_score", "random_score", "query_score", "query")
  missing_funcs <- key_functions[!key_functions %in% exported_funcs]
  
  if (length(missing_funcs) == 0) {
    cat("✓ All key functions are exported\n")
  } else {
    cat("✗ Missing key functions:", paste(missing_funcs, collapse = ", "), "\n")
  }
  
}, error = function(e) {
  cat("Error checking package structure:", e$message, "\n")
})

# Test 6: Check dependencies
cat("\n=== Testing Dependencies ===\n")
required_packages <- c("dplyr", "tidyr", "tibble", "gprofiler2", "pbapply", "pheatmap", "UpSetR", "grid", "gplots", "reshape2")

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✓", pkg, "is available\n")
  } else {
    cat("✗", pkg, "is NOT available\n")
  }
}

cat("\n=== Function Testing Completed ===\n")
