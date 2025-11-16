#!/bin/bash
### ============================================================
### UCSF Wynton HPC — Part 3: Convert to RData (R) - WITH LOGGING
### ============================================================
### This script runs the R script (Part 3) with enhanced logging
### to load the ranked parquet checkpoint and convert it to the
### final CMap-like .RData file.
###
### DEPENDENCY: Waits for 'hpc_part2_rank' to finish.
###
### RESOURCES:
### - 16 cores (to get 256GB total memory)
### - 16 GB RAM per core = 256GB total
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N hpc_part3_rdata                 # Job name
#$ -hold_jid hpc_part2_rank           # WAITS for Part 2 job to finish
#$ -pe smp 16                         # 16 CPU cores (to get enough memory)
#$ -l mem_free=16G                    # 16GB per core = 256GB total
#$ -l scratch=50G                     # Local scratch storage
#$ -l h_rt=12:00:00                   # Max wall time (12 hours)
#$ -A sirota_lab                      # Account for billing

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu        # Your email
#$ -m bea                             # Notify on begin, end, and abort

### ============================================================
### Setup and Logging
### ============================================================

JOB_NAME="hpc_part3_rdata"
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"

exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting HPC Pipeline - PART 3 (R Conversion with Logging)"
echo "=============================================================="
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Cores Allocated: ${NSLOTS:-unknown}"
echo "Waiting for Job: hpc_part2_rank"
echo "Start Time: $(date)"
echo "Shell Log File: $LOG_FILE"
echo "=============================================================="

### ============================================================
### Environment Setup
### ============================================================

echo ""
echo "Setting up R environment via Singularity..."

# Define Singularity image path
SINGULARITY_IMAGE="$HOME/rocker_r431.sif"

# Check if image exists
if [ ! -f "$SINGULARITY_IMAGE" ]; then
    echo "❌ ERROR: Singularity image not found at $SINGULARITY_IMAGE"
    echo "   Please pull the image first:"
    echo "   singularity pull ~/rocker_r431.sif docker://rocker/r-ver:4.3.1"
    exit 1
fi

echo "✅ Found Singularity image: $SINGULARITY_IMAGE"

echo ""
echo "R version:"
singularity exec "$SINGULARITY_IMAGE" R --version

echo ""
echo "Checking for required R packages..."
singularity exec "$SINGULARITY_IMAGE" Rscript -e "if (!require('arrow', quietly=TRUE)) { cat('⚠️  WARNING: arrow package not found\n'); cat('   Install with: singularity exec ~/rocker_r431.sif R -e \"install.packages(\\\"arrow\\\", repos=\\\"https://cloud.r-project.org\\\")\"\n') } else { cat('✅ arrow package found\n') }"

### ============================================================
### Path Setup
### ============================================================

# Define base directory (adjust if needed)
BASE_DIR="/wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing"
SCRIPT_DIR="${BASE_DIR}/tahoe_cmap_analysis/scripts"

echo ""
echo "Navigating to scripts directory: $SCRIPT_DIR"

cd "$SCRIPT_DIR" || {
    echo "❌ ERROR: Could not navigate to scripts directory: $SCRIPT_DIR"
    echo "   Current directory: $(pwd)"
    echo "   Please verify the BASE_DIR path in the script"
    exit 1
}

echo "✅ Successfully changed to: $(pwd)"

### ============================================================
### Pre-flight Checks
### ============================================================

echo ""
echo "Running pre-flight checks..."

SCRIPT_PATH="hpc_part3_convert_to_rdata.R"
CHECKPOINT_FILE="../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet"
OUTPUT_DIR="../data/drug_signatures/tahoe"
R_LOG_DIR="../logs"

# Check if R script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: R script not found at $SCRIPT_PATH"
    exit 1
fi
echo "✅ R script found: $SCRIPT_PATH"

# Check if checkpoint file exists (from Part 2)
if [ ! -f "$CHECKPOINT_FILE" ]; then
    echo "❌ ERROR: Checkpoint file not found: $CHECKPOINT_FILE"
    echo "   This file should be created by Part 2 (hpc_part2_rank_and_save_parquet.py)"
    echo "   Please ensure Part 2 completed successfully before running Part 3"
    exit 1
fi
echo "✅ Checkpoint file found: $CHECKPOINT_FILE"

# Get checkpoint file size
CHECKPOINT_SIZE=$(du -h "$CHECKPOINT_FILE" | cut -f1)
echo "   Checkpoint size: $CHECKPOINT_SIZE"

