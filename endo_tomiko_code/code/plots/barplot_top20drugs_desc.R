#library(dplyr)
library(forcats)

# LOAD DATA
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")
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

## if looking into drugs in ALL 6 signatures
drugs <- as.data.frame(table(drugs)) ## determines the frequency (1 - 6) of each drug
drugs <- drugs[drugs$Freq == 6,]
## if looking into unique drugs 
#drugs <- distinct(drugs) ## DrugBank.ID column

load("~/Desktop/endometriosis/code/plots/Drugbanks_ATC.RData") #names given to these objects when they were originally saved will be given to them when they are loaded. 


#only keeping rows in drug repurposing data
#drugbank <- db_drugs_atc[db_drugs_atc$primary_key %in% drugs$DrugBank.ID,]
#sex <- drugbank[(drugbank$ATC_code_1=="G"),]
drugs_drugbank <- db_drugs_atc[db_drugs_atc$primary_key %in% drugs$DrugBank.ID,] 
drugs_drugbank <- drugs_drugbank[!duplicated(drugs_drugbank[c("name","desc_2")]),] ## (TO) ## removes duplicate descriptions for each drug
#drugs_drugbank <- drugs_drugbank[!duplicated(drugs_drugbank[c("name","desc_3")]),] ## (TO) ## removes duplicate descriptions for each drug

## just top 20 drugs ## (TO) - USE THIS ********
drugs_drugbank_top20 <- drugs_drugbank[drugs_drugbank$primary_key %in% head(unstratified$DrugBank.ID, 20),] ## top 20 for unstratified signature ## (TO)
drugs_drugbank_top20 <- drugs_drugbank_top20[!duplicated(drugs_drugbank_top20[c("name","desc_2")]),] ## (TO) ## removes duplicate descriptions for each drug ## (TO)
drugs_drugbank_top20_ordered <- head(unstratified_id,20) ## (TO)
colnames(drugs_drugbank_top20_ordered) <- "primary_key" ## (TO)
drugs_drugbank_top20_ordered$rank <- rownames(drugs_drugbank_top20_ordered) ## (TO)
drugs_drugbank_top20_ordered <- transform(drugs_drugbank_top20_ordered, rank = as.numeric(rank)) ## (TO)
drugs_drugbank_top20_ordered <- merge(drugs_drugbank_top20_ordered,drugs_drugbank_top20,by="primary_key",all.x=TRUE) ## (TO)
drugs_drugbank_top20_ordered <- drugs_drugbank_top20_ordered[order(drugs_drugbank_top20_ordered$rank),] ## (TO)
drugs_drugbank_top20_ordered <- subset(drugs_drugbank_top20_ordered, select=c("rank","primary_key", "name","desc_4","desc_3","desc_2")) ## (TO)
write.csv(drugs_drugbank_top20_ordered, "~/Desktop/endometriosis/tables/top20_unstratified_atc_drug_desc.csv", row.names = FALSE) ## (TO)

## table of all drugs and their descriptions ## (TO) - OR USE THIS for supplemental table 4 ********
drugs_drugbank_all <- drugs_drugbank[drugs_drugbank$primary_key %in% unstratified$DrugBank.ID,] ## all drugs for unstratified signature ## (TO)
drugs_drugbank_all <- drugs_drugbank_all[!duplicated(drugs_drugbank_all[c("name","desc_2")]),] ## (TO) ## removes duplicate descriptions for each drug ## (TO)
drugs_drugbank_all_ordered <- subset(unstratified, select = c("DrugBank.ID", "name")) ## (TO)
colnames(drugs_drugbank_all_ordered) <- c("primary_key","drug_name") ## (TO)
drugs_drugbank_all_ordered$rank <- rownames(drugs_drugbank_all_ordered) ## (TO)
drugs_drugbank_all_ordered <- transform(drugs_drugbank_all_ordered, rank = as.numeric(rank)) ## (TO)
drugs_drugbank_all_ordered <- merge(drugs_drugbank_all_ordered,drugs_drugbank_all,by="primary_key",all.x=TRUE) ## (TO)
drugs_drugbank_all_ordered <- drugs_drugbank_all_ordered[order(drugs_drugbank_all_ordered$rank),] ## (TO)
#drugs_drugbank_all_ordered <- subset(drugs_drugbank_all_ordered, select=c("rank","primary_key", "name","desc_4","desc_3","desc_2")) ## (TO)
drugs_drugbank_all_ordered <- subset(drugs_drugbank_all_ordered, select=c("rank","primary_key", "drug_name","desc_4","desc_3","desc_2")) ## (TO)
write.csv(drugs_drugbank_all_ordered, "~/Desktop/endometriosis/tables/all_unstratified_atc_drug_desc.csv", row.names = FALSE) ## (TO)


