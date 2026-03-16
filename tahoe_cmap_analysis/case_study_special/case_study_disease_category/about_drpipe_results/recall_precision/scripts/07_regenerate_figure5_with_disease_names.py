#!/usr/bin/env python3
"""
Regenerate Figure 5 with actual disease names instead of category combinations
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

print("=" * 80)
print("REGENERATING FIGURE 5 WITH ACTUAL DISEASE NAMES")
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

# Create mapping from disease category string to actual disease name
cmap_disease_map = {}
tahoe_disease_map = {}

# For CMAP - group by disease_therapeutic_areas (category) and get actual disease names
for category in all_cmap['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_cmap[all_cmap['disease_therapeutic_areas'] == category]['disease_name'].unique()
        for disease in diseases_in_category:
            cmap_disease_map[category] = disease
            break  # Just take first one per category

# For TAHOE
for category in all_tahoe['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_tahoe[all_tahoe['disease_therapeutic_areas'] == category]['disease_name'].unique()
        for disease in diseases_in_category:
            tahoe_disease_map[category] = disease
            break  # Just take first one per category

print(f"\n✓ Found {len(cmap_disease_map)} CMAP disease categories")
print(f"✓ Found {len(tahoe_disease_map)} TAHOE disease categories")

# Add actual disease names to results dataframes
cmap_results['disease_name'] = cmap_results['Disease'].map(cmap_disease_map).fillna(cmap_results['Disease'])
tahoe_results['disease_name'] = tahoe_results['Disease'].map(tahoe_disease_map).fillna(tahoe_results['Disease'])

# Get top 20 diseases by recall
print("\n✓ Selecting top 20 diseases by recall...")
top_cmap = cmap_results.nlargest(15, 'Recall_%')
top_tahoe = tahoe_results.nlargest(15, 'Recall_%')

# Combine and deduplicate
top_diseases = pd.concat([
    top_cmap[['disease_name', 'Disease', 'Precision_%', 'Recall_%']].assign(platform='CMAP'),
    top_tahoe[['disease_name', 'Disease', 'Precision_%', 'Recall_%']].assign(platform='TAHOE')
]).drop_duplicates(subset=['disease_name']).head(20)

# Create heatmap data
heatmap_matrix = pd.DataFrame(index=top_diseases['disease_name'].values, 
                              columns=['CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall'])

for idx, row in top_diseases.iterrows():
    disease_name = row['disease_name']
    
    # Get CMAP data
    cmap_row = cmap_results[cmap_results['disease_name'] == disease_name]
    if not cmap_row.empty:
        heatmap_matrix.loc[disease_name, 'CMAP Prec'] = cmap_row.iloc[0]['Precision_%']
        heatmap_matrix.loc[disease_name, 'CMAP Recall'] = cmap_row.iloc[0]['Recall_%']
    
    # Get TAHOE data
    tahoe_row = tahoe_results[tahoe_results['disease_name'] == disease_name]
    if not tahoe_row.empty:
        heatmap_matrix.loc[disease_name, 'TAHOE Prec'] = tahoe_row.iloc[0]['Precision_%']
        heatmap_matrix.loc[disease_name, 'TAHOE Recall'] = tahoe_row.iloc[0]['Recall_%']

heatmap_matrix = heatmap_matrix.fillna(0).astype(float)

# Create figure
print("✓ Creating heatmap figure...")
fig, ax = plt.subplots(figsize=(10, 14))
sns.heatmap(heatmap_matrix, annot=True, fmt='.1f', cmap='RdYlGn', 
           cbar_kws={'label': 'Percentage (%)'}, ax=ax, linewidths=0.5, vmin=0, vmax=100)
ax.set_title('Per-Disease Precision and Recall Heatmap\n(Top 20 Diseases by Recall - Using Actual Disease Names)', 
            fontsize=13, fontweight='bold', pad=20)
ax.set_xlabel('Metric', fontsize=12, fontweight='bold')
ax.set_ylabel('Disease', fontsize=12, fontweight='bold')

# Rotate y-axis labels for readability
plt.setp(ax.get_yticklabels(), rotation=0, fontsize=10)
plt.setp(ax.get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
plt.savefig(fig_dir / "Figure_5_Disease_Heatmap.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: Figure_5_Disease_Heatmap.png")

# Also save a version with category grouping
print("\n✓ Creating category-grouped heatmap...")

# Get primary category
def get_primary_category(disease_string):
    if '|' in str(disease_string):
        return disease_string.split('|')[0]
    return disease_string

cmap_results['primary_category'] = cmap_results['Disease'].apply(get_primary_category)
tahoe_results['primary_category'] = tahoe_results['Disease'].apply(get_primary_category)

# Group by category
categories = sorted(set(list(cmap_results['primary_category'].unique()) + list(tahoe_results['primary_category'].unique())))
print(f"✓ Found {len(categories)} primary disease categories")

# Create category-grouped heatmap
grouped_diseases = []
for category in categories:
    cmap_cat = cmap_results[cmap_results['primary_category'] == category].nlargest(2, 'Recall_%')
    tahoe_cat = tahoe_results[tahoe_results['primary_category'] == category].nlargest(2, 'Recall_%')
    
    for _, row in pd.concat([cmap_cat, tahoe_cat]).drop_duplicates(subset=['disease_name']).iterrows():
        grouped_diseases.append({
            'disease_name': row['disease_name'],
            'category': category,
            'platform': 'CMAP' if row['Disease'] in cmap_results['Disease'].values else 'TAHOE'
        })

# Create heatmap with grouping
heatmap_grouped = pd.DataFrame(index=[d['disease_name'] for d in grouped_diseases],
                               columns=['Category', 'CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall'])

for idx, disease_info in enumerate(grouped_diseases):
    disease_name = disease_info['disease_name']
    heatmap_grouped.loc[disease_name, 'Category'] = disease_info['category']
    
    cmap_row = cmap_results[cmap_results['disease_name'] == disease_name]
    if not cmap_row.empty:
        heatmap_grouped.loc[disease_name, 'CMAP Prec'] = cmap_row.iloc[0]['Precision_%']
        heatmap_grouped.loc[disease_name, 'CMAP Recall'] = cmap_row.iloc[0]['Recall_%']
    
    tahoe_row = tahoe_results[tahoe_results['disease_name'] == disease_name]
    if not tahoe_row.empty:
        heatmap_grouped.loc[disease_name, 'TAHOE Prec'] = tahoe_row.iloc[0]['Precision_%']
        heatmap_grouped.loc[disease_name, 'TAHOE Recall'] = tahoe_row.iloc[0]['Recall_%']

# Drop category column and create numeric heatmap
heatmap_grouped_numeric = heatmap_grouped[['CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall']].fillna(0).astype(float)

fig, ax = plt.subplots(figsize=(10, 16))
sns.heatmap(heatmap_grouped_numeric, annot=True, fmt='.1f', cmap='RdYlGn', 
           cbar_kws={'label': 'Percentage (%)'}, ax=ax, linewidths=0.5, vmin=0, vmax=100)
ax.set_title('Per-Disease Precision and Recall Heatmap\n(Grouped by Primary Disease Category)', 
            fontsize=13, fontweight='bold', pad=20)
ax.set_xlabel('Metric', fontsize=12, fontweight='bold')
ax.set_ylabel('Disease (grouped by category)', fontsize=12, fontweight='bold')

plt.setp(ax.get_yticklabels(), rotation=0, fontsize=9)
plt.setp(ax.get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
plt.savefig(fig_dir / "Figure_5B_Disease_Heatmap_by_Category.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: Figure_5B_Disease_Heatmap_by_Category.png")

print("\n" + "=" * 80)
print("FIGURE 5 REGENERATED WITH ACTUAL DISEASE NAMES")
print("=" * 80)
print(f"\nGenerated Files:")
print(f"  ✓ Figure_5_Disease_Heatmap.png (Top 20 diseases by recall)")
print(f"  ✓ Figure_5B_Disease_Heatmap_by_Category.png (Grouped by disease category)")

# Print sample of disease names
print(f"\nSample disease names (top 10 by recall):")
for i, disease in enumerate(heatmap_matrix.index[:10], 1):
    print(f"  {i}. {disease}")
