# Simple test of DRpipe package core functions
cat("=== Simple DRpipe Function Test ===\n")

library(DRpipe)

# Test 1: Test clean_table function with sample data
cat("\n1. Testing clean_table function...\n")
tryCatch({
  # Create sample disease signature data
  sample_data <- data.frame(
    SYMBOL = c("TP53", "BRCA1", "MYC", "EGFR", "KRAS"),
    log2FC = c(2.5, -1.8, 3.2, -2.1, 1.5),
    p_val_adj = c(0.001, 0.01, 0.0001, 0.005, 0.02)
  )
  
  # Create sample gene universe (simulating CMap genes)
  sample_gene_universe <- c("7157", "672", "4609", "1956", "3845")  # Entrez IDs
  
  cat("Sample data:\n")
  print(sample_data)
  
  # Test clean_table function
  cleaned_data <- clean_table(
    sample_data,
    gene_key = "SYMBOL",
    logFC_key = "log2FC",
    logFC_cutoff = 1,
    pval_key = "p_val_adj",
    pval_cutoff = 0.05,
    db_gene_list = sample_gene_universe
  )
  
  cat("✓ clean_table executed successfully\n")
  cat("Result:\n")
  print(cleaned_data)
  
}, error = function(e) {
  cat("✗ Error in clean_table:", e$message, "\n")
})

# Test 2: Test cmap_score function
cat("\n2. Testing cmap_score function...\n")
tryCatch({
  # Create sample data for cmap_score
  sig_up <- data.frame(GeneID = c("7157", "4609"))  # TP53, MYC
  sig_down <- data.frame(GeneID = c("672", "1956"))  # BRCA1, EGFR
  
  # Create sample drug signature
  drug_signature <- data.frame(
    ids = c("7157", "672", "4609", "1956", "3845"),
    rank = c(1, 2, 3, 4, 5)
  )
  
  score <- cmap_score(sig_up, sig_down, drug_signature)
  
  cat("✓ cmap_score executed successfully\n")
  cat("Connectivity score:", score, "\n")
  
}, error = function(e) {
  cat("✗ Error in cmap_score:", e$message, "\n")
})

# Test 3: Test query_score function
cat("\n3. Testing query_score function...\n")
tryCatch({
  # Create minimal CMap signatures for testing
  test_signatures <- data.frame(
    V1 = c("7157", "672", "4609", "1956", "3845"),
    exp1 = c(1, 2, 3, 4, 5),
    exp2 = c(5, 4, 3, 2, 1)
  )
  
  genes_up <- c("7157", "4609")
  genes_down <- c("672", "1956")
  
  scores <- query_score(test_signatures, genes_up, genes_down)
  
  cat("✓ query_score executed successfully\n")
  cat("Scores:", scores, "\n")
  
}, error = function(e) {
  cat("✗ Error in query_score:", e$message, "\n")
})

# Test 4: Check available functions
cat("\n4. Checking exported functions...\n")
exported_funcs <- ls("package:DRpipe")
cat("Total exported functions:", length(exported_funcs), "\n")
cat("Functions:", paste(exported_funcs, collapse = ", "), "\n")

# Test 5: Check key dependencies
cat("\n5. Checking dependencies...\n")
key_deps <- c("dplyr", "gprofiler2", "pbapply")
for (pkg in key_deps) {
  available <- requireNamespace(pkg, quietly = TRUE)
  cat(ifelse(available, "✓", "✗"), pkg, "\n")
}

cat("\n=== Test Complete ===\n")
