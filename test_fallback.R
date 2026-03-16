#!/usr/bin/env Rscript
# Test script to verify probe_id_fallback works correctly

library(DRpipe)

cat("\n════════════════════════════════════════════════════════════════\n")
cat("Testing DRpipe probe_id_fallback for ESE signature\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Load CMap gene list
load("scripts/data/drug_signatures/cmap_signatures.RData")
if ("V1" %in% names(cmap_signatures)) {
  db_genes <- as.character(cmap_signatures$V1)
} else {
  db_genes <- as.character(cmap_signatures[[1]])
}
cat("CMap gene universe:", length(db_genes), "genes\n\n")

# Load ESE signature
ese <- read.csv("scripts/data/disease_signatures/endo_disease_signatures/endomentriosis_ese_disease_signature.csv")
cat("ESE signature loaded:", nrow(ese), "genes\n")
cat("Columns:", paste(names(ese), collapse=", "), "\n\n")

# Test clean_table with probe_id_fallback
cat("Testing clean_table:\n")
cat("  1. First tries g:Profiler to convert symbols -> Entrez\n")
cat("  2. For failed conversions, falls back to probe IDs (X column)\n\n")

cleaned <- clean_table(
  ese,
  gene_key = "symbols",
  logFC_key = "logFC",
  logFC_cutoff = 1.1,
  pval_key = "adj.P.Val",
  pval_cutoff = 0.05,
  db_gene_list = db_genes,
  probe_id_key = "X",
  probe_id_fallback = TRUE
)

cat("\n\nFinal cleaned signature:", nrow(cleaned), "genes\n")
cat("  Up-regulated:", sum(cleaned$logFC > 0), "\n")
cat("  Down-regulated:", sum(cleaned$logFC < 0), "\n")

# Check if the 3 previously missing genes are now included
missing_ids <- c("91353", "28815", "5369")
found_in_cleaned <- missing_ids %in% cleaned$GeneID
cat("\nPreviously missing genes (failed g:Profiler, recovered via probe ID):\n")
for (i in 1:3) {
  status <- if(found_in_cleaned[i]) "✓ RECOVERED" else "✗ not found"
  cat(sprintf("  %s: %s\n", missing_ids[i], status))
}

# Compare with Tomiko's expected count
cat("\n\nExpected (Tomiko): 197 genes\n")
cat("Got (DRpipe):     ", nrow(cleaned), "genes\n")
if (nrow(cleaned) == 197) {
  cat("\n✓ SUCCESS: Gene counts match!\n")
} else {
  cat("\n✗ MISMATCH: Gene counts differ\n")
}
