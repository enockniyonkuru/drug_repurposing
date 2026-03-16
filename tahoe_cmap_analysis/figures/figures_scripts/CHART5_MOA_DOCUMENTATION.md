# Chart 5: Small Molecular Mechanism Map (MOA Analysis)

## Overview
Chart 5 presents a visual analysis of the mechanism of action (MOA) landscape for the top drug hits from the exp 8 case study (urticaria). This chart answers critical questions about the molecular targets and mechanisms represented in the drug repurposing results.

## Key Questions Addressed

1. **What are the primary mechanisms of action among our predicted drugs?**
   - Shows the distribution of drug classes (kinase inhibitors, chemotherapy, etc.)

2. **Which mechanisms are shared across both TAHOE and CMAP pipelines?**
   - Identifies convergence on specific mechanisms as a sign of robustness
   - Highlights unique mechanisms from each pipeline

3. **Are our predictions mechanistically diverse or convergent?**
   - Multiple diverse mechanisms suggest broad therapeutic opportunities
   - Convergence on specific pathways suggests strong target validation

## Visualization Components

### 1. **Bar Plot: MOA Class Distribution**
- **X-axis**: Mechanism of Action Classes (sorted by frequency)
- **Y-axis**: Count of drugs in each MOA class
- **Interpretation**: 
  - Identifies the most common mechanisms among top hits
  - Shows relative representation of different drug classes
  - Helps identify dominant therapeutic strategies

### 2. **Dot Plot: Pipeline-Specific MOA Overlap**
- **X-axis**: Mechanism of Action Classes
- **Y-axis**: Number of drugs
- **Color**: Pipeline classification
  - Green (TAHOE): Mechanism appears primarily in TAHOE predictions
  - Orange (CMAP): Mechanism appears primarily in CMAP predictions
  - Purple (Both): Mechanism appears in both pipelines
- **Bubble Size**: Reflects the count (larger bubbles = more drugs)
- **Interpretation**:
  - Purple bubbles indicate robust mechanism identification
  - Asymmetric coloring reveals pipeline-specific insights
  - Shared mechanisms (purple) are high-confidence targets

### 3. **Heatmap: MOA × Pipeline Contingency**
- **Rows**: Mechanism of Action classes (sorted by total count)
- **Columns**: Pipeline source (TAHOE, CMAP, Both)
- **Cell Values**: Number of drugs in each combination
- **Color Gradient**: White (0) → Dark blue (maximum count)
- **Interpretation**:
  - Quick visual of the contingency table
  - Shows which pipelines prioritize which mechanisms
  - Darker columns indicate mechanism concentration

## Mechanism of Action Classes

### Major Categories Included:

**Kinase Inhibitors** (Most Common)
- EGFR, ALK, BCR-ABL, MEK, BRAF, KRAS, JAK, etc.
- Well-established druggable targets
- Rationale: Directly modulate dysregulated signaling in disease

**DNA Repair & Cell Cycle**
- PARP inhibitors, CDK4/6 inhibitors
- Target genomic instability pathways
- Particularly relevant in certain cancers

**Immune Modulators**
- JAK inhibitors, TLR agonists
- Target immune dysregulation
- Rationale: May reverse immunological imbalance in urticaria

**Hormone Therapy**
- Aromatase inhibitors, androgen receptor antagonists
- Target hormone-dependent pathways

**Chemotherapy Agents**
- Topoisomerase inhibitors, microtubule stabilizers, antimetabolites
- Broad mechanism: DNA damage, cell cycle arrest
- May reverse disease through cytotoxic effects

**Epigenetic Modifiers**
- HDAC inhibitors (vorinostat, belinostat, etc.)
- Target gene expression dysregulation
- Increasingly recognized as important for immune diseases

**Anti-inflammatory & Supportive**
- NSAIDs, anesthetics, photosensitizers
- Symptomatic relief and mechanism-agnostic approaches

## Data Source

### MOA Information Derived From:
1. **Open Targets Platform** - Primary drug target and mechanism data
2. **ChEMBL Database** - Chemical and pharmacological properties
3. **DrugBank** - Comprehensive drug information including mechanisms
4. **Literature** - Published drug development and clinical data

### Drug Filtering:
- **Q-value threshold**: < 0.05 (FDR-corrected significance)
- **Top N drugs visualized**: 20 (balances comprehensiveness with clarity)
- **Pipeline coverage**: Includes TAHOE-only, CMAP-only, and shared hits

## Interpretation Guidance

### Strong Signals (Confidence Indicators):

1. **Shared Mechanisms (Purple Bubbles)**
   - When both pipelines identify drugs with the same MOA
   - Suggests robust pathway involvement in disease
   - **Example**: If both TAHOE and CMAP identify multiple JAK inhibitors
     → Strong evidence that JAK signaling is dysregulated in urticaria

2. **High Mechanism Frequency**
   - MOA classes with many drugs
   - Indicates multiple druggable entry points into a pathway
   - Provides redundancy and treatment flexibility

3. **Novel/Unexpected Mechanisms**
   - Mechanisms not typically associated with the disease
   - May represent new biological insights
   - Suggests potential for true drug repurposing discovery

