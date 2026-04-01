# shared batch execution

This folder contains the shared execution entrypoints used by the study-specific configs stored under each study folder.

## Core scripts

- `run_batch_from_config.R`
  Reads a YAML config and launches a batch run.
- `run_cdrpipe_batch.R`
  Lower-level runner used by the wrapper.
- `apply_percentile_filter.R`
  Helper used by percentile-based disease-signature filtering.
- `convert_signatures_to_rds.R`
  Utility for signature format conversion.

## Study-specific config files

- CREEDS:
  [creeds_manual_config_all_avg.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/execute/creeds_manual_config_all_avg.yml)
- Endometriosis:
  [all_19_signatures_config.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/all_19_signatures_config.yml)
  [tomiko_v3_config.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/tomiko_v3_config.yml)
  [tomiko_v4_strict_config.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/tomiko_v4_strict_config.yml)
  [single_cell_batch_config.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/single_cell_batch_config.yml)
- Autoimmune:
  [autoimmune_batch_config.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/scripts/execute/autoimmune_batch_config.yml)

## Usage

From `cdrpipe_comparative_analysis/`:

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file creeds/scripts/execute/creeds_manual_config_all_avg.yml
```

The same wrapper works for the endometriosis and autoimmune configs.

## Path resolution

Config paths are interpreted relative to the `cdrpipe_comparative_analysis/` root.
