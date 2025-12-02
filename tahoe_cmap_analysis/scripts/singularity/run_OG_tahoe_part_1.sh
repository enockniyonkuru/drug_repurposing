#!/bin/bash
#'
#' HPC Submission: Tahoe Signatures Part 1
#'
#' UCSF Wynton HPC job submission script for extracting and filtering
#' raw Tahoe H5 drug signature data. Handles large-scale data processing
#' with memory and CPU resource allocation.
#'

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N OG Tahoe                  # Job name
#$ -pe smp 8                          # Number of CPU cores to use
#$ -l mem_free=8G                     # Memory per core (total = 8×8 = 64 GB)
#$ -l scratch=200G                    # Local temporary storage
#$ -l h_rt=48:00:00                   # Max wall time (48 h)
### NOTE: For Wynton, maximum allowed runtime on member.q = 2 weeks (336 h)

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu           # Replace with your email
#$ -m bea                             # Notify on begin, end, and abort

### --- 1. Logging Setup ---
JOB_NAME=${JOB_NAME:-tahoe_pipeline}
# Use the relative path for project-specific logs
LOG_DIR="../logs" 
mkdir -p "$LOG_DIR"

# This is the master job log file (captures scheduler messages, echoes, and Python output if not redirected)
MASTER_LOG_FILE="${LOG_DIR}/${JOB_NAME}_master_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"
exec > "$MASTER_LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting Tahoe Drug Filtering Pipeline"
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Start Time: $(date)"
echo "Master Log File: $MASTER_LOG_FILE"
echo "=============================================================="

### --- 2. Python-Specific Log File Setup ---
# Define a separate file path for the Python script's console output (stdout/stderr)
PYTHON_LOG="${LOG_DIR}/${JOB_NAME}_python_console_${JOB_ID:-manual}.txt"
echo "Python script console output will be redirected to: $PYTHON_LOG"

### --- Load modules ---
module load python/3.10

### --- Environment prep (optional) ---
source ../venv/bin/activate

### --- 3. Run the Python pipeline with Output Redirection ---
echo "Running Python script with P-value filtering enabled..."
echo "--------------------------------------------------------------"

# Run the Python script and redirect its console output to the PYTHON_LOG file
python3 ../scripts/OG_tahoe_part1_create_signature.py \
    --enable-filter \
    --padj-threshold 0.05 \
    --n-cores 8 \
    >> "$PYTHON_LOG" 2>&1

# Check the exit status of the Python command
PYTHON_EXIT_CODE=$?

echo "--------------------------------------------------------------"
echo "Python Script Execution Finished."
echo "Exit Code: $PYTHON_EXIT_CODE"

### --- Wrap-up ---
echo "=============================================================="
if [ "$PYTHON_EXIT_CODE" -eq 0 ]; then
    echo "✅ Job Completed Successfully"
else
    echo "❌ Job Failed (Python Exit Code: $PYTHON_EXIT_CODE). Check $PYTHON_LOG and the Python internal log for details."
fi
echo "End Time: $(date)"
echo "=============================================================="

# Exit with the Python script's exit code
exit $PYTHON_EXIT_CODE