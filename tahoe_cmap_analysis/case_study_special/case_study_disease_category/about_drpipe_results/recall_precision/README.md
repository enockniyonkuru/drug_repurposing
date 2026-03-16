# Precision & Recall Analysis for Drug Repurposing Pipeline

## Overview

This directory contains a comprehensive analysis of precision and recall metrics for both CMAP and TAHOE drug repurposing pipelines, validating predictions against the Open Targets database.

### Key Metrics

**Precision:** Of all drugs predicted by DRpipe for a disease, what percentage are validated in Open Targets?
$$\text{Precision} = \frac{S}{I} \times 100\%$$

**Recall:** Of all known disease-drug relationships available in the CMAP/TAHOE databases, what percentage did we successfully predict?
$$\text{Recall} = \frac{S}{P} \times 100\%$$

Where:
- **U** = All known disease-drug pairs in Open Targets
- **P** = Subset of U where drugs exist in CMAP/TAHOE database (maximum recoverable)
- **I** = All predictions made by DRpipe for this disease
- **S** = Successfully recovered = I ∩ U

---

## Directory Structure

```
recall_precision/
├── ANALYSIS_PLAN.md              # Detailed methodology and workflow
├── README.md                      # This file
├── scripts/
│   ├── 01_prepare_data.py
│   ├── 02_calculate_precision_recall.py
│   ├── 03_aggregate_statistics.py
│   ├── 04_generate_figures.py
│   ├── 05_generate_report.py
│   └── run_all.py
├── intermediate_data/
│   ├── disease_universes.csv
│   ├── cmap_precision_recall_per_disease.csv
│   ├── tahoe_precision_recall_per_disease.csv
│   └── summary_statistics.csv
├── figures/
│   ├── figure_01_precision_distribution.png
│   ├── figure_02_recall_distribution.png
│   ├── figure_03_precision_vs_recall_scatter.png
│   ├── figure_04_comparison_boxplot.png
│   ├── figure_05_disease_heatmap.png
│   └── figure_06_summary_table.png
└── outputs/
    ├── platform_comparison.csv
    ├── ANALYSIS_RESULTS.md
    └── MANUSCRIPT_PARAGRAPH.txt
```

---

## Quick Start

### Option 1: Run Everything at Once
```bash
python scripts/run_all.py
```

### Option 2: Run Step by Step
```bash
cd scripts/

# 1. Prepare data (extract universes)
python 01_prepare_data.py

# 2. Calculate precision & recall per disease
python 02_calculate_precision_recall.py

# 3. Generate summary statistics
python 03_aggregate_statistics.py

# 4. Create visualizations
python 04_generate_figures.py

# 5. Generate comprehensive report
python 05_generate_report.py
```

---

## Data Requirements

The analysis requires the following CSV files in the parent directory:
- `open_target_cmap_recovered.csv` - CMAP recovered drugs from Open Targets
- `open_target_tahoe_recovered.csv` - TAHOE recovered drugs from Open Targets
- `all_discoveries_cmap.csv` - All CMAP predictions
- `all_discoveries_tahoe.csv` - All TAHOE predictions

Expected columns (case-insensitive):
- `disease` or `disease_therapeutic_areas`
- `drug_name` or `drug`
- `drug_id` or `drug_identifier`

---

## Output Files

### Per-Disease Results
- **`cmap_precision_recall_per_disease.csv`**
  - Columns: disease, I (predicted), S (recovered), P (possible), Precision (%), Recall (%)
  
- **`tahoe_precision_recall_per_disease.csv`**
  - Columns: disease, I (predicted), S (recovered), P (possible), Precision (%), Recall (%)

### Summary Statistics
- **`summary_statistics.csv`**
  - Platform-level aggregated metrics (mean, median, SD, percentiles)

- **`platform_comparison.csv`**
  - Side-by-side comparison of CMAP vs TAHOE

### Figures
- **Distribution plots**: Histograms and box plots showing metric distributions
- **Scatter plot**: Precision vs Recall colored by disease
- **Heatmap**: Per-disease metric values
- **Summary tables**: Comparison of platforms with key statistics

### Final Report
- **`ANALYSIS_RESULTS.md`**: Comprehensive analysis with findings, interpretation, and limitations
- **`MANUSCRIPT_PARAGRAPH.txt`**: Publication-ready paragraph summarizing results

---

## Key Results to Expect

### Interpretation
- **High Precision, Low Recall**: Selective predictions, but missing many known relationships
- **Low Precision, High Recall**: Catches most known drugs but makes many false predictions
- **High Precision, High Recall**: Ideal—selective and comprehensive

### Platform Comparison
The analysis will reveal:
1. Which platform (CMAP or TAHOE) has better precision
2. Which platform has better recall
3. Disease-level variation in both metrics
4. Correlation between precision and recall

---

## Methodology Details

See `ANALYSIS_PLAN.md` for:
- Detailed workflow of each analysis phase
- Handling of edge cases (P=0, I=0, duplicates)
- Validation checks
- Implementation details

---

## Dependencies

```
python >= 3.8
pandas >= 1.1.0
numpy >= 1.19.0
matplotlib >= 3.3.0
seaborn >= 0.11.0
scipy >= 1.5.0
```

Install with:
```bash
pip install pandas numpy matplotlib seaborn scipy
```

---

## Notes

- All calculations are performed **per-disease** to enable disease-level analysis
- **Recall denominator (P)** is specific to each platform:
  - CMAP recall = S / (known drugs in CMAP universe)
  - TAHOE recall = S / (known drugs in TAHOE universe)
- Diseases with P=0 or I=0 are handled appropriately (marked N/A)
- All intermediate data is saved for reproducibility and further analysis

---

## Validation

Before trusting results, the scripts perform automatic validation:
- ✓ S ≤ I (recovered cannot exceed predicted)
- ✓ S ≤ P (recovered cannot exceed possible)
- ✓ P ≤ U (possible cannot exceed universe)
- ✓ Consistency checks on drug matching
- ✓ Detection of anomalous metrics per disease

---

## Contact & Questions

For questions about methodology or interpretation, refer to:
- `ANALYSIS_PLAN.md` for workflow details
- Code comments in individual scripts
- `ANALYSIS_RESULTS.md` for interpretation guide

