#!/usr/bin/env python3
"""
Create Heatmap with Disease-Specific Phase 4 Highlighting

IMPORTANT: This version shows Phase 4 status SPECIFIC to each disease-drug pair.
Unlike the previous version which highlighted Phase 4 drugs globally,
this version only highlights red borders for drug-disease combinations
where the drug is actually in Phase 4 for that specific disease.

This is more accurate because a drug may be Phase 4 for one indication
but Phase 3 or lower for another.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle
import seaborn as sns
import numpy as np
import os
from pathlib import Path

# Paths
excel_file = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/20_autoimmune.xlsx"
drug_detail_dir = Path("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/drug_details")
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"

print("Creating heatmap with Disease-Specific Phase 4 Validation...")
print("=" * 80)

# Load Excel data
df_excel = pd.read_excel(excel_file)

# Get disease names and sort
disease_names = df_excel['disease_name'].str.title().tolist()
print(f"Analyzing {len(disease_names)} diseases...")

# Mapping from disease names to CSV file names
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

# Load recovered drugs with disease-specific phase information
drug_sources = {}  # {disease: {drug: source}}
drug_disease_phase = {}  # {(drug, disease): phase} - DISEASE-SPECIFIC phase

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
                # THIS IS KEY: Get the phase specific to this disease-drug pair
                phase = float(row['phase']) if pd.notna(row['phase']) else None
                
                drug_sources[disease_name][drug] = source
                
                # Store disease-specific phase (key is drug-disease pair)
                drug_disease_phase[(drug, disease_name)] = phase
                    
        except Exception as e:
            print(f"  Warning: Could not load {csv_path.name}: {e}")
    else:
        drug_sources[disease_name] = {}

# Get all unique drugs across all diseases
all_drugs = set()
for drugs_dict in drug_sources.values():
    all_drugs.update(drugs_dict.keys())

print(f"\nTotal unique drugs found: {len(all_drugs)} drugs")

# Count sources
cmap_only = sum(1 for disease_drugs in drug_sources.values() 
                for source in disease_drugs.values() if source == 'CMAP_ONLY')
tahoe_only = sum(1 for disease_drugs in drug_sources.values() 
                 for source in disease_drugs.values() if source == 'TAHOE_ONLY')
both = sum(1 for disease_drugs in drug_sources.values() 
           for source in disease_drugs.values() if source == 'BOTH')

print(f"\nRecovery distribution:")
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

# ===== MAIN HEATMAP WITH DISEASE-SPECIFIC PHASE 4 HIGHLIGHTING =====
fig, ax = plt.subplots(figsize=(20, 11))

im = ax.imshow(df_matrix, aspect='auto', cmap=cmap, norm=norm, interpolation='nearest')

# Set ticks and labels
ax.set_xticks(np.arange(len(sorted_drugs)))
ax.set_yticks(np.arange(len(disease_names)))
ax.set_xticklabels(sorted_drugs, fontsize=7.5, rotation=90)
ax.set_yticklabels(disease_names, fontsize=9)

# Add gridlines
ax.set_xticks(np.arange(len(sorted_drugs))-.5, minor=True)
ax.set_yticks(np.arange(len(disease_names))-.5, minor=True)
ax.grid(which="minor", color="gray", linestyle='-', linewidth=0.5, alpha=0.3)

# Count disease-specific phase 4 drugs
disease_specific_phase4_count = 0

# Highlight disease-specific phase 4 drugs with borders
for col_idx, drug in enumerate(sorted_drugs):
    for row_idx, disease in enumerate(disease_names):
        disease_lower = disease.lower()
        # Check if this specific drug-disease pair is in Phase 4
        if (drug, disease_lower) in drug_disease_phase:
            phase = drug_disease_phase[(drug, disease_lower)]
            if phase == 4.0 and df_matrix.iloc[row_idx, col_idx] > 0:
                # Add red border only for disease-specific Phase 4
                rect = Rectangle((col_idx - 0.5, row_idx - 0.5), 1, 1,
                               linewidth=2, edgecolor='red', facecolor='none')
                ax.add_patch(rect)
                disease_specific_phase4_count += 1

print(f"\nDisease-specific Phase 4 drug-disease pairs found: {disease_specific_phase4_count}")

# Title and labels
ax.set_title('Drug Recovery Source and Disease-Specific Phase 4 Clinical Trial Status Across 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs (sorted by frequency)', fontsize=12, fontweight='bold')
ax.set_ylabel('Autoimmune Diseases', fontsize=12, fontweight='bold')

# Create custom legend
legend_elements = [
    mpatches.Patch(facecolor='#FFFFFF', edgecolor='black', label='Not Recovered'),
    mpatches.Patch(facecolor='#F39C12', label='CMAP Only'),
    mpatches.Patch(facecolor='#5DADE2', label='TAHOE Only'),
    mpatches.Patch(facecolor='#9B59B6', label='Both Methods'),
    mpatches.Patch(facecolor='white', edgecolor='red', linewidth=2, label='Phase 4 (Disease-Specific)')
]
ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.01, 1), fontsize=11, framealpha=0.95)

plt.tight_layout()

# Save PNG
png_output = os.path.join(output_dir, 'heatmap_recovery_source_innovative_disease_specific_phase4.png')
plt.savefig(png_output, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved heatmap with disease-specific phase 4 (PNG): {png_output}")

# Save PDF
pdf_output = os.path.join(output_dir, 'heatmap_recovery_source_innovative_disease_specific_phase4.pdf')
plt.savefig(pdf_output, bbox_inches='tight')
print(f"✓ Saved heatmap with disease-specific phase 4 (PDF): {pdf_output}")

plt.close()

# ===== GENERATE COMPARISON REPORT =====
report_path = os.path.join(output_dir, 'disease_specific_phase4_comparison.txt')

with open(report_path, 'w') as f:
    f.write("=" * 100 + "\n")
    f.write("DISEASE-SPECIFIC PHASE 4 CLINICAL TRIAL DRUG VALIDATION REPORT\n")
    f.write("Enhanced Drug Repurposing Analysis - 20 Autoimmune Diseases\n")
    f.write("=" * 100 + "\n\n")
    
    f.write(f"Report Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Analysis Focus: Drugs with disease-specific Phase 4 clinical trial status\n\n")
    
    f.write("KEY DIFFERENCE FROM PREVIOUS ANALYSIS\n")
    f.write("-" * 100 + "\n")
    f.write("Previous analysis: Highlighted drugs that are Phase 4 globally (drug-level status)\n")
    f.write("This analysis: Highlights drugs in Phase 4 for SPECIFIC disease indications (drug-disease-specific status)\n")
    f.write("This is more accurate because a drug may be Phase 4 for one disease but Phase 1-3 for another\n\n")
    
    f.write("SUMMARY STATISTICS\n")
    f.write("-" * 100 + "\n")
    f.write(f"Total unique drugs analyzed:              {len(all_drugs)}\n")
    f.write(f"Total drug-disease pairs:                 {sum(len(d) for d in drug_sources.values())}\n")
    f.write(f"Drug-disease pairs in Phase 4:            {disease_specific_phase4_count}\n")
    f.write(f"Percentage of pairs in Phase 4:           {100*disease_specific_phase4_count/(sum(len(d) for d in drug_sources.values())):.1f}%\n\n")
    
    # Create a matrix showing disease-specific phase 4 drugs per disease
    f.write("DISEASE-SPECIFIC PHASE 4 DRUGS BY DISEASE\n")
    f.write("-" * 100 + "\n")
    
    for disease in sorted(disease_names):
        disease_lower = disease.lower()
        phase4_drugs_in_disease = []
        
        if disease_lower in drug_sources:
            for drug in drug_sources[disease_lower]:
                if (drug, disease_lower) in drug_disease_phase:
                    phase = drug_disease_phase[(drug, disease_lower)]
                    if phase == 4.0:
                        source = drug_sources[disease_lower][drug]
                        phase4_drugs_in_disease.append((drug, source, phase))
        
        if phase4_drugs_in_disease:
            f.write(f"\n{disease.upper()}\n")
            f.write(f"  Found {len(phase4_drugs_in_disease)} disease-specific Phase 4 drugs:\n")
            for drug, source, phase in sorted(phase4_drugs_in_disease):
                f.write(f"    • {drug:<30} [{source:<12}] Phase {int(phase)}\n")
        else:
            f.write(f"\n{disease.upper()}\n")
            f.write(f"  No disease-specific Phase 4 drugs recovered\n")
    
    f.write("\n" + "=" * 100 + "\n")
    f.write("INTERPRETATION NOTES\n")
    f.write("=" * 100 + "\n")
    f.write("""
