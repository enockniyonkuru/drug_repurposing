library(dplyr)
library(tidyr)

# Define profiles
profiles <- c("ESE", "INII", "IIINIV", "MSE", "PE", "Unstratified")

# Read Tomiko's results
tomiko_results <- list()
for (profile in profiles) {
  file <- sprintf("tomiko_cdrpipe_comparison/old_tomiko_drug_hits_comparison/drug_instances_%s.csv", 
                  ifelse(profile == "IIINIV", "IIInIV", 
                         ifelse(profile == "INII", "InII", profile)))
  tomiko_results[[profile]] <- read.csv(file) %>%
    pull(drug_name) %>%
    unique() %>%
    sort()
}

# Read our new results (DRpipe)
drpipe_results <- list()
for (profile in profiles) {
  search_pattern <- sprintf("scripts/results/CMAP_Endometriosis_%s_Strict_*/", profile)
  dir_match <- Sys.glob(search_pattern)[1]
  
  if (!is.na(dir_match)) {
    # Find the hits CSV file
    hits_file <- Sys.glob(file.path(dir_match, "*_q<0.*.csv"))[1]
    if (!is.na(hits_file)) {
      drpipe_results[[profile]] library(dplyr)
library(tidyr)

# Define profiles
profiles <- c("ESE", "INII", "IIINIV", "MS  library(tidyr  
# Define proltsprofiles <- c("Eha
# Read Tomiko's results
tomiko_results <- list()
for (profile in tertomiko_results <- listesfor (profile in profile.f  me(
  Profile = profiles,
                  ifelse(profile == "IIINIV", "IIInIV", 
                         ifelse(profile == pr                         ifelse(profile == "INII", "InIrl  tomiko_results[[profile]] <- readength(intersect(tomiko_results[[p]]    pull(drug_name) %>%
    unique() %>%
    sor(p    unique() %>%
    sen    sort()
}

#ik}

# Read[[p]]drpipe_results <- list()
for (lyfor (profisapply(profiles  search_pattern <- spriniff  dir_match <- Sys.glob(search_pattern)[1]
  
  if (!is.na(dir_match)) {
    # Find thmp  
  if (!is.na(dir_match)) {
    # Find *  00    # Find the hits CSV fIO    hits_file <- Sys.glob(fRp    if (!is.na(hits_file)) {
      drpipe_results[[profile]] libnc      drpipe_results[[profiLAlibrary(tidyr)

# Define profiles
profiles <-{

# Define prointprofiles <- c("Esu# Define proltsprofiles <- c("Eha
# Read Tomiko's results
- # Read Tomiko's results
tomiko_r],tomiko_results <- listlefor (profile in tertomitd  Profile = profiles,
                  ifelse(profile == "IIINIV", "IIItf                  if)
                         ifelse(profile == pr                unique() %>%
    sor(p    unique() %>%
    sen    sort()
}

#ik}

# Read[[p]]drpipe_results <- list()
for (lyfor (profisapply(profiles  search_pattern <- spriniff  dir_match <- Sys.glob(sear      sor(p    unst    sen    sort()
}

#ikco}

#ik}

# Read[ }
  
# (lefor (lyfor (profisapply(profiles  pr  
  if (!is.na(dir_match)) {
    # Find thmp  
  if (!is.na(dir_match)) {
    # Find *  00    # Find(o ly    # Find thmp  
  if (!")))
  }
}
