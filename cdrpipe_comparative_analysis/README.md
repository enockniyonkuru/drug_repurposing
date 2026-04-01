# CDRPipe Comparative Analysis

Comparative analyses and manuscript figures for the CDRPipe drug repurposing platform evaluation.

---

## Conceptual Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CDRPipe Comparative Analysis                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │ DRUG SIGNATURES │  │  DRUG EVIDENCE  │  │  DISEASE PROCESSING │  │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────────┤  │
│  │ • Extraction    │  │ • Extraction    │  │ • CREEDS (233)      │  │
│  │ • Processing    │  │ • Processing    │  │ • Autoimmune (20)   │  │
│  │ • Visuals       │  │ • Visuals       │  │ • Endometriosis(19) │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 1. Drug Signatures Workflow

Preparation of CMap and TAHOE drug expression signatures for CDRPipe analysis.

```
Extraction → Processing → Visuals
```

| Stage | Scripts | Outputs |
|-------|---------|---------|
| **Extraction** | `drug_signatures/scripts/extraction/extract_OG_tahoe_part_*.py/.R` | Raw TAHOE matrices from H5 |
| **Processing** | `drug_signatures/scripts/processing/filter_tahoe_*.py/.R` | `tahoe_signatures.RData`, valid instances |
| **Visuals** | `drug_signatures/scripts/visualization/generate_platform_comparison.R` | Platform coverage figures |

**Learn more**: [drug_signatures/README.md](drug_signatures/README.md)
---

## 2. Drug Evidence Workflow

Processing of known drug-disease associations from Open Targets for validation.

```
Extraction → Processing → Visuals
```

| Stage | Scripts | Outputs |
|-------|---------|---------|
| **Extraction** | Manual download from Open Targets | `.parquet` evidence files |
| **Processing** | `drug_evidence/scripts/processing/processing_known_drugs_data.py` | Curated drug-disease tables |
| **Visuals** | Used in case study validation figures | Recovery metrics |
| **Data Location**: |`drug_evidence/data/open_targets/`|
| **Learn more**: | [drug_evidence/README.md](drug_evidence/README.md)|
---

## 3. Disease Processing Workflows

Three case studies demonstrating CDRPipe on disease gene signatures.

### 3.1 CREEDS Case Study (233 Diseases)

Large-scale benchmarking across 233 human disease signatures from the CREEDS database.

```
Extraction → Processing → Results → Analysis → Figures
```

| Stage | Scripts | Outputs |
|-------|---------|---------|
| **Extraction** | `creeds/scripts/processing/process_creeds_signatures.py` | One CSV per disease |
| **Processing** | `creeds/scripts/processing/standardize_creeds_signatures.py` | Standardized signatures |
| **Results** | `shared/scripts/execute/run_batch_from_config.R` | CDRPipe hit tables |
| **Analysis** | `creeds/scripts/analysis/*.py` | Concordance, summaries |
| **Figures** | `creeds/scripts/visualization/*.py/.R` | Manuscript figures |

**Learn more**: [creeds/README.md](creeds/README.md)

### 3.2 Autoimmune Case Study (20 Diseases)

Validation of known drug recovery for 20 autoimmune conditions (derived from CREEDS results).

```
Extraction (from CREEDS) → Analysis → Figures
```

| Stage | Scripts | Outputs |
|-------|---------|---------|
| **Extraction** | Subset from CREEDS results | `autoimmune/data/figure_inputs/` |
| **Analysis** | `autoimmune/scripts/analysis/*.py` | Recovery validation tables |
| **Figures** | `autoimmune/scripts/visualization/*.py` | Case study figures |

**Learn more**: [autoimmune/README.md](autoimmune/README.md)

### 3.3 Endometriosis Case Study (19 Signatures)

Multi-source consensus from three independent endometriosis signature sources.

```
Extraction (Microarray + Single-Cell + CREEDS) → Processing → Results → Analysis → Figures
```

| Stage | Scripts | Outputs |
|-------|---------|--------|
| **Extraction** | `endometriosis/scripts/processing/*.py` | Raw signatures from 3 sources |
| **Processing** | Signature standardization | 19-signature canonical panel |
| **Results** | `shared/scripts/execute/run_batch_from_config.R` | CDRPipe hit tables |
| **Analysis** | `endometriosis/scripts/analysis/*.py` | Cross-signature analysis |
| **Figures** | `endometriosis/scripts/visualization/*.R` | Heatmaps, overlap plots |

**Signature Sources**: Microarray (6) • Single-Cell RNA-seq (10) • CREEDS (3)

**Learn more**: [endometriosis/README.md](endometriosis/README.md)

---

## Repository Structure