This analysis is MORE CONSERVATIVE AND ACCURATE than the previous analysis because:

1. INDICATION-SPECIFIC: Phase 4 status shown here is for that specific disease indication,
   not just because the drug is Phase 4 for some other indication

2. CLINICAL RELEVANCE: A drug in Phase 4 for Disease A might only be in Phase 2 for Disease B,
   This analysis correctly distinguishes between them

3. TRANSLATIONAL VALUE: Disease-specific Phase 4 drugs are immediately ready for that
   specific indication, while globally-Phase4 drugs may need adaptation for new indications

EXAMPLE:
- Methotrexate is Phase 4 for Rheumatoid Arthritis (decades of use)
- But it might be Phase 3 or clinical research phase for Sjögren's syndrome
- This analysis shows Phase 4 ONLY where it's been proven for that disease

EXPECTED PATTERN:
- Expect FEWER red borders than the previous version
- Only highly validated disease-specific combinations show red borders
- This is more scientifically defensible for manuscript publication
""")

print(f"✓ Saved disease-specific phase 4 comparison report: {report_path}")

# Create summary statistics
print("\n" + "=" * 80)
print("DISEASE-SPECIFIC PHASE 4 ANALYSIS COMPLETE!")
print("=" * 80)
print(f"\nKey Findings:")
print(f"  • Total drug-disease pairs: {sum(len(d) for d in drug_sources.values())}")
print(f"  • Disease-specific Phase 4 pairs: {disease_specific_phase4_count}")
print(f"  • Percentage: {100*disease_specific_phase4_count/(sum(len(d) for d in drug_sources.values())):.1f}%")
print(f"  • Expected: FEWER red borders than previous version (more conservative)")

print("\n" + "=" * 80)
