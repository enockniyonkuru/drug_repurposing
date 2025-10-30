# Drug Repurposing Analysis Pipeline

A comprehensive R package and Shiny application for drug repurposing analysis using disease gene expression signatures and the Connectivity Map (CMap) to identify potential therapeutic compounds.

This pipeline identifies existing drugs that could be repurposed for new therapeutic applications by analyzing their ability to reverse disease-associated gene expression patterns using the Connectivity Map database.

---

## Table of Contents
1. [What This Repository Does](#1-what-this-repository-does)
2. [Core Functionalities](#2-core-functionalities)
3. [Two Ways to Use This Repository](#3-two-ways-to-use-this-repository)
4. [Getting Started](#4-getting-started)
5. [Prerequisites & Installation](#5-prerequisites--installation)
6. [Using the R Package](#6-using-the-r-package)
7. [Using the Shiny App](#7-using-the-shiny-app)
8. [Repository Structure](#8-repository-structure)
9. [Configuration Reference](#9-configuration-reference)
10. [Data Formats](#10-data-formats)
11. [Troubleshooting](#11-troubleshooting)
12. [Methodology](#12-methodology)
13. [Citation & License](#13-citation--license)

---

## 1. What This Repository Does

**DRpipe** is a drug repurposing analysis pipeline that helps researchers identify existing drugs that could be repurposed for new therapeutic applications. The pipeline:

- **Analyzes disease gene expression signatures** to identify up-regulated and down-regulated genes
- **Compares disease signatures against the Connectivity Map (CMap)** database of drug-induced gene expression profiles
- **Identifies drugs that reverse disease signatures** (negative connectivity scores indicate therapeutic potential)
- **Provides statistical significance testing** using permutation-based methods and FDR correction
- **Generates comprehensive visualizations** including heatmaps, score distributions, and overlap analyses
- **Supports multiple analysis modes** for robust drug discovery and parameter sensitivity testing

**Key Concept**: The pipeline finds drugs whose gene expression effects are *opposite* to the disease state, suggesting they may reverse the disease phenotype.

---

## 2. Core Functionalities

### 2.1 Single Analysis

Run a complete drug repurposing analysis with one parameter configuration.

**Two Modes:**

#### Single Cutoff Mode
- Uses one fold-change threshold to define disease signature
- Fast, straightforward analysis
- Best when you know your optimal parameters

#### Sweep Mode
- Tests multiple fold-change thresholds simultaneously
- Identifies robust drug candidates across parameter ranges
- Reduces parameter bias and increases confidence in results
- Aggregates results using median or mean scores
- Just be aware that this can take up to an hour depending on processing power of your laptop

**Use Cases:**
- Initial exploration of a disease dataset
- Standard analysis with known parameters
- Comprehensive parameter exploration (sweep mode)

---

### 2.2 Comparative Analysis

Compare drug repurposing results across multiple parameter configurations or datasets.

**Two Use Cases:**

#### Parameter Sensitivity Analysis
- Same disease data, different parameters (e.g., different fold-change cutoffs)
- Understand how parameter choices affect results
- Identify robust hits that appear across multiple settings

#### Cross-Dataset Comparison
- Different disease datasets, same parameters
- Compare drug candidates across related conditions
- Find drugs with broad therapeutic potential

**Use Cases:**
- Validating results across parameter ranges
- Comparing multiple disease subtypes
- Finding drugs that work across related conditions
- Publication-ready comparative analyses

---

## 3. Two Ways to Use This Repository

You can interact with this repository in two ways, depending on your preferences and needs:

### 3.1 R Package (DRpipe)

**Best for:**
- Batch processing multiple datasets
- Integration into automated workflows
- Fine-grained control over all parameters
- Programmatic access to all functions
- Running on remote servers or HPC clusters

**Access to Core Functionalities:**

| Functionality | How to Access |
|--------------|---------------|
| **Single Analysis - Single Cutoff** | `source("scripts/runall.R")` with `mode: "single"` in config |
| **Single Analysis - Sweep Mode** | `source("scripts/runall.R")` with `mode: "sweep"` in config |
| **Comparative Analysis** | `source("scripts/compare_profiles.R")` with multiple profiles |

**Environments:**
- **RStudio**: Interactive development environment (recommended for beginners)
- **VS Code**: With R extension for code editing and execution
- **Terminal**: Command-line execution with `Rscript`

---

### 3.2 Shiny App (Interactive GUI)

**Best for:**
- Users who prefer graphical interfaces
- Quick parameter testing and exploration
- Demonstrating results to collaborators
- Learning the pipeline without coding
- Interactive visualization of results

**Access to Core Functionalities:**

| Functionality | How to Access |
|--------------|---------------|
| **Single Analysis - Single Cutoff** | Select "Single Analysis" → Configure parameters → Uncheck "Enable Sweep Mode" |
| **Single Analysis - Sweep Mode** | Select "Single Analysis" → Configure parameters → Check "Enable Sweep Mode" |
| **Comparative Analysis** | Select "Comparative Analysis" → Create/select multiple profiles |

**Environments:**
- **RStudio**: Launch with `shiny::runApp("shiny_app")`
- **VS Code**: Launch with R terminal
- **Terminal**: Launch with `R -e "shiny::runApp('shiny_app')"`

**See [Section 7: Using the Shiny App](#7-using-the-shiny-app) for detailed tutorial**

---

## 4. Getting Started

### 4.1 Quick Start Overview

**5 Steps to Your First Analysis:**

1. **Clone the repository**
   ```bash
   git clone https://github.com/enockniyonkuru/drug_repurposing.git
   cd drug_repurposing
   ```

2. **Download required data files** (see [Section 5.1](#51-required-data-files))
   - Download `cmap_signatures.RData` from Google Drive
   - Place in `scripts/data/` directory

3. **Install the R package**
   ```r
   devtools::document("DRpipe")
   devtools::install("DRpipe")
   ```

4. **Choose your interface:**
   - **R Package**: Edit `scripts/config.yml` and run `source("scripts/runall.R")`
   - **Shiny App**: Launch with `shiny::runApp("shiny_app")`

5. **View results** in `scripts/results/` directory

---

### 4.2 Launching from Different Environments

#### Option 1: RStudio (Recommended for Beginners)

**For R Package:**
```r
# 1. Open RStudio
# 2. Set working directory: Session > Set Working Directory > Choose Directory
#    Navigate to: drug_repurposing/scripts
# 3. Verify location
getwd()  # Should show: .../drug_repurposing/scripts

# 4. Run analysis
source("runall.R")  # For single analysis
source("compare_profiles.R")  # For comparative analysis
```

**For Shiny App:**
```r
# 1. Set working directory to shiny_app folder
setwd("path/to/drug_repurposing/shiny_app")

# 2. Launch app
shiny::runApp()
```

---

#### Option 2: VS Code

**For R Package:**
```r
# 1. Open VS Code with R extension installed
# 2. Open terminal in VS Code (Terminal > New Terminal)
# 3. Navigate to scripts directory
cd /path/to/drug_repurposing/scripts

# 4. Launch R
R

# 5. Run analysis
source("runall.R")
```

**For Shiny App:**
```r
# In R terminal within VS Code
setwd("path/to/drug_repurposing/shiny_app")
shiny::runApp()
```

---

#### Option 3: Terminal/Command Line

**For R Package:**
```bash
# Navigate to scripts directory
cd /path/to/drug_repurposing/scripts

# Run single analysis
Rscript runall.R

# Run comparative analysis
Rscript compare_profiles.R
```

**For Shiny App:**
```bash
# Navigate to shiny_app directory
cd /path/to/drug_repurposing/shiny_app

# Launch app
R -e "shiny::runApp()"

# Or with specific port
R -e "shiny::runApp(port=3838)"
```

---

## 5. Prerequisites & Installation

### 5.1 Required Data Files

#### Files Included in Repository

The following small data files are already included in `scripts/data/`:

1. **cmap_drug_experiments_new.csv** (831 KB) - CMap experiment metadata
2. **cmap_valid_instances.csv** (41 KB) - Curated list of valid CMap instances
3. **CoreFibroidSignature_All_Datasets.csv** (270 KB) - Example disease signature

#### Large Files (Download Required)

**Required:**
- **cmap_signatures.RData** (232 MB) - CMap reference signatures database

**Optional:**
- **gene_id_conversion_table.tsv** (4.5 MB) - Gene identifier conversion table

#### Download Instructions

🔗 **[Download Data Files from Google Drive](https://drive.google.com/drive/folders/1LvKiT0u3DGf5sW5bYVJk7scbM5rLmBx-?usp=sharing)**

**Steps:**
1. Visit the Google Drive link above
2. Download `cmap_signatures.RData`
3. Place in `scripts/data/` directory

**Verify your data directory:**
```bash
ls -lh scripts/data/
```

You should see:
- cmap_drug_experiments_new.csv
- cmap_valid_instances.csv
- CoreFibroidSignature_All_Datasets.csv
- cmap_signatures.RData (after download)

---

### 5.2 Software Requirements

**Required:**
- R ≥ 4.2
- RStudio (recommended) or VS Code with R extension

**R Packages (auto-installed with DRpipe):**
- `R6`, `dplyr`, `config`, `docopt`, `qvalue`, `pbapply`

**Optional (for visualizations):**
```r
install.packages(c("pheatmap", "UpSetR", "gplots"))
```

---

### 5.3 Installation Steps

#### Step 1: Clone Repository
```bash
git clone https://github.com/enockniyonkuru/drug_repurposing.git
cd drug_repurposing
```

#### Step 2: Install DRpipe Package
```r
# Install devtools if needed
install.packages("devtools", repos = "https://cloud.r-project.org")

# Build documentation and install DRpipe
devtools::document("DRpipe")
devtools::install("DRpipe")
```

#### Step 3: Verify Installation
```r
library(DRpipe)
?run_dr  # Should display help documentation
```

---

## 6. Using the R Package

### 6.1 Single Analysis - Single Cutoff

**Use Case:** Standard analysis with one fold-change threshold

#### Configuration (`scripts/config.yml`)

```yaml
execution:
  runall_profile: "CoreFibroid_logFC_1"  # Profile to use

CoreFibroid_logFC_1:
  paths:
    disease_file: "data/CoreFibroidSignature_All_Datasets.csv"
    signatures: "data/cmap_signatures.RData"
    cmap_meta: "data/cmap_drug_experiments_new.csv"
    cmap_valid: "data/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    logfc_cutoff: 1.0
    q_thresh: 0.05
    mode: "single"  # Single cutoff mode
```

#### Running the Analysis

**In RStudio:**
```r
setwd("/path/to/drug_repurposing/scripts")
source("runall.R")
```

**In Terminal:**
```bash
cd scripts
Rscript runall.R
```

#### Output Structure
```
results/CoreFibroid_logFC_1_20250107-183045/
├── CoreFibroid_results.RData           # Complete results
├── CoreFibroid_hits_q0.05.csv          # Significant drug hits
├── img/
│   ├── CoreFibroid_hist_revsc.jpg      # Score distribution
│   └── CoreFibroid_cmap_score.jpg      # Top drugs
└── sessionInfo.txt                      # Session details
```

---

### 6.2 Single Analysis - Sweep Mode

**Use Case:** Test multiple fold-change thresholds to find robust drug candidates

#### Configuration

```yaml
execution:
  runall_profile: "Sweep_CoreFibroid"

Sweep_CoreFibroid:
  paths:
    disease_file: "data/CoreFibroidSignature_All_Datasets.csv"
    # ... other paths same as above
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    mode: "sweep"                      # Enable sweep mode
    sweep_cutoffs: null                # Auto-derive cutoffs
    sweep_auto_grid: true
    sweep_step: 0.1                    # Step size between cutoffs
    sweep_min_frac: 0.10               # Min 10% of genes
    sweep_min_genes: 150               # Min 150 genes per cutoff
    robust_rule: "k_of_n"              # Filtering rule
    robust_k: 2                        # Must appear in ≥2 cutoffs
    aggregate: "median"                # Score aggregation method
    q_thresh: 0.05
```

#### Running the Analysis

```r
setwd("/path/to/drug_repurposing/scripts")
source("runall.R")  # Uses sweep profile from config
```

#### Output Structure
```
results/Sweep_CoreFibroid_20250107-183045/
├── cutoff_0.5/                        # Individual cutoff results
│   └── CoreFibroid_hits_cutoff_0.5.csv
├── cutoff_1.0/
├── cutoff_1.5/
├── aggregate/                         # Final robust results
│   ├── robust_hits.csv               # Drugs passing robust filtering
│   └── cutoff_summary.csv            # Summary per cutoff
└── CoreFibroid_results.RData
```

#### Key Parameters Explained

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `sweep_step` | Spacing between cutoffs | 0.1 |
| `sweep_min_genes` | Minimum genes per cutoff | 150 |
| `robust_rule` | "all" or "k_of_n" | "k_of_n" |
| `robust_k` | Min cutoffs required | 2 |
| `aggregate` | "mean", "median", or "weighted_mean" | "median" |

---

### 6.3 Comparative Analysis

**Use Case:** Compare results across multiple configurations

#### Two Common Scenarios

**Scenario 1: Parameter Sensitivity (Same Data, Different Parameters)**

```yaml
execution:
  compare_profiles: ["Lenient", "Standard", "Strict"]

Lenient:
  paths:
    disease_file: "data/my_data.csv"  # Same file
  params:
    logfc_cutoff: 0.5                 # Different cutoff

Standard:
  paths:
    disease_file: "data/my_data.csv"  # Same file
  params:
    logfc_cutoff: 1.0                 # Different cutoff

Strict:
  paths:
    disease_file: "data/my_data.csv"  # Same file
  params:
    logfc_cutoff: 1.5                 # Different cutoff
```

**Scenario 2: Cross-Dataset Comparison (Different Data, Same Parameters)**

```yaml
execution:
  compare_profiles: ["Dataset1", "Dataset2", "Dataset3"]

Dataset1:
  paths:
    disease_file: "data/dataset1.csv"  # Different file
  params:
    logfc_cutoff: 1.0                  # Same parameters

Dataset2:
  paths:
    disease_file: "data/dataset2.csv"  # Different file
  params:
    logfc_cutoff: 1.0                  # Same parameters
```

#### Running Comparative Analysis

```r
setwd("/path/to/drug_repurposing/scripts")
source("compare_profiles.R")
```

**Or from terminal:**
```bash
cd scripts
Rscript compare_profiles.R
```

#### Output Structure
```
results/profile_comparison_20250107-183045/
├── lenient_hits.csv                    # Individual profile results
├── standard_hits.csv
├── strict_hits.csv
├── combined_profile_hits.csv           # All results combined
├── profile_summary_stats.csv           # Summary statistics
└── img/
    ├── profile_comparison_score_dist.jpg
    ├── profile_overlap_heatmap.jpg
    ├── profile_overlap_atleast2.jpg
    └── profile_upset.jpg
```

---

## 7. Using the Shiny App

The Shiny app provides an interactive graphical interface for running analyses without writing code.

### 7.1 Launching the Shiny App

**From RStudio:**
```r
setwd("path/to/drug_repurposing/shiny_app")
shiny::runApp()
```

**From Terminal:**
```bash
cd shiny_app
R -e "shiny::runApp()"
```

**From VS Code:**
```r
# In R terminal
setwd("path/to/drug_repurposing/shiny_app")
shiny::runApp()
```

The app will open in your default web browser (typically at `http://127.0.0.1:XXXX`).

---

### 7.2 Single Analysis via Shiny App

#### Step 1: Select Analysis Type
- Choose **"Single Analysis"** from the dropdown

#### Step 2: Upload Data
- **Option A**: Upload your disease signature CSV file
- **Option B**: Load example data (Fibroid or Endothelial)

**Required CSV format:**
```csv
SYMBOL,log2FC_1,log2FC_2,p_val_adj
TP53,2.5,2.3,0.001
BRCA1,-1.8,-2.1,0.005
```

#### Step 3: Configure Parameters

**Basic Parameters:**
- **Gene Column**: Select column containing gene identifiers (e.g., SYMBOL)
- **Log2FC Prefix**: Prefix for fold-change columns (e.g., log2FC)
- **Log2FC Cutoff**: Fold-change threshold (e.g., 1.0)
- **Q-value Threshold**: FDR threshold (e.g., 0.05)

**For Single Cutoff Mode:**
- Leave "Enable Sweep Mode" unchecked

**For Sweep Mode:**
- Check "Enable Sweep Mode"
- Configure sweep parameters:
  - **Step Size**: Spacing between cutoffs (e.g., 0.1)
  - **Min Genes**: Minimum genes per cutoff (e.g., 150)
  - **Robust Rule**: "All cutoffs" or "K of N cutoffs"
  - **Robust K**: Minimum cutoffs required (e.g., 2)
  - **Aggregation**: "Median" or "Mean"

#### Step 4: Run Analysis
- Click **"Run Analysis"** button
- Monitor progress in real-time
- Wait for completion message

#### Step 5: View Results
- **Results Table**: Interactive table with filtering and sorting
- **Visualizations**: Bar charts, histograms, volcano plots
- **Download**: Export results as CSV

---

### 7.3 Comparative Analysis via Shiny App

#### Step 1: Select Analysis Type
- Choose **"Comparative Analysis"** from the dropdown

#### Step 2: Create/Select Profiles

**Option A: Use Existing Profiles**
- Select 2+ profiles from `config.yml`
- Profiles must already be defined in configuration file

**Option B: Create Custom Profiles**
- Click "Add Profile"
- Configure each profile with:
  - Profile name
  - Disease file
  - Parameters (including sweep settings if desired)
- Repeat for each profile you want to compare

#### Step 3: Run Comparative Analysis
- Click **"Run Comparative Analysis"**
- Each profile runs sequentially
- Progress shown for each profile

#### Step 4: View Comparative Results
- **Combined Results Table**: All profiles merged
- **Profile Overlap Heatmap**: Shows drug overlap between profiles
- **Score Distribution**: Compare score distributions across profiles
- **Download**: Export combined results

---

### 7.4 Shiny App Features

**Interactive Tables:**
- Sort by any column
- Filter results
- Search for specific drugs
- Pagination for large result sets

**Dynamic Visualizations:**
- Zoom and pan on plots
- Hover for detailed information
- Export plots as images

**Real-time Progress:**
- Progress bars during analysis
- Status messages
- Error reporting

**For detailed Shiny app documentation, see: [shiny_app/README.md](shiny_app/README.md)**

---

## 8. Repository Structure

```
drug_repurposing/
├── README.md                          # This file
├── DRpipe/                            # R package
│   ├── DESCRIPTION, NAMESPACE, LICENSE
│   ├── README.md                      # Package documentation
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
│   ├── runall.R                       # Single analysis script
│   ├── compare_profiles.R             # Comparative analysis script
│   ├── data/                          # Input data
│   │   ├── cmap_signatures.RData      # (Download required)
│   │   ├── cmap_drug_experiments_new.csv
│   │   ├── cmap_valid_instances.csv
│   │   └── CoreFibroidSignature_All_Datasets.csv
│   └── results/                       # Output directory
├── shiny_app/                         # Shiny application
│   ├── app.R                          # Main app file
│   ├── run.R                          # Helper launch script
│   └── README.md                      # Shiny app documentation
└── tahoe_cmap_analysis/               # Analysis of CMAP Vs Tahoe [Still in progress]
```

---

## 9. Configuration Reference

### 9.1 Understanding Configuration

The `scripts/config.yml` file controls all analysis parameters. It uses **profile names** as configuration identifiers.

**Profile Name Structure:**
```yaml
MyProfileName:                         # ← Profile identifier (you choose this)
  paths:
    disease_file: "data/my_data.csv"   # ← Actual input file
  params:
    logfc_cutoff: 1.0                  # ← Analysis parameters
```

**Key Concepts:**
- Profile names are **user-defined labels**, not file names
- Used to select which configuration to run
- Incorporated into output folder names for traceability

---

### 9.2 Core Parameters

| Parameter | Type | Typical Values | Description |
|-----------|------|----------------|-------------|
| `gene_key` | string | "SYMBOL", "ENSEMBL" | Column name with gene identifiers |
| `logfc_cols_pref` | string | "log2FC", "fc_" | Prefix for fold-change columns |
| `logfc_cutoff` | numeric | 0.5 - 2.0 | Absolute log2 fold-change threshold |
| `pval_key` | string/null | "p_val_adj", null | P-value column (null to skip) |
| `pval_cutoff` | numeric | 0.01 - 0.1 | P-value threshold |
| `q_thresh` | numeric | 0.01 - 0.1 | FDR threshold for drug significance |
| `reversal_only` | boolean | true/false | Keep only reversal drugs |
| `mode` | string | "single", "sweep" | Analysis mode |

---

### 9.3 Sweep Mode Parameters

| Parameter | Type | Typical Values | Description |
|-----------|------|----------------|-------------|
| `sweep_cutoffs` | array/null | [0.5, 1.0, 1.5] or null | Specific cutoffs or auto-generate |
| `sweep_step` | numeric | 0.1 - 0.5 | Step size for auto-generation |
| `sweep_min_genes` | integer | 100 - 300 | Minimum genes per cutoff |
| `robust_rule` | string | "all", "k_of_n" | Filtering rule |
| `robust_k` | integer | 2 - 5 | Min cutoffs required (for k_of_n) |
| `aggregate` | string | "mean", "median" | Score aggregation method |

---

### 9.4 Example Configuration

```yaml
# Execution settings
execution:
  runall_profile: "MyAnalysis"
  compare_profiles: ["Lenient", "Standard", "Strict"]

# Default profile (technical requirement - leave as-is)
default:
  paths:
    signatures: "data/cmap_signatures.RData"
    cmap_meta: "data/cmap_drug_experiments_new.csv"
    cmap_valid: "data/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    logfc_cutoff: 1.0
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    mode: "single"

# Your custom analysis profile
MyAnalysis:
  paths:
    disease_file: "data/my_disease_data.csv"
    signatures: "data/cmap_signatures.RData"
    cmap_meta: "data/cmap_drug_experiments_new.csv"
    cmap_valid: "data/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    logfc_cutoff: 1.0
    pval_key: null
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    mode: "single"
```

---

## 10. Data Formats

### 10.1 Disease Signature CSV

**Required columns:**
- Gene identifier column (e.g., SYMBOL, ENSEMBL)
- One or more fold-change columns with shared prefix

**Example:**

| SYMBOL | log2FC_1 | log2FC_2 | p_val_adj |
|--------|----------|----------|-----------|
| TP53   | 2.5      | 2.3      | 0.001     |
| BRCA1  | -1.8     | -2.1     | 0.005     |
| MYC    | 3.2      | 3.0      | 0.0001    |

**Notes:**
- Multiple log2FC columns are combined (default: average)
- P-value columns are optional
- Must have column headers (first row)

---

### 10.2 CMap Reference Files

**cmap_signatures.RData:**
- Matrix with genes as rows, experiments as columns
- Required for all analyses

**cmap_drug_experiments_new.csv:**
- Experiment metadata
- Drug names, cell lines, conditions

**cmap_valid_instances.csv:**
- Curated valid instances
- DrugBank IDs and validation flags

---

## 11. Troubleshooting

### 11.1 Common Issues

**"Cannot find config.yml"**
- **Solution**: Ensure working directory is `scripts/`
- **Check**: `getwd()` should show `.../drug_repurposing/scripts`
- **Fix**: `setwd("path/to/drug_repurposing/scripts")`

**"Disease file not found"**
- **Solution**: Verify path in `disease_file:` is relative to `scripts/`
- **Check**: `file.exists("data/your_file.csv")`

**"Gene column not found" or "No genes matched"**
- **Solution**: Verify `gene_key` matches your actual column name
- **Check**: `colnames(read.csv("data/your_file.csv"))`
- **Common cause**: Missing column headers in CSV

**"P-value column not found"**
- **Solution**: Set `pval_key: null` if no p-values
- **Or**: Verify column name matches your CSV

**CSV file format issues**
- **Solution**: Verify your CSV has column headers (first row)
- **Check**:
  ```r
  data <- read.csv("scripts/data/your_file.csv", nrows = 5)
  colnames(data)  # Should show proper names, not "V1", "V2"
  ```

---

### 11.2 Verifying Installation

```r
# Test package installation
library(DRpipe)
?run_dr  # Should display help

# Test data file
test_load <- try(load("scripts/data/cmap_signatures.RData"), silent = TRUE)
if (inherits(test_load, "try-error")) {
  cat("ERROR: File corrupted. Re-download from Google Drive.\n")
} else {
  cat("SUCCESS: File loaded correctly.\n")
}

# Verify working directory
getwd()  # Should end with: .../drug_repurposing/scripts
file.exists("config.yml")  # Should return TRUE
```

---

## 12. Methodology

### 12.1 Pipeline Steps

1. **Disease Signature Preparation**
   - Load differential expression results
   - Combine multiple fold-change columns
   - Filter by p-value (optional) and fold-change thresholds
   - Map to reference gene universe

2. **Connectivity Scoring**
   - Compare disease up/down gene sets to CMap profiles
   - Compute reversal scores for each drug-disease pair
   - Negative scores indicate reversal (desired)

3. **Statistical Analysis**
   - Generate null distributions via random sampling
   - Calculate empirical p-values
   - Compute q-values (FDR correction)

4. **Validation & Annotation**
   - Join with CMap experiment metadata
   - Filter to valid instances
   - Summarize per-drug results
   - Generate visualizations

### 12.2 Scoring Method

The pipeline uses connectivity scoring to measure how well a drug reverses the disease signature:
- **Negative scores**: Drug reverses disease signature (therapeutic potential)
- **Positive scores**: Drug mimics disease signature (avoid)
- **Statistical significance**: Determined by permutation testing and FDR correction

---

## 13. Citation & License

### 13.1 Authors

- **Enock Niyonkuru** - *Author, Maintainer* - [enock.niyonkuru@ucsf.edu](mailto:enock.niyonkuru@ucsf.edu)
- **Xinyu Tang** - *Author* - [Xinyu.Tang@ucsf.edu](mailto:Xinyu.Tang@ucsf.edu)
- **Marina Sirota** - *Author* - [Marina.Sirota@ucsf.edu](mailto:Marina.Sirota@ucsf.edu)


### 13.3 Citation

*Citation information will be added upon publication*

---

## Support

For questions or issues:
- Open an issue on [GitHub repository](https://github.com/enockniyonkuru/drug_repurposing) or send an email to enock.niyonkuru@ucsf.edu