# Manuscript Figures & Generating Scripts

All figures for the CDRPipe manuscript are stored in `figures/` and can be regenerated from the scripts in `scripts/`. There is **one script per figure folder**. Each script is self-contained, computing file paths relative to the repository root, so it can be run from any working directory.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Script → Output Mapping](#script--output-mapping)
5. [Color Convention](#color-convention)
6. [Reproducing All Figures](#reproducing-all-figures)

---

## Quick Start

```bash
# From the repository root — run any single script:
Rscript visuals/scripts/generate_analysis_across_diseases.R
python3  visuals/scripts/generate_drug_class_distributions.py
# … etc.
```

---

## Prerequisites

### R (≥ 4.4)

```r
install.packages(c("tidyverse", "ggplot2", "dplyr", "tidyr", "gplots",
                   "patchwork", "VennDiagram", "arrow", "readxl",
                   "cowplot", "gridExtra", "here"))
```

### Python (≥ 3.9)

```bash
pip install pandas matplotlib seaborn numpy scipy openpyxl
```

### Data Dependencies

Scripts read from upstream analysis outputs. Ensure these exist before regenerating:
- `tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx` — Main 90-disease analysis
- `tahoe_cmap_analysis/case_study_special/case_study_disease_category/about_drpipe_results/` — Biological concordance data
- `tahoe_cmap_analysis/validation/20_autoimmune_results_1/` — Autoimmune case study
- `scripts/results/endo_v4_cmap/`, `scripts/results/endo_v5_tahoe/` — Endometriosis results
- `tahoe_cmap_analysis/data/disease_signatures/creeds_manual_disease_signatures_standardised/` — Standardized CREEDS signatures
- `tahoe_cmap_analysis/data/drug_signatures/` — Drug signature RData + metadata

---

## Directory Structure

```
visuals/
├── figures/
│   ├── analysis_across_diseases/         # Precision/recall across diseases
│   ├── biological_concordance/           # Butterfly, lollipop, concordance
│   ├── case_study_autoimmune/            # Autoimmune validation & Phase 4 recovery
│   ├── case_study_endometriosis/         # CMap & Tahoe top-50 heatmaps
│   ├── disease_signature_analysis/       # 4-panel disease signature panels
│   ├── drug_class_distributions/         # Drug target classes & disease areas
│   └── platform_comparison/              # Gene universe, stability, strength, Venn
├── scripts/
│   ├── generate_analysis_across_diseases.R
│   ├── generate_biological_concordance.py
│   ├── generate_case_study_autoimmune.py
│   ├── generate_case_study_endometriosis.R
│   ├── generate_disease_signature_analysis.R
│   ├── generate_drug_class_distributions.py
│   └── generate_platform_comparison.R
└── README.md
```

---

## Script → Output Mapping

### Analysis Across Diseases

| Script | Output | Description |
|--------|--------|-------------|
| `generate_analysis_across_diseases.R` | `cmap_vs_tahoe_precision_recall_density.png` | Multi-panel precision/recall density + scatter |
| | `recall_distribution_density.png` | Panel A: Recall distribution density |
| | `precision_distribution_density.png` | Panel B: Precision distribution density |
| | `precision_vs_recall_scatter.png` | Panel C: Precision vs recall scatter |

**Data:** `tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx`

---

### Biological Concordance

| Script | Output | Description |
|--------|--------|-------------|
| `generate_biological_concordance.py` | `butterfly_drug_classes.png` | Butterfly plot of drug classes |
| | `drug_class_distribution_shift_lollipop.png` | Lollipop plot of score shifts |
| | `drug_class_concordance_heatmap.png` | Concordance heatmap |
| | `comparative_heatmap_recovered.png` | Side-by-side CMAP vs Tahoe heatmap (recovered) |
| | `comparative_heatmap_all_discoveries.png` | Side-by-side CMAP vs Tahoe heatmap (all discoveries) |
| | `difference_heatmap_recovered.png` | Tahoe − CMAP differential heatmap (recovered) |
| | `difference_heatmap_all_discoveries.png` | Tahoe − CMAP differential heatmap (all discoveries) |
| | `stacked_bar_drug_targets_cmap.png` | CMAP drug target distribution by disease area |
| | `stacked_bar_drug_targets_tahoe.png` | TAHOE drug target distribution by disease area |

**Data:** `tahoe_cmap_analysis/case_study_special/case_study_disease_category/about_drpipe_results/`

---

### Case Study: Autoimmune

| Script | Output | Description |
|--------|--------|-------------|
| `generate_case_study_autoimmune.py` | `recovery_rate_distribution_boxplot.png` | Recovery rate distribution boxplots |
| | `drug_hits_vs_recovery_rate_scatter.png` | Hits vs recovery scatter |
| | `cmap_vs_tahoe_recovery_statistical_test.png` | Statistical comparison box/strip |
| | `phase4_recovery_heatmap.png` | Disease-specific Phase 4 recovery heatmap |

**Data:** `tahoe_cmap_analysis/validation/20_autoimmune_results_1/20_autoimmune.xlsx`, `drug_details/*.csv`

---

### Case Study: Endometriosis

| Script | Output | Description |
|--------|--------|-------------|
| `generate_case_study_endometriosis.R` | `cmap_top50_reversal_scores_heatmap.png` | CMap top-50 reversal heatmap |
| | `tahoe_top50_reversal_scores_heatmap.png` | Tahoe top-50 reversal heatmap |

**Data:** `scripts/results/endo_v4_cmap/`, `scripts/results/endo_v5_tahoe/` (sub-signature CSVs)

---

### Disease Signature Analysis

| Script | Output | Description |
|--------|--------|-------------|
| `generate_disease_signature_analysis.R` | `disease_signature_four_panel_combined.png` | 4-panel composite |
| | `signature_strength_violin.png` | Violin of signature strength |
| | `up_vs_down_strength_scatter.png` | Up vs down scatter |
| | `signature_size_before_after_filtering.png` | Size before/after standardization |
| | `up_down_gene_count_histogram.png` | Up/down gene ratio histogram |

**Data:** `tahoe_cmap_analysis/data/disease_signatures/creeds_manual_disease_signatures_standardised/*.csv`, `creeds_disease_gene_counts_across_stages.csv`

---

### Drug Class Distributions

| Script | Output | Description |
|--------|--------|-------------|
| `generate_drug_class_distributions.py` | `cmap_drug_target_classes.png` | CMap drug target class distribution |
| | `tahoe_drug_target_classes.png` | Tahoe drug target class distribution |
| | `disease_therapeutic_areas.png` | Disease therapeutic area breakdown |

**Data:** `tahoe_cmap_analysis/data/drugs/cmap_drugs.csv`, `tahoe_drugs.csv`, `disease_list.csv`

---

### Platform Comparison

| Script | Output | Description |
|--------|--------|-------------|
| `generate_platform_comparison.R` | `gene_universe_before_after_mapping.png` | Gene universe sizes before/after mapping |
| | `signature_stability_four_panel_combined.png` | 4-panel stability patchwork |
| | `stability_panel_A/B/C/D_*.png` | Individual stability panels |
| | `signature_strength_up_vs_down_violin.png` | Violin plot of signature strength |
| | `up_vs_down_regulation_strength_scatter.png` | Up vs down gene scatter |
| | `drug_overlap_venn_cmap_tahoe_opentargets.png` | Drug platform coverage Venn diagram |

**Data:** `tahoe_cmap_analysis/data/drug_signatures/` (signatures .RData, experiment CSVs), `disease_signatures/creeds_manual_disease_signatures/`, `known_drugs/known_drug_info_data.parquet`  
**Note:** Stability panels use simulated (seeded) data to illustrate platform consistency patterns.

---

## Color Convention

| Element | Color | Hex |
|---------|-------|-----|
| CMap | Warm Orange | `#F39C12` |
| Tahoe-100M | Serene Blue | `#5DADE2` |
| Known / Open Targets | Green | `#27AE60` |
| Up-regulated genes | Red | `#E74C3C` |
| Down-regulated genes | Blue | `#3498DB` |

---

## Reproducing All Figures

To regenerate every manuscript figure from scratch:

```bash
# From the repository root

# R-based figures
Rscript visuals/scripts/generate_analysis_across_diseases.R
Rscript visuals/scripts/generate_case_study_endometriosis.R
Rscript visuals/scripts/generate_disease_signature_analysis.R
Rscript visuals/scripts/generate_platform_comparison.R

# Python-based figures
python3 visuals/scripts/generate_biological_concordance.py
python3 visuals/scripts/generate_case_study_autoimmune.py
python3 visuals/scripts/generate_drug_class_distributions.py
```

Outputs land in their respective `visuals/figures/<category>/` subdirectories. Each script prints its output path on completion.

**Total output**: ~30 publication-quality figures (PNG format).
