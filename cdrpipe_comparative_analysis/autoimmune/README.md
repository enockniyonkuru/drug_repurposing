# autoimmune workflow

This folder contains the autoimmune case-study workflow materials.

## Structure

- `data/`
  Autoimmune disease-signature inputs and the figure-input bundle used by the autoimmune figure script.
- `scripts/`
  Autoimmune-specific execution, analysis, and figure-generation scripts.
- `results/`
  Target location for autoimmune batch outputs.
- `analysis/`
  The preserved workbook, summary tables, and recovered-drug outputs.
- `figures/`
  Final autoimmune figure outputs.

## Main analysis

- [autoimmune_recovery_analysis](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/analysis/autoimmune_recovery_analysis)

## Main config

- [case_study_v2.yml](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/scripts/execute/case_study_v2.yml)

## Figures

- Final figures:
  [autoimmune/figures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/figures)
- Figure input bundle:
  [autoimmune/data/figure_inputs](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/autoimmune/data/figure_inputs)

## Shared dependencies

- [data/drug_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_signatures)
- [data/drug_evidence/open_targets](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_evidence/open_targets)
- [data/gene_id_conversion_table.tsv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/gene_id_conversion_table.tsv)
