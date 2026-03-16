# Chart 5: Quick Start Guide for MOA Visualization

## TL;DR - Quick Execution

```bash
cd /path/to/drug_repurposing
Rscript tahoe_cmap_analysis/scripts/visualization/create_moa_visualization_chart5.R
```

This generates:
- 3 publication-ready PDF plots
- 2 CSV summary tables
- Console output with statistical summaries

---

## What This Creates

### Three Complementary Visualizations:

1. **Bar Plot** (`chart5_moa_barplot_*.pdf`)
   - Shows which drug mechanisms are most common
   - Best for: Identifying dominant therapeutic strategies

2. **Dot Plot** (`chart5_moa_dotplot_*.pdf`) 
   - Shows which mechanisms are shared vs pipeline-specific
   - Best for: Understanding TAHOE vs CMAP agreement
   - Color: Green=TAHOE only, Orange=CMAP only, Purple=Both

3. **Heatmap** (`chart5_moa_heatmap_*.pdf`)
   - Shows contingency table of MOA × Pipeline
   - Best for: Quick reference and supplementary material

### Two Data Tables:

1. **Summary Statistics** (`chart5_moa_summary_*.csv`)
   - Counts by MOA class and pipeline
   - Percentages of shared/unique drugs

2. **Detailed Mapping** (`chart5_drug_moa_mapping_*.csv`)
   - Each drug with its MOA and classification
   - Ready for supplementary table in manuscript

---

## Customizing for Your Disease

### Option 1: Change Disease (Easiest)

Edit this line in the R script:
```r
# Line ~125: Change from disease_idx <- 1 to select different disease
disease_idx <- 1  # 1 = first disease in file (urticaria)
              # 2 = second disease (intellectual disability)
              # etc.
```

Then run the script and all outputs update automatically.

### Option 2: Use Top N Different Drugs

Edit this line:
```r
# Line ~135: Change number of top drugs to visualize
n_top <- 20  # Increase to 30 or 50 for more detail
         # Decrease to 10 for simpler visualization
```

### Option 3: Expand MOA Database

Add your drug-mechanism pairs to the `moa_database` tribble (lines ~20-90):

```r
moa_database <- tribble(
  ~drug_name, ~mechanism_of_action, ~mechanism_class,
  # ... existing entries ...
  "your_drug_name", "your mechanism description", "Your MOA Class",
)
```

Common MOA classes to use:
- Kinase Inhibitor
- Chemotherapy
- Hormone Therapy
- Immunotherapy
- Anti-inflammatory
- Epigenetic Modifier
- DNA Repair Inhibitor
- etc.

---

## Interpreting the Output

### Key Signal #1: Shared Mechanisms (Purple in Dot Plot)

If you see a large purple bubble on the dot plot, it means:
- ✓ **High confidence** - Both pipelines identified drugs with this MOA
- ✓ **Likely pathway involvement** - Mechanism probably dysregulated in disease
- ✓ **Robust finding** - Not unique to one signature database

**Example**: If both TAHOE and CMAP identify multiple JAK inhibitors for urticaria
→ Strong evidence that JAK/STAT pathway is a therapeutic target

### Key Signal #2: MOA Dominance (Tall Bars in Bar Plot)

If one MOA class has many drugs:
- ✓ **Multiple druggable entry points** - Flexibility in drug choice
- ✓ **Well-validated pathway** - Likely indicates real biology
- ⚠ **Possible bias** - May reflect database bias toward that class

**Example**: If kinase inhibitors dominate all diseases
→ Consider whether real or due to CMap/TAHOE focus on kinases

### Key Signal #3: Pipeline Disagreement (Different Colors in Dot Plot)

If TAHOE and CMAP identify different MOA classes:
- ⚠ **Possible differential coverage** - Databases emphasize different mechanisms
- ⚠ **Potential false positives** - One pipeline may have false hit
- ✓ **Opportunity for validation** - Can test which mechanism is real

---

## Data Quality Checks

### Before Interpretation:

1. **Check Drug Count**
   - Console output shows: "Top X drugs selected for visualization"
   - Expect: Usually 15-25 drugs with identified MOA
   - If many "Unknown": MOA database is incomplete for this disease

2. **Check Pipeline Agreement**
   - Look at the "Both" count in summary table
   - Expect: 10-30% of drugs should be in both pipelines
   - If <5%: Pipelines strongly disagree (investigate)
   - If >50%: Pipelines very similar (less discriminative)

3. **Check MOA Diversity**
   - Count distinct MOA classes in summary
   - Expect: 4-10 different mechanism classes
   - If <3: Mechanistically convergent (strong signal)
   - If >15: Very diverse (may include many unknowns)

---

## Publication-Ready Output

All PDF files are formatted for publication:
- High resolution (300 DPI when printed)
- Publication-standard fonts and sizes
- Suitable for main figures or supplementary material
- Can be imported into Illustrator for minor tweaks

### To Use in Manuscript:

