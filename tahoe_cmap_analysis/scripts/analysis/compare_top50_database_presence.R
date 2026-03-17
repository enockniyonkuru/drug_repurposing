# Compare Top 50 Drugs - Database Presence Analysis
# Check how many top 50 drugs from each database exist in the other

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

# Load the Unstratified results for both databases
cmap_file <- "scripts/results/endo_v4_cmap/endo_v4_Unstratified/endomentriosis_unstratified_disease_signature.csv_results.RData"
tahoe_file <- "scripts/results/endo_v5_tahoe/endo_tahoe_Unstratified/endomentriosis_unstratified_disease_signature.csv_results.RData"

# Load drug name mappings
cmap_drugs_map <- read.csv("scripts/data/drug_signatures/cmap_drug_experiments_new.csv")
tahoe_drugs_map <- read.csv("scripts/data/drug_signatures/tahoe_drug_experiments_new.csv")

# Load results
load(cmap_file)
cmap_results <- results$drugs

load(tahoe_file)
tahoe_results <- results$drugs

# Merge results with drug names
cmap_results$id <- cmap_results$exp_id
cmap <- merge(cmap_results, cmap_drugs_map[, c("id", "name")], by = "id", all.x = TRUE)
cmap$drug_name <- cmap$name

tahoe_results$id <- tahoe_results$exp_id
tahoe <- merge(tahoe_results, tahoe_drugs_map[, c("id", "name")], by = "id", all.x = TRUE)
tahoe$drug_name <- tahoe$name

cat("=== DATABASE SIZES ===\n")
cat("CMAP total experiments:", nrow(cmap), "\n")
cat("CMAP unique drugs:", length(unique(cmap$drug_name)), "\n")
cat("TAHOE total experiments:", nrow(tahoe), "\n")
cat("TAHOE unique drugs:", length(unique(tahoe$drug_name)), "\n\n")

# Get top 50 from each (sorted by score, lowest = best)
# Aggregate by drug name (take minimum score for each drug)
cmap_agg <- aggregate(cmap_score ~ drug_name, data = cmap, FUN = min)
tahoe_agg <- aggregate(cmap_score ~ drug_name, data = tahoe, FUN = min)

cmap_sorted <- cmap_agg[order(cmap_agg$cmap_score), ]
tahoe_sorted <- tahoe_agg[order(tahoe_agg$cmap_score), ]

cmap_top50 <- head(cmap_sorted, 50)
n_tahoe <- min(50, nrow(tahoe_sorted))
tahoe_top50 <- head(tahoe_sorted, n_tahoe)

cat("=== CMAP TOP 50 DRUGS ===\n")
for(i in 1:50) {
  cat(sprintf("%2d. %-35s (score: %.3f)\n", i, cmap_top50$drug_name[i], cmap_top50$cmap_score[i]))
}

cat("\n=== TAHOE TOP 50 DRUGS ===\n")
for(i in 1:n_tahoe) {
  cat(sprintf("%2d. %-35s (score: %.3f)\n", i, tahoe_top50$drug_name[i], tahoe_top50$cmap_score[i]))
}

# Normalize drug names for comparison (lowercase, trim)
normalize <- function(x) tolower(trimws(x))

cmap_all_drugs <- unique(normalize(cmap$drug_name))
tahoe_all_drugs <- unique(normalize(tahoe$drug_name))

cmap_top50_drugs <- normalize(cmap_top50$drug_name)
tahoe_top50_drugs <- normalize(tahoe_top50$drug_name)

# Check CMAP top 50 in TAHOE database
cat("\n\n========================================\n")
cat("CMAP TOP 50: HOW MANY EXIST IN TAHOE DATABASE?\n")
cat("========================================\n")
cmap_in_tahoe <- cmap_top50_drugs %in% tahoe_all_drugs
cat("Found in TAHOE:", sum(cmap_in_tahoe), "/ 50\n")
cat("NOT found in TAHOE:", sum(!cmap_in_tahoe), "/ 50\n\n")

cat("CMAP Top 50 drugs FOUND in TAHOE:\n")
found_drugs <- cmap_top50$drug_name[cmap_in_tahoe]
for(d in found_drugs) cat("  ✓", d, "\n")

cat("\nCMAP Top 50 drugs NOT FOUND in TAHOE:\n")
missing_drugs <- cmap_top50$drug_name[!cmap_in_tahoe]
for(d in missing_drugs) cat("  ✗", d, "\n")

# Check TAHOE top 50 in CMAP database
cat("\n\n========================================\n")
cat("TAHOE TOP 50: HOW MANY EXIST IN CMAP DATABASE?\n")
cat("========================================\n")
tahoe_in_cmap <- tahoe_top50_drugs %in% cmap_all_drugs
cat("Found in CMAP:", sum(tahoe_in_cmap), "/", n_tahoe, "\n")
cat("NOT found in CMAP:", sum(!tahoe_in_cmap), "/", n_tahoe, "\n\n")

cat("TAHOE Top 50 drugs FOUND in CMAP:\n")
found_drugs <- tahoe_top50$drug_name[tahoe_in_cmap]
for(d in found_drugs) cat("  ✓", d, "\n")

