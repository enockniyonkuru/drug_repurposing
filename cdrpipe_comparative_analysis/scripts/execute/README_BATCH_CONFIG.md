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
  [19_endo_standardized.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/19_endo_standardized.yml)
  [6_tomiko_endo_v3.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/6_tomiko_endo_v3.yml)
  [endomentriosis_tomiko_config_v4.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/endomentriosis_tomiko_config_v4.yml)
  [sirota_lab_config_all_avg.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/sirota_lab_config_all_avg.yml)
- Autoimmune:
  [case_study_v2.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/scripts/execute/case_study_v2.yml)

## Usage

From `cdrpipe_comparative_analysis/`:

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file creeds/scripts/execute/creeds_manual_config_all_avg.yml
```

The same wrapper works for the endometriosis and autoimmune configs.

## Path resolution

Config paths are interpreted relative to the `cdrpipe_comparative_analysis/` root.
