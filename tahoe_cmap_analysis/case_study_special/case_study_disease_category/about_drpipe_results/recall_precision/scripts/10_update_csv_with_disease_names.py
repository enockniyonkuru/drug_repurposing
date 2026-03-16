#!/usr/bin/env python3
"""
Update CSV tables to use actual disease names instead of category combinations
"""

import pandas as pd
from pathlib import Path

print("=" * 80)
print("UPDATING CSV TABLES WITH ACTUAL DISEASE NAMES")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "outputs"
about_dir = base_dir.parent

# Load raw data to create disease name mapping
print("\n✓ Loading raw discovery data...")
all_cmap = pd.read_csv(about_dir / "all_discoveries_cmap.csv")
all_tahoe = pd.read_csv(about_dir / "all_discoveries_tahoe.csv")

# Create disease name mapping (category -> disease name)
print("✓ Creating disease name mappings...")
cmap_disease_map = {}
tahoe_disease_map = {}

for category in all_cmap['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_cmap[all_cmap['disease_therapeutic_areas'] == category]['disease_name'].unique()
        if len(diseases_in_category) > 0:
            cmap_disease_map[category] = diseases_in_category[0]

for category in all_tahoe['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_tahoe[all_tahoe['disease_therapeutic_areas'] == category]['disease_name'].unique()
        if len(diseases_in_category) > 0:
            tahoe_disease_map[category] = diseases_in_category[0]

print(f"✓ Created {len(cmap_disease_map)} CMAP disease mappings")
print(f"✓ Created {len(tahoe_disease_map)} TAHOE disease mappings")

# =========================================================================
# UPDATE TABLE S1: CMAP
# =========================================================================
print("\n✓ Updating Table_S1_CMAP_Precision_Recall.csv...")
cmap_table = pd.read_csv(output_dir / "Table_S1_CMAP_Precision_Recall.csv")

print(f"  Before: {len(cmap_table)} rows")
print(f"  Sample disease entries:")
for i, disease in enumerate(cmap_table['Disease'].head(5)):
    print(f"    {i+1}. {disease}")

# Map to actual disease names
cmap_table['Disease'] = cmap_table['Disease'].map(cmap_disease_map).fillna(cmap_table['Disease'])

# Remove duplicates (keep first occurrence which has highest recall due to sorting)
cmap_table_unique = cmap_table.drop_duplicates(subset=['Disease'], keep='first')

print(f"  After: {len(cmap_table_unique)} unique rows")
print(f"  Sample disease names (after mapping):")
for i, disease in enumerate(cmap_table_unique['Disease'].head(5)):
    print(f"    {i+1}. {disease}")

# Save updated table
cmap_table_unique.to_csv(output_dir / "Table_S1_CMAP_Precision_Recall.csv", index=False)
print(f"  ✓ Saved: Table_S1_CMAP_Precision_Recall.csv")

# =========================================================================
# UPDATE TABLE S2: TAHOE
# =========================================================================
print("\n✓ Updating Table_S2_TAHOE_Precision_Recall.csv...")
tahoe_table = pd.read_csv(output_dir / "Table_S2_TAHOE_Precision_Recall.csv")

print(f"  Before: {len(tahoe_table)} rows")
print(f"  Sample disease entries:")
for i, disease in enumerate(tahoe_table['Disease'].head(5)):
    print(f"    {i+1}. {disease}")

# Map to actual disease names
tahoe_table['Disease'] = tahoe_table['Disease'].map(tahoe_disease_map).fillna(tahoe_table['Disease'])

# Remove duplicates
tahoe_table_unique = tahoe_table.drop_duplicates(subset=['Disease'], keep='first')

print(f"  After: {len(tahoe_table_unique)} unique rows")
print(f"  Sample disease names (after mapping):")
for i, disease in enumerate(tahoe_table_unique['Disease'].head(5)):
    print(f"    {i+1}. {disease}")

# Save updated table
tahoe_table_unique.to_csv(output_dir / "Table_S2_TAHOE_Precision_Recall.csv", index=False)
print(f"  ✓ Saved: Table_S2_TAHOE_Precision_Recall.csv")

# Print summary
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print(f"\n✓ Table_S1_CMAP_Precision_Recall.csv")
print(f"  • Original: {len(cmap_table)} entries")
print(f"  • Updated: {len(cmap_table_unique)} unique diseases")
print(f"  • Mean Precision: {cmap_table_unique['Precision'].mean():.2f}%")
print(f"  • Mean Recall: {cmap_table_unique['Recall'].mean():.2f}%")

print(f"\n✓ Table_S2_TAHOE_Precision_Recall.csv")
print(f"  • Original: {len(tahoe_table)} entries")
print(f"  • Updated: {len(tahoe_table_unique)} unique diseases")
print(f"  • Mean Precision: {tahoe_table_unique['Precision'].mean():.2f}%")
print(f"  • Mean Recall: {tahoe_table_unique['Recall'].mean():.2f}%")

print("\n" + "=" * 80)
print("VERIFICATION")
print("=" * 80)

print(f"\nTop 5 CMAP diseases (by Recall):")
for idx, (_, row) in enumerate(cmap_table_unique.head(5).iterrows(), 1):
    print(f"  {idx}. {row['Disease']:40s} | P: {row['Precision']:5.1f}% | R: {row['Recall']:5.1f}%")

print(f"\nTop 5 TAHOE diseases (by Recall):")
for idx, (_, row) in enumerate(tahoe_table_unique.head(5).iterrows(), 1):
    print(f"  {idx}. {row['Disease']:40s} | P: {row['Precision']:5.1f}% | R: {row['Recall']:5.1f}%")

print("\n" + "=" * 80)
print("TABLES UPDATED SUCCESSFULLY")
print("=" * 80)
