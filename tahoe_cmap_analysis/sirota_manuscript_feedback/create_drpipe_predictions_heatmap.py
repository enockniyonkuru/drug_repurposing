#!/usr/bin/env python3
"""
Create a heatmap showing TOP 100 DRpipe PREDICTED DRUGS (not just recovered)
across 20 autoimmune diseases
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os
import glob

output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"

print("Creating heatmap of top 100 DRpipe predicted drugs across 20 diseases...")
print("=" * 80)

# Paths to result directories
results_base = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/results/creed_manual_standardised_results_OG_exp_8"

# Map of disease names to look for
autoimmune_diseases = {
    'ankylosing spondylitis': 'ankylosing_spondylitis',
    'autoimmune thrombocytopenic purpura': 'autoimmune_thrombocytopenic_purpura',
    "Crohn's disease": "Crohn's_disease",
    'discoid lupus erythematosus': 'discoid_lupus_erythematosus',
    'inflammatory bowel disease': 'inflammatory_bowel_disease',
    'lupus erythematosus': 'lupus_erythematosus',
    'multiple sclerosis': 'multiple_sclerosis',
    'psoriatic arthritis': 'psoriatic_arthritis',
    'rheumatoid arthritis': 'rheumatoid_arthritis',
    'scleroderma': 'scleroderma',
    "Sjogren's syndrome": "Sjogren's_syndrome",
    'systemic lupus erythematosus': 'systemic_lupus_erythematosus',
    'ulcerative colitis': 'ulcerative_colitis',
    'dermatomyositis': 'dermatomyositis',
    'atopic dermatitis': 'atopic_dermatitis',
    'allergic contact dermatitis': 'allergic_contact_dermatitis',
    'type 1 diabetes mellitus': 'type_1_diabetes_mellitus',
    'polymyositis': 'polymyositis',
    'relapsing-remitting multiple sclerosis': 'relapsing-remitting_multiple_sclerosis',
    'pulmonary sarcoidosis': 'pulmonary_sarcoidosis'
}

# Collect all predicted drugs
all_predictions = {}  # {disease: {drug: {source, count}}}

print(f"\nSearching for DRpipe results for {len(autoimmune_diseases)} diseases...")

for disease_name, search_pattern in autoimmune_diseases.items():
    # Find directories matching this disease
    pattern = os.path.join(results_base, f"{search_pattern}*")
    matching_dirs = glob.glob(pattern)
    
    if not matching_dirs:
        # Try alternative patterns
        pattern2 = os.path.join(results_base, f"*{search_pattern.replace('_', ' ')}*")
        matching_dirs = glob.glob(pattern2)
    
    all_predictions[disease_name] = {}
    
    for result_dir in matching_dirs:
        # Determine if CMAP or TAHOE
        method = 'CMAP' if 'CMAP' in result_dir else 'TAHOE' if 'TAHOE' in result_dir else 'UNKNOWN'
        
        # Find the hits CSV file
        hits_files = glob.glob(os.path.join(result_dir, "*hits*q*.csv"))
        
        if hits_files:
            try:
                df = pd.read_csv(hits_files[0])
                
                if not df.empty and 'name' in df.columns:
                    # Get unique drug names
                    drugs = df['name'].dropna().unique()
                    
                    for drug in drugs:
                        drug_upper = str(drug).strip().upper()
                        if drug_upper not in all_predictions[disease_name]:
                            all_predictions[disease_name][drug_upper] = {'sources': set(), 'count': 0}
                        all_predictions[disease_name][drug_upper]['sources'].add(method)
                        all_predictions[disease_name][drug_upper]['count'] += 1
                        
            except Exception as e:
                pass  # Skip errors

# Count total predictions per disease
print(f"\nDRpipe Predictions Summary:")
print("-" * 80)

for disease, drugs in all_predictions.items():
    if drugs:
        print(f"{disease:45s}: {len(drugs):3d} predicted drugs")

# Get all unique drugs across all diseases
all_drugs = set()
for drugs in all_predictions.values():
    all_drugs.update(drugs.keys())

print(f"\nTotal unique predicted drugs: {len(all_drugs)}")

# Calculate drug frequency across diseases
drug_freq = {}
for drug in all_drugs:
    count = 0
    for diseases in all_predictions.values():
        if drug in diseases:
            count += 1
    drug_freq[drug] = count

# Get top 100 drugs by frequency
sorted_drugs = sorted(all_drugs, key=lambda x: drug_freq.get(x, 0), reverse=True)
top_100_drugs = sorted_drugs[:100]

print(f"Using top 100 most frequent predicted drugs")

# Get disease names in order
disease_list = list(autoimmune_diseases.keys())

# Create matrix: 1 = predicted, 0 = not predicted
matrix = []
for disease in disease_list:
    row = []
    for drug in top_100_drugs:
        if drug in all_predictions.get(disease, {}):
            row.append(1)
        else:
            row.append(0)
    matrix.append(row)

df_matrix = pd.DataFrame(matrix, index=disease_list, columns=top_100_drugs)

print(f"\nHeatmap dimensions: {df_matrix.shape[0]} diseases × {df_matrix.shape[1]} drugs")

# Create heatmap
fig, ax = plt.subplots(figsize=(22, 12))

# Use a simple binary colormap
sns.heatmap(df_matrix, 
            annot=False,
            cmap='RdYlBu_r',  # Red (1) to Blue (0)
            cbar_kws={'label': 'Predicted'},
            linewidths=0.2,
            linecolor='white',
            ax=ax,
            xticklabels=True,
            yticklabels=True)

ax.set_title('Top 100 DRpipe Predicted Drugs across 20 Autoimmune Diseases', 
             fontsize=16, fontweight='bold', pad=20)
ax.set_xlabel('Top 100 Predicted Drugs (by frequency)', fontsize=12, fontweight='bold')
ax.set_ylabel('Autoimmune Diseases', fontsize=12, fontweight='bold')

plt.xticks(rotation=90, fontsize=7)
plt.yticks(rotation=0, fontsize=10)

plt.tight_layout()

# Save PNG
png_output = os.path.join(output_dir, 'heatmap_top100_DRpipe_predictions.png')
plt.savefig(png_output, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved PNG: {png_output}")

# Save PDF
pdf_output = os.path.join(output_dir, 'heatmap_top100_DRpipe_predictions.pdf')
plt.savefig(pdf_output, bbox_inches='tight')
print(f"✓ Saved PDF: {pdf_output}")

plt.close()

# Print top drugs
print("\n" + "=" * 80)
print("Top 20 Most Frequently Predicted Drugs:")
print("-" * 80)

for i, drug in enumerate(top_100_drugs[:20], 1):
    freq = drug_freq[drug]
    print(f"{i:2d}. {drug:30s} - Predicted in {freq:2d} diseases")

print("\n" + "=" * 80)
print("Heatmap created successfully!")
print("\nVisualization Features:")
print("  • Shows ALL DRpipe predictions (not just recovered)")
print("  • Top 100 most frequent predicted drugs")
print("  • Red/Yellow = Predicted for that disease")
print("  • Blue = Not predicted for that disease")
