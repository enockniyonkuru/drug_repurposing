#!/usr/bin/env python3
"""
Generate heatmap grouped by primary therapeutic area from creeds_diseases_info.csv
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import matplotlib.patches as mpatches

print("=" * 80)
print("GENERATING HEATMAP GROUPED BY PRIMARY THERAPEUTIC AREA")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "intermediate_data"
fig_dir = base_dir / "figures"
about_dir = base_dir.parent
diseases_info_path = about_dir.parent / "about_diseases" / "creeds_diseases_info.csv"

# Load data
print("\n✓ Loading precision/recall data...")
cmap_results = pd.read_csv(output_dir / "cmap_precision_recall_per_disease.csv")
tahoe_results = pd.read_csv(output_dir / "tahoe_precision_recall_per_disease.csv")

# Load raw data to get actual disease names
print("✓ Loading raw discovery data to map disease IDs to names...")
all_cmap = pd.read_csv(about_dir / "all_discoveries_cmap.csv")
all_tahoe = pd.read_csv(about_dir / "all_discoveries_tahoe.csv")

# Load therapeutic areas mapping
print(f"✓ Loading therapeutic areas mapping from {diseases_info_path.name}...")
diseases_info = pd.read_csv(diseases_info_path)

# Create mapping from disease name to therapeutic areas
disease_to_therapeutic = {}
for _, row in diseases_info.iterrows():
    if pd.notna(row['disease_name']) and pd.notna(row['therapeutic_areas']):
        disease_name = row['disease_name'].lower()
        therapeutic_areas = str(row['therapeutic_areas']).split('|')
        primary_area = therapeutic_areas[0]
        disease_to_therapeutic[disease_name] = primary_area

print(f"✓ Mapped {len(disease_to_therapeutic)} diseases to therapeutic areas")

# Create mapping from disease category string to actual disease name
cmap_disease_map = {}
tahoe_disease_map = {}

# For CMAP
for category in all_cmap['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_cmap[all_cmap['disease_therapeutic_areas'] == category]['disease_name'].unique()
        for disease in diseases_in_category:
            cmap_disease_map[category] = disease
            break

# For TAHOE
for category in all_tahoe['disease_therapeutic_areas'].unique():
    if pd.notna(category):
        diseases_in_category = all_tahoe[all_tahoe['disease_therapeutic_areas'] == category]['disease_name'].unique()
        for disease in diseases_in_category:
            tahoe_disease_map[category] = disease
            break

# Add actual disease names to results dataframes
cmap_results['disease_name'] = cmap_results['Disease'].map(cmap_disease_map).fillna(cmap_results['Disease'])
tahoe_results['disease_name'] = tahoe_results['Disease'].map(tahoe_disease_map).fillna(tahoe_results['Disease'])

# Map therapeutic areas
cmap_results['therapeutic_area'] = cmap_results['disease_name'].str.lower().map(disease_to_therapeutic)
tahoe_results['therapeutic_area'] = tahoe_results['disease_name'].str.lower().map(disease_to_therapeutic)

# Get top diseases by recall
print("\n✓ Selecting diseases and grouping by therapeutic area...")
top_cmap = cmap_results.nlargest(12, 'Recall_%')
top_tahoe = tahoe_results.nlargest(12, 'Recall_%')

# Combine and deduplicate
top_diseases = pd.concat([
    top_cmap[['disease_name', 'Disease', 'Precision_%', 'Recall_%', 'therapeutic_area']].assign(platform='CMAP'),
    top_tahoe[['disease_name', 'Disease', 'Precision_%', 'Recall_%', 'therapeutic_area']].assign(platform='TAHOE')
]).drop_duplicates(subset=['disease_name']).head(24)

print(f"✓ Selected {len(top_diseases)} unique diseases")

# Sort by therapeutic area
top_diseases = top_diseases.sort_values(['therapeutic_area', 'Recall_%'], ascending=[True, False])

# Create heatmap data
heatmap_matrix = pd.DataFrame(
    index=top_diseases['disease_name'].values, 
    columns=['CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall']
)

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

# Create therapeutic area labels
therapeutic_labels = []
current_area = None
for disease in heatmap_matrix.index:
    for idx, row in top_diseases.iterrows():
        if row['disease_name'] == disease:
            area = row['therapeutic_area'] if pd.notna(row['therapeutic_area']) else 'Unknown'
            if area != current_area:
                current_area = area
                therapeutic_labels.append(f"\n{area}")
            else:
                therapeutic_labels.append("")
            break

# Identify therapeutic area boundaries
therapeutic_areas = top_diseases['therapeutic_area'].unique()
group_boundaries = []
current_row = 0

for area in therapeutic_areas:
    group_size = len(top_diseases[top_diseases['therapeutic_area'] == area])
    group_boundaries.append({
        'area': area,
        'start': current_row,
        'end': current_row + group_size,
        'size': group_size
    })
    current_row += group_size

print(f"\n✓ Therapeutic Area Groups:")
for group in group_boundaries:
    print(f"  • {group['area']}: rows {group['start']}-{group['end']-1} ({group['size']} diseases)")

# Create figure with visual grouping - IMPROVED VERSION
print("\n✓ Creating figure with visual grouping (no text overlap)...")

# Color map for therapeutic areas
colors_dict = {area: plt.cm.Set3(i / len(therapeutic_areas)) for i, area in enumerate(therapeutic_areas)}

# Create figure with extra space for color bar
fig = plt.figure(figsize=(14, 20))
gs = fig.add_gridspec(1, 2, width_ratios=[0.15, 1], wspace=0.02)
ax_colors = fig.add_subplot(gs[0])
ax_heatmap = fig.add_subplot(gs[1])

# Create heatmap
sns.heatmap(heatmap_matrix, annot=True, fmt='.1f', cmap='RdYlGn', 
           cbar_kws={'label': 'Percentage (%)'}, ax=ax_heatmap, linewidths=0.5, vmin=0, vmax=100)

# Create color bar on the left showing therapeutic areas
y_position = len(heatmap_matrix) - 0.5
color_blocks = []
for i, group in enumerate(group_boundaries):
    if group['size'] > 0:
        # Draw colored rectangle for each therapeutic area
        rect = mpatches.Rectangle((0, group['start']), 1, group['size'], 
                                  facecolor=colors_dict[group['area']], 
                                  edgecolor='black', linewidth=1.5)
        ax_colors.add_patch(rect)
        
        # Add horizontal lines between groups
        if group['start'] > 0:
            ax_heatmap.axhline(y=group['start'], color='black', linewidth=2)

# Format color bar axis
ax_colors.set_xlim(0, 1)
ax_colors.set_ylim(0, len(heatmap_matrix))
ax_colors.set_xticks([])
ax_colors.set_ylabel('Therapeutic Area', fontsize=11, fontweight='bold')
ax_colors.invert_yaxis()

# Create legend
legend_elements = [mpatches.Patch(facecolor=colors_dict[area], edgecolor='black', 
                                  label=area) for area in therapeutic_areas if area in colors_dict]
fig.legend(handles=legend_elements, loc='upper center', bbox_to_anchor=(0.5, -0.02), 
          ncol=4, fontsize=10, frameon=True, title='Therapeutic Areas')

# Formatting
ax_heatmap.set_title('Per-Disease Precision and Recall Heatmap\nGrouped by Primary Therapeutic Area', 
            fontsize=14, fontweight='bold', pad=20)
ax_heatmap.set_xlabel('Metric', fontsize=12, fontweight='bold')
ax_heatmap.set_ylabel('Disease', fontsize=11, fontweight='bold')

plt.setp(ax_heatmap.get_yticklabels(), rotation=0, fontsize=9.5)
plt.setp(ax_heatmap.get_xticklabels(), rotation=45, ha='right', fontsize=11)

plt.savefig(fig_dir / "Figure_5C_Disease_Heatmap_by_Therapeutic_Area.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: Figure_5C_Disease_Heatmap_by_Therapeutic_Area.png (clean layout, no overlap)")

print("\n" + "=" * 80)
print("VISUAL GROUPING EXPLANATION")
print("=" * 80)
print("""
HOW THE GROUPING WORKS:

1. DATA ORGANIZATION:
   - Diseases are sorted by therapeutic_area (primary category)
   - Within each therapeutic area, diseases are sorted by recall (highest first)

2. VISUAL INDICATORS:
   - BLACK HORIZONTAL LINES: Separate different therapeutic areas
   - COLORED LABELS (left side): Show which therapeutic area each group belongs to
   - ROWS GROUPED TOGETHER: Diseases from the same therapeutic area are together

3. THERAPEUTIC AREA GROUPS:
""")

for group in group_boundaries:
    diseases_in_group = top_diseases[top_diseases['therapeutic_area'] == group['area']]['disease_name'].tolist()
    print(f"\n   {group['area']}:")
    for disease in diseases_in_group:
        print(f"      • {disease}")

print("\n" + "=" * 80)
print("FILES GENERATED")
print("=" * 80)
print(f"✓ Figure_5C_Disease_Heatmap_by_Therapeutic_Area.png (clean layout)")
print(f"\nIMPROVEMENTS MADE:")
print(f"  • Color bar on left (no text overlap)")
print(f"  • Legend at bottom shows all therapeutic areas")
print(f"  • Black horizontal lines separate groups")
print(f"  • Increased figure size for better readability")
