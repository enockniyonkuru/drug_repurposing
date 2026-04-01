# Standardized Single-Cell Signatures

Disease signatures derived from single-cell RNA-seq data of endometriosis tissue.

## Files

| File | Description |
|------|-------------|
| `ciliated_epithelia_proliferat_signature.csv` | Ciliated epithelia, proliferative phase |
| `ciliated_epithelia_secretory__signature.csv` | Ciliated epithelia, secretory phase |
| `endothelia_proliferative_deg._signature.csv` | Endothelia, proliferative phase |
| `endothelia_secretory_deg.rds_signature.csv` | Endothelia, secretory phase |
| `smooth_muscle_proliferative_d_signature.csv` | Smooth muscle, proliferative phase |
| `smooth_muscle_secretory_deg.r_signature.csv` | Smooth muscle, secretory phase |
| `stromal_fibroblast_proliferat_signature.csv` | Stromal fibroblast, proliferative phase |
| `stromal_fibroblast_secretory__signature.csv` | Stromal fibroblast, secretory phase |
| `unciliated_epithelia_prolifer_signature.csv` | Unciliated epithelia, proliferative phase |
| `unciliated_epithelia_secretor_signature.csv` | Unciliated epithelia, secretory phase |

## Standardization

- Source: Single-cell RNA-seq differential expression (5 cell types × 2 menstrual phases)
- Gene retention rate: ~23% (5,764 of 25,136 unique genes mapped to CDRPipe reference)
- Format: CSV with columns `gene_symbol`, `logFC`
- Used in: **Experiment 1** (CDRPipe default parameters)
