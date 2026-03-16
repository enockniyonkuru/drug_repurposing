load('~/Desktop/endometriosis/code/cmap data/cmap_signatures.RData')
gene_list <- subset(cmap_signatures,select=1)
cmap_signatures <- cmap_signatures[,2:ncol(cmap_signatures)] 

print("Significant Genes table")

# Dataset: Unstratified 
dz_signature <- read.csv("~/Desktop/endometriosis/code/unstratified/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
gene_ids_u <- dz_signature['GeneID']

dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap

dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]

print(paste("unstratified, ", nrow(dz_signature), "genes"))
#gene_ids_u <- dz_signature['GeneID']

# Dataset: InII 
dz_signature <- read.csv("~/Desktop/endometriosis/code/by stage/InII/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
gene_ids_InII <- dz_signature['GeneID']
dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap

dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]

print(paste("InII, ", nrow(dz_signature), "genes"))
#gene_ids_InII <- dz_signature['GeneID']

# Dataset: IIInIV 
dataset <- "endo"
dz_signature <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
gene_ids_IIInIV <- dz_signature['GeneID']
dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap


dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]

print(paste("IIInIV, ", nrow(dz_signature), "genes"))
#gene_ids_IIInIV <- dz_signature['GeneID']

# Dataset: PE 
dataset <- "endo"
dz_signature <- read.csv("~/Desktop/endometriosis/code/by phase/PE/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
gene_ids_p <- dz_signature['GeneID']
dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap

dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]

print(paste("PE, ", nrow(dz_signature), "genes"))
#gene_ids_p <- dz_signature['GeneID']

# Dataset: ESE 
dataset <- "endo"
dz_signature <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
gene_ids_e <- dz_signature['GeneID']
dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap

dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]

print(paste("ESE, ", nrow(dz_signature), "genes"))
#gene_ids_e <- dz_signature['GeneID']

# Dataset: MSE
dataset <- "endo"
dz_signature <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/rawdata.csv")
colnames(dz_signature)[c(1,2)] <- c("GeneID","log2FoldChange") #Relabel columns: estimate is log2FC
dz_signature$GeneID <- gsub("_at", "", paste(dz_signature$GeneID))
gene_ids_m <- dz_signature['GeneID']
dz_signature <- dz_signature[which(dz_signature$GeneID %in% gene_list$V1),] # keep genes in cmap

dz_signature <- dz_signature[which(dz_signature$adj.P.Val < 0.05),]
dz_signature <- dz_signature[which(abs(dz_signature$log2FoldChange) > 1.1),]
dz_signature <- dz_signature[order(dz_signature$log2FoldChange),]

print(paste("MSE, ", nrow(dz_signature), "genes"))
#gene_ids_m <- dz_signature['GeneID']

gene_ids_all <- rbind(gene_ids_u, gene_ids_InII, gene_ids_IIInIV, gene_ids_p, gene_ids_e, gene_ids_m)
gene_ids_all <- as.data.frame(table(gene_ids_all)) ## determines the frequency (1 - 6) of each gene in column 'Freq'
gene_ids_all <- gene_ids_all[gene_ids_all$Freq == 6,] ## nrow 106 if only significant genes, #308 if any gene

nrow(gene_ids_all)

write.csv(gene_ids_all, "~/Desktop/endometriosis/code/gene_ids_all.csv")
