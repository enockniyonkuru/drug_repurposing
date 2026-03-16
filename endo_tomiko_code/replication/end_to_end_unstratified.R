#####################################################################
# COMPLETE END-TO-END REPLICATION: FROM RAW DATA TO DRUG INSTANCES
# Starting from raw transcriptomic data, replicating entire pipeline
#####################################################################

library(dplyr)
library(qvalue)

# Create output directory
output_dir <- "~/Desktop/endo_tomiko_code/replication/end_to_end_unstratified"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("START: END-TO-END PIPELINE REPLICATION (UNSTRATIFIED)\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# STEP 1: LOAD RAW DATA
# ============================================================================
cat("STEP 1: Loading raw disease data...\n")

# Using rawdata.csv (the filtered version used in original pipeline)
dz_signature_raw <- read.csv("~/Desktop/endo_tomiko_code/code/unstratified/rawdata.csv")
cat("  - Loaded rawdata.csv with", nrow(dz_signature_raw), "genes\n")
cat("  - Columns:", paste(colnames(dz_signature_raw), collapse=", "), "\n\n")

# ============================================================================
# STEP 2: LOAD CMAP DATA (same for all signatures)
# ============================================================================
cat("STEP 2: Loading CMap drug signatures and metadata...\n")

load('~/Desktop/endo_tomiko_code/code/cmap data/cmap_signatures.RData')
gene_list <- subset(cmap_signatures, select=1)
cmap_signatures <- cmap_signatures[, 2:ncol(cmap_signatures)]

cmap_experiments <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_drug_experiments_new.csv", 
                             stringsAsFactors = FALSE)
valid_instances <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_valid_instances.csv", 
                            stringsAsFactors = FALSE)

cat("  - Loaded", ncol(cmap_signatures), "CMap drug profiles\n")
cat("  - Loaded", nrow(cmap_experiments), "CMap experiments\n\n")

# ============================================================================
# STEP 3: PROCESS DISEASE SIGNATURE
# ============================================================================
cat("STEP 3: Processing disease signature...\n")

# Rename columns to match pipeline
colnames(dz_signature_raw)[c(1,2)] <- c("GeneID", "log2FoldChange")

# Filter by significance
dz_signature_raw <- dz_signature_raw[which(dz_signature_raw$adj.P.Val < 0.05), ]
cat("  - Filtered by adj.P.Val < 0.05:", nrow(dz_signature_raw), "genes\n")

# Filter by fold change
dz_signature_raw <- dz_signature_raw[which(abs(dz_signature_raw$log2FoldChange) > 1.1), ]
cat("  - Filtered by |log2FC| > 1.1:", nrow(dz_signature_raw), "genes\n")

# Sort by log2FoldChange
dz_signature_raw <- dz_signature_raw[order(dz_signature_raw$log2FoldChange), ]

# Clean gene IDs (remove probe suffixes)
dz_signature_raw$GeneID <- gsub("_at", "", paste(dz_signature_raw$GeneID))

# Keep only genes in CMap
dz_signature <- dz_signature_raw[which(dz_signature_raw$GeneID %in% gene_list$V1), ]
cat("  - Intersected with CMap genes:", nrow(dz_signature), "genes\n\n")

# Save processed disease signature
write.csv(dz_signature, file.path(output_dir, "dz_signature_processed.csv"))
cat("  ✓ Saved processed disease signature\n\n")

# ============================================================================
# STEP 4: DEFINE CMAP_SCORE FUNCTION
# ============================================================================
cat("STEP 4: Defining cmap_score function...\n\n")

