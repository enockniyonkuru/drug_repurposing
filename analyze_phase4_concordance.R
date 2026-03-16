#!/usr/bin/env Rscript
library(dplyr)
library(tidyr)

# Load the phase4 data
df_phase4 <- read.csv("tahoe_cmap_analysis/sirota_manuscript_feedback/phase4_drugs_detailed_list.csv")

# Parse the "Diseases_Found_In" column and create a long format
df_long <- df_phase4 %>%
  separate_rows(Diseases_Found_In, sep = "; ") %>%
  mutate(Diseases_Found_In = tolower(trimws(Diseases_Found_In)))

# Count Phase 4 drugs per disease
phase4_per_disease <- df_long %>%
  group_by(Diseases_Found_In) %>%
  summarise(phase4_drug_count = n(), .groups = 'drop') %>%
  arrange(desc(phase4_drug_count))

cat("=== PHASE 4 DRUG COUNT PER AUTOIMMUNE DISEASE ===\n\n")
print(phase4_per_disease)

cat("\n=== RHEUMATOID ARTHRITIS RANKING ===\n")
ra_rank <- which(phase4_per_disease$Diseases_Found_In == "rheumatoid arthritis")
cat(sprintf("Rheumatoid Arthritis ranks #%d with %d Phase 4 drugs recovered\n", 
            ra_rank, phase4_per_disease$phase4_drug_count[ra_rank]))

cat("\n=== RHEUMATOID ARTHRITIS DRUGS ===\n")
ra_drugs <- df_long %>% 
  filter(Diseases_Found_In == "rheumatoid arthritis") %>% 
  select(Drug, Recovery_Methods) %>% 
  arrange(Drug)
for(i in 1:nrow(ra_drugs)) {
  cat(sprintf("%s (%s)\n", ra_drugs$Drug[i], ra_drugs$Recovery_Methods[i]))
}

cat("\n=== COMPARISON TO TOP DISEASES ===\n")
top_5 <- phase4_per_disease %>% head(5)
for(i in 1:nrow(top_5)) {
  cat(sprintf("%d. %s: %d drugs\n", i, top_5$Diseases_Found_In[i], top_5$phase4_drug_count[i]))
}
