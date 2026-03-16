#!/usr/bin/env python3
"""
Create an innovative heatmap showing drug recovery source:
- CMAP Only (Blue)
- TAHOE Only (Orange)  
- Both (Red/Purple)
- None (White)
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import numpy as np
import os
import glob

# Paths
validation_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1"
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"
table1_path = os.path.join(validation_path, "Table1_Disease_Summary.csv")

print("Creating innovative source-tracking heatmap...")
print("=" * 80)

# Read Table1
df_table1 = pd.read_csv(table1_path)
disease_names = df_table1['Disease'].tolist()

print(f"Analyzing {len(disease_names)} diseases...")

# Collect drug sources for each disease
drug_sources = {}  # {disease: {drug: source}}

# Look for recovered drug files
drug_detail_dir = os.path.join(validation_path, "drug_details")
csv_files = glob.glob(os.path.join(drug_detail_dir, "*recovered_drugs.csv"))

print(f"Found {len(csv_files)} disease-specific drug files")

# Parse disease-specific drug files
for csv_file in csv_files:
    filename = os.path.basename(csv_file)
    disease_name = filename.replace("_recovered_drugs.csv", "").replace("_", " ")
    
    try:
        df_drugs = pd.read_csv(csv_file)
        drug_sources[disease_name] = {}
        
        for idx, row in df_drugs.iterrows():
            drug = row['drug']
            source = str(row['source']).strip()
            
            # Determine the source - handle various formats
            if 'BOTH' in source.upper():
                drug_sources[disease_name][drug] = 'BOTH'
            elif 'CMAP' in source.upper() and 'TAHOE' not in source.upper():
                drug_sources[disease_name][drug] = 'CMAP_ONLY'
            elif 'TAHOE' in source.upper() and 'CMAP' not in source.upper():
                drug_sources[disease_name][drug] = 'TAHOE_ONLY'
            else:
                drug_sources[disease_name][drug] = 'OTHER'
                
    except Exception as e:
        print(f"  Warning: Could not parse {filename}: {e}")

# For diseases without specific files, create empty entries
for disease in disease_names:
    if disease not in drug_sources:
        drug_sources[disease] = {}

# Get all unique drugs
all_drugs = set()
for drugs in drug_sources.values():
    all_drugs.update(drugs.keys())

print(f"Total unique drugs found: {len(all_drugs)} drugs")

# Count sources
cmap_only = 0
tahoe_only = 0
both = 0
for drugs in drug_sources.values():
    for source in drugs.values():
        if source == 'CMAP_ONLY':
            cmap_only += 1
        elif source == 'TAHOE_ONLY':
            tahoe_only += 1
        elif source == 'BOTH':
            both += 1

print(f"\nRecovery distribution:")
print(f"  CMAP Only: {cmap_only} instances")
print(f"  TAHOE Only: {tahoe_only} instances")
print(f"  Both: {both} instances")

# Sort drugs by total recovery frequency
drug_freq = {}
for drug in all_drugs:
    count = 0
    for diseases in drug_sources.values():
        if drug in diseases:
            count += 1
    drug_freq[drug] = count

sorted_drugs = sorted(all_drugs, key=lambda x: drug_freq.get(x, 0), reverse=True)

# Create numerical encoding for visualization
# 0 = not recovered, 1 = CMAP only, 2 = TAHOE only, 3 = Both
encoding = {
    'CMAP_ONLY': 1,
    'TAHOE_ONLY': 2,
    'BOTH': 3,
    'OTHER': 0,
    'NONE': 0
}

matrix = []
for disease in disease_names:
    row = []
    for drug in sorted_drugs:
        if drug in drug_sources[disease]:
            source = drug_sources[disease][drug]
            row.append(encoding.get(source, 0))
        else:
            row.append(0)
    matrix.append(row)

df_matrix = pd.DataFrame(matrix, index=disease_names, columns=sorted_drugs)

print(f"\nHeatmap dimensions: {df_matrix.shape[0]} diseases × {df_matrix.shape[1]} drugs")

# Create custom colormap with consistent colors
from matplotlib.colors import ListedColormap, BoundaryNorm
# Color scheme: White (not recovered), Orange (CMAP only), Blue (TAHOE only), Purple (Both)
colors = ['#FFFFFF', '#F39C12', '#5DADE2', '#9B59B6']  # White, Warm Orange (CMAP), Serene Blue (TAHOE), Purple (Both)
n_bins = 4
cmap = ListedColormap(colors)
norm = BoundaryNorm([0, 1, 2, 3, 4], cmap.N)

# Create the heatmap
fig, ax = plt.subplots(figsize=(18, 10))

im = ax.imshow(df_matrix, aspect='auto', cmap=cmap, norm=norm, interpolation='nearest')

# Set ticks and labels
ax.set_xticks(np.arange(len(sorted_drugs)))
ax.set_yticks(np.arange(len(disease_names)))
ax.set_xticklabels(sorted_drugs, fontsize=8, rotation=90)
ax.set_yticklabels(disease_names, fontsize=9)

# Add gridlines
ax.set_xticks(np.arange(len(sorted_drugs))-.5, minor=True)
ax.set_yticks(np.arange(len(disease_names))-.5, minor=True)
ax.grid(which="minor", color="gray", linestyle='-', linewidth=0.5)

# Title and labels
ax.set_title('Drug Recovery Source: CMAP, TAHOE, or Both\nacross 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs', fontsize=12, fontweight='bold')
ax.set_ylabel('Diseases', fontsize=12, fontweight='bold')

# Create custom legend
legend_elements = [
    mpatches.Patch(facecolor='#FFFFFF', edgecolor='black', label='Not Recovered'),
    mpatches.Patch(facecolor='#F39C12', label='CMAP Only'),
    mpatches.Patch(facecolor='#5DADE2', label='TAHOE Only'),
    mpatches.Patch(facecolor='#9B59B6', label='Both Methods')
]
ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.12, 1), fontsize=10)

plt.tight_layout()

# Save PNG
png_output = os.path.join(output_dir, 'heatmap_recovery_source_innovative.png')
plt.savefig(png_output, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved innovative heatmap PNG: {png_output}")

# Save PDF
pdf_output = os.path.join(output_dir, 'heatmap_recovery_source_innovative.pdf')
plt.savefig(pdf_output, bbox_inches='tight')
print(f"✓ Saved innovative heatmap PDF: {pdf_output}")

plt.close()

# Create summary statistics visualization
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Pie chart of recovery sources
sources_count = [cmap_only, tahoe_only, both]
sources_labels = [f'CMAP Only\n({cmap_only})', f'TAHOE Only\n({tahoe_only})', f'Both\n({both})']
colors_pie = ['#F39C12', '#5DADE2', '#9B59B6']

axes[0].pie(sources_count, labels=sources_labels, colors=colors_pie, autopct='%1.1f%%',
            startangle=90, textprops={'fontsize': 11, 'weight': 'bold'})
axes[0].set_title('Distribution of Recovery Sources', fontsize=12, fontweight='bold')

# Bar chart of top drugs by recovery frequency
top_n = 15
top_drugs = sorted_drugs[:top_n]
top_counts = [drug_freq[drug] for drug in top_drugs]

axes[1].barh(range(len(top_drugs)), top_counts, color='#70AD47')
axes[1].set_yticks(range(len(top_drugs)))
axes[1].set_yticklabels(top_drugs, fontsize=10)
axes[1].set_xlabel('Number of Diseases', fontsize=11, fontweight='bold')
axes[1].set_title(f'Top {top_n} Most Frequently Recovered Drugs', fontsize=12, fontweight='bold')
axes[1].invert_yaxis()

for i, v in enumerate(top_counts):
    axes[1].text(v + 0.1, i, str(v), va='center', fontsize=9, fontweight='bold')

plt.tight_layout()

stats_output = os.path.join(output_dir, 'heatmap_recovery_statistics.png')
plt.savefig(stats_output, dpi=300, bbox_inches='tight')
print(f"✓ Saved statistics visualization: {stats_output}")

stats_pdf = os.path.join(output_dir, 'heatmap_recovery_statistics.pdf')
plt.savefig(stats_pdf, bbox_inches='tight')
print(f"✓ Saved statistics PDF: {stats_pdf}")

plt.close()

print("\n" + "=" * 80)
print("Innovative heatmap created successfully!")
print("\nVisualization Features:")
print("  • Color-coded by recovery source")
print("  • White: Not recovered")
print("  • Blue: CMAP Only")
print("  • Orange: TAHOE Only")
print("  • Purple: Both Methods (highest confidence)")
print("\nRows: 20 autoimmune diseases")
print("Columns: All recovered drugs (sorted by frequency)")
print("\nBonus: Included statistics visualization showing:")
print("  • Distribution of recovery sources (pie chart)")
print("  • Top 15 most frequently recovered drugs (bar chart)")