cmap_score <- function(sig_up, sig_down, drug_signature) {
  num_genes <- nrow(drug_signature)
  ks_up <- 0
  ks_down <- 0
  connectivity_score <- 0
  
  drug_signature[,"rank"] <- rank(drug_signature[,"rank"])
  
  up_tags_rank <- merge(drug_signature, sig_up, by.x = "ids", by.y = 1)
  down_tags_rank <- merge(drug_signature, sig_down, by.x = "ids", by.y = 1)
  
  up_tags_position <- sort(up_tags_rank$rank)
  down_tags_position <- sort(down_tags_rank$rank)
  
  num_tags_up <- length(up_tags_position)
  num_tags_down <- length(down_tags_position)
  
  if(num_tags_up > 1) {
    a_up <- 0
    b_up <- 0
    
    a_up <- max(sapply(1:num_tags_up, function(j) {
      j/num_tags_up - up_tags_position[j]/num_genes
    }))
    b_up <- max(sapply(1:num_tags_up, function(j) {
      up_tags_position[j]/num_genes - (j-1)/num_tags_up
    }))
    
    if(a_up > b_up) {
      ks_up <- a_up
    } else {
      ks_up <- -b_up
    }
  } else {
    ks_up <- 0
  }
  
  if (num_tags_down > 1){
    a_down <- 0
    b_down <- 0
    
    a_down <- max(sapply(1:num_tags_down, function(j) {
      j/num_tags_down - down_tags_position[j]/num_genes
    }))
    b_down <- max(sapply(1:num_tags_down, function(j) {
      down_tags_position[j]/num_genes - (j-1)/num_tags_down
    }))
    
    if(a_down > b_down) {
      ks_down <- a_down
    } else {
      ks_down <- -b_down
    }
  } else {
    ks_down <- 0
  }
  
  if (ks_up == 0 & ks_down != 0){
    connectivity_score <- -ks_down
  } else if (ks_up != 0 & ks_down == 0){
    connectivity_score <- ks_up
  } else if (sum(sign(c(ks_down, ks_up))) == 0) {
    connectivity_score <- ks_up - ks_down
  }
  
  return(connectivity_score)
}

cat("  ✓ cmap_score function defined\n\n")

# ============================================================================
# STEP 5: SEPARATE UP AND DOWN REGULATED GENES
# ============================================================================
cat("STEP 5: Separating up/down regulated genes...\n")

dz_genes_up <- subset(dz_signature, log2FoldChange > 0, select="GeneID")
dz_genes_down <- subset(dz_signature, log2FoldChange < 0, select="GeneID")

cat("  - Up-regulated genes:", nrow(dz_genes_up), "\n")
cat("  - Down-regulated genes:", nrow(dz_genes_down), "\n\n")

# ============================================================================
# STEP 6: CALCULATE RANDOM DISTRIBUTION (for p-value calculation)
# ============================================================================
cat("STEP 6: Calculating random score distribution (1,000 permutations)...\n")

N_PERMUTATIONS <- 1000

rand_cmap_scores <- sapply(sample(1:ncol(cmap_signatures), N_PERMUTATIONS, replace=TRUE), 
                           function(exp_id) {
  if (exp_id %% 100 == 0) cat("  - Permutation", exp_id, "\n")
  
  cmap_exp_signature <- cbind(gene_list, subset(cmap_signatures, select=exp_id))
  colnames(cmap_exp_signature) <- c("ids", "rank")
  
  random_input_signature_genes <- sample(gene_list[,1], 
                                        (nrow(dz_genes_up) + nrow(dz_genes_down)))
  rand_dz_gene_up <- data.frame(GeneID = random_input_signature_genes[1:nrow(dz_genes_up)])
  rand_dz_gene_down <- data.frame(GeneID = random_input_signature_genes[
    (nrow(dz_genes_up)+1):length(random_input_signature_genes)])
  
  cmap_score(rand_dz_gene_up, rand_dz_gene_down, cmap_exp_signature)
}, simplify=FALSE)

random_scores <- unlist(rand_cmap_scores)
cat("  ✓ Random distribution calculated\n\n")

# ============================================================================
# STEP 7: SCORE ALL DRUGS AGAINST DISEASE SIGNATURE
# ============================================================================
cat("STEP 7: Computing connectivity scores for all drugs...\n")

dz_cmap_scores <- sapply(1:ncol(cmap_signatures), function(exp_id) {
  if (exp_id %% 500 == 0) cat("  - Drug", exp_id, "/", ncol(cmap_signatures), "\n")
  
  cmap_exp_signature <- cbind(gene_list, subset(cmap_signatures, select=exp_id))
  colnames(cmap_exp_signature) <- c("ids", "rank")
  cmap_score(dz_genes_up, dz_genes_down, cmap_exp_signature)
})

