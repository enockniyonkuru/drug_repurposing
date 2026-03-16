#!/bin/bash
# Compare top 20 drugs from end-to-end vs replicated for all signatures

signatures=("ESE" "MSE" "PE" "IIInIV" "InII")

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        TOP 20 DRUGS COMPARISON: E2E vs REPLICATED              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

for sig in "${signatures[@]}"; do
  if [ "$sig" = "ESE" ] || [ "$sig" = "MSE" ] || [ "$sig" = "PE" ]; then
    replicated="replication/drug_instances_${sig}_replicated.csv"
  else
    replicated="replication/drug_instances_${sig}_replicated.csv"
  fi
  
  e2e="replication/end_to_end_${sig}/drug_instances_${sig}_e2e.csv"
  
  # Extract top 20 drug names
  rep_top20=$(head -21 "$replicated" | tail -20 | cut -d, -f8 | tr -d '"')
  e2e_top20=$(head -21 "$e2e" | tail -20 | cut -d, -f8 | tr -d '"')
  
  # Compare
  if [ "$rep_top20" = "$e2e_top20" ]; then
    match="✓ MATCH"
  else
    match="✗ DIFFER"
  fi
  
  echo "$sig: $match"
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
