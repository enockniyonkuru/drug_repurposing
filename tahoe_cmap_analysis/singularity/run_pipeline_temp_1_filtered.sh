#!/bin/bash
### ============================================================
### UCSF Wynton HPC Submission Script — DRpipe: Temp Special
### ============================================================

### --- Scheduler Directives ---
#$ -S /bin/bash
#$ -cwd
#$ -j y
#$ -r y
#$ -N drpipe_temp             # Job name (unique for this run)
#$ -pe smp 4                  # Number of CPU cores
#$ -l mem_free=6G             # Memory per core
#$ -l h_rt=24:00:00           # Max wall time

### --- Email notifications ---
#$ -M enock.niyonkuru@ucsf.edu
#$ -m bea

### --- Logging setup ---
JOB_NAME=${JOB_NAME:-drpipe_temp}
LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${JOB_NAME}_${JOB_ID:-manual}.log"
exec > "$LOG_FILE" 2>&1

echo "=============================================================="
echo "🚀 Starting DRpipe Batch Analysis: TEMP SPECIAL"
echo "Node: $(hostname)"
echo "Working Directory: $(pwd)"
echo "Job ID: ${JOB_ID:-manual}"
echo "Start Time: $(date)"
echo "=============================================================="

### --- Load modules ---
echo "Loading R module..."
module load R
echo "Module load complete."

### --- Define Paths ---
R_SCRIPT="run_drpipe_batch.R"
CMAP_SIG="../data/drug_signatures/cmap/cmap_genes_filtered.RData"
CMAP_META="../data/drug_signatures/cmap/cmap_drug_experiments_new.csv"
TAHOE_SIG="../data/drug_signatures/tahoe/tahoe_genes_filtered.RData"
TAHOE_META="../data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv"
GENE_TABLE="../data/gene_id_conversion_table.tsv"
REPORT_DIR="../reports"

### --- Run the R Script ---
echo "Starting Rscript for TEMP SPECIAL..."
Rscript ${R_SCRIPT} \
  --disease_dir "../data/disease_signatures/temp_singnatures" \
  --disease_source "TEMP SPECIAL" \
  --cmap_sig "${CMAP_SIG}" \
  --cmap_meta "${CMAP_META}" \
  --tahoe_sig "${TAHOE_SIG}" \
  --tahoe_meta "${TAHOE_META}" \
  --gene_table "${GENE_TABLE}" \
  --out_root "../results/temp_special_1_results_filtered" \
  --report_dir "${REPORT_DIR}" \
  --report_prefix "temp_special_1"

echo "Rscript finished."

### --- Wrap-up ---
echo "=============================================================="
echo "Job Completed Successfully"
echo "End Time: $(date)"
echo "=============================================================="