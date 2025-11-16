# TAHOE-CMAP Analysis Scripts Documentation

This document provides detailed descriptions of all scripts in the `tahoe_cmap_analysis/scripts/` directory, organized by their function in the analysis pipeline.

## Table of Contents

1. [Data Preprocessing & Filtering](#data-preprocessing--filtering)
2. [Pipeline Execution](#pipeline-execution)
3. [Results Compilation & Analysis](#results-compilation--analysis)
4. [Comparison & Diagnostics](#comparison--diagnostics)
5. [Visualization](#visualization)
6. [Utilities](#utilities)

---

## Data Preprocessing & Filtering

### `filter_cmap_data.py`
**Purpose:** Filters CMAP drug signature data to include only shared genes and shared drugs between CMAP and TAHOE databases.

**Key Operations:**
- Loads raw CMAP signatures from RData file (~1,309 drugs, ~22,000 genes)
- Filters to 12,544 shared genes (common with TAHOE)
- Filters to 61 shared drugs (present in both databases)
- Generates two output files:
  - `cmap_genes_filtered.RData` - Gene-filtered only (all CMAP drugs)
  - `cmap_genes_drugs.RData` - Gene and drug filtered (shared drugs only)
- Performs extensive QC checks on gene counts, drug counts, and data integrity
- Generates a summary report: `cmap_signature_versions_report.txt`

**Input Files:**
- `cmap_signatures.RData` - Raw CMAP signatures
- `cmap_drug_experiments_new.csv` - CMAP experiment metadata
- `shared_genes_tahoe_cmap.csv` - List of shared genes
- `shared_drugs_tahoe_cmap.csv` - List of shared drugs

**Output Files:**
- `cmap_genes_filtered.RData` - Intermediate filtered data
- `cmap_genes_drugs.RData` - Final filtered data for pipeline
- `cmap_signature_versions_report.txt` - QC report

**Runtime:** ~5-10 minutes

---

### `filter_tahoe_part1_gene_filtering.py`
**Purpose:** Filters massive TAHOE H5 file (~300K genes, 56,827 experiments) to shared genes and drugs. This is Part 1 of a multi-part TAHOE filtering pipeline.

**Key Operations:**
- Streams data from large H5 file (`aggregated.h5`) in parallel chunks
- Filters to 12,544 shared genes across all 56,827 experiments
- Ranks gene expression values (CMap-style ranking)
- Filters to experiments for 61 shared drugs
- Generates two output files:
  - `tahoe_genes_filtered.RData` - Gene-filtered (all experiments)
  - `tahoe_genes_drugs.RData` - Gene and drug filtered (shared drugs only)
- Uses parallel processing to handle large dataset efficiently

**Input Files:**
- `aggregated.h5` - Raw TAHOE data (~300K genes)
- `genes.parquet` - Gene metadata
- `experiments.parquet` - Experiment metadata
- `tahoe_drug_experiments_new.csv` - TAHOE experiment-drug mapping
- `shared_genes_tahoe_cmap.csv` - Shared genes list
- `shared_drugs_tahoe_cmap.csv` - Shared drugs list

**Output Files:**
- `tahoe_l2fc_shared_genes_all_drugs.parquet` - Intermediate filtered data
- `tahoe_genes_filtered.RData` - Gene-filtered ranked data
- `tahoe_genes_drugs.RData` - Final filtered data for pipeline
- `tahoe_signature_versions_report.txt` - Summary report

**Runtime:** Several hours (recommended to run on HPC)

**Note:** For HPC execution, use `create_tahoe_og_signatures_hpc.py` instead.

---

### `filter_tahoe_part2_ranking.py`
**Purpose:** Part 2 of TAHOE filtering - ranks gene expression values after gene filtering.

**Note:** This functionality is now integrated into `filter_tahoe_part1_gene_filtering.py`.

---

### `filter_tahoe_part3a_rdata_all.R`
**Purpose:** Converts filtered TAHOE data to RData format (all drugs version).

**Key Operations:**
- Reads filtered Parquet data
- Converts to R-compatible RData format
- Saves as `tahoe_genes_filtered.RData`

**Note:** This functionality is now integrated into the Python pipeline.

---

### `filter_tahoe_part3b_rdata_shared_drugs.R`
**Purpose:** Converts filtered TAHOE data to RData format (shared drugs only version).

**Key Operations:**
- Reads filtered Parquet data
- Filters to shared drugs
- Converts to R-compatible RData format
- Saves as `tahoe_genes_drugs.RData`

**Note:** This functionality is now integrated into the Python pipeline.

---

### `filter_shared_drugs.py`
**Purpose:** Identifies drugs common to both CMAP and TAHOE databases and filters compiled results to include only these shared drugs.

**Key Operations:**
- Compares drug names between CMAP and TAHOE (case-insensitive)
- Identifies 61 drugs present in both databases
- Saves list of shared drugs
- Filters compiled drug hits to shared drugs only
- Generates summary statistics for shared drug subset

**Input Files:**
- `cmap_drug_experiments_new.csv` - CMAP metadata
- `tahoe_drug_experiments_new.csv` - TAHOE metadata
- `all_drug_hits_compiled.csv` - Full compiled results

**Output Files:**
- `shared_drugs_cmap_tahoe.csv` - List of 61 shared drugs
- `all_drug_hits_compiled_shared_only.csv` - Filtered results
- `drug_hits_summary_shared_only.csv` - Summary statistics

**Runtime:** < 1 minute

---

### `create_tahoe_og_signatures_hpc.py`
**Purpose:** HPC-optimized version of TAHOE filtering for large-scale processing on high-performance computing clusters.

**Key Features:**
- Optimized for parallel processing on HPC systems
- Handles full TAHOE dataset efficiently
- Uses Singularity containers for reproducibility
- Generates same outputs as `filter_tahoe_part1_gene_filtering.py`

**Usage:** Run via `singularity/run_filter_tahoe_data.sh` on HPC

---

## Pipeline Execution

### `run_all_diseases_batch.R`
**Purpose:** Main batch execution script that runs the drug repurposing pipeline for all diseases using both CMAP and TAHOE drug signatures.

**Key Operations:**
- Processes all disease signature files in the specified directory
- For each disease, runs TWO analyses:
  1. CMAP drug signatures analysis
  2. TAHOE drug signatures analysis
- Uses DRpipe R package for connectivity scoring
- Generates comprehensive results including:
  - Drug hits CSV files (with connectivity scores, p-values, q-values)
  - RData files with full analysis results
  - Visualization plots (heatmaps, histograms, upset plots)
- Creates batch execution logs and summary files
- Tracks success/failure status for each run

**Configuration:**
- `logfc_cutoff: 0.0` - No logFC filtering (accept all genes)
- `pval_cutoff: 1.0` - No p-value filtering
- `q_thresh: 1.0` - Accept all q-values (filter later)
- `reversal_only: FALSE` - Accept both reversal and mimicry
- `cmap_valid_path: NULL` - No instance filtering

**Input Files:**
- Disease signature files (`*_signature.csv`)
- `cmap_genes_drugs.RData` or `tahoe_genes_drugs.RData`
- `cmap_drug_experiments_new.csv` or `tahoe_drug_experiments_new.csv`

**Output Structure:**
```
results/
├── batch_run_log_TIMESTAMP.txt
├── batch_run_summary_TIMESTAMP.csv
└── [Disease]_[CMAP|TAHOE]_TIMESTAMP/
    ├── file*_hits_q<1.00.csv
    ├── file*_results.RData
    ├── file*_random_scores_logFC_0.RData
    └── img/
        ├── heatmap_*.png
        ├── histogram_*.png
        └── upset_*.png
```

**Runtime:** Several hours for 58 diseases × 2 methods = 116 runs

---

### `run_single_disease_test.R`
**Purpose:** Test script for running the pipeline on a single disease for debugging and validation.

**Key Operations:**
- Runs pipeline for one disease with both CMAP and TAHOE
- Useful for testing parameter changes
- Quick validation of pipeline functionality

**Usage:** Modify disease file path and run for testing

**Runtime:** ~2-5 minutes per disease

---

### `run_creeds_automatic_batch.R`
**Purpose:** Batch execution script specifically for CREEDS disease signatures with automatic processing.

**Key Features:**
- Processes CREEDS-formatted disease signatures
- Automated preprocessing of CREEDS data format
- Runs both CMAP and TAHOE analyses

---

### `run_creeds_manual_batch.R`
**Purpose:** Batch execution script for manually curated CREEDS disease signatures.

**Key Features:**
- Processes manually curated/validated CREEDS signatures
- Additional quality control steps
- Runs both CMAP and TAHOE analyses

---

### `run_sirota_lab_batch.R`
**Purpose:** Batch execution script for Sirota Lab disease signatures.

**Key Features:**
- Processes disease signatures from Sirota Lab datasets
- Handles Sirota Lab-specific data formats
- Runs both CMAP and TAHOE analyses

---

### `temp_run_sirota_lab_batch.R`
**Purpose:** Temporary/experimental version of Sirota Lab batch script for testing.

---

## Results Compilation & Analysis

### `compile_drug_hits.py`
**Purpose:** Compiles drug repurposing results from all pipeline runs into master datasets with summary statistics.

**Key Operations:**
- Scans all result directories from batch runs
- Reads individual drug hits CSV files
- Combines into comprehensive datasets:
  - All drug hits with disease and method annotations
  - Summary statistics per disease (hit counts, common drugs)
- Identifies drugs found by both CMAP and TAHOE (consensus predictions)
- Calculates unique drugs per method

**Input Files:**
- `batch_run_summary_TIMESTAMP.csv` - Batch run metadata
- Individual `*_hits_q<1.00.csv` files from each run

**Output Files:**
- `all_drug_hits_compiled.csv` - Complete list of all drug hits
- `drug_hits_summary.csv` - Summary statistics by disease

**Summary Statistics Provided:**
- Total CMAP hits
- Total TAHOE hits
- Common drug hits (consensus predictions)
- Diseases with hits per method

**Runtime:** < 1 minute

---

### `extract_pipeline_results.py`
**Purpose:** Advanced analysis script that aggregates pipeline results, matches diseases to official IDs, and validates predictions against known drug-disease associations from Open Targets.

**Key Operations:**
- Scans pipeline result directories
- Matches disease names to official disease IDs using:
  - Direct name matching
  - Synonym matching from disease ontology
- Filters results by multiple q-value thresholds (0.5, 0.1, 0.05)
- Compares pipeline predictions against known drugs from Open Targets
- Extracts drug phase and status information for validated hits
- Generates three types of outputs per q-value threshold:
  1. Summary CSV with counts and phase/status pivots
  2. Drug lists CSV with detailed drug names per category
  3. Hierarchical JSON with complete analysis details

**Input Files:**
- Pipeline result directories (e.g., `sirota_lab_disease_results_genes_drugs/`)
- `disease_info_data.parquet` - Disease ontology and synonyms
- `known_drug_info_data.parquet` - Known drug-disease associations

**Output Files (per q-value threshold):**
- `analysis_summary_[folder]_q[X].csv` - Aggregate counts and statistics
- `analysis_drug_lists_[folder]_q[X].csv` - Detailed drug lists
- `analysis_details_[folder]_q[X].json` - Complete hierarchical data
- `pipeline_analysis_report_[folder].txt` - Summary report

**Categories Analyzed:**
- TAHOE hits (total and validated)
- CMAP hits (total and validated)
- Common hits (consensus predictions)
- Drug phase distribution (Phase 0-4)
- Drug status distribution (Approved, Clinical trials, etc.)

**Usage:**
```bash
python extract_pipeline_results.py \
    --input_dir results/sirota_lab_disease_results_genes_drugs \
    --output_dir data/analysis
```

**Runtime:** ~5-10 minutes depending on dataset size

---

### `extract_filter_results_to_shared_drugs.py`
**Purpose:** Extracts and filters pipeline results to focus on the shared drug subset for direct method comparison.

**Key Operations:**
- Filters results to 61 shared drugs only
- Enables direct CMAP vs TAHOE comparison
- Generates shared-drug-specific summaries

**Output Files:**
- Filtered results for shared drugs
- Comparative statistics

---

### `extract_selected_disease_info.py`
**Purpose:** Extracts detailed information for specific diseases of interest from the analysis results.

**Key Operations:**
- Filters analysis results for selected diseases
- Extracts comprehensive disease-specific data
- Generates focused reports for diseases of interest

---

## Comparison & Diagnostics

### `compare_tahoe_cmap.py`
**Purpose:** Comprehensive comparison of CMAP and TAHOE results across all diseases to identify systematic differences.

**Key Operations:**
- Compares drug hits between methods
- Analyzes overlap and unique predictions
- Identifies method-specific patterns
- Generates comparison statistics

**Output:**
- Comparative analysis tables
- Method performance metrics
- Overlap statistics

---

### `compare_tahoe_cmap_qvalues.py`
**Purpose:** Detailed comparison of q-value distributions between CMAP and TAHOE to diagnose statistical issues.

**Key Operations:**
- Loads results from both CMAP and TAHOE for each disease
- Compares q-value distributions
- Identifies diseases with q=0 issues (flat distributions)
- Generates diagnostic plots for each disease:
  - Connectivity score histograms
  - P-value distributions
  - Q-value comparisons
  - Box plots and density plots
- Classifies issues by type:
  - `BOTH_FLAT` - Both methods have q=0 problem
  - `TAHOE_FLAT` - Only TAHOE has q=0 problem
  - `CMAP_FLAT` - Only CMAP has q=0 problem
  - `HEALTHY` - No systematic issues
- Generates summary CSV with statistics for all diseases

**Input Files:**
- Individual disease result folders (CMAP and TAHOE)
- `*_hits_*.csv` files from each run

**Output Files:**
- `tahoe_cmap_qvalue_comparison_summary.csv` - Summary statistics
- Individual comparison plots for each disease (PNG)

**Diagnostic Metrics:**
- Percentage of drugs with q=0
- Percentage of drugs with p=0
- Connectivity score statistics (mean, median, std, range)
- Number of unique p-values and q-values

**Usage:** Helps identify whether q-value issues are:
- TAHOE-specific (permutation/FDR code issue)
- Disease-specific (signature quality issue)
- Global pipeline issue (FDR implementation)

**Runtime:** ~5-10 minutes for 58 diseases

---

### `compare_cmap_tahoe_random_scores.py`
**Purpose:** Compares null distributions (random scores) between CMAP and TAHOE to diagnose p-value calculation issues.

**Key Operations:**
- Loads random score distributions from RData files
- Compares statistical properties:
  - Mean, median, standard deviation
  - Min, max, quartiles
  - Percentage of zero values
- Performs statistical tests:
  - Kolmogorov-Smirnov test (distribution similarity)
  - Mann-Whitney U test (median comparison)
  - Levene's test (variance equality)
- Generates comprehensive visualizations:
  - Histograms (individual and overlaid)
  - Density plots (individual and overlaid)
  - Box plots
  - Q-Q plots (normality check)

**Input Files:**
- `*_random_scores_logFC_0.RData` files from CMAP and TAHOE runs

**Output Files:**
- Comparison visualization (PNG)
- Console output with statistical test results

**Use Case:** Diagnose why TAHOE might have different p-value distributions than CMAP by examining the null distributions used for permutation testing.

**Runtime:** < 1 minute

---

### `diagnose_corefibroid_q_values.py`
**Purpose:** Specific diagnostic script for investigating q-value issues in CoreFibroid disease analysis.

**Key Operations:**
- Deep dive into CoreFibroid results
- Examines p-value to q-value conversion
- Identifies FDR correction issues
- Generates detailed diagnostic reports

---

### `validate_pvalue_fix.R`
**Purpose:** Validates fixes to p-value calculation issues in the pipeline.

**Key Operations:**
- Tests p-value calculation methods
- Validates permutation testing
- Ensures FDR correction is working correctly
- Generates validation reports

---

## Visualization

### `visualize_random_scores.py`
**Purpose:** Creates visualizations of random score distributions for quality control and diagnostics.

**Key Operations:**
- Loads random scores from RData files
- Generates distribution plots
- Compares across methods and diseases
- Identifies outliers or anomalies

**Output:**
- Distribution plots (histograms, density plots)
- Summary statistics visualizations

---

### `theodoris_create_faceted_overlap_matrices.py`
**Purpose:** Creates faceted overlap matrices for Theodoris Lab disease analysis showing drug-disease relationships.

**Key Operations:**
- Generates overlap matrices between diseases
- Creates faceted visualizations
- Shows shared drug patterns across diseases

**Output:**
- Faceted overlap matrix plots
- Drug-disease relationship visualizations

---

### `theodoris_lab_disease_analysis.py`
**Purpose:** Specialized analysis script for Theodoris Lab disease signatures.

**Key Operations:**
- Processes Theodoris Lab-specific data formats
- Generates lab-specific analyses
- Creates custom visualizations

---

## Disease Signature Processing

### `process_creeds_signatures.py`
**Purpose:** Processes disease signatures from the CREEDS database into pipeline-compatible format.

**Key Operations:**
- Downloads/loads CREEDS disease signatures
- Converts to standardized format (gene symbols, log2FC)
- Validates data quality
- Saves processed signatures

**Input:** CREEDS database files

**Output:** Processed disease signature CSV files

---

### `process_sirota_lab_signatures.py`
**Purpose:** Processes disease signatures from Sirota Lab datasets into pipeline-compatible format.

**Key Operations:**
- Loads Sirota Lab disease data
- Standardizes gene identifiers
- Converts to pipeline format
- Validates signatures

**Input:** Sirota Lab data files

**Output:** Processed disease signature CSV files

---

### `processing_open_target_data.py`
**Purpose:** Processes Open Targets Platform data for drug-disease association validation.

**Key Operations:**
- Downloads/loads Open Targets data
- Extracts drug-disease associations
- Processes clinical trial information
- Formats for validation pipeline

**Input:** Open Targets Platform data

**Output:** 
- `known_drug_info_data.parquet` - Known drug-disease associations
- `disease_info_data.parquet` - Disease ontology information

---

### `preprocess_disease_file.R`
**Purpose:** Preprocesses disease signature files to ensure compatibility with DRpipe.

**Key Operations:**
- Standardizes column names
- Validates gene identifiers
- Checks data format
- Converts to required format

---

## Utilities

### `utils.py`
**Purpose:** Shared utility functions used across multiple scripts.

**Key Functions:**
- `normalize_drug_name()` - Standardizes drug names for matching
- `clean_text()` - Text cleaning for comparisons
- Data loading helpers
- File path utilities

**Usage:** Imported by other scripts as needed

---

## Legacy Scripts (Deprecated)

### `old_generate_drug_hits_evidence_summaries.py`
**Purpose:** Old version of evidence summary generation (replaced by `extract_pipeline_results.py`)

**Status:** Deprecated - use `extract_pipeline_results.py` instead

---

### `old_merge_drug_evidence_hits_to_json.py`
**Purpose:** Old version of JSON evidence merging (replaced by `extract_pipeline_results.py`)

**Status:** Deprecated - use `extract_pipeline_results.py` instead

---

## Typical Workflow

### 1. Data Preparation
```bash
# Filter CMAP data
python filter_cmap_data.py

# Filter TAHOE data (HPC recommended)
python create_tahoe_og_signatures_hpc.py
# OR locally (slow):
python filter_tahoe_part1_gene_filtering.py

# Process disease signatures
python process_creeds_signatures.py
python process_sirota_lab_signatures.py
```

### 2. Pipeline Execution
```bash
# Run all diseases with both methods
Rscript run_all_diseases_batch.R

# OR run specific disease sets
Rscript run_creeds_automatic_batch.R
Rscript run_sirota_lab_batch.R
```

### 3. Results Compilation
```bash
# Compile all results
python compile_drug_hits.py

# Identify shared drugs
python filter_shared_drugs.py

# Extract and validate results
python extract_pipeline_results.py \
    --input_dir results/batch_results \
    --output_dir data/analysis
```

### 4. Comparison & Diagnostics
```bash
# Compare methods
python compare_tahoe_cmap_qvalues.py

# Diagnose issues
python compare_cmap_tahoe_random_scores.py
python diagnose_corefibroid_q_values.py
```

### 5. Visualization
```bash
# Generate visualizations
python visualize_random_scores.py
python theodoris_create_faceted_overlap_matrices.py
```

---

## Key Parameters Across Scripts

### Q-value Thresholds
- **0.05** - Highly stringent (high confidence)
- **0.1** - Moderate (balanced sensitivity/specificity)
- **0.5** - Lenient (exploratory analysis)

### Pipeline Settings (in R scripts)
- `logfc_cutoff: 0.0` - No logFC filtering
- `pval_cutoff: 1.0` - No p-value filtering
- `q_thresh: 1.0` - Accept all (filter post-hoc)
- `reversal_only: FALSE` - Accept reversal and mimicry

### Data Dimensions
- **Shared genes:** 12,544 (common to CMAP and TAHOE)
- **Shared drugs:** 61 (present in both databases)
- **CMAP drugs:** 1,309 total
- **TAHOE drugs:** 379 total
- **TAHOE experiments:** 56,827

---

## Troubleshooting

### Common Issues

**1. Memory errors in TAHOE filtering**
- Solution: Use HPC version (`create_tahoe_og_signatures_hpc.py`)
- Or: Reduce chunk size in parallel processing

**2. Q-value = 0 for all drugs**
- Diagnosis: Run `compare_tahoe_cmap_qvalues.py`
- Check: Random score distributions with `compare_cmap_tahoe_random_scores.py`
- Validate: Use `validate_pvalue_fix.R`

**3. Missing disease matches in extraction**
- Check: Disease name formatting
- Review: Synonym matching in `extract_pipeline_results.py`
- Update: Disease ontology data if needed

**4. Drug name mismatches**
- Solution: Use `normalize_drug_name()` from `utils.py`
- Check: Case sensitivity in comparisons

---

## Output File Naming Conventions

### Pipeline Results
- `[Disease]_[CMAP|TAHOE]_[Timestamp]/` - Individual run directories
- `file*_hits_q<1.00.csv` - Drug hits (unfiltered)
- `file*_results.RData` - Complete R workspace
- `file*_random_scores_logFC_0.RData` - Null distributions

### Compiled Results
- `all_drug_hits_compiled.csv` - All drugs, all diseases
- `all_drug_hits_compiled_shared_only.csv` - Shared drugs only
- `drug_hits_summary.csv` - Summary statistics

### Analysis Results
- `analysis_summary_*_q[X].csv` - Counts and statistics
- `analysis_drug_lists_*_q[X].csv` - Drug name lists
- `analysis_details_*_q[X].json` - Hierarchical data

### Reports
- `batch_run_log_*.txt` - Execution logs
- `batch_run_summary_*.csv` - Run status summary
- `*_comparison_summary.csv` - Method comparisons
- `*_report.txt` - Analysis reports

---

## Dependencies

### Python Packages
- pandas, numpy - Data manipulation
- pyreadr - R data file I/O
- tables (pytables) - HDF5 file handling
- pyarrow - Parquet file handling
- matplotlib, seaborn - Visualization
- scipy - Statistical tests
- tqdm - Progress bars
- joblib - Parallel processing

### R Packages
- DRpipe - Drug repurposing pipeline
- tidyverse - Data manipulation
- ggplot2 - Visualization

---

## Contact & Support

For questions about specific scripts or issues:
1. Check the script's docstring for detailed usage
2. Review the main README.md for context
3. Examine the COMPREHENSIVE_STUDY_REPORT.md for methodology
4. Check output logs for error messages

---

**Last Updated:** November 2025
**Pipeline Version:** 1.0
**Status:** Under active development
