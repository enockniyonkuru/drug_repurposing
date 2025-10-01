# Drug Repurposing Analysis Pipeline

A comprehensive R package for drug repurposing analysis using disease gene expression signatures and the Connectivity Map (CMap) to identify potential therapeutic compounds.

This pipeline identifies existing drugs that could be repurposed for new therapeutic applications by analyzing their ability to reverse disease-associated gene expression patterns using the Connectivity Map database.

---

## Table of Contents
1. [Project Overview](#1-project-overview)  
2. [Repository Structure](#2-repository-structure)  
3. [Prerequisites](#3-prerequisites)  
4. [Installation](#4-installation)  
5. [Quick Start Guide](#5-quick-start-guide)  
6. [Three Main Functionalities](#6-three-main-functionalities)  
7. [Configuration](#7-configuration)  
8. [Data Formats](#8-data-formats)  
9. [Customizing for Your Dataset](#9-customizing-for-your-dataset)  
10. [Methodology](#10-methodology)  
11. [Citation & License](#11-citation--license)

---

## 1. Project Overview

**DRpipe** provides three main analysis modes:

1. **Single Profile Analysis** - Run end-to-end drug repurposing analysis with one parameter set
2. **Profile Comparison** - Compare results across multiple parameter configurations
3. **Sweep Mode** - Test multiple fold-change cutoffs simultaneously for robust drug discovery

The pipeline uses the Connectivity Map (CMap) database to find compounds that produce transcriptional signatures opposite to those observed in disease states.

---

## 2. Repository Structure

```
drug_repurposing/
├── README.md                          # This file
├── DRpipe/                            # R package
│   ├── DESCRIPTION, NAMESPACE, LICENSE
│   └── R/
│       ├── processing.R               # Core processing functions
│       ├── analysis.R                 # Plotting/summary helpers
│       ├── pipeline_processing.R      # DRP class + run_dr()
│       ├── pipeline_analysis.R        # DRA class + analyze_runs()
│       ├── io_config.R                # Config & IO helpers
│       ├── cli.R                      # Command-line interface
│       └── zzz-imports.R
├── scripts/                           # Analysis scripts
│   ├── config.yml                     # Configuration file
│   ├── load_execution_config.R        # Config management helper
│   ├── runall.R                       # Single profile analysis
│   ├── compare_profiles.R             # Profile comparison
│   ├── data/                          # Input data
│   └── results/                       # Output directory
└── dump/                              # Archived/development files
```

---

## 3. Prerequisites

**Required:**
- R ≥ 4.2
- Required packages (auto-installed with DRpipe):
  - `R6`, `dplyr`, `config`, `docopt`, `qvalue`, `pbapply`

**Optional (for visualizations):**
- `pheatmap`, `UpSetR`, `gplots`, `grid`

```r
install.packages(c("pheatmap", "UpSetR", "gplots"))
```

**Data:**
- CMap/LINCS reference signatures file (`cmap_signatures.RData`)
- Disease gene expression signature (CSV format)
- CMap metadata files (optional but recommended)

---

## 4. Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/enockniyonkuru/drug_repurposing.git
cd drug_repurposing
```

### Step 2: Install the Package

```r
# Install devtools if needed
install.packages("devtools", repos = "https://cloud.r-project.org")

# Build documentation and install DRpipe
devtools::document("DRpipe")
devtools::install("DRpipe")
```

### Step 3: Verify Installation

```r
library(DRpipe)
?run_dr
```

---

## 5. Quick Start Guide

### Minimal Setup

1. **Place your data** in `scripts/data/`:
   - Disease signature CSV
   - CMap signatures RData
   - CMap metadata files

2. **Edit configuration** in `scripts/config.yml`:
   ```yaml
   execution:
     runall_profile: "CoreFibroid_logFC_1"
   ```

3. **Run analysis** in RStudio:
   ```r
   setwd("scripts")
   source("runall.R")
   ```

Results will be saved to `scripts/results/<timestamp>/`

---

## 6. Three Main Functionalities

### 6.1 Single Profile Analysis

Run a complete drug repurposing analysis with one parameter configuration.

**Use Case:** Standard analysis with known parameters

**How to Run:**

```r
# In RStudio
setwd("scripts")
source("runall.R")
```

**Or from terminal:**
```bash
cd scripts
Rscript runall.R
```

**Configuration:**
```yaml
execution:
  runall_profile: "CoreFibroid_logFC_1"  # Profile to use
```

**Output:**
- `<dataset>_results.RData` - Complete results
- `<dataset>_hits_q<threshold>.csv` - Significant drug hits
- `img/` - Visualization plots
- `sessionInfo.txt` - Session details

---

### 6.2 Profile Comparison

Compare drug repurposing results across multiple parameter settings to understand how parameter choices affect results.

**Use Case:** Parameter sensitivity analysis, finding robust hits

**How to Run:**

```r
# In RStudio
setwd("scripts")
source("compare_profiles.R")
```

**Or from terminal:**
```bash
cd scripts
Rscript compare_profiles.R
```

**Configuration:**
```yaml
execution:
  compare_profiles: ["CoreFibroid_logFC_0.5", "CoreFibroid_logFC_1", "CoreFibroid_logFC_1.5"]
```

**What Gets Compared:**
- Drug hit counts across profiles
- Score distributions for each parameter setting
- Drug overlap between different stringency levels
- Statistical significance patterns

**Output Structure:**
```
results/profile_comparison/<timestamp>/
├── lenient_hits.csv                    # Individual profile results
├── default_hits.csv
├── strict_hits.csv
├── combined_profile_hits.csv           # All results combined
├── profile_summary_stats.csv           # Summary statistics
└── img/
    ├── profile_comparison_score_dist.jpg
    ├── profile_overlap_heatmap.jpg
    ├── profile_overlap_atleast2.jpg
    └── profile_upset.jpg
```

**Interpreting Results:**
- Drugs appearing in all profiles are high-confidence candidates
- Large differences between lenient/strict suggest parameter sensitivity
- Consistent score patterns indicate robust drug-disease relationships

---

### 6.3 Sweep Mode Analysis

Test multiple fold-change cutoffs simultaneously to identify robust drug candidates that are consistently found across different parameter settings.

**Use Case:** Comprehensive parameter exploration, reducing parameter bias

**How to Run:**

```r
# In RStudio
setwd("scripts")
source("runall.R")  # Uses sweep profile from config
```

**Configuration:**
```yaml
execution:
  runall_profile: "Sweep_CoreFibroid"  # Use sweep mode profile

Sweep_CoreFibroid:
  params:
    mode: "sweep"                      # Enable sweep mode
    sweep_cutoffs: null                # Auto-derive cutoffs
    sweep_auto_grid: true
    sweep_step: 0.1                    # Step size
    sweep_min_frac: 0.10               # Min 10% of genes
    sweep_min_genes: 150               # Min 150 genes
    robust_rule: "k_of_n"              # Filtering rule
    robust_k: 2                        # Must appear in ≥2 cutoffs
    aggregate: "median"                # Score aggregation method
```

**Key Parameters:**
- **`mode`**: Set to `"sweep"` to enable
- **`sweep_cutoffs`**: Array of cutoffs or `null` for auto-derivation
- **`robust_rule`**: `"all"` (all cutoffs) or `"k_of_n"` (k of n cutoffs)
- **`robust_k`**: Minimum cutoffs required for `"k_of_n"` rule
- **`aggregate`**: `"mean"`, `"median"`, or `"weighted_mean"`

**Output Structure:**
```
results/<timestamp>/
├── cutoff_0.5/                        # Individual cutoff results
│   └── <dataset>_hits_cutoff_0.5.csv
├── cutoff_1/
├── cutoff_1.5/
├── aggregate/                         # Final robust results
│   ├── robust_hits.csv               # Drugs passing robust filtering
│   └── cutoff_summary.csv            # Summary per cutoff
└── <dataset>_results.RData
```

**Interpreting Sweep Results:**
- **`n_support`**: Number of cutoffs where drug was significant (higher = more robust)
- **`aggregated_score`**: Combined connectivity score (more negative = better reversal)
- **`min_q`**: Best q-value across all cutoffs

**Advantages:**
- Reduces parameter sensitivity
- Identifies robust drug candidates
- Systematic parameter exploration
- Enhanced reproducibility

---

## 7. Configuration

### Configuration File Structure

The `scripts/config.yml` file controls all analysis parameters:

```yaml
# Execution settings
execution:
  runall_profile: "CoreFibroid_logFC_1"
  compare_profiles: ["CoreFibroid_logFC_0.5", "CoreFibroid_logFC_1", "CoreFibroid_logFC_1.5"]

# Profile definitions
CoreFibroid_logFC_1:
  paths:
    signatures: "data/cmap_signatures.RData"
    disease_file: "data/CoreFibroidSignature_All_Datasets.csv"
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
    mode: "single"
```

### Key Parameters

**Paths:**
- `signatures`: CMap signatures RData file
- `disease_file`: Disease signature CSV (or use `disease_dir` + `disease_pattern`)
- `cmap_meta`: CMap experiment metadata
- `cmap_valid`: Valid CMap instances
- `out_dir`: Output directory

**Analysis Parameters:**
- `gene_key`: Gene identifier column (default: "SYMBOL")
- `logfc_cols_pref`: Fold-change column prefix (default: "log2FC")
- `logfc_cutoff`: Absolute fold-change threshold
- `q_thresh`: FDR threshold for significance (default: 0.05)
- `reversal_only`: Keep only negative connectivity (default: true)
- `seed`: Random seed for reproducibility

**Mode Selection:**
- `mode`: `"single"` or `"sweep"`

### Creating Custom Profiles

Add new profiles to `config.yml`:

```yaml
my_custom_profile:
  paths:
    signatures: "data/cmap_signatures.RData"
    disease_file: "data/my_disease.csv"
    # ... other paths
  params:
    logfc_cutoff: 0.8        # Custom cutoff
    q_thresh: 0.01           # Custom threshold
    mode: "single"
```

Then use it:
```yaml
execution:
  runall_profile: "my_custom_profile"
```

---

## 8. Data Formats

### 8.1 Disease Signature CSV

**Required columns:**
- Gene identifier column (default: `SYMBOL`)
- One or more fold-change columns with shared prefix (default: `log2FC`)

**Example:**

| SYMBOL | log2FC_1 | log2FC_2 | pval    |
|--------|----------|----------|---------|
| TP53   | 2.5      | 2.3      | 0.001   |
| BRCA1  | -1.8     | -2.1     | 0.005   |
| MYC    | 3.2      | 3.0      | 0.0001  |

**Notes:**
- Multiple log2FC columns are averaged automatically
- `pval`/`padj` columns are optional

### 8.2 CMap Signatures

- `.RData` file containing reference signatures
- Must have gene identifiers (column `V1`, `gene`, or as values)

### 8.3 CMap Metadata (Optional)

- `cmap_drug_experiments_new.csv` - Experiment annotations
- `cmap_valid_instances.csv` - Curated flags, DrugBank IDs

---

## 9. Customizing for Your Dataset

### Step 1: Prepare Your Data

Place your disease signature CSV in `scripts/data/`

### Step 2: Update Configuration

Edit `scripts/config.yml`:

```yaml
my_disease:
  paths:
    disease_file: "data/my_disease_signature.csv"
    # ... other paths
  params:
    gene_key: "SYMBOL"           # Or "ENSEMBL", "ENTREZ", etc.
    logfc_cols_pref: "log2FC"    # Or "fc_", "logFC_", etc.
    logfc_cutoff: 1.0            # Adjust as needed
```

### Step 3: Run Analysis

```yaml
execution:
  runall_profile: "my_disease"
```

```r
setwd("scripts")
source("runall.R")
```

### Common Customizations

**Different gene identifiers:**
```yaml
params:
  gene_key: "ENSEMBL"  # Instead of "SYMBOL"
```

**Different fold-change prefix:**
```yaml
params:
  logfc_cols_pref: "fc_"  # Matches fc_1, fc_2, etc.
```

**Multiple disease files:**
```yaml
paths:
  disease_dir: "data/diseases/"
  disease_pattern: ".*_signature\\.csv"
```

---

## 10. Methodology

### Pipeline Steps

1. **Disease Signature Preparation**
   - Load differential expression results
   - Average multiple fold-change columns
   - Filter by absolute fold-change threshold
   - Map to reference gene universe

2. **Connectivity Scoring**
   - Compare disease up/down gene sets to CMap profiles
   - Compute reversal scores for each drug-disease pair

3. **Statistical Analysis**
   - Generate null distributions via random sampling
   - Calculate empirical p-values
   - Compute q-values (FDR correction)

4. **Validation & Annotation**
   - Join with CMap experiment metadata
   - Filter to valid instances
   - Summarize per-drug results
   - Generate visualizations

### Scoring Method

The pipeline uses connectivity scoring to measure how well a drug reverses the disease signature:
- Negative scores indicate reversal (desired)
- Positive scores indicate similarity (undesired)
- Statistical significance determined by permutation testing

---

## 11. Citation & License

### Authors

- **Xinyu Tang** - *Author* - [Xinyu.Tang@ucsf.edu](mailto:Xinyu.Tang@ucsf.edu)
- **Enock Niyonkuru** - *Author, Maintainer* - [enock.niyonkuru@ucsf.edu](mailto:enock.niyonkuru@ucsf.edu)
- **Marina Sirota** - *Author* - [Marina.Sirota@ucsf.edu](mailto:Marina.Sirota@ucsf.edu)

### License

MIT License - see [`DRpipe/LICENSE`](DRpipe/LICENSE)

### Citation

*Citation information will be added upon publication*

---

## Support

For questions or issues:
- Open an issue on GitHub
- Contact the maintainers via email

---

**Last Updated:** January 2025
