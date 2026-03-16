#!/usr/bin/env Rscript
# Compare end-to-end generated with original

orig <- read.csv("code/unstratified/drug_instances_unstratified.csv", row.names=1)
e2e <- read.csv("replication/end_to_end_unstratified/drug_instances_from_raw_data.csv", row.names=1)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║     COMPARISON: ORIGINAL vs END-TO-END FROM RAW DATA           ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Original rows:", nrow(orig), "\n")
cat("End-to-end rows:", nrow(e2e), "\n\n")

cat("Top 5 drugs (Original):\n")
print(head(orig[, c("name", "cmap_score", "DrugBank.ID")], 5))

cat("\n\nTop 5 drugs (End-to-end):\n")
print(head(e2e[, c("name", "cmap_score", "DrugBank.ID")], 5))

cat("\n\nComparison:\n")
cat("  Drug names match:", identical(orig$name, e2e$name), "\n")
cat("  Scores match:", all(abs(orig$cmap_score - e2e$cmap_score) < 1e-10), "\n")
cat("  Exp IDs match:", identical(orig$exp_id, e2e$exp_id), "\n")

# Count overlaps
common_drugs <- length(intersect(orig$name, e2e$name))
cat("  Common drugs:", common_drugs, "out of", nrow(orig), "(original) and", nrow(e2e), "(e2e)\n\n")

cat("════════════════════════════════════════════════════════════════\n")