### Weaker Signals (Caution):

1. **Pipeline Disagreement**
   - Different MOAs predicted by TAHOE vs CMAP
   - May reflect differences in drug signature databases
   - Requires experimental validation

2. **Single-Drug Mechanisms**
   - Only one drug represents a particular MOA
   - Less robust than convergent mechanisms
   - May be false positive or context-specific

3. **Unknown/Unspecified MOA**
   - Drugs lacking mechanistic annotation
   - Limits biological interpretation
   - Consider literature search for additional information

## Case Study Example: Urticaria (Chart 5a)

For urticaria, expected key mechanisms:
- **JAK/STAT inhibitors** - Control immune-mediated mast cell activation
- **PDE4/PDE5 inhibitors** - Anti-inflammatory and mast cell stabilization
- **Mast cell stabilizers** - Direct antihistamine/anti-allergic effects
- **Kinase inhibitors** - Various (often off-target but contributing to efficacy)
- **Corticosteroids** - Standard-of-care anti-inflammatory approach

**Expected Pattern**: Mix of immune-focused mechanisms (JAK/STAT) with broad anti-inflammatory agents, reflecting the condition's complex immunopathology.

## How to Use This Chart

### For Clinicians:
1. Verify predicted MOAs against known disease biology
2. Identify if mechanisms align with current standard-of-care
3. Assess novelty of proposed mechanisms

### For Researchers:
1. Prioritize mechanisms for experimental validation
2. Identify convergent targets across pipelines
3. Design mechanistic studies based on MOA predictions

### For Drug Development:
1. Assess patent landscape and clinical precedent
2. Prioritize drugs with proven safety profiles in MOA class
3. Design biomarker strategies around identified mechanisms

## Limitations & Considerations

1. **MOA Database Completeness**
   - Not all drugs have complete mechanistic annotations
   - "Unknown" classification doesn't mean non-functional
   - Recommend literature supplementation

2. **Pleiotropy**
   - Many drugs have multiple MOAs
   - Visualization shows primary mechanism only
   - Check detailed drug-MOA mapping table for full profiles

3. **Off-target Effects**
   - Drugs may exert effects through unintended targets
   - High-dose effects may differ from therapeutic doses
   - Context-dependent activity not fully captured

4. **Pipeline-Specific Biases**
   - TAHOE and CMAP use different drug signature sources
   - May preferentially capture certain MOA classes
   - Affects apparent mechanism distribution

## Related Outputs

1. **Detailed Drug-MOA Table** (`chart5_drug_moa_mapping_*.csv`)
   - Complete list of each drug and its assigned mechanism(s)
   - Pipeline classification for each drug
   - Ready for further analysis or supplementary material

2. **Summary Statistics** (`chart5_moa_summary_*.csv`)
   - Counts and percentages for each MOA class
   - Pipeline overlap statistics
   - Quick reference for manuscript/presentation

3. **Visual Outputs**
   - Bar plot: MOA distribution (publication-ready)
   - Dot plot: Pipeline overlap (shows nuance)
   - Heatmap: Contingency table (summary view)

## Script Location & Execution

**Script**: `tahoe_cmap_analysis/scripts/visualization/create_moa_visualization_chart5.R`

**Usage**:
```bash
# From terminal
cd /path/to/drug_repurposing
Rscript tahoe_cmap_analysis/scripts/visualization/create_moa_visualization_chart5.R

# From R/RStudio
setwd("/path/to/drug_repurposing")
source("tahoe_cmap_analysis/scripts/visualization/create_moa_visualization_chart5.R")
```

**Output Directory**: `tahoe_cmap_analysis/figures/`

**Generated Files**:
- `chart5_moa_barplot_[disease_name].pdf` - Main bar plot
- `chart5_moa_dotplot_[disease_name].pdf` - Pipeline overlap visualization
- `chart5_moa_heatmap_[disease_name].pdf` - Contingency heatmap
- `chart5_moa_summary_[disease_name].csv` - Summary statistics
- `chart5_drug_moa_mapping_[disease_name].csv` - Detailed drug-MOA table

## Next Steps

### To Customize for Different Diseases:
1. Modify `disease_idx` variable in script
2. Adjust `n_top` to change number of drugs visualized
3. Expand MOA database with additional drug-mechanism mappings
4. Add disease-specific background mechanism knowledge

### To Integrate with Open Targets:
```r
# Replace manual MOA database with API queries:
# 1. Use ottargets R package to query Open Targets API
# 2. Retrieve mechanismOfAction field for each drug
# 3. Parse JSON response for structured MOA information
# 4. Merge with drug prediction results
```

### To Add Statistical Testing:
- Chi-square test for pipeline-MOA independence
- Fisher's exact test for 2×2 contingency tables
- Multiple testing correction for MOA comparisons

## Citation & References

For detailed information about Open Targets mechanism of action classifications, see:
- https://platform.opentargets.org/
- Carvalho-Silva et al. (2023) Open Targets Platform: new developments and updates

---

**Chart 5 Version**: 1.0  
**Last Updated**: 2024  
**Corresponding Author**: See main project README
