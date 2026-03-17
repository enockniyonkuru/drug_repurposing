# TAHOE vs CMAP Comparative Analysis

Large-scale comparative drug repurposing analysis across 233 CREEDS diseases using both CMAP and TAHOE drug signature databases. This directory contains the preprocessing, execution, analysis, visualization, and validation pipelines for the manuscript.

---

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Prerequisites](#prerequisites)
4. [Data](#data)
5. [Scripts](#scripts)
6. [Results](#results)
7. [Validation Pipeline](#validation-pipeline)
8. [Case Studies](#case-studies)
9. [Reproducing the Analysis](#reproducing-the-analysis)
10. [Logs & Archived Files](#logs--archived-files)

---

## Overview

This sub-project runs the CDRpipe drug repurposing pipeline on hundreds of disease signatures from the CREEDS and Sirota Lab repositories, comparing predictions from two drug signature platforms:

- **CMAP** (Connectivity Map) — ~7,000 drug experiments, ~1,300 compounds
- **TAHOE** (Tahoe-100M) — ~100,000+ drug experiments, ~20,000+ compounds

The analysis covers:
- **90 selected diseases** with shared CMAP/TAHOE genes
- **19 endometriosis sub-signatures**
- **6 Tomiko endometriosis** reference signatures
- **20 autoimmune diseases** for case-study validation
- **Known-drug recovery** against Open Targets, DrugBank, DailyMed, and ChEMBL

---

## Directory Structure

```
tahoe_cmap_analysis/
├── data/                          # All input datasets
│   ├── disease_signatures/        # Disease gene expression CSVs
│   ├── drug_signatures/           # CMAP and TAHOE RData/metadata
│   ├── known_drugs/               # Open Targets known associations (parquet)
│   ├── analysis/                  # Processed analysis outputs (e.g., Exp8_Analysis.xlsx)
│   ├── gene_id_conversion_table.tsv
│   └── shared_drugs_cmap_tahoe.csv
├── scripts/                       # All code, organized by purpose
│   ├── preprocessing/             # Data extraction, filtering, standardization (20 files)
│   ├── execution/                 # Batch pipeline execution and configs (14 files)
│   ├── analysis/                  # Comparative analysis scripts (18 files)
│   ├── visualization/             # Figure generation (31 files)
│   ├── extraction/                # Case study data extraction (3 files)
│   └── singularity/               # HPC Singularity job scripts (2 files)
├── results/                       # Pipeline output (per disease set)
├── validation/                    # 4-step known-drug validation pipeline
├── case_study_special/            # Disease-specific case studies
├── logs/                          # Execution logs
└── venv/                          # Python 3.10 virtual environment
```

---

## Prerequisites

### R (≥ 4.2)

```r
# Install DRpipe (from repository root)
devtools::install("DRpipe")

# Additional packages used by analysis/visualization scripts
install.packages(c("readxl", "gridExtra", "ggplot2", "patchwork",
                   "VennDiagram", "arrow", "cowplot", "here"))
```

### Python (≥ 3.9)

```bash
cd tahoe_cmap_analysis
python3 -m venv venv
source venv/bin/activate
pip install pandas numpy pyarrow pyreadr tables joblib tqdm \
            matplotlib seaborn scipy openpyxl scikit-learn
```

Key Python packages:
- `pyarrow` / `pyarrow.parquet` — Parquet I/O for known-drug data
- `tables` (PyTables) — HDF5/H5 file handling for raw TAHOE data
- `pyreadr` — Reading RData files from Python
- `joblib` — Parallel processing for large filtering jobs

### Data Downloads

Drug signature databases (too large for Git) must be placed in `data/drug_signatures/`:
- See the main repository [README](../README.md#51-required-data-files) for download links
- Both CMAP and TAHOE RData files are needed for the full comparative analysis

---

## Data

### `data/disease_signatures/`

| Subdirectory | Contents |
|---|---|
| `CREEDS/` | Original CREEDS disease signatures (raw download) |
| `creeds_manual_disease_signatures/` | Manually curated CREEDS signatures |
| `creeds_manual_disease_signatures_standardised/` | Standardized versions (column-renamed) |
| `creeds_manual_disease_signatures_shared_genes/` | Filtered to shared CMAP/TAHOE genes |
| `90_subset_creeds_manual_disease_signatures_shared_genes/` | 90-disease subset used in main analysis |
| `sirota_lab_disease_signatures/` | Sirota Lab disease signatures (raw + standardized) |
| `6_tomiko_diseases_signatures_v1/` | 6 Tomiko endometriosis reference signatures |
| `case_study/`, `case_study_v2_selected/` | Case study subsets |
| `test_disease_signature/` | Test/debug signature |

Metadata: `creeds_disease_gene_counts_across_stages.csv` tracks gene counts at each preprocessing stage.

### `data/drug_signatures/`

| Subdirectory | Contents |
|---|---|
| `cmap/` | CMAP signatures (RData), experiment metadata, valid instances |
| `tahoe/` | TAHOE signatures (RData), experiment metadata, valid instances |

### `data/known_drugs/`

Open Targets data in Parquet format for known-drug validation:
- `known_drug_info_data.parquet` — Master known drug-disease associations
- `disease.parquet`, `disease_phenotype.parquet` — Disease metadata

### `data/analysis/`

Processed analysis summaries:
- `Exp8_Analysis.xlsx` — Master analysis matrix for 90-disease experiment
- Per-analysis output CSVs for endometriosis, case studies, etc.

---

## Scripts

### `scripts/preprocessing/` — Data Preparation (20 files)

Handles raw data extraction, gene filtering, signature standardization, and format conversion.

**Multi-part TAHOE pipeline** (designed for HPC):
1. `filter_tahoe_part_1_gene_filtering.py` — Filter raw TAHOE H5 to shared genes → Parquet
2. `filter_tahoe_part_2_ranking.py` — Rank filtered genes
3. `filter_tahoe_part_3a_rdata_all.R` / `3b_rdata_shared_drugs.R` — Convert to RData

**Disease signature processing:**
- `process_creeds_signatures.py` — Extract and process CREEDS signatures
- `standardize_creeds_signatures.py` — Rename columns, standardize format
- `standardize_endo_signatures.py` — Standardize endometriosis signatures
- `process_sirota_lab_signatures.py` — Process Sirota Lab signatures

**Known-drug data:**
- `processing_known_drugs_data.py` — Process Open Targets / ChEMBL data
- `create_known_drugs_json.py` — Create JSON lookup for known drugs

**Utilities:**
- `utils.py` — `normalize_drug_name()`, `normalize_cell_line_name()` functions
- `generate_valid_instances.py` — Create valid experiment instance lists (correlation-based QC)
- `filter_shared_drugs_cmap_tahoe.py` — Identify drugs present in both databases
- `filter_cmap_data.py` — Filter CMAP to shared genes/drugs

### `scripts/execution/` — Pipeline Execution (14 files)

Batch-run DRpipe across diseases and databases.

**Core entry point:**
```bash
Rscript scripts/execution/run_batch_from_config.R --config scripts/execution/batch_configs/90_selected_diseases.yml
```

**Batch configuration files** in `batch_configs/`:
| Config | Description |
|--------|-------------|
| `90_selected_diseases.yml` | Main 90-disease CMAP + TAHOE run |
| `19_endo_standardized.yml` | 19 endometriosis signatures |
| `6_tomiko_endo.yml` | 6 Tomiko endometriosis signatures |
| `creeds_manual_config_all_avg.yml` | Full CREEDS manual with averaging |
| `sirota_lab_config_all_avg.yml` | Full Sirota Lab with averaging |
| `case_study.yml`, `case_study_v2.yml` | Case study subsets |
| `test_config.yml` | Small test run |

**Config structure:**
```yaml
disease:
  source: "90 selected diseases"
  directory: "/path/to/disease_signatures/"
cmap:
  signatures: "/path/to/cmap_signatures_shared_genes.RData"
  metadata: "/path/to/cmap_drug_experiments_new.csv"
tahoe:
  signatures: "/path/to/tahoe_signatures_shared_genes_only.RData"
  metadata: "/path/to/tahoe_drug_experiments_new.csv"
analysis:
  gene_table: "/path/to/gene_id_conversion_table.tsv"
  qval_threshold: 0.05
  logfc_column_selection: "all"
  use_averaging: true
  percentile_filtering:
    enabled: true
    threshold: 75
output:
  root_directory: "/path/to/results/"
```

**Supporting scripts:**
- `check_progress.sh` — Monitor batch progress
- `restart_pipeline.sh` — Resume interrupted pipeline
- `apply_percentile_filter.R` — Percentile-based gene filtering
- `convert_signatures_to_rds.R` — RData → RDS conversion for faster loading

### `scripts/analysis/` — Comparative Analysis (18 files)

Post-hoc analysis comparing CMAP and TAHOE results.

**Key scripts:**
- `compare_tahoe_cmap.py` — Compare drugs, cell lines, genes between platforms
- `compare_databases.R` — Comprehensive CMAP vs TAHOE statistical comparison
- `compile_drug_hits.py` — Compile drug hit lists across diseases
- `extract_pipeline_results_analysis.py` — Aggregate pipeline outputs
- `overlap_analysis.py` — Gene and drug overlap analysis
- `compare_endometriosis.R` — Endometriosis-specific platform comparison
- `analyze_manuscript_data.R` — Generate manuscript-ready statistics
- `analyze_phase4_concordance.R` — Phase 4 clinical trial concordance

### `scripts/visualization/` — Figure Generation (31 files)

All charts and figures for analysis and manuscript.

**Categories:**
- **Heatmaps**: `create_heatmaps_cmap_tahoe.R`, `create_heatmaps_cmap_tahoe_top50.R`
- **Gene visualizations**: `create_gene_overlaps.R`, `create_gene_profiles.R`
- **Venn diagrams**: `create_venn_full_datasets.R`, `create_venn_platform_coverage.R`
- **Precision/recall**: `create_precision_recall_beautiful.R`, `create_recall_focused_visualizations.R`
- **Manuscript figures**: `generate_manuscript_figures.R`, `generate_extended_manuscript_figures.R`
- **Disease analysis**: `generate_disease_specific_analysis.R`, `generate_disease_analysis_known_drugs_only.R`
- **Block charts**: `generate_block1_CORRECTED.R`, `generate_block2_CORRECTED.R`, `generate_block3_CORRECTED.R`
- **Python helpers**: `plot_compare_tahoe_cmap_qvalues.py`, `plot_disease_signature_info.py`

### `scripts/extraction/` — Case Study Extraction (3 files)

- `extract_case_study_all_steps.R` — Consolidates all processing steps
- `extract_case_study_complete.R` — Alternative extraction
- `regenerate_volcano_plots_fixed.R` — Regenerate disease-specific volcano plots

### `scripts/singularity/` — HPC Execution (2 files)

Shell scripts for running TAHOE preprocessing on HPC clusters via Singularity:
- `run_OG_tahoe_part_1.sh` — Gene filtering on HPC
- `run_OG_tahoe_part2_rank_and_save_parquet.sh` — Ranking on HPC

---

## Results

Pipeline outputs organized by disease set:

| Directory | Description |
|---|---|
| `90_selected_diseases_shared_genes/` | Main 90-disease CMAP + TAHOE results |
| `19_endo_standardized/` | 19 endometriosis signature results |
| `6_tomiko_endo_v1/`, `6_tomiko_endo_v2/` | Tomiko endometriosis variants |
| `creed_manual_standardised_results_OG_exp_8/` | CREEDS experiment 8 (all diseases) |
| `sirota_lab_standardised_results_OG_exp_10/` | Sirota Lab experiment 10 |
| `case_study_results/`, `case_study_v2/` | Case study outputs |

Each result folder typically contains per-disease subfolders with:
- `*_hits_*.csv` — Significant drug hits (filtered by q-value)
- `*_results.RData` — Complete R results object
- `img/` — Generated plots (histograms, bar charts)

---

## Validation Pipeline

Four-step known-drug recovery validation in `validation/`:

### Step 1: Drug Overlap (`step_1_drug_overlap/`)
Analyzes overlap of drugs between CMAP, TAHOE, and known-drug databases.

### Step 2: Disease Overlap (`step_2_disease_overlap/`)
Matches disease names across pipeline output, DailyMed, DrugBank, and Open Targets.

### Step 3: Disease-Drug Pair Identification (`step_3_max_disease_drug_pairs/`)
Creates maximum disease-drug pairs for validation.

### Step 4: DRpipe Validation (`step_4_drpipe_validation/`)
Compares pipeline predictions against known therapeutic drugs. Calculates precision, recall, and recovery rates.

### Known-Drug Databases (`validation/known_drugs/`)
- `chembldb_known_drugs/` — ChEMBL disease-drug associations
- `dailymed_known_drugs/` — DailyMed FDA label data
- `drug_bank_known_drugs/` — DrugBank drug-indication pairs
- `open_target_known_drugs/` — Open Targets therapeutic associations

### Autoimmune Validation (`validation/20_autoimmune_results_1/`)
- 20 autoimmune diseases with detailed drug recovery analysis
- `20_autoimmune.xlsx` — Summary tables
- `drug_details/` — Per-disease drug-level results

### Endometriosis Threshold Analysis (`validation/endo_disease_signatures/`)
- Threshold optimization for endometriosis signatures
- UpSet plots, hit comparisons, and recommendation docs

---

## Case Studies

### `case_study_special/case_study_1_autoimmune/`

5-disease autoimmune case study with per-disease directories:
1. Autoimmune thrombocytopenic purpura
2. Cerebral palsy
3. Eczema
4. Chronic lymphocytic leukemia
5. Endometriosis of ovary

Each contains: disease signature, CMAP/TAHOE results, per-disease figures, and `4_disease_results.xlsx`.

### `case_study_special/case_study_disease_category/`

Disease-category level analysis for the manuscript:
- `about_diseases/` — Disease metadata and categories
- `about_drugs/` — Drug annotations and target classes
- `about_drpipe_results/` — Pipeline results aggregated by category
- `write_up_paper/` — Data tables for manuscript text

---

## Reproducing the Analysis

### Full Pipeline (90 Diseases)

```bash
cd tahoe_cmap_analysis

# 1. Activate Python environment (for preprocessing if needed)
source venv/bin/activate

# 2. Ensure disease signatures are standardized
python3 scripts/preprocessing/standardize_creeds_signatures.py

# 3. Run the batch pipeline (CMAP + TAHOE, 90 diseases)
Rscript scripts/execution/run_batch_from_config.R \
  --config scripts/execution/batch_configs/90_selected_diseases.yml

# 4. Analyze results
Rscript scripts/analysis/compare_databases.R
python3 scripts/analysis/compile_drug_hits.py

# 5. Generate figures
Rscript scripts/visualization/generate_manuscript_figures.R
```

### Endometriosis Sub-Analysis

```bash
Rscript scripts/execution/run_batch_from_config.R \
  --config scripts/execution/batch_configs/19_endo_standardized.yml
```

### Validation

```bash
# Run 4-step validation pipeline
# Step 1-3: Disease/drug overlap matching
# Step 4: Known-drug recovery
# See validation/known_drugs/README.md for details
```

### Generate Manuscript Figures Only

If results already exist, regenerate figures without re-running the pipeline:

```bash
Rscript scripts/visualization/generate_manuscript_figures.R
Rscript scripts/visualization/generate_extended_manuscript_figures.R
Rscript scripts/visualization/create_heatmaps_cmap_tahoe_top50.R
Rscript scripts/visualization/create_precision_recall_beautiful.R
```

---

## Logs & Archived Files

- `logs/` — All pipeline execution logs (`batch_run_*.log`, `pipeline_*.log`)
- Archived figures (1,000+ files): `../dump/tahoe_cmap_all_figures/`
- Retired scripts and data: `../dump/tahoe_cmap_retired/`
