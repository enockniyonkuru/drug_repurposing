#####################################################################
# REPLICATION: Recreate drug_instances_unstratified.csv
# This script replicates the process from results_analysis.R
#####################################################################

library(dplyr)

# Load pipeline results and CMap data
load("~/Desktop/endo_tomiko_code/code/unstratified/results.RData")  #pipeline results
load('~/Desktop/endo_tomiko_code/code/cmap data/cmap_signatures.RData')   #cmap_signatures
cmap_experiments <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_drug_experiments_new.csv", stringsAsFactors = F) #cmap profiles metadata
valid_instances <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_valid_instances.csv", stringsAsFactors = F)

# Extract results
drug_preds <- results[[1]]
dz_sig <- results[[2]]

# Keep valid (concordant) profiles; keep drugs listed in DrugBank
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]

drug_instances_all <- merge(drug_preds, cmap_experiments_valid, by.x="exp_id", by.y="id")

# Apply thresholds for significant hits: FDR < 0.0001 and reversed profiles (cmap_score < 0)
drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)

# Keep the most negative score for each drug (best hit if tested multiple times)
drug_instances <- drug_instances %>% 
  group_by(name) %>% 
  dplyr::slice(which.min(cmap_score))

drug_instances <- drug_instances[order(drug_instances$cmap_score), ]

# Write to CSV
write.csv(drug_instances, "~/Desktop/endo_tomiko_code/replication/drug_instances_unstratified_replicated.csv")

print("Replication complete!")
print(paste("Number of drugs found:", nrow(drug_instances)))
print("First few rows:")
print(head(drug_instances, 3))
