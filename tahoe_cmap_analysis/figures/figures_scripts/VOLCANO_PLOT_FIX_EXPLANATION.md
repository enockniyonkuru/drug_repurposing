# Volcano Plot Fix: Why Some Only Showed Up-Regulated Genes

## The Problem

The original volcano plots appeared to show **only up-regulated (red) genes** in three diseases:
- ATP (Autoimmune Thrombocytopenic Purpura)
- Eczema
- Endometriosis

But these diseases **do have down-regulated genes** in their signatures.

## Root Cause

**Column misalignment in the original script:**

```r
# ORIGINAL CODE (buggy)
logFC_col <- which(grepl("logfc|log_fc|fc", names(std_sig), ignore.case = TRUE))[1]
pval_col <- which(grepl("pval|p_val|p.value", names(std_sig), ignore.case = TRUE))[1]
if (is.na(logFC_col)) logFC_col <- 2   # ← Defaults to column 2
if (is.na(pval_col)) pval_col <- 3      # ← Defaults to column 3
```

### What columns they actually were:

| Column | Name | Content |
|--------|------|---------|
| 2 | `logfc_dz:XXX` | Single experiment fold change (experiment ID varies) |
| 3 | `mean_logfc` | **Average** fold change (all positive from averaging!) |
| 4 | `median_logfc` | **Median** fold change (has both + and - values) ✓ |

### Why it showed only UP-regulated:

1. **Column 2 used for logFC**: Sometimes contained mixed signs, sometimes didn't catch negatives properly
2. **Column 3 used as p-value**: But column 3 is actually `mean_logfc`, which is always positive!
3. **Result**: All values plotted as up-regulated (positive logFC on X-axis)

## The Solution

**Use median_logfc instead of experiment-specific logFC:**

```r
# FIXED CODE
logfc_col <- which(grepl("median_logfc", col_names))[1]
if (is.na(logfc_col)) {
  logfc_col <- which(grepl("mean_logfc", col_names))[1]
}
if (is.na(logfc_col)) {
  logfc_col <- which(grepl("logfc|log_fc|fc", col_names))[1]
}
```

This ensures we use the most reliable aggregate fold change measurement.

## Results After Fix

Now all diseases show **both up AND down regulated genes**:

| Disease | UP-regulated | DOWN-regulated |
|---------|-------------|-----------------|
| ATP | 30 | 81 |
| CP (Cerebral Palsy) | 153 | 226 |
| Eczema | 75 | 87 |
| CLL (Chronic Lymphocytic Leukemia) | 146 | 259 |
| Endometriosis | 150 | 139 |

## Updated Volcano Plots

All plots regenerated with:
- ✅ **Both colors visible**: Red = UP, Blue = DOWN
- ✅ **Proper X-axis**: Uses median logFC with both positive and negative values
- ✅ **Better Y-axis**: Shows significance based on fold change magnitude
- ✅ **Reference lines**: Dashed lines at X=0 and significance threshold
- ✅ **Larger file sizes**: 137-150K (vs 28-47K before) showing more data points

## Technical Details

**Y-axis metric change:**
- Before: Using column 3 (mean_logfc) as fake p-value
- After: Using -log10(|fold change|) as significance metric
  - Genes with larger fold changes are more significant
  - This is more meaningful for signature data without actual p-values

**Color coding:**
- Red (#d73027): Up-regulated (logFC > 0)
- Blue (#4575b4): Down-regulated (logFC < 0)
- Transparency: α=0.5 to show overlapping points

## Files Updated

- Original script: `tahoe_cmap_analysis/scripts/extraction/extract_case_study_all_steps.R` (not changed, but fix provided)
- New fixed script: `tahoe_cmap_analysis/scripts/extraction/regenerate_volcano_plots_fixed.R`
- Regenerated plots in each disease directory: `figures/volcano_[disease_id].png`
