# shared scripts

This folder contains scripts that are reused across studies in
`cdrpipe_comparative_analysis/`. Study-specific workflows live under:

- [creeds/scripts](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts)
- [autoimmune/scripts](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/scripts)
- [endometriosis/scripts](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts)

Run the shared scripts from the `cdrpipe_comparative_analysis/` root unless a
script explicitly says otherwise.

## How This Folder Fits The Workflow

The shared scripts cover five jobs:

1. `extraction/`
   Build the Tahoe signature matrix from the raw Tahoe export.
2. `processing/`
   Harmonize CMAP and Tahoe, prepare Open Targets evidence, and generate shared
   reference files such as valid-instance tables.
3. `execute/`
   Launch study batch runs from YAML config files.
4. `analysis/`
   Reserved for cross-study analysis helpers. Most analysis now lives with each
   study instead.
5. `visualization/`
   Create shared cross-study figures, especially the platform comparison panels.

## Reproducible Shared Workflow

This is the shared workflow that feeds the study folders.

1. Prepare Tahoe signatures from the raw Tahoe H5 export.
   Use the three-step extraction pipeline in `extraction/`.
2. Prepare shared platform inputs.
   Use the scripts in `processing/` to filter CMAP and Tahoe, generate valid
   instances, and process Open Targets evidence.
3. Run a study batch config.
   Use `execute/run_batch_from_config.R` with a config from a study folder.
4. Analyze within the study folder.
   CREEDS, autoimmune, and endometriosis each keep their own analysis outputs
   and figure-generation scripts.
5. Generate shared cross-study figures.
   Use the scripts in `visualization/`.

## Folder Audit

### `extraction/`

These scripts build the full Tahoe signature object used later by the batch
pipeline.

- `extract_OG_tahoe_part_1.py`
  Reads the raw Tahoe H5 log-fold-change matrix, optionally applies p-value
  filtering, and writes a parquet checkpoint.
  Main input:
  `data/raw_data/tahoe/broad_tahoe_lfc_lfc.h5`
  Main output:
  `data/intermediate_hpc/tahoe_l2fc_all_genes_all_drugs.parquet`
- `extract_OG_tahoe_part_2_rank_and_save_parquet.py`
  Loads the part-1 checkpoint, maps genes to Entrez IDs, ranks each experiment,
  and writes the ranked parquet checkpoint used by the R conversion step.
  Main input:
  `data/intermediate_hpc/tahoe_l2fc_all_genes_all_drugs.parquet`
  Main output:
  `data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet`
- `extract_OG_tahoe_part_3_convert_to_rdata.R`
  Converts the ranked Tahoe parquet checkpoint into the final
  `tahoe_signatures.RData` object used by `CDRPipe`.
  Main input:
  `data/drug_signatures/tahoe/checkpoint_ranked_all_genes_all_drugs.parquet`
  Main output:
  `data/drug_signatures/tahoe/tahoe_signatures.RData`
- `run_OG_tahoe_part_1.sh`
  Wynton/HPC submission wrapper for part 1.
- `run_OG_tahoe_part2_rank_and_save_parquet.sh`
  Wynton/HPC submission wrapper for part 2.

Notes:

- The two shell scripts are cluster launchers. They are useful if you want to
  recreate the large Tahoe build on Wynton, but they are not required for
  downstream study reruns if `tahoe_signatures.RData` already exists.
- The part-1 and part-2 scripts are resource-heavy and were written for large
  matrices. The part-3 R conversion is the final handoff into the package-ready
  RData format.

### `processing/`

These scripts create shared harmonized inputs used across studies.

- `filter_cmap_data.py`
  Filters CMAP signatures down to the shared gene universe and the shared drug
  set used in the platform comparison work.
  Main inputs:
  `data/drug_signatures/cmap/cmap_signatures.RData`,
  `data/drug_signatures/cmap/cmap_drug_experiments_new.csv`,
  `data/shared_genes_cmap_tahoe.csv`,
  `data/shared_drugs_cmap_tahoe.csv`
  Main outputs:
  `data/drug_signatures/cmap/cmap_genes_filtered.RData`,
  `data/drug_signatures/cmap/cmap_genes_drugs.RData`,
  `data/cmap_signature_versions_report.txt`
- `filter_tahoe_by_shared_genes.R`
  Filters the full Tahoe signature object to the shared gene universe.
  Main inputs:
  `data/drug_signatures/tahoe/tahoe_signatures.RData`,
  `data/shared_genes_cmap_tahoe.csv`
  Main output:
  `data/drug_signatures/tahoe/tahoe_signatures_shared_genes_only.RData`
