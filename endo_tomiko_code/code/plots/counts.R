### counts by stage ###
#library(matrixStats)

InII <- read.csv("~/Desktop/endometriosis/code/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/code/by stage/IIInIV/drug_instances_IIInIV.csv")

InII_name <- InII[,8, drop=FALSE]
IIInIV_name <- IIInIV[,8,drop=FALSE]

#intersect(InII_name,IIInIV_name)
#setdiff(InII_name,IIInIV_name) # unique to stage 1/2
#setdiff(IIInIV_name,InII_name) # unique to stage 3/4
nrow(InII)

intersect(InII_name[,1],IIInIV_name[,1])
#Reduce(intersect,list(InII_name[,1], IIInIV_name[,1])) # intersection of stage 1/2 and stage 3/4
setdiff(InII_name[,1],IIInIV_name[,1])
setdiff(IIInIV_name[,1],InII_name[,1])


### counts by phase ### 

PE <- read.csv("~/Desktop/endometriosis/code/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/code/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/code/by phase/MSE/drug_instances_MSE.csv")


PE_name <- PE[,8, drop=FALSE]
ESE_name <- ESE[,8, drop=FALSE]
MSE_name <- MSE[,8, drop=FALSE]

#intersect(PE_name, ESE_name, MSE_name) 

#setdiff(PE_nam, ESE_nam, MSE_name) # unique to PE
#setdiff(ESE_name, PE_name, MSE_name) # unique to ESE
#setdiff(MSE_name, PE_nam, ESE_nam) # unique to MSE

Reduce(intersect,list(PE_name[,1], ESE_name[,1], MSE_name[,1]))

Reduce(setdiff,list(PE_name[,1], ESE_name[,1], MSE_name[,1])) # unique to PE
Reduce(setdiff,list(ESE_name[,1], PE_name[,1], MSE_name[,1])) # unique to ESE
Reduce(setdiff,list(MSE_name[,1], PE_name[,1], ESE_name[,1])) # unique to MSE


### total drug hits ### Table 1 total drug hits
unstratified <- read.csv("~/Desktop/endometriosis/code/unstratified/drug_instances_unstratified.csv")
unstratified_name <- unstratified[,8, drop=FALSE]
print(paste("unstatified: ", nrow(unstratified_name)))
print(paste("InII: ", nrow(InII_name)))
print(paste("IIInIV: ", nrow(IIInIV_name)))
print(paste("PE: ", nrow(PE_name)))
print(paste("ESE: ", nrow(ESE_name)))
print(paste("MSE: ", nrow(MSE_name)))

### drug hits common across all six signatures
common_hits_six <- Reduce(intersect,list(unstratified_name[,1],InII_name[,1],IIInIV_name[,1],PE_name[,1], ESE_name[,1], MSE_name[,1]))
length(common_hits_six)
common_hits_six
write.csv(common_hits_six, "~/Desktop/endometriosis/drug_hits_six_common.csv")

### drug hits unique from all six signatures
unique_hits_six <- Reduce(union,list(unstratified_name[,1],InII_name[,1],IIInIV_name[,1],PE_name[,1], ESE_name[,1], MSE_name[,1]))
length(unique_hits_six)
unique_hits_six
write.csv(unique_hits_six, "~/Desktop/endometriosis/drug_hits_six_unique.csv")

### (TO)
unique_hits_six_cmap_scores <- as.data.frame(unique_hits_six) ## (TO)
colnames(unique_hits_six_cmap_scores) <- "name" ## (TO)

unstratified_cmap_scores <- unstratified[c("name","cmap_score")] # get names and cmap scores ## (TO)
unique_hits_six_cmap_scores <- left_join(unique_hits_six_cmap_scores, unstratified_cmap_scores, by = "name") ## left join to DF of 299 names ## (TO)

InII_cmap_scores <- InII[c("name","cmap_score")] ## (TO)
unique_hits_six_cmap_scores <- left_join(unique_hits_six_cmap_scores, InII_cmap_scores, by = "name") ## (TO)

IIInIV_cmap_scores <- IIInIV[c("name","cmap_score")] ## (TO)
unique_hits_six_cmap_scores <- left_join(unique_hits_six_cmap_scores, IIInIV_cmap_scores, by = "name") ## (TO)

