# LOAD DATA
# unstratified
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")
names(unstratified)[names(unstratified) == "cmap_score"] <- "unstratified_reversal"

unstratified$X <- NULL
unstratified$subset_comparison_id <- NULL
unstratified$exp_id <- NULL
unstratified$concentration <- NULL
unstratified$array_platform <- NULL
unstratified$cell_line <- NULL
unstratified$vendor <- NULL
unstratified$vendor_catalog_id <- NULL
unstratified$vendor_catalog_name <- NULL
unstratified$cas_number <- NULL
unstratified$drug_concept_id <- NULL
unstratified$vehicle <- NULL

# by stage
InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/drug_instances_IIInIV.csv")
names(InII)[names(InII) == "cmap_score"] <- "InII_reversal"
names(IIInIV)[names(IIInIV) == "cmap_score"] <- "IIInIV_reversal"

InII$X <- NULL
InII$subset_comparison_id <- NULL
InII$exp_id <- NULL
InII$concentration <- NULL
InII$array_platform <- NULL
InII$cell_line <- NULL
InII$vendor <- NULL
InII$vendor_catalog_id <- NULL
InII$vendor_catalog_name <- NULL
InII$cas_number <- NULL
InII$drug_concept_id <- NULL
InII$vehicle <- NULL

IIInIV$X <- NULL
IIInIV$subset_comparison_id <- NULL
IIInIV$exp_id <- NULL
IIInIV$concentration <- NULL
IIInIV$array_platform <- NULL
IIInIV$cell_line <- NULL
IIInIV$vendor <- NULL
IIInIV$vendor_catalog_id <- NULL
IIInIV$vendor_catalog_name <- NULL
IIInIV$cas_number <- NULL
IIInIV$drug_concept_id <- NULL
IIInIV$vehicle <- NULL


# by phase 
PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/drug_instances_MSE.csv")
names(PE)[names(PE) == "cmap_score"] <- "PE_reversal"
names(ESE)[names(ESE) == "cmap_score"] <- "ESE_reversal"
names(MSE)[names(MSE) == "cmap_score"] <- "MSE_reversal"

PE$X <- NULL
PE$subset_comparison_id <- NULL
PE$exp_id <- NULL
PE$concentration <- NULL
PE$array_platform <- NULL
PE$cell_line <- NULL
PE$vendor <- NULL
PE$vendor_catalog_id <- NULL
PE$vendor_catalog_name <- NULL
PE$cas_number <- NULL
PE$drug_concept_id <- NULL
PE$vehicle <- NULL

ESE$X <- NULL
ESE$subset_comparison_id <- NULL
ESE$exp_id <- NULL
ESE$concentration <- NULL
ESE$array_platform <- NULL
ESE$cell_line <- NULL
ESE$vendor <- NULL
ESE$vendor_catalog_id <- NULL
ESE$vendor_catalog_name <- NULL
ESE$cas_number <- NULL
ESE$drug_concept_id <- NULL
ESE$vehicle <- NULL

MSE$X <- NULL
MSE$subset_comparison_id <- NULL
MSE$exp_id <- NULL
MSE$concentration <- NULL
MSE$array_platform <- NULL
MSE$cell_line <- NULL
MSE$vendor <- NULL
MSE$vendor_catalog_id <- NULL
MSE$vendor_catalog_name <- NULL
MSE$cas_number <- NULL
MSE$drug_concept_id <- NULL
MSE$vehicle <- NULL




criteria = c( 
              "name", "DrugBank.ID")

library(dplyr)

merge <- Reduce(function(x, y) merge(x, y, all = TRUE), list(unstratified, InII, IIInIV, PE, ESE, MSE))
m <- merge[order(merge$unstratified_reversal), ]


write.csv(merge, "~/Desktop/endometriosis/drugs.csv")


data <- read.csv("~/Desktop/endometriosis/drugs.csv")
data$ID <- seq.int(nrow(data))
data$Drug.Class <- NULL
data$Notes <- NULL
data$ID <- seq.int(nrow(data))

load("~/Desktop/endometriosis/code/plots/Drugbanks_ATC.RData")

capFirst <- function(s) {
  paste(toupper(substring(s, 1, 1)), substring(s, 2), sep = "")
}

data$name <- capFirst(data$name)
data[2, 5] <- "Flumethasone"


#only keeping rows in drug repurposing data
drugbank <- db_drugs_atc[db_drugs_atc$name %in% data$name,]
drugbank <- select(drugbank, name, desc_4, ATC_code_5, desc_2)
drugbank <- drugbank[!duplicated(drugbank$name), ]

data <- merge(data, drugbank, by.x = "name", by.y = "name", all.x = TRUE)

data <- data[order(data$ID), ]

formatThis <- function(s) {
  paste(toupper(substring(s, 1, 1)), tolower(substring(s, 2)), sep = "")
}

data$desc_2 <- formatThis(data$desc_2)

library(dplyr)
library(stringr)
library(tidyverse)

data$desc_2 <- data$desc_2 %>%
  str_replace_all("NANA", " ")

data$desc_4 <- data$desc_4 %>%
  str_replace_all("NA", " ")

data$ATC_code_5 <- data$ATC_code_5 %>%
  str_replace_all("NA", " ")

data$X <- NULL
data$p <- NULL
data$q <- NULL
data$analysis_id <- NULL
data$duration <- NULL
data$valid <- NULL
rownames(data) <- data$ID
data$ID <- NULL

names(data)[names(data) == "desc_4"] <- "Drug description"
names(data)[names(data) == "desc_2"] <- "Drug class"
names(data)[names(data) == "ATC_code_5"] <- "ATC Code"


write.csv(data, "~/Desktop/endometriosis/atc.csv")


colnames(InII)

