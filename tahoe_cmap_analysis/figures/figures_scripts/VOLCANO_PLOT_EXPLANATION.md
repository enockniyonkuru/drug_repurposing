# Volcano Plot Explanation

## How These Charts Were Made

The volcano plots were created by the `extract_case_study_all_steps.R` script using the R `ggplot2` package.

### Source Code (from `tahoe_cmap_analysis/scripts/extraction/extract_case_study_all_steps.R`)

```r
create_volcano_plot <- function(std_sig, output_path) {
  if (ncol(std_sig) < 3) return(FALSE)
  
  # Auto-detect column names
  logFC_col <- which(grepl("logfc|log_fc|fc", names(std_sig), ignore.case = TRUE))[1]
  pval_col <- which(grepl("pval|p_val|p.value", names(std_sig), ignore.case = TRUE))[1]
  
  # Default to columns 2 and 3 if not found
  if (is.na(logFC_col)) logFC_col <- 2
  if (is.na(pval_col)) pval_col <- 3
  
  # Prepare data
  df <- data.frame(
    logFC = std_sig[[logFC_col]],
    pval = std_sig[[pval_col]]
  ) %>%
    mutate(
      neg_log_pval = -log10(pval + 1e-300),    # Transform p-value to -log10 scale
      direction = ifelse(logFC > 0, "up", "down")  # Classify direction
    ) %>%
    filter(is.finite(neg_log_pval) & is.finite(logFC))
  
  # Create visualization
  p <- ggplot(df, aes(x = logFC, y = neg_log_pval, color = direction)) +
    geom_point(alpha = 0.6, size = 2) +
    scale_color_manual(values = c("up" = "#d73027", "down" = "#4575b4")) +
    theme_minimal() + 
    labs(x = "Log Fold Change", y = "-Log10(P-value)", title = "Volcano Plot")
  
  ggsave(output_path, p, width = 8, height = 6, dpi = 300)
  return(TRUE)
}
```

### Input Data

The plots use **standardized disease signatures** from:
- **ATP**: `tahoe_cmap_analysis/data/disease_signatures/case_study/autoimmune_thrombocytopenic_purpura_signature.csv`
- **CLL**: `tahoe_cmap_analysis/data/disease_signatures/case_study/chronic_lymphocytic_leukemia_signature.csv`

These files contain:
- **gene_symbol**: Gene names (HGNC symbols)
- **logfc_* columns**: Log fold change values from different experiments
- **mean_logfc**: Average log fold change across experiments (typically used for X-axis)
- **median_logfc**: Median log fold change

### Processing Steps

1. **Load standardized signature** file (contains genes with fold change values)
2. **Extract columns**:
   - X-axis: Log fold change (logFC) - measures how much each gene is up/down regulated
   - Y-axis: P-value - transformed to -log10(p-value) for visibility
3. **Calculate direction**: Classify genes as "up-regulated" (logFC > 0, red) or "down-regulated" (logFC < 0, blue)
4. **Remove invalid values**: Filter out infinite or NaN values (from very small p-values)
5. **Create scatter plot** with color-coded points

---

## What Information They Carry

### The Volcano Plot Structure

```
     Y-axis: -log10(p-value)
     ↑
     | Low p-value (high significance)
     | [Red dots = up-regulated genes]
     | [Blue dots = down-regulated genes]
     |
     | Medium significance
     |
     | High p-value (low significance)
     └─────────────────────────→ X-axis: Log Fold Change
         Negative (down-reg)    0    Positive (up-reg)
```

### Information Each Axis Carries

| Axis | Meaning | What It Shows |
|------|---------|---------------|
| **X-axis: Log Fold Change** | Magnitude & direction of gene expression change | How much the gene is over-expressed (positive) or under-expressed (negative) in disease vs control |
| **Y-axis: -log10(p-value)** | Statistical significance of the change | How confident we are that the change is real (not random noise). Higher = more significant |

### Important Regions

1. **Upper Right (Red dots)**: 
   - Genes strongly UP-regulated in disease
   - High fold change + statistically significant
   - Likely disease-relevant genes

2. **Upper Left (Blue dots)**:
   - Genes strongly DOWN-regulated in disease
   - Low fold change + statistically significant
   - Also likely disease-relevant

3. **Middle (Both colors)**:
   - Genes with moderate changes or weak significance
   - Less convincing evidence of involvement

4. **Bottom (Both colors)**:
   - Genes with weak changes or not statistically significant
   - Possibly noise or random variation

### For Your Specific Charts

**ATP (Autoimmune Thrombocytopenic Purpura):**
- Shows genes dysregulated in blood platelet disorder
- Red dots = genes overexpressed in ATP patients
- Blue dots = genes suppressed in ATP patients

**CLL (Chronic Lymphocytic Leukemia):**
- Shows genes dysregulated in B-cell lymphoma
- Red dots = genes overexpressed in CLL cancer cells
- Blue dots = genes suppressed in CLL cancer cells

---

## Suggested Titles

### Option 1: Descriptive & Scientific
**"Volcano Plot of Gene Expression Changes in [Disease]"**
- Generic but clear
- Shows genes significantly altered in disease

### Option 2: Mechanism-Focused
**"Dysregulated Genes in [Disease]: Log Fold Change vs Statistical Significance"**
- Emphasizes the biological disruption
- Explains both axes in the title

### Option 3: Outcome-Focused
**"Identification of Disease-Associated Gene Expression Changes in [Disease]"**
- Highlights discovery purpose
- Suitable for research papers

### Option 4: Disease-Specific (Recommended)

**For ATP:**
- **"Gene Expression Dysregulation in Autoimmune Thrombocytopenic Purpura"**
- or **"Platelet Disorder Signature: Dysregulated Gene Expression in ATP"**

**For CLL:**
- **"Gene Expression Signature of Chronic Lymphocytic Leukemia"**
- or **"B-Cell Lymphoma Signature: Dysregulated Genes in CLL"**

### Option 5: Simple & Direct (Best for Presentations)
**"[Disease Name] Gene Expression Volcano Plot"**

**For ATP:** `"ATP Gene Expression Volcano Plot"`
**For CLL:** `"CLL Gene Expression Volcano Plot"`

---

## Technical Details

- **File Format**: PNG (300 dpi, 8×6 inches)
- **Color Scheme**: 
  - Red (#d73027): Up-regulated genes
  - Blue (#4575b4): Down-regulated genes
- **Theme**: Minimal (clean, publication-ready)
- **Alpha (transparency)**: 0.6 (allows overlapping points visibility)
- **Point Size**: 2 (standard for scatter plots)

---

## Interpretation Example

If you see a gene at coordinates:
- X = 1.5, Y = 10
  - → This gene has ~1.5 fold change (up-regulated)
  - → With p-value of 10^-10 (extremely significant)
  - → Strong evidence this gene matters in the disease

If you see a gene at coordinates:
- X = 0.2, Y = 2
  - → This gene has only 0.2 fold change
  - → With p-value of 0.01 (weakly significant)
  - → Weak evidence, possibly noise
