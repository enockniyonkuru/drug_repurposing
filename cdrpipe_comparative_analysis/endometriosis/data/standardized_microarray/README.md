# Standardized Microarray Signatures

Disease signatures derived from microarray gene expression studies of endometriosis.

## Files

| File | Description |
|------|-------------|
| `dvc_esesamples_signature.csv` | Eutopic secretory endometrium samples |
| `dvc_msesamples_signature.csv` | Mid-secretory endometrium samples |
| `dvc_pesamples_signature.csv` | Proliferative endometrium samples |
| `dvc_unstratified_signature.csv` | Unstratified (all phases combined) |
| `stages_i_ii_vs_control_signature.csv` | Endometriosis stages I–II vs. control |
| `stages_iii_iv_vs_control_signature.csv` | Endometriosis stages III–IV vs. control |

## Standardization

- Source: GEO microarray datasets (differential expression analysis)
- Gene retention rate: 100% (all genes mapped to CDRPipe reference)
- Format: CSV with columns `gene_symbol`, `logFC`
- Used in: **Experiment 1** (CDRPipe default parameters) and **Experiment 2** (Oskotsky replication, strict parameters)