**For Main Figure**: Use dot plot
- Shows mechanism diversity and pipeline agreement simultaneously
- Most informative single visualization

**For Supplement**: Use all three
- Bar plot: Simple mechanism overview
- Heatmap: Contingency reference
- Tables: Detailed supporting data

### Suggested Caption Example:

> **Chart 5: Mechanism of Action Landscape**
> The top 20 drug candidates for [disease] predicted by TAHOE and CMAP pipelines (q < 0.05) cluster into [N] distinct mechanism of action (MOA) classes. Shared mechanisms (purple dots) include [list main ones], suggesting robust pathway involvement. TAHOE-specific mechanisms (green) include [examples], while CMAP-specific (orange) include [examples]. Mechanisms span [categories], providing multiple therapeutic entry points.

---

## Troubleshooting

### Issue: "Unknown/Unspecified" Dominates Output
**Cause**: MOA database incomplete for this disease's drugs
**Fix 1**: Add more drug-MOA pairs to `moa_database`
**Fix 2**: Query Open Targets API programmatically (see advanced section)
**Fix 3**: Use your own drug annotation system

### Issue: Script Shows "Error: Unexpected Symbol"
**Cause**: Likely YAML parsing error in drug hits
**Fix**: Check that disease row contains properly formatted Python lists
```r
# Test if parsing works:
test_list <- eval(parse(text = disease_row$tahoe_hits_list))
```

### Issue: Output Files Not in Expected Location
**Cause**: Working directory may be different
**Fix**: Run script with full paths
```bash
Rscript /full/path/to/create_moa_visualization_chart5.R
```

### Issue: Visualization Looks Cluttered (Too Many MOA Classes)
**Fix**: Reduce number of drugs
```r
n_top <- 10  # Instead of 20
```

---

## Advanced: Programmatic MOA Lookup

Instead of manual database, query Open Targets API:

```r
# Requires: devtools::install_github("opentargets/otapi")
library(otapi)

# For each drug in hits, query:
get_drug_info <- function(drug_name) {
  result <- ot.getTarget(q = drug_name)
  return(result$mechanismOfAction)
}

# Apply to all drugs:
moa_automatic <- sapply(top_drugs, get_drug_info)
```

This ensures you have the most current MOA information.

---

## Common MOA Classes Reference

When expanding the MOA database, use these standard categories:

| Category | Examples | Common in |
|----------|----------|-----------|
| **Kinase Inhibitor** | EGFR, JAK, MEK inhibitors | Most cancers, autoimmune |
| **Chemotherapy** | Topoisomerase inhibitors, antimetabolites | Solid tumors, hematologic |
| **Hormone Therapy** | Aromatase inhibitors, AR antagonists | Breast, prostate |
| **Immunotherapy** | Checkpoint inhibitors, TLR agonists | Cancers, immune diseases |
| **Anti-inflammatory** | NSAIDs, corticosteroids | Inflammatory conditions |
| **DNA Repair** | PARP inhibitors | DNA damage-dependent cancers |
| **Epigenetic Modifier** | HDAC inhibitors, DNA methyltransferase inhibitors | Various cancers |
| **Cardiovascular** | Beta blockers, ACE inhibitors | Hypertension, heart disease |
| **Neurological** | Dopamine agonists, MAO inhibitors | Parkinson's, depression |
| **Photosensitizer** | Verteporfin, porfirins | Photodynamic therapy |
| **Other** | Antibiotics, antivirals, antihistamines | Infectious, allergic |

---

## Files Generated Summary

```
tahoe_cmap_analysis/figures/
├── chart5_moa_barplot_[disease].pdf          ← Main mechanism distribution
├── chart5_moa_dotplot_[disease].pdf          ← Pipeline overlap (best for publication)
├── chart5_moa_heatmap_[disease].pdf          ← Contingency table
├── chart5_moa_summary_[disease].csv          ← Summary statistics
└── chart5_drug_moa_mapping_[disease].csv     ← Detailed data table
```

All files are ready for:
- Direct inclusion in manuscripts
- Upload to supplementary materials
- Further analysis or visualization
- Data repository submission

---

## Next Steps

After generating Chart 5:

1. **Validate MOA Predictions**
   - Search PubMed for "[disease] + [top mechanism]"
   - Check clinical trials for similar MOAs
   - Review mechanistic literature

2. **Integrate with Other Charts**
   - Combine with Chart 3 (precision/recall) to show quality
   - Show mechanism diversity alongside performance metrics
   - Link top mechanisms to known pathways

3. **Plan Experiments**
   - Use MOA distribution to guide validation studies
   - Prioritize shared mechanisms for functional testing
   - Design mechanistic assays based on predicted targets

4. **Compare Across Diseases**
   - Run Chart 5 for multiple diseases
   - Identify common mechanisms across conditions
   - Find disease-specific vs universal mechanisms

---

**Last Updated**: 2024-12-05  
**Questions?** See full documentation in `CHART5_MOA_DOCUMENTATION.md`
