# Configuration Adjustment Summary - Steps 3 & 4

**Date:** December 18, 2025  
**Config File:** `tahoe_cmap_analysis/scripts/execution/batch_configs/6_tomiko_endo_v3.yml`  
**Study Design Reference:** `tomiko_study_design.md`

---

## Overview

The configuration file has been updated to implement **Steps 3 and 4** of the Tomiko Study Design v3 pipeline for drug repurposing analysis.

---

## Configuration Changes

### 1. Disease Signatures Input

**Updated:** Disease directory path

```yaml
disease:
  source: "Tomiko Endometriosis Signatures - Study Design v3"
  directory: "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/endo_disease_signatures/the_6_tomiko_study_v3/6_tomiko_disease_signatures_v3"
```

**Input:** 6 processed disease signatures (CSV files)
- DvC_unstratified.csv (879 genes)
- Stages_I-II_vs_Control.csv (1,461 genes)
- Stages_III-IV_vs_Control.csv (745 genes)
- DvC_PEsamples.csv (1,760 genes)
- DvC_ESEsamples.csv (324 genes)
- DvC_MSEsamples.csv (942 genes)

---

### 2. Step 3: Reversal Direction Filter

**Added:** Reversal score threshold parameter

```yaml
analysis:
  # Step 3: Reversal direction filter
  # Keep drugs with reversal score < 0
  # This ensures the drug OPPOSES the disease transcriptional state
  # (Filter is applied AFTER connectivity scoring, not on disease genes)
  reversal_score_threshold: 0  # Keep scores < 0 (negative reversal)
```

**Requirement:**
- ✅ Reversal score < 0
- ✅ Ensures drug opposes disease transcriptional state
- ✅ Applied AFTER connectivity scoring (Step 2)

---

### 3. Step 4: Statistical Significance Cutoff

**Updated:** Q-value significance threshold

```yaml
analysis:
  # Step 4: Apply final significance threshold - q-value < 0.0001
  # This removes weak or unstable drug-disease associations
  qval_threshold: 0.0001
```

**Previous:** 0.05  
**New:** 0.0001

**Requirement:**
- ✅ Q-value < 0.0001
- ✅ Removes weak or unstable drug-disease associations
- ✅ Final significance cutoff in pipeline

---

### 4. Output Configuration

**Updated:** Results directory path

```yaml
output:
  root_directory: "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/endo_disease_signatures/the_6_tomiko_study_v3/6_tomiko_drpipe_results_v3"
  report_directory: "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/endo_disease_signatures/the_6_tomiko_study_v3"
  report_prefix: "6_tomiko_study_v3"
```

**Output Location:**
- Results saved to: `6_tomiko_drpipe_results_v3/`
- Reports saved to: `the_6_tomiko_study_v3/`

---

## Pipeline Filters - Complete Summary

### Disease Gene Level (Steps 1-2)
- adj.P.Val < 0.05
- |logfc_dz| > 1.1
- Genes ranked by logfc_dz (preserved for connectivity)

### Drug Level (Steps 3-4)
- **Step 3:** Reversal score < 0 (negative correlation)
- **Step 4:** Q-value < 0.0001 (highly significant)

---

## Ready to Run

The configuration file is now ready to execute the CDRPipe analysis pipeline with:
- ✅ Correct input disease signatures
- ✅ Step 3 reversal direction filter enabled
- ✅ Step 4 strict significance threshold (0.0001)
- ✅ Results routed to correct output directory

**Next Action:** Run the CDRPipe analysis using this configuration file
