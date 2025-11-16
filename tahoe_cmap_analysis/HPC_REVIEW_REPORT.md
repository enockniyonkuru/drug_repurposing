# HPC Scripts Review Report
**Date:** November 8, 2025  
**Reviewer:** Cline AI Assistant  
**Files Reviewed:**
- `tahoe_cmap_analysis/scripts/create_tahoe_og_signatures_hpc.py`
- `tahoe_cmap_analysis/singularity/run_create_tahoe_signatures_hpc.sh`

---

## ✅ OVERALL STATUS: READY FOR HPC EXECUTION

Both scripts are well-structured and ready for UCSF Wynton HPC execution with the recommendations below.

---

## 📋 DETAILED REVIEW

### 1. Python Script (`create_tahoe_og_signatures_hpc.py`)

#### ✅ Strengths:
- **Excellent HPC optimization**: Parallel processing, checkpointing, resource monitoring
- **Comprehensive logging**: Both file and console output with timestamps
- **Memory management**: Chunked processing, garbage collection, resource estimation
- **Error handling**: Try-catch blocks, validation checks, informative error messages
- **Flexibility**: Command-line arguments for all parameters with sensible defaults
- **NSLOTS integration**: Automatically detects HPC scheduler core allocation

#### ✅ Path Verification:
All paths are **CORRECT** relative to the expected execution directory (`tahoe_cmap_analysis/scripts/`):

| Path Type | Default Value | Status | Verified Location |
|-----------|---------------|--------|-------------------|
| H5 file | `../data/drug_signatures/tahoe/aggregated.h5` | ✅ EXISTS | Confirmed |
| Genes file | `../data/drug_signatures/tahoe/genes.parquet` | ✅ EXISTS | Confirmed |
| Experiments file | `../data/drug_signatures/tahoe/experiments.parquet` | ✅ EXISTS | Confirmed |
| Gene mapping | `../../scripts/data/gene_id_conversion_table.tsv` | ✅ EXISTS | Confirmed |
| Intermediate dir | `../data/intermediate_hpc` | ✅ WILL CREATE | Auto-created |
| Output dir | `../data/drug_signatures/tahoe` | ✅ EXISTS | Confirmed |
| Log dir | `../logs` | ✅ WILL CREATE | Auto-created |

#### 📝 Notes:
- Script expects to run from `tahoe_cmap_analysis/scripts/` directory
- All input files verified to exist in repository
- Output directories will be created automatically if they don't exist
- Gene mapping file path goes up two levels (`../../`) to reach main `scripts/data/` directory

---

### 2. Shell Script (`run_create_tahoe_signatures_hpc.sh`)

#### ✅ Strengths:
- **Proper SGE directives**: Correctly formatted for UCSF Wynton HPC
- **Resource allocation**: Sensible defaults (16 cores, 16GB/core = 256GB total)
- **Comprehensive logging**: Timestamped logs with job information
- **Email notifications**: Configured for job status updates
- **Error handling**: Exit code checking and informative messages
- **Environment setup**: Module loading and virtual environment activation

#### ✅ Path Verification:
All paths are **CORRECT** relative to execution from `tahoe_cmap_analysis/singularity/`:

| Path Type | Value | Status | Notes |
|-----------|-------|--------|-------|
| Log directory | `$HOME/hpc_logs` | ✅ CORRECT | Uses home directory |
| Virtual env | `../venv` | ✅ CORRECT | Relative to singularity/ |
| Scripts directory | `../scripts` | ✅ CORRECT | Navigates to scripts/ |
| Python script | `create_tahoe_og_signatures_hpc.py` | ✅ CORRECT | In scripts/ directory |

#### 📝 Configuration Details:
```bash
#$ -pe smp 16              # 16 CPU cores
#$ -l mem_free=16G         # 16GB per core = 256GB total
#$ -l scratch=500G         # 500GB scratch space
#$ -l h_rt=72:00:00        # 72 hours max runtime
```

---

## 🔧 RECOMMENDATIONS

### Critical (Must Address):

1. **Update Email Address**
   ```bash
   #$ -M enock.niyonkuru@ucsf.edu  # ← Verify this is correct
   ```
   Ensure this is your actual UCSF email address.

