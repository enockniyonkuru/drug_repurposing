#!/usr/bin/env python3
"""
Create Recovery Source Heatmap with Phase 4 Clinical Trial Highlighting

Enhanced version of the innovative recovery source heatmap that:
1. Highlights which drugs were validated in phase 4 of clinical trials
2. Uses border/marker to distinguish phase 4 drugs
3. Generates a validation report with phase 4 drug details

Format:
- Rows: All 20 autoimmune diseases
- Columns: Individual recovered drugs (sorted by frequency)
- Colors: CMAP Only (Orange), TAHOE Only (Blue), Both (Purple), None (White)
- Phase 4 Highlighting: Bold border/marker around phase 4 drugs
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

print("Creating heatmap with Phase 4 Clinical Trial Validation...")
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

# Load recovered drugs from CSV files and extract phase information
drug_sources = {}  # {disease: {drug: source}}
drug_phases = {}   # {drug: phase} - store phase for each drug globally
phase4_drugs = set()  # Track all phase 4 drugs

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
                phase = float(row['phase']) if pd.notna(row['phase']) else None
                
                drug_sources[disease_name][drug] = source
                
                # Store phase information globally (keep the maximum phase if multiple)
                if drug not in drug_phases and phase is not None:
                    drug_phases[drug] = phase
                elif drug in drug_phases and phase is not None and phase > drug_phases[drug]:
                    drug_phases[drug] = phase
                
                # Mark as phase 4 if applicable
                if phase == 4.0:
                    phase4_drugs.add(drug)
                    
        except Exception as e:
            print(f"  Warning: Could not load {csv_path.name}: {e}")
    else:
        drug_sources[disease_name] = {}

print(f"\nPhase 4 Clinical Trial Drugs Found: {len(phase4_drugs)} drugs")
print(f"Total unique drugs found: {len(drug_phases)} drugs")

# Get all unique drugs across all diseases
all_drugs = set()
for drugs_dict in drug_sources.values():
    all_drugs.update(drugs_dict.keys())

print(f"All unique drugs in heatmap: {len(all_drugs)} drugs")

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

# ===== MAIN HEATMAP WITH PHASE 4 HIGHLIGHTING =====
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

# Highlight phase 4 drugs with borders (only on cells, not header)
for col_idx, drug in enumerate(sorted_drugs):
    if drug in phase4_drugs:
        # Add a thicker border to all cells in this column
        for row_idx in range(len(disease_names)):
            if df_matrix.iloc[row_idx, col_idx] > 0:  # Only if drug was recovered
                rect = Rectangle((col_idx - 0.5, row_idx - 0.5), 1, 1,
                               linewidth=2, edgecolor='red', facecolor='none')
                ax.add_patch(rect)

# Title and labels
ax.set_title('Drug Recovery Source and Phase 4 Clinical Trial Status Across 20 Autoimmune Diseases', 
             fontsize=14, fontweight='bold', pad=20)
ax.set_xlabel('Recovered Drugs (sorted by frequency)', fontsize=12, fontweight='bold')
ax.set_ylabel('Autoimmune Diseases', fontsize=12, fontweight='bold')

# Create custom legend
legend_elements = [
    mpatches.Patch(facecolor='#FFFFFF', edgecolor='black', label='Not Recovered'),
    mpatches.Patch(facecolor='#F39C12', label='CMAP Only'),
    mpatches.Patch(facecolor='#5DADE2', label='TAHOE Only'),
    mpatches.Patch(facecolor='#9B59B6', label='Both Methods'),
    mpatches.Patch(facecolor='white', edgecolor='red', linewidth=2, label='Phase 4 Clinical Trial')
]
ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.01, 1), fontsize=11, framealpha=0.95)

plt.tight_layout()

# Save PNG
png_output = os.path.join(output_dir, 'heatmap_recovery_source_innovative_with_phase4.png')
plt.savefig(png_output, dpi=300, bbox_inches='tight')
print(f"\n✓ Saved heatmap with phase 4 highlighting (PNG): {png_output}")

# Save PDF
pdf_output = os.path.join(output_dir, 'heatmap_recovery_source_innovative_with_phase4.pdf')
plt.savefig(pdf_output, bbox_inches='tight')
print(f"✓ Saved heatmap with phase 4 highlighting (PDF): {pdf_output}")

plt.close()

# ===== PHASE 4 VALIDATION REPORT =====
report_path = os.path.join(output_dir, 'phase4_drug_validation_report.txt')

with open(report_path, 'w') as f:
    f.write("=" * 100 + "\n")
    f.write("PHASE 4 CLINICAL TRIAL DRUG VALIDATION REPORT\n")
    f.write("Enhanced Drug Repurposing Analysis - 20 Autoimmune Diseases\n")
    f.write("=" * 100 + "\n\n")
    
    f.write(f"Report Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Analysis Focus: Drugs recovered in Phase 4 of clinical trials\n\n")
    
    f.write("SUMMARY STATISTICS\n")
    f.write("-" * 100 + "\n")
    f.write(f"Total unique drugs analyzed:        {len(all_drugs)}\n")
    f.write(f"Total drugs with phase data:        {len(drug_phases)}\n")
    f.write(f"Drugs in Phase 4 of trials:         {len(phase4_drugs)}\n")
    f.write(f"Percentage in Phase 4:              {100*len(phase4_drugs)/len(drug_phases):.1f}%\n")
    f.write(f"\n")
    
    # Count phase 4 drugs by recovery method
    phase4_cmap_only = 0
    phase4_tahoe_only = 0
    phase4_both = 0
    phase4_occurrences = {}  # Track all occurrences with their sources
    
    for disease, drugs_dict in drug_sources.items():
        for drug, source in drugs_dict.items():
            if drug in phase4_drugs:
                if drug not in phase4_occurrences:
                    phase4_occurrences[drug] = {'sources': set(), 'diseases': []}
                phase4_occurrences[drug]['sources'].add(source)
                phase4_occurrences[drug]['diseases'].append(disease)
                
                if source == 'CMAP_ONLY':
                    phase4_cmap_only += 1
                elif source == 'TAHOE_ONLY':
                    phase4_tahoe_only += 1
                elif source == 'BOTH':
                    phase4_both += 1
    
    f.write("PHASE 4 DRUGS BY RECOVERY METHOD\n")
    f.write("-" * 100 + "\n")
    f.write(f"Phase 4 drugs found by CMAP only:     {phase4_cmap_only} instances\n")
    f.write(f"Phase 4 drugs found by TAHOE only:    {phase4_tahoe_only} instances\n")
    f.write(f"Phase 4 drugs found by both methods:  {phase4_both} instances\n")
    f.write(f"Total Phase 4 recoveries:             {phase4_cmap_only + phase4_tahoe_only + phase4_both} instances\n\n")
    
    # List all phase 4 drugs with details
    f.write("DETAILED PHASE 4 DRUG LIST (sorted by frequency across diseases)\n")
    f.write("-" * 100 + "\n")
    f.write(f"{'Rank':<5} {'Drug':<25} {'Phase':<8} {'Freq':<6} {'Methods':<30} {'# Diseases':<12}\n")
    f.write("-" * 100 + "\n")
    
    sorted_phase4 = sorted(phase4_occurrences.items(), 
                           key=lambda x: len(x[1]['diseases']), reverse=True)
    
    for rank, (drug, info) in enumerate(sorted_phase4, 1):
        sources = ', '.join(sorted(info['sources']))
        phase = drug_phases.get(drug, 'N/A')
        freq = drug_freq.get(drug, 0)
        num_diseases = len(set(info['diseases']))
        
        f.write(f"{rank:<5} {drug:<25} {str(phase):<8} {freq:<6} {sources:<30} {num_diseases:<12}\n")
    
    f.write("\n")
    f.write("PHASE 4 DRUGS BY DISEASE\n")
    f.write("-" * 100 + "\n")
    
    for disease in sorted(disease_names):
        disease_lower = disease.lower()
        phase4_in_disease = []
        if disease_lower in drug_sources:
            for drug in phase4_drugs:
                if drug in drug_sources[disease_lower]:
                    source = drug_sources[disease_lower][drug]
                    phase = drug_phases.get(drug, 'N/A')
                    phase4_in_disease.append((drug, source, phase))
        
        if phase4_in_disease:
            f.write(f"\n{disease.upper()}\n")
            f.write(f"  Found {len(phase4_in_disease)} phase 4 drugs:\n")
            for drug, source, phase in sorted(phase4_in_disease):
                f.write(f"    • {drug:<25} [{source:<12}] Phase {phase}\n")
        else:
            f.write(f"\n{disease.upper()}\n")
            f.write(f"  No phase 4 drugs recovered\n")
    
    f.write("\n" + "=" * 100 + "\n")
    f.write("INTERPRETATION NOTES\n")
    f.write("=" * 100 + "\n")
    f.write("""
