#!/usr/bin/env python3
"""
Create CSV for 20 autoimmune diseases with recovery metrics.
This script creates the template structure for the autoimmune disease analysis.

Columns:
- disease_name: Name of the disease
- U: All known disease-drug pairs in Open Targets
- P: Known drugs present in CMAP or TAHOE (maximum recoverable)
- I: Drugs predicted as repurposing candidates by DRpipe
- S: Intersection of predicted candidates (I) with known drugs (P) - successfully recovered
- S/P: Recovery rate (S/P × 100%)
- S/I: Precision rate (S/I × 100%) - fraction of predicted that are known
"""

import csv
import os

# Autoimmune diseases from the 233 diseases list
autoimmune_diseases = [
    "ankylosing spondylitis",
    "autoimmune thrombocytopenic purpura",
    "Crohn's disease",
    "discoid lupus erythematosus",
    "inflammatory bowel disease",
    "lupus erythematosus",
    "multiple sclerosis",
    "psoriatic arthritis",
    "rheumatoid arthritis",
    "scleroderma",
    "Sjogren's syndrome",
    "systemic lupus erythematosus",
    "ulcerative colitis",
    "dermatomyositis",
    "atopic dermatitis",
    "allergic contact dermatitis",
    "type 1 diabetes mellitus",
    "polymyositis",
    "relapsing-remitting multiple sclerosis",
    "pulmonary sarcoidosis"
]

# Output file path
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"
output_file = os.path.join(output_dir, "autoimmune_diseases_recovery_metrics.csv")

print("Creating autoimmune disease recovery metrics CSV...")
print("=" * 80)
print(f"\nAutoimmune diseases identified: {len(autoimmune_diseases)}")
for i, disease in enumerate(autoimmune_diseases, 1):
    print(f"  {i:2d}. {disease}")

# Create CSV with template structure
print(f"\nCreating CSV file: {output_file}")
with open(output_file, 'w', newline='') as f:
    writer = csv.writer(f)
    
    # Write header
    header = ['disease_name', 'U', 'P', 'I', 'S', 'S/P', 'S/I']
    writer.writerow(header)
    
    # Write template rows for each disease
    # U, P, I, S columns are left empty for manual population with analysis results
    for disease in autoimmune_diseases:
        writer.writerow([disease, '', '', '', '', '', ''])

print(f"✓ Created {output_file}")
print(f"✓ Total autoimmune diseases: {len(autoimmune_diseases)}")
print("\nColumn definitions:")
print("  U   = All known disease-drug pairs in Open Targets")
print("  P   = Known drugs present in CMAP or TAHOE (maximum recoverable)")
print("  I   = Drugs predicted as repurposing candidates by DRpipe")
print("  S   = Intersection of I and P (successfully recovered therapeutics)")
print("  S/P = Recovery rate (S/P × 100%)")
print("  S/I = Precision rate (S/I × 100%)")
print("\n" + "=" * 80)
print("Template created successfully!")
print("Please populate U, P, I, S columns with actual analysis results.")
