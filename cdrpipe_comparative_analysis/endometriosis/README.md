# Endometriosis Case Study

Drug repurposing analysis for endometriosis using CDRPipe, based on three
independent sources of disease gene expression signatures. The case study
comprises two experiments: a default CDRPipe analysis across all signature
sources, and a replication of the published Oskotsky et al. analysis using
matched parameters.

## Disease Signature Sources

Three data sources provide 19 disease signatures in total. Each source
captures a different biological layer (microarray, bulk RNA-seq, single-cell
RNA-seq) and a different stratification of disease subtypes.

### 1. Microarray Signatures (6 signatures)

Differential expression from endometriosis tissue biopsies, stratified by
**menstrual cycle phase** and **disease stage**.

> Oskotsky TT, Bhoja A, Bunis D, Le BL, Tang AS, Kosti I, et al.
> "Identifying therapeutic candidates for endometriosis through a
> transcriptomics-based drug repositioning approach."
> *iScience*. 2024;27(4):109388.
> [doi:10.1016/j.isci.2024.109388](https://doi.org/10.1016/j.isci.2024.109388)
> | [PubMed](https://pubmed.ncbi.nlm.nih.gov/38510116/)
> | [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC10952035/)

| Signature | Phase | Stage | Genes |
|-----------|-------|-------|------:|
| `endo_ESE_I_II` | Early Secretory (ESE) | I–II | 535 |
| `endo_ESE_III_IV` | Early Secretory (ESE) | III–IV | 1,049 |
| `endo_MSE_I_II` | Mid-Secretory (MSE) | I–II | 2,569 |
| `endo_MSE_III_IV` | Mid-Secretory (MSE) | III–IV | 1,775 |
| `endo_PE_I_II` | Proliferative (PE) | I–II | 1,652 |
| `endo_unstratified` | All phases | All stages | 1,565 |

These signatures have large effect sizes (median |logFC| > 1.14), making them
the most complete source for CDRPipe analysis.

### 2. CREEDS Bulk Signatures (3 signatures)

Curated from the CREEDS database (Crowd Extracted Expression of Differential
Signatures):

| Signature | Genes |
|-----------|------:|
| `endometriosis` | 558 |
| `endometriosis_of_ovary` | 511 |
| `endometrial_cancer` | 477 |

Total unique genes: 1,546. All genes passed QC (100% retention).

### 3. Single-Cell RNA-seq Signatures (10 signatures)

Derived from single-cell RNA-seq data spanning 5 cell types × 2 menstrual
phases.

> Almonte-Loya A, Wang W, Houshdaran S, Tang X, Flynn E, Liu B, et al.
> "Single-Cell Profiling Reveals Altered Endometrial Cellular Features
> Across the Menstrual Cycle in Endometriosis Patients."
> *bioRxiv*. 2025. (Preprint v2, 2025-08-14)
> [doi:10.1101/2025.07.21.666016](https://doi.org/10.1101/2025.07.21.666016)

| Cell Type | Phases | Genes (post-QC) |
|-----------|--------|----------------:|
| Ciliated epithelial | ESE, MSE | ~13,000 |
| Stromal fibroblast | ESE, MSE | ~13,000 |
| Glandular secretory | ESE, MSE | ~13,000 |
| Smooth muscle cell | ESE, MSE | ~13,000 |
| Unciliated epithelial | ESE, MSE | ~13,000 |

QC filtering retained 13,342 genes (23% of 58,252 raw). Three QC filters were
applied: (QC1) mean and median logFC must have the same sign, (QC2) |median| ≥
0.02, (QC3) adjusted p < 0.05.

## Experiments

### Experiment 1 — Default CDRPipe Analysis

Runs all 19 signatures through CDRPipe with default parameters (100,000
permutations). Three configs cover different signature groupings:

| Config | Signatures | Key Parameters |
|--------|-----------|----------------|
| `all_19_signatures_config.yml` | All 19 combined | q < 0.05, 75th percentile filter |
| `microarray_config.yml` | 6 microarray | q < 0.0001, reversal < 0 |
| `single_cell_batch_config.yml` | 10 single-cell | q < 0.5, logfc = 0.0, mean_logfc |

All three use the CDRPipe default of **100,000 permutations** and score drugs
against both CMAP and TAHOE databases.

**Current results**: Only single-cell results exist (`results/single_cell/`,
20 folders: 10 cell types × 2 databases). Microarray and CREEDS default
results can be generated on demand.

### Experiment 2 — Replication of Oskotsky et al.

Runs only the 6 microarray signatures with non-default parameters that match
the methodology of Oskotsky et al. (2024), to validate CDRPipe against their
published drug rankings.

| Config | Value |
|--------|-------|
| `microarray_strict_config.yml` | |
| |logFC| cutoff | > 1.1 |
| q-value threshold | < 0.0001 |
| Permutations | **1,000** |
| Seed | 2009 |
| Databases | CMAP + TAHOE |

**Results**: `results/microarray/` contains heatmap source data and
replication validation tables.

- `cmap_hit_tables/` — 6 CMap hit CSVs (input to the heatmap)
- `tahoe_hit_tables/` — 6 Tahoe hit CSVs (must regenerate; currently empty)
- `replication_tables/` — Top-20 drug agreement between CDRPipe and the
  Oskotsky et al. published analysis

**Figures**: The CMap and Tahoe top-50 reversal-score heatmaps in `figures/`
are produced from this experiment.

## Data Directory Guide

The `data/` directory contains disease signatures at different processing
stages. Each folder serves a specific role in the pipeline.

### Raw signatures (input to standardization)

| Folder | Source | Description |
|--------|--------|-------------|
| `microarray_raw/` | Microarray | 6 raw differential expression files from GEO |
| `single_cell_signatures_raw/` | Single-cell | 13 raw DEG files from scRNA-seq analysis |

### Processed / standardized signatures (input to CDRPipe)

| Folder | Source | Experiment | Description |
|--------|--------|------------|-------------|
| `standardized_microarray/` | Microarray | 1 | 6 signatures, QC-filtered, CDRPipe-ready format (`gene_symbol`, `logFC`) |
| `standardized_creeds/` | CREEDS | 1 | 3 signatures, QC-filtered, CDRPipe-ready format |
| `standardized_single_cell/` | Single-cell | 1 | 10 signatures (5 cell types × 2 phases), QC-filtered |
| `microarray_processed/` | Microarray | 1 & 2 | 6 processed microarray signatures (used by `microarray_config.yml`) |
| `microarray_strict_filtered/` | Microarray | 2 | 6 signatures with strict |logFC| > 1.1 filter (used by `microarray_strict_config.yml`) |

Each `standardized_*/` folder has its own README with file descriptions and
QC statistics.

### How data flows through the pipeline

```
Raw signatures → standardize_endo_signatures.py → standardized_*/
                                                   (or microarray_processed/)
                                                        ↓
                                     CDRPipe (via config.yml) → results/
```

## Directory Structure

```
endometriosis/
├── data/
│   ├── microarray_raw/                     # 6 raw microarray signatures
│   ├── microarray_processed/               # 6 processed microarray signatures
│   ├── microarray_strict_filtered/         # 6 strict-filtered (|logFC| > 1.1)
│   ├── single_cell_signatures_raw/         # 13 raw single-cell CSV files
│   ├── single_cell_signatures_standardized/# 12 standardized single-cell sigs
│   ├── standardized_creeds/                # 3 CREEDS QC-filtered signatures
│   ├── standardized_microarray/            # 6 microarray QC-filtered signatures
│   └── standardized_single_cell/           # 10 single-cell QC-filtered signatures
├── scripts/
│   ├── processing/                         # Signature standardization scripts
│   │   ├── standardize_endo_signatures.py  # Generic QC filter (all sources)
│   │   └── process_single_cell_signatures.py
│   ├── execute/                            # CDRPipe batch YAML configs
│   │   ├── all_19_signatures_config.yml    # Experiment 1: all 19 combined
│   │   ├── microarray_config.yml           # Experiment 1: microarray only
│   │   ├── single_cell_batch_config.yml    # Experiment 1: single-cell only
│   │   └── microarray_strict_config.yml    # Experiment 2: replication
│   ├── analysis/                           # QC and threshold analysis scripts
│   └── visualization/                      # Figure generation scripts
│       └── generate_case_study_endometriosis.R
├── analysis/
│   └── all_19_signatures_analysis/         # Cross-signature analysis outputs
├── results/
│   ├── single_cell/                        # Experiment 1: 10 cell types × 2 DBs
│   ├── creeds/                             # Experiment 1: (not yet generated)
│   └── microarray/                         # Experiment 2: heatmap source data
│       ├── cmap_hit_tables/                # 6 CMap hit CSVs
│       ├── tahoe_hit_tables/               # 6 Tahoe hit CSVs (must regenerate)
│       └── replication_tables/             # Validation vs published analysis
├── figures/
│   ├── cmap_top50_reversal_scores_heatmap.png
│   └── tahoe_top50_reversal_scores_heatmap.png
└── dump/                                   # Threshold analysis, study design docs
```

## Reproduction Guide

Run all commands from the `cdrpipe_comparative_analysis/` directory.

### 1. Review or regenerate standardized signatures

The standardization script applies QC filters to raw signatures:

```bash
python endometriosis/scripts/processing/standardize_endo_signatures.py \
  --input_dir endometriosis/data/<raw_signatures_dir> \
  --output_dir endometriosis/data/<output_dir>
```

To regenerate single-cell standardized signatures from raw:

```bash
python endometriosis/scripts/processing/process_single_cell_signatures.py
```

The standardized signatures are already in `data/standardized_*/` and do not
need regeneration for a standard re-run.

### 2. Run CDRPipe batch analysis

Each config drives a complete CDRPipe run via the shared batch runner:

```bash
# --- Experiment 1: Default CDRPipe ---

# Microarray only
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/microarray_config.yml

# Single-cell only
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/single_cell_batch_config.yml

# --- Experiment 2: Replication study ---

Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/microarray_strict_config.yml
```

### 3. Regenerate figures (Experiment 2)

The CMap heatmap can be regenerated directly — the source data is in
`results/microarray/cmap_hit_tables/`:

```bash
Rscript endometriosis/scripts/visualization/generate_case_study_endometriosis.R
```

The Tahoe heatmap requires regenerating the TAHOE hit tables first. After
running CDRPipe in step 2 with `microarray_strict_config.yml`, copy the
per-signature TAHOE hit CSVs into `results/microarray/tahoe_hit_tables/`
using the naming convention `tahoe_hits_{ESE,IIInIV,InII,MSE,PE,unstratified}.csv`.
Each file needs `name` and `cmap_score` columns. Then re-run the script above.

See `results/microarray/README.md` for detailed instructions.

## Shared Dependencies

This case study uses the shared infrastructure in `../shared/`:

- **Drug signature databases**: `../data/drug_signatures/` (CMAP and TAHOE
  `.RData` files)
- **Batch runner**: `../shared/scripts/execute/run_batch_from_config.R`
- **Gene ID table**: `../data/gene_id_conversion_table.tsv`

See `../shared/scripts/execute/README_BATCH_CONFIG.md` for YAML config format
documentation.

## Related Documentation

- [Autoimmune case study](../autoimmune/README.md) — parallel analysis for 6
  autoimmune diseases
- [CREEDS case study](../creeds/README.md) — detailed CREEDS signature analysis
- [Drug signatures README](../data/drug_signatures/README.md) — CMAP/TAHOE
  database documentation
- [Drug evidence README](../data/drug_evidence/README.md) — clinical validation
  data


