#!/bin/bash
# Run all 6 endometriosis profiles sequentially

set -e

PROFILES=(
  "CMAP_Endometriosis_ESE_Strict"
  "CMAP_Endometriosis_INII_Strict"
  "CMAP_Endometriosis_IIINIV_Strict"
  "CMAP_Endometriosis_MSE_Strict"
  "CMAP_Endometriosis_PE_Strict"
  "CMAP_Endometriosis_Unstratified_Strict"
)

echo "========================================"
echo "Running all 6 Endometriosis Profiles"
echo "========================================"

for i in "${!PROFILES[@]}"; do
  profile="${PROFILES[$i]}"
  num=$((i+1))
  
  echo ""
  echo "[$num/6] Starting: $profile"
  echo "--------------------------------------"
  
  # Update config
  sed -i '' "s/runall_profile: .*/runall_profile: \"$profile\"/" config.yml
  
  # Run the profile
  Rscript runall.R
  
  echo "✓ Completed: $profile"
  echo ""
done

echo "========================================"
echo "All 6 profiles completed!"
echo "========================================"
