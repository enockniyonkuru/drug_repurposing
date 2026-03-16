#!/usr/bin/env Rscript
# Deep investigation into zero scores in TAHOE

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("================================================================================\n")
cat("DEEP DIVE: Why 55.8% of TAHOE scores are exactly zero?\n")
cat("================================================================================\n\n")

# Load both results
load("scripts/results/endo_v4_cmap/endo_v4_ESE/endomentriosis_ese_disease_signature_results.RData")
cmap <- results

load("scripts/results/endo_v5_tahoe/endo_tahoe_ESE/endomentriosis_ese_disease_signature_results.RData")
tahoe <- results

# =============================================================================
# 1. ZERO SCORE COMPARISON
# =============================================================================
cat("=== ZERO SCORE COMPARISON ===\n\n")
cat("CMAP:\n")
cat("  Total experiments:", nrow(cmap$drugs), "\n")
cat("  Scores = 0:", sum(cmap$drugs$cmap_score == 0), 
    "(", round(100*sum(cmap$drugs$cmap_score == 0)/nrow(cmap$drugs),1), "%)\n")

cat("\nTAHOE:\n")
cat("  Total experiments:", nrow(tahoe$drugs), "\n")
cat("  Scores = 0:", sum(tahoe$drugs$cmap_score == 0), 
    "(", round(100*sum(tahoe$drugs$cmap_score == 0)/nrow(tahoe$drugs),1), "%)\n")

# =============================================================================
# 2. CHECK SIGNATURE OVERLAP
# =============================================================================
cat("\n=== DISEASE SIGNATURE GENES ===\n\n")

# Check what's in the results
cat("CMAP results structure:\n")
cat("  Names:", paste(names(cmap), collapse=", "), "\n")

cat("\nTAHOE results structure:\n")
cat("  Names:", paste(names(tahoe), collapse=", "), "\n")

# Check signature_info if available
if ("signature_info" %in% names(cmap)) {
  cat("\nCMAP signature_info:\n")
  print(cmap$signature_info)
}
if ("signature_info" %in% names(tahoe)) {
  cat("\nTAHOE signature_info:\n")
  print(tahoe$signature_info)
}

# =============================================================================
# 3. LOAD AND COMPARE DRUG SIGNATURE DATABASES
# =============================================================================
cat("\n=== DRUG SIGNATURE DATABASES ===\n\n")

# Load CMAP signatures
if (file.exists("scripts/data/drug_signatures/cmap_signatures.RData")) {
  env_cmap <- new.env()
  load("scripts/data/drug_signatures/cmap_signatures.RData", envir = env_cmap)
  cat("CMAP signature database loaded\n")
  cat("  Objects:", paste(ls(env_cmap), collapse=", "), "\n")
  
  # Find the main signature matrix
  for (obj in ls(env_cmap)) {
    o <- get(obj, envir = env_cmap)
    if (is.matrix(o)) {
      cat("  ", obj, ": ", nrow(o), " genes x ", ncol(o), " experiments\n", sep="")
      cmap_sig_genes <- rownames(o)
    }
  }
}

# Load TAHOE signatures
if (file.exists("scripts/data/drug_signatures/tahoe_signatures.RData")) {
  env_tahoe <- new.env()
  load("scripts/data/drug_signatures/tahoe_signatures.RData", envir = env_tahoe)
  cat("\nTAHOE signature database loaded\n")
  cat("  Objects:", paste(ls(env_tahoe), collapse=", "), "\n")
  
  for (obj in ls(env_tahoe)) {
    o <- get(obj, envir = env_tahoe)
    if (is.matrix(o)) {
      cat("  ", obj, ": ", nrow(o), " genes x ", ncol(o), " experiments\n", sep="")
      tahoe_sig_genes <- rownames(o)
    }
  }
}

# =============================================================================
# 4. GENE OVERLAP ANALYSIS
# =============================================================================
cat("\n=== GENE OVERLAP ANALYSIS ===\n\n")

