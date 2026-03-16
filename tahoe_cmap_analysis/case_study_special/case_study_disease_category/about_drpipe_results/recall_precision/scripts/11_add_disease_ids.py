#!/usr/bin/env python3
"""
Add disease IDs to the CSV tables
"""

import pandas as pd
from pathlib import Path

print("=" * 80)
print("ADDING DISEASE IDs TO CSV TABLES")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "outputs"
about_dir = base_dir.parent

# Load raw data
print("\n✓ Loading raw discovery data...")
all_cmap = pd.read_csv(about_dir / "all_discoveries_cmap.csv")
all_tahoe = pd.read_csv(about_dir / "all_discoveries_tahoe.csv")

# Create disease name to ID mapping
print("✓ Creating disease name to ID mappings...")
cmap_disease_to_id = {}
tahoe_disease_to_id = {}

# For CMAP
for _, row in all_cmap.iterrows():
    disease_name = row['disease_name']
    disease_id = row['disease_id']
    if pd.notna(disease_name) and pd.notna(disease_id):
        if disease_name not in cmap_disease_to_id:
            cmap_disease_to_id[disease_name] = disease_id

# For TAHOE
for _, row in all_tahoe.iterrows():
    disease_name = row['disease_name']
    disease_id = row['disease_id']
    if pd.notna(disease_name) and pd.notna(disease_id):
        if disease_name not in tahoe_disease_to_id:
            tahoe_disease_to_id[disease_name] = disease_id

print(f"✓ Created {len(cmap_disease_to_id)} CMAP disease ID mappings")
print(f"✓ Created {len(tahoe_disease_to_id)} TAHOE disease ID mappings")

# =========================================================================
# UPDATE TABLE S1: CMAP
# =========================================================================
print("\n✓ Updating Table_S1_CMAP_Precision_Recall.csv...")
cmap_table = pd.read_csv(output_dir / "Table_S1_CMAP_Precision_Recall.csv")

# Add disease ID column
cmap_table['Disease_ID'] = cmap_table['Disease'].map(cmap_disease_to_id)

# Reorder columns: Disease_ID, Disease, I, S, P, Precision, Recall
cmap_table = cmap_table[['Disease_ID', 'Disease', 'I', 'S', 'P', 'Precision', 'Recall']]

print(f"  • Rows: {len(cmap_table)}")
print(f"  • Disease IDs mapped: {cmap_table['Disease_ID'].notna().sum()}")
print(f"  • Sample:")
for idx, (_, row) in enumerate(cmap_table.head(3).iterrows(), 1):
    print(f"    {idx}. {row['Disease_ID']:15s} | {row['Disease']:35s} | P: {row['Precision']:5.1f}% | R: {row['Recall']:5.1f}%")

cmap_table.to_csv(output_dir / "Table_S1_CMAP_Precision_Recall.csv", index=False)
print(f"  ✓ Saved: Table_S1_CMAP_Precision_Recall.csv")

# =========================================================================
# UPDATE TABLE S2: TAHOE
# =========================================================================
print("\n✓ Updating Table_S2_TAHOE_Precision_Recall.csv...")
tahoe_table = pd.read_csv(output_dir / "Table_S2_TAHOE_Precision_Recall.csv")

# Add disease ID column
tahoe_table['Disease_ID'] = tahoe_table['Disease'].map(tahoe_disease_to_id)

# Reorder columns
tahoe_table = tahoe_table[['Disease_ID', 'Disease', 'I', 'S', 'P', 'Precision', 'Recall']]

print(f"  • Rows: {len(tahoe_table)}")
print(f"  • Disease IDs mapped: {tahoe_table['Disease_ID'].notna().sum()}")
print(f"  • Sample:")
for idx, (_, row) in enumerate(tahoe_table.head(3).iterrows(), 1):
    print(f"    {idx}. {row['Disease_ID']:15s} | {row['Disease']:35s} | P: {row['Precision']:5.1f}% | R: {row['Recall']:5.1f}%")

tahoe_table.to_csv(output_dir / "Table_S2_TAHOE_Precision_Recall.csv", index=False)
print(f"  ✓ Saved: Table_S2_TAHOE_Precision_Recall.csv")

# Print summary
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print(f"\n✓ Table_S1_CMAP_Precision_Recall.csv")
print(f"  • Total diseases: {len(cmap_table)}")
print(f"  • Disease IDs added: {cmap_table['Disease_ID'].notna().sum()}")
print(f"  • Columns: Disease_ID, Disease, I, S, P, Precision, Recall")

print(f"\n✓ Table_S2_TAHOE_Precision_Recall.csv")
print(f"  • Total diseases: {len(tahoe_table)}")
print(f"  • Disease IDs added: {tahoe_table['Disease_ID'].notna().sum()}")
print(f"  • Columns: Disease_ID, Disease, I, S, P, Precision, Recall")

print("\n" + "=" * 80)
print("TABLES UPDATED SUCCESSFULLY")
print("=" * 80)
