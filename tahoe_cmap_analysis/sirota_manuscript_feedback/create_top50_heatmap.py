#!/usr/bin/env python3
"""
Create Recovery Source Innovative Heatmap - Top 50 Drugs

Shows top 50 most frequently recovered drugs across all 20 autoimmune diseases.
Uses the innovative color-coded format:
- Orange: CMAP Only
- Blue: TAHOE Only
- Purple: Both Methods
- White: Not recovered
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import numpy as np
import os
from pathlib import Path

# Paths
drug_detail_dir = Path("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/drug_details")
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"

print("Creating innovative recovery source heatmap - Top 50 Drugs...")
print("=" * 80)

# Load Excel to get disease order
excel_file = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/20_autoimmune.xlsx"
df_excel = pd.read_excel(excel_file)
disease_names = df_excel['disease_name'].str.title().tolist()

# Disease name to CSV mapping
disease_csv_map = {
    'multiple sclerosis': 'multiple_sclerosis',
    'systemic lupus erythematosus': 'systemic_lupus_erythematosus',
    'rheumatoid arthritis': 'rheumatoid_arthritis',
    'type 1 diabetes mellitus': 'type_1_diabetes_mellitus',
    'relapsing-remitting multiple sclerosis': 'relapsing_remitting_multiple_sclerosis',
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

# Collect drug sources from CSV files
drug_sources = {}  # {disease: {drug: source}}
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

print(f"Analyzing {len(disease_names)} diseases...")

# Get all unique drugs and their frequency
all_drugs = set()
for drugs_dict in drug_sources.values():
    all_drugs.update(drugs_dict.keys())

drug_freq = {}
for drug in all_drugs:
    count = 0
    for disease_drugs in drug_sources.values():
        if drug in disease_drugs:
            count += 1
    drug_freq[drug] = count

# Get top 50 drugs
sorted_drugs = sorted(all_drugs, key=lambda x: drug_freq.get(x, 0), reverse=True)
top_50_drugs = sorted_drugs[:50]

print(f"Total unique drugs found: {len(all_drugs)}")
print(f"Using top 50 most frequent drugs for heatmap")

# Count sources for top 50
cmap_only = sum(1 for d in drug_sources.values() for s in d.values() if s == 'CMAP_ONLY')
tahoe_only = sum(1 for d in drug_sources.values() for s in d.values() if s == 'TAHOE_ONLY')
both = sum(1 for d in drug_sources.values() for s in d.values() if s == 'BOTH')

print(f"\nTotal recovery instances (all drugs):")
print(f"  CMAP Only: {cmap_only}")
print(f"  TAHOE Only: {tahoe_only}")
print(f"  Both: {both}")

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
    for drug in top_50_drugs:
        if disease_lower in drug_sources and drug in drug_sources[disease_lower]:
            source = drug_sources[disease_lower][drug]
            row.append(encoding.get(source, 0))
        else:
            row.append(0)
    matrix.append(row)

df_matrix = pd.DataFrame(matrix, index=disease_names, columns=top_50_drugs)

print(f"Heatmap dimensions: {df_matrix.shape[0]} diseases × {df_matrix.shape[1]} top drugs")

# Create custom colormap
from matplotlib.colors import ListedColormap, BoundaryNorm
colors = ['#FFFFFF', '#F39C12', '#5DADE2', '#9B59B6']  # White, Orange (CMAP), Blue (TAHOE), Purple (Both)
n_bins = 4
cmap = ListedColormap(colors)
norm = BoundaryNorm([0, 1, 2, 3, 4], cmap.N)

# Create the heatmap
fig, ax = plt.subplots(figsize=(20, 10))

im = ax.imshow(df_matrix, aspect='auto', cmap=cmap, norm=norm, interpolation='nearest')

# Set ticks and labels
ax.set_xticks(np.arange(len(top_50_drugs)))
ax.set_yticks(np.arange(len(disease_names)))
ax.set_xticklabels(top_50_drugs, fontsize=9, rotation=90)
ax.set_yticklabels(disease_names, fontsize=10)

# Add gridlines
ax.set_xticks(np.arange(len(top_50_drugs))-.5, minor=True)
ax.set_yticks(np.arange(len(disease_names))-.5, minor=True)
ax.grid(which="minor", color="gray", linestyle='-', linewidth=0.5)

# Title and labels
ax.set_title('Top 50 Recovered Drugs: CMAP vs TAHOE vs Both\nAcross 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Top 50 Most Frequently Recovered Drugs', fontsize=12, fontweight='bold')
ax.set_ylabel('Diseases', fontsize=12, fontweight='bold')

# Create custom legend
legend_elements = [
    mpatches.Patch(facecolor='#FFFFFF', edgecolor='black', label='Not Recovered'),
    mpatches.Patch(facecolor='#F39C12', label='CMAP Only'),
    mpatches.Patch(facecolor='#5DADE2', label='TAHOE Only'),
    mpatches.Patch(facecolor='#9B59B6', label='Both Methods')
]
ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.12, 1), fontsize=11)

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
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# Left panel: Pie chart of recovery sources for top 50
top_50_cmap_only = sum(1 for disease_drugs in drug_sources.values() 
                        for drug, source in disease_drugs.items() 
                        if drug in top_50_drugs and source == 'CMAP_ONLY')
top_50_tahoe_only = sum(1 for disease_drugs in drug_sources.values() 
                         for drug, source in disease_drugs.items() 
                         if drug in top_50_drugs and source == 'TAHOE_ONLY')
top_50_both = sum(1 for disease_drugs in drug_sources.values() 
                   for drug, source in disease_drugs.items() 
                   if drug in top_50_drugs and source == 'BOTH')

sources_count = [top_50_cmap_only, top_50_tahoe_only, top_50_both]
sources_labels = [f'CMAP Only\n({top_50_cmap_only})', f'TAHOE Only\n({top_50_tahoe_only})', f'Both\n({top_50_both})']
colors_pie = ['#F39C12', '#5DADE2', '#9B59B6']

axes[0].pie(sources_count, labels=sources_labels, colors=colors_pie, autopct='%1.1f%%',
            startangle=90, textprops={'fontsize': 11, 'weight': 'bold'})
axes[0].set_title('Distribution of Recovery Sources\n(Top 50 Drugs)', fontsize=12, fontweight='bold')

# Right panel: Bar chart of top 50 drugs by recovery frequency
top_50_freqs = [drug_freq[drug] for drug in top_50_drugs]

axes[1].barh(range(len(top_50_drugs)), top_50_freqs, color='#70AD47', alpha=0.8, edgecolor='black')
axes[1].set_yticks(range(len(top_50_drugs)))
axes[1].set_yticklabels(top_50_drugs, fontsize=8)
axes[1].set_xlabel('Number of Diseases', fontsize=11, fontweight='bold')
axes[1].set_title('Top 50 Drugs by Recovery Frequency', fontsize=12, fontweight='bold')
axes[1].invert_yaxis()
axes[1].set_xlim(0, max(top_50_freqs) + 1)

# Add value labels for top drugs
for i, v in enumerate(top_50_freqs):
    if i < 15:  # Only label top 15 to avoid clutter
        axes[1].text(v + 0.05, i, str(int(v)), va='center', fontsize=8, fontweight='bold')

plt.tight_layout()

# Save stats
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
print("Columns: Top 50 most frequently recovered drugs")
print(f"\nTop 50 Drugs Statistics:")
print(f"  CMAP Only instances: {top_50_cmap_only}")
print(f"  TAHOE Only instances: {top_50_tahoe_only}")
print(f"  Both instances: {top_50_both}")
print(f"  Total instances in top 50: {top_50_cmap_only + top_50_tahoe_only + top_50_both}")
print("\nBonus: Included statistics visualization showing:")
print("  • Distribution of recovery sources for top 50 drugs (pie chart)")
print("  • Frequency of each top 50 drug across diseases (bar chart)")
print("=" * 80)
