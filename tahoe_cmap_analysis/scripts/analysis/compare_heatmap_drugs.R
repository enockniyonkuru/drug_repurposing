# Compare heatmap drugs between CMAP and TAHOE

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

# Load heatmap data
cmap_heatmap <- read.csv("scripts/results/cmap_v4_top50_heatmap_data.csv", row.names=1)
tahoe_heatmap <- read.csv("scripts/results/tahoe_v5_top50_heatmap_data.csv", row.names=1)

cmap_drugs <- rownames(cmap_heatmap)
tahoe_drugs <- rownames(tahoe_heatmap)

cat("=== HEATMAP TOP 50 COMPARISON ===\n\n")
cat("CMAP heatmap drugs:", length(cmap_drugs), "\n")
cat("TAHOE heatmap drugs:", length(tahoe_drugs), "\n\n")

# Normalize for comparison
normalize <- function(x) tolower(trimws(x))
cmap_norm <- normalize(cmap_drugs)
tahoe_norm <- normalize(tahoe_drugs)

# Find exact overlap
overlap <- intersect(cmap_norm, tahoe_norm)
cat("EXACT OVERLAP between heatmaps:", length(overlap), "drugs\n\n")

if(length(overlap) > 0) {
  cat("Overlapping drugs (exact match):\n")
  for(d in overlap) {
    cmap_idx <- which(cmap_norm == d)
    tahoe_idx <- which(tahoe_norm == d)
    cat(sprintf("  %s (CMAP row %d) = %s (TAHOE row %d)\n", 
                cmap_drugs[cmap_idx], cmap_idx, tahoe_drugs[tahoe_idx], tahoe_idx))
  }
}

# Also check for partial matches (drug name variations)
cat("\n\n=== CHECKING FOR PARTIAL MATCHES ===\n")
cat("(Same drug with different salt/formulation names)\n\n")

# Look for common drug roots
check_partial <- function(cmap_d, tahoe_d) {
  # Remove common suffixes like (hydrochloride), etc.
  clean <- function(x) {
    x <- gsub("\\s*\\([^)]+\\)", "", x)  # Remove parenthetical
    x <- gsub("hydrochloride|sodium|salt|acetate|sulfate|dihydrochloride", "", x, ignore.case = TRUE)
    x <- trimws(tolower(x))
    return(x)
  }
  return(clean(cmap_d) == clean(tahoe_d))
}

# Check each pair
partial_matches <- data.frame(CMAP = character(), TAHOE = character(), stringsAsFactors = FALSE)

for(i in 1:length(cmap_drugs)) {
  for(j in 1:length(tahoe_drugs)) {
    # Check if base names match
    cmap_base <- gsub("\\s*\\([^)]+\\)", "", cmap_drugs[i])
    tahoe_base <- gsub("\\s*\\([^)]+\\)", "", tahoe_drugs[j])
    
    if(tolower(trimws(cmap_base)) == tolower(trimws(tahoe_base)) ||
       grepl(tolower(trimws(cmap_drugs[i])), tolower(tahoe_drugs[j]), fixed = TRUE) ||
       grepl(tolower(trimws(tahoe_drugs[j])), tolower(cmap_drugs[i]), fixed = TRUE)) {
      partial_matches <- rbind(partial_matches, 
                               data.frame(CMAP = cmap_drugs[i], 
                                          CMAP_rank = i,
                                          TAHOE = tahoe_drugs[j],
                                          TAHOE_rank = j,
                                          stringsAsFactors = FALSE))
    }
  }
}

if(nrow(partial_matches) > 0) {
  cat("Found", nrow(partial_matches), "potential matches:\n\n")
  print(partial_matches)
} else {
  cat("No partial matches found\n")
}

# Print all drugs from both for manual inspection
cat("\n\n=== ALL CMAP HEATMAP DRUGS ===\n")
for(i in 1:length(cmap_drugs)) {
  cat(sprintf("%2d. %s\n", i, cmap_drugs[i]))
}

cat("\n\n=== ALL TAHOE HEATMAP DRUGS ===\n")
for(i in 1:length(tahoe_drugs)) {
  cat(sprintf("%2d. %s\n", i, tahoe_drugs[i]))
}
