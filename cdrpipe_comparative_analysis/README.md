# cdrpipe comparative analysis

This directory is organized so each study can be followed from inputs to scripts to results, analysis, and final figures.

## Top-level layout

```text
cdrpipe_comparative_analysis/
├── autoimmune/
│   ├── analysis/
│   ├── data/
│   ├── figures/
│   ├── results/
│   └── scripts/
├── creeds/
│   ├── analysis/
│   ├── data/
│   ├── figures/
│   ├── results/
│   └── scripts/
├── endometriosis/
│   ├── analysis/
│   ├── data/
│   ├── figures/
│   ├── results/
│   └── scripts/
├── data/
│   ├── drug_evidence/
│   ├── drug_signatures/
│   ├── gene_id_conversion_table.tsv
│   └── shared_drugs_cmap_tahoe.csv
├── figures/
│   └── platform_comparison/
└── scripts/
    ├── analysis/
    ├── execute/
    ├── extraction/
    ├── processing/
    └── visualization/
```

## What lives where

- `autoimmune/`
  Autoimmune case-study inputs, configs, analysis tables, and figures.
- `creeds/`
  The CREEDS all-diseases workflow, including raw exports, standardized signatures, batch outputs, cross-disease summaries, and CREEDS-specific figures.
- `endometriosis/`
  Endometriosis-specific signatures, execution configs, analysis outputs, and figures.
- `data/`
  Shared inputs used by more than one study. This includes platform signatures,
  Open Targets evidence tables, and gene conversion resources.
- `scripts/`
  Shared extraction, processing, execution, analysis, and visualization scripts that are not owned by a single study.
- `figures/`
  Shared figure outputs. At the moment this folder is used for the cross-study platform comparison figures.

## Recommended starting points

- CREEDS workflow:
  [creeds/README.md](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/creeds/README.md)
- Shared execution entrypoints:
  [scripts/execute/README_BATCH_CONFIG.md](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/scripts/execute/README_BATCH_CONFIG.md)
- Shared figure provenance:
  [figures/figure_provenance_manifest.csv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/figures/figure_provenance_manifest.csv)

## Core shared inputs

- [drug_signatures](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_signatures)
- [drug_evidence](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/drug_evidence)
- [gene_id_conversion_table.tsv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/gene_id_conversion_table.tsv)
- [shared_drugs_cmap_tahoe.csv](/Users/enockniyonkuru/Desktop/drug_repurposing/cdrpipe_comparative_analysis/data/shared_drugs_cmap_tahoe.csv)

## Notes

- Study-specific scripts now live inside the matching study folder.
- Figure-input bundles live with the study that owns them. Shared platform
  figures now read directly from the canonical shared data folders instead of a
  duplicated figure-input copy.
- Legacy scripts that no longer drive the current study figures were moved into `dump/old_tahoe_cmap_analysis_mar_30/`.