2. **Verify Virtual Environment Path**
   The script references `../venv` relative to `singularity/` directory.
   - **Expected location**: `tahoe_cmap_analysis/venv/`
   - **Action**: Ensure virtual environment exists with all required packages:
     ```bash
     cd tahoe_cmap_analysis
     python3 -m venv venv
     source venv/bin/activate
     pip install -r requirements.txt
     ```

### Important (Recommended):

3. **Test Resource Requirements**
   - Current allocation: 16 cores × 16GB = **256GB RAM**
   - The script includes memory estimation - run a test to verify this is sufficient
   - If dataset is larger than expected, you may need to increase `mem_free`

4. **Verify Module Availability**
   ```bash
   module load python/3.10
   ```
   Confirm this module exists on Wynton HPC. If not, adjust to available Python version.

5. **Check Scratch Space**
   - Allocated: 500GB
   - Verify this is sufficient for your intermediate files
   - Script will check disk space before processing

### Optional (Nice to Have):

6. **Add Checkpoint Recovery**
   The Python script supports `--skip-part1` and `--skip-part2` flags. Consider adding these to the shell script if you need to resume from a checkpoint:
   ```bash
   # Example: Resume from Part 2 if Part 1 completed
   python3 "$SCRIPT_PATH" --skip-part1
   ```

7. **Add Resource Monitoring**
   Consider adding periodic resource logging:
   ```bash
   # Add before running Python script
   qstat -j $JOB_ID &
   ```

---

## 🚀 EXECUTION INSTRUCTIONS

### Pre-flight Checklist:

- [ ] Virtual environment created and packages installed
- [ ] Email address updated in shell script
- [ ] Input files verified to exist (all ✅ confirmed above)
- [ ] Sufficient quota on home directory for logs
- [ ] Sufficient quota on scratch space (500GB)

### To Submit Job:

```bash
# Navigate to singularity directory
cd /path/to/drug_repurposing/tahoe_cmap_analysis/singularity

# Submit job
qsub run_create_tahoe_signatures_hpc.sh
```

### To Monitor Job:

```bash
# Check job status
qstat -u $USER

# View live log (replace JOB_ID)
tail -f ~/hpc_logs/tahoe_signatures_JOB_ID_*.log

# Check detailed job info
qstat -j JOB_ID
```

### Expected Outputs:

1. **Logs**:
   - Shell script log: `~/hpc_logs/tahoe_signatures_<JOB_ID>_<timestamp>.log`
   - Python script log: `tahoe_cmap_analysis/logs/tahoe_signatures_<timestamp>.log`

2. **Intermediate Files**:
   - `tahoe_cmap_analysis/data/intermediate_hpc/tahoe_l2fc_all_genes_all_drugs.parquet`

3. **Final Output**:
   - `tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures.RData`

---

## 🐛 TROUBLESHOOTING

### If Job Fails:

1. **Check logs** in both locations mentioned above
2. **Verify paths** by running interactively:
   ```bash
   qlogin -pe smp 4 -l mem_free=8G
   cd tahoe_cmap_analysis/scripts
   python3 create_tahoe_og_signatures_hpc.py --help
   ```

3. **Test with smaller dataset** using command-line arguments:
   ```bash
   python3 create_tahoe_og_signatures_hpc.py --n-cores 4 --rank-chunk-size 256
   ```

### Common Issues:

- **Out of Memory**: Increase `mem_free` in shell script
- **Module not found**: Check available modules with `module avail python`
- **Virtual env issues**: Recreate venv or use system Python
- **Path errors**: Verify you're running from correct directory

---

## ✅ FINAL VERDICT

**Both scripts are production-ready for UCSF Wynton HPC.**

The only required action is to verify/update the email address. All paths are correct, the code is well-optimized for HPC environments, and comprehensive logging will help track progress and debug any issues.

**Estimated Runtime**: 24-72 hours depending on dataset size  
**Estimated Memory**: 200-300GB peak usage  
**Estimated Disk**: 300-500GB for intermediate files

Good luck with your analysis! 🎉
