# Standardized CREEDS Signatures

Disease signatures from the [CREEDS](https://maayanlab.cloud/CREEDS/) crowdsourced database.

## Files

| File | Description |
|------|-------------|
| `creeds_endometriosis_signature.csv` | Endometriosis vs. control |
| `creeds_endometriosis_of_ovary_signature.csv` | Ovarian endometriosis vs. control |
| `creeds_endometrial_cancer_signature.csv` | Endometrial cancer vs. control |

## Standardization

- Source: CREEDS API (crowd-sourced differential expression)
- Gene retention rate: 100% (all genes mapped to CDRPipe reference)
- Format: CSV with columns `gene_symbol`, `logFC`
- Used in: **Experiment 1** (CDRPipe default parameters)
