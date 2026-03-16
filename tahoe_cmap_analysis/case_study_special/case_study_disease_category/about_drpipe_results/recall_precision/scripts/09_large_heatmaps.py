#!/usr/bin/env python3
"""
Generate heatmaps:
1. Top 100 diseases by recall
2. All diseases
(without category labels - clean simple heatmaps)
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

print("=" * 80)
print("GENERATING LARGE HEATMAPS: TOP 100 + ALL DISEASES")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "intermediate_data"
fig_dir = base_dir / "figures"
about_dir = base_dir.parent

# Load data
print("\n✓ Loading precision/recall data...")
cmap_results = pd.read_csv(output_dir / "cmap_precision_recall_per_disease.csv")
tahoe_results = pd.read_csv(output_dir / "tahoe_precision_recall_per_disease.csv")

# Load raw data to get actual disease names
print("✓ Loading raw discovery data to map disease IDs to names...")
all_cmap = pd.read_csv(about_dir / "all_discoveries_cmap.csv")
all_tahoe = pd.read_csv(about_dir / "all_discoveries_tahoe.csv")

# Create disease name mapping
cmap_disease_map = {}
tahoe_disease_map = {}

for category in all_cmap['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_cmap[all_cmap['disease_therapeutic_areas'] == category]['disease_name'].unique()
        for disease in diseases_in_category:
            cmap_disease_map[category] = disease
            break

for category in all_tahoe['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_tahoe[all_tahoe['disease_therapeutic_areas'] == category]['disease_name'].unique()
        for disease in diseases_in_category:
            tahoe_disease_map[category] = disease
            break

# Add actual disease names
cmap_results['disease_name'] = cmap_results['Disease'].map(cmap_disease_map).fillna(cmap_results['Disease'])
tahoe_results['disease_name'] = tahoe_results['Disease'].map(tahoe_disease_map).fillna(tahoe_results['Disease'])

# =========================================================================
# HEATMAP 1: TOP 100 DISEASES BY RECALL
# =========================================================================
print("\n✓ Creating heatmap for TOP 100 diseases...")

top_cmap = cmap_results.nlargest(50, 'Recall_%')
top_tahoe = tahoe_results.nlargest(50, 'Recall_%')

top_100_diseases = pd.concat([
    top_cmap[['disease_name', 'Precision_%', 'Recall_%']].assign(platform='CMAP'),
    top_tahoe[['disease_name', 'Precision_%', 'Recall_%']].assign(platform='TAHOE')
]).drop_duplicates(subset=['disease_name']).head(100)

# Sort by recall descending
top_100_diseases = top_100_diseases.sort_values('Recall_%', ascending=False)

# Create heatmap data
heatmap_top100 = pd.DataFrame(
    index=top_100_diseases['disease_name'].values, 
    columns=['CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall']
)

for idx, row in top_100_diseases.iterrows():
    disease_name = row['disease_name']
    
    cmap_row = cmap_results[cmap_results['disease_name'] == disease_name]
    if not cmap_row.empty:
        heatmap_top100.loc[disease_name, 'CMAP Prec'] = cmap_row.iloc[0]['Precision_%']
        heatmap_top100.loc[disease_name, 'CMAP Recall'] = cmap_row.iloc[0]['Recall_%']
    
    tahoe_row = tahoe_results[tahoe_results['disease_name'] == disease_name]
    if not tahoe_row.empty:
        heatmap_top100.loc[disease_name, 'TAHOE Prec'] = tahoe_row.iloc[0]['Precision_%']
        heatmap_top100.loc[disease_name, 'TAHOE Recall'] = tahoe_row.iloc[0]['Recall_%']

heatmap_top100 = heatmap_top100.fillna(0).astype(float)

# Create figure
fig, ax = plt.subplots(figsize=(10, 32))
sns.heatmap(heatmap_top100, annot=False, cmap='RdYlGn', 
           cbar_kws={'label': 'Percentage (%)'}, ax=ax, linewidths=0.2, vmin=0, vmax=100)
ax.set_title('Per-Disease Precision and Recall Heatmap\n(Top 100 Diseases by Recall)', 
            fontsize=13, fontweight='bold', pad=20)
ax.set_xlabel('Metric', fontsize=12, fontweight='bold')
ax.set_ylabel('Disease', fontsize=11, fontweight='bold')

plt.setp(ax.get_yticklabels(), rotation=0, fontsize=6)
plt.setp(ax.get_xticklabels(), rotation=45, ha='right', fontsize=10)

plt.tight_layout()
plt.savefig(fig_dir / "Figure_5D_Top100_Disease_Heatmap.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: Figure_5D_Top100_Disease_Heatmap.png ({len(heatmap_top100)} diseases)")

# =========================================================================
# HEATMAP 2: ALL DISEASES
# =========================================================================
print("\n✓ Creating heatmap for ALL diseases...")

all_diseases = pd.concat([
    cmap_results[['disease_name', 'Precision_%', 'Recall_%']].assign(platform='CMAP'),
    tahoe_results[['disease_name', 'Precision_%', 'Recall_%']].assign(platform='TAHOE')
]).drop_duplicates(subset=['disease_name'])

# Sort by recall descending
all_diseases = all_diseases.sort_values('Recall_%', ascending=False)

# Create heatmap data
heatmap_all = pd.DataFrame(
    index=all_diseases['disease_name'].values, 
    columns=['CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall']
)

for idx, row in all_diseases.iterrows():
    disease_name = row['disease_name']
    
    cmap_row = cmap_results[cmap_results['disease_name'] == disease_name]
    if not cmap_row.empty:
        heatmap_all.loc[disease_name, 'CMAP Prec'] = cmap_row.iloc[0]['Precision_%']
        heatmap_all.loc[disease_name, 'CMAP Recall'] = cmap_row.iloc[0]['Recall_%']
    
    tahoe_row = tahoe_results[tahoe_results['disease_name'] == disease_name]
    if not tahoe_row.empty:
        heatmap_all.loc[disease_name, 'TAHOE Prec'] = tahoe_row.iloc[0]['Precision_%']
        heatmap_all.loc[disease_name, 'TAHOE Recall'] = tahoe_row.iloc[0]['Recall_%']

heatmap_all = heatmap_all.fillna(0).astype(float)

# Create figure with very small text for readability
fig, ax = plt.subplots(figsize=(10, 120))
sns.heatmap(heatmap_all, annot=False, cmap='RdYlGn', 
           cbar_kws={'label': 'Percentage (%)'}, ax=ax, linewidths=0.1, vmin=0, vmax=100)
ax.set_title(f'Per-Disease Precision and Recall Heatmap\n(All {len(heatmap_all)} Diseases)', 
            fontsize=13, fontweight='bold', pad=20)
ax.set_xlabel('Metric', fontsize=12, fontweight='bold')
ax.set_ylabel('Disease', fontsize=10, fontweight='bold')

plt.setp(ax.get_yticklabels(), rotation=0, fontsize=3)
plt.setp(ax.get_xticklabels(), rotation=45, ha='right', fontsize=10)

plt.tight_layout()
plt.savefig(fig_dir / "Figure_5E_All_Diseases_Heatmap.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: Figure_5E_All_Diseases_Heatmap.png ({len(heatmap_all)} diseases)")

print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print(f"\n✓ Figure_5D_Top100_Disease_Heatmap.png")
print(f"  • {len(heatmap_top100)} diseases")
print(f"  • Sorted by recall (highest first)")
print(f"  • No annotations, clean color visualization")

print(f"\n✓ Figure_5E_All_Diseases_Heatmap.png")
print(f"  • {len(heatmap_all)} diseases (ALL CMAP + TAHOE)")
print(f"  • Sorted by recall (highest first)")
print(f"  • Very fine scale for comprehensive view")

print(f"\n" + "=" * 80)
print("FILES GENERATED SUCCESSFULLY")
print("=" * 80)
