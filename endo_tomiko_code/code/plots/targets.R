# LOAD DATA
unstratified <- read.csv("~/Desktop/endometriosis/unstratified/drug_instances_unstratified.csv")
unstratified_id <- unstratified[,19, drop=FALSE]

InII <- read.csv("~/Desktop/endometriosis/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/by stage/IIInIV/drug_instances_IIInIV.csv")

InII_id <- InII[,19, drop=FALSE]
IIInIV_id <- IIInIV[,19,drop=FALSE]
 
PE <- read.csv("~/Desktop/endometriosis/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/by phase/MSE/drug_instances_MSE.csv")

PE_id <- PE[,19, drop=FALSE]
ESE_id <- ESE[,19,drop=FALSE]
MSE_id <- MSE[,19,drop=FALSE]


#putting together dataset of all drugs
drugs <- rbind(unstratified_id, InII_id, IIInIV_id, PE_id, ESE_id, MSE_id)
drugs <- distinct(drugs)

protein <- read.csv("~/Desktop/endometriosis/plots/all.csv")
links <- read.csv("~/Desktop/endometriosis/plots/uniprot links.csv")

#only keeping rows in drug repurposing data
links <- links[links$DrugBank.ID %in% drugs$DrugBank.ID,]

#protein <- protein[,3:6,drop=FALSE]
protein <- protein[protein$UniProt.ID %in% links$UniProt.ID,]

df <- merge(links, protein, by.x = "UniProt.ID", by.y = "UniProt.ID")

df <- select(df, Name.x, Gene.Name)
df <- subset(df, Gene.Name!="")
names(df)[names(df) == "Gene.Name"] <- "gene_name"
names(df)[names(df) == "Name.x"] <- "drug_name"

# NOW LET'S DO THIS PROCESS AGAIN FOR THE TOP 20 DRUG HITS! 

unstratified_top20 <- unstratified[1:14,19,drop=FALSE]
PE_top20 <- PE[1:14,19,drop=FALSE]
ESE_top20 <- ESE[1:14,19,drop=FALSE]
MSE_top20 <- MSE[1:14,19,drop=FALSE]
InII_top20 <- InII[1:14,19,drop=FALSE]
IIInIV_top20 <- IIInIV[1:14,19,drop=FALSE]

top20 <- rbind(unstratified_top20, PE_top20, ESE_top20, MSE_top20, InII_top20, IIInIV_top20)
top20 <- distinct(top20)

#only keeping rows in drug repurposing data
linkstop20 <- links[links$DrugBank.ID %in% top20$DrugBank.ID,]

#protein <- protein[,3:6,drop=FALSE]
proteintop20 <- protein[protein$UniProt.ID %in% linkstop20$UniProt.ID,]

dftop20 <- merge(linkstop20, proteintop20, by.x = "UniProt.ID", by.y = "UniProt.ID")

dftop20 <- select(dftop20, Name.x, Gene.Name)
dftop20 <- subset(dftop20, Gene.Name!="")
names(dftop20)[names(dftop20) == "Gene.Name"] <- "gene_name"
names(dftop20)[names(dftop20) == "Name.x"] <- "drug_name"
dftop20 <- distinct(dftop20)

write.csv(dftop20, "~/Desktop/endometriosis/plots/targetstop20.csv")