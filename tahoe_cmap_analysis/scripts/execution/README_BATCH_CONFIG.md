# DRpipe Batch Analysis - Configuration-Based Execution

This directory contains the refactored batch processing system for the drug repurposing analysis pipeline.

## Overview

The batch analysis system has been refactored to support three execution modes:

1. **Direct Parameter Mode** (`run_drpipe_batch.R`) - Pass all arguments via command line
2. **Configuration File Mode** (`run_batch_from_config.R`) - Use a YAML config file (Recommended)
3. **Legacy Direct Scripts** - Original hardcoded scripts for specific disease sources

## Files

### Core Scripts

- **`run_drpipe_batch.R`** - Generic batch runner with parameterized arguments
  - Accepts all parameters via command-line flags
  - Supports skipping existing results with `--skip_existing`
  - Base script used by the configuration wrapper

- **`run_batch_from_config.R`** - Configuration file wrapper (Recommended)
  - Reads parameters from YAML config files
  - Simpler, more maintainable approach
  - Validates all configuration values before execution

### Configuration Files

- **`batch_configs/creeds_manual_config.yml`** - Configuration for CREEDS MANUAL disease signatures
  - All paths and parameters for CREEDS MANUAL analysis
  - Can be modified for different versions or datasets
  - Template for creating new configurations

### Legacy Scripts

- **`run_creeds_manual_batch.R`** - Original hardcoded CREEDS MANUAL script (kept for reference)
- **`run_drpipe_batch.R`** - Updated with skip logic from CREEDS MANUAL
- **`run_sirota_lab_batch.R`** - Original hardcoded Sirota Lab script (kept for reference)

## Usage

### Recommended: Using Configuration File

```bash
# From the scripts/execution directory
Rscript run_batch_from_config.R --config_file batch_configs/creeds_manual_config.yml
```

### Advanced: Direct Parameters

```bash
Rscript run_drpipe_batch.R \
  --disease_dir "../data/disease_signatures/creeds_manual_disease_signatures_standardised_exp_2" \
  --disease_source "CREEDS MANUAL" \
  --cmap_sig "../data/drug_signatures/cmap/cmap_signatures.RData" \
  --cmap_meta "../data/drug_signatures/cmap/cmap_drug_experiments_new.csv" \
  --tahoe_sig "../data/drug_signatures/tahoe/tahoe_signatures.RData" \
  --tahoe_meta "../data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv" \
  --gene_table "../data/gene_id_conversion_table.tsv" \
  --out_root "../results/creed_manual_standardised_results_OG_exp_8" \
  --report_dir "../reports" \
  --report_prefix "creeds_manual" \
  --skip_existing TRUE
```

## Creating New Configurations

To create a configuration for a new disease source:

1. Copy an existing config:
   ```bash
   cp batch_configs/creeds_manual_config.yml batch_configs/my_new_source_config.yml
   ```

2. Edit the config file with appropriate paths:
   ```yaml
   disease:
     source: "MY NEW SOURCE"
     directory: "path/to/disease_signatures"
   
   cmap:
     signatures: "path/to/cmap_signatures.RData"
     metadata: "path/to/cmap_metadata.csv"
   
   # ... etc
   ```

3. Run the batch:
   ```bash
   Rscript run_batch_from_config.R --config_file batch_configs/my_new_source_config.yml
   ```

## Configuration Parameters

### Disease Section
- `source` - Label for the disease signature source
- `directory` - Path to directory containing `*_signature.csv` files

### CMAP Section
- `signatures` - Path to CMAP signatures RData file
- `metadata` - Path to CMAP drug experiments metadata CSV
- `valid_instances` - (Optional) Path to valid instances CSV

### TAHOE Section
- `signatures` - Path to TAHOE signatures RData file
- `metadata` - Path to TAHOE drug experiments metadata CSV

### Analysis Section
- `gene_table` - Path to gene ID conversion table
- `logfc_cutoff` - LogFC threshold (default: 0.0)
- `qval_threshold` - Q-value threshold (default: 0.5)

### Output Section
- `root_directory` - Where to save analysis results
- `report_directory` - Where to save reports
- `report_prefix` - Prefix for report filenames

### Runtime Section
- `skip_existing_results` - Skip diseases with existing results (default: false)
- `verbose` - Verbose output (default: true)

## Key Features

### Skip Existing Results
When `skip_existing_results: true` in the config (or `--skip_existing TRUE` on command line):
- Checks for existing result folders in the output directory
- Skips any disease that has already been processed
- Useful for resuming interrupted batch runs
- Results marked as "SKIPPED" in summary

### Output Files

For each batch run:
- `batch_run_log_<timestamp>.txt` - Detailed processing log
- `batch_run_summary_<timestamp>.csv` - Summary of all runs
- `<prefix>_batch_report_<timestamp>.txt` - Human-readable report
- `<prefix>_batch_summary_<timestamp>.csv` - Summary in reports directory

## Examples

### Run CREEDS MANUAL with skip logic enabled
```bash
Rscript run_batch_from_config.R --config_file batch_configs/creeds_manual_config.yml
```

### Run with verbose output
The wrapper script automatically shows configuration summary when running.

### Create a new config for Sirota Lab data
```bash
cp batch_configs/creeds_manual_config.yml batch_configs/sirota_lab_config.yml
# Edit sirota_lab_config.yml with appropriate paths
Rscript run_batch_from_config.R --config_file batch_configs/sirota_lab_config.yml
```

## Troubleshooting

### Error: "Configuration file not found"
- Check that the config file path is correct relative to where you're running the script
- Use absolute paths if needed

### Error: "Missing required configuration section"
- Ensure your config file includes all required sections: disease, cmap, tahoe, analysis, output, runtime
- See the example config for the correct structure

### Error: "Gene conversion table not found"
- Verify the path in the config points to an existing file
- Check that relative paths are correct from where you're running the script

### Results showing as SKIPPED
- This happens when `skip_existing_results: true` and result folders already exist
- Set to `false` to reprocess everything, or delete existing result folders
