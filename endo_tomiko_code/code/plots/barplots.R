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
drugs <- distinct(drugs)

load("~/Desktop/endometriosis/code/plots/Drugbanks_ATC.RData")


#only keeping rows in drug repurposing data
drugbank <- db_drugs_atc[db_drugs_atc$primary_key %in% drugs$DrugBank.ID,]
sex <- drugbank[(drugbank$ATC_code_1=="G"),]


library(dplyr)
#counts <- as.data.frame(count(drugbank, ATC_code_2)) ## (TO)
#counts <- counts[order(counts$n), ] ## (TO)
#counts <- counts[dim(counts)[1]:1,] ## (TO)

counts <- as.data.frame(count(drugbank, desc_2)) ## (TO)
counts <- counts[order(counts$n), ] ## (TO)
counts <- counts[dim(counts)[1]:1,] ## (TO)

library("stringr") ## (TO)
counts$desc_2 <- str_to_sentence(counts$desc_2) ## (TO) changes text from ALL CAPS to Sentence case
write.csv(counts, "~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_for_barplot.csv", row.names = FALSE) ## (TO)

#write.csv(counts,"~/Desktop/endometriosis/counts.csv", row.names = FALSE) ## (TO)


countsofcounts <- as.data.frame(count(counts, n), name = NUMBER)

###data <- read.csv("~/Desktop/endometriosis/code/plots/barplot.csv") ## (TO) where does this file come from??

data <- read.csv("~/Desktop/endometriosis/code/plots/counts_atc_drug_desc_for_barplot.csv")
library(forcats)

# data %>%
#   mutate(Drug.Class = fct_reorder(Drug.Class, Count)) %>%
#   ggplot( aes(x=Drug.Class, y=Count)) +
#   geom_bar(stat="identity") +
#   coord_flip() +
#   xlab("") +
#   ylab("") +
#   theme_classic(base_size = 30)
# 
# ggplot(data, aes(x=reorder(Drug.Class, value), Count)) + 
#     geom_bar(stat = "identity") +
#     theme_blank()

## (TO) makes horizontally oriented bar plot with counts (on x axis) of drug class descriptions (on y axis) USE THIS ONE 
#data %>%
head(data,20) %>%
  mutate(desc_2 = fct_reorder(desc_2, n)) %>% ## (TO)
  ggplot( aes(x=desc_2, y=n)) + ## (TO)
  geom_bar(stat="identity") + 
  coord_flip() + 
  xlab("") +
  ylab("") +
  theme_classic(base_size = 30)

## below code block does not work
ggplot(data, aes( x=n, y=reorder(desc_2, desc(n)))) + ## reorder desc_2 following descending value of column n
  geom_bar(stat = "identity", aes(y=desc_2)) +
  theme_blank()

# all drugs
par(las=1)
par(mar = c(5, 5, 2, 1))
par(cex.names = 0.5)
#my_colors <- c("lightblue", "mistyrose", "lightcyan", "lavender", "cornsilk")
counts <- data

## wrong order, no labels
barplot2(counts$n, main="", col = "darkorchid4", border=NA, horiz=TRUE,
        xlab="Drug Counts")

counts$desc_2 <- factor(counts$desc_2, levels = counts$desc_2)
ggplot(counts, aes(desc_2, n, fill = desc_2)) + coord_flip()
#######################

# top 20 drugs
unstratified_top20 <- unstratified[1:20,]
top20name <- unstratified_top20[,8, drop=FALSE]
top20_vector <- dplyr::pull(top20name, name)
#str_sub(top20_vector, 1, 1) <- str_sub(top20_vector, 1, 1) %>% str_to_upper()
db_drugs_atc$name<-str_to_lower(db_drugs_atc$name)
drugbanktop20 <- db_drugs_atc[db_drugs_atc$name %in% top20_vector,]

par(las=1)
par(mar = c(5, 25, 2, 1))
par(cex.names = 0.2)
my_colors <- c("lightblue", "mistyrose", "lightcyan", 
               "lavender", "cornsilk")
counts <- table(drugbanktop20$desc_2)

barplot(counts, main="", col = my_colors, border=NA, horiz=TRUE,
        xlab="Drug Counts", cex.names = 0.8)

# top 20 drugs ## (TO)
top20name <- unstratified_top20[,8, drop=FALSE]
top20_vector <- dplyr::pull(top20name, name)
#str_sub(top20_vector, 1, 1) <- str_sub(top20_vector, 1, 1) %>% str_to_upper()
db_drugs_atc$name<-str_to_lower(db_drugs_atc$name)
drugbanktop20 <- db_drugs_atc[db_drugs_atc$name %in% top20_vector,]

par(las=1)
par(mar = c(5, 25, 2, 1))
par(cex.names = 0.2)
my_colors <- c("lightblue", "mistyrose", "lightcyan", 
               "lavender", "cornsilk")
counts <- table(drugbanktop20$desc_2)

barplot(counts, main="", col = my_colors, border=NA, horiz=TRUE,
        xlab="Drug Counts", cex.names = 0.8)