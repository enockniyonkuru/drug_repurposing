# Enhanced Logging for HPC Part 3 Script

## Overview

I've added comprehensive error logging to the HPC Part 3 R script to help you identify exactly where and why errors occur. This document explains the logging system and how to use it.

---

## Files Created

### 1. **hpc_part3_convert_to_rdata_with_logging.R**
   - Location: `tahoe_cmap_analysis/scripts/`
   - Enhanced R script with detailed logging at every step
   - Creates timestamped log files with full error context

### 2. **run_hpc_part3_with_logging.sh**
   - Location: `tahoe_cmap_analysis/singularity/`
   - Shell script that runs the logging-enabled R script
   - Includes Singularity integration for UCSF Wynton HPC

---

## What Gets Logged

### Console Output (Shell Log)
- Job information (node, cores, time)
- Environment setup status
- Pre-flight check results
- High-level progress updates
- Final success/failure status

**Location:** `~/hpc_logs/hpc_part3_rdata_<JOB_ID>_<timestamp>.log`

### Detailed R Log
- **Timestamps** for every operation
- **Step-by-step progress** through the pipeline
- **System information** (R version, platform, memory)
- **File information** (sizes, paths, timestamps)
- **Data dimensions** at each stage
- **Error context** with full traceback
- **Possible causes** for each error type

**Location:** `tahoe_cmap_analysis/logs/hpc_part3_rdata_<timestamp>.log`

---

## Log Levels

The R script uses different log levels:

- **INFO**: Normal progress messages
- **ERROR**: Error messages with full context

---

## What Each Step Logs

### Step 0: Environment Setup
```
- R version and platform
- arrow package availability and version
- Working directory
```

### Step 1: Path Setup and Validation
```
- Input/output file paths
- File existence checks
- File sizes and modification times
- Disk space availability
- Directory creation status
```

### Step 2: Load Parquet Data
```
- Load start time
- Data dimensions (rows × columns)
- Column names and data types
- Load duration
- Memory usage
- entrezID column verification
```

### Step 3: Convert to CMap Format
```
- Gene ID extraction (count and samples)
- Experiment column count
- Progress every 100 columns with ETA
- Conversion duration
- Final data structure verification
```

### Step 4: Save to RData
```
- Available disk space before save
- Save operation duration
- Output file verification
- File size
- Integrity test (reload verification)
```

---

## Error Information Captured

When an error occurs, the log includes:

1. **Error Message**: The actual error text
2. **Context**: What operation was being performed
3. **Traceback**: Function call stack
4. **System Info**:
   - R version
   - Platform
   - Working directory
   - Memory usage (if pryr package available)
5. **Possible Causes**: Common reasons for this type of error
6. **Troubleshooting Steps**: What to check next

---

## How to Use

### Submit the Job

```bash
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/singularity

# Submit with logging
qsub run_hpc_part3_with_logging.sh
```

### Monitor Progress

```bash
# Check job status
qstat -u enockniyonkuru

# Watch shell log in real-time
tail -f ~/hpc_logs/hpc_part3_rdata_*.log

# Watch R detailed log in real-time
tail -f /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/logs/hpc_part3_rdata_*.log
```

### After Completion

```bash
# View shell log
less ~/hpc_logs/hpc_part3_rdata_<JOB_ID>_*.log

# View detailed R log
less /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/tahoe_cmap_analysis/logs/hpc_part3_rdata_*.log
```

---

## Example Log Output

### Success Case
```
[2025-11-09 01:30:00] [INFO] ================================================================================
[2025-11-09 01:30:00] [INFO] HPC PART 3: Converting Checkpoint to RData (All Genes, All Exps)
[2025-11-09 01:30:00] [INFO] ================================================================================
[2025-11-09 01:30:00] [INFO] Log file: ../logs/hpc_part3_rdata_20251109_013000.log
[2025-11-09 01:30:00] [INFO] Start time: 2025-11-09 01:30:00
[2025-11-09 01:30:00] [INFO] Working directory: /wynton/protected/.../scripts
[2025-11-09 01:30:00] [INFO] R version: R version 4.3.1 (2023-06-16)
...
[2025-11-09 01:45:23] [INFO] ✓ Data saved successfully in 2.3 minutes
[2025-11-09 01:45:23] [INFO] ✓ Output file verified (3.45 GB)
[2025-11-09 01:45:25] [INFO] ✓ File integrity verified (loaded 12328 x 1310)
[2025-11-09 01:45:25] [INFO] ✅✅✅ HPC PIPELINE PART 3 COMPLETE! ✅✅✅
```

