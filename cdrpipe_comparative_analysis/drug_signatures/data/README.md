# Drug Signature Inputs

This directory intentionally keeps only lightweight metadata in version control.

Removed from the public-facing copy:

- large CMAP and TAHOE signature matrices
- shared-gene RData/RDS exports
- parquet checkpoints used during preprocessing

Expected large files if you want to rerun the full pipeline locally:

- `cmap/cmap_signatures.RData`
- `cmap/cmap_signatures_shared_genes.RData`
- `cmap/cmap_signatures_shared_genes.rds`
- `tahoe/tahoe_signatures.RData`
- `tahoe/tahoe_signatures_shared_genes_only.RData`

Metadata retained here:

- `cmap/cmap_drug_experiments_new.csv`
- `cmap/cmap_probe_set_ids.csv`
- `tahoe/tahoe_drug_experiments_new.csv`

Place any restored large files back into the same subdirectories using the exact filenames above.
