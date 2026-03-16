#!/usr/bin/env python3
"""
Add columns to CMAP and TAHOE drug CSV files indicating cross-availability
"""

import pandas as pd
import os

# Define file paths
base_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"
cmap_drugs_file = os.path.join(base_dir, "cmap_drugs.csv")
tahoe_drugs_file = os.path.join(base_dir, "tahoe_drugs.csv")
overlap_drugs_file = os.path.join(base_dir, "overlap_drugs_cmap_tahoe.csv")

print("Adding cross-availability columns to drug CSV files...")
print("=" * 80)

# Read the drug lists
print("\nReading drug files...")
cmap_df = pd.read_csv(cmap_drugs_file)
tahoe_df = pd.read_csv(tahoe_drugs_file)
overlap_df = pd.read_csv(overlap_drugs_file)

# Get sets of drug names for comparison
cmap_drugs_set = set(cmap_df['drug_name'].str.lower())
tahoe_drugs_set = set(tahoe_df['drug_name'].str.lower())
overlap_drugs_set = set(overlap_df['drug_name'].str.lower())

print(f"   CMAP drugs: {len(cmap_drugs_set)}")
print(f"   TAHOE drugs: {len(tahoe_drugs_set)}")
print(f"   Overlapping drugs: {len(overlap_drugs_set)}")

# Add column to CMAP drugs: "in_tahoe"
print("\nAdding 'in_tahoe' column to CMAP drugs...")
cmap_df['in_tahoe'] = cmap_df['drug_name'].str.lower().isin(tahoe_drugs_set).map({True: 'Yes', False: 'No'})
cmap_df.to_csv(cmap_drugs_file, index=False)
print(f"   ✓ Updated {cmap_drugs_file}")
print(f"   ✓ CMAP drugs in TAHOE: {(cmap_df['in_tahoe'] == 'Yes').sum()}")

# Add column to TAHOE drugs: "in_cmap"
print("\nAdding 'in_cmap' column to TAHOE drugs...")
tahoe_df['in_cmap'] = tahoe_df['drug_name'].str.lower().isin(cmap_drugs_set).map({True: 'Yes', False: 'No'})
tahoe_df.to_csv(tahoe_drugs_file, index=False)
print(f"   ✓ Updated {tahoe_drugs_file}")
print(f"   ✓ TAHOE drugs in CMAP: {(tahoe_df['in_cmap'] == 'Yes').sum()}")

print("\n" + "=" * 80)
print("Done! Both CSV files have been updated with cross-availability columns.")
