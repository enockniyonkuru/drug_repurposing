#####################################################################
# REPLICATION: Recreate drug_instances for ALL signatures
# ESE, MSE, PE, IIInIV, InII
#####################################################################

library(dplyr)

# List of all signatures to replicate
signatures <- list(
  list(name = "ESE", path = "code/by phase/ESE"),
  list(name = "MSE", path = "code/by phase/MSE"),
  list(name = "PE", path = "code/by phase/PE"),
  list(name = "IIInIV", path = "code/by stage/IIInIV"),
  list(name = "InII", path = "code/by stage/InII")
)

# Load CMap data (same for all signatures)
load('~/Desktop/endo_tomiko_code/code/cmap data/cmap_signatures.RData')
cmap_experiments <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_drug_experiments_new.csv", stringsAsFactors = F)
valid_instances <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_valid_instances.csv", stringsAsFactors = F)

# Keep valid (concordant) profiles; keep drugs listed in DrugBank
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]

# Replicate for each signature
results_summary <- data.frame()

for (sig in signatures) {
  cat("\n========================================\n")
  cat("Processing:", sig$name, "\n")
  cat("========================================\n")
  
  # Load results for this signature
  results_file <- file.path("~/Desktop/endo_tomiko_code", sig$path, "results.RData")
  load(results_file)
  
  drug_preds <- results[[1]]
  dz_sig <- results[[2]]
  
  # Merge with CMap experiments
  drug_instances_all <- merge(drug_preds, cmap_experiments_valid, by.x="exp_id", by.y="id")
  
  # Apply thresholds: FDR < 0.0001 and reversed profiles (cmap_score < 0)
  drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)
  
  # Keep the most negative score for each drug
  drug_instances <- drug_instances %>% 
    group_by(name) %>% 
    dplyr::slice(which.min(cmap_score))
  
  drug_instances <- drug_instances[order(drug_instances$cmap_score), ]
  
  # Write to replication folder
  output_file <- file.path("~/Desktop/endo_tomiko_code/replication", 
                           paste0("drug_instances_", sig$name, "_replicated.csv"))
  write.csv(drug_instances, output_file)
  
  cat("✓ Replicated:", nrow(drug_instances), "drugs\n")
  
  # Record summary
  results_summary <- rbind(results_summary, 
                          data.frame(Signature = sig$name, 
                                    Drugs = nrow(drug_instances),
                                    Top_Score = min(drug_instances$cmap_score)))
}

cat("\n========================================\n")
cat("REPLICATION SUMMARY\n")
cat("========================================\n")
print(results_summary)
cat("\nAll files saved to: ~/Desktop/endo_tomiko_code/replication/\n")
