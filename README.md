# Computational Drug Repurposing Pipeline (CDRPipe)

A comprehensive R package and Shiny application for drug repurposing analysis using disease gene expression signatures and drug signature databases (Connectivity Map/CMap and TAHOE) to identify potential therapeutic compounds.

This pipeline identifies existing drugs that could be repurposed for new therapeutic applications by analyzing their ability to reverse disease-associated gene expression patterns using drug signature databases including the Connectivity Map and TAHOE.

**🌐 Access the Shiny App:** [www.cdrpipe.org](https://www.cdrpipe.org)

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
12. [Citation & License](#12-citation--license)

---

## 1. What This Repository Does

**CDRPipe** is a drug repurposing analysis pipeline that helps researchers identify existing drugs that could be repurposed for new therapeutic applications. The pipeline:

- **Analyzes disease gene expression signatures** to identify up-regulated and down-regulated genes
- **Compares disease signatures against drug signature databases** (Connectivity Map/CMap and TAHOE) of drug-induced gene expression profiles
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

### 3.1 R Package (CDRPipe)

**Best for:**
- Batch processing multiple datasets
- Integration into automated workflows
- Fine-grained control over all parameters
- Programmatic access to all functions
- Running on remote servers or HPC clusters

**Access to Core Functionalities:**

| Functionality | How to Access |
|--------------|---------------|
| **Single Analysis - Single Cutoff** | `Rscript scripts/runall.R` using `execution.runall_profile` |
| **Single Analysis - Sweep Mode** | `Rscript scripts/runall.R` with `mode: "sweep"` in the selected profile |
| **Comparative Analysis** | `Rscript scripts/compare_profiles.R` using `execution.compare_profiles` |

**Primary package entry points:**
- `DRP$new(...)`
- `DRA$new(...)`
- `run_dr(...)`
- `load_dr_config(...)`
- `dr_cli()`

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
   - Download the required CMap files from Box: `cmap_signatures.RData` and `cmap_drug_experiments_new.csv`
   - If using TAHOE, download `tahoe_signatures.parquet`, `convert_parquet_to_rdata.R`, and `tahoe_drug_experiments_new.csv` from Box
   - Convert the Tahoe parquet file to `tahoe_signatures.RData` before running analyses
   - Place drug signature files in `scripts/data/drug_signatures/` directory
   - Place your disease signature files in `scripts/data/disease_signatures/` directory

3. **Install the R package**
   ```r
   devtools::install("CDRPipe")
   ```

4. **Choose your interface:**
   - **R Package**: Edit `scripts/config.yml` and run `Rscript scripts/runall.R`
   - **Shiny App**: Launch with `shiny::runApp("shiny_app")`

5. **View results** in `scripts/results/` directory

---

### 4.2 Launching from Different Environments

#### Option 1: RStudio (Recommended for Beginners)

**For R Package:**
```r
# Open the repository project, then run from the repo root
source("scripts/runall.R")           # Single profile selected in scripts/config.yml
source("scripts/compare_profiles.R") # Multi-profile comparison from scripts/config.yml
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
# Open the repository root with the R extension, then run:
source("scripts/runall.R")
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
# From the repository root

# Run single analysis
Rscript scripts/runall.R

# Run comparative analysis
Rscript scripts/compare_profiles.R
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

#### Directory Structure for Data

```
scripts/
├── data/
│   ├── drug_signatures/
│   │   ├── cmap_signatures.RData         # Required (232 MB)
│   │   ├── cmap_drug_experiments_new.csv # Required for CMap
│   │   ├── cmap_valid_instances.csv      # Optional (41 KB)
│   │   ├── convert_parquet_to_rdata.R    # Download from Box if using TAHOE
│   │   ├── tahoe_signatures.parquet      # Download from Box if using TAHOE
│   │   ├── tahoe_signatures.RData        # Generated locally from parquet; required for TAHOE
│   │   ├── tahoe_drug_experiments_new.csv # Required if using TAHOE (4.1 MB)
│   │   └── tahoe_valid_instances_OG_035.csv # Optional
│   ├── disease_signatures/
│   │   ├── your_disease_1.csv            # Your disease data files
│   │   └── your_disease_2.csv            # Place here
│   └── (other existing files)
```

#### Drug Signature Files

**For CMap Analysis (2 required + 1 optional):**
1. **cmap_signatures.RData** (232 MB) - REQUIRED - CMap reference signatures database
2. **cmap_drug_experiments_new.csv** (831 KB) - REQUIRED - CMap experiment metadata
3. **cmap_valid_instances.csv** (41 KB) - Optional - Curated list of valid CMap instances

**For TAHOE Analysis (3 required for setup + 1 generated output + 1 optional):**
1. **tahoe_signatures.parquet** - REQUIRED download from Box - Source TAHOE signature matrix
2. **convert_parquet_to_rdata.R** - REQUIRED download from Box - Helper script used to build the RData file
3. **tahoe_drug_experiments_new.csv** (4.1 MB) - REQUIRED - TAHOE experiment metadata
4. **tahoe_signatures.RData** (generated locally) - REQUIRED for analysis - Create this from the parquet file before running TAHOE analyses
5. **tahoe_valid_instances_OG_035.csv** (optional) - Optional - Curated list of valid TAHOE instances

#### Disease Signature Files

Place your disease gene expression data in `scripts/data/disease_signatures/`:
- CSV format with columns: gene identifiers, log fold-change, p-values (optional)
- Examples: `disease_name.csv`, `condition_1.csv`, etc.
- See [Section 10: Data Formats](#10-data-formats) for detailed specifications

#### Download Instructions

🔗 **[Download Data Files from Box](https://ucsf.box.com/s/m54ipylmdytjsqmlp7axnabvjh2q8lwl)**

**Steps:**
1. Visit the Box link above
2. Download required drug signature files:
   - For CMap: `cmap_signatures.RData` and `cmap_drug_experiments_new.csv`
   - For TAHOE: `convert_parquet_to_rdata.R`, `tahoe_signatures.parquet`, and `tahoe_drug_experiments_new.csv`
3. Create directories if they don't exist:
   ```bash
   mkdir -p scripts/data/drug_signatures
   mkdir -p scripts/data/disease_signatures
   ```
4. Place downloaded files in `scripts/data/drug_signatures/`
5. If you are using TAHOE, convert the parquet file to an `.RData` file:
   ```bash
   cd scripts/data/drug_signatures
   Rscript convert_parquet_to_rdata.R tahoe_signatures.parquet -o tahoe_signatures.RData --object-name tahoe_signatures --force
   cd ../../..
   ```
6. Before proceeding with TAHOE, verify that the generated `.RData` file loads correctly.

   If you run this from the repository root, use:
   ```bash
   Rscript -e 'e <- new.env(); load("scripts/data/drug_signatures/tahoe_signatures.RData", envir=e); obj <- get(ls(e)[1], envir=e); cat("class:", class(obj), "\n"); cat("dim:", paste(dim(obj), collapse=" x "), "\n"); print(head(obj[, 1:10]))'
   ```

   If you run it from a different working directory, update the path inside `load(...)` first.

   You should see a non-`NA` preview similar to:
   ```text
   class: data.frame
   dim: 22168 x 56828
     V1    V2    V3    V4    V5    V6    V7    V8    V9   V10
   1  1 16540  3291 18302 11965  2035  1954 17745  1875  9212
   2  2  3587  3788 17564   628 13006 15845 10754  4091  5094
   3  3 13572 15901 16376 14958  8502 16275 13944 16754 16163
   4  9  5163  3092  6496  9387 12986 12516  3464 16969 17830
   5 10 19186 18657 19118 18594 16140 18055 18364 17774 18192
   6 12 12008 15723  2490 16261   764 12904  7980 13862  3775
   ```
7. Place your disease data in `scripts/data/disease_signatures/`

**Verify your data directory:**
```bash
ls -lh scripts/data/drug_signatures/
ls -lh scripts/data/disease_signatures/
```

For CMap, you should see:
- cmap_signatures.RData (232 MB)
- cmap_drug_experiments_new.csv (831 KB)
- cmap_valid_instances.csv (41 KB, optional)

For TAHOE, after conversion, you should see:
- convert_parquet_to_rdata.R
- tahoe_signatures.parquet
- tahoe_signatures.RData
- tahoe_drug_experiments_new.csv
- tahoe_valid_instances_OG_035.csv (optional)

---

### 5.2 Software Requirements

**Required:**
- R ≥ 4.2
- RStudio (recommended) or VS Code with R extension

**R Packages (auto-installed with CDRPipe):**
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

#### Step 2: Install CDRPipe Package
```r
# Install devtools if needed
install.packages("devtools", repos = "https://cloud.r-project.org")

# Install from the local checkout
devtools::install("CDRPipe")
```

#### Step 3: Verify Installation
```r
library(CDRPipe)
?run_dr  # Should display help documentation
```

Current package interfaces:
- `DRP$new(...)`
- `DRA$new(...)`
- `run_dr(...)`
- `load_dr_config(...)`
- `dr_cli()`

Quick quality check:
```bash
Rscript scripts/ci/check_cdrpipe.R
```

---

## 6. Using the R Package

### 6.1 Single Analysis - Single Cutoff

**Use Case:** Standard analysis with one selected profile from `scripts/config.yml`.

Typical workflow:

```bash
Rscript scripts/runall.R
```

`runall.R`:
- reads `execution.runall_profile`
- resolves paths relative to `scripts/config.yml`
- creates a timestamped output folder under `scripts/results/`
- runs the selected `DRP` profile
- writes plots, result tables, `config_effective.yml`, and `sessionInfo.txt`

Representative profile:

```yaml
execution:
  runall_profile: "CMAP_Acne_Standard"

CMAP_Acne_Standard:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: 0.055
    q_thresh: 0.05
    reversal_only: true
    n_permutations: 100000
    mode: "single"
```

Representative output:

```text
scripts/results/CMAP_Acne_Standard_20260330-184636/
├── acne_signature_results.RData
├── acne_signature_hits_logFC_0.055_q<0.05.csv
├── img/
│   ├── cmap_score.jpg
│   └── acne_signature_heatmap_cmap_hits.jpg
├── config_effective.yml
└── sessionInfo.txt
```

---

### 6.2 Single Analysis - Sweep Mode

**Use Case:** Test multiple fold-change thresholds to identify robust hits across cutoffs.

```yaml
execution:
  runall_profile: "MyAnalysis_SweepMode"

MyAnalysis_SweepMode:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/my_disease_data.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    mode: "sweep"                      # Enable sweep mode
    sweep_cutoffs: null                # Auto-derive cutoffs
    sweep_auto_grid: true
    sweep_step: 0.1                    # Step size between cutoffs
    sweep_min_frac: 0.20               # Min 20% of genes
    sweep_min_genes: 200               # Min 200 genes per cutoff
    robust_rule: "k_of_n"              # Filtering rule
    robust_k: 2                        # Must appear in ≥2 cutoffs
    aggregate: "median"                # Score aggregation method
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    combine_log2fc: "average"
```

Run it with the same entrypoint:

```bash
Rscript scripts/runall.R
```

Key sweep parameters:

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `sweep_step` | Spacing between cutoffs | 0.1 |
| `sweep_min_genes` | Minimum genes per cutoff | 200 |
| `robust_rule` | "all" or "k_of_n" | "k_of_n" |
| `robust_k` | Min cutoffs required | 2 |
| `aggregate` | "mean", "median", or "weighted_mean" | "median" |

---

### 6.3 Comparative Analysis

**Use Case:** Compare results across multiple profiles listed in `execution.compare_profiles`.

```yaml
execution:
  compare_profiles: ["CMAP_Acne_Lenient", "CMAP_Acne_Standard", "CMAP_Acne_Strict"]
```

Run from the repository root:

```bash
Rscript scripts/compare_profiles.R
```

Representative output:

```text
scripts/results/profile_comparison/<YYYYMMDD-HHMMSS>/
├── <profile>_hits.csv
├── combined_profile_hits.csv
├── profile_summary_stats.csv
├── profile_comparison_report.md
└── img/
    ├── profile_comparison_score_dist.jpg
    ├── profile_overlap_heatmap.jpg
    ├── profile_overlap_atleast2.jpg
    └── profile_upset.jpg
```

### 6.4 Parallelization And Permutations

Single-mode runs now support `params$ncores` for the heavy scoring steps:
- `random_score()`
- `query_score()`

Example:

```yaml
TAHOE_Acne_Standard_Smoke:
  params:
    ncores: 4
    n_permutations: 1000
```

Guidance:
- Use `n_permutations: 100000` for final analyses and publication-quality runs.
- Lower counts such as `1000` or `10000` are useful for faster validation runs.
- Lower permutation counts reduce runtime, but they also reduce p-value resolution.
- `ncores` is most helpful for large profiles such as TAHOE.

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
- **Option B**: Load example data (Acne, Arthritis, or Glaucoma)

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
├── CDRPipe/                            # R package (core pipeline logic)
│   ├── DESCRIPTION, NAMESPACE, LICENSE
│   ├── README.md                      # Package API documentation
│   └── R/
│       ├── processing.R               # Core data processing (clean_table, query, etc.)
│       ├── analysis.R                 # Plotting/summary helpers
│       ├── pipeline_processing.R      # DRP class + run_dr()
│       ├── pipeline_analysis.R        # DRA class + analyze_runs()
│       ├── io_config.R                # Config & IO helpers
│       ├── cli.R                      # Command-line interface
│       ├── plot_sweep_legacy.R        # Legacy sweep mode plotting
│       └── zzz-imports.R
├── scripts/                           # Pipeline execution & configuration
│   ├── README.md                      # Scripts documentation
│   ├── config.yml                     # YAML configuration (all profiles)
│   ├── runall.R                       # Entry point: single analysis
│   ├── compare_profiles.R            # Entry point: comparative analysis
│   ├── load_execution_config.R        # Config-loading helpers
│   ├── preprocess_disease_file.R      # Disease file column standardization
│   ├── data/                          # Input data
│   │   ├── drug_signatures/           # Drug signature databases (download required)
│   │   │   ├── cmap_signatures.RData  # CMap (232 MB)
│   │   │   ├── cmap_drug_experiments_new.csv
│   │   │   ├── cmap_valid_instances.csv
│   │   │   ├── tahoe_signatures.RData # TAHOE (generated locally from Box parquet)
│   │   │   ├── tahoe_drug_experiments_new.csv
│   │   │   └── tahoe_valid_instances_OG_035.csv
│   │   └── disease_signatures/        # Disease gene expression CSVs
│   │       ├── acne_signature.csv
│   │       ├── arthritis_signature.csv
│   │       └── glaucoma_signature.csv
│   └── results/                       # Timestamped output directories
├── shiny_app/                         # Interactive web application
│   ├── README.md                      # Shiny app documentation
│   ├── app.R                          # Main Shiny application
│   ├── run.R                          # Launcher with dependency checks
│   └── check_packages.R              # Package verification script
├── visuals/                           # Manuscript figures
│   └── figures/                       # Generated figures
└── dump/                              # Archived/deprecated files (not needed for pipeline)
```

---

## About the Subdirectories

Directories with their own README:

| Directory | Purpose | README |
|-----------|---------|--------|
| `CDRPipe/` | Core R package (functions, classes, CLI) | [CDRPipe/README.md](CDRPipe/README.md) |
| `scripts/` | Pipeline execution, configuration, input data, results | [scripts/README.md](scripts/README.md) |
| `shiny_app/` | Interactive web application for analysis and visualization | [shiny_app/README.md](shiny_app/README.md) |
| Manuscript comparative analysis | CREEDS 233-disease analysis, autoimmune case study, endometriosis case study, and manuscript-specific comparative analyses | [cdrpipe-comparative-analysis](https://github.com/enockniyonkuru/cdrpipe-comparative-analysis) |

**Key references:**
- For **threshold tuning**, valid instance creation, and manuscript batch processing: see [cdrpipe-comparative-analysis](https://github.com/enockniyonkuru/cdrpipe-comparative-analysis)
- For **running your own disease**: see [scripts/README.md](scripts/README.md)

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
| `n_permutations` | integer | 1000, 10000, 100000 | Permutation count for null-score testing |
| `ncores` | integer/null | 2, 4, 8, null | Optional worker count for single-mode scoring |
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
  runall_profile: "CMAP_Acne_Standard"
  compare_profiles: ["CMAP_Acne_Lenient", "CMAP_Acne_Standard", "CMAP_Acne_Strict"]

# Default profile (technical requirement - leave as-is)
default:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: null
    percentile_filtering:
      enabled: true
      threshold: 25
    pval_key: null
    pval_cutoff: 0.05
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    n_permutations: 100000
    mode: "single"
    combine_log2fc: "average"

# Acne analysis profile (CMap) - Standard threshold
CMAP_Acne_Standard:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: 0.055
    pval_key: null
    pval_cutoff: 0.05
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    mode: "single"

# TAHOE analysis example (using Acne signature)
TAHOE_Acne_Standard:
  paths:
    signatures: "data/drug_signatures/tahoe_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/tahoe_drug_experiments_new.csv"
    drug_valid: null
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: null
    percentile_filtering:
      enabled: true
      threshold: 50
    pval_key: null
    pval_cutoff: 0.05
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    n_permutations: 100000
    mode: "single"

# TAHOE verification profile with faster runtime
TAHOE_Acne_Standard_Smoke:
  paths:
    signatures: "data/drug_signatures/tahoe_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/tahoe_drug_experiments_new.csv"
    drug_valid: null
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: null
    percentile_filtering:
      enabled: true
      threshold: 50
    pval_key: null
    pval_cutoff: 0.05
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    n_permutations: 1000
    ncores: 4
    mode: "single"

> **Note on TAHOE Valid Instances:** The public Tahoe profiles currently run without a `drug_valid` filter. If you want an additional Tahoe valid-instance filter, `tahoe_valid_instances_OG_035.csv` is available locally and can be added back to a custom profile.

# Parameter sensitivity analysis profiles for Acne
CMAP_Acne_Lenient:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: 0.033
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    mode: "single"

CMAP_Acne_Standard:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: 0.055
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    mode: "single"

CMAP_Acne_Strict:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: 0.066
    q_thresh: 0.05
    reversal_only: true
    seed: 123
    mode: "single"
```

---

## 9.5 Advanced Threshold Tuning

For detailed guidance on adjusting disease and drug signature thresholds, filtering parameters, and running manuscript batch analyses with custom configurations, see the **[cdrpipe-comparative-analysis repository](https://github.com/enockniyonkuru/cdrpipe-comparative-analysis)**.

This includes:
- **Creating valid instances** for drug signatures with correlation-based quality control
- **Filtering disease signatures** with configurable fold-change and p-value thresholds
- **Filtering drug signatures** with stage-by-stage quality metrics
- **Batch processing** 233 CREEDS diseases with custom parameters
- **Batch configuration files** with YAML templates for multi-disease runs

**Quick Reference for Valid Instance Thresholds:**
- **CMAP**: r = 0.15 (minimum correlation threshold)
- **TAHOE**: r = 0.35 (stricter correlation threshold)

These thresholds determine which drug signatures meet quality criteria based on replicate consistency. For more details on parameter sensitivity and best practices, refer to the [cdrpipe-comparative-analysis repository](https://github.com/enockniyonkuru/cdrpipe-comparative-analysis).

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

### 10.2 Drug Signature Reference Files

**CMap Reference Files:**
- **cmap_signatures.RData**: Matrix with genes as rows, experiments as columns. Required for CMap analyses.
- **cmap_drug_experiments_new.csv**: Experiment metadata containing drug names, cell lines, and experimental conditions.
- **cmap_valid_instances.csv**: Curated valid instances with DrugBank IDs and validation flags (optional but recommended).

**TAHOE Reference Files:**
- **tahoe_signatures.parquet**: Download this source file from Box when setting up TAHOE locally.
- **convert_parquet_to_rdata.R**: Helper script from Box used to convert the Tahoe parquet file into the RData file expected by the pipeline.
- **tahoe_signatures.RData**: Matrix with genes as rows, experiments as columns. Generate this locally from `tahoe_signatures.parquet`; it is required for TAHOE analyses.
- **tahoe_drug_experiments_new.csv**: Experiment metadata containing drug names, cell lines, and experimental conditions.
- **tahoe_valid_instances_OG_035.csv**: Curated valid instances with DrugBank IDs and validation flags (optional).

---

## 11. Troubleshooting

### 11.1 Common Issues

**"Cannot find config.yml"**
- **Check**: Run from the repository root with `Rscript scripts/runall.R` or `Rscript scripts/compare_profiles.R`
- **Note**: The scripts now resolve their own location, so `setwd("scripts")` is usually not necessary
- **Fix**: Verify that `scripts/config.yml` exists and that you did not rename the `scripts/` directory

**"Disease file not found"**
- **Solution**: Verify path in `disease_file:` is relative to `scripts/config.yml`
- **Check**: `file.exists("scripts/data/your_file.csv")`

**"Tahoe run is extremely slow"**
- **Cause**: Tahoe has a much larger experiment matrix than CMAP
- **Recommendation**: Use `TAHOE_Acne_Standard_Smoke` or temporarily lower `n_permutations`
- **For final runs**: Prefer `n_permutations: 100000`
- **For faster validation**: Use `n_permutations: 1000` or `10000`, and set `ncores` when available

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
library(CDRPipe)
?run_dr  # Should display help

# Test data file
test_load <- try(load("scripts/data/drug_signatures/cmap_signatures.RData"), silent = TRUE)
if (inherits(test_load, "try-error")) {
  cat("ERROR: File corrupted. Re-download from Box.\n")
} else {
  cat("SUCCESS: File loaded correctly.\n")
}

# Verify working directory
getwd()  # Often the repository root
file.exists("scripts/config.yml")  # Should return TRUE from the repo root
```

---

## 12. Citation & License

### 12.1 Authors

- **Enock Niyonkuru** - *Author, Maintainer* - [enock.niyonkuru@ucsf.edu](mailto:enock.niyonkuru@ucsf.edu)
- **Xinyu Tang** - *Author* - [Xinyu.Tang@ucsf.edu](mailto:Xinyu.Tang@ucsf.edu)
- **Umair Khan** - *Author* - [Umair.Khan@ucsf.edu](mailto:Umair.Khan@ucsf.edu)
- **Tomiko Oskotsky** - *Author* - [Tomiko.Oskotsky@ucsf.edu](mailto:Tomiko.Oskotsky@ucsf.edu)
- **Marina Sirota** - *Author* - [Marina.Sirota@ucsf.edu](mailto:Marina.Sirota@ucsf.edu)

### 12.2 Citation

*Citation information will be added upon publication of the manuscript*

---

## Support

For questions or issues:
- Open an issue on [GitHub repository](https://github.com/enockniyonkuru/drug_repurposing) or send an email to enock.niyonkuru@ucsf.edu
