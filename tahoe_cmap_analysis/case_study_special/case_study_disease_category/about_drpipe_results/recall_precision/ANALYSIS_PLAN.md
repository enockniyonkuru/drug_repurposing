# Precision & Recall Analysis Plan
## Drug Repurposing Pipeline Validation Against Open Targets

---

## Overview
Calculate precision and recall metrics for both CMAP and TAHOE pipelines, measuring how well predictions align with validated disease-drug relationships from Open Targets.

---

## Definitions

### Per-Disease Variables
| Variable | Definition | Symbol |
|----------|-----------|--------|
| **U** | All known disease-drug pairs in Open Targets (union) | Universe |
| **P** | Subset of U where drugs exist in CMAP/TAHOE database | Possible (max recoverable) |
| **I** | All predictions made by DRpipe for this disease | Identified (predicted) |
| **S** | Intersection of predictions ∩ validated drugs = I ∩ U | Success (recovered) |

### Metrics
- **Precision = S / I** = Of all predictions, what % were validated?
- **Recall = S / P** = Of all recoverable known drugs, what % did we predict?

---

## Data Requirements

### Input Files Needed
1. **Open Targets Validated Data**
   - File: `open_target_cmap_recovered.csv` and `open_target_tahoe_recovered.csv`
   - Contains: disease, drug_name, drug_id, mechanism_of_action

2. **CMAP Predictions (All Discoveries)**
   - File: `all_discoveries_cmap.csv`
   - Contains: disease, drug_name, drug_id, score/rank

3. **TAHOE Predictions (All Discoveries)**
   - File: `all_discoveries_tahoe.csv`
   - Contains: disease, drug_name, drug_id, score/rank

4. **Drug Availability in Databases**
   - Extract unique drugs from all_discoveries_cmap.csv → CMAP drug universe
   - Extract unique drugs from all_discoveries_tahoe.csv → TAHOE drug universe

---

## Analysis Workflow

### Phase 1: Data Preparation
**Script:** `01_prepare_data.py`

**Steps:**
1. Load all datasets
2. Extract Open Targets universe (U) per disease
3. Extract CMAP drug universe from all_discoveries_cmap.csv
4. Extract TAHOE drug universe from all_discoveries_tahoe.csv
5. For each disease:
   - Calculate P_cmap = drugs in U that exist in CMAP universe
   - Calculate P_tahoe = drugs in U that exist in TAHOE universe
6. Create intermediate dataframe: `disease_universes.csv`
   - Columns: disease, U_count, P_cmap, P_tahoe, I_cmap, I_tahoe

**Output:**
- `disease_universes.csv`: Summary of universe sizes per disease

---

### Phase 2: Precision & Recall Calculation
**Script:** `02_calculate_precision_recall.py`

**Steps:**

#### For CMAP:
```
For each disease in all_discoveries_cmap.csv:
  I = all drugs predicted for this disease (count)
  S = drugs in (I AND Open_Targets_recovered) (count)
  P = drugs in (Open_Targets U AND CMAP_universe) (count)
  
  Precision_cmap = S / I * 100
  Recall_cmap = S / P * 100
```

#### For TAHOE:
```
For each disease in all_discoveries_tahoe.csv:
  I = all drugs predicted for this disease (count)
  S = drugs in (I AND Open_Targets_recovered) (count)
  P = drugs in (Open_Targets U AND TAHOE_universe) (count)
  
  Precision_tahoe = S / I * 100
  Recall_tahoe = S / P * 100
```

**Output Files:**
- `cmap_precision_recall_per_disease.csv`: Columns: disease, I, S, P, Precision, Recall
- `tahoe_precision_recall_per_disease.csv`: Columns: disease, I, S, P, Precision, Recall

---

### Phase 3: Aggregation & Summary Statistics
**Script:** `03_aggregate_statistics.py`

**Calculations:**

For each platform (CMAP and TAHOE):
```
Precision:
  - Mean ± SD
  - Median (Q2), Q1, Q3
  - Min, Max, Range
  - Distribution (histogram bins)
  
Recall:
  - Mean ± SD
  - Median (Q2), Q1, Q3
  - Min, Max, Range
  - Distribution (histogram bins)
```

**Output Files:**
- `summary_statistics.csv`: Table with all aggregated metrics
- `platform_comparison.csv`: Side-by-side CMAP vs TAHOE stats

---

