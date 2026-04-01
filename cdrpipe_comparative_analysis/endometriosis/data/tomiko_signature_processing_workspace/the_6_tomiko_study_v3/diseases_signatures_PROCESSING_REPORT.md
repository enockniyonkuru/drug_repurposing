# Tomiko Disease Signatures - Step 1 Processing Report

**Date:** December 18, 2025  
**Source File:** `tomiko_disease_signatures.xlsx`  
**Processing Method:** Automated extraction and filtering  

---

## Processing Summary

Extracted and filtered 6 disease signatures from the Tomiko study following **Step 1: Data processing and disease signature construction**.

### Applied Filters

1. **Column Selection:**
   - `gene_symbol`
   - `adj.P.Val`
   - `logFC (Control/Disease)` → renamed to `logfc_dz`

2. **Disease Level Filters:**
   - `adj.P.Val < 0.05`
   - `|logfc_dz| > 1.1` (absolute value)

3. **Processing:**
   - Genes ranked by `logfc_dz` in descending order
   - Ranked list preserved for CMap query (Step 2)

---

## Results Summary

| Disease Signature | Genes Before | Genes After | Retained (%) |
|---|---:|---:|---:|
| DvC_unstratified | 1,369 | 879 | 64.2% |
| Stages I-II vs Control | 2,222 | 1,461 | 65.7% |
| Stages III-IV vs Control | 1,164 | 745 | 64.0% |
| DvC_PEsamples | 2,572 | 1,760 | 68.4% |
| DvC_ESEsamples | 539 | 324 | 60.1% |
| DvC_MSEsamples | 1,402 | 942 | 67.2% |
| **TOTAL** | **9,268** | **6,111** | **65.9%** |

---

## Generated Files

All filtered disease signatures have been saved as CSV files in this directory:

1. **DvC_unstratified.csv** (879 genes)
2. **Stages_I-II_vs_Control.csv** (1,461 genes)
3. **Stages_III-IV_vs_Control.csv** (745 genes)
4. **DvC_PEsamples.csv** (1,760 genes)
5. **DvC_ESEsamples.csv** (324 genes)
6. **DvC_MSEsamples.csv** (942 genes)

---

## File Format

Each CSV file contains the following columns (in order):

| Column | Description |
|---|---|
| `gene_symbol` | Gene identifier |
| `adj.P.Val` | Adjusted p-value (all < 0.05) |
| `logfc_dz` | Log fold change control/disease (all \|value\| > 1.1) |

**Sorting:** Genes are sorted by `logfc_dz` in descending order for ranking in downstream CMap analysis.

---

## Next Steps

**Step 2 - Disease Signature Ranking and CMap Query:**
- Use the ranked filtered disease signatures to query CMap
- Compute connectivity scores using rank-based Kolmogorov-Smirnov statistic
- Produces reversal score per drug per disease signature

**Step 3 - Reversal Direction Filter:**
- Keep drugs with reversal score < 0

**Step 4 - Statistical Significance:**
- Keep drugs with q-value < 0.0001

---

## Notes

- All filters were applied **before** any drug scoring (as per protocol)
- Gene direction (sign of logfc_dz) is preserved for downstream connectivity analysis
- CSV files are ready for CMap integration or external analysis tools
