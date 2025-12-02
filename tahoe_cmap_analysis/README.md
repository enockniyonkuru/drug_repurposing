# TAHOE-CMAP Analysis

This directory contains a comprehensive comparative analysis exploring drug repurposing across two major drug signature databases: **CMAP** (Connectivity Map) and **TAHOE**.

## Overview

This analysis evaluates therapeutic candidates by comparing drug signatures from both CMAP and TAHOE databases across **233 disease signatures from CREEDS** (ChemicalRepository for Expression Information from Disease Studies). The goal was to:

- Identify robust drug-disease associations across both databases
- Assess method consistency across a large, diverse disease collection
- Discover high-confidence therapeutic candidates for drug repurposing
- Explore shared drug candidates between the two databases
- Demonstrate reproducibility and scalability of the pipeline

### Key Findings

- **6,161 total drug-disease associations** identified across both databases
- **33 high-confidence drugs** validated by both CMAP and TAHOE methods
- **61 drugs** present in both databases for direct method comparison
- Comprehensive coverage of 233 diverse disease categories with therapeutic potential

## Table of Contents

- [Directory Structure](#directory-structure)
- [Data Organization](#data-organization)
- [Analysis Scripts](#analysis-scripts)
- [Running the Analysis](#running-the-analysis)
- [Advanced Usage](#advanced-usage)
  - [Creating Valid Instances for Drug Signatures](#creating-valid-instances-for-drug-signatures)
  - [Filtering Disease Signatures](#filtering-disease-signatures)
  - [Filtering Drug Signatures](#filtering-drug-signatures)
  - [Running Batch Analysis with Custom Thresholds](#running-batch-analysis-with-custom-thresholds)
- [Methodology](#methodology)
- [Integration with DRpipe](#integration-with-drpipe)
- [Dependencies](#dependencies)
- [Related Documentation](#related-documentation)

## Directory Structure

```
tahoe_cmap_analysis/
├── README.md                    # This file
├── requirements.txt             # Python dependencies
├── data/
│   ├── disease_signatures/      # CREEDS disease signatures (233 diseases)
│   ├── drug_signatures/         # CMAP and TAHOE signatures
│   │   ├── cmap/               # CMAP database files and metadata
│   │   └── tahoe/              # TAHOE database files and metadata
│   ├── analysis/               # Processed analysis-ready datasets
│   ├── known_drugs/            # Drug validation and reference data
│   ├── shared_drugs_cmap_tahoe.csv
│   └── gene_id_conversion_table.tsv
├── scripts/                     # Analysis and processing scripts
│   ├── analysis/               # Comparative analysis scripts
│   ├── preprocessing/          # Data preprocessing and filtering
│   ├── execution/              # Batch processing and pipeline execution
│   ├── visualization/          # Plotting and visualization scripts
│   └── singularity/            # Container definitions
├── results/                     # Filtered analysis outputs
├── reports/                     # Batch execution reports and logs
└── venv/                        # Python virtual environment
```

## Data Organization

### Input Data (`data/`)

#### disease_signatures/
Contains 233 disease signatures from CREEDS:
- Individual disease CSV files with gene expression data
- Standard format: gene identifiers + log2 fold-change values
- Source: ChemicalRepository for Expression Information from Disease Studies

#### drug_signatures/
CMAP and TAHOE database files:

**CMAP Data** (`drug_signatures/cmap/`)
- `cmap_signatures.RData` - Drug-induced gene expression signatures
- `cmap_drug_experiments_new.csv` - Experiment metadata (drug names, cell lines, doses)

**TAHOE Data** (`drug_signatures/tahoe/`)
- `tahoe_signatures.RData` - TAHOE drug-induced signatures
- `tahoe_drug_experiments_new.csv` - TAHOE experiment metadata
- `checkpoint_ranked_all_genes_all_drugs.parquet` - Ranked signatures (intermediate)

#### known_drugs/
External drug reference data for validation and annotation

#### gene_id_conversion_table.tsv
Mapping between different gene identifier formats (SYMBOL, ENSEMBL, ENTREZ)

#### shared_drugs_cmap_tahoe.csv
List of 61 drugs present in both CMAP and TAHOE databases

### Analysis Output Files

**Compiled Results** (`data/analysis/`)
- `all_drug_hits_compiled.csv` - Complete drug-disease associations
- `drug_hits_summary.csv` - Summary statistics per disease
- `full_annotated_hits_with_open_targets.csv` - Results with external evidence

**JSON Format** (For programmatic access)
- `drug_disease_combined.json` - Full analysis results as nested dictionary
- `drug_disease_combined_shared.json` - Shared drug subset in dictionary format

## Analysis Scripts

### Preprocessing (`scripts/preprocessing/`)

**Data Preparation:**
- `process_creeds_signatures.py` - Load and standardize CREEDS disease signatures
- `standardize_creeds_signatures.py` - Convert various signature formats to standard
- `processing_known_drugs_data.py` - Prepare external drug reference data
- `process_sirota_lab_signatures.py` - Process Sirota Lab signature data

**Drug Signature Filtering:**
- `filter_cmap_data.py` - Filter CMAP signatures with configurable thresholds
- `filter_tahoe_part_1_gene_filtering.py` - Stage 1: Gene-level quality control
- `filter_tahoe_part_2_ranking.py` - Stage 2: Signature ranking
- `filter_tahoe_part_3a_rdata_all.R` - Stage 3: Export all drugs to R format
- `filter_tahoe_part_3b_rdata_shared_drugs.R` - Stage 3: Export shared drugs to R format

**Quality Control:**
- `generate_valid_instances.py` - Generate valid signature instances based on replicate consistency
- `filter_shared_drugs_cmap_tahoe.py` - Extract and validate shared drug subset

**Utilities:**
- `utils.py` - Common functions and helper methods

### Analysis (`scripts/analysis/`)

**Comparative Analysis:**
- `compare_cmap_tahoe.py` - Main pipeline comparing CMAP and TAHOE predictions
- `compare_cmap_tahoe_random_scores.py` - Statistical validation against random backgrounds
- `compile_drug_hits.py` - Aggregate results across all 233 diseases
- `extract_filter_results_to_shared_drugs.py` - Focus analysis on 61 shared drugs

**Result Extraction:**
- `extract_pipeline_results_analysis.py` - Extract results from pipeline outputs
- `extract_selected_disease_info.py` - Pull disease-specific analysis details

### Batch Execution (`scripts/execution/`)

**Batch Processing:**
- `run_batch_from_config.R` - Execute batch analysis from YAML configuration (recommended)
- `run_drpipe_batch.R` - Generic batch runner with command-line parameters
- `batch_configs/` - Pre-configured batch execution templates

**Legacy Scripts** (Reference):
- `run_creeds_manual_batch.R` - Original CREEDS MANUAL batch script
- `run_sirota_lab_batch.R` - Original Sirota Lab batch script

## Running the Analysis

### Quick Setup
```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Single Disease Analysis
```bash
cd scripts/analysis
python compare_cmap_tahoe.py
```

### Batch Processing Multiple Diseases (Recommended)

The batch execution system supports processing all 233 CREEDS diseases or any custom subset:

**Using Configuration File (Recommended):**
```bash
cd scripts/execution
Rscript run_batch_from_config.R --config_file batch_configs/creeds_manual_config.yml
```

**Using Direct Parameters:**
```bash
Rscript run_drpipe_batch.R \
  --config_path "../config.yml" \
  --profile "Tahoe_Chronic_granulomatous_disease_0.00" \
  --disease_dir "../../data/disease_signatures/creeds" \
  --skip_existing TRUE
```

See `scripts/execution/README_BATCH_CONFIG.md` for detailed batch configuration options.

## Advanced Usage

### Creating Valid Instances for Drug Signatures

Valid instances are drug signatures that meet quality criteria based on replicate consistency. Creating them is essential for robust analysis:

#### For CMAP:
```bash
cd scripts/preprocessing
python generate_valid_instances.py \
  --dataset cmap \
  --filter_mode percentile \
  --threshold 15
```

#### For TAHOE:
```bash
python generate_valid_instances.py \
  --dataset tahoe \
  --filter_mode percentile \
  --threshold 4.5
```

**Filter Modes:**
- `percentile` - Keep top N% of instances by replicate correlation
- `pvalue` - Filter by statistical significance (p-value based)
- `rvalue` - Filter by minimum correlation coefficient

**Common Threshold Values:**
- CMAP: r = 0.15 (default) - minimum correlation threshold for valid instances
- TAHOE: r = 0.35 (default) - stricter threshold appropriate for TAHOE data

Output files contain:
- List of valid instance IDs
- Quality metrics and statistics
- Report summarizing validation results

### Filtering Disease Signatures

Adjust thresholds for disease signature filtering in `config.yml`:

```yaml
params:
  # Absolute log2 fold-change threshold for gene selection
  # Typical values: 0.0 (all genes), 0.5 (standard), 1.0 (strict), 1.5 (very strict)
  logfc_cutoff: 0.5
  
  # P-value threshold for gene selection (set to null to skip)
  # Typical values: 0.05 (standard), 0.01 (strict), 0.1 (lenient), null (disabled)
  pval_key: null
  pval_cutoff: 0.05
  
  # Keep only drug reversals (negative connectivity)
  reversal_only: true
```

**Adjusting Strictness:**
- **More lenient** (discover more drugs): 
  - `logfc_cutoff: 0.0` (include all genes)
  - `pval_cutoff: 0.1` (higher p-value threshold)
  
- **More strict** (discover fewer, higher-confidence drugs):
  - `logfc_cutoff: 1.0` (only highly significant genes)
  - `pval_cutoff: 0.01` (strict p-value threshold)

### Filtering Drug Signatures

Adjust thresholds when pre-processing CMAP or TAHOE data:

#### CMAP Filtering:
```bash
cd scripts/preprocessing
python filter_cmap_data.py \
  --percentile_cutoff 25 \
  --output_rdata "data/cmap_signatures_filtered.RData"
```

#### TAHOE Multi-Stage Filtering:

**Stage 1 - Gene Filtering:**
```bash
python filter_tahoe_part_1_gene_filtering.py \
  --min_gene_count 100 \
  --max_gene_count 5000
```

**Stage 2 - Ranking:**
```bash
python filter_tahoe_part_2_ranking.py \
  --top_n_genes 500
```

**Stage 3 - Export:**
```bash
Rscript filter_tahoe_part_3a_rdata_all.R    # Export all drugs
Rscript filter_tahoe_part_3b_rdata_shared_drugs.R  # Export shared drugs
```

**Key Parameters:**
- `percentile_cutoff`: Keep top N% of drugs by quality metrics
- `min_gene_count`, `max_gene_count`: Filter signatures by number of genes
- `top_n_genes`: Limit to top N genes per signature by absolute expression change

### Running Batch Analysis with Custom Thresholds

Create a custom batch configuration in `scripts/execution/batch_configs/custom_config.yml`:

```yaml
# Custom batch configuration
execution:
  disease_source: "creeds_manual"
  disease_dir: "../../data/disease_signatures/creeds"
  output_base: "../../results/custom_analysis"
  
analysis:
  profile: "Tahoe_Custom_0.75"  # References profile in config.yml
  logfc_cutoff: 0.75             # Custom fold-change threshold
  pval_cutoff: 0.01              # Custom p-value threshold
  q_thresh: 0.05                 # Custom FDR threshold
  
processing:
  skip_existing: true
  parallel_jobs: 4
```

Then execute:
```bash
Rscript run_batch_from_config.R --config_file batch_configs/custom_config.yml
```

## Methodology

The analysis pipeline processes all 233 CREEDS diseases through the following workflow:

1. **Disease Signature Processing** - Standardize and filter disease gene expression data
2. **Drug Signature Preparation** - Filter CMAP and TAHOE signatures by quality metrics
3. **Valid Instance Generation** - Identify high-quality drug signatures via replicate consistency
4. **Drug-Disease Scoring** - Calculate association scores for each drug-disease pair
5. **Method Comparison** - Compare predictions from CMAP and TAHOE methods
6. **Statistical Validation** - Assess significance using random background models
7. **Result Compilation** - Aggregate and annotate findings across all 233 diseases

### Analysis Modes

**Full Dataset**: Uses complete drug libraries
- CMAP: 1,309 drugs after quality filtering
- TAHOE: 379 drugs after quality filtering
- Maximizes discovery potential
- Identifies method-specific strengths

**Shared Drug Subset**: Uses 61 drugs present in both databases
- Enables direct method-to-method comparison
- Higher confidence in consensus predictions
- Demonstrates method reliability on common drugs

## Integration with DRpipe

This TAHOE-CMAP analysis demonstrates key capabilities that are integrated into the main [DRpipe package](../DRpipe/):

### Core DRpipe Features Demonstrated Here

1. **Disease Signature Processing**: Standardizing diverse disease expression data formats
2. **Drug Signature Quality Control**: Creating and applying valid instances for drug signatures
3. **Batch Processing at Scale**: Processing 233 diseases efficiently with configurable thresholds
4. **Flexible Threshold Configuration**: Tuning parameters to balance discovery vs. precision
5. **CMAP and TAHOE Integration**: Supporting multiple drug signature databases

### Using DRpipe vs. This Analysis

**For exploratory TAHOE-CMAP comparison**: Use this directory
- Specialized scripts for method comparison
- Pre-configured batch processing for CREEDS diseases
- Analysis outputs comparing both databases

**For production drug repurposing analysis**: Use [DRpipe package](../DRpipe/)
- Integrated pipeline for single or comparative analysis
- [Shiny app interface](../shiny_app/) for interactive analysis
- `runall.R` script for batch processing any disease set
- Standardized quality control and result reporting

**Running batch analyses with DRpipe:**
```bash
cd ../scripts
# Edit config.yml to configure your analysis
Rscript runall.R
```

See the main [README.md](../README.md) and [batch configuration guide](../tahoe_cmap_analysis/scripts/execution/README_BATCH_CONFIG.md) for details.

## Dependencies

- Python ≥ 3.8
- pandas ≥ 2.0.0
- numpy ≥ 1.24.0
- pyreadr (for R data file support)
- pyarrow (for Parquet file support)
- tqdm (for progress bars)
- joblib (for parallel processing)

See `requirements.txt` for complete dependency list.

## Related Documentation

- **Main Project README**: [../README.md](../README.md)
- **DRpipe Package**: [../DRpipe/README.md](../DRpipe/README.md)
- **Shiny App**: [../shiny_app/README.md](../shiny_app/README.md)

