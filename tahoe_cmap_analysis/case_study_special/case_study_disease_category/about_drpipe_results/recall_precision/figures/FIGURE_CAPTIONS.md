# Figure Captions: Precision & Recall Analysis

## Overview
This document provides detailed captions for all figures in the precision and recall validation analysis of the CMAP and TAHOE drug repurposing pipelines.

---

## Figure 1A: Precision Distribution - Histogram

Histogram showing the distribution of precision values across diseases for both CMAP (orange) and TAHOE (blue) pipelines. Dashed vertical lines indicate mean precision for each platform. TAHOE shows higher mean precision (9.9%) compared to CMAP (5.5%), indicating more accurate predictions on average.

---

## Figure 1B: Precision Distribution - Density Plot

Kernel density estimate (KDE) plot showing the probability density of precision values. TAHOE demonstrates a broader distribution with higher density at elevated precision values, while CMAP shows concentration at lower precision values with a long tail.

---

## Figure 2A: Recall Distribution - Histogram

Histogram showing the distribution of recall values across diseases. Both platforms achieve similar mean recall (~60%), with most diseases showing recall between 0-100%. The high variance reflects disease-dependent availability of known drug-disease relationships in the Open Targets database.

---

## Figure 2B: Recall Distribution - Density Plot

Kernel density estimate (KDE) showing recall value distributions. Both platforms exhibit bimodal distributions with peaks at lower recall values and at 100% recall, indicating that many diseases have perfect recovery of available known drugs.

---

## Figure 3: Precision vs Recall Scatter Plot

Scatter plot showing the relationship between precision and recall for each disease across both platforms. Each point represents one disease; stars indicate platform means. TAHOE shows superior mean precision (9.9% vs 5.5%) with similar recall, indicating better selectivity of predictions while maintaining comprehensive coverage.

---

## Figure 4A: Precision Comparison - Box Plot

Box plot comparing precision distributions between CMAP and TAHOE. TAHOE (blue) shows higher median and mean precision, with greater variability. Both platforms show right-skewed distributions with outliers at higher precision values.

---

## Figure 4B: Recall Comparison - Box Plot

Box plot comparing recall distributions. Both platforms show similar distributions with means around 60%, indicating comparable coverage of known disease-drug relationships. CMAP shows slightly higher median recall (61.3% vs 59.1%), though the difference is not statistically significant.

---

## Figure 5: Per-Disease Precision and Recall Heatmap

Heatmap showing precision and recall values for the top 20 diseases (selected by highest recall). Color intensity represents percentage values (green=high, red=low). Disease rows are ordered to highlight variation in performance across therapeutic areas and platforms.

---

## Figure 6: Summary Statistics Table

Summary statistics comparing CMAP and TAHOE across all diseases analyzed. TAHOE demonstrates higher mean precision (9.9% ± 13.7%) compared to CMAP (5.5% ± 6.5%), while recall values are comparable. SD indicates higher variability in TAHOE results, reflecting disease-dependent performance.

---

## Figure Organization

**Figure 1**: Precision Distribution
- Panel A: Histogram showing frequency distribution of precision values
- Panel B: Kernel density estimate for smoother visualization

**Figure 2**: Recall Distribution  
- Panel A: Histogram showing frequency distribution of recall values
- Panel B: Kernel density estimate for smoother visualization

**Figure 3**: Precision-Recall Relationship
- Scatter plot with individual diseases as points
- Stars indicate platform-level means

**Figure 4**: Box Plot Comparisons
- Panel A: Precision comparison between platforms
- Panel B: Recall comparison between platforms

**Figure 5**: Per-Disease Heatmap
- Top 20 diseases selected by highest recall
- Four columns: CMAP Precision, CMAP Recall, TAHOE Precision, TAHOE Recall

**Figure 6**: Summary Statistics Table
- Aggregate statistics across all diseases
- Mean and standard deviation for each metric

---

## Color Scheme

Throughout all figures:
- **CMAP**: Warm Orange (#F39C12)
- **TAHOE**: Serene Blue (#5DADE2)

This consistent color scheme facilitates visual distinction between platforms across all analyses.

---

## Data Availability

All underlying data are available in the intermediate_data/ directory:
- `cmap_precision_recall_per_disease.csv` - Per-disease metrics for CMAP (101 diseases)
- `tahoe_precision_recall_per_disease.csv` - Per-disease metrics for TAHOE (112 diseases)
- `summary_statistics.csv` - Aggregated statistics

---

## Interpretation Guide

**Precision** (% of predictions validated)
- Higher precision indicates fewer false positives
- TAHOE achieves 1.8× higher mean precision (9.9% vs 5.5%)

**Recall** (% of known relationships recovered)
- Higher recall indicates more comprehensive coverage
- Both platforms achieve similar mean recall (~60%)

**Ideal Performance**: High precision (selective) + High recall (comprehensive)

---

Generated: January 6, 2026
Analysis: Precision & Recall Validation of Drug Repurposing Pipelines
