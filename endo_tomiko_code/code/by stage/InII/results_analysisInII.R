#####################################################################

# Component #2: Apply drug repositoning pipeline to transcriptomic condition signature
# Adapted from code written by Brian Le, Bin Chen, and Marina Sirota
# updated for endometriosis by Tomiko Oskotsky - October 2022
# For more details, see: Le et al.: https://insight.jci.org/articles/view/133761
# For original pipeline code, see: Chen et al.: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5447464/
#####################################################################

# Suggested: clear working environment before moving onto this part!
set.seed(2009) ## (TO)

library(pheatmap)
library(gplots)
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(AnnotationDbi)
library(reshape2)
library(pheatmap)

dataset <- "endo" 

load("~/Desktop/endometriosis/code/by stage/InII/results.RData")  #pipeline results
load('~/Desktop/endometriosis/code/cmap data/cmap_signatures.RData')   #cmap_signatures
cmap_experiments <- read.csv("~/Desktop/endometriosis/code/cmap data/cmap_drug_experiments_new.csv", stringsAsFactors =  F) #cmap profiles metadata
valid_instances <- read.csv("~/Desktop/endometriosis/code/cmap data/cmap_valid_instances.csv", stringsAsFactors = F)

drug_preds <- results[[1]]
dz_sig <- results[[2]]

#keep valid (concordant) profiles; keep drugs listed in DrugBank
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]

drug_instances_all <- merge(drug_preds, cmap_experiments_valid, by.x="exp_id", by.y="id")

#We can inspect the distribution of reversal scores
hist(drug_instances_all$cmap_score, breaks = 10)

#Apply thresholds for significant hits: here, we apply FDR < 0.05 and keep only the reversed profiles (cmap_score < 0)
drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)

#Since drugs in cmap have been tested multiple times, we keep the most negative score to be as inclusive as possible
#Alternatively, you could aggregate the scores in a different manner (e.g. averages, or based on metadata)
drug_instances <- drug_instances %>% 
  group_by(name) %>% 
  dplyr::slice(which.min(cmap_score))

drug_instances <- drug_instances[order(drug_instances$cmap_score), ]
drug_instances_id <- c(drug_instances$exp_id) + 1 #the first column is the gene id
#get candidate drugs
drug_signatures <- cmap_signatures[,c(1, drug_instances_id)] #the first column is the gene id

write.csv(drug_instances, "~/Desktop/endometriosis/code/by stage/InII/drug_instances_InII.csv")

drug_dz_signature <- merge(dz_sig[, c("GeneID", "log2FoldChange")], drug_signatures, by.x = "GeneID", by.y="V1")
colnames(drug_dz_signature)[2] <- "value"
drug_dz_signature <- drug_dz_signature[order(drug_dz_signature$value),]

#Convert disease and drug values to ranks from 1:numgenes
drug_dz_signature[,2] <- -drug_dz_signature[,2] # higher rank corresponds to more overexpressed, so we need to reverse order of disease sig
for (i in 2:ncol(drug_dz_signature)){
  drug_dz_signature[,i] <- rank(drug_dz_signature[,i] )
}
drug_dz_signature <- drug_dz_signature[order(drug_dz_signature[,2]),] #order by disease expression

gene_ids <- drug_dz_signature[,1]
drug_dz_signature <- drug_dz_signature[, -1]

drug_names <- sapply(2:ncol(drug_dz_signature), function(id){
  #need to minus 1 as in cmap_signatures, V1 is gene id.
  new_id <- strtoi(paste(unlist(strsplit(as.character(colnames(drug_dz_signature)[id]),""))[-1], collapse="")) - 1 
  cmap_experiments_valid$name[cmap_experiments_valid$id == new_id]
})
colnames(drug_dz_signature)[-1] <- drug_names

write.csv(drug_dz_signature, "~/Desktop/endometriosis/code/by stage/InII/drug_dz_signature_InII.csv")

#load("~/Desktop/drugs.csv")  #pipeline results

drug_dz_signature_limited <- drug_dz_signature[,1:25]
drug_names_limited <- drug_names[1:24]
gene_ids_limited <- gene_ids[1:24]

#FIGURE: all hits from cmap, using a red/blue color scheme
pdf(("~/Desktop/endometriosis/code/by stage/InII/heatmap_cmap_hits_InII.pdf"), width = 12, height = 15)
layout(matrix(1))
par(mar=c(6.5, 4, 1, 0.5))
colPal <- redblue(100)
image(t(drug_dz_signature_limited), col= colPal,   axes=F, srt=45)
axis(1,  at=seq(0,1,length.out= ncol( drug_dz_signature_limited) ), labels= F)
axis(2,  at=seq(0,1,length.out= length (gene_ids) ), labels= F)
text(x = seq(0,1,length.out=ncol(drug_dz_signature_limited)), c(-0.015),
     labels = c("endo sig", drug_names_limited), srt = 45, pos=2, offset=-0.2, xpd = TRUE, cex=1,
     col = "black")
dev.off()



############ What about looking at overlapping hits?

#hits_ALV <- read.csv(file = "results/ALV_hits.csv")
#hits_BALF <- read.csv(file = "results/BALF_hits.csv")

#tab_ALV <- data.frame(name = hits_ALV$name, source = "ALV", value = hits_ALV$cmap_score/min(hits_ALV$cmap_score))
#tab_BALF <- data.frame(name = hits_BALF$name, source = "BALF", value = hits_BALF$cmap_score/min(hits_BALF$cmap_score))
#df_all <- dcast(rbind(tab_ALV, tab_BALF), name ~ source, value.var = "value")
#df_all <- data.frame(drug_dz_signature)

#heatmap of drug repo hits
#df_all[is.na(df_all)] <- 0
#rownames(df_all) <- df_all[,1]

#tiff("~/Desktop/combined.tiff", width = 1200, height = 2400, res = 200)
#pheatmap(df_all[,c(2:3)], color = colorRampPalette(c("grey", "red3"))(100), border_color = "grey60",
       #  labels_col = c("ALV", "EXP", "BALF"), angle_col = "0",
        # fontsize_row = 8, fontsize_col = 12,
        # cluster_cols = FALSE, treeheight_row = 0, legend = FALSE)
#dev.off()