- `filter_tahoe_part_1_gene_filtering.py`
  Older Tahoe shared-gene filtering pipeline that starts from raw Tahoe data and
  writes intermediate parquet output for the shared-gene branch.
- `filter_tahoe_part_2_ranking.py`
  Ranks the intermediate Tahoe shared-gene parquet output.
- `filter_tahoe_part_3a_rdata_all.R`
  Converts the ranked Tahoe shared-gene parquet output into an RData file.
- `filter_tahoe_part_3b_rdata_shared_drugs.R`
  Filters the ranked Tahoe shared-gene output down to shared-drug experiments.
- `convert_filtered_tahoe_to_rdata.R`
  Utility to convert `tahoe_signatures_shared_genes.parquet` into an RData
  object when that parquet file already exists.
- `generate_valid_instances.py`
  Builds CMAP and Tahoe valid-instance tables using replicate consistency rules.
- `processing_known_drugs_data.py`
  Processes the raw Open Targets exports into the shared parquet files in
  [data/drug_evidence/open_targets](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_evidence/open_targets).
- `utils.py`
  Shared Python helpers for name normalization used by the processing scripts.

Notes:

- The `filter_tahoe_part_*` scripts belong to the shared-gene Tahoe branch used
  for platform harmonization. They are not required for every study rerun, but
  they are part of how the shared comparison inputs were built.
- `processing_known_drugs_data.py` is the main shared preprocessing step for the
  Open Targets evidence tables used in downstream validation.

### `execute/`

These scripts are the main shared entrypoints for running comparative-analysis
experiments with the installed `CDRPipe` package.

- `run_batch_from_config.R`
  Wrapper that reads a YAML config, resolves paths relative to the
  `cdrpipe_comparative_analysis/` root, and launches a batch run.
- `run_cdrpipe_batch.R`
  Lower-level batch runner that loops over disease signatures, executes CMAP and
  Tahoe runs, writes batch logs, and optionally skips diseases that already have
  results.
- `apply_percentile_filter.R`
  Helper used during batch execution when a config enables percentile-based
  disease-signature filtering.
- `convert_signatures_to_rds.R`
  Utility that converts very large shared-gene signature RData files into `.rds`
  files for easier loading.

Study config files live under each study folder:

- CREEDS:
  [creeds/scripts/execute/creeds_manual_config_all_avg.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/execute/creeds_manual_config_all_avg.yml)
- Autoimmune:
  [autoimmune/scripts/execute/case_study_v2.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/scripts/execute/case_study_v2.yml)
- Endometriosis:
  [endometriosis/scripts/execute/19_endo_standardized.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/19_endo_standardized.yml)
  [endometriosis/scripts/execute/6_tomiko_endo_v3.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/6_tomiko_endo_v3.yml)
  [endometriosis/scripts/execute/endomentriosis_tomiko_config_v4.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/endomentriosis_tomiko_config_v4.yml)
  [endometriosis/scripts/execute/sirota_lab_config_all_avg.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/execute/sirota_lab_config_all_avg.yml)

Example:

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file creeds/scripts/execute/creeds_manual_config_all_avg.yml
```

### `analysis/`

This folder is intentionally light. Shared post-processing now mostly lives with
the study that produced the results:

- CREEDS analysis scripts and outputs live under [creeds/analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/analysis)
- Autoimmune analysis scripts and outputs live under [autoimmune/analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/analysis)
- Endometriosis analysis scripts and outputs live under [endometriosis/analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/analysis)

### `visualization/`

These scripts create shared figures that are not owned by just one study.

- `generate_platform_comparison.R`
  Main shared figure script for the CMAP vs Tahoe platform comparison. It now
  reads directly from the canonical shared locations:
  `data/drug_signatures/`,
  `data/drug_evidence/open_targets/`,
  and `creeds/data/manual_signatures_extracted/`.
- `create_venn_full_datasets.R`
  Builds a Venn diagram showing the raw drug coverage across CMAP, Tahoe, and
  Open Targets.
- `create_venn_platform_coverage.R`
  Builds a cleaner platform-overlap Venn diagram used for analysis summaries.
- `generate_analysis_flowchart.R`
  Draws the overall study-design flowchart.

Outputs from these shared scripts go into
[figures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/figures).

## What To Run For A Fresh Reproduction

If you are reproducing the shared layer from scratch, this is the practical
order to follow:

1. Build Tahoe signatures with the `extraction/` pipeline.
2. Prepare shared platform resources with the `processing/` scripts.
3. Run the study config you care about with `execute/run_batch_from_config.R`.
4. Use the study-owned analysis and figure scripts inside `creeds/`,
   `autoimmune/`, or `endometriosis/`.
5. Generate cross-study panels from `visualization/`.
