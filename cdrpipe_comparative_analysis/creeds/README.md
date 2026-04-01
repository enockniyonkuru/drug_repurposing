# creeds workflow

This folder is the CREEDS all-diseases workflow for the comparative analysis.
It takes the downloaded CREEDS manual disease signatures, converts them into one
file per disease, standardizes those signatures, runs the CMAP and TAHOE batch
screening, summarizes the cross-disease results, and stores the figures used in
the manuscript.

## What is in this folder

- `data/`
  CREEDS-specific inputs and processed signature files.
- `scripts/`
  CREEDS-specific processing, execution, analysis, and figure-generation
  scripts.
- `results/`
  Per-disease batch result folders plus preserved downstream result tables used
  by the figure scripts.
- `analysis/`
  Cross-disease summary outputs and the curated workbook used by the main
  across-disease figure.
- `figures/`
  Final figure files generated from the CREEDS workflow.

## Shared inputs used by this workflow

- [data/drug_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_signatures)
- [data/drug_evidence/open_targets](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_evidence/open_targets)
- [data/gene_id_conversion_table.tsv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/gene_id_conversion_table.tsv)

## Reproducibility audit

The curated tree supports a script-driven rerun of the core CREEDS workflow:

1. raw CREEDS export files in `creeds/data/raw_creeds_exports/`
2. per-disease extracted signatures in `creeds/data/manual_signatures_extracted/`
3. standardized signatures in `creeds/data/manual_signatures_standardized/`
4. batch CMAP and TAHOE results in `creeds/results/manual_standardized_all_diseases_results/`
5. cross-disease CSV and JSON summaries in `creeds/analysis/manual_standardized_all_diseases_analysis/`

Two parts of the tree should be treated as preserved companion artifacts rather
than outputs rebuilt end to end by one script in this folder:

- [creeds/data/manual_signatures_shared_genes](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/manual_signatures_shared_genes)
  is a preserved reference dataset. The shared gene universe itself can be
  regenerated with
  [compare_tahoe_cmap.py](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/analysis/compare_tahoe_cmap.py),
  but the exact script that wrote the full folder is not preserved in the
  curated tree.
- [CREEDS_Manual_All_Diseases_Analysis.xlsx](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/analysis/CREEDS_Manual_All_Diseases_Analysis.xlsx)
  is the preserved workbook used by
  [plot_analysis_across_diseases.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/visualization/plot_analysis_across_diseases.R).
  The script-generated analysis layer is the CSV and JSON output in
  [manual_standardized_all_diseases_analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/analysis/manual_standardized_all_diseases_analysis).

## Step-by-step replication

Run the commands below from
`/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis`.

### 1. Confirm the required inputs are present

You need:

- CREEDS raw exports in
  [raw_creeds_exports](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/raw_creeds_exports)
  including:
  `disease_signatures-v1.0.json`,
  `disease_signatures-v1.0.csv`,
  `disease_signatures-p1.0.json`,
  and `disease_signatures-p1.0.csv`
- CMAP and TAHOE signatures in
  [data/drug_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_signatures)
- Open Targets evidence in
  [data/drug_evidence/open_targets](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_evidence/open_targets)
- the `CDRPipe` package installed and available to `Rscript`

### 2. Extract one CREEDS signature file per disease

```bash
python creeds/scripts/processing/process_creeds_signatures.py
```

This writes the extracted disease signatures to
[manual_signatures_extracted](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/manual_signatures_extracted).

### 3. Standardize the extracted signatures

```bash
python creeds/scripts/processing/standardize_creeds_signatures.py
```

This writes the standardized signatures used by the batch run to
[manual_signatures_standardized](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/manual_signatures_standardized).

### 4. Run the CMAP and TAHOE batch analysis

```bash
Rscript scripts/execute/run_batch_from_config.R \
  --config_file creeds/scripts/execute/creeds_manual_config_all_avg.yml
```

This config now starts from disease `1` and writes:

- per-disease result folders to
  [manual_standardized_all_diseases_results](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/results/manual_standardized_all_diseases_results)
- report files to
  [manual_standardized_all_diseases_analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/analysis/manual_standardized_all_diseases_analysis)

### 5. Build the cross-disease summary tables

```bash
python creeds/scripts/analysis/extract_pipeline_results_analysis.py \
  --input_dir creeds/results/manual_standardized_all_diseases_results \
  --output_dir creeds/analysis/manual_standardized_all_diseases_analysis
```

This produces the analysis summary, drug-list, and detail exports used for the
CREEDS cross-disease comparisons.

### 6. Review the curated workbook used for the manuscript summary figure

Open:

- [CREEDS_Manual_All_Diseases_Analysis.xlsx](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/analysis/CREEDS_Manual_All_Diseases_Analysis.xlsx)

This workbook is preserved in the repository because it is the direct input for
the manuscript-level across-disease figure.

### 7. Regenerate the CREEDS figures

```bash
Rscript creeds/scripts/visualization/plot_disease_signature_filtering.R
Rscript creeds/scripts/visualization/plot_analysis_across_diseases.R
python creeds/scripts/visualization/plot_biological_concordance.py
python creeds/scripts/visualization/plot_drug_class_distributions.py
```

The figures are written to
[creeds/figures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/figures).

## Figure inputs used by the live scripts

- [plot_disease_signature_filtering.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/visualization/plot_disease_signature_filtering.R)
  uses [manual_signatures_standardized](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/manual_signatures_standardized)
  and [signature_gene_counts_across_stages.csv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/signature_gene_counts_across_stages.csv).
- [plot_analysis_across_diseases.R](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/visualization/plot_analysis_across_diseases.R)
  uses [CREEDS_Manual_All_Diseases_Analysis.xlsx](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/analysis/CREEDS_Manual_All_Diseases_Analysis.xlsx).
- [plot_biological_concordance.py](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/visualization/plot_biological_concordance.py)
  uses [biological_concordance](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/results/biological_concordance).
- [plot_drug_class_distributions.py](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/scripts/visualization/plot_drug_class_distributions.py)
  uses [drug_class_distributions](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/results/drug_class_distributions).
- [recall_precision](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/results/recall_precision)
  stores the precision-recall validation tables derived from the CREEDS
  discovery outputs.

## Related guides

- [creeds/data/README.md](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/data/README.md)
- [creeds/results/README.md](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/results/README.md)
