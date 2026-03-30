# CREEDS Manual Disease Signatures - Filtered to Shared Genes

## Overview
This folder contains disease signatures from the CREEDS manual dataset that have been filtered to include **only genes present in both CMAP and Tahoe** platforms.

## Filtering Process
- **Source Directory**: `creeds_manual_disease_signatures_standardised/`
- **Shared Genes Reference**: `shared_genes_cmap_tahoe.csv` (12,556 genes)
- **Filtering Method**: Case-insensitive gene symbol matching

## Contents
- **233 filtered disease signature CSV files** (one per disease)
- **filtering_summary.csv**: Comprehensive summary showing row counts before and after filtering

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Diseases | 233 |
| Total Genes (Standardised) | 97,519 |
| Total Genes (After Filtering) | 75,926 |
| Total Genes Removed | 21,593 |
| **Average Retention Rate** | **79.65%** |
| Median Retention Rate | 79.79% |
| Min Retention Rate | 0.00% (leukemia) |
| Max Retention Rate | 100.00% (cervix_carcinoma, prolactinoma) |

## File Structure
Each filtered CSV file maintains the same structure as the standardised version:
- `gene_symbol`: Gene name
- `logfc_dz:*`: Log fold change for experiment
- `mean_logfc`: Mean log fold change
- `median_logfc`: Median log fold change
- `common_experiment`: Experiment value
- `organism`: Source organism (human)
- `signature_type`: UP or DOWN regulation

## Usage
These filtered signatures ensure that all downstream analyses comparing disease signatures with drug profiles (from CMAP or Tahoe) are performed on the **common gene space**, enabling fair and valid comparisons.

## Quality Notes
- 2 diseases (cervix_carcinoma, prolactinoma) retained 100% of genes
- 1 disease (leukemia) had 0% retention (18 genes, none in shared space)
- Most diseases (median) retained ~80% of their genes
- High retention rates indicate good overlap between disease gene space and drug platform gene coverage

---
**Generated**: December 10, 2025
**Script**: `filter_disease_signatures_shared_genes.py`
