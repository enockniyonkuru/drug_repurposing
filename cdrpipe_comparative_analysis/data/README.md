# shared data

This folder contains inputs used by more than one study workflow.

## Included here

- `drug_signatures/`
  Shared CMAP and Tahoe platform data.
- `drug_evidence/open_targets/`
  Shared Open Targets disease and drug evidence tables.
- `gene_id_conversion_table.tsv`
  Shared Entrez conversion table used by the batch runs.
- `shared_drugs_cmap_tahoe.csv`
  Shared cross-platform drug-overlap reference.

Shared figures should read from these canonical data folders directly rather
than from a duplicated `figure_inputs/` copy.
