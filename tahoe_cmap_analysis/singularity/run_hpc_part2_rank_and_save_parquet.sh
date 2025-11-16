#!/bin/bash
### ============================================================
### UCSF Wynton HPC — Part 2: Rank (Python)
### ============================================================
### This script runs the HPC-optimized Python script (Part 2)
### to load the full intermediate parquet, rank all signatures,
### and save a new, ranked parquet checkpoint.
###
### RESOURCES:
### - 16 cores (for parallel ranking)
### - 256 GB RAM (16G * 16 cores)
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N hpc_part2_rank                  # Job name
#$ -pe smp 16                         # 16 CPU cores
#$ -l mem_free=16G                    # 16GB per core = 256GB total
#$ -l scratch=500G                    # Local scratch storage
#$ -l h_rt=12:00:00                   # Max wall time (12 hours)

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu        # Your email
#$ -m bea                             # Notify on begin, end, and abort

### ============================================================
### Setup and Logging
### ============================================================

JOB_NAME="hpc_part2_rank"
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"

exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting HPC Pipeline - PART 2 (Python Ranking)"
echo "=============================================================="
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Cores Allocated: ${NSLOTS:-unknown}"
echo "Start Time: $(date)"
echo "Log File: $LOG_FILE"
echo "=============================================================="

### ============================================================
### Environment Setup
### ============================================================

echo ""
echo "Setting up Python environment..."

module load python/3.10

VENV_PATH="../venv"
if [ -d "$VENV_PATH" ]; then
    echo "Activating virtual environment: $VENV_PATH"
    source "$VENV_PATH/bin/activate"
else
    echo "⚠️  WARNING: Virtual environment not found at $VENV_PATH"
    exit 1
fi

echo ""
echo "Python environment:"
python --version
pip list | grep -E "pandas|numpy|pyarrow|tables|pyreadr|joblib|psutil|tqdm"

### ============================================================
### Run Part 2 Script
### ============================================================

echo ""
echo "=============================================================="
echo "Running Part 2 (Python) script..."
echo "=============================================================="

# Navigate to scripts directory as expected
cd ../scripts || {
    echo "❌ ERROR: Could not navigate to scripts directory"
    exit 1
}

SCRIPT_PATH="hpc_part2_rank_and_save_parquet.py"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: Script not found at $SCRIPT_PATH"
    exit 1
fi

python3 "$SCRIPT_PATH"

EXIT_CODE=$?

### ============================================================
### Post-Processing
### ============================================================

echo ""
echo "=============================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Part 2 (Python) Completed Successfully!"
    echo "   Created: ../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet"
    echo "   Triggering Part 3 (R) job..."
else
    echo "❌ Part 2 (Python) Failed with exit code: $EXIT_CODE"
    echo "   Check $LOG_FILE for details."
fi
echo "=============================================================="
echo "End Time: $(date)"
echo "=============================================================="

exit $EXIT_CODE