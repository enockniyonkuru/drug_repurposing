#!/bin/bash
# Script to kill the stuck process and restart the pipeline with the fix

echo "=========================================="
echo "TAHOE Pipeline Restart Tool"
echo "=========================================="
echo ""

# Kill any stuck R processes
echo "[STEP 1] Stopping any running pipeline processes..."
pkill -f "run_batch_from_config.R" 2>/dev/null || true
sleep 2

# Check if process is dead
if pgrep -f "run_batch_from_config.R" > /dev/null; then
  echo "✗ Process still running, force killing..."
  pkill -9 -f "run_batch_from_config.R"
  sleep 2
else
  echo "✓ Pipeline process stopped"
fi

echo ""
echo "[STEP 2] Verifying fix is in place..."

# Check if the fix is present in the code
if grep -q "subprocess loader" /Users/enockniyonkuru/Desktop/drug_repurposing/DRpipe/R/pipeline_processing.R; then
  echo "✓ Fix is installed in DRpipe code"
else
  echo "✗ Fix not found! Apply fix first:"
  echo "  See HANG_FIX_SUMMARY.md"
  exit 1
fi

echo ""
echo "[STEP 3] Ready to restart..."
echo "To restart the pipeline, run:"
echo ""
echo "  cd /Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/scripts/execution"
echo "  Rscript run_batch_from_config.R --config_file batch_configs/90_selected_diseases.yml"
echo ""
echo "Monitor progress with:"
echo "  tail -f tahoe_cmap_analysis/results/90_selected_diseases_shared_genes/batch_run_log_*.txt"
echo ""
echo "=========================================="