cat("\nTAHOE Top 50 drugs NOT FOUND in CMAP:\n")
missing_drugs <- tahoe_top50$drug_name[!tahoe_in_cmap]
for(d in missing_drugs) cat("  ✗", d, "\n")

# Summary
cat("\n\n========================================\n")
cat("SUMMARY\n")
cat("========================================\n")
cat(sprintf("CMAP Top 50 → %d/50 (%.1f%%) exist in TAHOE database\n", 
            sum(cmap_in_tahoe), sum(cmap_in_tahoe)/50*100))
cat(sprintf("TAHOE Top 50 → %d/%d (%.1f%%) exist in CMAP database\n", 
            sum(tahoe_in_cmap), n_tahoe, sum(tahoe_in_cmap)/n_tahoe*100))

# Check for drugs that are top 50 in BOTH
cat("\n\n========================================\n")
cat("DRUGS IN TOP 50 OF BOTH DATABASES\n")
cat("========================================\n")
overlap <- intersect(cmap_top50_drugs, tahoe_top50_drugs)
if(length(overlap) > 0) {
  cat("Found", length(overlap), "drugs in top 50 of BOTH:\n")
  for(d in overlap) {
    cmap_rank <- which(cmap_top50_drugs == d)
    tahoe_rank <- which(tahoe_top50_drugs == d)
    cmap_score <- cmap_top50$cmap_score[cmap_rank]
    tahoe_score <- tahoe_top50$cmap_score[tahoe_rank]
    orig_name <- cmap_top50$drug_name[cmap_rank]
    cat(sprintf("  • %s: CMAP rank #%d (%.3f) | TAHOE rank #%d (%.3f)\n", 
                orig_name, cmap_rank, cmap_score, tahoe_rank, tahoe_score))
  }
} else {
  cat("No drugs appear in top 50 of both databases\n")
}

# Additional: Check where CMAP top 50 rank in TAHOE (if present)
cat("\n\n========================================\n")
cat("CMAP TOP 50 DRUGS: THEIR RANK IN TAHOE\n")
cat("========================================\n")
for(i in 1:50) {
  drug <- cmap_top50_drugs[i]
  orig_name <- cmap_top50$drug_name[i]
  cmap_score <- cmap_top50$cmap_score[i]
  
  tahoe_rank <- which(normalize(tahoe_sorted$drug_name) == drug)
  if(length(tahoe_rank) > 0) {
    tahoe_score <- tahoe_sorted$cmap_score[tahoe_rank[1]]
    cat(sprintf("%2d. %-35s CMAP: #%2d (%.3f) → TAHOE: #%5d (%.3f)\n", 
                i, orig_name, i, cmap_score, tahoe_rank[1], tahoe_score))
  } else {
    cat(sprintf("%2d. %-35s CMAP: #%2d (%.3f) → TAHOE: NOT FOUND\n", 
                i, orig_name, i, cmap_score))
  }
}

# Additional: Check where TAHOE top 50 rank in CMAP (if present)
cat("\n\n========================================\n")
cat("TAHOE TOP 50 DRUGS: THEIR RANK IN CMAP\n")
cat("========================================\n")
for(i in 1:n_tahoe) {
  drug <- tahoe_top50_drugs[i]
  orig_name <- tahoe_top50$drug_name[i]
  tahoe_score <- tahoe_top50$cmap_score[i]
  
  cmap_rank <- which(normalize(cmap_sorted$drug_name) == drug)
  if(length(cmap_rank) > 0) {
    cmap_score <- cmap_sorted$cmap_score[cmap_rank[1]]
    cat(sprintf("%2d. %-35s TAHOE: #%2d (%.3f) → CMAP: #%4d (%.3f)\n", 
                i, orig_name, i, tahoe_score, cmap_rank[1], cmap_score))
  } else {
    cat(sprintf("%2d. %-35s TAHOE: #%2d (%.3f) → CMAP: NOT FOUND\n", 
                i, orig_name, i, tahoe_score))
  }
}

# Save results to a file
sink("top50_database_comparison.txt")
cat("=== TOP 50 DRUG DATABASE PRESENCE COMPARISON ===\n")
cat("Analysis Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
cat(sprintf("CMAP Top 50 → %d/50 (%.1f%%) exist in TAHOE database\n", 
            sum(cmap_in_tahoe), sum(cmap_in_tahoe)/50*100))
cat(sprintf("TAHOE Top 50 → %d/%d (%.1f%%) exist in CMAP database\n\n", 
            sum(tahoe_in_cmap), n_tahoe, sum(tahoe_in_cmap)/n_tahoe*100))

cat("CMAP Top 50 NOT in TAHOE:\n")
for(d in cmap_top50$drug_name[!cmap_in_tahoe]) cat("  -", d, "\n")
cat("\nTAHOE Top 50 NOT in CMAP:\n")
for(d in tahoe_top50$drug_name[!tahoe_in_cmap]) cat("  -", d, "\n")
sink()

cat("\n\nResults saved to: top50_database_comparison.txt\n")
