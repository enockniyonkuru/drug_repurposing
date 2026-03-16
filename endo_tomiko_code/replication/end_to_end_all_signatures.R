#####################################################################
# COMPLETE END-TO-END REPLICATION: FROM RAW DATA FOR ALL SIGNATURES
# ESE, MSE, PE, IIInIV, InII
#####################################################################

library(dplyr)
library(qvalue)

# List of all signatures
signatures <- list(
  list(name = "ESE", path = "code/by phase/ESE", rawdata = "rawdata.csv"),
  list(name = "MSE", path = "code/by phase/MSE", rawdata = "rawdata.csv"),
  list(name = "PE", path = "code/by phase/PE", rawdata = "rawdata.csv"),
  list(name = "IIInIV", path = "code/by stage/IIInIV", rawdata = "rawdata.csv"),
  list(name = "InII", path = "code/by stage/InII", rawdata = "rawdata.csv")
)

# Load CMap data (same for all)
load('~/Desktop/endo_tomiko_code/code/cmap data/cmap_signatures.RData')
gene_list <- subset(cmap_signatures, select=1)
cmap_signatures <- cmap_signatures[, 2:ncol(cmap_signatures)]

cmap_experiments <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_drug_experiments_new.csv", 
                             stringsAsFactors = FALSE)
valid_instances <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_valid_instances.csv", 
                            stringsAsFactors = FALSE)

cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[
  cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]

# cmap_score function
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

cat("\n════════════════════════════════════════════════════════════════\n")
cat("END-TO-END PIPELINE FOR ALL 5 SIGNATURES\n")
cat("════════════════════════════════════════════════════════════════\n\n")

# Run for each signature
for (sig in signatures) {
  cat("Processing:", sig$name, "\n")
  
  # Create output directory
  output_dir <- file.path("~/Desktop/endo_tomiko_code/replication", 
                          paste0("end_to_end_", sig$name))
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Load raw data
  rawdata_file <- file.path("~/Desktop/endo_tomiko_code", sig$path, sig$rawdata)
  dz_signature_raw <- read.csv(rawdata_file)
  
  # Rename columns
  colnames(dz_signature_raw)[c(1,2)] <- c("GeneID", "log2FoldChange")
  
  # Filter
  dz_signature_raw <- dz_signature_raw[which(dz_signature_raw$adj.P.Val < 0.05), ]
  dz_signature_raw <- dz_signature_raw[which(abs(dz_signature_raw$log2FoldChange) > 1.1), ]
  dz_signature_raw <- dz_signature_raw[order(dz_signature_raw$log2FoldChange), ]
  dz_signature_raw$GeneID <- gsub("_at", "", paste(dz_signature_raw$GeneID))
  dz_signature <- dz_signature_raw[which(dz_signature_raw$GeneID %in% gene_list$V1), ]
  
  # Separate genes
  dz_genes_up <- subset(dz_signature, log2FoldChange > 0, select="GeneID")
  dz_genes_down <- subset(dz_signature, log2FoldChange < 0, select="GeneID")
  
  # Random scores (1000 permutations)
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
  
  # Score all drugs
  dz_cmap_scores <- sapply(1:ncol(cmap_signatures), function(exp_id) {
    cmap_exp_signature <- cbind(gene_list, subset(cmap_signatures, select=exp_id))
    colnames(cmap_exp_signature) <- c("ids", "rank")
    cmap_score(dz_genes_up, dz_genes_down, cmap_exp_signature)
  })
  
  # P-values and q-values
  p_values <- sapply(dz_cmap_scores, function(score) {
    length(which(abs(random_scores) >= abs(score))) / length(random_scores)
  })
  q_values <- qvalue(p_values)$qvalues
  
  # Compile results
  subset_comparison_id <- paste0(sig$name, "_endo")
  analysis_id <- "cmap"
  
  drugs <- data.frame(
    exp_id = seq(1:length(dz_cmap_scores)), 
    cmap_score = dz_cmap_scores, 
    p = p_values, 
    q = q_values,
    subset_comparison_id, 
    analysis_id
  )
  
  # Merge with metadata
  drug_instances_all <- merge(drugs, cmap_experiments_valid, by.x="exp_id", by.y="id")
  
  # Filter
  drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)
  
  # Deduplicate
  drug_instances <- drug_instances %>% 
    group_by(name) %>% 
    dplyr::slice(which.min(cmap_score))
  
  drug_instances <- drug_instances[order(drug_instances$cmap_score), ]
  
  # Save
  output_file <- file.path(output_dir, paste0("drug_instances_", sig$name, "_e2e.csv"))
  write.csv(drug_instances, output_file)
  
  cat("  ✓ Saved:", nrow(drug_instances), "drugs\n\n")
}

cat("════════════════════════════════════════════════════════════════\n")
cat("✓ END-TO-END PIPELINE COMPLETE FOR ALL 5 SIGNATURES\n")
cat("════════════════════════════════════════════════════════════════\n\n")
