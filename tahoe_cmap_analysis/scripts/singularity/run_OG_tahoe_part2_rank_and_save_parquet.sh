#!/bin/bash
#'
#' HPC Submission: Tahoe Signatures Part 2
#'
#' UCSF Wynton HPC job submission script for ranking Tahoe drug signatures.
#' Allocates 16 cores and 256GB RAM for memory-intensive ranking operations.
#' Produces ranked parquet checkpoint for downstream analysis.
#'

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N hpc_part2_rank                  # Job name
#$ -pe smp 16                         # 16 CPU cores
#$ -l mem_free=16G                    # 16GB per core = 256GB total (CRITICAL for Part 2)
#$ -l scratch=500G                    # Local scratch storage
#$ -l h_rt=12:00:00                   # Max wall time (12 hours)

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu        # Your email
#$ -m bea                             # Notify on begin, end, and abort

### ============================================================
### Setup and Logging
### ============================================================

# Use the name defined by the scheduler ($SGE_TASK_ID is sometimes preferred over $JOB_ID)
JOB_NAME=${JOB_NAME:-hpc_part2_rank} 
LOG_DIR="../logs"
mkdir -p "$LOG_DIR"

# MASTER_LOG_FILE must be defined relative to the STARTING directory
MASTER_LOG_FILE="${LOG_DIR}/${JOB_NAME}_master_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"
exec > "$MASTER_LOG_FILE" 2>&1

# Capture the allocated cores before moving directories
ALLOCATED_CORES=${NSLOTS:-16} 
PROJECT_ROOT=$(pwd) # Save the initial working directory

echo "=============================================================="
echo "🚀 Starting HPC Pipeline - PART 2 (Python Ranking)"
echo "=============================================================="
echo "Node: $(hostname)"
echo "Project Root Directory: $PROJECT_ROOT"
echo "Job ID: ${JOB_ID:-manual}"
echo "Cores Allocated: $ALLOCATED_CORES"
echo "Start Time: $(date)"
echo "Master Log File: $MASTER_LOG_FILE"
echo "=============================================================="

### ============================================================
### Environment Setup
### ============================================================

echo ""
echo "Setting up Python environment..."

module load python/3.10

# Use absolute path for venv activation to be safe, regardless of later CD command
VENV_PATH="$PROJECT_ROOT/venv"
if [ -d "$VENV_PATH" ]; then
    echo "Activating virtual environment..."
    source "$VENV_PATH/bin/activate"
else
    echo "❌ ERROR: Virtual environment not found at $VENV_PATH"
    exit 1
fi

echo ""
python --version

### ============================================================
### Run Part 2 Script
### ============================================================

echo ""
echo "=============================================================="
echo "Running Part 2 (Python) script..."
echo "=============================================================="

# Define the correct script name
SCRIPT_NAME="OG_tahoe_part2_rank_and_save_parquet.py"

# Navigate to scripts directory (where the Python script lives)
cd ../scripts || {
    echo "❌ ERROR: Could not navigate to ../scripts directory"
    exit 1
}

if [ ! -f "$SCRIPT_NAME" ]; then
    echo "❌ ERROR: Script not found: $SCRIPT_NAME"
    exit 1
fi

# EXECUTION COMMAND: Pass the allocated cores ($ALLOCATED_CORES) and log directory
python3 "$SCRIPT_NAME" \
    --n-cores "$ALLOCATED_CORES" \
    --log-dir "$PROJECT_ROOT/logs"

EXIT_CODE=$?

### ============================================================
### Post-Processing
### ============================================================

# Return to root directory for cleaner post-processing
cd "$PROJECT_ROOT" 

echo ""
echo "=============================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Part 2 (Python) Completed Successfully!"
    echo "   Checkpoint created at: ../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet"
    echo "   Next Step: Run HPC Part 3 (R script) for final RData conversion."
else
    echo "❌ Part 2 (Python) Failed with exit code: $EXIT_CODE"
    echo "   Check the master log file ($MASTER_LOG_FILE) for Python script errors."
fi
echo "End Time: $(date)"
echo "=============================================================="

exit $EXIT_CODE