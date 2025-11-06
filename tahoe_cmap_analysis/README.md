# TAHOE-CMAP Analysis Directory

## IMPORTANT: UNDER DEVELOPMENT - NOT FOR PRODUCTION USE

**This directory contains experimental work that is still under active development and validation.**

### Current Status
- **TAHOE integration is NOT fully complete**
- **Analysis tools are being validated**
- **Results should be considered preliminary**
- **Workflows are subject to change**

### For Production Drug Repurposing Analysis
**Please use the main DRpipe package and Shiny app instead:**
- See main repository [README.md](../README.md) for instructions
- Use DRpipe R package (Section 6)
- Use Shiny app (Section 7)
- Both are fully functional and validated for CMAP-based analyses

---

## About This Directory

This directory contains experimental analysis comparing CMAP and TAHOE drug signature databases for drug repurposing across 58 disease signatures. The work is part of ongoing research to evaluate and integrate TAHOE as an alternative/complementary drug signature database.

### Preliminary Findings

This analysis systematically evaluated two computational drug repurposing methods (CMAP and TAHOE) to identify potential therapeutic candidates for 58 diseases. The preliminary study identified **6,161 total drug-disease associations** with **33 high-confidence drugs** validated by both methods.

**Note:** These findings are preliminary and subject to further validation.

## Directory Structure

```
tahoe_cmap_analysis/
├── README.md                           # This file
├── COMPREHENSIVE_STUDY_REPORT.md       # Detailed analysis report
├── COMPREHENSIVE_STUDY_REPORT.html     # HTML version of report
├── data/                               # Compiled analysis results
├── results/                            # Filtered results by q-value threshold
├── results_1/                          # Raw pipeline outputs
└── scripts/                            # Analysis and processing scripts
```

## Main Files

### Reports
- **`COMPREHENSIVE_STUDY_REPORT.md`** - Complete study documentation including:
  - Executive summary and key findings
  - Methodology and pipeline details
  - Full dataset and shared drug subset analyses
  - Method comparison and recommendations
  - Disease-specific insights
  
- **`COMPREHENSIVE_STUDY_REPORT.html`** - Same content as above in HTML format for easier viewing in browsers

## Data Directory (`data/`)

Contains compiled summary files and drug-disease association data:

### Full Dataset Analysis (All Drugs)
Files analyzing all drugs from CMAP (1,309 drugs) and TAHOE (379 drugs):

- **`all_drug_hits_compiled.csv`** - Complete list of all drug hits across all diseases
- **`drug_hits_summary.csv`** - Summary statistics per disease
- **`full_summary_with_total_row.csv`** - Count summary with totals (CMAP hits, TAHOE hits, shared drugs, evidence rates)
- **`full_summary_drug_sets_by_disease.csv`** - Detailed drug lists per disease per method
- **`full_annotated_hits_with_open_targets.csv`** - All drug hits annotated with Open Targets evidence
- **`drug_disease_combined.json`** - Dictionary-like structure of disease → drug → evidence mappings

### Shared Drug Subset Analysis (61 Common Drugs)
Files analyzing only the 61 drugs present in BOTH databases:

- **`shared_drugs_cmap_tahoe.csv`** - List of the 61 drugs common to both databases
- **`all_drug_hits_compiled_shared_only.csv`** - Drug hits from shared drugs only
- **`drug_hits_summary_shared_only.csv`** - Summary statistics for shared drug analysis
- **`shared_summary_with_total_row.csv`** - Count summary for shared drugs
- **`shared_summary_drug_sets_by_disease.csv`** - Drug lists per disease (shared drugs only)
- **`shared_annotated_hits_with_open_targets.csv`** - Shared drug hits with evidence annotations
- **`drug_disease_combined_shared.json`** - Dictionary structure for shared drug analysis

### Key Differences Between Full and Shared Analyses

**Full Dataset**: 
- Uses complete drug libraries (CMAP: 1,309 drugs, TAHOE: 379 drugs)
- Maximizes discovery potential
- Shows method-specific strengths
- ~60% novel predictions without prior evidence

**Shared Subset**: 
- Uses only 61 drugs present in both databases
- Enables direct method-to-method comparison
- 100% validation rate for consensus predictions (33 drugs)
- Demonstrates method reliability

## Results Directory (`results/`)

Contains filtered analysis results at different q-value thresholds:

### Subdirectories
- **`filtered_q0p05/`** - Highly stringent filtering (q-value < 0.05)
- **`filtered_q0p1/`** - Moderate filtering (q-value < 0.1)
- **`filtered_q0p5/`** - Lenient filtering (q-value < 0.5)

### Files in Each Threshold Directory

