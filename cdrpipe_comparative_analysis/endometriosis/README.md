# endometriosis workflow

This folder contains the endometriosis-specific comparative-analysis workflow.
It keeps the source signature sets, the canonical standardized signature panel
used for the main endometriosis batch run, the preserved summary outputs, and
the manuscript figure files.

## What is in this folder

- `data/`
  Endometriosis signature inputs and preserved processing materials.
- `scripts/`
  Endometriosis-specific processing, execution, analysis, and figure-generation
  scripts.
- `results/`
  Preserved manuscript support tables and the location where new batch result
  folders should be written.
- `analysis/`
  Cross-signature endometriosis analysis outputs from the standardized batch
  run.
- `figures/`
  Final endometriosis figure files.

## Canonical data folders

- [standardized_endometriosis_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/standardized_endometriosis_signatures)
  The 19-signature standardized panel used by the main endometriosis batch run.
- [tomiko_v3_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/tomiko_v3_signatures)
  The six-signature Tomiko panel used by the `6_tomiko_endo_v3.yml` run.
- [strict_filter_endometriosis_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/strict_filter_endometriosis_signatures)
  The six strict-filter signatures used by the `endometriosis_tomiko_config_v4.yml` run.
- [tomiko_signatures_raw](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/tomiko_signatures_raw)
  Preserved Tomiko source signatures.
- [sirota_lab_signatures_raw](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/sirota_lab_signatures_raw)
  Preserved Sirota Lab source signatures.
- [sirota_lab_signatures_standardized](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/sirota_lab_signatures_standardized)
  Standardized Sirota Lab signatures.
- [tomiko_signature_processing_workspace](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/tomiko_signature_processing_workspace)
  Preserved notes, threshold summaries, and intermediate workspace files that
  support the endometriosis curation process.

## Shared inputs used by this workflow

- [data/drug_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_signatures)
- [data/gene_id_conversion_table.tsv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/gene_id_conversion_table.tsv)

## Reproducibility audit

The curated tree supports direct reruns from the canonical signature sets
forward:

1. run the standardized 19-signature batch analysis from
   [standardized_endometriosis_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/standardized_endometriosis_signatures)
2. run the Tomiko six-signature panel from
   [tomiko_v3_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/tomiko_v3_signatures)
3. run the strict six-signature panel from
   [strict_filter_endometriosis_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/strict_filter_endometriosis_signatures)
4. inspect the preserved analysis outputs in
   [standardized_endometriosis_signature_analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/analysis/standardized_endometriosis_signature_analysis)

The exact one-step assembly that produced the full
`standardized_endometriosis_signatures/` panel from Tomiko, Sirota, and CREEDS
inputs is not preserved as a single dedicated script in this curated tree. The
standardized panel itself is preserved and is the canonical input for the main
reproducible batch run.

The manuscript heatmap provenance is also preserved, but not fully rerunnable
end to end because the original Tahoe six-signature hit tables have not been
recovered.

## Step-by-step replication

Run the commands below from
`/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis`.

### 1. Review the source signatures

The preserved source inputs are:

- [tomiko_signatures_raw](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/tomiko_signatures_raw)
- [sirota_lab_signatures_raw](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/sirota_lab_signatures_raw)

If you need the standardized Sirota-only set, you can regenerate it with:

```bash
python endometriosis/scripts/processing/process_sirota_lab_signatures.py
```

### 2. Regenerate a standardized signature directory when needed

The generic standardization helper is:

```bash
python endometriosis/scripts/processing/standardize_endo_signatures.py \
  --input_dir <input_signature_dir> \
  --output_dir <output_signature_dir>
```

The preserved canonical output of that process for the main endometriosis run is:

- [standardized_endometriosis_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/data/standardized_endometriosis_signatures)

### 3. Run the main standardized endometriosis batch analysis

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/19_endo_standardized.yml
```

This writes new per-signature result folders to:

- `endometriosis/results/standardized_endometriosis_signature_results/`

and writes the analysis report files to:

- [standardized_endometriosis_signature_analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/analysis/standardized_endometriosis_signature_analysis)

### 4. Run the alternative endometriosis panels

Tomiko v3 six-signature panel:

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/6_tomiko_endo_v3.yml
```

Strict six-signature panel:

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/endometriosis_tomiko_config_v4.yml
```

Sirota-only panel:

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file endometriosis/scripts/execute/sirota_lab_config_all_avg.yml
```

### 5. Recreate the exploratory QC and threshold summaries

The main helper scripts are:

- [analyze_threshold_recommendations.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/analysis/analyze_threshold_recommendations.R)
- [analyze_qc_threshold_comprehensive.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/analysis/analyze_qc_threshold_comprehensive.R)
- [calculate_genes_retained.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/analysis/calculate_genes_retained.R)

These scripts now write their outputs into stable paths under `endometriosis/`
rather than into ad hoc working directories.

### 6. Review the preserved heatmap provenance

The surviving manuscript support material is in:

- [case_study_heatmap_provenance](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/results/case_study_heatmap_provenance)

This includes:

- [preserved_cmap_hit_tables](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/results/case_study_heatmap_provenance/preserved_cmap_hit_tables)
- [preserved_replication_tables](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/results/case_study_heatmap_provenance/preserved_replication_tables)

The original Tahoe six-signature hit tables used by the heatmap workflow are
still missing, so this provenance layer is preserved for traceability rather
than as a full end-to-end rerun path.

### 7. Review the final figures

The current manuscript figures are in:

- [endometriosis/figures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/figures)

The heatmap regeneration script is:

- [generate_case_study_endometriosis.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/endometriosis/scripts/visualization/generate_case_study_endometriosis.R)

At the moment that script serves as a provenance-aware guardrail: it explains
the missing direct inputs instead of silently failing.
