library(fgsea)
library(pheatmap)

if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("rhdf5") ## Packages which are only available in source form, and may need compilation of C/C++/Fortran: ‘Rhdf5lib’ ‘rhdf5filters’ ‘rhdf5’
BiocManager::install("ExperimentHub") ##Package which is only available in source form, and may need compilation of C/C++/Fortran: ‘AnnotationHub’

library("rhdf5")
library("ExperimentHub") 
library("dplyr")



#READING IN CMAP DATA

eh <- ExperimentHub()
query(eh, c("signatureSearchData", "cmap"))

## run this line by itself (installation process)
cmap_path <- eh[["EH3223"]]

rhdf5::h5ls(cmap_path) #downloaded as HDF5 file

cmap_lfc <- h5read(file = cmap_path, 
                   name = "assay")
cmap_rownames <- h5read(file = cmap_path, 
                        name = "rownames")

cmap_colnames <- h5read(file = cmap_path, 
                        name = "colnames")

cmap_lfc_sig <- data.frame(cmap_lfc) #convert to dataframe (12403 rows by 3478 columns)
rownames(cmap_lfc_sig) <- cmap_rownames #change rownames
colnames(cmap_lfc_sig) <- cmap_colnames
colnames(cmap_lfc_sig) <- gsub("_.*","",colnames(cmap_lfc_sig))
colnames(cmap_lfc_sig) <- gsub(".*-","",colnames(cmap_lfc_sig))
cmap_lfc_sig <- cmap_lfc_sig[, !duplicated(colnames(cmap_lfc_sig))]




### perform GSEA for every group of interest #####

pathways=gmtPathways("~/Desktop/endometriosis/code/plots/h.all.v7.2.entrez.gmt") #you can download the hallmark gene sets (or whatever pathways you're interested in) from here: https://www.gsea-msigdb.org/gsea/msigdb/index.jsp
pathway_heatmap_df <-  data.frame(pathway = names(pathways)) 
pathway_heatmap_df$pathway <- gsub("HALLMARK_", "",paste(pathway_heatmap_df$pathway))

##### ##### ##### ##### ##### ##### #####

## (TO) getting names / 'ids' of top 20 drugs
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv") ## (TO)
unstratified_top20 <- unstratified[1:20,] #gets top 20 rows ## (TO)
top20name <- unstratified_top20[,"name",drop=FALSE] ## (TO)
top20_vector <- dplyr::pull(top20name, name) ## (TO)

#ids <- as.vector(ids$name) ### (TO) Where is 'ids' ? 
#cmap_lfc_sig <- cmap_lfc_sig[,colnames(cmap_lfc_sig) %in% ids] ### omit (TO) 
cmap_lfc_sig <- cmap_lfc_sig[,colnames(cmap_lfc_sig) %in% top20_vector]

#FOR DISEASE SIG

DE_res <- read.csv("~/Desktop/endometriosis/code/unstratified/rawdata.csv")
DE_res$X <- gsub("_at", "", paste(DE_res$X))
rownames(DE_res) <- DE_res$X
DE_res$X <- NULL

DE_res <- DE_res[order(DE_res$logFC, decreasing = F),]

ranks <- data.frame(DE_res$logFC, as.character(rownames(DE_res))) # generate ranks dataframe with logFC and gene names
colnames(ranks) <- c("metric", "gene_id")
ranks <- setNames(ranks$metric, ranks$gene_id)
fgseaRes <- fgsea(pathways, ranks, minSize = 1, maxSize = 5000)
fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]

pathway_heatmap_df$unstratified <- fgseaRes$NES



DE_res <- read.csv("~/Desktop/endometriosis/code/by stage/InII/rawdata.csv")
DE_res$X <- gsub("_at", "", paste(DE_res$X))
rownames(DE_res) <- DE_res$X
DE_res$X <- NULL

DE_res <- DE_res[order(DE_res$logFC, decreasing = F),]

ranks <- data.frame(DE_res$logFC, as.character(rownames(DE_res))) # generate ranks dataframe with logFC and gene names
colnames(ranks) <- c("metric", "gene_id")
ranks <- setNames(ranks$metric, ranks$gene_id)
fgseaRes <- fgsea(pathways, ranks, minSize = 1, maxSize = 5000)
fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]

pathway_heatmap_df$InII <- fgseaRes$NES



DE_res <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/rawdata.csv")
DE_res$X <- gsub("_at", "", paste(DE_res$X))
rownames(DE_res) <- DE_res$X
DE_res$X <- NULL