Phase 4 Clinical Trial Status indicates drugs that have completed the majority of clinical 
testing and validation in human populations. Finding recovered drugs in Phase 4 is significant
because:

1. VALIDATION LEVEL: Phase 4 drugs have the highest level of clinical validation
2. SAFETY PROFILE: Side effects and adverse reactions are well-documented
3. EFFICACY DATA: Effectiveness is well-established in target populations
4. REGULATORY APPROVAL: Often already approved for at least one indication
5. REPURPOSING POTENTIAL: Using Phase 4 drugs for new diseases has lower risk

METHODOLOGY:
- Drugs were identified as recovered using CMAP and/or TAHOE databases
- Clinical trial phase information was extracted from public databases
- "Both" indicates drugs found by both CMAP and TAHOE methods (higher confidence)
- "CMAP Only" or "TAHOE Only" indicates single-method recovery

RECOMMENDATIONS:
- Prioritize Phase 4 drugs for experimental validation (highest confidence, lowest risk)
- Phase 4 drugs in "Both" category should be prioritized for further investigation
- Validate recovered efficacy using disease-specific biomarkers
- Consider existing safety/efficacy data when designing follow-up studies
""")

print(f"✓ Saved phase 4 validation report: {report_path}")

# ===== PHASE 4 SUMMARY STATISTICS VISUALIZATION =====
fig, axes = plt.subplots(2, 2, figsize=(15, 12))

# 1. Distribution of all drugs by phase
all_phases = [drug_phases.get(drug, None) for drug in all_drugs if drug in drug_phases]
unique_phases = sorted(set(p for p in all_phases if p is not None))
phase_counts = {phase: sum(1 for p in all_phases if p == phase) for phase in unique_phases}

axes[0, 0].bar([str(int(p)) for p in sorted(phase_counts.keys())], 
              [phase_counts[p] for p in sorted(phase_counts.keys())],
              color='#3498DB', alpha=0.7, edgecolor='black', linewidth=1.5)
axes[0, 0].set_xlabel('Clinical Trial Phase', fontsize=11, fontweight='bold')
axes[0, 0].set_ylabel('Number of Drugs', fontsize=11, fontweight='bold')
axes[0, 0].set_title('Distribution of Recovered Drugs by Clinical Trial Phase', 
                     fontsize=12, fontweight='bold')
axes[0, 0].grid(axis='y', alpha=0.3, linestyle='--')

# Add value labels on bars
for i, (phase, count) in enumerate(sorted(phase_counts.items())):
    axes[0, 0].text(i, count + 0.5, str(count), ha='center', fontweight='bold')

# 2. Phase 4 drugs by recovery method
methods = ['CMAP Only', 'TAHOE Only', 'Both Methods']
counts = [phase4_cmap_only, phase4_tahoe_only, phase4_both]
colors_bar = ['#F39C12', '#5DADE2', '#9B59B6']

axes[0, 1].bar(methods, counts, color=colors_bar, alpha=0.7, edgecolor='black', linewidth=1.5)
axes[0, 1].set_ylabel('Number of Instances', fontsize=11, fontweight='bold')
axes[0, 1].set_title('Phase 4 Drugs by Recovery Method', fontsize=12, fontweight='bold')
axes[0, 1].grid(axis='y', alpha=0.3, linestyle='--')

# Add value labels
for i, count in enumerate(counts):
    axes[0, 1].text(i, count + 0.3, str(count), ha='center', fontweight='bold')

# 3. Top phase 4 drugs by frequency
top_n = 12
top_phase4_drugs = sorted(phase4_occurrences.items(), 
                          key=lambda x: len(x[1]['diseases']), reverse=True)[:top_n]
drug_names_top = [drug for drug, _ in top_phase4_drugs]
drug_counts_top = [len(info['diseases']) for _, info in top_phase4_drugs]

axes[1, 0].barh(range(len(drug_names_top)), drug_counts_top, color='#E74C3C', alpha=0.7, edgecolor='black', linewidth=1.5)
axes[1, 0].set_yticks(range(len(drug_names_top)))
axes[1, 0].set_yticklabels(drug_names_top, fontsize=10)
axes[1, 0].set_xlabel('Number of Diseases', fontsize=11, fontweight='bold')
axes[1, 0].set_title(f'Top {top_n} Phase 4 Drugs by Recovery Frequency', fontsize=12, fontweight='bold')
axes[1, 0].invert_yaxis()
axes[1, 0].grid(axis='x', alpha=0.3, linestyle='--')

# Add value labels
for i, v in enumerate(drug_counts_top):
    axes[1, 0].text(v + 0.1, i, str(v), va='center', fontweight='bold')

# 4. Overall recovery statistics with phase 4 highlight
phase4_percent = 100 * len(phase4_drugs) / len(all_drugs)
non_phase4_percent = 100 * (len(all_drugs) - len(phase4_drugs)) / len(all_drugs)

wedges, texts, autotexts = axes[1, 1].pie([len(phase4_drugs), len(all_drugs) - len(phase4_drugs)],
                                           labels=[f'Phase 4\nDrugs\n({len(phase4_drugs)})', 
                                                  f'Other Phases\n({len(all_drugs) - len(phase4_drugs)})'],
                                           colors=['#E74C3C', '#95A5A6'],
                                           autopct='%1.1f%%',
                                           startangle=90,
                                           textprops={'fontsize': 11, 'weight': 'bold'})
axes[1, 1].set_title('Proportion of Phase 4 Drugs\nin All Recovered Drugs', fontsize=12, fontweight='bold')

plt.tight_layout()

stats_output = os.path.join(output_dir, 'phase4_validation_statistics.png')
plt.savefig(stats_output, dpi=300, bbox_inches='tight')
print(f"✓ Saved phase 4 statistics visualization (PNG): {stats_output}")

stats_pdf = os.path.join(output_dir, 'phase4_validation_statistics.pdf')
plt.savefig(stats_pdf, bbox_inches='tight')
print(f"✓ Saved phase 4 statistics visualization (PDF): {stats_pdf}")

plt.close()

# ===== CREATE A CSV WITH PHASE 4 DRUG DETAILS =====
phase4_csv_path = os.path.join(output_dir, 'phase4_drugs_detailed_list.csv')

phase4_data = []
for drug in sorted(phase4_drugs):
    if drug in phase4_occurrences:
        info = phase4_occurrences[drug]
        phase = drug_phases.get(drug, 'N/A')
        recovery_freq = drug_freq.get(drug, 0)
        num_diseases = len(set(info['diseases']))
        methods = ', '.join(sorted(info['sources']))
        diseases_str = '; '.join(sorted(set(info['diseases'])))
        
        phase4_data.append({
            'Drug': drug,
            'Clinical_Trial_Phase': phase,
            'Recovery_Frequency': recovery_freq,
            'Number_of_Diseases': num_diseases,
            'Recovery_Methods': methods,
            'Diseases_Found_In': diseases_str
        })

df_phase4 = pd.DataFrame(phase4_data)
df_phase4 = df_phase4.sort_values('Number_of_Diseases', ascending=False)
df_phase4.to_csv(phase4_csv_path, index=False)
print(f"✓ Saved phase 4 drugs detailed list (CSV): {phase4_csv_path}")

print("\n" + "=" * 80)
print("PHASE 4 VALIDATION ANALYSIS COMPLETE!")
print("=" * 80)
print(f"\nGenerated Files:")
print(f"  1. heatmap_recovery_source_innovative_with_phase4.png - Main visualization with red borders")
print(f"  2. heatmap_recovery_source_innovative_with_phase4.pdf - PDF version")
print(f"  3. phase4_validation_statistics.png - Statistical analysis charts")
print(f"  4. phase4_validation_statistics.pdf - PDF version of charts")
print(f"  5. phase4_drug_validation_report.txt - Detailed text report")
print(f"  6. phase4_drugs_detailed_list.csv - Structured data for further analysis")

print(f"\nKey Findings:")
print(f"  • Total Phase 4 drugs identified: {len(phase4_drugs)}")
print(f"  • Percentage of all recovered drugs: {100*len(phase4_drugs)/len(all_drugs):.1f}%")
print(f"  • Found by CMAP only: {phase4_cmap_only} instances")
print(f"  • Found by TAHOE only: {phase4_tahoe_only} instances")
print(f"  • Found by both methods: {phase4_both} instances (highest confidence)")

if sorted_phase4:
    print(f"\nTop 5 Phase 4 Drugs (by recovery frequency):")
    for rank, (drug, info) in enumerate(sorted_phase4[:5], 1):
        print(f"  {rank}. {drug}: {len(set(info['diseases']))} diseases, {drug_freq.get(drug, 0)} total recoveries")

print("\n" + "=" * 80)
