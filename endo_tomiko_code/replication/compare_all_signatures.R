#!/usr/bin/env Rscript
# Compare replicated files with originals for all signatures

library(dplyr)

signatures <- list(
  list(name = "ESE", orig_path = "code/by phase/ESE/drug_instances_ESE.csv"),
  list(name = "MSE", orig_path = "code/by phase/MSE/drug_instances_MSE.csv"),
  list(name = "PE", orig_path = "code/by phase/PE/drug_instances_PE.csv"),
  list(name = "IIInIV", orig_path = "code/by stage/IIInIV/drug_instances_IIInIV.csv"),
  list(name = "InII", orig_path = "code/by stage/InII/drug_instances_InII.csv")
)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║          DRUG INSTANCES REPLICATION VERIFICATION              ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

comparison_results <- data.frame()

for (sig in signatures) {
  orig_file <- file.path("~/Desktop/endo_tomiko_code", sig$orig_path)
  rep_file <- file.path("~/Desktop/endo_tomiko_code/replication", 
                        paste0("drug_instances_", sig$name, "_replicated.csv"))
  
  # Load both files
  orig <- read.csv(orig_file, row.names = 1)
  rep <- read.csv(rep_file, row.names = 1)
  
  # Compare dimensions
  nrow_match <- nrow(orig) == nrow(rep)
  ncol_match <- ncol(orig) == ncol(rep)
  
  # Compare key columns
  exp_id_match <- all(orig$exp_id == rep$exp_id)
  name_match <- all(orig$name == rep$name)
  score_match <- all(abs(orig$cmap_score - rep$cmap_score) < 1e-10, na.rm = TRUE)
  
  all_match <- nrow_match && ncol_match && exp_id_match && name_match && score_match
  
  cat(sprintf("%-10s │ Rows: %3d ↔ %3d │ ", sig$name, nrow(orig), nrow(rep)))
  cat(sprintf("Exp_ID: %s │ ", if(exp_id_match) "✓" else "✗"))
  cat(sprintf("Names: %s │ ", if(name_match) "✓" else "✗"))
  cat(sprintf("Scores: %s │ ", if(score_match) "✓" else "✗"))
  cat(sprintf("Result: %s\n", if(all_match) "✓ MATCH" else "✗ DIFFER"))
  
  comparison_results <- rbind(comparison_results,
                             data.frame(
                               Signature = sig$name,
                               Rows_Match = nrow_match,
                               Cols_Match = ncol_match,
                               Exp_ID_Match = exp_id_match,
                               Names_Match = name_match,
                               Scores_Match = score_match,
                               Overall_Match = all_match
                             ))
}

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║                    DETAILED COMPARISON RESULTS                ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Print summary
if (all(comparison_results$Overall_Match)) {
  cat("✓ SUCCESS: All replicated files match the originals!\n\n")
} else {
  cat("✗ MISMATCH: Some files differ from originals.\n\n")
}

# Show summary table
summary_table <- comparison_results %>%
  select(Signature, Overall_Match) %>%
  mutate(Status = if_else(Overall_Match, "✓ MATCH", "✗ DIFFER"))

print(summary_table[, c("Signature", "Status")])

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
