#####################################################################
# COMPLETE END-TO-END REPLICATION: ALL 6 SIGNATURES
# Using rawdata.csv (filtered) for each signature
#####################################################################

library(dplyr)
library(qvalue)

# Set random seed for reproducibility (same as original pipeline)
set.seed(2009)

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("END-TO-END PIPELINE: ALL 6 SIGNATURES FROM rawdata.csv\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Define all 6 signatures with their rawdata.csv paths
signatures <- list(
  list(name = "Unstratified", 
       rawdata_path = "~/Desktop/drug_repurposing/endo_tomiko_code/code/unstratified/rawdata.csv",
       output_dir = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/Unstratified"),
  list(name = "ESE", 
       rawdata_path = "~/Desktop/drug_repurposing/endo_tomiko_code/code/by phase/ESE/rawdata.csv",
       output_dir = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/ESE"),
  list(name = "MSE", 
       rawdata_path = "~/Desktop/drug_repurposing/endo_tomiko_code/code/by phase/MSE/rawdata.csv",
       output_dir = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/MSE"),
  list(name = "PE", 
       rawdata_path = "~/Desktop/drug_repurposing/endo_tomiko_code/code/by phase/PE/rawdata.csv",
       output_dir = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/PE"),
  list(name = "IIInIV", 
       rawdata_path = "~/Desktop/drug_repurposing/endo_tomiko_code/code/by stage/IIInIV/rawdata.csv",
       output_dir = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/IIInIV"),
  list(name = "InII", 
       rawdata_path = "~/Desktop/drug_repurposing/endo_tomiko_code/code/by stage/InII/rawdata.csv",
       output_dir = "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/InII")
)

# Create output directory
dir.create("~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata", 
           showWarnings = FALSE, recursive = TRUE)

# Load CMap data once (same for all signatures)
cat("Loading CMap data...\n")
load('~/Desktop/drug_repurposing/endo_tomiko_code/code/cmap data/cmap_signatures.RData')
gene_list <- subset(cmap_signatures, select=1)
cmap_signatures <- cmap_signatures[, 2:ncol(cmap_signatures)]

cmap_experiments <- read.csv("~/Desktop/drug_repurposing/endo_tomiko_code/code/cmap data/cmap_drug_experiments_new.csv", 
                             stringsAsFactors = FALSE)
valid_instances <- read.csv("~/Desktop/drug_repurposing/endo_tomiko_code/code/cmap data/cmap_valid_instances.csv", 
                            stringsAsFactors = FALSE)

# Keep valid experiments
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[
  cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]

cat("Loaded", ncol(cmap_signatures), "CMap profiles\n\n")

# Define cmap_score function
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
    a_up <- max(sapply(1:num_tags_up, function(j) {
      j/num_tags_up - up_tags_position[j]/num_genes
    }))
    b_up <- max(sapply(1:num_tags_up, function(j) {
      up_tags_position[j]/num_genes - (j-1)/num_tags_up
    }))
    ks_up <- if(a_up > b_up) a_up else -b_up
  } else {
    ks_up <- 0
  }
  
  if (num_tags_down > 1){
    a_down <- max(sapply(1:num_tags_down, function(j) {
      j/num_tags_down - down_tags_position[j]/num_genes
    }))
    b_down <- max(sapply(1:num_tags_down, function(j) {
      down_tags_position[j]/num_genes - (j-1)/num_tags_down
    }))
    ks_down <- if(a_down > b_down) a_down else -b_down
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

# Process each signature
results_summary <- data.frame()

for (sig in signatures) {
  cat("════════════════════════════════════════════════════════════════\n")
  cat("PROCESSING:", sig$name, "\n")
  cat("════════════════════════════════════════════════════════════════\n\n")
  
  dir.create(sig$output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Load raw data
  cat("1. Loading raw data from:", sig$rawdata_path, "\n")
  dz_signature_raw <- read.csv(sig$rawdata_path)
  colnames(dz_signature_raw)[c(1,2)] <- c("GeneID", "log2FoldChange")
  
  cat("   - Raw genes loaded:", nrow(dz_signature_raw), "\n")
  
  # Filter
  dz_signature_raw <- dz_signature_raw[which(dz_signature_raw$adj.P.Val < 0.05), ]
  cat("   - After adj.P.Val < 0.05:", nrow(dz_signature_raw), "\n")
  
  dz_signature_raw <- dz_signature_raw[which(abs(dz_signature_raw$log2FoldChange) > 1.1), ]
  cat("   - After |log2FC| > 1.1:", nrow(dz_signature_raw), "\n")
  
  dz_signature_raw <- dz_signature_raw[order(dz_signature_raw$log2FoldChange), ]
  dz_signature_raw$GeneID <- gsub("_at", "", paste(dz_signature_raw$GeneID))
  dz_signature <- dz_signature_raw[which(dz_signature_raw$GeneID %in% gene_list$V1), ]
  
  cat("   - Filtered genes (in CMap):", nrow(dz_signature), "\n\n")
  
  # Separate up/down
  dz_genes_up <- subset(dz_signature, log2FoldChange > 0, select="GeneID")
  dz_genes_down <- subset(dz_signature, log2FoldChange < 0, select="GeneID")
  
  cat("2. Separated genes: Up =", nrow(dz_genes_up), ", Down =", nrow(dz_genes_down), "\n\n")
  
  # Random distribution
  cat("3. Computing random distribution (1,000 permutations)...\n")
  N_PERMUTATIONS <- 1000
  rand_cmap_scores <- sapply(sample(1:ncol(cmap_signatures), N_PERMUTATIONS, replace=TRUE), 
                             function(exp_id) {
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
  cat("   ✓ Done\n\n")
  
  # Score all drugs
  cat("4. Scoring all drugs...\n")
  dz_cmap_scores <- sapply(1:ncol(cmap_signatures), function(exp_id) {
    cmap_exp_signature <- cbind(gene_list, subset(cmap_signatures, select=exp_id))
    colnames(cmap_exp_signature) <- c("ids", "rank")
    cmap_score(dz_genes_up, dz_genes_down, cmap_exp_signature)
  })
  cat("   ✓ Scored", length(dz_cmap_scores), "profiles\n\n")
  
  # P-values and q-values
  cat("5. Computing statistics...\n")
  p_values <- sapply(dz_cmap_scores, function(score) {
    length(which(abs(random_scores) >= abs(score))) / length(random_scores)
  })
  q_values <- qvalue(p_values)$qvalues
  cat("   ✓ Done\n\n")
  
  # Compile results
  cat("6. Compiling results...\n")
  subset_comparison_id <- paste0(tolower(sig$name), "_endo")
  analysis_id <- "cmap"
  
  drugs <- data.frame(
    exp_id = seq(1:length(dz_cmap_scores)), 
    cmap_score = dz_cmap_scores, 
    p = p_values, 
    q = q_values,
    subset_comparison_id, 
    analysis_id
  )
  
  drug_instances_all <- merge(drugs, cmap_experiments_valid, by.x="exp_id", by.y="id")
  drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)
  
  cat("   - Significant hits:", nrow(drug_instances), "\n")
  
  # Deduplicate
  cat("7. Deduplicating...\n")
  drug_instances <- drug_instances %>% 
    group_by(name) %>% 
    dplyr::slice(which.min(cmap_score))
  
  drug_instances <- drug_instances[order(drug_instances$cmap_score), ]
  
  cat("   - Unique drugs:", nrow(drug_instances), "\n\n")
  
  # Save
  cat("8. Saving results...\n")
  output_file <- file.path(sig$output_dir, paste0("drug_instances_", sig$name, ".csv"))
  write.csv(drug_instances, output_file, row.names = FALSE)
  
  results <- list(drug_instances, dz_signature)
  results_file <- file.path(sig$output_dir, "results.RData")
  save(results, file = results_file)
  
  cat("   ✓ Saved to:", sig$output_dir, "\n\n")
  
  # Record summary
  results_summary <- rbind(results_summary, 
                          data.frame(Signature = sig$name, 
                                    Genes_Up = nrow(dz_genes_up),
                                    Genes_Down = nrow(dz_genes_down),
                                    Total_Genes = nrow(dz_genes_up) + nrow(dz_genes_down),
                                    Drugs = nrow(drug_instances),
                                    Top_Drug = drug_instances$name[1],
                                    Top_Score = round(drug_instances$cmap_score[1], 4)))
}

cat("\n════════════════════════════════════════════════════════════════\n")
cat("FINAL SUMMARY\n")
cat("════════════════════════════════════════════════════════════════\n\n")
print(results_summary)

# Save summary
write.csv(results_summary, 
          "~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/summary.csv",
          row.names = FALSE)

cat("\n✓ ALL 6 SIGNATURES PROCESSED\n")
cat("✓ Results saved to: ~/Desktop/drug_repurposing/endo_tomiko_code/replication/e2e_rawdata/\n\n")
