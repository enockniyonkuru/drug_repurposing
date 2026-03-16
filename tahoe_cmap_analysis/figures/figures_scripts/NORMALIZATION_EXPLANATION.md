## Normalized Comparison: Fair Assessment Between TAHOE and CMAP

### Normalization Approach

The two pipelines (TAHOE and CMAP) return different numbers of candidate drugs due to their different underlying architecture and scoring systems. To enable a **fair comparison**, we normalized the recall metric to account for these differences.

### Normalization Method

**Normalization Factor Calculation:**
- TAHOE total candidate drugs: **45,122.83**
- CMAP total candidate drugs: **42,367.06**
- Ratio (TAHOE/CMAP): **1.065**

**Interpretation:** CMAP returns approximately 0.9x the candidates of TAHOE (or TAHOE returns ~6.5% more candidates).

**Adjustment Applied:**
- TAHOE Recall: Used as-is (baseline)
- CMAP Recall: Multiplied by 1.065 to adjust for the smaller candidate pool

This normalization answers the question: **"If CMAP had returned the same number of candidates as TAHOE, what would its recall be?"**

### Key Metrics After Normalization

| Metric | TAHOE | CMAP | Notes |
|--------|-------|------|-------|
| **Mean Recall** | 50.2% | 22.4% | TAHOE still outperforms significantly |
| **Median Recall** | 50.0% | 13.6% | Strong advantage to TAHOE |
| **Mean Precision** | 2.74% | 1.85% | TAHOE more precise |
| **Median Precision** | 1.55% | 0.80% | TAHOE's median is ~2x CMAP |

### Generated Files

1. **Fig6_Precision_vs_Recall_Scatter_NORMALIZED.png**
   - Scatter plot comparing precision vs recall (normalized) for all 234 diseases
   - Faceted by pipeline for easy comparison
   - X-axis: Recall (Normalized)
   - Y-axis: Precision

2. **Option3_DotPlot_With_Lines_NORMALIZED.png**
   - Dot plot showing metrics by match type (name vs synonym)
   - Demonstrates performance consistency across different matching strategies
   - Uses normalized recall values for fair comparison

### What Changed vs. Original Figures

- **Option3**: Recall values for CMAP adjusted upward (reflecting the normalization)
- **Fig6**: X-axis now shows normalized recall instead of raw recall values

### Conclusion

Even after normalization to account for different drug pool sizes:
- **TAHOE maintains a significant performance advantage**
- This suggests TAHOE's better performance is not solely due to returning more candidates
- TAHOE has better specificity and efficiency in its drug candidate selection