**Full Dataset Files:**
- `full_annotated_hits_with_open_targets.csv` - Filtered drug hits with evidence
- `full_summary_drug_sets_by_disease.csv` - Drug lists per disease
- `full_summary_with_total_row.csv` - Count summaries
- `full_summary_hits_vs_evidence_by_disease.csv` - Evidence validation statistics

**Shared Dataset Files** (only in `filtered_q0p5/`):
- `shared_annotated_hits_with_open_targets.csv`
- `shared_summary_drug_sets_by_disease.csv`
- `shared_summary_with_total_row.csv`
- `shared_summary_hits_vs_evidence_by_disease.csv`

### Understanding Q-value Filtering

- **Q-value**: False Discovery Rate (FDR)-corrected p-value
- **Lower q-value** = Higher confidence, fewer false positives
- **Higher q-value** = More discoveries, potentially more false positives
- **Recommendation**: Start with q < 0.1 for balanced sensitivity/specificity

## Results_1 Directory (`results_1/`)

Contains raw pipeline outputs from all 116 analysis runs (58 diseases × 2 methods):

### Structure
```
results_1/
├── batch_run_log_20251027-015445.txt          # Execution log
├── batch_run_summary_20251027-015445.csv      # Run summary statistics
└── [Disease]_[Method]_[Timestamp]/            # Individual disease-method results
    ├── file*_hits_q<1.00.csv                  # Drug hits (unfiltered)
    ├── file*_results.RData                    # R workspace with full results
    ├── file*_random_scores_logFC_0.RData      # Null distribution data
    └── img/                                   # Visualization plots
        ├── heatmap_*.png
        ├── histogram_*.png
        └── upset_*.png
```

### Disease-Method Result Folders

Each folder name follows the pattern: `[Disease]_[CMAP|TAHOE]_[Timestamp]`

**Examples:**
- `Alzheimer's_disease_CMAP_20251027-015445/`
- `Breast_cancer_TAHOE_20251027-015445/`
- `CoreFibroidSignature_sirota_lab_CMAP_20251027-015445/`

### Files in Each Result Folder

1. **`file*_hits_q<1.00.csv`** - Drug hits with connectivity scores
   - Columns: drug name, connectivity score, p-value, q-value, etc.
   - Unfiltered (q < 1.00 means all results included)
   
2. **`file*_results.RData`** - Complete R workspace
   - Contains all analysis objects
   - Can be loaded in R for further analysis
   
3. **`file*_random_scores_logFC_0.RData`** - Null distribution
   - Permutation test results (100,000 iterations)
   - Used for p-value calculation
   
4. **`img/`** - Visualization plots
   - Heatmaps showing drug-disease relationships
   - Histograms of connectivity score distributions
   - UpSet plots showing gene set overlaps

### Batch Run Files

- **`batch_run_log_20251027-015445.txt`** - Detailed execution log
  - Timestamps for each run
  - Success/failure status
  - Error messages if any
  
- **`batch_run_summary_20251027-015445.csv`** - Summary statistics
  - Number of hits per disease-method combination
  - Execution times
  - Quality metrics

## Scripts Directory (`scripts/`)

Contains Python and R scripts for data processing and analysis:

### Python Scripts

1. **`compile_drug_hits.py`** - Compiles drug hits from all pipeline runs
   - Reads individual result CSV files
   - Combines into master datasets
   - Generates summary statistics

2. **`filter_shared_drugs.py`** - Filters results to shared drug subset
   - Identifies 61 drugs common to both databases
   - Creates shared-only analysis files

3. **`merge_drug_evidence_hits_to_json.py`** - Creates JSON evidence mappings
   - Merges drug hits with Open Targets evidence
   - Generates dictionary-like structures
   - Outputs: `drug_disease_combined.json` and `drug_disease_combined_shared.json`

4. **`generate_drug_hits_evidence_summaries.py`** - Evidence validation analysis
   - Calculates evidence rates per disease
   - Generates summary tables
   - Full dataset analysis

5. **`generate_filtered_drug_hits_evidence_summaries.py`** - Filtered evidence analysis
   - Same as above but for q-value filtered results
   - Creates files in `results/filtered_q*/` directories

### R Scripts

1. **`run_all_diseases_batch.R`** - Main batch execution script
   - Runs pipeline for all 58 diseases
   - Both CMAP and TAHOE methods
   - Generates all results in `results_1/`

2. **`run_single_disease_test.R`** - Test script for single disease
   - Useful for debugging
   - Quick validation of pipeline changes

3. **`run_parallel_safe.sh`** - Parallel execution wrapper
   - Bash script for running multiple diseases in parallel
   - Manages system resources

### Other Files

- **`batch_sequential_output.log`** - Sequential execution log
- **`results/`** - Intermediate processing outputs

## Quick Start Guide

### 1. View the Analysis Report
```bash
# Open in browser
open COMPREHENSIVE_STUDY_REPORT.html

# Or read markdown version
cat COMPREHENSIVE_STUDY_REPORT.md
```

