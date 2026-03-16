#!/usr/bin/env python3
"""
Create a heatmap showing known drugs and recovered drugs for 20 autoimmune diseases
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# Read the data
table1_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/Table1_Disease_Summary.csv"
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"

print("Creating heatmap visualization...")
print("=" * 80)

# Read the table
df_table1 = pd.read_csv(table1_path)

# Prepare data for heatmap - show recovery metrics
# Create a matrix with diseases as rows and metrics as columns
heatmap_data = []
disease_names = []

for idx, row in df_table1.iterrows():
    disease_names.append(row['Disease'])
    heatmap_data.append({
        'Known Drugs': int(row['Known Drugs (DB)']),
        'Available CMAP': int(row['Available (CMAP)']),
        'Available TAHOE': int(row['Available (TAHOE)']),
        'Recovered CMAP': int(row['Recovered (CMAP)']),
        'Recovered TAHOE': int(row['Recovered (TAHOE)']),
        'Total Recovered': int(row['Total Recovered'])
    })

df_heatmap = pd.DataFrame(heatmap_data, index=disease_names)

print(f"Created heatmap data for {len(df_heatmap)} diseases")
print(f"Metrics: {list(df_heatmap.columns)}")

# Create the heatmap
fig, ax = plt.subplots(figsize=(12, 14))

# Create heatmap with normalized values (log scale for better visualization)
sns.heatmap(df_heatmap, 
            annot=True,           # Show values in cells
            fmt='d',              # Integer format
            cmap='YlOrRd',        # Yellow-Orange-Red colormap
            cbar_kws={'label': 'Count'},
            linewidths=0.5,
            linecolor='gray',
            ax=ax,
            vmin=0)

ax.set_title('Known Drugs and Recovery Metrics across 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Metrics', fontsize=12, fontweight='bold')
ax.set_ylabel('Disease', fontsize=12, fontweight='bold')

# Rotate x labels for better readability
plt.xticks(rotation=45, ha='right')
plt.yticks(rotation=0, fontsize=9)

plt.tight_layout()

# Save the figure
output_file = os.path.join(output_dir, 'heatmap_known_drugs_recovery.png')
plt.savefig(output_file, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved heatmap: {output_file}")

# Also save as PDF
pdf_file = os.path.join(output_dir, 'heatmap_known_drugs_recovery.pdf')
plt.savefig(pdf_file, bbox_inches='tight')
print(f"✓ Saved PDF: {pdf_file}")

plt.show()

print("\n" + "=" * 80)
print("Heatmap created successfully!")
print("\nHeatmap shows:")
print("  - Each row: One of 20 autoimmune diseases")
print("  - Each column: Different drug recovery metrics")
print("  - Color intensity: Represents the count (darker = more drugs)")
print("\nMetrics explained:")
print("  - Known Drugs: Total known drugs in DrugBank for each disease")
print("  - Available CMAP: Known drugs found in CMAP database")
print("  - Available TAHOE: Known drugs found in TAHOE database")
print("  - Recovered CMAP: Successfully recovered via CMAP predictions")
print("  - Recovered TAHOE: Successfully recovered via TAHOE predictions")
print("  - Total Recovered: Combined successful recoveries")
