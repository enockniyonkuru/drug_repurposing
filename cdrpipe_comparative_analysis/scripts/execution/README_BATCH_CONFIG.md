# Batch Execution

This directory contains the curated execution entry points for the comparative-analysis subproject.

## Supported Entry Points

1. `run_batch_from_config.R`
   Recommended wrapper that reads a YAML config and launches a batch run.
2. `run_cdrpipe_batch.R`
   Lower-level parameterized runner used by the wrapper.
3. `apply_percentile_filter.R`
   Helper used by percentile-based filtering workflows.

## Files

### Core Scripts

- `run_batch_from_config.R`
- `run_cdrpipe_batch.R`
- `apply_percentile_filter.R`
- `convert_signatures_to_rds.R`

### Configuration Files

- `batch_configs/90_selected_diseases.yml`
- `batch_configs/creeds_manual_config_all_avg.yml`
- `batch_configs/sirota_lab_config_all_avg.yml`
- `batch_configs/19_endo_standardized.yml`
- `batch_configs/6_tomiko_endo_v3.yml`
- `batch_configs/endomentriosis_tomiko_config_v4.yml`
- `batch_configs/case_study_v2.yml`

## Path Resolution

Configs are now interpreted relative to the `cdrpipe_comparative_analysis/` directory. That means paths such as `data/...` or `creeds_diseases/...` no longer depend on a machine-specific absolute path.

## Usage

### Recommended: Using Configuration File

```bash
Rscript run_batch_from_config.R --config_file batch_configs/creeds_manual_config.yml
```

### Advanced: Direct Parameters

```bash
Rscript run_cdrpipe_batch.R \
  --disease_dir "../../creeds_diseases/disease_signatures/creeds_manual_disease_signatures_standardised" \
  --disease_source "CREEDS MANUAL" \
  --cmap_sig "../../data/drug_signatures/cmap/cmap_signatures.RData" \
  --cmap_meta "../../data/drug_signatures/cmap/cmap_drug_experiments_new.csv" \
  --tahoe_sig "../../data/drug_signatures/tahoe/tahoe_signatures.RData" \
  --tahoe_meta "../../data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv" \
  --gene_table "../../data/gene_id_conversion_table.tsv" \
  --out_root "../../creeds_diseases/results/creed_manual_standardised_results_OG_exp_8" \
  --report_dir "../../creeds_diseases/analysis" \
  --report_prefix "creeds_manual" \
  --skip_existing TRUE
```

## Creating New Configurations

To create a configuration for a new disease source:

1. Copy an existing config:
   ```bash
   cp batch_configs/creeds_manual_config_all_avg.yml batch_configs/my_new_source_config.yml
   ```

2. Edit the config file with appropriate paths:
   ```yaml
   disease:
     source: "MY NEW SOURCE"
     directory: "creeds_diseases/disease_signatures/my_signatures"
   
   cmap:
     signatures: "data/drug_signatures/cmap/cmap_signatures.RData"
     metadata: "data/drug_signatures/cmap/cmap_drug_experiments_new.csv"
   
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
- `logfc_column_selection` - Which logFC column(s) to use:
  - `"all"` - Use all columns matching the prefix (e.g., `logfc_dz:1`, `logfc_dz:2`, etc.)
  - Custom column name (e.g., `"mean_logfc"`, `"log2FC"`) - Use a specific column from your disease file
  - Multiple columns (comma-separated) - e.g., `"logfc_dz:459,logfc_dz:297"`
  - **Note:** Custom column names are automatically mapped to `logfc_dz` internally for the CDRP pipeline
- `use_averaging` - How to handle logFC columns:
  - `true` - Average selected columns into a single `logfc_dz` column
  - `false` - Use column(s) as-is (single columns are still mapped to `logfc_dz`)

### Output Section
- `root_directory` - Where to save analysis results
- `report_directory` - Where to save reports
- `report_prefix` - Prefix for report filenames

### Runtime Section
- `skip_existing_results` - Skip diseases with existing results (default: false)
- `verbose` - Verbose output (default: true)

## Key Features

### LogFC Column Handling

The batch system provides flexible handling of logFC columns to work with disease signatures in any format:

**How Column Selection Works:**

The `logfc_column_selection` parameter allows you to specify which logFC column(s) to use from your disease signature file. The system automatically handles custom column names:

```yaml
analysis:
  logfc_column_selection: "mean_logfc"  # Use the mean_logfc column
  use_averaging: true                   # Average selected columns
```

**Column Name Mapping:**

Regardless of what you name your column in the disease file (e.g., `mean_logfc`, `log2FC`, `fold_change`), the script automatically maps it to `logfc_dz` internally. This ensures the CDRP pipeline can find the logFC values without requiring a specific column name in your input files.

**Examples:**

| Scenario | Configuration | Result |
|----------|--------------|--------|
| Single custom column | `logfc_column_selection: "mean_logfc"` `use_averaging: true` | Maps `mean_logfc` → `logfc_dz` |
| Multiple columns average | `logfc_column_selection: "logfc_dz:1,logfc_dz:2"` `use_averaging: true` | Averages columns 1 & 2 → `logfc_dz` |
| All columns with prefix | `logfc_column_selection: "all"` `use_averaging: true` | Averages all `logfc_dz:*` columns |
| Custom column, no averaging | `logfc_column_selection: "fold_change"` `use_averaging: false` | Maps `fold_change` → `logfc_dz` |

**Important Notes:**
- Custom column names (like `mean_logfc`) are **not** matched by the `logfc_dz` prefix - they must be specified exactly in `logfc_column_selection`
- When using `"all"`, the script looks for columns starting with the `logfc_dz` prefix
- Single columns are always mapped to `logfc_dz`, even when `use_averaging: false`

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
Rscript run_batch_from_config.R --config_file batch_configs/creeds_manual_config_all_avg.yml
```

### Run with verbose output
The wrapper script automatically shows configuration summary when running.

### Create a new config for Sirota Lab data
```bash
cp batch_configs/creeds_manual_config_all_avg.yml batch_configs/sirota_lab_config.yml
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
