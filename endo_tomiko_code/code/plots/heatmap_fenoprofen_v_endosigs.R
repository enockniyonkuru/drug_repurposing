#####################################################################
# Comp Immuno Mini-course Workshop: Computational Drug Repositioning
# Case study: COVID-19
#
# Component #3: Inspect the results! What drugs come up? How do the signatures look in comparison
# to the drug profiles?
# Adapted from code written by Brian Le, Bin Chen, and Marina Sirota
# For more details, see: Le et al.: https://insight.jci.org/articles/view/133761
# For original pipelien code, see: Chen et al.: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5447464/
#####################################################################

## based on results_analysis.R

## TO script works for heatmap of drug and 6 endo signatures for SHARED ***SIGNIFICANT*** genes

library(pheatmap)
library(gplots)
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(AnnotationDbi)
library(reshape2)
library(pheatmap)

dataset <- "endo" 

load("~/Desktop/endometriosis/code/unstratified/results.RData")  #pipeline results, unstratified
gene_ids_u <- results[[2]]['GeneID']
load("~/Desktop/endometriosis/code/by stage/InII/results.RData")  #pipeline results, stage I + II
gene_ids_InII <- results[[2]]['GeneID']
load("~/Desktop/endometriosis/code/by stage/IIInIV/results.RData")  #pipeline results, stage III + IV
gene_ids_IIInIV <- results[[2]]['GeneID']
load("~/Desktop/endometriosis/code/by phase/PE/results.RData")  #pipeline results, phase PE
gene_ids_p <- results[[2]]['GeneID']
load("~/Desktop/endometriosis/code/by phase/ESE/results.RData")  #pipeline results, phase ESE
gene_ids_e <- results[[2]]['GeneID']
load("~/Desktop/endometriosis/code/by phase/MSE/results.RData")  #pipeline results, phase MSE
gene_ids_m <- results[[2]]['GeneID']

## find the genes that are represented in unstratified and stratified signatures
gene_ids_all <- rbind(gene_ids_u, gene_ids_InII, gene_ids_IIInIV, gene_ids_p, gene_ids_e, gene_ids_m)
gene_ids_all <- as.data.frame(table(gene_ids_all)) ## determines the frequency (1 - 6) of each gene in column 'Freq'
gene_ids_all <- gene_ids_all[gene_ids_all$Freq == 6,] ## nrow 105 SIGNIFICANT?? shared genes by 6 signatures

## if using any gene (not just significant ones), then use gene_ids_all from genecounts.R
gene_ids_all <- read.csv("~/Desktop/endometriosis/code/gene_ids_all.csv")


load('~/Desktop/endometriosis/code/cmap data/cmap_signatures.RData')   #cmap_signatures
cmap_experiments <- read.csv("~/Desktop/endometriosis/code/cmap data/cmap_drug_experiments_new.csv", stringsAsFactors =  F) #cmap profiles metadata
valid_instances <- read.csv("~/Desktop/endometriosis/code/cmap data/cmap_valid_instances.csv", stringsAsFactors = F)
#keep valid (concordant) profiles / drugs listed in DrugBank
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by="id")
cmap_experiments_valid <- cmap_experiments_valid[cmap_experiments_valid$valid == 1 & cmap_experiments_valid$DrugBank.ID != "NULL", ]



files <- c('unstratified','by stage/InII','by stage/IIInIV','by phase/PE','by phase/ESE','by phase/MSE')

column_name <- c('unstratified','InII','IIInIV','PE','ESE','MSE')

drug_name <- "fenoprofen"
significant <- TRUE