PE_cmap_scores <- PE[c("name","cmap_score")] ## (TO)
unique_hits_six_cmap_scores <- left_join(unique_hits_six_cmap_scores, PE_cmap_scores, by = "name") ## (TO)

ESE_cmap_scores <- ESE[c("name","cmap_score")] ## (TO)
unique_hits_six_cmap_scores <- left_join(unique_hits_six_cmap_scores, ESE_cmap_scores, by = "name") ## (TO)

MSE_cmap_scores <- MSE[c("name","cmap_score")] ## (TO)
unique_hits_six_cmap_scores <- left_join(unique_hits_six_cmap_scores, MSE_cmap_scores, by = "name") ## (TO)


colnames(unique_hits_six_cmap_scores) <- c("name","unstratified", "InII","IIInIV", "PE", "ESE", "MSE") ## (TO)


unique_hits_six_cmap_scores$mean <- rowMeans(subset(unique_hits_six_cmap_scores, select = c("unstratified", "InII","IIInIV", "PE", "ESE", "MSE")), na.rm = FALSE) ## add mean column
#unique_hits_six_cmap_scores <- transform(unique_hits_six_cmap_scores, SD=apply(subset(unique_hits_six_cmap_scores, select = c("unstratified", "InII","IIInIV", "PE", "ESE", "MSE")),1, sd, na.rm = FALSE)) ## add SD column

unique_hits_six_cmap_scores$common <- !is.na(unique_hits_six_cmap_scores$mean)

#unique_hits_six_cmap_scores <- unique_hits_six_cmap_scores[order(unique_hits_six_cmap_scores$mean),] #3 sorts df by mean CMAP scores
#unique_hits_six_cmap_scores <- unique_hits_six_cmap_scores[order(unique_hits_six_cmap_scores$unstratified),] #3 sorts df by unstratified CMAP scores

unique_hits_six_cmap_scores <- subset(unique_hits_six_cmap_scores, select = c("name", "unstratified", "InII","IIInIV", "PE", "ESE", "MSE", "common")) ## remove mean column

unique_hits_six_cmap_scores$unstratified[!is.na(unique_hits_six_cmap_scores$unstratified)]<-"Yes" ## (TO)
unique_hits_six_cmap_scores$InII[!is.na(unique_hits_six_cmap_scores$InII)]<-"Yes" ## (TO) 
unique_hits_six_cmap_scores$IIInIV[!is.na(unique_hits_six_cmap_scores$IIInIV)]<-"Yes" ## (TO) 
unique_hits_six_cmap_scores$PE[!is.na(unique_hits_six_cmap_scores$PE)]<-"Yes" ## (TO) 
unique_hits_six_cmap_scores$ESE[!is.na(unique_hits_six_cmap_scores$ESE)]<-"Yes" ## (TO) 
unique_hits_six_cmap_scores$MSE[!is.na(unique_hits_six_cmap_scores$MSE)]<-"Yes" ## (TO) 

unique_hits_six_cmap_scores$unstratified[is.na(unique_hits_six_cmap_scores$unstratified)]<-"No" ## (TO)
unique_hits_six_cmap_scores$InII[is.na(unique_hits_six_cmap_scores$InII)]<-"No" ## (TO) 
unique_hits_six_cmap_scores$IIInIV[is.na(unique_hits_six_cmap_scores$IIInIV)]<-"No" ## (TO) 
unique_hits_six_cmap_scores$PE[is.na(unique_hits_six_cmap_scores$PE)]<-"No" ## (TO) 
unique_hits_six_cmap_scores$ESE[is.na(unique_hits_six_cmap_scores$ESE)]<-"No" ## (TO) 
unique_hits_six_cmap_scores$MSE[is.na(unique_hits_six_cmap_scores$MSE)]<-"No" ## (TO) 


write.csv(unique_hits_six_cmap_scores, "~/Desktop/endometriosis/tables/supp2table_drug_hits.csv") ## (TO)

unique_hits_six_cmap_scores

table(unique_hits_six_cmap_scores$common)
