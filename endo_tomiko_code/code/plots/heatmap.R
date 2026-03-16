library(pheatmap)
library(gplots)
library(ggplot2)
library(RColorBrewer)
library(AnnotationDbi)
library(reshape2)
library(pheatmap)
library(tidyverse)
library(dplyr)

#importing the data and cleaning it up
InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/drug_instances_IIInIV.csv")
PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/drug_instances_MSE.csv")
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")

unstratified <- dplyr::select(unstratified, name, cmap_score)
InII <- dplyr::select(InII, name, cmap_score)
IIInIV <- dplyr::select(IIInIV, name, cmap_score)
PE <- dplyr::select(PE, name, cmap_score)
ESE <- dplyr::select(ESE, name, cmap_score)
MSE <- dplyr::select(MSE, name, cmap_score)


unstratified <- unstratified[1:20,]
InII <- InII[InII$name %in% unstratified$name,]
IIInIV <- IIInIV[IIInIV$name %in% unstratified$name,]
PE <- PE[PE$name %in% unstratified$name,]
ESE <- ESE[ESE$name %in% unstratified$name,]
MSE <- MSE[MSE$name %in% unstratified$name,]



colnames(unstratified)[2] <- "unstratified"
colnames(InII)[2] <- "InII"
colnames(IIInIV)[2] <- "IIInIV"
colnames(PE)[2] <- "PE"
colnames(ESE)[2] <- "ESE"
colnames(MSE)[2] <- "MSE"



colname <- list(unstratified, InII, IIInIV, PE, ESE, MSE) ## (TO)
#putting together the data frame, cleaning it up, and converting it into a matrix
df <- Reduce(function(x,y) merge(x = x, y = y, by = "name", all.x = TRUE), 
       colname) ## (TO)

row.names(df) <- df$name
df <- df[,2:7]
df[is.na(df)] <- 0
#rowname <-  ## (TO)


sort.data.frame <- function(x, decreasing=FALSE, by=1, ... ){
  f <- function(...) order(...,decreasing=decreasing)
  i <- do.call(f,x[by])
  x[i,,drop=FALSE]
}

rescale <- function(x) -(x-max(x))/(max(x) - min(x)) * 100
dfr <- rescale(df)
dfr <- sort(dfr, by="unstratified", decreasing = TRUE)
#rowname <- row.names(dfr) ## (TO)

write.csv(dfr,"~/Desktop/endometriosis/dfr.csv")


matrix <- data.matrix(dfr)

#my_palette <- colorRampPalette(c("aliceblue", "lightblue4", "black"))(n = 299)
my_palette <- colorRampPalette(c("#EEEEEE", "darkorchid3", "#111111"))(n = 299)

## (TO)


#ggplot(dfr, aes(x = rowname, y = colname, fill = value)) +
#  geom_tile()
pdf(("~/Desktop/endometriosis/plots/heatmaps_by_signature_top20.pdf"), width = 9, height = 7)

## 1000 x 700
heatmap.2(matrix,
          #cellnote = matrix,  # same data set for cell labels
          main = "Reversal Scores for Top 20 Drug Candidates\nAcross All Endometriosis Signatures", # heat map title
          notecol="black",      # change font color of cell labels to black
          density.info="none",  # turns off density plot inside color legend
          trace="none",         # turns off trace lines inside the heat map
          margins =c(5,15),     # widens margins around plot
          col=my_palette,       # use on color palette defined earlier
          dendrogram="none",     # only draw a row dendrogram
          cexRow = 1.4, ##1.7    # size of Row font
          cexCol = 1.4,         # size of Col font
          lmat = rbind(c(0,3),c(4,1),c(0,2)), # position of color key / legend 
          lhei = c(1.5,3,1), #https://stackoverflow.com/questions/15351575/moving-color-key-in-r-heatmap-2-function-of-gplots-package
          lwid =  c(1.5,3),
          Colv=FALSE,
          Rowv=FALSE,            # turn off column clustering
          key=TRUE,              # show color legend, T or F
          
          srtCol = 0,             # angle of row labels, in degrees from horizontal
          adjCol = 0.5,
          key.title=NA,
          key.xlab="",
          keysize=0.25,
          key.xtickfun=function() {
            trace="none"
            cex <- par("cex")*par("cex.axis")
            #side <- 1 #side: on which side of the plot (1=bottom, 2=left, 3=top, 4=right).
            line <- 0
            col <- par("col.axis")
            font <- par("font.axis")
            mtext("No Reversal\n Effect (reversal\nscore > 0, or\nq-value > 0.0001)", side=1, at=0.5, adj=0.5, #
                  line=line, cex=cex, col=col, font=font, padj=1)
            mtext("Maximum Reversal\n Effect (reversal\nscore <= 0)", side=3, at=0.5, adj=0.5, #1 ≤ 
                  line=line, cex=cex, col=col, font=font, padj=-0.1)
            return(list(labels=FALSE, tick=FALSE))
          }
)

dev.off()

