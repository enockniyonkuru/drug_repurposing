library(UpSetR)
library(dplyr)


# Import differential gene expression data for each endometriosis signature

unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/rawdata.csv")[,1:2,drop=FALSE]
InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/rawdata.csv")[,1:2,drop=FALSE]
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/rawdata.csv")[,1:2,drop=FALSE]
PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/rawdata.csv")[,1:2,drop=FALSE]
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/rawdata.csv")[,1:2,drop=FALSE]
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/rawdata.csv")[,1:2,drop=FALSE]


unstratified_upregulated <- unlist(filter(unstratified, unstratified$logFC >= 0)[,1,drop=FALSE])
InII_upregulated <- unlist(filter(InII, InII$logFC >= 0)[,1,drop=FALSE])
IIInIV_upregulated <- unlist(filter(IIInIV, IIInIV$logFC >= 0)[,1,drop=FALSE])
PE_upregulated <- unlist(filter(PE, PE$logFC >= 0)[,1,drop=FALSE])
ESE_upregulated <- unlist(filter(ESE, ESE$logFC >= 0)[,1,drop=FALSE])
MSE_upregulated <- unlist(filter(MSE, MSE$logFC >= 0)[,1,drop=FALSE])

unstratified_downregulated <- unlist(filter(unstratified, unstratified$logFC < 0)[,1,drop=FALSE])
InII_downregulated <- unlist(filter(InII, InII$logFC < 0)[,1,drop=FALSE])
IIInIV_downregulated <- unlist(filter(IIInIV, IIInIV$logFC < 0)[,1,drop=FALSE])
PE_downregulated <- unlist(filter(PE, PE$logFC < 0)[,1,drop=FALSE])
ESE_downregulated <- unlist(filter(ESE, ESE$logFC < 0)[,1,drop=FALSE])
MSE_downregulated <- unlist(filter(MSE, MSE$logFC < 0)[,1,drop=FALSE])


unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/rawdata.csv")


# Identify overlaps

data_upregulated <- fromList(list(Unstratified = unstratified_upregulated,
             PE = PE_upregulated,
             ESE = ESE_upregulated,
             MSE = MSE_upregulated,
             'Stages I-II' = InII_upregulated,
             'Stages III-IV' = IIInIV_upregulated))

data_downregulated <- fromList(list(Unstratified = unstratified_downregulated,
                                  PE = PE_downregulated,
                                  ESE = ESE_downregulated,
                                  MSE = MSE_downregulated,
                                  'Stages I-II' = InII_downregulated,
                                  'Stages III-IV' = IIInIV_downregulated))

# Create UpSet Plots
#png(file="~/Desktop/endometriosis/plots/upset_upreg.png",
#    width=650, height=500)
pdf(file="~/Desktop/endometriosis/plots/upset_upreg.pdf")
par(las = 2, mar = c(10, 3, 1, 1)) 
upset(
  data = data_upregulated,
  order.by = "freq", nsets = 50, nintersects = 9,
  point.size = 7, line.size = 2,
  text.scale = 2,
  mainbar.y.max = 400, ## adding to make up and down reg genes upset plot y-axes align
)
dev.off()

print(paste("Upregulated Genes\n",
      nrow(data_upregulated)," total upregulated genes,\n",
      "XXXX overlap across all six signatures" ))

#png(file="~/Desktop/endometriosis/plots/upset_downreg.png",
#    width=650, height=500)
pdf(file="~/Desktop/endometriosis/plots/upset_downreg.pdf")
par(las = 2, mar = c(10, 3, 1, 1)) 
upset(
  data = data_downregulated,
  order.by = "freq", nsets = 50, nintersects = 9,
  point.size = 7, line.size = 2,
  text.scale = 2,
  mainbar.y.max = 400, ## adding to make up and down reg genes upset plot y-axes align

)
dev.off()

print(paste("Downregulated Genes\n",
                     nrow(data_downregulated)," total upregulated genes,\n",
                     "XXXX overlap across all six signatures" ))
