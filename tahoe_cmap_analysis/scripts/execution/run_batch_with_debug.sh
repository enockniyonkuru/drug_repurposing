#!/bin/bash
# Debug script to run batch with detailed output capture

cd /Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/scripts/execution

echo "====== STARTING BATCH RUN WITH ENHANCED LOGGING ======"
echo "Time: $(date)"
echo "Process: $$"
echo ""

# Run with tee to capture all output to both console and file
Rscript run_batch_from_config.R \
  --config_file batch_configs/90_selected_diseases.yml \
  2>&1 | tee batch_debug_$(date +%Y%m%d_%H%M%S).log

echo ""
echo "====== BATCH RUN COMPLETED ======"
echo "Time: $(date)"
echo ""
echo "Check the TAHOE folder to see if it's empty (hung) or has results:"
ls -lh ../../../results/90_selected_diseases_shared_genes/ | grep TAHOE | tail -5
