#!/bin/bash
### ============================================================
### UCSF Wynton HPC Submission Script — Tahoe Drug Filtering Pipeline
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N filter_tahoe_data                  # Job name
#$ -pe smp 8                          # Number of CPU cores to use
#$ -l mem_free=8G                     # Memory per core (total = 8×8 = 64 GB)
#$ -l scratch=200G                    # Local temporary storage
#$ -l h_rt=48:00:00                   # Max wall time (48 h)
### NOTE: For Wynton, maximum allowed runtime on member.q = 2 weeks (336 h)
###       Default memory per slot = 1 GB, so request enough (mem_free=)
###       Scratch storage varies (0.1–1.8 TiB); request reasonably below that.

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu           # Replace with your  email
#$ -m bea                             # Notify on begin, end, and abort

### --- Logging setup ---
JOB_NAME=${JOB_NAME:-tahoe_pipeline}
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"
exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting Tahoe Drug Filtering Pipeline"
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Start Time: $(date)"
echo "=============================================================="

### --- Load modules ---
module load python/3.10

### --- Environment prep (optional) ---
source ../venv/bin/activate

### --- Run the Python pipeline ---
python3 ../scripts/filter_tahoe_data.py

### --- Wrap-up ---
echo "=============================================================="
echo "✅ Job Completed Successfully"
echo "End Time: $(date)"
echo "=============================================================="
