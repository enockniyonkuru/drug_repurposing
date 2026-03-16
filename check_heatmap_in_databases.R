# Check heatmap drugs against full databases

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

# Load heatmap data
cmap_heatmap <- read.csv("scripts/results/cmap_v4_top50_heatmap_data.csv", row.names=1)
tahoe_heatmap <- read.csv("scripts/results/tahoe_v5_top50_heatmap_data.csv", row.names=1)

cmap_heatmap_drugs <- rownames(cmap_heatmap)
tahoe_heatmap_drugs <- rownames(tahoe_heatmap)

# Load full drug databases
cmap_db <- read.csv("scripts/data/drug_signatures/cmap_drug_experiments_new.csv")
tahoe_db <- read.csv("scripts/data/drug_signatures/tahoe_drug_experiments_new.csv")

cmap_all_drugs <- unique(cmap_db$name)
tahoe_all_drugs <- unique(tahoe_db$name)

cat("=== DATABASE SIZES ===\n")
cat("CMAP database unique drugs:", length(cmap_all_drugs), "\n")
cat("TAHOE database unique drugs:", length(tahoe_all_drugs), "\n")
cat("CMAP heatmap drugs:", length(cmap_heatmap_drugs), "\n")
cat("TAHOE heatmap drugs:", length(tahoe_heatmap_drugs), "\n\n")

# Normalize for comparison
normalize <- function(x) tolower(trimws(x))

# Also create a version that removes salt/formulation info
clean_name <- function(x) {
  x <- gsub("\\s*\\([^)]+\\)", "", x)  # Remove parenthetical like (hydrochloride)
  x <- trimws(tolower(x))
  return(x)
}

cmap_all_norm <- normalize(cmap_all_drugs)
tahoe_all_norm <- normalize(tahoe_all_drugs)
cmap_all_clean <- clean_name(cmap_all_drugs)
tahoe_all_clean <- clean_name(tahoe_all_drugs)

# ============================================
# CHECK CMAP HEATMAP DRUGS IN TAHOE DATABASE
# ============================================
cat("========================================\n")
cat("CMAP HEATMAP DRUGS: WHICH EXIST IN TAHOE DATABASE?\n")
cat("========================================\n\n")

cmap_in_tahoe_exact <- normalize(cmap_heatmap_drugs) %in% tahoe_all_norm
cmap_in_tahoe_clean <- clean_name(cmap_heatmap_drugs) %in% tahoe_all_clean

cat("Exact match found:", sum(cmap_in_tahoe_exact), "/ 50\n")
cat("Base name match found:", sum(cmap_in_tahoe_clean), "/ 50\n\n")

cat("CMAP Heatmap Drugs FOUND in TAHOE (exact or base name match):\n")
for(i in 1:length(cmap_heatmap_drugs)) {
  drug <- cmap_heatmap_drugs[i]
  exact <- cmap_in_tahoe_exact[i]
  base <- cmap_in_tahoe_clean[i]
  
  if(exact) {
    # Find the matching drug in TAHOE
    tahoe_match_idx <- which(tahoe_all_norm == normalize(drug))
    tahoe_match <- tahoe_all_drugs[tahoe_match_idx[1]]
    cat(sprintf("  %2d. %-30s -> EXACT: %s\n", i, drug, tahoe_match))
  } else if(base) {
    # Find partial match
    tahoe_match_idx <- which(tahoe_all_clean == clean_name(drug))
    tahoe_match <- tahoe_all_drugs[tahoe_match_idx[1]]
    cat(sprintf("  %2d. %-30s -> BASE:  %s\n", i, drug, tahoe_match))
  }
}

cat("\nCMAP Heatmap Drugs NOT FOUND in TAHOE:\n")
for(i in 1:length(cmap_heatmap_drugs)) {
  if(!cmap_in_tahoe_exact[i] && !cmap_in_tahoe_clean[i]) {
    cat(sprintf("  %2d. %s\n", i, cmap_heatmap_drugs[i]))
  }
}

# ============================================
# CHECK TAHOE HEATMAP DRUGS IN CMAP DATABASE
# ============================================
cat("\n\n========================================\n")
cat("TAHOE HEATMAP DRUGS: WHICH EXIST IN CMAP DATABASE?\n")
cat("========================================\n\n")

tahoe_in_cmap_exact <- normalize(tahoe_heatmap_drugs) %in% cmap_all_norm
tahoe_in_cmap_clean <- clean_name(tahoe_heatmap_drugs) %in% cmap_all_clean

cat("Exact match found:", sum(tahoe_in_cmap_exact), "/", length(tahoe_heatmap_drugs), "\n")
cat("Base name match found:", sum(tahoe_in_cmap_clean), "/", length(tahoe_heatmap_drugs), "\n\n")

cat("TAHOE Heatmap Drugs FOUND in CMAP (exact or base name match):\n")
for(i in 1:length(tahoe_heatmap_drugs)) {
  drug <- tahoe_heatmap_drugs[i]
  exact <- tahoe_in_cmap_exact[i]
  base <- tahoe_in_cmap_clean[i]
  
  if(exact) {
    cmap_match_idx <- which(cmap_all_norm == normalize(drug))
    cmap_match <- cmap_all_drugs[cmap_match_idx[1]]
    cat(sprintf("  %2d. %-35s -> EXACT: %s\n", i, drug, cmap_match))
  } else if(base) {
    cmap_match_idx <- which(cmap_all_clean == clean_name(drug))
    cmap_match <- cmap_all_drugs[cmap_match_idx[1]]
    cat(sprintf("  %2d. %-35s -> BASE:  %s\n", i, drug, cmap_match))
  }
}

cat("\nTAHOE Heatmap Drugs NOT FOUND in CMAP:\n")
for(i in 1:length(tahoe_heatmap_drugs)) {
  if(!tahoe_in_cmap_exact[i] && !tahoe_in_cmap_clean[i]) {
    cat(sprintf("  %2d. %s\n", i, tahoe_heatmap_drugs[i]))
  }
}

# ============================================
# SUMMARY
# ============================================
cat("\n\n========================================\n")
cat("SUMMARY\n")
cat("========================================\n")

cmap_found <- sum(cmap_in_tahoe_exact | cmap_in_tahoe_clean)
tahoe_found <- sum(tahoe_in_cmap_exact | tahoe_in_cmap_clean)

cat(sprintf("\nCMAP Heatmap Top 50 -> %d/50 (%.1f%%) exist in TAHOE database\n", 
            cmap_found, cmap_found/50*100))
cat(sprintf("TAHOE Heatmap Top 44 -> %d/44 (%.1f%%) exist in CMAP database\n", 
            tahoe_found, tahoe_found/44*100))

cat(sprintf("\nCMAP Heatmap drugs MISSING from TAHOE: %d/50 (%.1f%%)\n", 
            50-cmap_found, (50-cmap_found)/50*100))
cat(sprintf("TAHOE Heatmap drugs MISSING from CMAP: %d/44 (%.1f%%)\n", 
            44-tahoe_found, (44-tahoe_found)/44*100))
