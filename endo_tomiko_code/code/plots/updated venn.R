# produces venn diagrams for the drug instances
  
library(eulerr)
library(dplyr)

# LOAD DATA
# unstratified
unstratified <- read.csv("~/Desktop/endometriosis/unstratified/drug_instances_unstratified.csv")
unstratified_name <- unstratified[,8, drop=FALSE]

# by stage
InII <- read.csv("~/Desktop/endometriosis/by stage/InII/drug_instances_InII.csv")
IIInIV <- read.csv("~/Desktop/endometriosis/by stage/IIInIV/drug_instances_IIInIV.csv")

InII_name <- InII[,8, drop=FALSE]
IIInIV_name <- IIInIV[,8,drop=FALSE]
stage_name <- rbind(InII_name, IIInIV_name)
stage_name <- distinct(stage_name)

# by phase 
PE <- read.csv("~/Desktop/endometriosis/by phase/PE/drug_instances_PE.csv")
ESE <- read.csv("~/Desktop/endometriosis/by phase/ESE/drug_instances_ESE.csv")
MSE <- read.csv("~/Desktop/endometriosis/by phase/MSE/drug_instances_MSE.csv")

PE_name <- PE[,8, drop=FALSE]
ESE_name <- ESE[,8,drop=FALSE]
MSE_name <- MSE[,8,drop=FALSE]

phase_name <- rbind(PE_name, ESE_name, MSE_name)
all <- rbind(PE_name, ESE_name, MSE_name, InII_name, IIInIV_name, unstratified_name)
phase_name <- distinct(phase_name)

all <- distinct(all)

# getting rid of the column headers
names(unstratified_name) <- NULL
names(InII_name) <- NULL
names(IIInIV_name) <- NULL
names(PE_name) <- NULL
names(ESE_name) <- NULL
names(MSE_name) <- NULL
names(stage_name) <- NULL
names(phase_name) <- NULL

# set seed (for reproducibility of the shapes calculation)
set.seed(200602)

# aesthetics
eulerr_options(
  labels = list(fontsize = 16),
  quantities = list(fontsize = 14))

# MAKE VENN DIAGRAMS

# Stage 1/2 vs. 3/4

plot(
  euler(c(
    'Stage 1/2' = InII_name,
    'Stage 3/4' = IIInIV_name
  ),
  shape = "ellipse"),
  quantities = T,
  fill = 
    c("lemonchiffon1","plum2", "slategray1"),
  main = "")


# PE vs. ESE vs. MSE

plot(
  euler(c(
    'PE' = PE_name,
    'ESE' = ESE_name,
    'MSE' = MSE_name
  ),
  shape = "circle"),
  quantities = T,
  fill = 
    c("lemonchiffon1","plum2", "lightpink", "lightskyblue"),
  main = "")

# Unstratified vs. stratified by stage

plot(
  euler(c(
    'Stage Stratified' = stage_name,
    'Unstratified' = unstratified_name
  ),
  shape = "circle"),
  quantities = T,
  fill = 
    c("lemonchiffon1","plum2", "lightskyblue"),
  main = "")

# Unstratified vs. stratified by phase

plot(
  euler(c(
    'Phase Stratified' = phase_name,
    'Unstratified' = unstratified_name
  ),
  shape = "circle"),
  quantities = T,
  fill = 
    c("lemonchiffon1","plum2","lightskyblue"),
  main = "")

# Stratified by stage vs. phase

plot(
  euler(c(
    'Phase Stratified' = phase_name,
    'Stage Stratified' = stage_name
  ),
  shape = "circle"),
  quantities = T,
  fill = 
    c("lightskyblue","lemonchiffon1"),
  main = "")