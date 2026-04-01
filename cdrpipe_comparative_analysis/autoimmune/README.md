# Autoimmune Case Study

**Drug Repurposing Analysis for 20 Autoimmune Diseases** – A focused case study comparing CMAP and TAHOE platforms for known drug recovery.

## Overview

This case study evaluates the performance of CMAP and TAHOE drug repurposing platforms across 20 autoimmune diseases. The analysis measures each platform's ability to recover known therapeutic drugs validated in Open Targets.

**Key Finding**: TAHOE significantly outperforms CMAP in known drug recovery (mean 76.6% vs 17.8%, p < 0.001, Cohen's d = 2.35).

## Data Source

The autoimmune diseases analyzed here are a **subset of the 233 CREEDS diseases**. The CDRPipe results come from the main CREEDS batch run:

- **Source**: [creeds/results/manual_standardized_all_diseases_results](../creeds/results/manual_standardized_all_diseases_results/)
- **Parameters**: q-value < 0.05, 100,000 permutations
- **Validation**: Open Targets known drug associations

See [../creeds/README.md](../creeds/README.md) for full CREEDS workflow documentation.

## 20 Autoimmune Diseases Analyzed

| Disease | Known Drugs (DB) | CMAP Recovery | TAHOE Recovery |
|---------|------------------|---------------|----------------|
| Rheumatoid arthritis | 2,397 | 17.8% | 64.0% |
| Multiple sclerosis | 1,885 | 27.9% | 43.8% |
| Type 1 diabetes mellitus | 1,788 | 25.8% | 16.7% |
| Psoriasis | 1,473 | 4.2% | 93.3% |
| Crohn's disease | 1,283 | 7.4% | 75.0% |
| Ulcerative colitis | 1,192 | 12.5% | 50.0% |
| Systemic lupus erythematosus | 1,071 | 40.0% | 60.0% |
| Relapsing-remitting MS | 816 | 31.6% | 66.7% |
| Psoriasis vulgaris | 658 | 16.7% | 100.0% |
| Ankylosing spondylitis | 634 | 0.0% | 77.8% |
| Psoriatic arthritis | 630 | 0.0% | 100.0% |
| Autoimmune thrombocytopenic purpura | 605 | 12.5% | 100.0% |
| Inflammatory bowel disease | 538 | 9.1% | 85.7% |
| Arthritis | 435 | 33.3% | 0.0% |
| Sjogren's syndrome | 304 | 66.7% | 100.0% |
| Scleroderma | 224 | 50.0% | 100.0% |
| Colitis | 202 | 0.0% | 100.0% |
| Childhood type dermatomyositis | 160 | 0.0% | 100.0% |
| Discoid lupus erythematosus | 84 | 0.0% | 100.0% |
| Inclusion body myositis | 69 | 0.0% | 100.0% |

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Autoimmune Case Study Pipeline                           │
└─────────────────────────────────────────────────────────────────────────────┘

  CREEDS Results (233 diseases)
  ../creeds/results/manual_standardized_all_diseases_results/
         │
         ▼ [Filter to 20 autoimmune diseases]
  ┌──────────────────────────────────────┐
  │  20 Autoimmune Disease Results       │
  │  - {disease}_cmap_{date}/            │
  │  - {disease}_tahoe_{date}/           │
  └──────────────────────────────────────┘
         │
         ▼ [show_drug_details.py]
  ┌──────────────────────────────────────┐
  │  Recovery Analysis                   │
  │  - Per-disease recovered drug CSVs   │
  │  - disease_recovery_summary.csv      │
  └──────────────────────────────────────┘
         │
         ▼ [Manual curation]
  ┌──────────────────────────────────────┐
  │  20_autoimmune.xlsx                  │
  │  - Summary statistics                │
  │  - Complementarity analysis          │
  │  - Manuscript tables                 │
  └──────────────────────────────────────┘
         │
         ▼ [generate_case_study_autoimmune.py]
  ┌──────────────────────────────────────┐
  │  Manuscript Figures                  │
  │  - Recovery rate boxplot             │
  │  - Hits vs recovery scatter          │
  │  - Phase 4 recovery heatmap          │
  │  - Statistical comparison            │
  └──────────────────────────────────────┘
```

## Directory Structure

```
autoimmune/
├── data/
│   └── autoimmune_disease_signatures/   # 15 disease signatures (subset for re-runs)
├── scripts/
│   ├── execute/
│   │   └── autoimmune_batch_config.yml   # CDRPipe batch config for re-runs
│   ├── analysis/
│   │   └── show_drug_details.py          # Extract recovery details per disease
│   └── visualization/
│       ├── generate_case_study_autoimmune.py  # Main figure generator (4 figures)
│       ├── create_drug_consistency_figures.py  # Drug consistency visualizations
│       └── create_separate_panels.py          # Individual panel figures
├── analysis/
│   ├── recovery_summary/                 # Aggregated summary tables
│   │   ├── 20_autoimmune.xlsx            # Curated workbook
│   │   ├── MANUSCRIPT_INSIGHTS.md        # Key findings
│   │   ├── Table1_Disease_Summary.csv
│   │   ├── Table2_Summary_Statistics.csv
│   │   └── Table3_Complementarity.csv
│   └── per_disease_recovery/             # Per-disease recovered drug CSVs
│       ├── disease_recovery_summary.csv
│       └── {disease}_recovered_drugs.csv  (× 20 diseases)
└── figures/
    ├── recovery_rate_distribution_boxplot.png
    ├── drug_hits_vs_recovery_rate_scatter.png
    ├── cmap_vs_tahoe_recovery_statistical_test.png
    └── phase4_recovery_heatmap.png
```

## Key Results

### Statistical Comparison

| Metric | CMAP | TAHOE | Significance |
|--------|------|-------|--------------|
| Mean Recovery Rate | 17.8% | 76.6% | p < 0.001 |
| Median Recovery Rate | 12.5% | 89.5% | - |
| Cohen's d Effect Size | - | 2.35 | Large effect |
| Diseases where better | 2 | 18 | - |

### Complementarity Analysis

| Source | Drugs Recovered | Percentage |
|--------|-----------------|------------|
| CMAP Only | 54 | 31.8% |
| TAHOE Only | 110 | 64.7% |
| Both Methods | 6 | 3.5% |
| **Total Unique** | **170** | 100% |

## Shared Dependencies

| Input | Location | Purpose |
|-------|----------|---------|
| CREEDS results | `../creeds/results/` | CDRPipe batch outputs |
| Open Targets | `../drug_evidence/data/open_targets/` | Known drug validation |
| Drug signatures | `../drug_signatures/` | CMAP & TAHOE databases |

## Step-by-Step Reproduction

Run all commands from `cdrpipe_comparative_analysis/`:

### Prerequisites

1. **Complete the CREEDS workflow first** (see [../creeds/README.md](../creeds/README.md)):
```bash
# Ensure CREEDS results exist
ls creeds/results/manual_standardized_all_diseases_results/*multiple_sclerosis*
```

2. **Verify Open Targets data exists**:
```bash
ls drug_evidence/data/open_targets/known_drug_info_data.parquet
```

### Step 1: Extract Drug Recovery Details

```bash
python autoimmune/scripts/analysis/show_drug_details.py
```

**Output**: `autoimmune/analysis/per_disease_recovery/`
- 20 per-disease CSVs: `{disease}_recovered_drugs.csv`
- Summary: `disease_recovery_summary.csv`

### Step 2: Generate Figures

```bash
python autoimmune/scripts/visualization/generate_case_study_autoimmune.py
```

**Output**: `autoimmune/figures/`
- `recovery_rate_distribution_boxplot.png`
- `drug_hits_vs_recovery_rate_scatter.png`
- `cmap_vs_tahoe_recovery_statistical_test.png`
- `phase4_recovery_heatmap.png`

### Optional: Re-run CDRPipe (15 diseases)

If you need to regenerate CDRPipe results for the subset of 15 diseases with local signatures:

```bash
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file autoimmune/scripts/execute/autoimmune_batch_config.yml
```

The execution script (`shared/scripts/execute/run_batch_from_config.R`) reads the YAML config and launches the CDRPipe batch pipeline. See [`shared/scripts/execute/README_BATCH_CONFIG.md`](../shared/scripts/execute/README_BATCH_CONFIG.md) for details.

**Note**: The main analysis uses results from the full CREEDS run (20 diseases).

## CDRPipe Parameters

**Config**: [`autoimmune/scripts/execute/autoimmune_batch_config.yml`](scripts/execute/autoimmune_batch_config.yml)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `logfc_cutoff` | `0.0` | No additional fold-change filter |
| `qval_threshold` | `0.05` | Q-value significance cutoff |
| `permutations` | `100,000` | Permutation iterations |
| `use_averaging` | `true` | Average logFC across experiments |
| `valid_instances` | `cmap_valid_instances_OG_015.csv` | CMAP curated experiments |

## Key Outputs

### Analysis Tables (`analysis/recovery_summary/`)

| File | Description |
|------|-------------|
| `20_autoimmune.xlsx` | Curated workbook with all summary data |
| `Table1_Disease_Summary.csv` | Per-disease hit counts and recovery rates |
| `Table2_Summary_Statistics.csv` | Aggregate statistics |
| `Table3_Complementarity.csv` | CMAP vs TAHOE overlap analysis |
| `MANUSCRIPT_INSIGHTS.md` | Key findings and suggested text |

### Per-Disease Recovery (`analysis/per_disease_recovery/`)

Each `{disease}_recovered_drugs.csv` contains:
- Drug names recovered by CMAP, TAHOE, or both
- Clinical phase from Open Targets
- Trial status information

### Figures (`figures/`)

| Figure | Description |
|--------|-------------|
| `recovery_rate_distribution_boxplot.png` | CMAP vs TAHOE recovery comparison with Wilcoxon test |
| `drug_hits_vs_recovery_rate_scatter.png` | Relationship between total hits and recovery rate |
| `cmap_vs_tahoe_recovery_statistical_test.png` | Detailed statistical comparison |
| `phase4_recovery_heatmap.png` | Phase 4 drug recovery by disease |


## Related Documentation

- [creeds/README.md](../creeds/README.md) - Source CREEDS workflow (required dependency)
- [drug_evidence/README.md](../drug_evidence/README.md) - Open Targets validation data
- [drug_signatures/README.md](../drug_signatures/README.md) - CMAP & TAHOE drug databases
