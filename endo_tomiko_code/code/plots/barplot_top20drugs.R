library(dplyr)
library(forcats)

# LOAD DATA
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/"drug_instances_unstratified.csv)
unstratified_id <- unstratified[,19, drop=FALSE]

InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/drug_instances_IIInIV.csv")

InII_id <- InII[,19, drop=FALSE]
IIInIV_id <- IIInIV[,19,drop=FALSE]

PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/drug_instances_MSE.csv")

PE_id <- PE[,19, drop=FALSE]
ESE_id <- ESE[,19,drop=FALSE]
MSE_id <- MSE[,19,drop=FALSE]


#putting together dataset of all drugs
drugs <- rbind(unstratified_id, InII_id, IIInIV_id, PE_id, ESE_id, MSE_id)
drugs <- distinct(drugs) ## DrugBank.ID column

load("~/Desktop/endometriosis/code/plots/Drugbanks_ATC.RData") #names given to these objects when they were originally saved will be given to them when they are loaded. 


#only keeping rows in drug repurposing data
#drugbank <- db_drugs_atc[db_drugs_atc$primary_key %in% drugs$DrugBank.ID,]
#sex <- drugbank[(drugbank$ATC_code_1=="G"),]
drugs_drugbank <- db_drugs_atc[db_drugs_atc$primary_key %in% drugs$DrugBank.ID,] 
drugs_drugbank <- drugs_drugbank[!duplicated(drugs_drugbank[c("name","desc_2")]),] ## (TO) ## removes duplicate descriptions for each drug



counts <- as.data.frame(count(drugs_drugbank, desc_2)) ## (TO)
counts <- counts[order(counts$n), ] ## (TO)
counts <- counts[dim(counts)[1]:1,] ## (TO)

library("stringr") ## (TO)
counts$desc_2 <- str_to_sentence(counts$desc_2) ## (TO) changes text from ALL CAPS to Sentence case
#write.csv(counts, "~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_for_barplot.csv", row.names = FALSE) ## (TO)

counts <- read.csv("~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_for_barplot.csv")

#write.csv(counts,"~/Desktop/endometriosis/counts.csv", row.names = FALSE) ## (TO)


countsofcounts <- as.data.frame(count(counts, n), name = NUMBER)

data <- read.csv("~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_for_barplot.csv")
#library(forcats)


## (TO) makes horizontally oriented bar plot with counts (on x axis) of drug class descriptions (on y axis) USE THIS ONE 
#data %>%
#head(data,20) %>%
head(counts,20) %>%
  mutate(desc_2 = fct_reorder(desc_2, n,.desc = TRUE)) %>% ## (TO)
  ggplot( aes(x=desc_2, y=n)) + ## (TO)
  geom_bar(stat="identity") + 
  coord_flip() + 
  xlab("") +
  ylab("") +
  theme_classic(base_size = 30)

