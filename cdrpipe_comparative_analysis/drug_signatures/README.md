# Drug Signatures Workflow

Preparation of CMap and TAHOE drug expression signatures for CDRPipe analysis.

## Data Sources

| Platform | Source | Reference |
|----------|--------|-----------|
| **CMap** (Connectivity Map) | [Broad Institute CMap](https://www.broadinstitute.org/connectivity-map-cmap) | Subramanian et al., Cell 2017 |
| **TAHOE** (Transcriptomic Atlas of Human Oncology Expression) | [Hugging Face: Tahoe-100M](https://huggingface.co/datasets/tahoebio/Tahoe-100M) | [Preprint (bioRxiv 2025)](https://www.biorxiv.org/content/10.1101/2025.02.20.639398v1) |

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DRUG SIGNATURES PIPELINE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TAHOE Raw Data                           CMap Data                         │
│  (H5 file, ~100M experiments)             (Pre-processed RData)             │
│           │                                       │                         │
│           ▼                                       │                         │
│  ┌─────────────────────┐                          │                         │
│  │ OG TAHOE Extraction │                          │                         │
│  │ • L2FC from H5      │                          │                         │
│  │ • All genes (~18K)  │                          │                         │
│  │ • All experiments   │                          │                         │
│  └─────────────────────┘                          │                         │
│           │                                       │                         │
│           ▼                                       ▼                         │
│  ┌─────────────────────────────────────────────────────────────────┐        │
│  │              FILTERED TAHOE (Gene Harmonization)                │        │
│  │  • Filter to ~12K genes shared with CMap                        │        │
│  │  • Enables fair cross-platform comparison                       │        │
│  └─────────────────────────────────────────────────────────────────┘        │
│           │                                       │                         │
│           ▼                                       ▼                         │
│  ┌─────────────────────────────────────────────────────────────────┐        │
│  │                    RANK TRANSFORMATION                          │        │
│  │  • Convert L2FC → gene ranks (1 = most downregulated)           │        │
│  │  • CMap-compatible format for connectivity scoring              │        │
│  └─────────────────────────────────────────────────────────────────┘        │
│           │                                       │                         │
│           ▼                                       ▼                         │
│  ┌─────────────────────────────────────────────────────────────────┐        │
│  │                 VALID INSTANCE FILTERING                        │        │
│  │  • Leave-One-Out correlation analysis                           │        │
│  │  • Filter low-quality/inconsistent replicates                   │        │
│  │  • OG_035 = r > 0.35 threshold for TAHOE                        │        │
│  │  • OG_015 = r > 0.15 threshold for CMap                         │        │
│  └─────────────────────────────────────────────────────────────────┘        │
│           │                                       │                         │
│           ▼                                       ▼                         │
│  ┌───────────────────────┐           ┌───────────────────────┐              │
│  │ tahoe_signatures.RData│           │ cmap_signatures.RData │              │
│  │ tahoe_valid_instances │           │ cmap_valid_instances  │              │
│  └───────────────────────┘           └───────────────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## OG vs Filtered TAHOE: Key Differences

| Aspect | OG TAHOE | Filtered TAHOE |
|--------|----------|----------------|
| **Gene count** | ~18,000 (all TAHOE genes) | ~12,000 (shared with CMap) |
| **Purpose** | Full TAHOE analysis | Cross-platform comparison |
| **Use case** | TAHOE-only studies | CMap vs TAHOE benchmarking |

**Why filter?** CMap and TAHOE measure different gene sets. For fair comparison, we filter to the intersection (~12K genes measured by both platforms). The OG (original) extraction preserves all TAHOE genes for platform-specific analyses.

## Final Data Products

### Signature Matrices (RData)

| File | Rows | Columns | Description |
|------|------|---------|-------------|
| `cmap_signatures.RData` | ~12,000 genes | ~6,100 experiments | CMap ranked gene signatures |
| `tahoe_signatures.RData` | ~12,000 genes | ~100M experiments | TAHOE ranked gene signatures (filtered) |

Matrix format: Rows = genes (Entrez IDs), Columns = experiment IDs, Values = gene ranks (1 = most down, N = most up)

### Valid Instance Tables (CSV)

| File | Description |
|------|-------------|
| `cmap_valid_instances_OG_015.csv` | CMap experiments with LOO correlation r > 0.15 |
| `tahoe_valid_instances_OG_035.csv` | TAHOE experiments with LOO correlation r > 0.35 |

These tables identify high-quality drug signatures based on replicate consistency. The Leave-One-Out (LOO) correlation measures how well each replicate correlates with the average of other replicates for the same drug.

### Drug Metadata (CSV)

| File | Description |
|------|-------------|
| `cmap_drug_experiments_new.csv` | CMap experiment annotations (drug name, dose, cell line, time) |
| `tahoe_drug_experiments_new.csv` | TAHOE experiment annotations (drug name, dose, cell line, time) |

## Directory Structure

```
drug_signatures/
├── data/
│   ├── cmap/                      # CMap platform
│   │   ├── cmap_signatures.RData  # Ranked signature matrix (~1.5 GB)
│   │   ├── cmap_drug_experiments_new.csv
│   │   └── cmap_valid_instances_OG_015.csv
│   └── tahoe/                     # TAHOE platform
│       ├── tahoe_signatures.RData # Ranked signature matrix (~2 GB)
│       ├── tahoe_drug_experiments_new.csv
│       ├── tahoe_valid_instances_OG_035.csv
│       ├── experiments.parquet    # Full experiment metadata
│       └── genes.parquet          # Gene annotation
├── scripts/
│   ├── extraction/                # TAHOE H5 → signature matrix
│   ├── processing/                # Gene filtering, ranking, QC
│   └── visualization/             # Platform comparison figures
└── figures/
    └── platform_comparison/       # CMap vs TAHOE visualizations
```

## Scripts

### Extraction (TAHOE only - CMap comes pre-processed)

| Script | Description |
|--------|-------------|
| `extract_OG_tahoe_part_1.py` | Extract L2FC matrix from H5 file (HPC optimized) |
| `extract_OG_tahoe_part_2_rank_and_save_parquet.py` | Convert to rank-based signatures |
| `extract_OG_tahoe_part_3_convert_to_rdata.R` | Convert parquet → RData for CDRPipe |

### Processing

| Script | Description |
|--------|-------------|
| `filter_tahoe_part_1_gene_filtering.py` | Filter to CMap-shared gene universe |
| `filter_tahoe_part_2_ranking.py` | Apply gene ranking (L2FC → ranks) |
| `filter_tahoe_part_3a_rdata_all.R` | Generate final filtered RData |
| `generate_valid_instances.py` | LOO correlation analysis for QC |

### Visualization

| Script | Description |
|--------|-------------|
| `generate_platform_comparison.R` | CMap vs TAHOE comparison figures |
| `create_venn_platform_coverage.R` | Drug/gene overlap Venn diagrams |

## Reproduction

### Prerequisites

- Raw TAHOE H5 file from [Hugging Face](https://huggingface.co/datasets/tahoebio/Tahoe-100M)
- CMap data from [Broad Institute](https://www.broadinstitute.org/connectivity-map-cmap)
- Python 3.8+ with: `pandas numpy pyarrow h5py tables tqdm joblib`
- R 4.0+ with: `data.table`

### Full Pipeline

```bash
# From cdrpipe_comparative_analysis/

# ─── Step 1: Extract OG TAHOE from H5 ───
python drug_signatures/scripts/extraction/extract_OG_tahoe_part_1.py
python drug_signatures/scripts/extraction/extract_OG_tahoe_part_2_rank_and_save_parquet.py
Rscript drug_signatures/scripts/extraction/extract_OG_tahoe_part_3_convert_to_rdata.R

# ─── Step 2: Filter to shared genes ───
python drug_signatures/scripts/processing/filter_tahoe_part_1_gene_filtering.py
python drug_signatures/scripts/processing/filter_tahoe_part_2_ranking.py
Rscript drug_signatures/scripts/processing/filter_tahoe_part_3a_rdata_all.R

# ─── Step 3: Generate valid instances ───
python drug_signatures/scripts/processing/generate_valid_instances.py

# ─── Step 4: Generate figures ───
Rscript drug_signatures/scripts/visualization/generate_platform_comparison.R
```

## Data Availability

The large signature files (`*.RData`) are gitignored due to size. To reproduce:

1. **CMap**: Download from [clue.io](https://clue.io/) or [Broad FTP](https://www.broadinstitute.org/connectivity-map-cmap)
2. **TAHOE**: Download H5 from [Hugging Face Tahoe-100M](https://huggingface.co/datasets/tahoebio/Tahoe-100M) and run extraction pipeline
