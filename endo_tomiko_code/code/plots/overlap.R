if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("gespeR")

#counts by stage

InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/drug_instancesInII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/drug_instancesIIInIV.csv")
PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/drug_instances_MSE.csv")
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")

PE$name
intersect <- Reduce(intersect, list(InII$name,IIInIV$name,PE$name,ESE$name,MSE$name,unstratified$name))