```
cdrpipe_comparative_analysis/
│
├── shared/                            # Shared data & batch runner
│   ├── gene_id_conversion_table.tsv   # Gene symbol → Entrez ID mapping
│   ├── shared_drugs_cmap_tahoe.csv    # Drugs present in both platforms
│   ├── figure_provenance_manifest.csv # Figure input tracking
│   └── scripts/execute/               # Batch run orchestration
│
├── drug_signatures/                   # CMap & TAHOE platforms
│   ├── data/
│   │   ├── cmap/                      # CMap signatures + metadata
│   │   └── tahoe/                     # TAHOE signatures + metadata
│   ├── scripts/                       # Extraction, processing, visualization
│   └── figures/                       # Platform comparison figures
│
├── drug_evidence/                     # Known drug-disease associations
│   ├── data/open_targets/             # Open Targets evidence tables
│   └── scripts/                       # Evidence processing
│
├── creeds/                            # CREEDS 233-disease case study
│   ├── data/
│   │   ├── raw_creeds_exports/
│   │   ├── manual_signatures_extracted/
│   │   └── manual_signatures_standardized/
│   ├── scripts/
│   │   ├── processing/
│   │   ├── execute/
│   │   ├── analysis/
│   │   └── visualization/
│   ├── results/
│   ├── analysis/
│   └── figures/
│
├── autoimmune/                        # Autoimmune 20-disease case study
│   ├── data/
│   ├── scripts/
│   │   ├── execute/
│   │   ├── analysis/
│   │   └── visualization/
│   ├── results/
│   ├── analysis/
│   └── figures/
│
├── endometriosis/                     # Endometriosis 19-signature case study
│   ├── data/
│   │   ├── microarray_raw/            # 6 raw microarray signatures
│   │   ├── microarray_processed/      # 6 processed microarray signatures
│   │   ├── microarray_strict_filtered/# 6 strict-filtered (|logFC|>1.1)
│   │   ├── single_cell_signatures_raw/
│   │   ├── standardized_creeds/       # 3 CREEDS QC-filtered
│   │   ├── standardized_microarray/   # 6 microarray QC-filtered
│   │   └── standardized_single_cell/  # 10 single-cell QC-filtered
│   ├── scripts/
│   │   ├── processing/
│   │   ├── execute/
│   │   ├── analysis/
│   │   └── visualization/
│   ├── results/
│   │   ├── single_cell/               # Experiment 1 (default CDRPipe)
│   │   ├── creeds/                    # Experiment 1 (not yet generated)
│   │   └── microarray/                # Experiment 2 (Oskotsky replication)
│   ├── analysis/
│   └── figures/
│
└── dump/                              # Archived legacy scripts
```

---

## Reproduction Guide

### Prerequisites

1. **CDRPipe R Package**
   ```r
   devtools::install("../CDRPipe")
   ```

2. **Python Environment** (3.8+)
   ```bash
   pip install pandas numpy pyarrow h5py matplotlib seaborn
   ```

3. **Large Data Files**: See [Data Availability](#data-availability)

### Quick Start: Run by Workflow

```bash
# ─── Drug Signatures ───
# Generate TAHOE signatures from H5 (if raw data available)
python drug_signatures/scripts/extraction/extract_OG_tahoe_part_1.py
python drug_signatures/scripts/extraction/extract_OG_tahoe_part_2_rank_and_save_parquet.py
Rscript drug_signatures/scripts/extraction/extract_OG_tahoe_part_3_convert_to_rdata.R

# ─── CREEDS Case Study ───
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file creeds/scripts/execute/creeds_manual_config_all_avg.yml

# ─── Autoimmune Case Study ───
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file autoimmune/scripts/execute/case_study_v2.yml

# ─── Endometriosis Case Study ───
# Experiment 1: Single-cell (default CDRPipe)
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/single_cell_batch_config.yml
# Experiment 2: Microarray replication (Oskotsky et al.)
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/microarray_strict_config.yml
```

---

## Data Availability

### Primary Data Sources

| Platform | Download | Reference |
|----------|----------|-----------|
| **CMap** | [Broad Institute Connectivity Map](https://www.broadinstitute.org/connectivity-map-cmap) | Subramanian et al., Cell 2017 |
| **TAHOE** | [Hugging Face: Tahoe-100M](https://huggingface.co/datasets/tahoebio/Tahoe-100M) | [Preprint (bioRxiv 2025)](https://www.biorxiv.org/content/10.1101/2025.02.20.639398v1) |
| **Open Targets** | [Open Targets Platform](https://platform.opentargets.org/downloads) | Ochoa et al., NAR 2023 |

### Large Files (Not in Repository)

| File | Location | Source |
|------|----------|--------|
| `cmap_signatures.RData` | `drug_signatures/data/cmap/` | CMap (pre-processed) |
| `tahoe_signatures.RData` | `drug_signatures/data/tahoe/` | Generated via extraction pipeline |

### Included Data

| Data | Location | Description |
|------|----------|-------------|
| CMap/TAHOE metadata | `drug_signatures/data/*/` | Drug experiment annotations |
| Open Targets evidence | `drug_evidence/data/open_targets/` | Known drug-disease associations |
| Gene mapping | `shared/gene_id_conversion_table.tsv` | Symbol → Entrez conversion |
| Disease signatures | `creeds/data/`, `endometriosis/data/` | Processed signatures |

---

## Figure Provenance

All manuscript figures are tracked in `figures/figure_provenance_manifest.csv`.

| Workflow | Generator | Location |
|----------|-----------|----------|
| Drug Signatures | `scripts/visualization/generate_platform_comparison.R` | `figures/platform_comparison/` |
| CREEDS | `creeds/scripts/visualization/*.py/.R` | `creeds/figures/` |
| Autoimmune | `autoimmune/scripts/visualization/*.py` | `autoimmune/figures/` |
| Endometriosis | `endometriosis/scripts/visualization/*.R` | `endometriosis/figures/` |

---

## Study-Specific Documentation

| Study | README | Config |
|-------|--------|--------|
| **CREEDS** | [creeds/README.md](creeds/README.md) | `creeds/scripts/execute/*.yml` |
| **Autoimmune** | [autoimmune/README.md](autoimmune/README.md) | `autoimmune/scripts/execute/*.yml` |
| **Endometriosis** | [endometriosis/README.md](endometriosis/README.md) | `endometriosis/scripts/execute/*.yml` |
| **Shared Scripts** | [scripts/README.md](scripts/README.md) | — |
