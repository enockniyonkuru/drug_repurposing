

# ------------------------------------------------------------------------------
# Script: DR_processing.R
#
# This script processes a disease signature dataset (Core Fibroid example) and
# evaluates it against CMAP reference profiles to identify drugs with potential
# reversal activity. The workflow includes: loading and cleaning gene signatures,
# applying logFC cutoffs, generating random null distributions, computing CMAP
# scores, and assembling drug-level results with p/q-values. Outputs include
# result objects, random score ensembles, and filtered drug hits validated against
# CMAP experiment metadata. This serves as the first step in the drug repurposing
# analysis pipeline.
# ------------------------------------------------------------------------------


# --- Load libraries -----------------------------------------------------------
library(dplyr)        # data wrangling (mutate, select, filter, pull, group_by, slice)
library(gprofiler2)   # (loaded but not used below; for enrichment if needed later)
library(pbapply)      # parallelized apply helpers (used inside DRpipe funcs)
library(qvalue)       # q-value estimation (used inside DRpipe funcs)
library(DRpipe)       # your pipeline helpers: clean_table, random_score, query_score, query

# --- Inputs -------------------------------------------------------------------
load('data/cmap_signatures.RData')  # loads object(s) with CMAP signatures (e.g., cmap_signatures)

path  <- "."
# Find your disease signature CSV file(s)
files <- list.files(path, pattern = "CoreFibroidSignature_All_Datasets.csv")

# Derive a dataset label from the filename (used later in outputs/IDs)
dataset <- sub("Signature_All_Datasets\\.csv", "", files[[1]])

# Read the disease signature table
# (If the file is in the current folder, read it directly; if it’s in a subfolder, adjust path.)
dz_signature <- read.csv(list.files(path, files[[1]], full.names = TRUE))

# Compute a single logFC per gene as the row mean across all log2FC* columns
dz_signature <- dz_signature |>
    mutate(logFC = rowMeans(across(starts_with("log2FC")), na.rm = TRUE))


# Quick exploratory look at the logFC distribution and a simple threshold count
hist(dz_signature$logFC)
table(abs(dz_signature$logFC) > 1)

# --- Clean / filter signature -------------------------------------------------
# Keep genes present in CMAP signatures; apply an absolute logFC cutoff of 1
dz_signature_clean <- clean_table(
    dz_signature,
    gene_key      = "SYMBOL",
    logFC_key     = "logFC",
    logFC_cutoff  = 1,
    pval_key      = NULL,                  # no p-values provided
    db_gene_list  = cmap_signatures$V1     # reference gene universe from CMAP
)

# Split into up- and down-regulated gene lists (by GeneID produced by clean_table)
dz_genes_up   <- filter(dz_signature_clean, logFC > 0) |> pull(GeneID)
dz_genes_down <- filter(dz_signature_clean, logFC < 0) |> pull(GeneID)
n_up   <- length(dz_genes_up)
n_down <- length(dz_genes_down)

# --- Score against CMAP -------------------------------------------------------
# Null distribution: random up/down sets of the same sizes (for empirical p/q)
rand_cmap_scores <- random_score(cmap_signatures, n_up, n_down)

# Observed CMAP reversal scores for the actual disease signature
dz_cmap_scores   <- query_score(cmap_signatures, dz_genes_up, dz_genes_down)

# Combine null + observed into drug-level results with p/q-values
drugs <- query(
    rand_cmap_scores,
    dz_cmap_scores,
    subset_comparison_id = paste0(dataset, "_logFC_0.5")  # label for this run
)

# --- Save results -------------------------------------------------------------
dir.out <- "results/"
dir.create(dir.out, showWarnings = FALSE)

# Save both the drug hits table and the cleaned signature
results <- list(drugs, dz_signature_clean)
save(results, file = paste0(dir.out, dataset, "_logFC_1.RData"))

# Save the random score ensemble (for reproducibility / reuse)
save(rand_cmap_scores, file = paste0(dir.out, dataset, "_random_scores_100000_logFC_1.RData"))

# --- Quick filtering by external validation -----------------------------------
# Read CMAP experiment metadata and a curated list of valid instances
cmap_experiments <- read.csv("data/cmap_drug_experiments_new.csv", stringsAsFactors = FALSE)
valid_instances  <- read.csv("data/cmap_valid_instances.csv",      stringsAsFactors = FALSE)

# Merge and keep only valid experiments that have DrugBank IDs
cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by = "id")
cmap_experiments_valid <- subset(cmap_experiments_valid, valid == 1 & DrugBank.ID != "NULL")

# Annotate your drug table with experiment metadata, keep significant reversers
drugs.valid <- merge(drugs, cmap_experiments_valid, by.x = "exp_id", by.y = "id")

# Keep q < 0.05 and negative cmap_score (reversal), then one best instance per drug name
drugs.valid <- drugs.valid |>
    subset(q < 0.05 & cmap_score < 0) |>
    group_by(name) |>
    dplyr::slice(which.min(cmap_score))

