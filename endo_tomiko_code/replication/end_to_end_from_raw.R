#####################################################################
# END-TO-END REPLICATION: From Raw Data to Drug Instances
# Starting from raw disease signatures through pipeline to final results
#####################################################################

library(dplyr)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║     END-TO-END REPLICATION: RAW DATA → DRUG INSTANCES         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# ==================== STEP 1: Load CMap Data ====================
cat("STEP 1: Loading CMap reference data...\n")
load('~/Desktop/endo_tomiko_code/code/cmap data/cmap_signatures.RData')
cmap_experiments <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_drug_experiments_new.csv", stringsAsFactors = F)
valid_instances <- read.csv("~/Desktop/endo_tomiko_code/code/cmap data/cmap_valid_instances.csv", stringsAsFactors = F)

gene_list <- subset(cmap_signatures, select=1)
cmap_signatures <- cmap_signatures[,2:ncol(cmap_signatures)]

cat("✓ Loaded CMap data: ~", ncol(cmap_signatures), "drug experiments\n\n")

# ==================== STEP 2: Define cmap_score function ====================
cat("STEP 2: Defining connectivity score function...\n")

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
  }
  
  if(num_tags_down > 1) {
    a_down <- max(sapply(1:num_tags_down, function(j) {
      j/num_tags_down - down_tags_position[j]/num_genes
    }))
    b_down <- max(sapply(1:num_tags_down, function(j) {
      down_tags_position[j]/num_genes - (j-1)/num_tags_down
    }))
    ks_down <- if(a_down > b_down) a_down else -b_down
  }
  
  if (ks_up == 0 & ks_down != 0) {
    connectivity_score <- -ks_down
  } else if (ks_up != 0 & ks_down == 0) {
    connectivity_score <- ks_up
  } else if (sum(sign(c(ks_down, ks_up))) == 0) {
    connectivity_score <- ks_up - ks_down
  }
  
  return(connectivity_score)
}

cat("✓ Function defined\n\n")

# ==================== STEP 3: Process each signature ====================
cat("STEP 3: Processing disease signatures from raw data...\n\n")

signatures <- list(
  list(name = "Unstratified", rawdata_path = "~/Desktop/endo_tomiko_code/code/unstratified/rawdata.csv"),
  list(name = "ESE", rawdata_path = "~/Desktop/endo_tomiko_code/code/by phase/ESE/rawdata_all.csv"),
  list(name = "MSE", rawdata_path = "~/Desktop/endo_tomiko_code/code/by phase/MSE/rawdata_all.csv"),
  list(name = "PE", rawdata_path = "~/Desktop/endo_tomiko_code/code/by phase/PE/rawdata_all.csv"),
  list(name = "IIInIV", rawdata_path = "~/Desktop/endo_tomiko_code/code/by stage/IIInIV/rawdata_all.csv"),
  list(name = "InII", rawdata_path = "~/Desktop/endo_tomiko_code/code/by stage/InII/rawdata_all.csv")
)

results_summary <- data.frame()

