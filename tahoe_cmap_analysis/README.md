# TAHOE-CMAP Analysis Directory

## IMPORTANT: UNDER DEVELOPMENT - NOT FOR PRODUCTION USE

This directory contains experimental work that is still under active development and validation. TAHOE integration is NOT fully complete, analysis tools are being validated, and results should be considered preliminary. Workflows are subject to change.

For production drug repurposing analysis, please use the main DRpipe package and Shiny app instead. See the main repository [README.md](../README.md) for instructions.

---

## Quick Overview

The tahoe_cmap_analysis directory contains a comprehensive computational drug repurposing analysis that compares drug signatures from two databases:

- CMAP (Connectivity Map) - established drug signature database
- TAHOE - newly integrated drug signature database

This analysis evaluates therapeutic candidates for 58 disease signatures by comparing results from both databases to identify high-confidence drug-disease associations. The preliminary study identified **6,161 total drug-disease associations** with **33 high-confidence drugs** validated by both methods.

**Note:** These findings are preliminary and subject to further validation.

## Complete Directory Structure

```
tahoe_cmap_analysis/
├── README.md                           # This file - complete documentation
├── COMPREHENSIVE_STUDY_REPORT.md       # Detailed analysis report
├── COMPREHENSIVE_STUDY_REPORT.html     # HTML version of report
├── requirements.txt                    # Python dependencies
├── data/                               # Input data and compiled results
├── scripts/                            # Analysis and processing scripts
├── results/                            # Filtered analysis outputs
├── reports/                            # Batch execution reports
├── logs/                               # Log files (currently empty)
├── dump/                               # Archive of older versions and reports
└── venv/                               # Python virtual environment
```

---

## Main Files and Reports

### Report Files
- **COMPREHENSIVE_STUDY_REPORT.md** - Complete study documentation including:
  - Executive summary and key findings
  - Methodology and pipeline details
  - Full dataset and shared drug subset analyses
  - Method comparison and recommendations
  - Disease-specific insights
  
- **COMPREHENSIVE_STUDY_REPORT.html** - Same content as above in HTML format for easier viewing in browsers

---

## Subdirectories - Detailed Information

### data/ - Input Data and Compiled Results

Contains compiled summary files and drug-disease association data.

#### Full Dataset Analysis (All Drugs)

Files analyzing all drugs from CMAP (1,309 drugs) and TAHOE (379 drugs):

- **all_drug_hits_compiled.csv** - Complete list of all drug hits across all diseases
- **drug_hits_summary.csv** - Summary statistics per disease
- **full_summary_with_total_row.csv** - Count summary with totals
- **full_summary_drug_sets_by_disease.csv** - Detailed drug lists per disease per method
- **full_annotated_hits_with_open_targets.csv** - All drug hits annotated with Open Targets evidence
- **drug_disease_combined.json** - Dictionary-like structure of disease → drug → evidence mappings

#### Shared Drug Subset Analysis (61 Common Drugs)

Files analyzing only the 61 drugs present in BOTH databases:

- **shared_drugs_cmap_tahoe.csv** - List of the 61 drugs common to both databases
- **all_drug_hits_compiled_shared_only.csv** - Drug hits from shared drugs only
- **drug_hits_summary_shared_only.csv** - Summary statistics for shared drug analysis
- **shared_summary_with_total_row.csv** - Count summary for shared drugs
- **shared_summary_drug_sets_by_disease.csv** - Drug lists per disease (shared drugs only)
- **shared_annotated_hits_with_open_targets.csv** - Shared drug hits with evidence annotations
- **drug_disease_combined_shared.json** - Dictionary structure for shared drug analysis

#### Key Differences Between Full and Shared Analyses

Full Dataset:
- Uses complete drug libraries (CMAP: 1,309 drugs, TAHOE: 379 drugs)
- Maximizes discovery potential
- Shows method-specific strengths
- Approximately 60% novel predictions without prior evidence

Shared Subset:
- Uses only 61 drugs present in both databases
- Enables direct method-to-method comparison
- 100% validation rate for consensus predictions (33 drugs)
- Demonstrates method reliability

#### Data Organization

