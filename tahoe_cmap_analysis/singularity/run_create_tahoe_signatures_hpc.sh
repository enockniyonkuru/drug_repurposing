#!/bin/bash
### ============================================================
### UCSF Wynton HPC Submission Script — Tahoe Signature Creation
### ============================================================
### This script runs the HPC-optimized Tahoe signature creation pipeline
### which converts H5 data to ranked gene signatures in RData format.
###
### RESOURCE REQUIREMENTS:
### - This is a VERY memory-intensive job
### - Adjust mem_free and h_rt based on your dataset size
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N tahoe_signatures                # Job name
#$ -pe smp 16                         # Number of CPU cores (16 recommended)
#$ -l mem_free=16G                    # Memory per core (16GB × 16 = 256GB total)
#$ -l scratch=500G                    # Local scratch storage (500GB recommended)
#$ -l h_rt=72:00:00                   # Max wall time (72 hours = 3 days)

### NOTES:
### - For SMALL datasets (10K genes, 10K exp): 8 cores, 8G mem_free, 100G scratch, 12h
### - For MEDIUM datasets (20K genes, 50K exp): 16 cores, 16G mem_free, 300G scratch, 48h
### - For LARGE datasets (20K genes, 100K exp): 16 cores, 20G mem_free, 500G scratch, 72h
### - Adjust based on your actual dataset size

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu        # Replace with your email
#$ -m bea                             # Notify on begin, end, and abort

### ============================================================
### Setup and Logging
### ============================================================

# Job name for logging
JOB_NAME="tahoe_signatures"

# Create log directory
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"

# Create timestamped log file
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}_$(date +'%Y%m%d_%H%M%S').log"

# Redirect all output to log file
exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting Tahoe Signature Creation Pipeline (HPC-Optimized)"
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
echo "Setting up environment..."

# Load required modules
module load python/3.10

# Activate virtual environment (adjust path as needed)
VENV_PATH="../venv"
if [ -d "$VENV_PATH" ]; then
    echo "Activating virtual environment: $VENV_PATH"
    source "$VENV_PATH/bin/activate"
else
    echo "⚠️  WARNING: Virtual environment not found at $VENV_PATH"
    echo "    Proceeding with system Python (may cause issues)"
fi

# Verify Python and key packages
echo ""
echo "Python environment:"
python --version
echo "Installed packages:"
pip list | grep -E "pandas|numpy|pyarrow|tables|pyreadr|joblib|psutil|tqdm"

### ============================================================
### Run the Pipeline
### ============================================================

echo ""
echo "=============================================================="
echo "Running HPC-optimized Tahoe signature creation script..."
echo "=============================================================="

# Navigate to scripts directory (script expects to run from there)
cd ../scripts || {
    echo "❌ ERROR: Could not navigate to scripts directory"
    exit 1
}

# Set script path
SCRIPT_PATH="create_tahoe_og_signatures_hpc.py"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: Script not found at $SCRIPT_PATH"
    exit 1
fi

# Run the script with default parameters
# The script will automatically:
# - Use $NSLOTS for parallelization
# - Create comprehensive logs
# - Checkpoint progress
# - Monitor resources
# Note: Script uses relative paths (../) and expects to run from scripts/ directory

python3 "$SCRIPT_PATH"

# Capture exit code
EXIT_CODE=$?

### ============================================================
### Post-Processing and Cleanup
### ============================================================

echo ""
echo "=============================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Pipeline Completed Successfully!"
    echo "=============================================================="
    echo "End Time: $(date)"
    echo "Log File: $LOG_FILE"
    echo ""
    echo "Output files should be in:"
    echo "  - Intermediate: tahoe_cmap_analysis/data/intermediate_hpc/"
    echo "  - Final: tahoe_cmap_analysis/data/drug_signatures/tahoe/tahoe_signatures.RData"
    echo "  - Logs: tahoe_cmap_analysis/logs/"
else
    echo "❌ Pipeline Failed with exit code: $EXIT_CODE"
    echo "=============================================================="
    echo "End Time: $(date)"
    echo "Check the log file for details: $LOG_FILE"
    echo "Also check: tahoe_cmap_analysis/logs/ for detailed pipeline logs"
fi
echo "=============================================================="

exit $EXIT_CODE
