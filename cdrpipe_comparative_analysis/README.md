# CDRPipe Comparative Analysis

Curated comparative drug-repurposing workflows for benchmarking CMAP and TAHOE predictions across CREEDS diseases, endometriosis sub-signatures, and autoimmune case studies.

This cleaned copy keeps the reusable scripts, curated disease-signature inputs, summary analysis tables, and manuscript-facing assets. Large local runtime artifacts have been removed, including:

- per-disease `results/` directories
- the bundled Python `venv/`
- heavyweight drug-signature matrices and intermediate parquet checkpoints
- one-off debug, repair, and test scripts

`Exp8` outputs were intentionally preserved, including [Exp8_Analysis.xlsx](./creeds_diseases/analysis/Exp8_Analysis.xlsx) and the companion files in `creeds_diseases/analysis/creed_manual_analysis_exp_8/`.

## What This Directory Is For

Use this directory for:

- preprocessing disease and drug-signature inputs
- running comparative batch analyses from YAML configs
- reproducing curated downstream analyses
- regenerating publication support outputs

This directory is not intended to ship all raw binary inputs or every exploratory run artifact.

## Current Structure

```text
cdrpipe_comparative_analysis/
├── data/
│   ├── drug_signatures/          # Metadata kept; large signature matrices excluded
│   ├── known_drugs/              # Compact validation references
│   ├── gene_id_conversion_table.tsv
│   └── shared_drugs_cmap_tahoe.csv
├── scripts/
│   ├── preprocessing/
│   ├── execution/
│   ├── analysis/
│   ├── singularity/
│   └── visualization/
├── creeds_diseases/
│   ├── disease_signatures/
│   └── analysis/
├── case_study_endomentriosis/
│   ├── disease_signatures/
│   ├── endo_disease_signatures/
│   └── analysis/
├── case_study_autoimmune_diseases/
│   └── analysis/
└── visuals/                     # Preserved as-is
```

## Quick Start

1. Install the core package from the repository root:

   ```r
   devtools::install("CDRPipe")
   ```

2. Restore the required large signature matrices into `data/drug_signatures/` using the filenames documented in [data/drug_signatures/README.md](data/drug_signatures/README.md).

3. Run a curated batch configuration:

   ```bash
   Rscript scripts/execution/run_batch_from_config.R \
     --config_file scripts/execution/batch_configs/90_selected_diseases.yml
   ```

## Notes

- Batch configs are now written relative to this directory instead of a machine-specific absolute path.
- The preserved `Exp8` analysis workbook is the canonical input for the manuscript-oriented visualization scripts under `scripts/visualization/`.
- `visuals/` was intentionally left untouched during cleanup.
- Several stale endometriosis comparison helpers, one-off local diagnostics, and broken scratch scripts were removed; the remaining scripts are the curated set intended for sharing.
