# Replication Results Summary

## Objective
Replicate the creation of `drug_instances_unstratified.csv` from scratch and verify the results match the original.

## Process
The replication script ([replicate_drug_instances.R](replicate_drug_instances.R)) recreated the exact workflow from [code/unstratified/results_analysis.R](../code/unstratified/results_analysis.R) by:

1. Loading the pipeline results from `results.RData`
2. Loading CMap signatures and experiment metadata
3. Merging drug prediction scores with CMap experiment metadata
4. Filtering for valid (concordant) drug profiles with DrugBank IDs
5. Applying statistical thresholds:
   - FDR (q-value) < 0.0001
   - Reversed connectivity (cmap_score < 0)
6. Deduplicating by drug name, keeping the most negative (best) score
7. Sorting by cmap_score (most negative first)
8. Writing results to CSV

## Verification Results

✅ **REPLICATION SUCCESSFUL**

### File Comparison
- **Original file:** `code/unstratified/drug_instances_unstratified.csv`
- **Replicated file:** `replication/drug_instances_unstratified_replicated.csv`

### Metrics
| Metric | Result |
|--------|--------|
| Number of rows | 283 (282 drugs + 1 header) |
| Number of columns | 19 |
| MD5 Checksum (Original) | `02d86039fc38f0be0d1864f266f688e5` |
| MD5 Checksum (Replicated) | `02d86039fc38f0be0d1864f266f688e5` |
| Diff check | No differences found |

### Top 3 Drugs (Both files)
1. **fenoprofen** - cmap_score: -0.7655
2. **flumetasone** - cmap_score: -0.7511
3. **promazine** - cmap_score: -0.7157

## Conclusion
The replicated `drug_instances_unstratified.csv` is **byte-for-byte identical** to the original, confirming:
- The methodology is sound and reproducible
- All filtering, deduplication, and sorting steps are correctly implemented
- The 282 candidate endometriosis drugs have been accurately identified
