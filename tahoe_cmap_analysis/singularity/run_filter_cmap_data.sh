#!/bin/bash
### ============================================================
### UCSF Wynton HPC Submission Script — CMap Filtering Pipeline
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N filter_cmap_data                 # Job name
#$ -pe smp 4                        # Number of CPU cores to use
#$ -l mem_free=6G                   # Memory per core (total = 4×6 = 24 GB)
#$ -l scratch=100G                  # Local temporary storage
#$ -l h_rt=24:00:00                 # Max wall time (24 h)
### NOTE:
### - Wynton general queues allow up to 2 weeks (336 h) max runtime.
### - Default memory per slot = 1 GB; request enough for pandas/pyreadr.
### - Scratch ranges from 0.1–1.8 TiB per node — request within that limit.

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu           # Replace with your  email
#$ -m bea                           # Notify on begin, end, and abort

### --- Logging setup ---
JOB_NAME=${JOB_NAME:-cmap_pipeline}
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"
exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting CMap Filtering Pipeline"
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Start Time: $(date)"
echo "=============================================================="

### --- Load modules ---
module load python/3.10

### --- Environment prep (optional) ---
source ../venv/bin/activate

### --- Run your Python script ---
python3 ../scripts/filter_cmap_data.py

### --- Wrap-up ---
echo "=============================================================="
echo "Job Completed Successfully"
echo "End Time: $(date)"
echo "=============================================================="
