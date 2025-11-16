# HPC Part 3 Script Evaluation Report
## UCSF Wynton HPC Compatibility Analysis

**Script:** `run_hpc_part3_convert_to_rdata.sh`  
**Date:** November 9, 2025  
**Evaluator:** Cline AI Assistant

---

## Executive Summary

⚠️ **CRITICAL ISSUES FOUND** - The script has **major compatibility problems** with UCSF Wynton Protected HPC environment and will **NOT work as written**.

**Status:** 🔴 **REQUIRES SIGNIFICANT MODIFICATIONS**

---

## Detailed Analysis

### 1. ❌ CRITICAL: R Module Loading Issue

**Problem:**
```bash
# Load R module
module load R
```

**Why it fails:**
- According to `HPC_SETUP_GUIDE.md`, **Protected nodes don't have R modules**
- The guide explicitly states: "Protected nodes don't have R modules; use **Singularity** to run Rocker R 4.3.1"
- This command will fail with "module: command not found" or "R module not available"

**Impact:** Script will fail immediately at environment setup stage.

---

### 2. ❌ CRITICAL: Missing Singularity Integration

**Problem:**
The script runs R directly:
```bash
Rscript "$SCRIPT_PATH"
```

**Required approach:**
```bash
singularity exec ~/rocker_r431.sif Rscript "$SCRIPT_PATH"
```

**Why it matters:**
- R is only available through Singularity containers on Protected nodes
- Without Singularity wrapper, the Rscript command won't be found

---

### 3. ⚠️ WARNING: Grid Engine vs SLURM Scheduler

**Current directives:**
```bash
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N hpc_part3_rdata
#$ -hold_jid hpc_part2_rank
#$ -pe smp 1
#$ -l mem_free=250G
#$ -l scratch=50G
#$ -l h_rt=12:00:00
#$ -M enock.niyonkuru@ucsf.edu
#$ -m bea
```

**Analysis:**
- These are **Grid Engine (SGE)** directives (using `#$`)
- UCSF Wynton uses SGE, so this is **CORRECT** ✅
- However, need to verify if Protected cluster uses same scheduler

---

### 4. ✅ GOOD: Job Dependencies

**Correct usage:**
```bash
#$ -hold_jid hpc_part2_rank
```

This properly waits for Part 2 to complete before starting Part 3.

---

### 5. ⚠️ WARNING: Resource Allocation

**Current:**
- 1 core
- 250 GB RAM on single core
- 50 GB scratch
- 12 hour runtime

**Concerns:**
1. **250GB on 1 core** - This is unusual. Most HPC systems allocate memory per core (e.g., 16GB/core)
2. May need to request multiple cores to get 250GB total memory
3. Check if Wynton allows such high memory on single core

**From Part 2 script:**
```bash
#$ -pe smp 16
#$ -l mem_free=16G  # 16GB per core = 256GB total
```

**Recommendation:** Consider similar approach:
```bash
#$ -pe smp 16
#$ -l mem_free=16G  # 256GB total
```

---

### 6. ✅ GOOD: R Script Dependencies

**R script requires:**
```r
library(arrow)
```

**Analysis:**
- The `arrow` package must be installed in the Singularity R environment
- Need to verify package availability or install to `~/R/library`

---

### 7. ⚠️ WARNING: Path Navigation

**Current:**
```bash
cd ../scripts || {
    echo "❌ ERROR: Could not navigate to scripts directory"
    exit 1
}
```

**Concerns:**
- Assumes script is run from `tahoe_cmap_analysis/singularity/` directory
- The `#$ -cwd` directive uses current working directory
- If submitted from different location, paths will break

**Recommendation:** Use absolute paths or verify working directory

---

### 8. ✅ GOOD: Data Flow

**Input:** `../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet`  
**Output:** `../data/drug_signatures/tahoe/tahoe_signatures.RData`

The data flow from Part 2 → Part 3 is correctly configured.

---

### 9. ⚠️ WARNING: Missing Account Specification

**Part 2 script has:**
```bash
# (Not present in Part 2 either)
```

**HPC_SETUP_GUIDE.md shows:**
```bash
#$ -A sirota_lab
```

**Recommendation:** Add account specification:
```bash
#$ -A sirota_lab
```

---

## Required Fixes

### Fix 1: Replace Module Loading with Singularity

**BEFORE:**
```bash
echo ""
echo "Setting up R environment..."

# Load R module
module load R

echo ""
echo "R version:"
R --version
```

