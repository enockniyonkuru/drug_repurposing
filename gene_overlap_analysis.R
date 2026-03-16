#!/usr/bin/env Rscript
# Gene overlap analysis

setwd("/Users/enockniyonkuru/Desktop/drug_repurposing")

cat("=== GENE IDENTIFIER ANALYSIS ===\n\n")

# Load disease signature
dis <- read.csv("scripts/data/disease_signatures/endo_disease_signatures/endomentriosis_ese_disease_signature.csv")
cat("Disease signature uses SYMBOLS column\n")
cat("Sample symbols:", paste(head(dis$symbols, 10), collapse=", "), "\n")
cat("Total genes:", length(unique(dis$symbols)), "\n")

# Load gene conversion table
conv <- read.delim("scripts/data/gene_id_conversion_table.tsv")
cat("\nGene conversion table:\n")
cat("  Columns:", paste(names(conv), collapse=", "), "\n")
cat("  Rows:", nrow(conv), "\n")

# Check how many disease genes can be converted
dis_symbols <- unique(dis$symbols)
# Use Gene_name column instead of SYMBOL
converted <- conv[conv$Gene_name %in% dis_symbols, ]
cat("\nDisease symbols found in conversion table:", nrow(converted), "/", length(dis_symbols), "\n")

# Get Entrez IDs - use entrezID column
dis_entrez <- unique(converted$entrezID)
dis_entrez <- dis_entrez[!is.na(dis_entrez)]
cat("Mapped to Entrez IDs:", length(dis_entrez), "\n")

# Check overlap with drug databases
load("scripts/data/drug_signatures/cmap_signatures.RData")
cmap_genes <- as.numeric(rownames(cmap_signatures))

load("scripts/data/drug_signatures/tahoe_signatures.RData")
tahoe_genes <- as.numeric(rownames(tahoe_signatures))

cmap_overlap <- sum(dis_entrez %in% cmap_genes)
tahoe_overlap <- sum(dis_entrez %in% tahoe_genes)

cat("\n=== GENE OVERLAP WITH DRUG DATABASES ===\n")
cat("Disease genes in CMAP:", cmap_overlap, "/", length(dis_entrez), 
    "(", round(100*cmap_overlap/length(dis_entrez), 1), "%)\n")
cat("Disease genes in TAHOE:", tahoe_overlap, "/", length(dis_entrez),
    "(", round(100*tahoe_overlap/length(dis_entrez), 1), "%)\n")

cat("\n=== CONCLUSION ===\n")
if (tahoe_overlap >= cmap_overlap) {
  cat("Gene overlap is NOT the issue - TAHOE has equal or better coverage.\n")
  cat("The problem is in SCORE CALCULATION, not gene mapping.\n")
} else {
  cat("Gene overlap IS part of the issue - TAHOE has lower coverage.\n")
}