DE_res <- DE_res[order(DE_res$logFC, decreasing = F),]

ranks <- data.frame(DE_res$logFC, as.character(rownames(DE_res))) # generate ranks dataframe with logFC and gene names
colnames(ranks) <- c("metric", "gene_id")
ranks <- setNames(ranks$metric, ranks$gene_id)
fgseaRes <- fgsea(pathways, ranks, minSize = 1, maxSize = 5000)
fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]

pathway_heatmap_df$IIInIV <- fgseaRes$NES



DE_res <- read.csv("~/Desktop/endometriosis/code/by phase/PE/rawdata.csv")
DE_res$X <- gsub("_at", "", paste(DE_res$X))
rownames(DE_res) <- DE_res$X
DE_res$X <- NULL

DE_res <- DE_res[order(DE_res$logFC, decreasing = F),]

ranks <- data.frame(DE_res$logFC, as.character(rownames(DE_res))) # generate ranks dataframe with logFC and gene names
colnames(ranks) <- c("metric", "gene_id")
ranks <- setNames(ranks$metric, ranks$gene_id)
fgseaRes <- fgsea(pathways, ranks, minSize = 1, maxSize = 5000)
fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]

pathway_heatmap_df$PE <- fgseaRes$NES  



DE_res <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/rawdata.csv")
DE_res$X <- gsub("_at", "", paste(DE_res$X))
rownames(DE_res) <- DE_res$X
DE_res$X <- NULL

DE_res <- DE_res[order(DE_res$logFC, decreasing = F),]

ranks <- data.frame(DE_res$logFC, as.character(rownames(DE_res))) # generate ranks dataframe with logFC and gene names
colnames(ranks) <- c("metric", "gene_id")
ranks <- setNames(ranks$metric, ranks$gene_id)
fgseaRes <- fgsea(pathways, ranks, minSize = 1, maxSize = 5000)
fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]

pathway_heatmap_df$ESE <- fgseaRes$NES




DE_res <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/rawdata.csv")
DE_res$X <- gsub("_at", "", paste(DE_res$X))
rownames(DE_res) <- DE_res$X
DE_res$X <- NULL

DE_res <- DE_res[order(DE_res$logFC, decreasing = F),]

ranks <- data.frame(DE_res$logFC, as.character(rownames(DE_res))) # generate ranks dataframe with logFC and gene names
colnames(ranks) <- c("metric", "gene_id")
ranks <- setNames(ranks$metric, ranks$gene_id)
fgseaRes <- fgsea(pathways, ranks, minSize = 1, maxSize = 5000)
fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]

pathway_heatmap_df$MSE <- fgseaRes$NES

#FOR CMAP DATA

col <- as.vector(colnames(cmap_lfc_sig))
                  
#for(i in 1:43) {
for(i in 1:20) { ## (TO)
  ranks <- data.frame(cmap_lfc_sig %>% select(contains(col[i])), as.character(rownames(cmap_lfc_sig))) # generate ranks dataframe with logFC and gene names
  colnames(ranks) <- c("metric", "gene_id")
  ranks <- setNames(ranks$metric, ranks$gene_id)
  fgseaRes <- fgsea(pathways, ranks, minSize=1, maxSize=5000)
  fgseaRes <- fgseaRes[match(names(pathways), fgseaRes$pathway),]
  
  pathway_heatmap_df$temp <- fgseaRes$NES
  colnames(pathway_heatmap_df)[colnames(pathway_heatmap_df) == 'temp'] <- col[i]
}

write.csv(pathway_heatmap_df, "~/Desktop/endometriosis/pathway_heatmap_df.csv")



pathway_heatmap_df <- slice(pathway_heatmap_df, 1:(n()-5))

#drugs <- pathway_heatmap_df[,7:45]
diseases <- pathway_heatmap_df[,2:7] ## (TO)
drugs <- pathway_heatmap_df[,8:27] ## (TO)


### make heatmap
paletteLength <- 100
my_palette <- colorRampPalette(c("blue", "white", "red"))(n = paletteLength)
myBreaks <- c(seq(-1, 0, length.out=ceiling(paletteLength/2) + 1), 
              seq(1/paletteLength, 1, length.out=floor(paletteLength/2)))
pheatmap(diseases, cluster_cols = F, cluster_rows = F, color = my_palette, breaks = myBreaks, border_color = "white", cellwidth = 12, fontsize_row = 8, fontsize_col = 8)
