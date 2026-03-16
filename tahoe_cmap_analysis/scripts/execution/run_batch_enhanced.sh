#!/bin/bash
# Run batch with enhanced diagnostics

set -e

cd /Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/scripts/execution

LOG_FILE="batch_run_$(date +%Y%m%d_%H%M%S).log"

echo "========================================"
echo "BATCH RUN WITH ENHANCED DIAGNOSTICS"
echo "========================================"
echo "Start time: $(date)"
echo "Log file: $LOG_FILE"
echo ""

# Run batch with full output
Rscript run_batch_from_config.R \
  --config_file batch_configs/90_selected_diseases.yml \
  2>&1 | tee "$LOG_FILE"

echo ""
echo "========================================"
echo "BATCH RUN COMPLETED"
echo "========================================"
echo "End time: $(date)"
echo "Log file: $LOG_FILE"
echo ""
echo "Results summary:"
ls -1 ../../../results/90_selected_diseases_shared_genes/ | grep -E "_(CMAP|TAHOE)_" | wc -l
echo "result folders created"