for (number in c(1,2,3,4,5,6)){
  file <- files[number]
  load(paste("~/Desktop/endometriosis/code/",file,"/results.RData", sep = ""))
  if (significant == TRUE){
    
    dz_sig <- results[[2]]
    
  } else {
    
    dz_sig <- read.csv(paste("~/Desktop/endometriosis/code/",file,"/rawdata.csv", sep = ""))
    colnames(dz_sig)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
    dz_sig$GeneID <- gsub("_at", "", paste(dz_sig$GeneID)) 
  }
  
  dz_sig_6 <- dz_sig[dz_sig$GeneID %in% gene_ids_all$GeneID,]
  #print(paste(column_name[number], ": ", nrow(dz_sig_6)))
  
  if (number == 1) { ### get the drug signature for unstratified
    drug_preds <- results[[1]]
  

    #keep drugs listed in DrugBank
    drug_instances_all <- merge(drug_preds, cmap_experiments_drug, by.x="exp_id", by.y="id")
    
    #We can inspect the distribution of reversal scores
    #hist(drug_instances_all$cmap_score, breaks = 10)
    
    #Apply thresholds for significant drug candidates: here, we apply FDR < 0.05 and keep only the reversed profiles (cmap_score < 0) 
    drug_instances <- subset(drug_instances_all, q < 0.0001 & cmap_score < 0)
    drug_instances[str_detect(drug_instances$name,drug_name), ] ## select rows that contain drug 
    
    
    #Since drugs in cmap have been tested multiple times, we keep the most negative score to be as inclusive as possible
    #Alternatively, you could aggregate the scores in a different manner (e.g. averages, or based on metadata)
    #drug_instances <- drug_instances %>% 
    #  group_by(name) %>% 
    #  dplyr::slice(which.min(cmap_score))
    drug_instance <- drug_instances[which.min(drug_instances$cmap_score),]
    
    #drug_instances <- drug_instances[order(drug_instances$cmap_score), ]
    drug_instance_id <- c(drug_instance$exp_id) #+ 1 #the first column is the gene id
    
    ##print(paste(column_name[number], "", drug_instance_id, drug_instance$cmap_score))
    
    drug_signature <- cmap_signatures[,c(1, drug_instance_id)] #the first column V1 is the gene id
    
    drug_dz_signature <- merge(drug_signature, dz_sig_6[, c("GeneID", "log2FoldChange")], by.x="V1",by.y = "GeneID") ## merge dz sig w/ drug sig
    names(drug_dz_signature)[names(drug_dz_signature) == "V1"] <- "GeneID"
    
  } else {
    
    drug_dz_signature <- merge(drug_dz_signature, dz_sig_6[, c("GeneID", "log2FoldChange")], by.x="GeneID",by.y = "GeneID") ## merge dz sig w/ drug sig
  }
  names(drug_dz_signature)[names(drug_dz_signature) == "log2FoldChange"] <- column_name[number] ## rename column "log2FoldChange"
}
drug_dz_signature[,2] <- -drug_dz_signature[,2] # higher rank corresponds to more overexpressed, so we need to reverse order of disease sig
#write.csv(drug_instances, "~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")



# #Convert disease and drug values to ranks from 1:numgenes. ie, uses RANK instead of LOG FOLD CHANGE values
# for (i in 2:ncol(drug_dz_signature)){
#   drug_dz_signature[,i] <- rank(drug_dz_signature[,i] )
# }

drug_dz_signature <- drug_dz_signature[order(drug_dz_signature[,2], decreasing = TRUE),] #order by drug expression
#drug_dz_signature <- drug_dz_signature[order(drug_dz_signature$value),] ## TO - order reversal score by endo signature

gene_ids <- drug_dz_signature[,1]
names(drug_dz_signature)[names(drug_dz_signature) == colnames(drug_dz_signature)[2]] <- drug_name  ## renaming 2nd column w/ name of drug

if (significant == TRUE ){
  write.csv(drug_dz_signature, paste("~/Desktop/endometriosis/code/unstratified/drug_dz_signature_",drug_name,"_significant.csv"))
} else {
  write.csv(drug_dz_signature, paste("~/Desktop/endometriosis/code/unstratified/drug_dz_signature_",drug_name,".csv"))
}


#load("~/Desktop/drugs.csv")  #pipeline results
ncols <- ncol(drug_dz_signature)-1
column_name_labels <- c("Unstratified", "Stage 1/2", "Stage 3/4", "PE", "ESE", "MSE")

## if want to use purple scheme
#my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = nrow(drug_dz_signature))
my_palette <- colorRampPalette(c("blue4", "#FFFFFF", "#EE0000"))(n = nrow(drug_dz_signature)) 
##my_palette <- bluered(3)

## USE THIS CODE TO CREATE HEATMAP. For legend, note: for drugs, the values are rankings, not log fold change. so the colors don't represent up or down regulation, per se. from Brian's PTB paper: "(A) Differential gene expression heatmap of sPTB meta-analysis and 10 computationally identified drugs in pregnancy categories A or B. Each row corresponds to a gene (sorted top to bottom from most downregulated to most upregulated in sPTB relative to term births). A rank-based coloring scheme was used. The sPTB meta-analysis differential gene expression signature ranked the 115 downregulated genes (blue) and the 44 upregulated genes (red) separately. The 10-drug gene expression profiles were ordered from left to right by reversal score (most negative to least negative), with all 159 genes ranked from 1–159 (blue-red). Bluer color corresponds to more downregulated genes, and redder color corresponds to more upregulated genes. Bolded drugs (metformin, folic acid, clotrimazole, and progesterone) have been observed in past studies to have some efficacy in the prevention of PTB. (B) Drug-protein interactions for the 10 drug hits according to DrugBank."

