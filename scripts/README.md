# Scripts — Pipeline Execution & Configuration

This directory contains the main entry-point scripts, configuration, input data, and output results for running the CDRpipe drug repurposing pipeline from the command line.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Directory Structure](#directory-structure)
3. [Entry-Point Scripts](#entry-point-scripts)
4. [Configuration (config.yml)](#configuration-configyml)
5. [Input Data](#input-data)
6. [Output Results](#output-results)
7. [Utility & Batch Scripts](#utility--batch-scripts)
8. [Reproducing Analyses](#reproducing-analyses)

---

## Quick Start

```bash
# 1. Ensure DRpipe is installed
R -e 'devtools::install("../DRpipe")'

# 2. Download required data (see "Input Data" section below)

# 3. Run a single analysis (uses runall_profile from config.yml)
cd scripts
Rscript runall.R

# 4. Run a comparative analysis (uses compare_profiles from config.yml)
Rscript compare_profiles.R

# 5. Results appear in scripts/results/<profile>_<timestamp>/
```

All scripts assume the working directory is `scripts/`. Set it before running:

```r
setwd("/path/to/drug_repurposing/scripts")
```

---

## Directory Structure

```
scripts/
├── config.yml                  # Main YAML configuration (profiles + parameters)
├── runall.R                    # Entry point — single analysis (single cutoff or sweep)
├── compare_profiles.R          # Entry point — comparative multi-profile analysis
├── load_execution_config.R     # Config-loading helper functions
├── preprocess_disease_file.R   # Utility to standardize disease CSV columns
├── check_aggregation.R         # Diagnostic: compare CMAP vs TAHOE score distributions
├── run_all_6_endo.R            # Batch: 6 endometriosis sub-signatures (CMAP)
├── run_all_6_endo_tahoe.R      # Batch: 6 endometriosis sub-signatures (TAHOE)
├── run_all_endometriosis.sh    # Shell wrapper for batch endometriosis runs
├── run_ese_test.R              # Test: single ESE endometriosis signature
├── test_config_loading.R       # Test: verify config.yml parsing
├── data/                       # Input data (disease + drug signatures)
│   ├── disease_signatures/     # Disease gene expression CSVs
│   │   ├── acne_signature.csv
│   │   ├── arthritis_signature.csv
│   │   ├── glaucoma_signature.csv
│   │   └── endo_disease_signatures/   # 6 endometriosis sub-signatures
│   ├── drug_signatures/        # Drug signature databases (download required)
│   │   ├── cmap_signatures.RData          # CMap signatures (232 MB)
│   │   ├── cmap_drug_experiments_new.csv  # CMap experiment metadata
│   │   ├── cmap_valid_instances.csv       # CMap valid instances
│   │   ├── tahoe_signatures.RData         # TAHOE signatures (2.9 GB)
│   │   ├── tahoe_drug_experiments_new.csv # TAHOE experiment metadata
│   │   └── tahoe_valid_instances_OG_035.csv # TAHOE valid instances (r=0.35)
│   └── gene_id_conversion_table.tsv       # Gene ID mapping reference
└── results/                    # Timestamped output directories
```

---

## Entry-Point Scripts

### `runall.R` — Single Analysis

Runs one complete drug repurposing analysis using the profile specified in the `execution.runall_profile` field of `config.yml`.

```bash
Rscript runall.R
```

**What it does:**
1. Reads `config.yml` and selects the profile named in `execution.runall_profile`
2. Loads drug signature database (RData) into memory
3. Preprocesses the disease signature (gene filtering, fold-change thresholds)
4. Computes reversal scores for every drug experiment against the disease signature
5. Generates null distributions via permutation testing (default: 100,000 permutations)
6. Calculates p-values and FDR-corrected q-values
7. Filters significant hits and saves results to `results/<profile>_<timestamp>/`

**Supports two modes** (set in config):
- `mode: "single"` — One fold-change cutoff, one result set
- `mode: "sweep"` — Tests multiple cutoffs, aggregates robust hits

---

### `compare_profiles.R` — Comparative Analysis

Runs multiple profiles sequentially and compares their results.

```bash
Rscript compare_profiles.R
```

**What it does:**
1. Reads the `execution.compare_profiles` list from `config.yml`
2. Runs `runall.R`-equivalent logic for each profile
3. Merges results across profiles
4. Generates overlap heatmaps, UpSet plots, and comparison tables

**Use cases:**
- **Parameter sensitivity**: Same disease data, varying fold-change cutoffs (e.g., Lenient/Standard/Strict)
- **Cross-dataset**: Different disease signatures, same parameters
- **Cross-platform**: Same disease on CMap vs TAHOE

---

## Configuration (config.yml)

The file `config.yml` contains all analysis profiles. Each profile specifies paths and parameters.

### Structure

```yaml
# Which profile to run with runall.R
execution:
  runall_profile: "CMAP_Acne_Standard"
  compare_profiles: ["CMAP_Acne_Lenient", "CMAP_Acne_Standard", "CMAP_Acne_Strict"]

# Each profile defines paths + params
CMAP_Acne_Standard:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"          # Column name for gene identifiers
    logfc_cols_pref: "logfc_dz"      # Prefix for log2FC columns
    logfc_cutoff: 0.051              # Absolute fold-change threshold
    pval_key: null                   # P-value column (null = skip)
    pval_cutoff: 0.05                # P-value threshold
    q_thresh: 0.05                   # FDR threshold for drug significance
    reversal_only: true              # Keep only drugs that reverse signature
    seed: 123                        # Random seed for reproducibility
    n_permutations: 100000           # Permutations for null distribution
    mode: "single"                   # "single" or "sweep"
    combine_log2fc: "average"        # How to combine multiple logFC columns
```

### Key Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `gene_key` | `"SYMBOL"`, `"gene_symbol"` | Gene identifier column in disease CSV |
| `logfc_cols_pref` | `"log2FC"`, `"logfc_dz"` | Prefix matching fold-change columns |
| `logfc_cutoff` | 0.01–2.0 | Absolute log2FC threshold (null for percentile) |
| `percentile_filtering` | `{enabled: true, threshold: 50}` | Data-adaptive gene filtering (top N%) |
| `pval_key` | column name or `null` | P-value column for filtering |
| `q_thresh` | 0.01–0.10 | FDR q-value cutoff for significant drugs |
| `reversal_only` | `true`/`false` | Keep only drugs with negative reversal scores |
| `n_permutations` | 1000–1000000 | Permutation count (more = slower but more precise) |
| `mode` | `"single"`, `"sweep"` | Single cutoff vs multi-threshold sweep |
| `combine_log2fc` | `"average"`, `"median"`, `"first"` | Aggregation for multiple logFC columns |
| `pvalue_method` | `"continuous"`, `"discrete"` | P-value estimation method |
| `phipson_smyth_correction` | `true`/`false` | Correction for permutation p-values |

### Sweep-Specific Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `sweep_cutoffs` | `[0.5, 1.0, 1.5]` or `null` | Specific cutoffs (null = auto-derive) |
| `sweep_auto_grid` | `true`/`false` | Auto-generate thresholds from data |
| `sweep_step` | 0.033–0.5 | Step size between auto-generated cutoffs |
| `sweep_min_frac` | 0.10–0.30 | Minimum fraction of genes per cutoff |
| `sweep_min_genes` | 100–300 | Minimum genes per cutoff |
| `robust_rule` | `"all"`, `"k_of_n"` | Drug must appear in all or K-of-N cutoffs |
| `robust_k` | 2–5 | Minimum cutoffs required for k_of_n |
| `aggregate` | `"mean"`, `"median"` | Score aggregation across cutoffs |

### Pre-defined Profiles

The config file ships with profiles for multiple diseases and databases:

| Profile Pattern | Database | Disease | Filtering |
|----------------|----------|---------|-----------|
| `CMAP_Acne_Lenient/Standard/Strict` | CMap | Acne | Fixed cutoff (0.033/0.051/0.07) |
| `CMAP_Acne_Sweep` | CMap | Acne | Multi-threshold sweep |
| `CMAP_Arthritis_Lenient/Standard/Strict` | CMap | Arthritis | Fixed cutoff |
| `CMAP_Glaucoma_Lenient/Standard/Strict` | CMap | Glaucoma | Fixed cutoff |
| `TAHOE_Acne_Lenient/Standard/Strict` | TAHOE | Acne | Percentile-based |
| `CMAP_Endometriosis_ESE_Strict` | CMap | Endometriosis (ESE) | Fixed cutoff |

### Creating Your Own Profile

1. Copy an existing profile block in `config.yml`
2. Rename the profile key (e.g., `CMAP_MyDisease_Standard`)
3. Update `disease_file` to point to your CSV
4. Adjust parameters as needed
5. Set `execution.runall_profile` to your new profile name
6. Run `Rscript runall.R`

---

## Input Data

### Disease Signatures (`data/disease_signatures/`)

CSV files with differential gene expression data. Required columns:

| Column | Description | Example |
|--------|-------------|---------|
| Gene identifier | Gene symbols or IDs | `TP53`, `BRCA1` |
| Log2 fold-change | One or more columns with shared prefix | `log2FC_1`, `log2FC_2` |
| P-value (optional) | Adjusted or raw p-values | `p_val_adj` |

**Example CSV:**
```csv
gene_symbol,logfc_dz_1,logfc_dz_2,p_val_adj
TP53,2.5,2.3,0.001
BRCA1,-1.8,-2.1,0.005
```

**Included example signatures:**
- `acne_signature.csv` — CREEDS acne DEGs
- `arthritis_signature.csv` — CREEDS arthritis DEGs
- `glaucoma_signature.csv` — CREEDS glaucoma DEGs
- `endo_disease_signatures/` — 6 endometriosis sub-type signatures (ESE, InII, IIInIV, MSE, PE, Unstratified)

### Drug Signatures (`data/drug_signatures/`)

These files must be downloaded separately. They are too large for Git.

**Download from:** [Google Drive](https://drive.google.com/drive/folders/1LvKiT0u3DGf5sW5bYVJk7scbM5rLmBx-?usp=sharing)

| File | Size | Required For | Description |
|------|------|-------------|-------------|
| `cmap_signatures.RData` | 232 MB | CMap analyses | Gene × experiment rank matrix |
| `cmap_drug_experiments_new.csv` | 831 KB | CMap analyses | Experiment metadata (drug names, cell lines, etc.) |
| `cmap_valid_instances.csv` | 41 KB | CMap analyses | Curated valid instances (r ≥ 0.15) |
| `tahoe_signatures.RData` | 2.9 GB | TAHOE analyses | Gene × experiment rank matrix |
| `tahoe_drug_experiments_new.csv` | 4.1 MB | TAHOE analyses | Experiment metadata |
| `tahoe_valid_instances_OG_035.csv` | — | TAHOE analyses | Curated valid instances (r ≥ 0.35) |

**Setup:**
```bash
mkdir -p data/drug_signatures
# Place downloaded files in data/drug_signatures/
ls -lh data/drug_signatures/
```

### Preprocessing a New Disease File

If your disease CSV uses non-standard column names, use the preprocessing utility:

```bash
Rscript preprocess_disease_file.R input.csv output.csv
```

This renames `gene_symbol` → `SYMBOL` and `mean_logfc` → `log2FC`.

---

## Output Results

Each analysis creates a timestamped directory under `results/`:

```
results/<ProfileName>_<YYYYMMDD-HHMMSS>/
├── <ProfileName>_results.RData              # Complete R results object
├── <ProfileName>_hits_logFC_<X>_q<Y>.csv    # Significant drug hits table
├── img/
│   ├── <ProfileName>_hist_revsc.jpg         # Reversal score distribution
│   └── <ProfileName>_cmap_score.jpg         # Top drug bar chart
└── sessionInfo.txt                          # R session details
```

**Sweep mode** adds per-cutoff subdirectories and an aggregate summary:
```
results/<ProfileName>_<timestamp>/
├── cutoff_0.5/
│   └── hits_cutoff_0.5.csv
├── cutoff_1.0/
├── aggregate/
│   ├── robust_hits.csv
│   └── cutoff_summary.csv
└── <ProfileName>_results.RData
```

**Comparative analysis** creates a combined directory:
```
results/profile_comparison_<timestamp>/
├── <profile1>_hits.csv
├── <profile2>_hits.csv
├── combined_profile_hits.csv
├── profile_summary_stats.csv
└── img/
    ├── profile_comparison_score_dist.jpg
    ├── profile_overlap_heatmap.jpg
    └── profile_upset.jpg
```

---

## Utility & Batch Scripts

| Script | Purpose |
|--------|---------|
| `preprocess_disease_file.R` | Standardize column names in a disease CSV (`Rscript preprocess_disease_file.R in.csv out.csv`) |
| `load_execution_config.R` | Helper functions for YAML parsing — sourced by `runall.R` and `compare_profiles.R` |
| `check_aggregation.R` | Diagnostic script comparing CMap vs TAHOE score distributions |
| `run_all_6_endo.R` | Batch-run 6 endometriosis sub-signatures against CMap |
| `run_all_6_endo_tahoe.R` | Batch-run 6 endometriosis sub-signatures against TAHOE |
| `run_all_endometriosis.sh` | Shell wrapper for endometriosis batch processing |
| `run_ese_test.R` | Quick test with a single ESE endometriosis signature |
| `test_config_loading.R` | Verify `config.yml` loads correctly |

---

## Reproducing Analyses

### Reproduce an Acne Analysis (CMap)

```bash
cd scripts

# 1. Confirm data files are present
ls data/drug_signatures/cmap_signatures.RData
ls data/disease_signatures/acne_signature.csv

# 2. Set the profile in config.yml
#    execution:
#      runall_profile: "CMAP_Acne_Standard"

# 3. Run
Rscript runall.R

# 4. Check results
ls results/CMAP_Acne_Standard_*/
```

### Reproduce a Comparative Analysis

```bash
cd scripts

# 1. Set compare profiles in config.yml
#    execution:
#      compare_profiles: ["CMAP_Acne_Lenient", "CMAP_Acne_Standard", "CMAP_Acne_Strict"]

# 2. Run
Rscript compare_profiles.R

# 3. Check results
ls results/profile_comparison_*/
```

### Reproduce Endometriosis Batch Analysis

```bash
cd scripts

# CMap
Rscript run_all_6_endo.R

# TAHOE
Rscript run_all_6_endo_tahoe.R
```

### Run Your Own Disease

1. Place your disease CSV in `data/disease_signatures/my_disease.csv`
2. Add a profile to `config.yml`:
   ```yaml
   CMAP_MyDisease:
     paths:
       signatures: "data/drug_signatures/cmap_signatures.RData"
       disease_file: "data/disease_signatures/my_disease.csv"
       drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
       drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
       out_dir: "results"
     params:
       gene_key: "SYMBOL"
       logfc_cols_pref: "log2FC"
       logfc_cutoff: 1.0
       q_thresh: 0.05
       reversal_only: true
       seed: 123
       mode: "single"
       combine_log2fc: "average"
   ```
3. Set `execution.runall_profile: "CMAP_MyDisease"`
4. Run: `Rscript runall.R`
5. Results in: `results/CMAP_MyDisease_<timestamp>/`

---

## Typical Runtime

| Database | Mode | Permutations | Approximate Time |
|----------|------|-------------|-----------------|
| CMap | Single | 100,000 | 8–15 min |
| CMap | Sweep (6 cutoffs) | 100,000 | 45–90 min |
| TAHOE | Single | 100,000 | 30–50 min |
| TAHOE | Sweep (6 cutoffs) | 100,000 | 2–5 hours |

Times depend on machine specs and disease signature size. TAHOE is larger (~3× more experiments than CMap).
