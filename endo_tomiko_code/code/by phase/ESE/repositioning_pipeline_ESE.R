#####################################################################
# Comp Immuno Mini-course Workshop: Computational Drug Repositioning
# Case study: COVID-19
#
# Component #2: Apply drug repositoning pipeline to transcriptomic sPTB signature
# Adapted from code written by Brian Le, Bin Chen, and Marina Sirota
# For more details, see: Le et al.: https://insight.jci.org/articles/view/133761
# For original pipeline code, see: Chen et al.: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5447464/
#####################################################################

# Suggested: clear working environment before moving onto this part!

library(AnnotationDbi)
library(ggplot2)
library(org.Hs.eg.db)
library(qvalue)
library(tidyr)

### FUNCTION: cmap_score calculates the reversal score between the input signature and the drug profile
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
  
  # 
  if(num_tags_up > 1) {
    a_up <- 0
    b_up <- 0
    
    a_up <- max(sapply(1:num_tags_up,function(j) {
      j/num_tags_up - up_tags_position[j]/num_genes
    }))
    b_up <- max(sapply(1:num_tags_up,function(j) {
      up_tags_position[j]/num_genes - (j-1)/num_tags_up
    }))
    
    if(a_up > b_up) {
      ks_up <- a_up
    } else {
      ks_up <- -b_up
    }
  }else{
    ks_up <- 0
  }
  
  if (num_tags_down > 1){
    
    a_down <- 0
    b_down <- 0
    
    a_down <- max(sapply(1:num_tags_down,function(j) {
      j/num_tags_down - down_tags_position[j]/num_genes
    }))
    b_down <- max(sapply(1:num_tags_down,function(j) {
      down_tags_position[j]/num_genes - (j-1)/num_tags_down
    }))
    
    if(a_down > b_down) {
      ks_down <- a_down
    } else {
      ks_down <- -b_down
    }
  }else{
    ks_down <- 0
  }
  
  if (ks_up == 0 & ks_down != 0){ #only down gene inputed
    connectivity_score <- -ks_down
  }else if (ks_up !=0 & ks_down == 0){ #only up gene inputed
    connectivity_score <- ks_up
  }else if (sum(sign(c(ks_down,ks_up))) == 0) {
    connectivity_score <- ks_up - ks_down # different signs
  }
  
  return(connectivity_score)
}

# Load in CMap drug profiles 
load('~/Desktop/endometriosis/cmap data/cmap_signatures.RData')
gene_list <- subset(cmap_signatures,select=1)
cmap_signatures <- cmap_signatures[,2:ncol(cmap_signatures)] 


# Dataset: Endometriosis
dataset <- "endo"
dz_signature <- read.csv("~/Desktop/endometriosis/by phase/ESE/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC

dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap


####################
# Subset lists of up-regulated genes and down-regulated genes
dz_genes_up <- subset(dz_signature, log2FoldChange > 0, select="GeneID")
dz_genes_down <- subset(dz_signature, log2FoldChange < 0, select="GeneID")

# Intersection of genes in CMap drug profiles and dz_signature
dz_cmap_common_genes <- intersect(gene_list$V1, dz_signature$GeneID)
dz_cmap_common_genes <- merge(gene_list, dz_signature,
                              by.x = "V1", by.y = "GeneID",
                              all.x = FALSE, all.y = FALSE)

# Calculate distribution of scores using random genes (same number of up- and down-regulated genes)
# against random drugs
N_PERMUTATIONS <- 1000 #default 100000

rand_cmap_scores <- sapply(sample(1:ncol(cmap_signatures),N_PERMUTATIONS,replace=T),function(exp_id) {
  print(paste("Computing score for disease against cmap_experiment_id =",exp_id))
  cmap_exp_signature <- cbind(gene_list,subset(cmap_signatures,select=exp_id))
  colnames(cmap_exp_signature) <- c("ids","rank")
  random_input_signature_genes <- sample(gene_list[,1], (nrow(dz_genes_up)+nrow(dz_genes_down)))
  rand_dz_gene_up <- data.frame(GeneID=random_input_signature_genes[1:nrow(dz_genes_up)])
  rand_dz_gene_down <- data.frame(GeneID=random_input_signature_genes[(nrow(dz_genes_up)+1):length(random_input_signature_genes)])
  cmap_score(rand_dz_gene_up,rand_dz_gene_down,cmap_exp_signature)
},simplify=F)

#write.csv(rand_cmap_scores,"~/Desktop/rand_cmap_scores.csv",row.names=TRUE)
# Ran permutation 1,000 times, but typically a much higher distribution is used
# Load in data from permutation ran 100,000 times
#load(file = paste0("results/cmap_random_scores_", dataset, "_100000.RData"))


#############################
# Compute reversal score for each drug profile in CMap using dz_signature
dz_cmap_scores <- sapply(1:ncol(cmap_signatures),function(exp_id) {
  print(paste("Computing score for disease against cmap_experiment_id =",exp_id))
  cmap_exp_signature <- cbind(gene_list,subset(cmap_signatures,select=exp_id))
  colnames(cmap_exp_signature) <- c("ids","rank")
  cmap_score(dz_genes_up,dz_genes_down,cmap_exp_signature)
})

# Compute the significance against the random scores
random_scores <- unlist(rand_cmap_scores)
# Frequency-based p-value using absolute scores from sampling distribution to approximate two-tailed p-value
print("COMPUTING p-values")
p_values <- sapply(dz_cmap_scores,function(score) {
  length(which(abs(random_scores) >= abs(score))) / length(random_scores)
})
print("COMPUTING q-values")
q_values <- qvalue(p_values)$qvalues

subset_comparison_id <- paste0("ESE_", dataset)
analysis_id <- "cmap"

drugs <- data.frame(exp_id = seq(1:length(dz_cmap_scores)), cmap_score = dz_cmap_scores, p = p_values, q = q_values,
                    subset_comparison_id, analysis_id)
results <- list(drugs, dz_signature)
save(results, file = "~/Desktop/endometriosis/by phase/ESE/results.RData")
