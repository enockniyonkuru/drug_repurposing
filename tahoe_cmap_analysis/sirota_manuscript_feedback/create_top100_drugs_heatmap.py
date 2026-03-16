#!/usr/bin/env python3
"""
Create a comprehensive heatmap showing top 100 known drugs across 20 autoimmune diseases
with recovery metrics (Known, Available, Recovered)
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os
import glob

# Paths
validation_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1"
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"
table1_path = os.path.join(validation_path, "Table1_Disease_Summary.csv")

print("Creating comprehensive heatmap of top 100 drugs across 20 diseases...")
print("=" * 80)

# Read Table1
df_table1 = pd.read_csv(table1_path)
disease_names = df_table1['Disease'].tolist()

print(f"Analyzing {len(disease_names)} diseases...")

# Collect all drugs and their information
all_drugs_data = {}  # {drug: {disease: {recovered, recovered_source, known, available}}}

# Parse disease-specific drug files
drug_detail_dir = os.path.join(validation_path, "drug_details")
csv_files = glob.glob(os.path.join(drug_detail_dir, "*recovered_drugs.csv"))

print(f"Found {len(csv_files)} disease-specific drug files")

for csv_file in csv_files:
    filename = os.path.basename(csv_file)
    disease_name = filename.replace("_recovered_drugs.csv", "").replace("_", " ")
    
    try:
        df_drugs = pd.read_csv(csv_file)
        
        for idx, row in df_drugs.iterrows():
            drug = str(row['drug']).strip().upper()
            source = str(row['source']).strip()
            
            if drug not in all_drugs_data:
                all_drugs_data[drug] = {}
            
            if disease_name not in all_drugs_data[drug]:
                all_drugs_data[drug][disease_name] = {
                    'recovered': 0,
                    'source': 'NONE'
                }
            
            # Mark as recovered
            all_drugs_data[drug][disease_name]['recovered'] = 1
            all_drugs_data[drug][disease_name]['source'] = source
            
    except Exception as e:
        print(f"  Warning: Could not parse {filename}: {e}")

# Calculate drug frequency across diseases
drug_freq = {}
for drug, diseases in all_drugs_data.items():
    drug_freq[drug] = len(diseases)  # Number of diseases where this drug appears

# Get top 100 drugs by frequency
sorted_drugs = sorted(all_drugs_data.keys(), key=lambda x: drug_freq.get(x, 0), reverse=True)
top_100_drugs = sorted_drugs[:100]

print(f"\nTotal unique drugs found: {len(all_drugs_data)}")
print(f"Top 100 drugs selected")

# Create matrix for heatmap
# Values: 0 = not recovered, 1 = recovered, 2 = both methods, etc.
matrix = []

for disease in disease_names:
    row = []
    for drug in top_100_drugs:
        if drug in all_drugs_data and disease in all_drugs_data[drug]:
            source = all_drugs_data[drug][disease]['source']
            if 'BOTH' in source.upper():
                row.append(3)  # Both methods
            elif 'CMAP' in source.upper() and 'TAHOE' not in source.upper():
                row.append(1)  # CMAP only
            elif 'TAHOE' in source.upper() and 'CMAP' not in source.upper():
                row.append(2)  # TAHOE only
            else:
                row.append(1)  # Default to recovered
        else:
            row.append(0)  # Not recovered/known
    matrix.append(row)

df_matrix = pd.DataFrame(matrix, index=disease_names, columns=top_100_drugs)

print(f"Heatmap dimensions: {df_matrix.shape[0]} diseases × {df_matrix.shape[1]} drugs")

# Create custom colormap with consistent colors
from matplotlib.colors import ListedColormap, BoundaryNorm
# Color scheme: White (none), Orange (CMAP), Blue (TAHOE), Purple (Both)
colors = ['#FFFFFF', '#F39C12', '#5DADE2', '#9B59B6']
cmap = ListedColormap(colors)
norm = BoundaryNorm([0, 1, 2, 3, 4], cmap.N)

# Create the heatmap
fig, ax = plt.subplots(figsize=(20, 12))

im = ax.imshow(df_matrix, aspect='auto', cmap=cmap, norm=norm, interpolation='nearest')

# Set ticks and labels
ax.set_xticks(np.arange(len(top_100_drugs)))
ax.set_yticks(np.arange(len(disease_names)))
ax.set_xticklabels(top_100_drugs, fontsize=7, rotation=90)
ax.set_yticklabels(disease_names, fontsize=10)

# Add gridlines
ax.set_xticks(np.arange(len(top_100_drugs))-.5, minor=True)
ax.set_yticks(np.arange(len(disease_names))-.5, minor=True)
ax.grid(which="minor", color="gray", linestyle='-', linewidth=0.3)

# Title and labels
ax.set_title('Top 100 Known Drugs: Recovery Status across 20 Autoimmune Diseases', 
             fontsize=16, fontweight='bold', pad=20)
ax.set_xlabel('Top 100 Known Drugs (by frequency)', fontsize=12, fontweight='bold')
ax.set_ylabel('Autoimmune Diseases', fontsize=12, fontweight='bold')

# Create custom legend
import matplotlib.patches as mpatches
legend_elements = [
    mpatches.Patch(facecolor='#FFFFFF', edgecolor='black', label='Not Recovered'),
    mpatches.Patch(facecolor='#F39C12', label='CMAP Only'),
    mpatches.Patch(facecolor='#5DADE2', label='TAHOE Only'),
    mpatches.Patch(facecolor='#9B59B6', label='Both Methods')
]
ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.02, 1), fontsize=11)

plt.tight_layout()

# Save PNG
png_output = os.path.join(output_dir, 'heatmap_top100_known_drugs_recovery.png')
plt.savefig(png_output, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved PNG: {png_output}")

# Save PDF
pdf_output = os.path.join(output_dir, 'heatmap_top100_known_drugs_recovery.pdf')
plt.savefig(pdf_output, bbox_inches='tight')
print(f"✓ Saved PDF: {pdf_output}")

plt.close()

# Create summary statistics
print("\n" + "=" * 80)
print("Top 20 Most Frequently Recovered Drugs:")
print("-" * 80)

for i, drug in enumerate(top_100_drugs[:20], 1):
    freq = drug_freq[drug]
    print(f"{i:2d}. {drug:30s} - Appears in {freq:2d} diseases")

print("\n" + "=" * 80)
print("Heatmap created successfully!")
print("\nVisualization Features:")
print("  • 20 autoimmune diseases (rows)")
print("  • Top 100 known drugs (columns, sorted by frequency)")
print("  • Color-coded by recovery source")
print("  • White: Not recovered")
print("  • Orange (#F39C12): CMAP Only")
print("  • Blue (#5DADE2): TAHOE Only")
print("  • Purple (#9B59B6): Both Methods")
