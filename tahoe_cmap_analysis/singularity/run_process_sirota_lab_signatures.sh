#!/bin/bash
### ============================================================
### UCSF Wynton HPC Submission Script — Sirota Lab Signature Processing
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N process_sirota_sigs          # Job name
#$ -pe smp 4                        # Number of CPU cores to use
#$ -l mem_free=8G                   # Memory per core (total = 4×8 = 32 GB)
#$ -l scratch=50G                   # Local temporary storage
#$ -l h_rt=6:00:00                  # Max wall time (6 h)
### NOTE:
### - Wynton general queues allow up to 2 weeks (336 h) max runtime.
### - Default memory per slot = 1 GB; request enough for pandas/numpy/openpyxl.
### - Scratch ranges from 0.1–1.8 TiB per node — request within that limit.

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu      # Replace with your email
#$ -m bea                           # Notify on begin, end, and abort

### --- Logging setup ---
JOB_NAME=${JOB_NAME:-sirota_processing}
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"
exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting Sirota Lab Disease Signature Processing"
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Start Time: $(date)"
echo "=============================================================="

### --- Load modules ---
module load python/3.10

### --- Environment prep ---
# Activate virtual environment if it exists
if [ -d "../venv" ]; then
    echo "Activating virtual environment..."
    source ../venv/bin/activate
else
    echo "WARNING: Virtual environment not found at ../venv"
    echo "Attempting to use system Python..."
fi

### --- Install required dependencies if not present ---
echo "Checking for required Python packages..."
python3 -c "import openpyxl" 2>/dev/null || {
    echo "Installing openpyxl..."
    pip install --user openpyxl
}

### --- Run your Python script ---
echo ""
echo "Running process_sirota_lab_signatures.py..."
python3 ../scripts/process_sirota_lab_signatures.py

### --- Check exit status ---
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=============================================================="
    echo "✅ Job Completed Successfully"
    echo "End Time: $(date)"
    echo "=============================================================="
else
    echo ""
    echo "=============================================================="
    echo "❌ Job Failed with exit code: $EXIT_CODE"
    echo "End Time: $(date)"
    echo "=============================================================="
    exit $EXIT_CODE
fi
