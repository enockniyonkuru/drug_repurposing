#!/usr/bin/env python3
"""
Create 4 CSV files:
1. All 233 disease names from CREEDS
2. All drug names for TAHOE
3. All drug names for CMAP
4. Overlapping drugs between CMAP and TAHOE
"""

import os
import pandas as pd
import csv
from pathlib import Path

# Define base paths
base_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing"
disease_sig_dir = f"{base_dir}/tahoe_cmap_analysis/data/disease_signatures/creeds_manual_disease_signatures"
cmap_drugs_file = f"{base_dir}/scripts/data/drug_signatures/cmap_drug_experiments_new.csv"
tahoe_drugs_file = f"{base_dir}/scripts/data/drug_signatures/tahoe_drug_experiments_new.csv"
shared_drugs_file = f"{base_dir}/tahoe_cmap_analysis/data/shared_drugs_cmap_tahoe.csv"
output_dir = base_dir

print("Creating 4 CSV files...")
print("=" * 80)

# 1. Extract all disease names from CREEDS disease signatures
print("\n1. Extracting 233 disease names from CREEDS...")
disease_names = []
for filename in os.listdir(disease_sig_dir):
    if filename.endswith('_signature.csv'):
        # Remove '_signature.csv' suffix to get disease name
        disease_name = filename.replace('_signature.csv', '')
        # Replace underscores with spaces
        disease_name = disease_name.replace('_', ' ')
        disease_names.append(disease_name)

disease_names.sort()
diseases_csv_path = os.path.join(output_dir, "creeds_diseases_233.csv")
with open(diseases_csv_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['disease_name'])
    for disease in disease_names:
        writer.writerow([disease])
print(f"   ✓ Created {diseases_csv_path}")
print(f"   ✓ Total diseases: {len(disease_names)}")

# 2. Extract unique drug names for CMAP
print("\n2. Extracting drug names for CMAP...")
cmap_df = pd.read_csv(cmap_drugs_file)
cmap_drugs = sorted(cmap_df['name'].unique().tolist())
cmap_csv_path = os.path.join(output_dir, "cmap_drugs.csv")
with open(cmap_csv_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['drug_name'])
    for drug in cmap_drugs:
        writer.writerow([drug])
print(f"   ✓ Created {cmap_csv_path}")
print(f"   ✓ Total CMAP drugs: {len(cmap_drugs)}")

# 3. Extract unique drug names for TAHOE
print("\n3. Extracting drug names for TAHOE...")
tahoe_df = pd.read_csv(tahoe_drugs_file)
tahoe_drugs = sorted(tahoe_df['name'].unique().tolist())
tahoe_csv_path = os.path.join(output_dir, "tahoe_drugs.csv")
with open(tahoe_csv_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['drug_name'])
    for drug in tahoe_drugs:
        writer.writerow([drug])
print(f"   ✓ Created {tahoe_csv_path}")
print(f"   ✓ Total TAHOE drugs: {len(tahoe_drugs)}")

# 4. Extract overlapping drugs between CMAP and TAHOE
print("\n4. Extracting overlapping drugs between CMAP and TAHOE...")
# Use the existing shared_drugs file
shared_df = pd.read_csv(shared_drugs_file)
shared_drugs = sorted(shared_df['drug_name_standard'].unique().tolist())
overlap_csv_path = os.path.join(output_dir, "overlap_drugs_cmap_tahoe.csv")
with open(overlap_csv_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['drug_name'])
    for drug in shared_drugs:
        writer.writerow([drug])
print(f"   ✓ Created {overlap_csv_path}")
print(f"   ✓ Total overlapping drugs: {len(shared_drugs)}")

print("\n" + "=" * 80)
print("Summary:")
print(f"  • {diseases_csv_path}")
print(f"  • {cmap_csv_path}")
print(f"  • {tahoe_csv_path}")
print(f"  • {overlap_csv_path}")
print("\nAll CSV files created successfully!")