**AFTER:**
```bash
echo ""
echo "Setting up R environment..."

# Define Singularity image path
SINGULARITY_IMAGE="$HOME/rocker_r431.sif"

# Check if image exists
if [ ! -f "$SINGULARITY_IMAGE" ]; then
    echo "❌ ERROR: Singularity image not found at $SINGULARITY_IMAGE"
    echo "   Please pull the image first:"
    echo "   singularity pull ~/rocker_r431.sif docker://rocker/r-ver:4.3.1"
    exit 1
fi

echo ""
echo "R version:"
singularity exec "$SINGULARITY_IMAGE" R --version
```

---

### Fix 2: Update Rscript Execution

**BEFORE:**
```bash
Rscript "$SCRIPT_PATH"
```

**AFTER:**
```bash
singularity exec "$SINGULARITY_IMAGE" Rscript "$SCRIPT_PATH"
```

---

### Fix 3: Add Account Specification

**Add after email directives:**
```bash
#$ -M enock.niyonkuru@ucsf.edu
#$ -m bea
#$ -A sirota_lab                     # Account for billing
```

---

### Fix 4: Consider Memory Allocation Strategy

**Option A - Keep single core (if supported):**
```bash
#$ -pe smp 1
#$ -l mem_free=250G
```

**Option B - Use multiple cores (safer):**
```bash
#$ -pe smp 16
#$ -l mem_free=16G    # 256GB total
```

---

### Fix 5: Use Absolute Paths

**BEFORE:**
```bash
cd ../scripts || {
    echo "❌ ERROR: Could not navigate to scripts directory"
    exit 1
}
```

**AFTER:**
```bash
# Define base directory
BASE_DIR="/wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing"
SCRIPT_DIR="${BASE_DIR}/tahoe_cmap_analysis/scripts"

cd "$SCRIPT_DIR" || {
    echo "❌ ERROR: Could not navigate to scripts directory: $SCRIPT_DIR"
    exit 1
}
```

---

## Complete Corrected Script

See the corrected version in the next section.

---

## Testing Checklist

Before running on HPC:

- [ ] Verify Singularity image exists: `ls -lh ~/rocker_r431.sif`
- [ ] Test R in Singularity: `singularity exec ~/rocker_r431.sif R --version`
- [ ] Verify arrow package: `singularity exec ~/rocker_r431.sif Rscript -e "library(arrow)"`
- [ ] Check Part 2 output exists: `ls -lh ../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet`
- [ ] Verify output directory writable: `touch ../data/drug_signatures/tahoe/test.txt && rm ../data/drug_signatures/tahoe/test.txt`
- [ ] Test on dev node first: `ssh pdev1.wynton.ucsf.edu`
- [ ] Submit Part 2 first, then Part 3 with dependency

---

## Additional Recommendations

1. **Install arrow package in Singularity R:**
   ```bash
   singularity exec ~/rocker_r431.sif R -e "install.packages('arrow', repos='https://cloud.r-project.org')"
   ```

2. **Create a setup script** to verify all prerequisites before submission

3. **Add checkpoint validation** to verify Part 2 output before processing

4. **Consider splitting into smaller chunks** if memory issues persist

5. **Monitor memory usage** during test runs to optimize allocation

---

## Compatibility Matrix

| Component | Status | Notes |
|-----------|--------|-------|
| Scheduler (SGE) | ✅ | Correct directives |
| R Module | ❌ | Must use Singularity |
| Singularity | ❌ | Not implemented |
| Job Dependencies | ✅ | Correct hold_jid |
| Memory Allocation | ⚠️ | May need adjustment |
| Path Handling | ⚠️ | Should use absolute paths |
| Account Billing | ⚠️ | Missing -A flag |
| Data Flow | ✅ | Correct input/output |
| R Script | ✅ | Compatible with arrow |

---

## Conclusion

The script **CANNOT run as-is** on UCSF Wynton Protected HPC. The primary issues are:

1. **Critical:** Attempts to load R module instead of using Singularity
2. **Critical:** Missing Singularity wrapper for Rscript execution
3. **Important:** Missing account specification for billing
4. **Recommended:** Should use absolute paths for robustness

**Estimated fix time:** 15-30 minutes  
**Risk level after fixes:** Low (standard HPC workflow)

---

## Next Steps

1. Apply the fixes outlined above
2. Test on development node (`pdev1`)
3. Verify arrow package installation
4. Run Part 2 first to generate checkpoint
5. Submit Part 3 with corrected script
6. Monitor logs in `~/hpc_logs/`

---

**Report Generated:** November 9, 2025  
**Contact:** enock.niyonkuru@ucsf.edu
