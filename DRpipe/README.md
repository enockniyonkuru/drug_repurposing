# DRpipe: Drug Repurposing Analysis R Package

**DRpipe** is a comprehensive R package for drug repurposing analysis using disease gene expression signatures and the Connectivity Map (CMap). The package provides tools for preprocessing, scoring, filtering, and visualization to identify candidate compounds that may reverse disease-associated transcriptional changes.

## Table of Contents

1. [Package Overview](#1-package-overview)
2. [Installation](#2-installation)
3. [Quick Start](#3-quick-start)
4. [Core Functions](#4-core-functions)
5. [Complete Workflow](#5-complete-workflow)
6. [Visualization Functions](#6-visualization-functions)
7. [Configuration and Pipeline](#7-configuration-and-pipeline)
8. [Data Requirements](#8-data-requirements)
9. [Examples](#9-examples)
10. [Package Information](#10-package-information)

---

## 1. Package Overview

### 1.1 Features

**Data Processing:**
- Clean and filter differential expression (DEG) tables
- Map gene symbols to Entrez IDs using g:Profiler
- Generate null score distributions using random gene sets
- Compute connectivity (reversal) scores against CMap profiles
- Calculate statistical significance (p-values and q-values)

**Analysis and Visualization:**
- Plot histograms of reversal score distributions
- Filter valid drug instances using CMap experiment metadata
- Create disease-drug connectivity heatmaps
- Summarize overlaps across multiple datasets
- Generate UpSet plots and intersection analyses
- Export annotated results to CSV and Excel formats

### 1.2 Package Structure

```
DRpipe/
├── DESCRIPTION              # Package metadata and dependencies
├── NAMESPACE               # Exported functions and imports
├── LICENSE                 # MIT license
├── README.md              # This file
├── renv.lock              # R environment lock file
├── R/                     # Core package functions
│   ├── processing.R       # Data processing functions
│   ├── analysis.R         # Analysis and visualization functions
│   ├── pipeline_processing.R  # Processing pipeline
│   ├── pipeline_analysis.R    # Analysis pipeline
│   ├── io_config.R        # I/O and configuration utilities
│   ├── cli.R              # Command line interface
│   └── zzz-imports.R      # Package imports
├── man/                   # Function documentation (auto-generated)
└── renv/                  # R environment management
```

---

## 2. Installation

### 2.1 Install from Local Directory

```r
# Install devtools if not available
if (!require("devtools")) install.packages("devtools")

# Install DRpipe from local directory
devtools::install("path/to/DRpipe")

# Load the package
library(DRpipe)
```

### 2.2 Install Dependencies

```r
# Install required packages
install.packages(c("dplyr", "tidyr", "tibble", "gprofiler2", "pbapply", 
                   "qvalue", "pheatmap", "UpSetR", "grid", "gplots", 
                   "reshape2"))

# Optional packages for enhanced functionality
install.packages(c("writexl", "yaml"))
```

### 2.3 Development Installation

For development purposes, you can source functions directly:

```r
source("R/processing.R")
source("R/analysis.R")
source("R/pipeline_processing.R")
source("R/pipeline_analysis.R")
```

---

## 3. Quick Start

### 3.1 Basic Workflow

```r
library(DRpipe)

# 1. Load CMap signatures
load("path/to/cmap_signatures.RData")

# 2. Clean disease signature
disease_clean <- clean_table(
  your_disease_data,
  gene_key = "SYMBOL",
  logFC_key = "log2FC",
  logFC_cutoff = 1,
  db_gene_list = cmap_signatures$V1
)

# 3. Separate up/down genes
genes_up <- disease_clean$GeneID[disease_clean$logFC > 0]
genes_down <- disease_clean$GeneID[disease_clean$logFC < 0]

# 4. Compute scores
rand_scores <- random_score(cmap_signatures, length(genes_up), length(genes_down))
disease_scores <- query_score(cmap_signatures, genes_up, genes_down)
results <- query(rand_scores, disease_scores, subset_comparison_id = "MyDisease")

# 5. Visualize
pl_hist_revsc(list(MyDisease = results))
```

### 3.2 Complete Pipeline

```r
# Run complete pipeline with configuration
run_dr(
  signatures_rdata = "path/to/cmap_signatures.RData",
  disease_path = "path/to/disease_signature.csv",
  out_dir = "results",
  verbose = TRUE,
  make_plots = TRUE
)
```

---

## 4. Core Functions

### 4.1 Data Processing Functions

#### `clean_table()`
Cleans and filters differential expression tables.

```r
clean_table(
  x,                    # Input data frame
  gene_key = "SYMBOL",  # Gene symbol column name
  logFC_key = "log2FC", # Log fold-change column name
  logFC_cutoff = 1,     # Minimum absolute log FC
  pval_key = NULL,      # P-value column (optional)
  pval_cutoff = 0.05,   # P-value threshold
  db_gene_list          # Reference gene universe
)
```

#### `random_score()`
Generates null distribution of connectivity scores.

```r
random_score(
  cmap_signatures,      # CMap signature matrix
  n_up,                 # Number of up-regulated genes
  n_down,               # Number of down-regulated genes
  N_PERMUTATIONS = 1e5, # Number of permutations
  seed = 123            # Random seed
)
```

#### `query_score()`
Computes connectivity scores for disease signature.

```r
query_score(
  cmap_signatures,      # CMap signature matrix
  dz_genes_up,          # Up-regulated gene vector
  dz_genes_down         # Down-regulated gene vector
)
```

#### `query()`
Assembles results with statistical significance.

```r
query(
  rand_cmap_scores,     # Null distribution
  dz_cmap_scores,       # Observed scores
  subset_comparison_id  # Dataset identifier
)
```

### 4.2 Scoring Functions

#### `cmap_score()`
Computes connectivity score between disease and drug signatures.

```r
cmap_score(
  sig_up,               # Up-regulated genes data frame
  sig_down,             # Down-regulated genes data frame
  drug_signature,       # Drug signature with ranks
  scale = FALSE         # Whether to scale scores
)
```

---

## 5. Complete Workflow

### 5.1 Step-by-Step Analysis

```r
library(DRpipe)

# Step 1: Load data
load("cmap_signatures.RData")
disease_data <- read.csv("disease_signature.csv")

# Step 2: Process disease signature
disease_clean <- clean_table(
  disease_data,
  gene_key = "SYMBOL",
  logFC_key = "log2FC",
  logFC_cutoff = 1,
  pval_key = "p_val_adj",
  pval_cutoff = 0.05,
  db_gene_list = cmap_signatures$V1
)

# Step 3: Separate gene sets
genes_up <- disease_clean$GeneID[disease_clean$logFC > 0]
genes_down <- disease_clean$GeneID[disease_clean$logFC < 0]

# Step 4: Generate null distribution
rand_scores <- random_score(
  cmap_signatures, 
  length(genes_up), 
  length(genes_down),
  N_PERMUTATIONS = 1000000,
  seed = 123
)

# Step 5: Compute connectivity scores
disease_scores <- query_score(cmap_signatures, genes_up, genes_down)

# Step 6: Calculate significance
results <- query(rand_scores, disease_scores, subset_comparison_id = "MyDisease")

# Step 7: Filter valid hits
cmap_experiments <- read.csv("cmap_drug_experiments_new.csv")
valid_instances <- read.csv("cmap_valid_instances.csv")
cmap_exp_valid <- merge(cmap_experiments, valid_instances, by = "id")
valid_hits <- valid_instance(results, cmap_exp_valid)
```

### 5.2 Using Configuration Files

```r
# Load configuration
cfg <- load_dr_config(profile = "default", config_file = "config.yml")

# Run pipeline with configuration
run_dr(
  signatures_rdata = cfg$paths$signatures,
  disease_path = cfg$paths$disease_file,
  cmap_meta_path = cfg$paths$cmap_meta,
  cmap_valid_path = cfg$paths$cmap_valid,
  out_dir = cfg$paths$out_dir,
  gene_key = cfg$params$gene_key,
  logfc_cols_pref = cfg$params$logfc_cols_pref,
  logfc_cutoff = cfg$params$logfc_cutoff,
  q_thresh = cfg$params$q_thresh,
  reversal_only = cfg$params$reversal_only,
  seed = cfg$params$seed
)
```

---

## 6. Visualization Functions

### 6.1 Score Distribution Plots

```r
# Histogram of reversal scores
pl_hist_revsc(list(Dataset1 = results1, Dataset2 = results2))

# CMap score plots
pl_cmap_score(results, title = "Connectivity Scores")
```

### 6.2 Heatmaps

```r
# Prepare heatmap data
heatmap_data <- prepare_heatmap(results_list, cmap_exp_valid)

# Generate heatmap
pl_heatmap(heatmap_data, title = "Drug-Disease Connectivity")
```

### 6.3 Overlap Analysis

```r
# Overlap plots
pl_overlap(combined_results)

# UpSet plots for intersections
upset_data <- prepare_upset_drug(results_list, cmap_exp_valid)
pl_upset(upset_data)
```

---

## 7. Configuration and Pipeline

### 7.1 Configuration File Format

Create a YAML configuration file:

```yaml
default:
  paths:
    signatures: "data/cmap_signatures.RData"
    disease_file: "data/disease_signature.csv"
    cmap_meta: "data/cmap_drug_experiments_new.csv"
    cmap_valid: "data/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    logfc_cutoff: 1
    q_thresh: 0.05
    reversal_only: true
    seed: 123
```

### 7.2 Pipeline Functions

```r
# Complete processing pipeline
run_dr_processing(config)

# Complete analysis pipeline
run_dr_analysis(config)

# Combined pipeline
run_dr(config_parameters...)
```

---

## 8. Data Requirements

### 8.1 Input Data Formats

**Disease Signature (CSV):**
```csv
SYMBOL,log2FC,p_val_adj
TP53,2.5,0.001
BRCA1,-1.8,0.01
MYC,3.2,0.0001
```

**CMap Signatures (RData):**
- Matrix with genes as rows, experiments as columns
- First column: Entrez gene IDs
- Subsequent columns: Ranked expression values

**CMap Metadata (CSV):**
- Experiment annotations
- Drug information
- Cell line details

### 8.2 Output Formats

**Statistical Results:**
- RData files with complete results
- CSV files with filtered hits
- Excel files with annotations

**Visualizations:**
- PDF plots (histograms, heatmaps, overlaps)
- PNG figures for presentations

---

## 9. Examples

### 9.1 Fibroid Analysis Example

```r
library(DRpipe)

# Load fibroid dataset
fibroid_data <- read.csv("CoreFibroidSignature_All_Datasets.csv")

# Process with specific parameters
fibroid_clean <- clean_table(
  fibroid_data,
  gene_key = "SYMBOL",
  logFC_key = "log2FC",
  logFC_cutoff = 1,
  pval_key = "p_val_adj",
  db_gene_list = cmap_signatures$V1
)

# Continue with standard workflow...
```

### 9.2 Multiple Dataset Analysis

```r
# Analyze multiple datasets
datasets <- c("dataset1.csv", "dataset2.csv", "dataset3.csv")

results_list <- lapply(datasets, function(file) {
  data <- read.csv(file)
  # Process each dataset...
})

# Compare results across datasets
pl_overlap(do.call(rbind, results_list))
```

---

## 10. Package Information

### 10.1 System Requirements

- **R** (≥ 4.1)
- **Operating System**: Windows, macOS, Linux
- **Memory**: Minimum 8GB RAM recommended for large datasets
- **Storage**: Sufficient space for CMap data (~2-5GB)

### 10.2 Dependencies

**Required packages:**
- dplyr, tidyr, tibble (data manipulation)
- gprofiler2 (gene mapping)
- pbapply (progress bars)
- qvalue (multiple testing correction)
- pheatmap (heatmaps)
- UpSetR, grid, gplots (visualizations)
- reshape2 (data reshaping)

**Optional packages:**
- writexl (Excel export)
- yaml (configuration files)

### 10.3 Citation

If you use DRpipe in your research, please cite:

```
[Citation information to be added]
```

### 10.4 Authors

- **Xinyu Tang** - *Author* - Xinyu.Tang@ucsf.edu
- **Enock Niyonkuru** - *Author, Maintainer* - enock.niyonkuru@ucsf.edu
- **Marina Sirota** - *Author* - Marina.Sirota@ucsf.edu

### 10.5 License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

### 10.6 Support

- **Documentation**: Use `?function_name` for function help
- **Vignettes**: `browseVignettes("DRpipe")`
- **Issues**: Report bugs and feature requests on GitHub
- **Contact**: Email the maintainer for support

### 10.7 Version Information

- **Current Version**: 0.1.0
- **R Version Required**: ≥ 4.1
- **Last Updated**: 2024

---

## Getting Help

For detailed function documentation:
```r
# View function help
?clean_table
?query_score
?pl_heatmap

# Browse all package documentation
help(package = "DRpipe")

# View package vignettes
browseVignettes("DRpipe")
