#!/usr/bin/env Rscript
#' Tahoe Signatures Part 3b: Shared Drugs to RData
#'
#' Converts ranked parquet data to RData for shared drug experiments only.
#' Creates filtered signature matrix for direct CMAP-Tahoe comparison analysis.
#'

library(arrow)

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("Converting Part 2B Filtered Data to RData\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")

# Paths
parquet_file <- "../data/filtered_tahoe/tahoe_ranked_shared_genes_all_drugs.parquet"
shared_drugs_file <- "../reports/shared_drugs_tahoe_cmap.csv"
drug_exp_file <- "../data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv"
output_rdata <- "../data/drug_signatures/tahoe/tahoe_genes_drugs.RData"
report_file <- "../reports/tahoe_signature_versions_report.txt"

cat("\n[Step 1] Loading ranked data from parquet...\n")
ranked_df <- read_parquet(parquet_file)
cat(sprintf("  - Loaded data with shape: %d rows x %d columns\n", nrow(ranked_df), ncol(ranked_df)))

# Set entrezID as rownames and remove the column
rownames(ranked_df) <- ranked_df$entrezID
ranked_df$entrezID <- NULL
cat(sprintf("  - Matrix shape after setting rownames: %d genes x %d experiments\n", 
            nrow(ranked_df), ncol(ranked_df)))

cat("\n[Step 2] Loading shared drug information...\n")
shared_drugs <- read.csv(shared_drugs_file, stringsAsFactors = FALSE)
drug_exp <- read.csv(drug_exp_file, stringsAsFactors = FALSE)

# Get shared drug names
shared_drug_names <- shared_drugs$tahoe_original_name[!is.na(shared_drugs$tahoe_original_name)]
cat(sprintf("  - Found %d shared drug names\n", length(shared_drug_names)))

# Get experiment IDs for shared drugs
shared_exp_ids <- drug_exp$id[drug_exp$name %in% shared_drug_names]
shared_exp_ids_str <- as.character(shared_exp_ids)
cat(sprintf("  - Found %d experiment IDs for shared drugs\n", length(shared_exp_ids_str)))

cat("\n[Step 3] Filtering to shared drug experiments...\n")
# Find which columns match shared experiment IDs
cols_to_keep <- colnames(ranked_df)[colnames(ranked_df) %in% shared_exp_ids_str]
cat(sprintf("  - Found %d matching experiments in ranked matrix\n", length(cols_to_keep)))

if (length(cols_to_keep) == 0) {
  stop("ERROR: No shared drug experiments found in ranked matrix!")
}

# Filter the data
ranked_genes_drugs <- ranked_df[, cols_to_keep]
cat(sprintf("  - Filtered matrix shape: %d genes x %d experiments\n", 
            nrow(ranked_genes_drugs), ncol(ranked_genes_drugs)))

cat("\n[Step 4] Converting to CMap-like format...\n")
# Transpose so experiments are rows, genes are columns
transposed <- t(ranked_genes_drugs)

# Create CMap-like data frame with V1, V2, V3, ... column names
# V1 will be the Entrez IDs, V2-Vn will be the experiments
entrez_ids <- as.integer(colnames(transposed))
cmap_like <- data.frame(V1 = entrez_ids)

# Add each experiment as a column
for (i in 1:nrow(transposed)) {
  col_name <- paste0("V", i + 1)
  cmap_like[[col_name]] <- as.numeric(transposed[i, ])
}

cat(sprintf("  - CMap-like DataFrame created with shape: %d rows x %d columns\n", 
            nrow(cmap_like), ncol(cmap_like)))

cat("\n[Step 5] Saving to RData...\n")
tahoe_genes_drugs <- cmap_like
save(tahoe_genes_drugs, file = output_rdata)
cat(sprintf("  - Saved: %s\n", output_rdata))
cat(sprintf("  - Shape: %d genes x %d signatures\n", 
            nrow(tahoe_genes_drugs), ncol(tahoe_genes_drugs) - 1))

cat("\n[Step 6] Generating report...\n")
# Try to load genes_filtered file for report
genes_filtered_file <- "../data/drug_signatures/tahoe/tahoe_genes_filtered.RData"
if (file.exists(genes_filtered_file)) {
  tryCatch({
    load(genes_filtered_file)
    genes_filtered_shape <- dim(tahoe_genes_filtered)
    cat(sprintf("  - Loaded tahoe_genes_filtered.RData shape: %d x %d\n", 
                genes_filtered_shape[1], genes_filtered_shape[2]))
  }, error = function(e) {
    cat(sprintf("  - Warning: Could not load %s: %s\n", genes_filtered_file, e$message))
    genes_filtered_shape <- c(0, 0)
  })
} else {
  cat(sprintf("  - Warning: %s does not exist\n", genes_filtered_file))
  genes_filtered_shape <- c(0, 0)
}

# Generate report
report_lines <- c(
  "===============================================",
  "  Tahoe Drug Signature Versions Report",
  "===============================================",
  "",
  "This report summarizes the dimensions (genes, signatures) of the two",
  "generated Tahoe .RData files. These files contain RANKED data.",
  "",
  "--- 1. `tahoe_signatures.RData` ---",
  "Status:   NOT CREATED",
  "Reason:   The full Tahoe dataset ('aggregated.h5') is too large to",
  "          process into a single RData file. The pipeline starts",
  "          by filtering for shared genes.",
  "",
  "--- 2. Gene-Filtered Signatures ---",
  "File:     tahoe_genes_filtered.RData",
  "Filter:   Filtered to include ONLY shared genes (all experiments).",
  sprintf("Genes:    %s", format(genes_filtered_shape[1], big.mark = ",")),
  sprintf("Sigs:     %s (Total columns - 1 for gene ID)", 
          format(genes_filtered_shape[2] - 1, big.mark = ",")),
  sprintf("Shape:    (%d, %d)", genes_filtered_shape[1], genes_filtered_shape[2]),
  "",
  "--- 3. Gene- and Drug-Filtered Signatures ---",
  "File:     tahoe_genes_drugs.RData",
  "Filter:   Filtered by shared genes AND shared drugs.",
  sprintf("Genes:    %s", format(nrow(tahoe_genes_drugs), big.mark = ",")),
  sprintf("Sigs:     %s (Total columns - 1 for gene ID)", 
          format(ncol(tahoe_genes_drugs) - 1, big.mark = ",")),
  sprintf("Shape:    (%d, %d)", nrow(tahoe_genes_drugs), ncol(tahoe_genes_drugs)),
  "",
  "--- Summary ---",
  sprintf("Shared genes used: %s", format(nrow(ranked_df), big.mark = ",")),
  sprintf("Shared drugs used: %s", format(length(shared_drug_names), big.mark = ",")),
  sprintf("Shared drug experiments: %s", format(length(shared_exp_ids), big.mark = ","))
)

writeLines(report_lines, report_file)
cat(sprintf("  - Report saved: %s\n", report_file))

cat("\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
cat("✅ Part 2B Complete - RData file created successfully!\n")
cat(paste(rep("=", 80), collapse=""), "\n", sep="")
