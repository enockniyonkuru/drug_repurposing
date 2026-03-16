#!/usr/bin/env python3
"""
Create Recovery Source Innovative Heatmap - CORRECTED VERSION

Uses Excel source data (20_autoimmune.xlsx) to match figure2_heatmap.png exactly,
while maintaining the innovative heatmap format showing drug recovery sources.

Format:
- Rows: All 20 autoimmune diseases
- Columns: Individual recovered drugs (sorted by frequency)
- Colors: CMAP Only (Orange), TAHOE Only (Blue), Both (Purple), None (White)
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import numpy as np
import os
from pathlib import Path

# Paths
excel_file = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/20_autoimmune.xlsx"
drug_detail_dir = Path("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/drug_details")
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"

print("Creating innovative recovery source heatmap...")
print("=" * 80)

# Load Excel data
df_excel = pd.read_excel(excel_file)

# Get disease names and sort
disease_names = df_excel['disease_name'].str.title().tolist()
print(f"Analyzing {len(disease_names)} diseases...")

# Collect drug sources from CSV files
drug_sources = {}  # {disease: {drug: source}}
disease_csv_map = {
    'multiple sclerosis': 'multiple_sclerosis',
    'systemic lupus erythematosus': 'systemic_lupus_erythematosus',
    'rheumatoid arthritis': 'rheumatoid_arthritis',
    'type 1 diabetes mellitus': 'type_1_diabetes_mellitus',
    'relapsing-remitting multiple sclerosis': 'relapsing_remitting_multiple_sclerosis',  # Note: underscores in file
    "sjogren's syndrome": "Sjogren's_syndrome",
    'ulcerative colitis': 'ulcerative_colitis',
    'autoimmune thrombocytopenic purpura': 'autoimmune_thrombocytopenic_purpura',
    "crohn's disease": "Crohn's_disease",
    'scleroderma': 'scleroderma',
    'arthritis': 'arthritis',
    'inflammatory bowel disease': 'inflammatory_bowel_disease',
    'psoriasis': 'psoriasis',
    'psoriasis vulgaris': 'Psoriasis_vulgaris',
    'childhood type dermatomyositis': 'childhood_type_dermatomyositis',
    'discoid lupus erythematosus': 'discoid_lupus_erythematosus',
    'inclusion body myositis': 'inclusion_body_myositis',
    'colitis': 'colitis',
    'psoriatic arthritis': 'psoriatic_arthritis',
    'ankylosing spondylitis': 'ankylosing_spondylitis',
}

# Load recovered drugs from CSV files
for excel_row in df_excel.iterrows():
    disease_name = excel_row[1]['disease_name'].lower()
    
    # Find corresponding CSV file
    csv_name = disease_csv_map.get(disease_name, disease_name.replace(' ', '_'))
    csv_path = drug_detail_dir / f"{csv_name}_recovered_drugs.csv"
    
    if csv_path.exists():
        try:
            df_drugs = pd.read_csv(csv_path)
            drug_sources[disease_name] = {}
            
            for _, row in df_drugs.iterrows():
                drug = row['drug'].upper()
                source = str(row['source']).strip().upper()
                drug_sources[disease_name][drug] = source
        except Exception as e:
            print(f"  Warning: Could not load {csv_path.name}: {e}")
    else:
        drug_sources[disease_name] = {}

# Get all unique drugs across all diseases
all_drugs = set()
for drugs_dict in drug_sources.values():
    all_drugs.update(drugs_dict.keys())

print(f"Total unique drugs found: {len(all_drugs)} drugs")

# Count sources
cmap_only = 0
tahoe_only = 0
both = 0
for disease_drugs in drug_sources.values():
    for source in disease_drugs.values():
        if source == 'CMAP_ONLY':
            cmap_only += 1
        elif source == 'TAHOE_ONLY':
            tahoe_only += 1
        elif source == 'BOTH':
            both += 1

print(f"\nRecovery distribution from CSV files:")
print(f"  CMAP Only: {cmap_only} instances")
print(f"  TAHOE Only: {tahoe_only} instances")
print(f"  Both: {both} instances")

# Sort drugs by recovery frequency
drug_freq = {}
for drug in all_drugs:
    count = 0
    for disease_drugs in drug_sources.values():
        if drug in disease_drugs:
            count += 1
    drug_freq[drug] = count

sorted_drugs = sorted(all_drugs, key=lambda x: drug_freq.get(x, 0), reverse=True)

# Create numerical encoding for visualization
# 0 = not recovered, 1 = CMAP only, 2 = TAHOE only, 3 = Both
encoding = {
    'CMAP_ONLY': 1,
    'TAHOE_ONLY': 2,
    'BOTH': 3,
}

matrix = []
for disease in disease_names:
    disease_lower = disease.lower()
    row = []
    for drug in sorted_drugs:
        if disease_lower in drug_sources and drug in drug_sources[disease_lower]:
            source = drug_sources[disease_lower][drug]
            row.append(encoding.get(source, 0))
        else:
            row.append(0)
    matrix.append(row)

df_matrix = pd.DataFrame(matrix, index=disease_names, columns=sorted_drugs)

print(f"\nHeatmap dimensions: {df_matrix.shape[0]} diseases × {df_matrix.shape[1]} drugs")

# Create custom colormap
from matplotlib.colors import ListedColormap, BoundaryNorm
colors = ['#FFFFFF', '#F39C12', '#5DADE2', '#9B59B6']  # White, Orange (CMAP), Blue (TAHOE), Purple (Both)
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

# Calculate totals from CSV data
cmap_only_total = sum(1 for d in drug_sources.values() for s in d.values() if s == 'CMAP_ONLY')
tahoe_only_total = sum(1 for d in drug_sources.values() for s in d.values() if s == 'TAHOE_ONLY')
both_total = sum(1 for d in drug_sources.values() for s in d.values() if s == 'BOTH')

# Pie chart of recovery sources
sources_count = [cmap_only_total, tahoe_only_total, both_total]
sources_labels = [f'CMAP Only\n({cmap_only_total})', f'TAHOE Only\n({tahoe_only_total})', f'Both\n({both_total})']
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
print("  • Orange: CMAP Only")
print("  • Blue: TAHOE Only")
print("  • Purple: Both Methods (highest confidence)")
print("\nRows: 20 autoimmune diseases")
print("Columns: All recovered drugs (sorted by frequency)")
print(f"\nData summary:")
print(f"  Total unique drugs: {len(all_drugs)}")
print(f"  CMAP Only instances: {cmap_only_total}")
print(f"  TAHOE Only instances: {tahoe_only_total}")
print(f"  Both instances: {both_total}")
print("\nBonus: Included statistics visualization showing:")
print("  • Distribution of recovery sources (pie chart)")
print("  • Top 15 most frequently recovered drugs (bar chart)")
print("=" * 80)
