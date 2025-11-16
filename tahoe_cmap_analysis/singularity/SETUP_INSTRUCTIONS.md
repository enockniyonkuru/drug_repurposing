# Setup Instructions for HPC Part 3 Script

## Quick Start

Before running the Part 3 script on UCSF Wynton HPC, follow these steps:

---

## 1. Pull Singularity Image (One-time setup)

```bash
# Login to Wynton Protected
ssh enockniyonkuru@plog1.wynton.ucsf.edu

# Pull the Rocker R 4.3.1 image
singularity pull ~/rocker_r431.sif docker://rocker/r-ver:4.3.1
```

**Expected output:**
```
INFO:    Converting OCI blobs to SIF format
INFO:    Starting build...
...
INFO:    Creating SIF file...
```

**Verify:**
```bash
ls -lh ~/rocker_r431.sif
# Should show a file ~500-800 MB
```

---

## 2. Install Required R Packages

The R script requires the `arrow` package. Install it in the Singularity container:

```bash
# Create R library directory if it doesn't exist
mkdir -p ~/R/library

# Install arrow package
singularity exec ~/rocker_r431.sif R -e "install.packages('arrow', lib='~/R/library', repos='https://cloud.r-project.org')"
```

**Verify installation:**
```bash
singularity exec ~/rocker_r431.sif Rscript -e "library(arrow); cat('✅ arrow package loaded successfully\n')"
```

---

## 3. Test R Environment

```bash
# Test R version
singularity exec ~/rocker_r431.sif R --version

# Test Rscript
singularity exec ~/rocker_r431.sif Rscript -e "cat('Hello from R in Singularity!\n')"
```

---

## 4. Verify Directory Structure

```bash
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing

# Check that required directories exist
ls -la tahoe_cmap_analysis/scripts/
ls -la tahoe_cmap_analysis/data/intermediate_hpc/
ls -la tahoe_cmap_analysis/data/drug_signatures/tahoe/
```

---

## 5. Create Log Directory

```bash
mkdir -p ~/hpc_logs
```

---

## 6. Test on Development Node (Recommended)

Before submitting to the queue, test on a development node:

```bash
# Login to dev node
ssh pdev1.wynton.ucsf.edu

# Navigate to project
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/scripts

# Test R script with small data (if available)
singularity exec ~/rocker_r431.sif Rscript -e "library(arrow); cat('Environment ready!\n')"
```

---

## 7. Submit Jobs

### Option A: Submit Part 2 and Part 3 together

```bash
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/singularity

# Submit Part 2 (will run first)
qsub run_hpc_part2_rank_and_save_parquet.sh

# Submit Part 3 (will wait for Part 2 to finish due to -hold_jid)
qsub run_hpc_part3_convert_to_rdata_FIXED.sh
```

### Option B: Submit Part 3 only (if Part 2 already completed)

```bash
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/singularity

# Remove the dependency if Part 2 is already done
# Edit the script to comment out: #$ -hold_jid hpc_part2_rank

qsub run_hpc_part3_convert_to_rdata_FIXED.sh
```

---

## 8. Monitor Jobs

```bash
# Check job status
qstat -u enockniyonkuru

# View job details
qstat -j <job_id>

# Monitor log file in real-time
tail -f ~/hpc_logs/hpc_part3_rdata_*.log

# After completion, check accounting info
qacct -j <job_id>
```

---

## 9. Verify Output

After successful completion:

```bash
# Check output file exists
ls -lh /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures.RData

# Test loading in R
singularity exec ~/rocker_r431.sif Rscript -e "load('tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures.RData'); cat('Dimensions:', dim(tahoe_signatures), '\n')"
```

---

## Troubleshooting

### Issue: "Singularity image not found"
**Solution:**
```bash
# Check if image exists
ls -lh ~/rocker_r431.sif

# If not, pull it again
singularity pull ~/rocker_r431.sif docker://rocker/r-ver:4.3.1
```

### Issue: "arrow package not found"
**Solution:**
```bash
# Install arrow package
singularity exec ~/rocker_r431.sif R -e "install.packages('arrow', repos='https://cloud.r-project.org')"
```

### Issue: "Checkpoint file not found"
**Solution:**
```bash
# Verify Part 2 completed successfully
ls -lh tahoe_cmap_analysis/data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet

# Check Part 2 logs
tail ~/hpc_logs/hpc_part2_rank_*.log
```

### Issue: "Out of memory"
**Solution:**
- The script requests 256GB (16 cores × 16GB)
- If still insufficient, increase to 32 cores × 16GB = 512GB
- Edit script: `#$ -pe smp 32`

### Issue: "Job killed by scheduler"
**Solution:**
- Check if exceeded time limit (12 hours)
- Increase: `#$ -l h_rt=24:00:00`
- Check logs for actual runtime

---

## File Locations Reference

| Item | Path |
|------|------|
| Singularity Image | `~/rocker_r431.sif` |
| R Libraries | `~/R/library/` |
| Project Root | `/wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing` |
| Scripts | `tahoe_cmap_analysis/scripts/` |
| Input (Part 2 output) | `tahoe_cmap_analysis/data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet` |
| Output (Part 3) | `tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures.RData` |
| Logs | `~/hpc_logs/` |

---

## Expected Runtime

- **Part 2 (Python):** 2-6 hours (depends on data size)
- **Part 3 (R):** 15-30 minutes
- **Total Pipeline:** ~3-7 hours

---

## Support

- **HPC Issues:** wynton-help@ucsf.edu
- **Pipeline Issues:** enock.niyonkuru@ucsf.edu
- **Documentation:** https://wynton.ucsf.edu

---

**Last Updated:** November 9, 2025
