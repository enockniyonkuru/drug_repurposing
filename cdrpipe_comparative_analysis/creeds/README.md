# CREEDS Case Study

**Crowd Extracted Expression of Differential Signatures (CREEDS)** – A comprehensive multi-disease drug repurposing analysis across 233 human disease signatures.

## Data Source

**CREEDS** is a crowdsourced resource of gene expression signatures from the Ma'ayan Lab at Mount Sinai School of Medicine.

- **Website**: https://maayanlab.cloud/CREEDS/
- **Paper**: Wang Z et al. (2016) *Extraction and analysis of signatures from the Gene Expression Omnibus by the crowd.* Nature Communications 7:12846. [DOI: 10.1038/ncomms12846](https://doi.org/10.1038/ncomms12846)

### Signature Types

CREEDS provides two signature types:
- **Manual signatures (v1.0)**: Curated by experts with verified disease annotations
- **Automatic signatures (p1.0)**: Computationally extracted from GEO metadata

**We use manual signatures only** because:
1. Higher annotation quality with expert validation
2. More reliable disease-gene associations
3. Better reproducibility for drug discovery applications

### Raw Data Download

Download the manual disease signatures from CREEDS:
```bash
# Navigate to raw data directory
cd creeds/data/raw_creeds_exports/

# Download manual disease signatures (v1.0)
curl -O https://maayanlab.cloud/CREEDS/download/disease_signatures-v1.0.json
curl -O https://maayanlab.cloud/CREEDS/download/disease_signatures-v1.0.csv
```

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CREEDS Processing Pipeline                         │
└─────────────────────────────────────────────────────────────────────────────┘

  CREEDS JSON (v1.0)
  ~240 multi-disease entries
         │
         ▼ [process_creeds_signatures.py]
  ┌──────────────────┐
  │  233 Individual  │  Split multi-disease entries
  │  Disease CSVs    │  Aggregate gene logFC across experiments
  └──────────────────┘
         │
         ▼ [standardize_creeds_signatures.py]
  ┌──────────────────┐
  │  233 Standardized│  QC1: Mean/median consistency
  │  Signatures      │  Filter: |median_logFC| ≥ 0.02
  └──────────────────┘
         │
         ▼ [run_batch_from_config.R]
  ┌──────────────────┬──────────────────┐
  │   191 CMAP       │   181 TAHOE      │  CDRPipe connectivity scoring
  │   Result Folders │   Result Folders │  q-value filtering
  └──────────────────┴──────────────────┘
         │
         ▼ [extract_pipeline_results_analysis.py]
  ┌──────────────────────────────────────┐
  │  Cross-Disease Analysis Summaries    │
  │  - analysis_summary_*.csv            │
  │  - analysis_drug_lists_*.csv         │
  │  - analysis_details_*.json           │
  └──────────────────────────────────────┘
         │
         ▼ [visualization scripts]
  ┌──────────────────────────────────────┐
  │  Manuscript Figures                  │
  │  - Precision/recall distributions    │
  │  - Biological concordance heatmaps   │
  │  - Drug class distributions          │
  └──────────────────────────────────────┘
```

## Directory Structure

```
creeds/
├── data/
│   ├── raw_creeds_exports/           # Downloaded CREEDS files
│   │   ├── disease_signatures-v1.0.json
│   │   └── disease_signatures-v1.0.csv
│   ├── manual_signatures_extracted/  # 233 individual disease CSVs
│   ├── manual_signatures_standardized/ # QC-filtered signatures
│   ├── manual_signatures_shared_genes/ # Filtered to CMAP∩TAHOE genes
│   ├── disease_metadata.parquet      # Disease ID mapping
│   └── signature_gene_counts_across_stages.csv
├── scripts/
│   ├── processing/                   # Data processing scripts
│   ├── execute/                      # CDRPipe config files
│   ├── analysis/                     # Post-processing analysis
│   └── visualization/                # Figure generation
├── results/
│   ├── manual_standardized_all_diseases_results/
│   │   ├── {disease}_cmap_{date}/    # 191 CMAP result folders
│   │   └── {disease}_tahoe_{date}/   # 181 TAHOE result folders
│   ├── biological_concordance/       # CMAP vs TAHOE comparison data
│   ├── drug_class_distributions/     # Drug category analysis
│   └── recall_precision/             # Validation metrics
├── analysis/
│   ├── CREEDS_Manual_All_Diseases_Analysis.xlsx  # Curated workbook
│   └── manual_standardized_all_diseases_analysis/
│       ├── analysis_summary_*_q{threshold}.csv
│       ├── analysis_drug_lists_*_q{threshold}.csv
│       └── analysis_details_*_q{threshold}.json
└── figures/
    ├── analysis_across_diseases/     # Precision/recall plots
    ├── biological_concordance/       # CMAP vs TAHOE heatmaps
    ├── disease_signature_analysis/   # Signature QC plots
    └── drug_class_distributions/     # Drug category plots
```

## Data Processing Details

### Step 1: Extract Disease Signatures

**Script**: `process_creeds_signatures.py`

The CREEDS JSON contains multi-disease entries where a single experiment may be annotated with multiple diseases. This script:

1. **Loads** the JSON database with ~240 disease signature entries
2. **Splits** multi-disease entries (e.g., "disease_A|disease_B") into individual files
3. **Aggregates** gene expression across experiments for each disease:
   - Collects logFC values from all experiments
   - Calculates mean and median logFC per gene
   - Identifies the most comprehensive experiment (highest gene count)
4. **Exports** one CSV per disease with columns:
   - `gene_symbol`: Gene identifier
   - `logfc_{sig_id}`: Per-experiment logFC values
   - `mean_logfc`: Mean across experiments
   - `median_logfc`: Median across experiments
   - `common_experiment`: LogFC from most comprehensive experiment

### Step 2: Standardize Signatures

**Script**: `standardize_creeds_signatures.py`

Quality control filtering to ensure robust disease signatures:

1. **QC1 - Mean/Median Consistency**:
   - Keeps genes where `sign(mean_logfc) == sign(median_logfc)`
   - Ensures consistent direction across experiments

2. **Strong Effect Filter**:
   - Requires `|median_logfc| ≥ 0.02`
   - Removes weakly differential genes

3. **Output**:
   - Ranked genes split into UP and DOWN regulated
   - Adds `signature_type` column

**Example filtering progression** (from `signature_gene_counts_across_stages.csv`):
| Disease | Before | After QC | After Shared Gene | Retention |
|---------|--------|----------|------------------|-----------|
| Alzheimer's disease | 1,795 | 881 | 636 | 35.4% |
| Crohn's disease | 1,844 | 644 | 574 | 31.1% |
| Down syndrome | 2,975 | 1,373 | 1,020 | 34.3% |

### Step 3: CDRPipe Batch Analysis

**Config**: [`creeds/scripts/execute/creeds_manual_config_all_avg.yml`](scripts/execute/creeds_manual_config_all_avg.yml)

Runs CDRPipe connectivity scoring for each disease against both CMAP and TAHOE drug signature databases.

**CDRPipe Parameters Used:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `logfc_cutoff` | `0.0` | No minimum fold-change threshold (QC done in preprocessing) |
| `qval_threshold` | `0.05` | Q-value significance cutoff for final analysis |
| `permutations` | `100,000` | Permutation iterations for statistical testing |
| `use_averaging` | `true` | Average logFC across multiple experiments per disease |
| `logfc_column_selection` | `"all"` | Use all available logFC columns |
| `valid_instances` | `cmap_valid_instances_OG_015.csv` | CMAP curated experiment filter |

**Drug Signature Databases:**
- **CMAP**: ~6,100 drug experiments from Connectivity Map
- **TAHOE**: ~100M drug experiments from Tahoe-100M

**Scoring Method**: Kolmogorov-Smirnov connectivity scores with permutation-based p-values

### Step 4: Cross-Disease Analysis

**Script**: `extract_pipeline_results_analysis.py`

Aggregates results across all diseases:
- Counts drug hits per disease at each q-value threshold
- Compares CMAP vs TAHOE drug discoveries
- Cross-references hits with Open Targets known drugs
- Extracts clinical phase and trial status information

## Shared Inputs

This workflow requires shared data from the parent directory:

| Input | Location | Purpose |
|-------|----------|---------|
| CMAP signatures | `../drug_signatures/cmap/` | Drug perturbation profiles |
| TAHOE signatures | `../drug_signatures/tahoe/` | Drug perturbation profiles |
| Open Targets | `../drug_evidence/open_targets/` | Validation against known drugs |
| Gene ID table | `../data/gene_id_conversion_table.tsv` | Symbol standardization |

## Step-by-Step Reproduction

Run all commands from `cdrpipe_comparative_analysis/`:

### Prerequisites

1. **Download CREEDS raw data** (if not present):
```bash
cd creeds/data/raw_creeds_exports/
curl -O https://maayanlab.cloud/CREEDS/download/disease_signatures-v1.0.json
curl -O https://maayanlab.cloud/CREEDS/download/disease_signatures-v1.0.csv
cd ../../..
```

2. **Verify shared inputs exist**:
```bash
ls drug_signatures/cmap/cmap_signatures.RData
ls drug_signatures/tahoe/tahoe_signatures.RData
ls drug_evidence/open_targets/known_drug_info_data.parquet
```

3. **Install CDRPipe** (if not already installed):
```bash
Rscript -e "devtools::install('../CDRPipe')"
```

### Step 1: Extract Disease Signatures

```bash
python creeds/scripts/processing/process_creeds_signatures.py
```

**Output**: `creeds/data/manual_signatures_extracted/` (233 CSV files)

**Expected output**:
```
Processing MANUAL signatures (v1.0)
✓ Total unique diseases found: 233
✓ Diseases processed: 233
✓ Multi-disease entries split: 12
```

### Step 2: Standardize Signatures

```bash
python creeds/scripts/processing/standardize_creeds_signatures.py \
  --input_dir creeds/data/manual_signatures_extracted \
  --output_dir creeds/data/manual_signatures_standardized
```

**Output**: `creeds/data/manual_signatures_standardized/` (233 CSV files)

### Step 3: Run CDRPipe Batch Analysis

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file creeds/scripts/execute/creeds_manual_config_all_avg.yml
```

**Output**: `creeds/results/manual_standardized_all_diseases_results/`
- 191 CMAP result folders (`{disease}_cmap_{timestamp}/`)
- 181 TAHOE result folders (`{disease}_tahoe_{timestamp}/`)

> **Note**: This step is computationally intensive. TAHOE analysis may take several hours per disease. Use `runtime.skip_existing_results: true` in the config to resume interrupted runs.

### Step 4: Generate Cross-Disease Analysis

```bash
python creeds/scripts/analysis/extract_pipeline_results_analysis.py \
  --input_dir creeds/results/manual_standardized_all_diseases_results \
  --output_dir creeds/analysis/manual_standardized_all_diseases_analysis
```

**Output**: Analysis summaries at q-value thresholds 0.5, 0.1, 0.05

### Step 5: Generate Figures

```bash
# Signature QC analysis
Rscript creeds/scripts/visualization/plot_disease_signature_filtering.R

# Precision/recall across diseases
Rscript creeds/scripts/visualization/plot_analysis_across_diseases.R

# Biological concordance heatmaps
python creeds/scripts/visualization/plot_biological_concordance.py

# Drug class distribution analysis
python creeds/scripts/visualization/plot_drug_class_distributions.py
```

**Output**: `creeds/figures/` subdirectories

## Key Outputs

### Analysis Results (`analysis/`)

| File | Description |
|------|-------------|
| `CREEDS_Manual_All_Diseases_Analysis.xlsx` | Curated workbook for manuscript figures |
| `analysis_summary_*_q{threshold}.csv` | Per-disease hit counts and validation metrics |
| `analysis_drug_lists_*_q{threshold}.csv` | Full drug name lists per disease |
| `analysis_details_*_q{threshold}.json` | Complete analysis with drug phases/status |

### Figures (`figures/`)

| Subdirectory | Contents |
|--------------|----------|
| `analysis_across_diseases/` | Precision/recall density plots, scatter plots |
| `biological_concordance/` | CMAP vs TAHOE heatmaps, butterfly plots |
| `disease_signature_analysis/` | Signature QC progression visualizations |
| `drug_class_distributions/` | Drug category bar charts, lollipop plots |

### Validation Results (`results/`)

| Subdirectory | Contents |
|--------------|----------|
| `biological_concordance/` | CMAP vs TAHOE drug overlap statistics |
| `drug_class_distributions/` | Drug category analysis data |
| `recall_precision/` | Validation performance metrics |

## Statistics Summary

| Metric | Count |
|--------|-------|
| Total diseases extracted | 233 |
| Diseases with CMAP results | 191 |
| Diseases with TAHOE results | 181 |
| Q-value thresholds tested | 0.5, 0.1, 0.05 |

## Preservation Notes

Two artifacts are preserved rather than fully regenerated:

1. **`CREEDS_Manual_All_Diseases_Analysis.xlsx`**: Curated workbook that serves as direct input for manuscript figures. The script-generated layer is in `manual_standardized_all_diseases_analysis/`.

2. **`manual_signatures_shared_genes/`**: Reference dataset filtered to CMAP∩TAHOE gene overlap. Can be regenerated with `compare_tahoe_cmap.py`.

## Related Documentation

- [creeds/data/README.md](data/README.md) - Data folder details
- [../drug_signatures/README.md](../drug_signatures/README.md) - Drug signature processing
- [../drug_evidence/README.md](../drug_evidence/README.md) - Open Targets validation data
- [../../CDRPipe/README.md](../../CDRPipe/README.md) - CDRPipe R package documentation
