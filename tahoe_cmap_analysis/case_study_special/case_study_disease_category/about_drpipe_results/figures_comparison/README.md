# Drug Repurposing Analysis: Cross-Comparisons

## Overview

This folder contains **cross-comparison figures** that enable direct comparison across:
1. **CMAP vs Tahoe** (platform comparison)
2. **Recovered vs All Discoveries** (validation vs complete predictions)

All figures use **consistent rows and columns** (12 therapeutic areas × 10 drug target classes).

---

## Figure Descriptions

### 1. [cmap_recovered_vs_all.png](cmap_recovered_vs_all.png)
**CMAP: Recovered vs All Discoveries**

Side-by-side heatmaps comparing CMAP's validated drug-disease pairs (left) with all pipeline predictions (right). Uses the same color scale for direct comparison. Key insight: Shows how CMAP's validated predictions compare to its complete output.

### 2. [tahoe_recovered_vs_all.png](tahoe_recovered_vs_all.png)
**Tahoe: Recovered vs All Discoveries**

Side-by-side heatmaps comparing Tahoe's validated drug-disease pairs (left) with all pipeline predictions (right). Uses the same color scale for direct comparison. Key insight: Shows how Tahoe's validated predictions compare to its complete output.

### 3. [comprehensive_2x2.png](comprehensive_2x2.png)
**Comprehensive 2×2 Grid: All Four Conditions**

Raw count heatmaps showing:
- Top-left: CMAP Recovered
- Top-right: Tahoe Recovered
- Bottom-left: CMAP All Discoveries
- Bottom-right: Tahoe All Discoveries

All four heatmaps use the **same color scale** (based on global maximum) for direct numerical comparison.

### 4. [comprehensive_2x2_normalized.png](comprehensive_2x2_normalized.png)
**Normalized 2×2 Grid: Percentage Distributions**

Row-normalized heatmaps (% within each disease therapeutic area) showing:
- Top-left: CMAP Recovered (%)
- Top-right: Tahoe Recovered (%)
- Bottom-left: CMAP All Discoveries (%)
- Bottom-right: Tahoe All Discoveries (%)

This enables comparison of **drug target profiles** across conditions, removing the effect of different total counts.

---

## Consistent Categories

All figures use identical rows and columns:

### Rows (12 Disease Therapeutic Areas)
1. Cancer/Tumor
2. Genetic/Congenital
3. Immune System
4. Nervous System
5. Gastrointestinal
6. Musculoskeletal
7. Respiratory
8. Hematologic
9. Endocrine System
10. Skin/Integumentary
11. Cardiovascular
12. Infectious Disease

### Columns (10 Drug Target Classes)
1. Enzyme
2. Membrane receptor
3. Transcription factor
4. Ion channel
5. Transporter
6. Epigenetic regulator
7. Unclassified protein
8. Other cytosolic protein
9. Secreted protein
10. Structural protein

---

## Color Convention

- **CMAP**: Warm Orange (`#F39C12`) colormap
- **Tahoe**: Serene Blue (`#5DADE2`) colormap

---

## Key Observations

### From comprehensive_2x2.png (Raw Counts):
- Tahoe generates more predictions across all disease-drug combinations
- Both platforms show strong activity in Cancer/Tumor diseases
- Enzyme-targeting drugs dominate Tahoe's output

### From comprehensive_2x2_normalized.png (Percentages):
- Tahoe has ~50% enzyme-targeting drugs regardless of validation status
- CMAP shows more balanced distribution across drug target classes
- The pattern is consistent between recovered and all discoveries

---

*Generated: January 2025*
*Script: unified_visualization.py*
