#!/bin/bash
# Monitor 90-disease pipeline progress

LOG_FILE="/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/scripts/execution/batch_run_90_diseases.log"
RESULTS_DIR="/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/results/90_selected_diseases_shared_genes"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   PIPELINE PROGRESS - 90 DISEASES (SHARED GENES FILTERED)   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Count results folders
RESULT_COUNT=$(find "$RESULTS_DIR" -maxdepth 1 -type d -name "*_*" 2>/dev/null | wc -l)
echo "📊 Disease results completed: $RESULT_COUNT/90"

# Show current disease
CURRENT=$(grep "Processing disease" "$LOG_FILE" 2>/dev/null | tail -1 | sed 's/.*Processing disease //' | sed 's/ .*//')
if [ -n "$CURRENT" ]; then
    echo "🔄 Currently processing: Disease $CURRENT"
fi

# Show current analysis step
CURRENT_STEP=$(grep -E "Running CMAP|Running TAHOE" "$LOG_FILE" 2>/dev/null | tail -1)
if [ -n "$CURRENT_STEP" ]; then
    echo "   $CURRENT_STEP"
fi

# Show process info
PID=$(pgrep -f "run_batch_from_config" | head -1)
if [ -n "$PID" ]; then
    echo ""
    echo "✅ Process Status: RUNNING (PID: $PID)"
    # Try to get memory info
    MEM=$(ps aux | grep "$PID" | grep -v grep | awk '{printf "%.1f", $6/1024}' 2>/dev/null)
    if [ -n "$MEM" ]; then
        echo "   Memory: ${MEM} GB"
    fi
else
    LAST_LINE=$(tail -1 "$LOG_FILE")
    if echo "$LAST_LINE" | grep -q "Error\|error\|ERROR"; then
        echo "❌ Process Status: FAILED"
        echo "   Error: $LAST_LINE"
    else
        echo "✓ Process Status: COMPLETED"
    fi
fi

# Estimate time
echo ""
echo "📝 Summary:"
echo "   Config: 90_selected_diseases.yml"
echo "   Output: $RESULTS_DIR"
echo ""

# Show last activity
echo "Last activity:"
tail -3 "$LOG_FILE" | sed 's/^/   /'

echo ""
echo "To view full log:"
echo "  tail -f $LOG_FILE"
echo ""
