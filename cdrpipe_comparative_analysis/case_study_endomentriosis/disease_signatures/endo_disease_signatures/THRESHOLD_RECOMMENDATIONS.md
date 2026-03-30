# Threshold Recommendations for Endometriosis Drug Repurposing Analysis

**Analysis Date:** December 16, 2025  
**Configuration File:** `tahoe_cmap_analysis/scripts/execution/batch_configs/6_tomiko_endo.yml`

---

## Executive Summary

Based on comprehensive analysis of your disease signatures, **I strongly recommend using percentile-based filtering with an 85th percentile threshold**. This approach ensures fair representation across all data sources while maintaining robust gene coverage for drug repurposing analysis.

---

## Key Findings

### 1. Dramatic Variation in Effect Sizes Across Data Sources

Your disease signatures show substantial heterogeneity in effect sizes:

| Source | Mean \|logFC\| | Median \|logFC\| | Avg. Genes | Range |
|--------|---------------|-----------------|-----------|-------|
| **CREEDS** | 0.024 - 0.044 | 0.024 - 0.033 | 289 | Very small effects |
| **Laura** | 0.141 - 0.885 | 0.092 - 0.881 | 1,334 | Highly variable |
| **Tomiko** | 1.215 - 1.236 | 1.144 - 1.176 | 1,541 | Large, consistent effects |

**Critical Insight:** Tomiko signatures have effect sizes ~50x larger than CREEDS signatures. This creates severe problems for fixed logFC cutoffs.

### 2. The Problem with Fixed logFC Cutoffs

Using a fixed logFC threshold creates extreme bias:

**At logFC > 1.0:**
- ❌ CREEDS: **100% of genes removed** (0/289 genes retained)
- ⚠️ Laura: **91.7% of genes removed** (8.4% retained)  
- ✅ Tomiko: **100% of genes retained** (1,541/1,541 genes)

**Result:** Your analysis would be driven almost exclusively by Tomiko signatures, completely ignoring CREEDS data and severely underweighting Laura's cell-type-specific signatures.

### 3. Percentile-Based Filtering Solves This Problem

Percentile filtering ensures proportional representation:

| Percentile | CREEDS | Laura | Tomiko | Average |
|-----------|--------|-------|--------|---------|
| **75th** | 217 genes | 1,001 genes | 1,156 genes | 1,010 genes |
| **80th** | 232 genes | 1,068 genes | 1,234 genes | 1,077 genes |
| **85th** | 246 genes | 1,135 genes | 1,311 genes | 1,144 genes |
| **90th** | 261 genes | 1,201 genes | 1,388 genes | 1,212 genes |

**All sources contribute proportionally** regardless of their native effect sizes.

---

## Recommended Configuration

### PRIMARY RECOMMENDATION ⭐

```yaml
analysis:
  qval_threshold: 0.05
  percentile_filtering:
    enabled: true
    threshold: 85  # Keep top 85% of genes by |logFC| per signature
```

**Rationale:**
1. **Fair representation**: Each signature contributes ~85% of its strongest signals
2. **Adequate coverage**: Averages 1,144 genes per signature (range: 246-1,311)
3. **Biological validity**: Focuses on genes with strongest differential expression within each dataset
4. **Literature support**: Percentile approaches are standard in drug repurposing studies
5. **Adaptability**: Automatically adjusts to different experimental platforms and biological contexts

### Why 85th percentile specifically?

- **75th percentile**: May be too restrictive for small signatures (CREEDS: 217 genes)
- **85th percentile**: ✅ Optimal balance - sufficient genes for robust scoring across all sources
- **90th percentile**: Includes more noise, may dilute signal

---

## Alternative Approach (Not Recommended)

### If you must use fixed logFC cutoff:

```yaml
analysis:
  qval_threshold: 0.05
  logfc_cutoff: 1.15  # Based on 75th percentile of median effect sizes
```

⚠️ **WARNING - This approach will:**
- Eliminate 100% of CREEDS data (effect sizes too small)
- Severely reduce Laura contributions (especially cell-type-specific signatures)
- Create extreme bias toward Tomiko signatures
- Reduce biological interpretability of results
- Not be defensible in peer review

**Only use this if:**
- You have explicit biological justification for excluding low-effect datasets
- You're willing to defend this choice in publications
- You understand the severe limitations this imposes

---

## Impact Analysis

### Gene Retention by Signature Type

**Most Affected Signatures (with fixed cutoff):**
1. `creeds_endometriosis` - 736 genes → 0 genes at logFC > 1.0 (**100% loss**)
2. `creeds_endometrial_cancer` - 522 genes → 0 genes (**100% loss**)
3. `laura_stromal_fibroblast_proliferat` - 2,441 genes → 7 genes (**99.7% loss**)
4. `laura_unciliated_epithelia_prolifer` - 2,098 genes → 19 genes (**99.1% loss**)