for (sig in signatures) {
  cat(sprintf("  Processing %s...\n", sig$name))
  
  # ========== STEP 3a: Load and filter raw disease signature ==========
  dz_signature <- read.csv(sig$rawdata_path)
  
  # Rename columns to match expected format
  if ("logFC" %in% colnames(dz_signature)) {
    dz_signature <- dz_signature %>% 
      rename(GeneID = probe.id, log2FoldChange = logFC, adj.P.Val = adj.P.Val)
  } else {
    dz_signature <- dz_signature %>%
      rename(GeneID = ., log2FoldChange = 2)
  }
  
  # Filter for significant genes
  dz_signature_filtered <- dz_signature[which(dz_signature$adj.P.Val < 0.05), ]
  dz_signature_filtered <- dz_signature_filtered[which(abs(dz_signature_filtered$log2FoldChange) > 1.1), ]
  dz_signature_filtered <- dz_signature_filtered[order(dz_signature_filtered$log2FoldChange), ]
  dz_signature_filtered$GeneID <- gsub("_at", "", dz_signature_filtered$GeneID)
  dz_signature_filtered <- dz_signature_filtered[which(dz_signature_filtered$GeneID %in% gene_list$V1), ]
  
  # Subset lists of up- and down-regulated genes
  dz_genes_up <- subset(dz_signature_filtered, log2FoldChange > 0, select = "GeneID")
  dz_genes_down <- subset(dz_signature_filtered, log2FoldChange < 0, select = "GeneID")
  
  # ========== STEP 3b: Calculate random scores ==========
  N_PERMUTATIONS <- 1000
  
  rand_cmap_scores <- sapply(sample(1:ncol(cmap_signatures), N_PERMUTATIONS, replace = T), function(exp_id) {
    cmap_exp_signature <- cbind(gene_list, subset(cmap_signatures, select = exp_id))
    colnames(cmap_exp_signature) <- c("ids", "rank")
    random_input_signature_genes <- sample(gene_list[,1], (nrow(dz_genes_up) + nrow(dz_genes_down)))
    rand_dz_gene_up <- data.frame(GeneID = random_input_signature_genes[1:nrow(dz_genes_up)])
    rand_dz_gene_down <- data.frame(GeneID = random_input_signature_genes[(nrow(dz_genes_up)+1):length(random_input_signature_genes)])
    cmap_score(rand_dz_gene_up, rand_dz_gene_down, cmap_exp_signature)
  }, simplify = F)
  
  # ========== STEP 3c: Calculate scores for all drugs ==========
  dz_cmap_scores <- sapply(1:ncol(cmap_signatures), function(exp_id) {
    cmap_exp_signature <- cbind(gene_list, subset(cmap_signatures, select = exp_id))
    colnames(cmap_exp_signature) <- c("ids", "rank")
    cmap_score(dz_genes_up, dz_genes_down, cmap_exp_signature)
  })
  
  # ========== STEP 3d: Calculate p-values and q-values ==========
  random_scores <- unlist(rand_cmap_scores)
  p_values <- sapply(dz_cmap_scores, function(score) {
    length(which(abs(random_scores) >= abs(score))) / length(random_scores)
  })
  
  library(qvalue)
  q_values <- qvalue(p_values)$qvalues
  
  # ========== STEP 3e: Create drug predictions dataframe ==========
  drug_preds <- data.frame(
    exp_id = seq(1:length(dz_cmap_scores)), 
    cmap_score = dz_cmap_scores, 
    p = p_values, 
    q = q_values,
    subset_comparison_id = paste0(tolower(sig$name), "_endo"),
    analysis_id = "cmap"
  )
  
  # ========== STEP 3f: Merge with CMap metadata and filter ==========
  cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by = "id")
  cmap_experiments_valid <- cmap_experiments_valid[cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]
  
  drug_instances_all <- merge(drug_preds, cmap_experiments_valid, by.x = "exp_id", by.y = "id")
  
  # Apply thresholds
  drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)
  
  # Keep best hit per drug
  drug_instances <- drug_instances %>%
    group_by(name) %>%
    dplyr::slice(which.min(cmap_score)) %>%
    arrange(cmap_score)
  
  # ========== STEP 3g: Save results ==========
  output_file <- sprintf("~/Desktop/endo_tomiko_code/replication/from_raw/drug_instances_%s_from_raw.csv", 
                         tolower(sig$name))
  write.csv(drug_instances, output_file)
  
  cat(sprintf("    ✓ %d candidate drugs identified\n", nrow(drug_instances)))
  
  results_summary <- rbind(results_summary,
                          data.frame(
                            Signature = sig$name,
                            Genes_Up = nrow(dz_genes_up),
                            Genes_Down = nrow(dz_genes_down),
                            Total_Genes = nrow(dz_genes_up) + nrow(dz_genes_down),
                            Drugs_Found = nrow(drug_instances),
                            Top_Score = min(drug_instances$cmap_score)
                          ))
}

# ==================== STEP 4: Summary ====================
cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║                    PROCESSING COMPLETE                        ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

print(results_summary)

cat("\n✓ All drug instances generated from raw data!\n")
cat("✓ Output folder: ~/Desktop/endo_tomiko_code/replication/from_raw/\n\n")