# Check if output directory exists or can be created
mkdir -p "$OUTPUT_DIR" 2>/dev/null
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "❌ ERROR: Cannot create output directory: $OUTPUT_DIR"
    exit 1
fi
echo "✅ Output directory ready: $OUTPUT_DIR"

# Create R log directory
mkdir -p "$R_LOG_DIR" 2>/dev/null
if [ ! -d "$R_LOG_DIR" ]; then
    echo "⚠️  WARNING: Cannot create R log directory: $R_LOG_DIR"
    echo "   R script will still run but may not create detailed logs"
else
    echo "✅ R log directory ready: $R_LOG_DIR"
fi

# Check available disk space
AVAILABLE_SPACE=$(df -h "$OUTPUT_DIR" | tail -1 | awk '{print $4}')
echo "   Available disk space: $AVAILABLE_SPACE"

echo ""
echo "All pre-flight checks passed! ✅"

### ============================================================
### Run Part 3 Script with Enhanced Logging
### ============================================================

echo ""
echo "=============================================================="
echo "Running Part 3 (R) script via Singularity with enhanced logging..."
echo "=============================================================="
echo "Expected runtime: 15-30 minutes"
echo "Expected output: ../data/drug_signatures/tahoe/tahoe_signatures.RData"
echo ""
echo "NOTE: The R script will create its own detailed log file in:"
echo "      $R_LOG_DIR/hpc_part3_rdata_*.log"
echo ""
echo "This shell log captures stdout/stderr, while the R log has detailed"
echo "step-by-step progress, error context, and system information."
echo ""

START_TIME=$(date +%s)

singularity exec "$SINGULARITY_IMAGE" Rscript "$SCRIPT_PATH"

EXIT_CODE=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED / 60))
ELAPSED_SEC=$((ELAPSED % 60))

### ============================================================
### Post-Processing
### ============================================================

echo ""
echo "=============================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Part 3 (R) Completed Successfully!"
    echo ""
    echo "   Runtime: ${ELAPSED_MIN}m ${ELAPSED_SEC}s"
    echo ""
    
    OUTPUT_FILE="../data/drug_signatures/tahoe/tahoe_signatures.RData"
    if [ -f "$OUTPUT_FILE" ]; then
        OUTPUT_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo "   Final Output: $OUTPUT_FILE"
        echo "   File Size: $OUTPUT_SIZE"
        echo ""
        echo "✅✅✅ PIPELINE COMPLETE! ✅✅✅"
        echo ""
        echo "Log files created:"
        echo "  1. Shell log: $LOG_FILE"
        echo "  2. R detailed log: $R_LOG_DIR/hpc_part3_rdata_*.log"
        echo ""
        echo "Next steps:"
        echo "  1. Review the R log file for detailed execution information"
        echo "  2. Verify the output file can be loaded in R"
        echo "  3. Check data dimensions match expectations"
        echo "  4. Proceed with downstream analysis"
    else
        echo "⚠️  WARNING: Script completed but output file not found"
        echo "   Expected: $OUTPUT_FILE"
        echo "   Check the R log file for details: $R_LOG_DIR/hpc_part3_rdata_*.log"
    fi
else
    echo "❌ Part 3 (R) Failed with exit code: $EXIT_CODE"
    echo ""
    echo "   Runtime before failure: ${ELAPSED_MIN}m ${ELAPSED_SEC}s"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  1. Check shell log: $LOG_FILE"
    echo "  2. Check R detailed log: $R_LOG_DIR/hpc_part3_rdata_*.log"
    echo "     (The R log will have exact error location and context)"
    echo ""
    echo "Common issues:"
    echo "  - arrow package not installed"
    echo "  - Checkpoint file corrupted"
    echo "  - Insufficient memory (requested 256GB)"
    echo "  - Disk space issues"
    echo ""
    echo "The R log file contains:"
    echo "  - Exact step where error occurred"
    echo "  - Full error message and context"
    echo "  - System information at time of error"
    echo "  - Traceback of function calls"
fi
echo "=============================================================="
echo "End Time: $(date)"
echo "Shell Log File: $LOG_FILE"
if [ -d "$R_LOG_DIR" ]; then
    R_LOG_FILE=$(ls -t "$R_LOG_DIR"/hpc_part3_rdata_*.log 2>/dev/null | head -1)
    if [ -n "$R_LOG_FILE" ]; then
        echo "R Detailed Log: $R_LOG_FILE"
    fi
fi
echo "=============================================================="

exit $EXIT_CODE
