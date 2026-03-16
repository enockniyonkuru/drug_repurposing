#!/usr/bin/env Rscript
# Compare overlaps for stages

orig_IIInIV <- read.csv("code/by stage/IIInIV/drug_instances_IIInIV.csv", row.names=1)
e2e_IIInIV <- read.csv("replication/end_to_end_IIInIV_v2/drug_instances_IIInIV_from_raw.csv", row.names=1)

orig_InII <- read.csv("code/by stage/InII/drug_instances_InII.csv", row.names=1)
e2e_InII <- read.csv("replication/end_to_end_InII_v2/drug_instances_InII_from_raw.csv", row.names=1)

cat("\n")
cat("DRUG OVERLAP ANALYSIS (STAGES)\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# IIInIV
orig_drugs_IIInIV <- orig_IIInIV$name
e2e_drugs_IIInIV <- e2e_IIInIV$name

common_IIInIV <- intersect(orig_drugs_IIInIV, e2e_drugs_IIInIV)
only_orig_IIInIV <- setdiff(orig_drugs_IIInIV, e2e_drugs_IIInIV)
only_e2e_IIInIV <- setdiff(e2e_drugs_IIInIV, orig_drugs_IIInIV)

cat("IIInIV (Stage III-IV):\n")
cat("  Original drugs:", length(orig_drugs_IIInIV), "\n")
cat("  E2E drugs:", length(e2e_drugs_IIInIV), "\n")
cat("  Common overlap:", length(common_IIInIV), "\n")
cat("  Overlap %:", sprintf("%.1f%%", 100 * length(common_IIInIV) / length(orig_drugs_IIInIV)), "\n")
cat("  Only in original:", length(only_orig_IIInIV), "\n")
cat("  Only in E2E:", length(only_e2e_IIInIV), "\n\n")

# InII
orig_drugs_InII <- orig_InII$name
e2e_drugs_InII <- e2e_InII$name

common_InII <- intersect(orig_drugs_InII, e2e_drugs_InII)
only_orig_InII <- setdiff(orig_drugs_InII, e2e_drugs_InII)
only_e2e_InII <- setdiff(e2e_drugs_InII, orig_drugs_InII)

cat("InII (Stage I-II):\n")
cat("  Original drugs:", length(orig_drugs_InII), "\n")
cat("  E2E drugs:", length(e2e_drugs_InII), "\n")
cat("  Common overlap:", length(common_InII), "\n")
cat("  Overlap %:", sprintf("%.1f%%", 100 * length(common_InII) / length(orig_drugs_InII)), "\n")
cat("  Only in original:", length(only_orig_InII), "\n")
cat("  Only in E2E:", length(only_e2e_InII), "\n\n")

cat("════════════════════════════════════════════════════════════════\n")