col_name_labels <- c("Fenoprofen", "Unstratified", "Stage 1/2", "Stage 3/4", "PE", "ESE", "MSE") 
#layout(matrix(1))

heatmap(as.matrix(drug_dz_signature[,2:ncol(drug_dz_signature)]), 
        Rowv=NA,Colv=NA,
        margins = c(5,10),
        col=my_palette, 
        scale="column",
        labCol = "",
        labRow = "",
        add.expr = text(x = seq_along(col_name_labels), y = -2, srt = 0,
                        labels = col_name_labels, xpd = TRUE))

legend(x="right", 
       cex=0.8,
       legend=c("downregulated", "upregulated"),fill=c("blue4", "#EE0000"))

pdf(("~/Desktop/endometriosis/code/unstratified/heatmap_cmap_hits_unstratified_20230104.pdf"), width = 12, height = 15)
heatmap(as.matrix(drug_dz_signature[,2:ncol(drug_dz_signature)]), 
        Rowv=NA,Colv=NA,
        margins = c(5,10),
        col=my_palette, 
        scale="column",
        labCol = "",
        labRow = "",
        add.expr = text(x = seq_along(col_name_labels), y = -1, srt = 0,
                        labels = col_name_labels, xpd = TRUE))

legend(x="right", 
       cex=0.7,
       legend=c("upregulated","downregulated"),fill=c("#EE0000","blue4"))
dev.off()

### OLD CODE BELOW
#FIGURE: endo sig + top 24 hits from cmap, using a red/blue color scheme
pdf(("~/Desktop/endometriosis/code/unstratified/heatmap_cmap_hits_unstratified_20221227.pdf"), width = 12, height = 15)
layout(matrix(1))
par(mar=c(10, 4, 1, 0.5))
colPal <- redblue(100)
image(t(drug_dz_signature[,2:nol(drug_dz_signature)]), col= colPal,   axes=F, srt=45)
axis(1,  at=seq(0,1,length.out= ncols ), labels= F)
axis(2,  at=seq(0,1,length.out= length (gene_ids) ), labels= F)
text(x = seq(0,1,length.out=ncols), c(-0.015),
     labels = c(drug_name, column_name_labels), srt = 45, pos=2, offset=-0.2, xpd = TRUE, cex=1.8,
     col = "black")
dev.off()

## heatmap fenoprofen + signatures
layout(matrix(1))
par(mar=c(2, 5, 2, 1))
#colPal <- redblue(3)
image(t(drug_dz_signature[,2:ncol(drug_dz_signature)]), col= my_palette, axes=F, srt=45)
axis(1,  at=seq(0,1,length.out= ncols), labels= F) #labels= T
axis(2,  at=seq(0,1,length.out= length (gene_ids) ), labels= F) #labels= T
text(x = seq(0,1,length.out=ncols), c(-0.015),
     labels = c(str_to_title(drug_name), column_name_labels), srt = 315, pos=4, offset=-0.2, xpd = TRUE, cex=1.2,
     col = "black")

## heatmap just signatures
layout(matrix(1))
par(mar=c(2, 5, 2, 10))
#colPal <- bluered(3)
image(t(drug_dz_signature[,3:ncol(drug_dz_signature)]), col= my_palette, axes=F, srt=45)
axis(1,  at=seq(0,1,length.out= ncols-1), labels= F) #labels= T
axis(2,  at=seq(0,1,length.out= length (gene_ids) ), labels= F) #labels= T
text(x = seq(0,1,length.out=ncols-1), c(-0.015),
     labels = c(column_name_labels), srt = 315, pos=4, offset=-0.2, xpd = TRUE, cex=1.2,
     col = "black")
legend(x="right", legend=c("downregulated", "upregulated"),fill=c("blue4", "#EE0000"))

## heatmap just fenoprofen
layout(matrix(1))
par(mar=c(2, 5, 2, 1), xpd = TRUE)
colPal <- bluered(3)
image(t(drug_dz_signature[,2]), col= my_palette, axes=F, srt=45)
axis(1,  at=seq(0,1,length.out= 1), labels= F) #labels= T
axis(2,  at=seq(0,1,length.out= length (gene_ids) ), labels= F) #labels= T
text(x = seq(0,1,length.out=1), c(-0.015),
     labels = str_to_title(drug_name), srt = 315, pos=4, offset=-0.2, xpd = TRUE, cex=1.2,
     col = "black")


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