# library(dplyr)
# counts <- as.data.frame(count(drugs_drugbank, desc_2)) ## (TO)
# #counts <- as.data.frame(count(drugs_drugbank, desc_3)) ## (TO)
# counts <- counts[order(counts$n), ] ## (TO)
# counts <- counts[dim(counts)[1]:1,] ## (TO)
# 
# library("stringr") ## (TO)
# counts$desc_2 <- str_to_sentence(counts$desc_2) ## (TO) changes text from ALL CAPS to Sentence case
# #counts$desc_3 <- str_to_sentence(counts$desc_3) ## (TO) changes text from ALL CAPS to Sentence case
# write.csv(counts, "~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_across6_for_barplot.csv", row.names = FALSE) ## (TO)
# 
# #write.csv(counts,"~/Desktop/endometriosis/counts.csv", row.names = FALSE) ## (TO)
# 
# 
# countsofcounts <- as.data.frame(count(counts, n), name = NUMBER)
# 
# #data <- read.csv("~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_for_barplot.csv")
# data <- read.csv("~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_across6_for_barplot.csv")
# library(forcats)
# 
# 
# ## (TO) makes horizontally oriented bar plot with counts (on x axis) of drug class descriptions (on y axis) 
# pdf(file="~/Desktop/endometriosis/plots/barplot_drug_classes.pdf", width=14)
# head(counts,20) %>%
#   mutate(desc_2 = fct_reorder(desc_2, n,.desc = FALSE)) %>% ## (TO)
#   ggplot( aes(x=desc_2, y=n)) + ## (TO)
#   #ggtitle("Counts of Drug Classes") +
#   #theme(plot.title = element_text(hjust = 0.5)) + #to center title
#   geom_bar(stat="identity") + ##, fill="darkorchid"
#   coord_flip() + 
#   xlab("") +
#   ylab("") +
#   theme_classic(base_size = 30)
# dev.off()
# 
# # head(counts,20) %>%
# #   mutate(desc_3 = fct_reorder(desc_3, n,.desc = FALSE)) %>% ## (TO)
# #   ggplot( aes(x=desc_3, y=n)) + ## (TO)
# #   geom_bar(stat="identity") + 
# #   coord_flip() + 
# #   xlab("") +
# #   ylab("") +
# #   theme_classic(base_size = 30)

## adding back the cmap scores to annotated file with drug names and descriptions

file_annot <- read.csv("~/Desktop/endometriosis/tables/Supp_Table_4_all_unstratified_atc_drug_desc_annotated.csv")

unstratified_cmap <- subset(unstratified, select=c("DrugBank.ID", "cmap_score")) 
names(unstratified_cmap)[names(unstratified_cmap) == "DrugBank.ID"] <- "primary_key"
names(unstratified_cmap)[names(unstratified_cmap) == "cmap_score"] <- "cmap_score_unstratified"
file_annot_merged <- merge(x = file_annot, y = unstratified_cmap, by = "primary_key", all.x = TRUE)

InII_cmap <- subset(InII, select=c("DrugBank.ID", "cmap_score")) 
names(InII_cmap)[names(InII_cmap) == "DrugBank.ID"] <- "primary_key"
names(InII_cmap)[names(InII_cmap) == "cmap_score"] <- "cmap_score_I-II"
file_annot_merged <- merge(x = file_annot_merged, y = InII_cmap, by = "primary_key", all.x = TRUE)

IIInIV_cmap <- subset(IIInIV, select=c("DrugBank.ID", "cmap_score")) 
names(IIInIV_cmap)[names(IIInIV_cmap) == "DrugBank.ID"] <- "primary_key"
names(IIInIV_cmap)[names(IIInIV_cmap) == "cmap_score"] <- "cmap_score_III-IV"
file_annot_merged <- merge(x = file_annot_merged, y = IIInIV_cmap, by = "primary_key", all.x = TRUE)

PE_cmap <- subset(PE, select=c("DrugBank.ID", "cmap_score")) 
names(PE_cmap)[names(PE_cmap) == "DrugBank.ID"] <- "primary_key"
names(PE_cmap)[names(PE_cmap) == "cmap_score"] <- "cmap_score_PE"
file_annot_merged <- merge(x = file_annot_merged, y = PE_cmap, by = "primary_key", all.x = TRUE)

ESE_cmap <- subset(ESE, select=c("DrugBank.ID", "cmap_score")) 
names(ESE_cmap)[names(ESE_cmap) == "DrugBank.ID"] <- "primary_key"
names(ESE_cmap)[names(ESE_cmap) == "cmap_score"] <- "cmap_score_ESE"
file_annot_merged <- merge(x = file_annot_merged, y = ESE_cmap, by = "primary_key", all.x = TRUE)

MSE_cmap <- subset(MSE, select=c("DrugBank.ID", "cmap_score")) 
names(MSE_cmap)[names(MSE_cmap) == "DrugBank.ID"] <- "primary_key"
names(MSE_cmap)[names(MSE_cmap) == "cmap_score"] <- "cmap_score_MSE"
file_annot_merged <- merge(x = file_annot_merged, y = MSE_cmap, by = "primary_key", all.x = TRUE)

## reorder rows
file_annot_merged <- file_annot_merged[, c("primary_key", "rank", "drug_name", "cmap_score_unstratified", "cmap_score_I-II", "cmap_score_III-IV", "cmap_score_PE", "cmap_score_ESE", "cmap_score_MSE", "desc_4", "desc_3", "desc_2", "notes", "ref")] # leave the row index blank to keep all rows

file_annot_merged <- (file_annot_merged[order(file_annot_merged$rank, decreasing = FALSE), ])
write.csv(file_annot_merged, "~/Desktop/endometriosis/tables/Supp_Table_4_all_unstratified_atc_drug_desc_annotated_w_cmap_scores.csv")