### Error Case
```
[2025-11-09 01:32:15] [ERROR] ================================================================================
[2025-11-09 01:32:15] [ERROR] ERROR OCCURRED: object 'entrezID' not found
[2025-11-09 01:32:15] [ERROR] CONTEXT: Failed to load parquet file
[2025-11-09 01:32:15] [ERROR] TRACEBACK:
[2025-11-09 01:32:15] [ERROR]   1: read_parquet(checkpoint_file)
[2025-11-09 01:32:15] [ERROR]   2: tryCatch(...)
[2025-11-09 01:32:15] [ERROR] SYSTEM INFO:
[2025-11-09 01:32:15] [ERROR]   R Version: R version 4.3.1 (2023-06-16)
[2025-11-09 01:32:15] [ERROR]   Platform: x86_64-pc-linux-gnu
[2025-11-09 01:32:15] [ERROR]   Working Directory: /wynton/protected/.../scripts
[2025-11-09 01:32:15] [ERROR] Possible causes:
[2025-11-09 01:32:15] [ERROR]   1. File is corrupted
[2025-11-09 01:32:15] [ERROR]   2. Insufficient memory
[2025-11-09 01:32:15] [ERROR]   3. arrow package version incompatibility
[2025-11-09 01:32:15] [ERROR]   4. File format mismatch
```

---

## Troubleshooting with Logs

### If Job Fails

1. **Check the shell log first** (`~/hpc_logs/hpc_part3_rdata_*.log`)
   - Look for pre-flight check failures
   - Check environment setup issues

2. **Check the R detailed log** (`tahoe_cmap_analysis/logs/hpc_part3_rdata_*.log`)
   - Find the exact step that failed
   - Read the error context and possible causes
   - Check system information at time of failure

3. **Common Issues and Solutions**:

   **arrow package not found:**
   ```bash
   singularity exec ~/rocker_r431.sif R -e "install.packages('arrow', repos='https://cloud.r-project.org')"
   ```

   **Checkpoint file not found:**
   ```bash
   # Verify Part 2 completed
   ls -lh tahoe_cmap_analysis/data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet
   ```

   **Out of memory:**
   ```bash
   # Edit script to request more cores/memory
   #$ -pe smp 32
   #$ -l mem_free=16G  # 512GB total
   ```

   **Disk space issues:**
   ```bash
   # Check available space
   df -h /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing
   ```

---

## Comparison: Original vs Logging Version

| Feature | Original Script | Logging Version |
|---------|----------------|-----------------|
| Error messages | Basic | Detailed with context |
| Progress tracking | Minimal | Step-by-step with timestamps |
| System info | None | Full system state |
| Traceback | No | Yes, full call stack |
| File verification | Basic | Comprehensive |
| Disk space check | No | Yes |
| Memory tracking | No | Yes (if pryr available) |
| Log file | Console only | Separate detailed log |
| Error causes | Not provided | Listed for each error |
| Troubleshooting | Manual | Guided suggestions |

---

## Log File Locations Summary

| Log Type | Location | Contains |
|----------|----------|----------|
| Shell Log | `~/hpc_logs/hpc_part3_rdata_<JOB_ID>_<timestamp>.log` | Job info, environment setup, high-level status |
| R Detailed Log | `tahoe_cmap_analysis/logs/hpc_part3_rdata_<timestamp>.log` | Step-by-step execution, errors, system info |

---

## Benefits

1. **Pinpoint Errors**: Know exactly which step failed
2. **Understand Context**: See what was happening when error occurred
3. **System State**: Capture memory, disk, and environment info
4. **Faster Debugging**: Guided troubleshooting suggestions
5. **Progress Tracking**: Monitor long-running operations
6. **Audit Trail**: Complete record of execution

---

## Next Steps

1. Use `run_hpc_part3_with_logging.sh` instead of the original script
2. When errors occur, check both log files
3. Use the error context and suggestions to fix issues
4. Keep logs for debugging and optimization

---

**Created:** November 9, 2025  
**Author:** Cline AI Assistant  
**Contact:** enock.niyonkuru@ucsf.edu
