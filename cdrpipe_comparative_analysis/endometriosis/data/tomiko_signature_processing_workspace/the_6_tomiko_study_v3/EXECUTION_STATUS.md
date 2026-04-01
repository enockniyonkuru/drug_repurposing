# CDRPipe Analysis - Execution Status

**Started:** December 18, 2025 ~18:07  
**Config:** `6_tomiko_endo_v3.yml`  
**Disease Signatures:** 6 (Tomiko Study Design v3)

## Status

✅ **Running in background** (PID: 56655)  
📍 **Progress:** 2 diseases completed, analysis continuing...

## Diseases

| # | Disease | Status | Results |
|---|---------|--------|---------|
| 1 | tomiko_dvc_esesamples | ✅ Completed | tomiko_dvc_esesamples_CMAP_* |
| 2 | tomiko_dvc_msesamples | ✅ Completed | tomiko_dvc_msesamples_CMAP_* |
| 3 | tomiko_dvc_pesamples | ⏳ Processing | - |
| 4 | tomiko_dvc_unstratified | ⏳ Queued | - |
| 5 | tomiko_stages_i_ii_vs_control | ⏳ Queued | - |
| 6 | tomiko_stages_iii_iv_vs_control | ⏳ Queued | - |

## Configuration Applied

- **Step 3:** Reversal score < 0 ✅
- **Step 4:** Q-value < 0.0001 ✅
- **Gene Filtering:** Disabled (using all filtered genes from Step 1)
- **Output Location:** `6_tomiko_drpipe_results_v3/`

## Monitoring

**Log file:** `run_analysis.log`

```bash
# Monitor progress
tail -f /Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/endo_disease_signatures/the_6_tomiko_study_v3/run_analysis.log

# Check process
ps aux | grep "56655"

# Count completed results
ls -1 /Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/endo_disease_signatures/the_6_tomiko_study_v3/6_tomiko_drpipe_results_v3 | grep -c "CMAP"
```

**Expected completion time:** ~30-60 minutes depending on system load

---

## Notes

- Disease 1 was processed earlier and results reused (skip_existing=TRUE)
- All 6 disease signatures are correctly named and loaded
- Pipeline is applying all filters as specified in the study design
- Results will be saved with both CMAP and TAHOE drug scorings
