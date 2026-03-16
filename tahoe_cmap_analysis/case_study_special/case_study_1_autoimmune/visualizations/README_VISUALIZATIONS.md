# Manuscript Visualizations Guide

## Overview

This folder contains comprehensive visualizations of disease analysis results from your DRPipe pipeline, comparing TAHOE and CMAP methods across 4 disease cases. The visualizations are organized into **individual disease analyses** and **comparative 4-disease analyses**.

---

## Folder Structure

```
visualizations/
├── 01_cerebral_palsy/
├── 02_eczema/
├── 03_autoimmune_thrombocytopenic_purpura/
├── 04_chronic_lymphocytic_leukemia/
├── 02_all_diseases_hit_distribution.png
├── 03_all_diseases_recall.png
├── 04_all_diseases_heatmap.png
├── 05_all_diseases_ot_coverage.png
├── 06_performance_scatter.png
├── 07_common_hits.png
├── 08_summary_table.png
├── 09_disease_summary_grid.png
├── VISUALIZATION_SUMMARY.txt
└── README_VISUALIZATIONS.md
```

---

## Individual Disease Visualizations

Each disease folder (01-04) contains **5 complementary visualizations**:

### Format: `Disease_Folder/01_comprehensive_overview.png`
A **4-panel overview** combining all metrics for quick assessment:
- **Top-left**: Hit comparison (TAHOE vs CMAP)
- **Top-right**: Recall metrics (percentage of known pairs found)
- **Bottom-left**: OpenTarget coverage (pairs confirmed in OT database)
- **Bottom-right**: Method overlap (pie chart of shared hits)

**Best for**: Manuscripts - shows complete story of one disease in a single figure

### Format: `Disease_Folder/01a_hit_comparison.png`
**Bar chart** showing total number of hits found by each method
- Red bar: TAHOE method
- Teal bar: CMAP method
- Useful for: Highlighting method performance differences

### Format: `Disease_Folder/01b_recall_metrics.png`
**Recall percentages** - what % of known disease-drug pairs were recovered?
- Shows how well each method performs against known relationships
- Useful for: Demonstrating validation against OpenTargets database

### Format: `Disease_Folder/01c_ot_coverage.png`
**OpenTarget pairs** actually found by each method
- Shows validated hits confirmed in the OT database
- Useful for: Emphasizing reproducibility and database agreement

### Format: `Disease_Folder/01d_method_overlap.png`
**Pie chart** showing unique and shared hits
- Reveals whether methods are finding the same drugs or complementary ones
- Useful for: Discussing method complementarity

---

## 4-Disease Comparative Visualizations

### `02_all_diseases_hit_distribution.png`
**Dodged bar chart** comparing hits across all 4 diseases
- See which diseases yield more candidates
- Compare TAHOE vs CMAP performance across diseases
- **Figure type**: Publication-ready comparative analysis

### `03_all_diseases_recall.png`
**Recall performance** across all diseases with percentages labeled
- Directly compares method accuracy across disease cases
- Shows consistency of performance
- **Use case**: Validating generalizability of approach

### `04_all_diseases_heatmap.png`
**Heat map** of hits: TAHOE, CMAP, and Common across diseases
- Purple intensity indicates hit count
- Easy to spot patterns: which diseases have more hits?
- **Use case**: Identifying disease-specific patterns

### `05_all_diseases_ot_coverage.png`
**OT-validated pairs** found by each method
- Shows real database hits (not just computational predictions)
- Emphasizes reproducibility in established databases
- **Figure type**: Great for Methods/Validation section

### `06_performance_scatter.png`
**Method comparison scatter plot**
- X-axis: TAHOE Recall (%)
- Y-axis: CMAP Recall (%)
- Bubble size: Total hits found
- Diagonal dashed line: Equal performance
- **Use case**: Shows if methods are complementary or redundant

### `07_common_hits.png`
**Common hits** found by both methods
- Horizontal bar chart sorted by magnitude
- Shows consensus candidates (high confidence)
- **Use case**: Identifying high-confidence, method-independent predictions

### `08_summary_table.png`
**Data table** with all key metrics
- Easy reference for exact numbers
- Can be placed in Methods or Results section
- Format: PNG for manuscript embedding