### 2. Explore Summary Data
```bash
# Full dataset summary
cat data/full_summary_with_total_row.csv

# Shared drug subset summary
cat data/shared_summary_with_total_row.csv
```

### 3. Find Drugs for a Specific Disease
```bash
# Search in the detailed drug sets file
grep "Alzheimer" data/full_summary_drug_sets_by_disease.csv
```

### 4. Check Evidence for Drug-Disease Pairs
```python
import json

# Load the evidence mapping
with open('data/drug_disease_combined.json', 'r') as f:
    evidence = json.load(f)

# Check evidence for a specific disease
disease = "Alzheimer's disease"
if disease in evidence:
    print(f"Drugs for {disease}:")
    for drug, info in evidence[disease].items():
        print(f"  {drug}: {info['evidence_count']} evidence entries")
```

### 5. Examine Individual Disease Results
```bash
# List all results for a disease
ls results_1/Alzheimers_disease_CMAP_*/

# View drug hits
cat results_1/Alzheimers_disease_CMAP_*/file*_hits_q\<1.00.csv
```

## Key Findings Summary

### Overall Statistics
- **Total drug-disease associations**: 6,161
- **CMAP hits**: 3,524 (38.7% with evidence)
- **TAHOE hits**: 2,637 (42.9% with evidence)
- **Consensus predictions**: 33 drugs (100% with evidence)
- **Novel predictions**: ~60% without prior evidence

### Method Comparison
- **CMAP**: Broader coverage (1,309 drugs), higher sensitivity
- **TAHOE**: Deeper profiling (56,827 experiments), higher specificity
- **Complementary**: Different drugs identified by each method
- **Consensus**: Highest confidence when both methods agree

### Top Diseases by Hit Count
1. Endometrial cancer (216 hits)
2. Glioblastoma (214 hits)
3. Chronic granulomatous disease (208 hits)
4. Colorectal cancer (207 hits)
5. Eczema (208 hits)

## Understanding the Analysis

### Two Analysis Strategies

**1. Full Dataset Analysis**
- Uses complete drug libraries (CMAP: 1,309, TAHOE: 379)
- Maximizes discovery potential
- Files: `full_*.csv`, `all_drug_hits_compiled.csv`

**2. Shared Drug Subset Analysis**
- Uses only 61 drugs in both databases
- Enables direct method comparison
- Files: `shared_*.csv`, `all_drug_hits_compiled_shared_only.csv`

### Evidence Validation

Drug hits are validated against:
- **Open Targets Platform**: Clinical trial data, approval status
- **Evidence types**: Phase 0-4 trials, approved indications
- **Validation rate**: 40.5% overall, 100% for consensus predictions

### Statistical Significance

- **Connectivity Score**: Measures drug-disease relationship strength
  - Negative = therapeutic potential (reverses disease signature)
  - Positive = contraindicated (mimics disease signature)
- **P-value**: Statistical significance from permutation testing
- **Q-value**: FDR-corrected p-value (controls false discoveries)

## Additional Resources

### External Links
- [Open Targets Platform](https://platform.opentargets.org)
- [CREEDS Database](http://amp.pharm.mssm.edu/creeds/)
- [CMAP/LINCS](https://clue.io/)

### Related Files in Project
- `../DRpipe/` - R package for drug repurposing pipeline
- `../scripts/` - Main analysis scripts and configuration
- `../shiny_app/` - Interactive visualization application

## Tips for Navigation

1. **Start with the report**: Read `COMPREHENSIVE_STUDY_REPORT.md` for context
2. **Check summaries first**: Use `data/*_summary_*.csv` files for overview
3. **Drill down as needed**: Explore individual disease results in `results_1/`
4. **Use filtered results**: Start with `results/filtered_q0p1/` for high-confidence hits
5. **Validate with evidence**: Check `*_annotated_hits_with_open_targets.csv` files

## Common Questions

**Q: What's the difference between CMAP and TAHOE?**
A: CMAP has broader drug coverage (1,309 drugs) while TAHOE has deeper profiling per drug (56,827 experiments). CMAP is better for discovery, TAHOE for validation.

**Q: Which q-value threshold should I use?**
A: Start with q < 0.1 for balanced results. Use q < 0.05 for high confidence or q < 0.5 for exploratory analysis.

**Q: What does "shared drugs" mean?**
A: The 61 drugs present in both CMAP and TAHOE databases, allowing direct method comparison.

**Q: How reliable are the predictions?**
A: 40.5% have existing evidence. Consensus predictions (both methods agree) have 100% validation rate.

**Q: Where can I find drugs for my disease of interest?**
A: Check `data/full_summary_drug_sets_by_disease.csv` or search in `data/drug_disease_combined.json`.
