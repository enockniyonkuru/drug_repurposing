# Check DRpipe package structure and dependencies
cat("=== DRpipe Package Structure Check ===\n")

library(DRpipe)

# Check package description
cat("\n1. Package Information:\n")
desc <- packageDescription('DRpipe')
cat("Package:", desc$Package, "\n")
cat("Version:", desc$Version, "\n")
cat("Title:", desc$Title, "\n")

# Check dependencies from DESCRIPTION file
cat("\n2. Dependency Check:\n")
required_packages <- c("dplyr", "tidyr", "tibble", "gprofiler2", "pbapply", 
                      "pheatmap", "UpSetR", "grid", "gplots", "reshape2")

for (pkg in required_packages) {
  available <- requireNamespace(pkg, quietly = TRUE)
  status <- ifelse(available, "✓", "✗")
  cat(status, pkg, "\n")
}

# Check for qvalue package (was skipped during installation)
cat("\n3. Optional Dependencies:\n")
qvalue_available <- requireNamespace("qvalue", quietly = TRUE)
cat(ifelse(qvalue_available, "✓", "✗"), "qvalue", "\n")

if (!qvalue_available) {
  cat("Note: qvalue package is not available. This may affect statistical analysis.\n")
}

# Test package functions are accessible
cat("\n4. Function Accessibility:\n")
key_functions <- c("clean_table", "cmap_score", "random_score", "query_score", "query")
for (func in key_functions) {
  exists_func <- exists(func, mode = "function")
  cat(ifelse(exists_func, "✓", "✗"), func, "\n")
}

# Check visualization functions
cat("\n5. Visualization Functions:\n")
viz_functions <- c("pl_hist_revsc", "pl_heatmap", "pl_overlap", "pl_upset")
for (func in viz_functions) {
  exists_func <- exists(func, mode = "function")
  cat(ifelse(exists_func, "✓", "✗"), func, "\n")
}

# Test sample workflow components
cat("\n6. Testing Sample Workflow Components:\n")
tryCatch({
  # Create minimal test data
  test_data <- data.frame(
    SYMBOL = c("TP53", "BRCA1"),
    log2FC = c(2.0, -1.5),
    p_val_adj = c(0.01, 0.02)
  )
  
  gene_universe <- c("7157", "672")
  
  # Test clean_table
  cleaned <- clean_table(test_data, gene_key = "SYMBOL", logFC_key = "log2FC", 
                        logFC_cutoff = 1, pval_key = "p_val_adj", 
                        db_gene_list = gene_universe)
  cat("✓ clean_table workflow test passed\n")
  
  # Test scoring functions
  sig_up <- data.frame(GeneID = "7157")
  sig_down <- data.frame(GeneID = "672")
  drug_sig <- data.frame(ids = c("7157", "672"), rank = c(1, 2))
  
  score <- cmap_score(sig_up, sig_down, drug_sig)
  cat("✓ cmap_score workflow test passed\n")
  
}, error = function(e) {
  cat("✗ Workflow test failed:", e$message, "\n")
})

cat("\n=== Package Check Complete ===\n")