### `09_disease_summary_grid.png`
**2×2 grid** with summary statistics for each disease
- Disease name, hit counts, and recall for all 4 diseases
- Compact view showing key metrics side-by-side
- **Use case**: Supplementary material overview

---

## Recommended Manuscript Figures

### Main Text (Publication)

| Purpose | Recommended Figure |
|---------|-------------------|
| Show method comparison across diseases | `03_all_diseases_recall.png` |
| Highlight total candidate drugs found | `02_all_diseases_hit_distribution.png` |
| Show method complementarity | `06_performance_scatter.png` |
| Validate against databases | `05_all_diseases_ot_coverage.png` |
| Individual disease deep-dive | `Disease_Folder/01_comprehensive_overview.png` |

### Supplementary Material

| Purpose | Recommended Figure |
|---------|-------------------|
| Complete disease-by-disease analysis | `Disease_Folder/*` (all 4) |
| All metrics in one table | `08_summary_table.png` |
| Heatmap view of patterns | `04_all_diseases_heatmap.png` |
| Disease summary overview | `09_disease_summary_grid.png` |
| High-confidence candidates | `07_common_hits.png` |

---

## Data Metrics Explained

### Hit Counts
- **TAHOE Hits**: Number of unique drugs found using TAHOE method
- **CMAP Hits**: Number of unique drugs found using CMAP method
- **Common Hits**: Drugs found by both methods (consensus candidates)

### Recall (%)
- Definition: % of known disease-drug pairs (from OpenTargets) that were recovered
- Higher = better recovery of established relationships
- Formula: `(Pairs Found by Method) / (Total Known Pairs) × 100`

### OpenTarget Validation
- **Total OT Pairs**: All known disease-drug relationships in OpenTargets DB
- **OT + TAHOE (DRPipe Found)**: Known OT pairs that DRPipe found via TAHOE
- **OT + CMAP (DRPipe Found)**: Known OT pairs that DRPipe found via CMAP

---

## Quick Reference: Key Statistics

```
DISEASES ANALYZED:
  1. Cerebral Palsy
  2. Eczema
  3. Autoimmune Thrombocytopenic Purpura
  4. Chronic Lymphocytic Leukemia

METHOD SUMMARY:
  - TAHOE: DGCA + DRPipe drug prioritization
  - CMAP: Connectivity Map + drug selection
  - Common: High-confidence candidates (found by both)
```

---

## File Specifications

- **Format**: PNG files (300 DPI)
- **Resolution**: High-quality for print and digital publication
- **Color scheme**: 
  - TAHOE: Serene Blue (#5DADE2)
  - CMAP: Warm Orange (#F39C12)
- **Fonts**: Publication-standard sans-serif
- **Size**: Varies (4-14 inches width), optimized for manuscript columns

---

## How to Use in Your Manuscript

### Step 1: Select Figures
Choose 3-5 main figures from the comparative visualizations for main text.

### Step 2: Create Figure Legends
Example legend for `03_all_diseases_recall.png`:

> **Figure X: Recall Performance of TAHOE and CMAP Methods**
> 
> Percentage of known disease-drug pairs (from OpenTargets database) recovered by each method across four disease cases. Error bars indicate... [add your context]. The TAHOE method achieved average recall of X%, while CMAP achieved Y%, demonstrating [your interpretation].

### Step 3: Supplementary Material
Include all individual disease visualizations and additional comparatives in supplementary materials.

### Step 4: Data Table
Reference `08_summary_table.png` in your Methods or Results section for exact values.

---

## Customization Options

To regenerate or modify visualizations:

1. **Edit colors**: Modify hex codes in `generate_visualizations.R` (lines marked `#FF6B6B`, `#4ECDC4`, etc.)
2. **Change figure size**: Adjust `width =` and `height =` parameters in `ggsave()` calls
3. **Modify titles/labels**: Edit `labs()` and `annotate()` functions
4. **Add/remove metrics**: Edit the data selection and plotting sections

---

## Data Source

All visualizations generated from: `4_disease_results.xlsx`

**Creation Date**: December 5, 2025  
**Generator Script**: `generate_visualizations.R`

---

## Questions or Issues?

- All PNG files are ready for immediate manuscript use
- High DPI ensures crisp printing and digital display
- All files are self-contained (no external dependencies)
- Colors are colorblind-accessible where possible

---

**Good luck with your manuscript submission!** 🎯