### Phase 4: Visualization
**Script:** `04_generate_figures.py`

**Figures to Generate:**

1. **Distribution Plots**
   - Histogram: Precision distribution (CMAP vs TAHOE)
   - Histogram: Recall distribution (CMAP vs TAHOE)
   - Box plots: Precision comparison
   - Box plots: Recall comparison

2. **Scatter Plots**
   - Precision vs Recall scatter (colored by disease)
   - Precision vs I (number of predictions)
   - Recall vs P (number of possible recoverable)

3. **Summary Table Figures**
   - Mean ± SD comparison table (CMAP vs TAHOE)
   - Percentile comparison table

4. **Disease-Level Heatmap**
   - Rows: diseases
   - Columns: Precision_CMAP, Recall_CMAP, Precision_TAHOE, Recall_TAHOE
   - Color intensity by metric value

**Output Files:**
- `figure_01_precision_distribution.png`
- `figure_02_recall_distribution.png`
- `figure_03_precision_vs_recall_scatter.png`
- `figure_04_comparison_boxplot.png`
- `figure_05_disease_heatmap.png`
- `figure_06_summary_table.png`

---

### Phase 5: Summary Report
**Script:** `05_generate_report.py`

**Output Files:**
- `ANALYSIS_RESULTS.md`: Comprehensive markdown report with:
  - Key findings
  - Summary statistics tables
  - Interpretation
  - Figure captions
  - Limitations

---

## Directory Structure

```
recall_precision/
├── ANALYSIS_PLAN.md (this file)
├── README.md (overview and how to run)
├── scripts/
│   ├── 01_prepare_data.py
│   ├── 02_calculate_precision_recall.py
│   ├── 03_aggregate_statistics.py
│   ├── 04_generate_figures.py
│   └── 05_generate_report.py
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
├── outputs/
│   ├── platform_comparison.csv
│   ├── ANALYSIS_RESULTS.md
│   └── MANUSCRIPT_PARAGRAPH.txt
└── run_all.py (master script to execute everything)
```

---

## Implementation Details

### Key Matching Criteria
- **Disease matching**: Use exact string match or fuzzy matching?
  - *Recommendation*: Exact match, with case-insensitive comparison
  
- **Drug matching**: 
  - Primary: drug_id (if available)
  - Secondary: drug_name (case-insensitive, whitespace normalized)
  - *Recommendation*: Use drug_id when available, fall back to name
  
- **Handling duplicates**: 
  - If a disease-drug pair appears multiple times, count as 1

### Edge Cases
1. **Diseases with P = 0**: 
   - Recall undefined (0/0)
   - Handle: Mark as "N/A" or exclude from mean calculation

2. **Diseases with I = 0**: 
   - Precision undefined (0/0)
   - Handle: Mark as "N/A" or exclude from mean calculation

3. **Multiple diseases per row**:
   - Split into individual disease entries for per-disease calculation

---

## Execution Order

```bash
python 01_prepare_data.py           # ~1 min
python 02_calculate_precision_recall.py  # ~2 min
python 03_aggregate_statistics.py   # ~1 min
python 04_generate_figures.py       # ~3 min
python 05_generate_report.py        # ~1 min

# Or all at once:
python run_all.py
```

---

## Expected Outputs

### Summary Statistics Example
```
Platform: CMAP
Precision (%)
  Mean:   45.3 ± 28.2
  Median: 42.1
  Q1-Q3:  18.5-68.9
  Min-Max: 0-100
  
Recall (%)
  Mean:   12.5 ± 8.3
  Median: 10.2
  Q1-Q3:  6.1-17.4
  Min-Max: 0-45.2
```

### Key Metrics to Report
- Average precision and recall per platform
- Percentage of diseases with precision > 50%
- Percentage of diseases with recall > 20%
- Diseases with highest/lowest precision and recall
- Correlation between precision and recall

---

## Validation Checks

Before finalizing results:
1. ✓ Verify S ≤ I (recovered ≤ predicted)
2. ✓ Verify S ≤ P (recovered ≤ possible)
3. ✓ Verify P ≤ U (possible ≤ universe)
4. ✓ Check for diseases with anomalous metrics
5. ✓ Verify drug name/ID consistency across files

---

## Notes
- All calculations will be per-disease to allow disease-level analysis
- Both platform-level and disease-level results will be reported
- Code will include extensive logging for transparency
- All intermediate data saved for reproducibility