cat("  ✓ Scored", length(dz_cmap_scores), "drug profiles\n\n")

# ============================================================================
# STEP 8: CALCULATE P-VALUES AND Q-VALUES
# ============================================================================
cat("STEP 8: Computing p-values and q-values...\n")

p_values <- sapply(dz_cmap_scores, function(score) {
  length(which(abs(random_scores) >= abs(score))) / length(random_scores)
})

q_values <- qvalue(p_values)$qvalues

cat("  - Min p-value:", min(p_values), "\n")
cat("  - Min q-value:", min(q_values), "\n\n")

# ============================================================================
# STEP 9: COMPILE DRUG RESULTS
# ============================================================================
cat("STEP 9: Compiling drug results...\n")

subset_comparison_id <- "unstratified_endo"
analysis_id <- "cmap"

drugs <- data.frame(
  exp_id = seq(1:length(dz_cmap_scores)), 
  cmap_score = dz_cmap_scores, 
  p = p_values, 
  q = q_values,
  subset_comparison_id, 
  analysis_id
)

cat("  - Created results dataframe with", nrow(drugs), "rows\n\n")

# ============================================================================
# STEP 10: MERGE WITH EXPERIMENT METADATA
# ============================================================================
cat("STEP 10: Merging with CMap experiment metadata...\n")

cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[
  cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]

drug_instances_all <- merge(drugs, cmap_experiments_valid, by.x="exp_id", by.y="id")

cat("  - Merged with", nrow(drug_instances_all), "valid experiments\n\n")

# ============================================================================
# STEP 11: FILTER FOR SIGNIFICANT HITS
# ============================================================================
cat("STEP 11: Filtering for significant hits (q < 0.0001, score < 0)...\n")

drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)

cat("  - Found", nrow(drug_instances), "significant hits\n\n")

# ============================================================================
# STEP 12: DEDUPLICATE BY DRUG (KEEP BEST SCORE)
# ============================================================================
cat("STEP 12: Deduplicating by drug name (keeping best score)...\n")

drug_instances <- drug_instances %>% 
  group_by(name) %>% 
  dplyr::slice(which.min(cmap_score))

drug_instances <- drug_instances[order(drug_instances$cmap_score), ]

cat("  - After deduplication:", nrow(drug_instances), "unique drugs\n\n")

# ============================================================================
# STEP 13: SAVE RESULTS
# ============================================================================
cat("STEP 13: Saving results...\n\n")

# Save drug instances
output_file <- file.path(output_dir, "drug_instances_from_raw_data.csv")
write.csv(drug_instances, output_file)
cat("  ✓ Saved:", output_file, "\n")

# Save full results (for results_analysis.R compatibility)
results <- list(drug_instances, dz_signature)
results_file <- file.path(output_dir, "results.RData")
save(results, file = results_file)
cat("  ✓ Saved:", results_file, "\n\n")

# ============================================================================
# VERIFICATION
# ============================================================================
cat("════════════════════════════════════════════════════════════════\n")
cat("COMPLETION SUMMARY\n")
cat("════════════════════════════════════════════════════════════════\n\n")

cat("Input: rawdata.csv with", nrow(dz_signature_raw) + nrow(dz_signature_raw[which(dz_signature_raw$adj.P.Val >= 0.05 | abs(dz_signature_raw$log2FoldChange) <= 1.1), ]), "genes\n")
cat("After filtering: ", nrow(dz_signature), "significant genes\n")
cat("Scored against: ", ncol(cmap_signatures), "CMap drug profiles\n")
cat("Significant hits: ", nrow(drug_instances), "unique drugs\n\n")

cat("Top 5 drugs:\n")
print(head(drug_instances[, c("name", "cmap_score", "DrugBank.ID")], 5))

cat("\n✓ END-TO-END PIPELINE COMPLETE\n")
cat("════════════════════════════════════════════════════════════════\n\n")