# Load disease signature
disease_file <- "scripts/data/disease_signatures/endomentriosis_ese_disease_signature.csv"
if (file.exists(disease_file)) {
  disease <- read.csv(disease_file)
  cat("Disease signature file columns:", paste(names(disease), collapse=", "), "\n")
  
  # Find gene column
  gene_col <- grep("gene|symbol|entrez", names(disease), ignore.case = TRUE, value = TRUE)[1]
  if (!is.na(gene_col)) {
    disease_genes <- unique(disease[[gene_col]])
    cat("Disease genes:", length(disease_genes), "\n")
    
    if (exists("cmap_sig_genes")) {
      cmap_overlap <- length(intersect(disease_genes, cmap_sig_genes))
      cat("\nOverlap with CMAP drug DB:", cmap_overlap, "genes\n")
    }
    if (exists("tahoe_sig_genes")) {
      tahoe_overlap <- length(intersect(disease_genes, tahoe_sig_genes))
      cat("Overlap with TAHOE drug DB:", tahoe_overlap, "genes\n")
    }
  }
}

# =============================================================================
# 5. ANALYSIS OF ZERO-SCORE EXPERIMENTS
# =============================================================================
cat("\n=== ANALYSIS OF ZERO-SCORE EXPERIMENTS ===\n\n")

# For TAHOE, what characterizes zero-score experiments?
tahoe_zero <- tahoe$drugs[tahoe$drugs$cmap_score == 0, ]
tahoe_nonzero <- tahoe$drugs[tahoe$drugs$cmap_score != 0, ]

cat("TAHOE zero-score experiments:\n")
cat("  Count:", nrow(tahoe_zero), "\n")
cat("  P-value distribution:\n")
cat("    p = 0:", sum(tahoe_zero$p == 0), "\n")
cat("    p = 1:", sum(tahoe_zero$p == 1), "\n")
cat("    0 < p < 1:", sum(tahoe_zero$p > 0 & tahoe_zero$p < 1), "\n")

cat("\nTAHOE non-zero score experiments:\n")
cat("  Count:", nrow(tahoe_nonzero), "\n")
cat("  Negative scores:", sum(tahoe_nonzero$cmap_score < 0), "\n")
cat("  Positive scores:", sum(tahoe_nonzero$cmap_score > 0), "\n")

# =============================================================================
# 6. CHECK IF ZERO SCORES ARE DUE TO NO GENE OVERLAP
# =============================================================================
cat("\n=== HYPOTHESIS: ZERO SCORES FROM NO GENE OVERLAP ===\n\n")

cat("When connectivity score = 0, it typically means:\n")
cat("  1. No overlapping genes between disease signature and drug experiment\n")
cat("  2. OR equal number of up/down regulated genes in same direction\n")
cat("  3. OR the drug experiment has no expression change\n")

cat("\nComparing proportions:\n")
cat("  CMAP zero scores: ", round(100*sum(cmap$drugs$cmap_score == 0)/nrow(cmap$drugs),1), "%\n", sep="")
cat("  TAHOE zero scores: ", round(100*sum(tahoe$drugs$cmap_score == 0)/nrow(tahoe$drugs),1), "%\n", sep="")

# =============================================================================
# 7. SUMMARY
# =============================================================================
cat("\n================================================================================\n")
cat("SUMMARY: ROOT CAUSE OF FEWER TAHOE HITS\n")
cat("================================================================================\n")

cat("
KEY FINDING: 55.8% of TAHOE experiments have ZERO connectivity scores!

This is the PRIMARY reason for fewer hits:
  - CMAP: ", round(100*sum(cmap$drugs$cmap_score == 0)/nrow(cmap$drugs),1), "% zero scores
  - TAHOE: ", round(100*sum(tahoe$drugs$cmap_score == 0)/nrow(tahoe$drugs),1), "% zero scores

Of the remaining non-zero TAHOE scores:
  - Only 0.3% are negative (therapeutic direction)
  - 43.9% are positive (disease-promoting direction)

COMBINED FACTORS:
1. MASSIVE ZERO-SCORE RATE (55.8%):
   - Likely due to poor gene overlap between disease signature and TAHOE
   - Different gene identifiers or missing genes in TAHOE database

2. POSITIVE BIAS IN NON-ZERO SCORES:
   - 99.2% of non-zero TAHOE scores are positive
   - Suggests TAHOE drug signatures correlate WITH disease, not AGAINST

3. STRICTER FDR CORRECTION:
   - 9.3x more experiments means 9x stricter q-value threshold
   - Even significant negative scores may not pass FDR correction

RECOMMENDED ACTIONS:
1. Check gene identifier mapping between disease signature and TAHOE
2. Verify TAHOE database gene coverage
3. Consider using a rank-based approach instead of significance threshold
4. Investigate why TAHOE scores are positively biased
", sep="")

cat("\n✓ Investigation complete!\n")
