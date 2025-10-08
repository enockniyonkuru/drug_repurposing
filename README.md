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
6. [Working Directory Setup](#6-working-directory-setup)
7. [Understanding Configuration](#7-understanding-configuration)
8. [Three Main Functionalities](#8-three-main-functionalities)  
9. [Running via Shiny App (GUI Alternative)](#9-running-via-shiny-app-gui-alternative)
10. [Configuration Reference](#10-configuration-reference)  
11. [Data Formats](#11-data-formats)  
12. [Customizing for Your Dataset](#12-customizing-for-your-dataset)  
13. [Advanced Topics](#13-advanced-topics)
14. [Troubleshooting](#14-troubleshooting)
15. [Methodology](#15-methodology)  
16. [Citation & License](#16-citation--license)

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

See [Section 3.1: Required Data Files](#31-required-data-files) for download instructions.

---

### 3.1 Required Data Files

The pipeline requires several data files to run. Due to file size limitations, large files are hosted externally.

#### Files Included in Repository

The following small data files are already included in `scripts/data/`:

1. **cmap_drug_experiments_new.csv** (831 KB)
   - CMap experiment metadata
   - Contains drug names, cell lines, and experimental conditions

2. **cmap_valid_instances.csv** (41 KB)
   - Curated list of valid CMap instances
   - Includes DrugBank IDs and validation flags

3. **CoreFibroidSignature_All_Datasets.csv** (270 KB)
   - Example disease signature for fibroid analysis
   - Contains gene symbols and log2 fold-change values

#### Large Files (Download Required)

The following files are **required** but must be downloaded separately:

1. **cmap_signatures.RData** (232 MB)
   - CMap reference signatures database
   - **Required for pipeline execution**

2. **gene_id_conversion_table.tsv** (4.5 MB)
   - Gene identifier conversion table
   - Optional but recommended for gene mapping

#### Download Instructions

**All required data files are available on Google Drive:**

🔗 **[Download Data Files](https://drive.google.com/drive/folders/1LvKiT0u3DGf5sW5bYVJk7scbM5rLmBx-?usp=sharing)**

**Steps:**
1. Visit the Google Drive link above
2. Download the following files:
   - `cmap_signatures.RData`
   - `gene_id_conversion_table.tsv` (optional)
3. Place downloaded files in the `scripts/data/` directory

**Verify your data directory:**
```bash
ls -lh scripts/data/
```

You should see:
- ✓ cmap_drug_experiments_new.csv
- ✓ cmap_valid_instances.csv
- ✓ CoreFibroidSignature_All_Datasets.csv
- ✓ cmap_signatures.RData (after download)
- ✓ gene_id_conversion_table.tsv (optional, after download)

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
   - CMap signatures RData (download from Google Drive)
   - CMap metadata files

2. **Edit configuration** in `scripts/config.yml`:
   ```yaml
   execution:
     runall_profile: "CoreFibroid_logFC_1"  # Use the name of your chosen profile
   ```
   
   **What is a profile name?** 
   - A profile name (e.g., "CoreFibroid_logFC_1") is a **user-defined configuration label** in `config.yml`
   - It is NOT a file name - it's an identifier for a specific analysis setup
   - The profile defines which input file to use, what parameters to apply, etc.
   - See [Section 7: Understanding Configuration](#7-understanding-configuration) for details


3. **Run analysis** in RStudio:
   ```r
   # IMPORTANT: Set working directory to scripts folder
   setwd("/path/to/drug_repurposing/scripts")
   
   # Verify you're in the correct directory
   getwd()  # Should show: .../drug_repurposing/scripts
   
   # Run the analysis
   source("runall.R")
   ```

Results will be saved to `scripts/results/<profile_name>_<timestamp>/`

---

## 6. Working Directory Setup

**The pipeline requires two steps with different working directories:**

### Step 1 (Terminal): Clone and Install

Run from the repository root:

```bash
cd /path/to/drug_repurposing
```

Then install the package in R:
```r
devtools::document("DRpipe")
devtools::install("DRpipe")
```

### Step 2 (R/RStudio): Run Analysis

**IMPORTANT**: Set working directory to the `scripts/` folder:

```r
# Option 1: Absolute path (most reliable)
setwd("/full/path/to/drug_repurposing/scripts")

# Option 2: Relative to home directory
setwd("~/Desktop/drug_repurposing/scripts")

# Option 3: Using RStudio
# Session > Set Working Directory > Choose Directory
# Navigate to: drug_repurposing/scripts

# Verify you're in the correct location
getwd()  # Should end with: .../drug_repurposing/scripts

# Check that config file exists
file.exists("config.yml")  # Should return TRUE

# Check that data directory exists
dir.exists("data")  # Should return TRUE

# Then run the analysis
source("runall.R")
```

**Why this matters**: The configuration file (`config.yml`) uses relative paths (e.g., `data/`, `results/`) that are relative to the `scripts/` directory.

---

## 7. Understanding Configuration

### Profile Names Explained

**Profile names are user-defined configuration identifiers**, not file names. They serve as:

1. **Configuration Labels**: Each profile in `config.yml` defines a complete analysis setup
2. **Analysis Identifiers**: Used to select which configuration to run
3. **Output Naming**: Incorporated into output folder names for traceability

**Example Profile Breakdown:**
```yaml
CoreFibroid_logFC_1:        # ← Profile name (you choose this)
  paths:
    disease_file: "data/CoreFibroidSignature_All_Datasets.csv"  # ← Input file
  params:
    logfc_cutoff: 1         # ← Analysis parameter
```

**How it works:**
- `CoreFibroid_logFC_1` is the **profile name** you reference in `execution:`
- The actual input file is specified in `paths: disease_file:`
- Output folders will be named: `CoreFibroid_logFC_1_20250107-183045/`

**Naming Convention (Recommended):**
- Use descriptive names: `<Dataset>_<KeyParameter>_<Value>`
- Examples: `Endothelial_logFC_0.5`, `Fibroid_Strict`, `MyDisease_Test1`
- Must match exactly when referenced in `execution: runall_profile:`

### Configuration Structure

#### The "default" Profile (Technical Requirement)

```yaml
default:
  paths:
    signatures: "data/cmap_signatures.RData"
    # ... other settings
  params:
    logfc_cutoff: 0.5
```

**Purpose**: 
- Required by the R `config` package (technical requirement)
- Serves as a **fallback** if no profile is specified
- **You typically don't use this directly**
- **Leave unchanged** unless you have specific reasons

#### Custom Profiles (What You Actually Use)

```yaml
CoreFibroid_logFC_1:      # ← Your actual analysis profile
  paths:
    disease_file: "data/CoreFibroidSignature_All_Datasets.csv"
  params:
    logfc_cutoff: 1.0
```

**Purpose**:
- These are your **actual analysis configurations**
- You reference these in `execution: runall_profile:`
- Each represents a specific analysis setup

---

## 8. Three Main Functionalities

### 8.1 Single Profile Analysis

Run a complete drug repurposing analysis with one parameter configuration.

**Use Case:** Standard analysis with known parameters

**How to Run:**

```r
# In RStudio
setwd("/path/to/drug_repurposing/scripts")
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

### 8.2 Profile Comparison

Compare drug repurposing results across multiple parameter settings to understand how parameter choices affect results.

**Use Case:** Parameter sensitivity analysis, finding robust hits

**How to Run:**

```r
# In RStudio
setwd("/path/to/drug_repurposing/scripts")
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

#### Two Use Cases for compare_profiles

**Use Case 1: Same Data, Different Parameters (Parameter Sensitivity)**

```yaml
execution:
  compare_profiles: ["Lenient", "Standard", "Strict"]

Lenient:
  paths:
    disease_file: "data/my_data.csv"  # ← Same file
  params:
    logfc_cutoff: 0.5  # ← Different cutoff

Standard:
  paths:
    disease_file: "data/my_data.csv"  # ← Same file
  params:
    logfc_cutoff: 1.0  # ← Different cutoff

Strict:
  paths:
    disease_file: "data/my_data.csv"  # ← Same file
  params:
    logfc_cutoff: 1.5  # ← Different cutoff
```

**Result**: Compares how parameter choices affect results for ONE dataset

**Use Case 2: Different Data, Same Parameters (Cross-Dataset Comparison)**

```yaml
execution:
  compare_profiles: ["Dataset1", "Dataset2", "Dataset3"]

Dataset1:
  paths:
    disease_file: "data/dataset1.csv"  # ← Different file
  params:
    logfc_cutoff: 1.0  # ← Same parameters

Dataset2:
  paths:
    disease_file: "data/dataset2.csv"  # ← Different file
  params:
    logfc_cutoff: 1.0  # ← Same parameters

Dataset3:
  paths:
    disease_file: "data/dataset3.csv"  # ← Different file
  params:
    logfc_cutoff: 1.0  # ← Same parameters
```

**Result**: Compares results across MULTIPLE datasets with consistent parameters

**Important Notes:**
- `runall_profile:` accepts ONE profile name only
- `compare_profiles:` accepts an ARRAY of profile names
- Each profile runs as a **separate analysis**
- Results are then **compared and visualized together**
- This is NOT parallel processing (runs sequentially)
- Use `compare_profiles.R` script, not `runall.R`

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

### 8.3 Sweep Mode Analysis

Test multiple fold-change cutoffs simultaneously to identify robust drug candidates that are consistently found across different parameter settings.

**Use Case:** Comprehensive parameter exploration, reducing parameter bias

**How to Run:**

```r
# In RStudio
setwd("/path/to/drug_repurposing/scripts")
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

## 9. Running via Shiny App (GUI Alternative)

For users who prefer a graphical interface over command-line tools, the DRpipe pipeline can also be run through an interactive Shiny web application.

### Overview

The Shiny app provides a user-friendly way to:
- Upload disease gene expression data through a web form
- Configure analysis parameters using interactive controls
- Run single or comparative analyses with a button click
- View and download results directly in your browser
- Generate interactive visualizations

### Quick Start

**Step 1: Install the DRpipe package** (if not already done)
```r
devtools::document("DRpipe")
devtools::install("DRpipe")
```

**Step 2: Navigate to the Shiny app directory**
```r
setwd("path/to/drug_repurposing/shiny_app")
```

**Step 3: Launch the app**
```r
# Option 1: Direct launch
shiny::runApp()

# Option 2: Using helper script
source("run.R")
```

**Step 4: Use the app**
1. Choose analysis type (Single or Comparative)
2. Upload your disease signature CSV or load example data
3. Configure parameters through the interface
4. Click "Run Analysis"
5. View results and download outputs

### Features

**Analysis Types:**
- **Single Analysis**: Run with one parameter configuration
- **Comparative Analysis**: Compare results across multiple configurations

**Capabilities:**
- Full sweep mode support with parameter customization
- Real-time progress tracking
- Interactive result tables with filtering and sorting
- Dynamic visualizations (bar charts, histograms, volcano plots, heatmaps)
- CSV export of results

### When to Use the Shiny App

**Use the Shiny app when:**
- You prefer graphical interfaces over command-line tools
- You want to quickly test different parameters
- You're new to R or the DRpipe pipeline
- You need to demonstrate results to collaborators

**Use the command-line pipeline when:**
- You need to process many datasets in batch
- You want to integrate into automated workflows
- You need fine-grained control over all parameters
- You're running analyses on a remote server

### Documentation

For detailed Shiny app documentation, including:
- Data format requirements
- Parameter descriptions
- Troubleshooting tips
- Example datasets

See: **[shiny_app/README.md](shiny_app/README.md)**

---

## 10. Configuration Reference

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

### Parameter Reference Guide

#### Core Parameters

| Parameter | Type | Recommended Values | Description |
|-----------|------|-------------------|-------------|
| `logfc_cutoff` | numeric | 0.5 - 2.0 | Absolute log2 fold-change threshold. Higher = more stringent. **Typical: 1.0** |
| `pval_key` | string or null | `"p_val_adj"`, `"FDR"`, `null` | Column name for p-values. Set to `null` to skip p-value filtering |
| `pval_cutoff` | numeric | 0.01 - 0.1 | P-value threshold (only used if `pval_key` is set). **Typical: 0.05** |
| `q_thresh` | numeric | 0.01 - 0.1 | FDR threshold for drug significance. **Typical: 0.05** |
| `reversal_only` | boolean | `true` / `false` | Keep only drugs with negative connectivity (reversal). **Recommended: true** |
| `seed` | integer | any | Random seed for reproducibility. **Typical: 123** |

#### Gene Identifier Parameters

| Parameter | Type | Options | Description |
|-----------|------|---------|-------------|
| `gene_key` | string | `"SYMBOL"`, `"ENSEMBL"`, `"ENTREZ"` | Column name containing gene identifiers in your input file |
| `logfc_cols_pref` | string | `"log2FC"`, `"logFC_"`, `"fc_"` | Prefix for fold-change columns. Matches columns like `log2FC_1`, `log2FC_2` |

#### Multi-Column Handling

| Parameter | Type | Options | Description |
|-----------|------|---------|-------------|
| `combine_log2fc` | string | `"average"`, `"median"`, `"first"` | **How to combine multiple log2FC columns**. If your data has `log2FC_1`, `log2FC_2`, `log2FC_3`, this determines how they're merged into a single value. **Recommended: "average"** |

**Example**: If you have three replicates with log2FC values [2.1, 2.3, 2.0]:
- `"average"`: Uses 2.13 (mean)
- `"median"`: Uses 2.1 (middle value)
- `"first"`: Uses 2.1 (first column only)

#### Sweep Mode Parameters (Advanced)

| Parameter | Type | Recommended Values | Description |
|-----------|------|-------------------|-------------|
| `mode` | string | `"single"` / `"sweep"` | Analysis mode. Use `"sweep"` for multi-cutoff analysis |
| `sweep_cutoffs` | array or null | `[0.5, 1.0, 1.5]` or `null` | Specific cutoffs to test. Use `null` for auto-generation |
| `sweep_step` | numeric | 0.1 - 0.5 | Step size for auto-generated cutoffs. **Typical: 0.1** |
| `sweep_min_genes` | integer | 100 - 300 | Minimum genes required per cutoff. **Typical: 150** |
| `robust_rule` | string | `"all"` / `"k_of_n"` | Drug must appear in all cutoffs or k of n cutoffs |
| `robust_k` | integer | 2 - 5 | Minimum cutoffs required (for `"k_of_n"` rule) |
| `aggregate` | string | `"mean"`, `"median"`, `"weighted_mean"` | How to combine scores across cutoffs |

---

## 10. Data Formats

### 10.1 Disease Signature CSV

**Required columns:**
- Gene identifier column (default: `SYMBOL`)
- One or more fold-change columns with shared prefix (default: `log2FC`)

**Example:**

| SYMBOL | log2FC_1 | log2FC_2 | p_val_adj |
|--------|----------|----------|-----------|
| TP53   | 2.5      | 2.3      | 0.001     |
| BRCA1  | -1.8     | -2.1     | 0.005     |
| MYC    | 3.2      | 3.0      | 0.0001    |

**Notes:**
- Multiple log2FC columns are combined based on `combine_log2fc` parameter (default: average)
- P-value columns (e.g., `p_val_adj`, `FDR`, `pvalue`) are optional but can be used for filtering
- To enable p-value filtering, set `pval_key` to your column name in the config

### 10.2 CMap Signatures

- `.RData` file containing reference signatures
- Must have gene identifiers (column `V1`, `gene`, or as values)

### 10.3 CMap Metadata (Optional)

- `cmap_drug_experiments_new.csv` - Experiment annotations
- `cmap_valid_instances.csv` - Curated flags, DrugBank IDs

---

## 11. Customizing for Your Dataset

### Quick Start: Customizing for Your Data

#### Minimal Required Changes (3 steps)

**Step 1**: Create your profile (copy an existing one)
```yaml
MyAnalysis:  # ← Choose your profile name
  paths:
    disease_file: "data/my_disease_data.csv"  # ← Your input file
    signatures: "data/cmap_signatures.RData"   # ← Keep as-is
    cmap_meta: "data/cmap_drug_experiments_new.csv"  # ← Keep as-is
    cmap_valid: "data/cmap_valid_instances.csv"      # ← Keep as-is
    out_dir: "results"  # ← Keep as-is
```

**Step 2**: Update parameters for your data
```yaml
  params:
    gene_key: "SYMBOL"        # ← Match YOUR gene column name
    logfc_cols_pref: "log2FC" # ← Match YOUR fold-change column prefix
    logfc_cutoff: 1.0         # ← Adjust threshold as needed
    pval_key: null            # ← Set to your p-value column or null
    # ... other params can use defaults
```

**Step 3**: Reference your profile
```yaml
execution:
  runall_profile: "MyAnalysis"  # ← Use your profile name
```

#### What NOT to Change

**Leave these as-is** (unless you have specific reasons):
- `default:` section (technical requirement)
- CMap reference file paths (`signatures`, `cmap_meta`, `cmap_valid`)
- `out_dir: "results"` (unless you want a different output location)
- Most advanced parameters (unless you understand their purpose)

#### Full Customization Checklist

- [ ] **Profile name**: Choose descriptive name
- [ ] **disease_file**: Path to your CSV file
- [ ] **gene_key**: Column name with gene identifiers
- [ ] **logfc_cols_pref**: Prefix for your fold-change columns
- [ ] **logfc_cutoff**: Threshold appropriate for your data
- [ ] **pval_key**: P-value column name (or null)
- [ ] **execution: runall_profile**: Reference your profile name

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

**Enable p-value filtering:**
```yaml
params:
  pval_key: "p_val_adj"    # Column name for p-values
  pval_cutoff: 0.05        # P-value threshold
```

**Note:** P-value filtering is applied BEFORE fold-change filtering. Set `pval_key: null` to disable.

**Multiple disease files:**
```yaml
paths:
  disease_dir: "data/diseases/"
  disease_pattern: ".*_signature\\.csv"
```

---

## 12. Advanced Topics

### 12.1 Working with Multiple Input Files

#### Option 1: Multiple Profiles (Recommended for Different Parameters)

Define multiple profiles in `config.yml` and switch between them:

```yaml
execution:
  runall_profile: "Dataset1_Analysis"  # ← Change this to switch profiles

Dataset1_Analysis:
  paths:
    disease_file: "data/dataset1.csv"
  params:
    logfc_cutoff: 1.0

Dataset2_Analysis:
  paths:
    disease_file: "data/dataset2.csv"
  params:
    logfc_cutoff: 1.5
```

**To run different analyses**: Edit only the `runall_profile:` line, then re-run `source("runall.R")`

#### Option 2: Directory Pattern Matching (For Batch Processing)

Process multiple files automatically using pattern matching:

```yaml
MyBatchAnalysis:
  paths:
    disease_dir: "data/my_datasets/"      # Directory containing files
    disease_pattern: ".*_signature\\.csv"  # Regex pattern to match files
  params:
    logfc_cutoff: 1.0
```

This will process ALL files matching the pattern in one run.

#### Option 3: Profile Comparison Mode

See [Section 8.2: Profile Comparison](#82-profile-comparison) for details.

### 12.2 Organizing Multiple Projects

#### Strategy 1: Subdirectories (Recommended)

```
scripts/data/
├── project1/
│   ├── disease_signature.csv
│   └── metadata.txt
├── project2/
│   ├── disease_signature.csv
│   └── metadata.txt
└── shared/
    ├── cmap_signatures.RData
    ├── cmap_drug_experiments_new.csv
    └── cmap_valid_instances.csv
```

**Configuration:**
```yaml
Project1_Analysis:
  paths:
    disease_file: "data/project1/disease_signature.csv"
    signatures: "data/shared/cmap_signatures.RData"
```

#### Strategy 2: Descriptive Filenames

```
scripts/data/
├── fibroid_study_2024_signature.csv
├── endothelial_pilot_signature.csv
├── cancer_validation_signature.csv
├── cmap_signatures.RData
└── cmap_drug_experiments_new.csv
```

**Configuration:**
```yaml
Fibroid2024:
  paths:
    disease_file: "data/fibroid_study_2024_signature.csv"
```

#### Strategy 3: Separate Results Directories

```yaml
Project1:
  paths:
    disease_file: "data/project1_data.csv"
    out_dir: "results/project1"  # ← Project-specific output

Project2:
  paths:
    disease_file: "data/project2_data.csv"
    out_dir: "results/project2"  # ← Project-specific output
```

**Results structure:**
```
scripts/results/
├── project1/
│   └── Project1_20250107-183045/
└── project2/
    └── Project2_20250107-184523/
```

#### Best Practices

1. **Use descriptive names**: Include project, date, or version in filenames
2. **Separate outputs**: Use different `out_dir` for each project
3. **Document**: Keep a README in each project subdirectory
4. **Version control**: Consider using git to track configuration changes
5. **Backup**: Keep original data files in a separate backup location

---

## 13. Troubleshooting

### 13.1 Verifying cmap_signatures.RData

If you encounter errors loading `cmap_signatures.RData`:

```r
# Test if file loads correctly
test_load <- try(load("scripts/data/cmap_signatures.RData"), silent = TRUE)

if (inherits(test_load, "try-error")) {
  cat("ERROR: File appears corrupted. Please re-download.\n")
} else {
  cat("SUCCESS: File loaded correctly.\n")
  cat("Objects loaded:", test_load, "\n")
}
```

**If corrupted**:
1. Delete the existing file
2. Re-download from [Google Drive link](https://drive.google.com/drive/folders/1LvKiT0u3DGf5sW5bYVJk7scbM5rLmBx-?usp=sharing)
3. Verify file size: Should be ~232 MB
4. Check MD5 checksum if available

### 13.2 Understanding gene_key Parameter

The `gene_key` parameter specifies **which column in YOUR disease signature file** contains gene identifiers:

```yaml
params:
  gene_key: "SYMBOL"  # ← Column name in YOUR input CSV
```

**Common scenarios:**

| Your CSV has | Use gene_key |
|--------------|--------------|
| Column named "SYMBOL" | `gene_key: "SYMBOL"` |
| Column named "gene_name" | `gene_key: "gene_name"` |
| Column named "Gene" | `gene_key: "Gene"` |
| Column named "ENSEMBL" | `gene_key: "ENSEMBL"` |

**To check your column names:**
```r
# Read your disease signature file
data <- read.csv("scripts/data/your_file.csv")
colnames(data)  # Shows all column names
```

### 13.3 Common Issues

**Issue**: "Cannot find config.yml"
- **Solution**: Ensure you're in the `scripts/` directory: `setwd("<your_path>/drug_repurposing/scripts")`
- **Example**: `setwd("~/Desktop/drug_repurposing/scripts")` or `setwd("/Users/username/projects/drug_repurposing/scripts")`

**Issue**: "Disease file not found"
- **Solution**: Check that the path in `disease_file:` is relative to `scripts/` directory

**Issue**: "No genes matched" or "gene_key column not found"
- **Solution**: Verify `gene_key` matches your actual column name
- **Common cause**: Missing column headers in your CSV file

**Issue**: "P-value column not found"
- **Solution**: Set `pval_key: null` if you don't have p-values, or verify the column name

**Issue**: "Error reading disease signature file" or unexpected results
- **Solution**: **Verify your CSV has column headers!** This is a very common issue.
- **How to check**:
  ```r
  # Read first few lines of your file
  data <- read.csv("scripts/data/your_file.csv", nrows = 5)
  head(data)
  colnames(data)  # Should show proper column names, not "V1", "V2", etc.
  ```
- **If headers are missing**: Add them manually to your CSV file before running the pipeline
- **Example header row**: `SYMBOL,log2FC_1,log2FC_2,p_val_adj`

### 13.4 CSV File Format Checklist

Before running the pipeline, verify your disease signature CSV file:

- [ ] **Has column headers** (first row contains column names, not data)
- [ ] **Gene identifier column** matches your `gene_key` parameter
- [ ] **Fold-change columns** match your `logfc_cols_pref` parameter
- [ ] **No special characters** in column names (use underscores instead of spaces)
- [ ] **Consistent formatting** (no mixed delimiters, proper CSV format)

**Quick verification:**
```r
# Load your file
data <- read.csv("scripts/data/your_file.csv")

# Check structure
str(data)  # Should show proper column names and data types

# Verify required columns exist
"SYMBOL" %in% colnames(data)  # Should be TRUE (or your gene_key value)
any(grepl("^log2FC", colnames(data)))  # Should be TRUE (or your logfc_cols_pref)
```

---

## 14. Methodology

### Pipeline Steps

1. **Disease Signature Preparation**
   - Load differential expression results
   - Combine multiple fold-change columns (based on `combine_log2fc` parameter)
   - Filter by p-value threshold (optional, if `pval_key` is specified)
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

## 15. Citation & License

### Authors

- **Enock Niyonkuru** - *Author, Maintainer* - [enock.niyonkuru@ucsf.edu](mailto:enock.niyonkuru@ucsf.edu)
- **Xinyu Tang** - *Author* - [Xinyu.Tang@ucsf.edu](mailto:Xinyu.Tang@ucsf.edu)
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
