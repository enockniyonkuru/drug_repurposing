## upset plot of the # drugs represented in the 6 signatures
library(UpSetR)

# LOAD DATA
# unstratified
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")
#unstratified_name <- unstratified[,8, drop=FALSE] #"name"
unstratified_name <- unstratified[,"name", drop=FALSE]

# by stage
InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/drug_instances_IIInIV.csv")

#InII_name <- InII[,8, drop=FALSE] #"name"
#IIInIV_name <- IIInIV[,8,drop=FALSE]
InII_name <- InII[,"name", drop=FALSE] #8
IIInIV_name <- IIInIV[,"name",drop=FALSE]

# by phase 
PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/drug_instances_MSE.csv")

# PE_name <- PE[,8, drop=FALSE]
# ESE_name <- ESE[,8,drop=FALSE]
# MSE_name <- MSE[,8,drop=FALSE]
PE_name <- PE[,"name", drop=FALSE]
ESE_name <- ESE[,"name",drop=FALSE]
MSE_name <- MSE[,"name",drop=FALSE]

PE <- unlist(PE_name)
unstratified <- unlist(unstratified_name)
ESE <- unlist(ESE_name)
MSE <- unlist(MSE_name)
InII <- unlist(InII_name)
IIInIV <- unlist(IIInIV_name)

list <- list(Unstratified = unstratified,
             PE = PE,
             ESE = ESE,
             MSE = MSE,
             'Stages I-II' = InII,
             'Stages III-IV' = IIInIV)
data <- fromList(list)

#dev.new()
pdf(file="~/Desktop/endometriosis/plots/upset_drugs_20230405.pdf", width=11)
par(las = 2, mar = c(10, 3, 1, 1)) #bottom, left, top, and right.
upset(
  data = fromList(list),
  order.by = "freq", nsets = 50, nintersects = 25,
  point.size = 7, line.size = 2,
  text.scale = 2
  )
dev.off()

## use Illustrator to adjust left side (set size 300 label cut off)
