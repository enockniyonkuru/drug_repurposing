#!/usr/bin/env python3
"""
Create two heatmaps showing recovered drugs for 20 autoimmune diseases
One heatmap for TAHOE, one for CMAP
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

print("Creating separate CMAP and TAHOE heatmaps for recovered drugs...")
print("=" * 80)

# Read Table1 to get all disease names
df_table1 = pd.read_csv(table1_path)
disease_names = df_table1['Disease'].tolist()

print(f"Analyzing {len(disease_names)} diseases...")

# Collect all recovered drugs for each disease and method
cmap_heatmap_data = {}
tahoe_heatmap_data = {}

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
        
        cmap_drugs = {}
        tahoe_drugs = {}
        
        for idx, row in df_drugs.iterrows():
            drug = row['drug']
            source = row['source']
            
            if 'CMAP' in source:
                cmap_drugs[drug] = 1  # Mark as recovered in CMAP
            if 'TAHOE' in source:
                tahoe_drugs[drug] = 1  # Mark as recovered in TAHOE
        
        cmap_heatmap_data[disease_name] = cmap_drugs
        tahoe_heatmap_data[disease_name] = tahoe_drugs
        
    except Exception as e:
        print(f"  Warning: Could not parse {filename}: {e}")

print(f"\nProcessed {len(cmap_heatmap_data)} diseases with recovered drugs")

# For diseases without specific files, create empty entries
for disease in disease_names:
    if disease not in cmap_heatmap_data:
        cmap_heatmap_data[disease] = {}
        tahoe_heatmap_data[disease] = {}

# Get all unique drugs across all diseases
all_cmap_drugs = set()
all_tahoe_drugs = set()

for drugs in cmap_heatmap_data.values():
    all_cmap_drugs.update(drugs.keys())
for drugs in tahoe_heatmap_data.values():
    all_tahoe_drugs.update(drugs.keys())

print(f"Total unique drugs found:")
print(f"  CMAP: {len(all_cmap_drugs)} drugs")
print(f"  TAHOE: {len(all_tahoe_drugs)} drugs")

# Create matrices for heatmaps
# Sort drugs by total recovery frequency for better visualization
cmap_drug_freq = {}
tahoe_drug_freq = {}

for drug in all_cmap_drugs:
    cmap_drug_freq[drug] = sum(1 for d in cmap_heatmap_data.values() if drug in d)
for drug in all_tahoe_drugs:
    tahoe_drug_freq[drug] = sum(1 for d in tahoe_heatmap_data.values() if drug in d)

# Sort by frequency
sorted_cmap_drugs = sorted(all_cmap_drugs, key=lambda x: cmap_drug_freq.get(x, 0), reverse=True)
sorted_tahoe_drugs = sorted(all_tahoe_drugs, key=lambda x: tahoe_drug_freq.get(x, 0), reverse=True)

# Build matrices
cmap_matrix = []
tahoe_matrix = []

for disease in disease_names:
    cmap_row = [cmap_heatmap_data[disease].get(drug, 0) for drug in sorted_cmap_drugs]
    tahoe_row = [tahoe_heatmap_data[disease].get(drug, 0) for drug in sorted_tahoe_drugs]
    cmap_matrix.append(cmap_row)
    tahoe_matrix.append(tahoe_row)

# Create DataFrames
df_cmap = pd.DataFrame(cmap_matrix, index=disease_names, columns=sorted_cmap_drugs)
df_tahoe = pd.DataFrame(tahoe_matrix, index=disease_names, columns=sorted_tahoe_drugs)

print(f"\nHeatmap dimensions:")
print(f"  CMAP: {df_cmap.shape[0]} diseases × {df_cmap.shape[1]} drugs")
print(f"  TAHOE: {df_tahoe.shape[0]} diseases × {df_tahoe.shape[1]} drugs")

# Create CMAP heatmap
fig, ax = plt.subplots(figsize=(16, 10))
sns.heatmap(df_cmap, 
            annot=False,
            cmap='YlOrRd',
            cbar_kws={'label': 'Recovered'},
            linewidths=0.2,
            linecolor='white',
            ax=ax,
            xticklabels=True,
            yticklabels=True)

ax.set_title('CMAP: Recovered Drugs across 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs (CMAP)', fontsize=12, fontweight='bold')
ax.set_ylabel('Diseases', fontsize=12, fontweight='bold')

plt.xticks(rotation=90, fontsize=8)
plt.yticks(rotation=0, fontsize=9)
plt.tight_layout()

cmap_output = os.path.join(output_dir, 'heatmap_CMAP_recovered_drugs.png')
plt.savefig(cmap_output, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved CMAP heatmap: {cmap_output}")
plt.close()

# Create TAHOE heatmap
fig, ax = plt.subplots(figsize=(16, 10))
sns.heatmap(df_tahoe, 
            annot=False,
            cmap='YlOrRd',
            cbar_kws={'label': 'Recovered'},
            linewidths=0.2,
            linecolor='white',
            ax=ax,
            xticklabels=True,
            yticklabels=True)

ax.set_title('TAHOE: Recovered Drugs across 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs (TAHOE)', fontsize=12, fontweight='bold')
ax.set_ylabel('Diseases', fontsize=12, fontweight='bold')

plt.xticks(rotation=90, fontsize=8)
plt.yticks(rotation=0, fontsize=9)
plt.tight_layout()

tahoe_output = os.path.join(output_dir, 'heatmap_TAHOE_recovered_drugs.png')
plt.savefig(tahoe_output, dpi=300, bbox_inches='tight')
print(f"✓ Saved TAHOE heatmap: {tahoe_output}")
plt.close()

# Save PDF versions
cmap_pdf = os.path.join(output_dir, 'heatmap_CMAP_recovered_drugs.pdf')
tahoe_pdf = os.path.join(output_dir, 'heatmap_TAHOE_recovered_drugs.pdf')

fig, ax = plt.subplots(figsize=(16, 10))
sns.heatmap(df_cmap, annot=False, cmap='YlOrRd', cbar_kws={'label': 'Recovered'},
            linewidths=0.2, linecolor='white', ax=ax, xticklabels=True, yticklabels=True)
ax.set_title('CMAP: Recovered Drugs across 20 Autoimmune Diseases', fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs (CMAP)', fontsize=12, fontweight='bold')
ax.set_ylabel('Diseases', fontsize=12, fontweight='bold')
plt.xticks(rotation=90, fontsize=8)
plt.yticks(rotation=0, fontsize=9)
plt.tight_layout()
plt.savefig(cmap_pdf, bbox_inches='tight')
print(f"✓ Saved CMAP PDF: {cmap_pdf}")
plt.close()

fig, ax = plt.subplots(figsize=(16, 10))
sns.heatmap(df_tahoe, annot=False, cmap='YlOrRd', cbar_kws={'label': 'Recovered'},
            linewidths=0.2, linecolor='white', ax=ax, xticklabels=True, yticklabels=True)
ax.set_title('TAHOE: Recovered Drugs across 20 Autoimmune Diseases', fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs (TAHOE)', fontsize=12, fontweight='bold')
ax.set_ylabel('Diseases', fontsize=12, fontweight='bold')
plt.xticks(rotation=90, fontsize=8)
plt.yticks(rotation=0, fontsize=9)
plt.tight_layout()
plt.savefig(tahoe_pdf, bbox_inches='tight')
print(f"✓ Saved TAHOE PDF: {tahoe_pdf}")
plt.close()

print("\n" + "=" * 80)
print("Both heatmaps created successfully!")
print("\nHeatmap Structure:")
print("  Rows: 20 autoimmune diseases")
print("  Columns: Recovered drugs (sorted by frequency)")
print("  Color: Yellow/Orange/Red indicates recovered status")
print("\nKey observations:")
print(f"  CMAP recovered drugs: {sorted_cmap_drugs[:5]} (top 5)")
print(f"  TAHOE recovered drugs: {sorted_tahoe_drugs[:5]} (top 5)")
