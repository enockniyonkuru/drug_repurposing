# Shared Resources

Cross-workflow resources used by multiple case studies.

## Contents

```
shared/
├── gene_id_conversion_table.tsv   # Gene symbol → Entrez ID mapping
├── shared_drugs_cmap_tahoe.csv    # Drugs present in both CMap and TAHOE
├── figure_provenance_manifest.csv # Complete figure input tracking
└── scripts/
    └── execute/                   # Batch run orchestration
        ├── run_batch_from_config.R
        ├── run_cdrpipe_batch.R
        ├── apply_percentile_filter.R
        └── convert_signatures_to_rds.R
```

## Data Files

| File | Description |
|------|-------------|
| `gene_id_conversion_table.tsv` | Mapping between gene symbols and Entrez IDs |
| `shared_drugs_cmap_tahoe.csv` | List of drugs with signatures in both platforms |
| `figure_provenance_manifest.csv` | Tracks all manuscript figures to their input data |

## Batch Execution Scripts

The `scripts/execute/` folder contains the shared CDRPipe batch runner used by all case studies.

### Usage

```bash
# Run any case study batch
Rscript shared/scripts/execute/run_batch_from_config.R \
  --config_file <path_to_config.yml>
```

### Scripts

| Script | Description |
|--------|-------------|
| `run_batch_from_config.R` | Main batch runner, reads YAML config |
| `run_cdrpipe_batch.R` | Lower-level batch execution |
| `apply_percentile_filter.R` | Apply percentile-based gene filtering |
| `convert_signatures_to_rds.R` | Convert signatures between formats |

See [README_BATCH_CONFIG.md](scripts/execute/README_BATCH_CONFIG.md) for config file documentation.