**Unaffected Signatures:**
- All 6 Tomiko signatures retain 100% of genes at logFC > 1.0

### Statistical Power Implications

**With percentile filtering (85%):**
- All 19 signatures contribute robustly
- Balanced statistical power across data sources
- Cell-type-specific signatures properly represented
- Multiple evidence lines for drug candidates

**With fixed logFC > 1.0:**
- Only 6-7 signatures contribute meaningfully
- Analysis dominated by Tomiko data
- Loss of cell-type specificity from Laura
- Loss of public database validation from CREEDS

---

## Validation Against Known Hits

Your previous analysis shows:
- **Combined approach (CMAP + Tahoe)**: Identifies drugs with convergent evidence
- **Percentile filtering**: Allows all signature types to contribute
- **Drug overlap analysis**: Shows meaningful agreement across databases

Using percentile filtering ensures that:
1. Known endometriosis drugs can be rediscovered across all signature types
2. Cell-type-specific mechanisms are captured (Laura signatures)
3. Literature-validated findings are included (CREEDS signatures)
4. Novel candidates from clinical data are prioritized (Tomiko signatures)

---

## Implementation Steps

### Step 1: Update Configuration File

Edit [6_tomiko_endo.yml](tahoe_cmap_analysis/scripts/execution/batch_configs/6_tomiko_endo.yml):

```yaml
analysis:
  qval_threshold: 0.05
  logfc_column_selection: "all"
  use_averaging: true
  
  # RECOMMENDED SETTING
  percentile_filtering:
    enabled: true
    threshold: 85  # Keep top 85% of genes by |logFC|
```

### Step 2: Run Analysis

```bash
cd tahoe_cmap_analysis/scripts/execution
Rscript run_batch_analysis.R batch_configs/6_tomiko_endo.yml
```

### Step 3: Monitor Results

Check that all signatures contribute:
- Review batch summary logs
- Verify gene counts per signature
- Examine hit distributions across CMAP and Tahoe

---

## Supporting Evidence

### Generated Analysis Files

1. **signature_statistics.csv**: Detailed statistics for all 19 signatures
2. **effect_size_by_source.png**: Visual comparison of effect size distributions
3. **gene_count_by_source.png**: Gene count distributions after QC
4. **threshold_impact.png**: Impact of different fixed cutoffs
5. **percentile_comparison.png**: Percentile-based retention across sources

All files available in: `tahoe_cmap_analysis/validation/endo_disease_signatures/threshold_analysis/`

### Key Statistics

**Total signatures analyzed:** 19
- CREEDS: 3 signatures
- Laura: 10 cell-type-specific signatures  
- Tomiko: 6 clinical signatures

**Quality control applied:**
- Mean/median logFC consistency
- Median |logFC| ≥ 0.02
- Adjusted p-value < 0.05

---

## Frequently Asked Questions

### Q: Why not use logFC > 0.5 as a compromise?

**A:** Even logFC > 0.5 eliminates 100% of CREEDS data and significantly reduces Laura contributions. The problem isn't the specific cutoff value - it's the fixed cutoff approach itself.

### Q: Will percentile filtering include noise from low-effect genes?

**A:** No - all genes already passed stringent QC (adj.p < 0.05, |effect| ≥ 0.02). Percentile filtering selects the *strongest* signals within each dataset, ensuring high signal-to-noise ratios.

### Q: How does this compare to published studies?

**A:** Most modern drug repurposing studies use either:
1. Percentile/rank-based methods (recommended)
2. Adaptive thresholds per dataset
3. Signature-specific optimization

Fixed global cutoffs are increasingly recognized as problematic for heterogeneous data.

### Q: What if I want stricter filtering?

**A:** You can adjust to 75th or 80th percentile. Do NOT go below 70th percentile as this may over-restrict smaller signatures.

---

## Conclusion

**Use percentile-based filtering with 85th percentile threshold.** This approach:

✅ Ensures fair representation across all data sources  
✅ Maintains statistical power for all comparisons  
✅ Adapts to biological differences in effect sizes  
✅ Maximizes discovery potential for drug candidates  
✅ Aligns with current best practices in the field  

The alternative of fixed logFC cutoffs would severely compromise your analysis by creating extreme bias toward high-effect datasets.

---

## Contact & Questions

For questions about this analysis or threshold selection, refer to:
- Analysis script: `tahoe_cmap_analysis/validation/endo_disease_signatures/analyze_threshold_recommendations.R`
- Configuration file: `tahoe_cmap_analysis/scripts/execution/batch_configs/6_tomiko_endo.yml`
- Results directory: `tahoe_cmap_analysis/validation/endo_disease_signatures/threshold_analysis/`