- **analysis/** - Processed analysis-ready datasets
- **disease_signatures/** - Disease signature data files (input)
- **drug_signatures/** - Drug signature data from CMAP and TAHOE (input)
- **known_drugs/** - Reference dataset of known therapeutic drugs
- **gene_id_conversion_table.tsv** - Mapping for gene identifiers between databases

### scripts/ - Analysis and Processing Scripts

All executable scripts organized by processing stage.

#### scripts/execution/ - Batch Pipeline Execution

Runs drug repurposing analysis on multiple diseases in parallel.

Key Files:
- **run_drpipe_batch.R** - Main batch execution script for DRpipe
- **run_batch_from_config.R** - Flexible batch runner using configuration files
- **batch_configs/** - Configuration files defining analysis parameters and disease sets
- **README_BATCH_CONFIG.md** - Documentation for batch configuration format

How to use:
1. Create or edit a configuration file in batch_configs/
2. Run run_batch_from_config.R with your config
3. Monitor progress in the reports/ directory

#### scripts/preprocessing/ - Data Preparation and Filtering

Prepares raw CMAP and TAHOE data for analysis.

TAHOE Processing:
- **extract_OG_tahoe_part_1.py** - Extract TAHOE signature data (Part 1)
- **extract_OG_tahoe_part_2_rank_and_save_parquet.py** - Rank TAHOE signatures (Part 2)
- **extract_OG_tahoe_part_3_convert_to_rdata.R** - Convert to R format (Part 3)

CMAP Processing:
- **filter_cmap_data.py** - Filter and standardize CMAP signatures

Data Standardization:
- **filter_tahoe_part_1_gene_filtering.py** - Filter genes (Part 1)
- **filter_tahoe_part_2_ranking.py** - Rank and score (Part 2)
- **filter_tahoe_part_3a_rdata_all.R** - Convert all results to RData format
- **filter_tahoe_part_3b_rdata_shared_drugs.R** - Convert shared drugs subset to RData

Disease and Drug Signature Processing:
- **process_creeds_signatures.py** - Process CREEDS disease signatures
- **process_sirota_lab_signatures.py** - Process Sirota lab disease signatures
- **standardize_creeds_signatures.py** - Standardize CREEDS format
- **processing_known_drugs_data.py** - Prepare known drug reference data

Utility:
- **generate_valid_instances.py** - Create valid drug-disease instance lists
- **filter_shared_drugs_cmap_tahoe.py** - Identify drugs in both databases
- **utils.py** - Common utility functions

Note: Preprocessing scripts are numbered (Part 1, 2, 3) - execute in order.

#### scripts/analysis/ - Results Analysis and Comparison

Analyzes and compares drug repurposing results from both databases.

Key Scripts:
- **extract_pipeline_results_analysis.py** - Extract results from pipeline outputs
- **compile_drug_hits.py** - Aggregate drug predictions across diseases
- **compare_tahoe_cmap.py** - Compare predictions between TAHOE and CMAP
- **compare_cmap_tahoe_random_scores.py** - Statistical comparison with random controls
- **extract_filter_results_to_shared_drugs.py** - Filter results to drugs present in both databases
- **extract_selected_disease_info.py** - Extract disease-specific analysis summaries

When to use: After running batch execution to analyze results, generate comparison statistics and validation metrics, or create summary tables for reporting.

#### scripts/visualization/ and scripts/singularity/

Additional directories for visualization scripts and containerization configurations for HPC cluster execution.

### results/ - Filtered Analysis Outputs

Contains filtered analysis outputs organized by q-value thresholds.

Contents:
- **creed_manual_standardised_results_OG_exp_8/** - CREEDS disease results (q-value filtered)
- **test_results/** - Smaller test runs and validation results

When to use: Access final filtered results after batch execution. Results are typically filtered by q-value significance thresholds and are suitable for publication-ready analyses.

#### Understanding Q-value Filtering

- Q-value: False Discovery Rate (FDR)-corrected p-value
- Lower q-value = Higher confidence, fewer false positives
- Higher q-value = More discoveries, potentially more false positives
- Recommendation: Start with q < 0.1 for balanced sensitivity/specificity

### reports/ - Batch Execution Summary Reports

Contains batch execution summary reports for monitoring and verification.

Report Types:
- ***_batch_report_*.txt** - Detailed execution logs with run statistics
  - File pattern: [dataset]_batch_report_[TIMESTAMP].txt
  - Contents: Number of drugs found, execution time, success rates per disease
  
- ***_batch_summary_*.csv** - Tabular summary of results per disease
  - File pattern: [dataset]_batch_summary_[TIMESTAMP].csv
  - Columns: Disease name, drug count, execution status, timing

When to use: Monitor batch job success/failure, verify all diseases processed correctly, or compare results across different runs.

### logs/ - Log Files

Currently empty. Intended for storing detailed execution logs, Python script outputs, R package diagnostics, and performance profiling data.

### dump/ - Archive and Legacy Documentation

Archive of older versions and supplementary documentation.

Important Contents:
- **COMPREHENSIVE_STUDY_REPORT.md** - Full analysis documentation
- **COMPREHENSIVE_STUDY_REPORT.html** - HTML version of comprehensive report
- **HPC_REVIEW_REPORT.md** - High-Performance Computing setup notes
- **SCRIPTS_README.md** - Legacy scripts documentation
- **data_old/, results_old/, etc.** - Previous versions and archived results

When to use: Reference for historical analysis approaches, legacy script documentation, or older result versions for comparison.

### venv/ - Python Virtual Environment

Contains the Python virtual environment for the project.

Setup:
```bash
cd tahoe_cmap_analysis
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## Getting Started - Quick Workflow

### For New Team Members

1. Understand the project:
   - Read README.md (this file) for project overview
   - Check dump/COMPREHENSIVE_STUDY_REPORT.md for full analysis details

2. Set up the environment:
   ```bash
   cd tahoe_cmap_analysis
   source venv/bin/activate  # or create if not exists
   pip install -r requirements.txt
   ```

3. Explore the data:
   - Look in data/ to understand input files
   - Check scripts/preprocessing/ to see how data is prepared

4. Run an analysis:
   - Create a batch config in scripts/execution/batch_configs/
   - Execute with scripts/execution/run_batch_from_config.R
   - Check reports/ for execution summaries

5. Analyze results:
   - Browse results/ for filtered outputs
   - Use scripts/analysis/ scripts to generate comparisons

### Common Tasks

#### Task: Run batch analysis on new diseases
1. Prepare disease signatures in data/disease_signatures/
2. Create config in scripts/execution/batch_configs/
3. Run scripts/execution/run_batch_from_config.R
4. Review results in reports/ and results/

#### Task: Add new drug signatures
1. Process raw data using scripts in scripts/preprocessing/
2. Update data/drug_signatures/
3. Re-run preprocessing scripts in order
4. Execute fresh batch analysis

#### Task: Compare CMAP vs TAHOE results
1. Ensure batch results are in results/
2. Run comparison scripts from scripts/analysis/
3. Results saved to results/ with comparison metrics

#### Task: Generate publication figures
1. Use analysis outputs from results/
2. Check dump/COMPREHENSIVE_STUDY_REPORT.md for figure templates
3. Consider batch summary reports in reports/ for data

---

## Dependencies

### Python Requirements
- pandas >= 2.0.0
- pyreadr >= 0.4.7
- pyarrow >= 12.0.0
- tqdm >= 4.65.0
- tables >= 3.8.0
- joblib >= 1.3.0
- psutil >= 5.9.0
- numpy >= 1.24.0

### R Requirements
- DRpipe package (see parent directory)
- Standard R data manipulation packages

Install all Python dependencies:
```bash
pip install -r requirements.txt
```

---

## Key Files Reference

| File/Directory | Purpose | Key Use Case |
|---|---|---|
| data/shared_drugs_cmap_tahoe.csv | Drugs in both databases | Cross-validation |
| data/gene_id_conversion_table.tsv | Gene ID mapping | Handling different ID systems |
| scripts/execution/batch_configs/ | Analysis parameters | Customizing runs |
| scripts/preprocessing/ | Data preparation | Updating source databases |
| scripts/analysis/ | Results processing | Generating final outputs |
| results/ | Filtered results | Publication-ready data |
| dump/COMPREHENSIVE_STUDY_REPORT.md | Full documentation | Understanding methodology |

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
