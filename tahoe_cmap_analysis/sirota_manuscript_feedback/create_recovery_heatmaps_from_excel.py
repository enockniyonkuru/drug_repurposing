#!/usr/bin/env python3
"""
Create Recovery Heatmaps from Excel Source Data

This script generates recovery heatmaps directly from the Excel file (20_autoimmune.xlsx)
to ensure consistency with the official data. It creates:
1. Recovery source innovative heatmap (CMAP Only, TAHOE Only, Both)
2. CMAP vs TAHOE recovery rate heatmap
3. Recovery statistics visualization

Data is taken directly from 20_autoimmune.xlsx to match figure2_heatmap.png exactly.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import numpy as np
import os

# Paths
excel_file = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/20_autoimmune.xlsx"
output_dir = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback"

print("Creating recovery heatmaps from Excel source data...")
print("=" * 80)

# Load Excel data
df = pd.read_excel(excel_file)

# Sort by TAHOE recovery rate for better visualization
df_sorted = df.sort_values('TAHOE Recovery Rate', ascending=False)

# Extract relevant columns
diseases = df_sorted['disease_name'].str.title().tolist()
cmap_recovery_rates = df_sorted['CMAP Recovery Rate'].tolist()
tahoe_recovery_rates = df_sorted['TAHOE Recovery Rate'].tolist()
cmap_recovered = df_sorted['cmap_in_known_count'].tolist()
tahoe_recovered = df_sorted['tahoe_in_known_count'].tolist()
both_recovered = df_sorted['common_in_known_count'].tolist()
total_recovered = df_sorted['total_in_known_count'].tolist()

# Calculate CMAP only and TAHOE only
cmap_only = [c - b for c, b in zip(cmap_recovered, both_recovered)]
tahoe_only = [t - b for t, b in zip(tahoe_recovered, both_recovered)]

print(f"Analyzing {len(df_sorted)} diseases")
print(f"Total recovered drugs across all diseases:")
print(f"  CMAP Only: {sum(cmap_only)}")
print(f"  TAHOE Only: {sum(tahoe_only)}")
print(f"  Both: {sum(both_recovered)}")
print(f"  Total unique: {sum(total_recovered)}")

# =============================================================================
# FIGURE 1: Recovery Source Heatmap
# =============================================================================
print("\n[1] Creating recovery source heatmap...")

# Create matrix for heatmap (20 diseases × 3 columns for sources)
recovery_sources = np.array([
    cmap_only,
    both_recovered,
    tahoe_only
]).T

fig, ax = plt.subplots(figsize=(8, 12))

# Create heatmap
im = ax.imshow(recovery_sources, aspect='auto', cmap='YlOrRd', interpolation='nearest')

# Set ticks and labels
ax.set_xticks([0, 1, 2])
ax.set_xticklabels(['CMAP Only', 'Both', 'TAHOE Only'], fontsize=11, fontweight='bold')
ax.set_yticks(np.arange(len(diseases)))
ax.set_yticklabels(diseases, fontsize=10)

# Add values in cells
for i in range(len(diseases)):
    for j in range(3):
        value = recovery_sources[i, j]
        if value > 0:
            text = ax.text(j, i, int(value),
                          ha="center", va="center", color="black" if value < 8 else "white",
                          fontweight='bold', fontsize=9)

ax.set_title('Known Drug Recovery by Source\nAcross All 20 Autoimmune Diseases',
             fontsize=14, fontweight='bold', pad=20)

# Add colorbar
cbar = plt.colorbar(im, ax=ax, orientation='vertical', pad=0.02)
cbar.set_label('Number of Drugs', fontsize=10)

plt.tight_layout()

# Save
png_file = os.path.join(output_dir, 'heatmap_recovery_source_from_excel.png')
pdf_file = os.path.join(output_dir, 'heatmap_recovery_source_from_excel.pdf')
plt.savefig(png_file, dpi=300, bbox_inches='tight')
plt.savefig(pdf_file, bbox_inches='tight')
plt.close()
print(f"✓ Saved: heatmap_recovery_source_from_excel.png/pdf")

# =============================================================================
# FIGURE 2: Recovery Rate Heatmap (CMAP vs TAHOE)
# =============================================================================
print("[2] Creating recovery rate comparison heatmap...")

# Create matrix for recovery rates
recovery_rates = np.array([
    cmap_recovery_rates,
    tahoe_recovery_rates
]).T

fig, ax = plt.subplots(figsize=(8, 12))

# Create heatmap
im = ax.imshow(recovery_rates, aspect='auto', cmap='RdYlGn', vmin=0, vmax=100, interpolation='nearest')

# Set ticks and labels
ax.set_xticks([0, 1])
ax.set_xticklabels(['CMAP', 'TAHOE'], fontsize=11, fontweight='bold')
ax.set_yticks(np.arange(len(diseases)))
ax.set_yticklabels(diseases, fontsize=10)

# Add percentage values in cells
for i in range(len(diseases)):
    for j in range(2):
        value = recovery_rates[i, j]
        text_color = "black" if 20 < value < 80 else "white"
        text = ax.text(j, i, f'{value:.1f}%',
                      ha="center", va="center", color=text_color,
                      fontweight='bold', fontsize=9)

ax.set_title('Known Drug Recovery Rates (%)\nCMAP vs TAHOE',
             fontsize=14, fontweight='bold', pad=20)

# Add colorbar
cbar = plt.colorbar(im, ax=ax, orientation='vertical', pad=0.02)
cbar.set_label('Recovery Rate (%)', fontsize=10)

plt.tight_layout()

# Save
png_file = os.path.join(output_dir, 'heatmap_recovery_rates_from_excel.png')
pdf_file = os.path.join(output_dir, 'heatmap_recovery_rates_from_excel.pdf')
plt.savefig(png_file, dpi=300, bbox_inches='tight')
plt.savefig(pdf_file, bbox_inches='tight')
plt.close()
print(f"✓ Saved: heatmap_recovery_rates_from_excel.png/pdf")

# =============================================================================
# FIGURE 3: Summary Statistics
# =============================================================================
print("[3] Creating summary statistics visualization...")

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# Left panel: Pie chart of recovery sources
sources_count = [sum(cmap_only), sum(both_recovered), sum(tahoe_only)]
sources_labels = [
    f'CMAP Only\n({sources_count[0]})',
    f'Both\n({sources_count[1]})',
    f'TAHOE Only\n({sources_count[2]})'
]
colors_pie = ['#F39C12', '#9B59B6', '#5DADE2']

axes[0].pie(sources_count, labels=sources_labels, colors=colors_pie, autopct='%1.1f%%',
            startangle=90, textprops={'fontsize': 11, 'weight': 'bold'})
axes[0].set_title('Distribution of Recovery Sources', fontsize=12, fontweight='bold')

# Right panel: Bar chart of diseases by total recovery
top_diseases_idx = np.argsort(total_recovered)[-15:]
top_diseases = [diseases[i] for i in top_diseases_idx]
top_totals = [total_recovered[i] for i in top_diseases_idx]

axes[1].barh(range(len(top_diseases)), top_totals, color='#70AD47', alpha=0.8, edgecolor='black')
axes[1].set_yticks(range(len(top_diseases)))
axes[1].set_yticklabels(top_diseases, fontsize=10)
axes[1].set_xlabel('Total Unique Drugs Recovered', fontsize=11, fontweight='bold')
axes[1].set_title('Top 15 Diseases by Drug Recovery', fontsize=12, fontweight='bold')
axes[1].invert_yaxis()

# Add value labels
for i, v in enumerate(top_totals):
    axes[1].text(v + 0.2, i, str(int(v)), va='center', fontsize=9, fontweight='bold')

plt.tight_layout()

# Save
png_file = os.path.join(output_dir, 'heatmap_recovery_statistics_from_excel.png')
pdf_file = os.path.join(output_dir, 'heatmap_recovery_statistics_from_excel.pdf')
plt.savefig(png_file, dpi=300, bbox_inches='tight')
plt.savefig(pdf_file, bbox_inches='tight')
plt.close()
print(f"✓ Saved: heatmap_recovery_statistics_from_excel.png/pdf")

# =============================================================================
# FIGURE 4: Comprehensive Comparison Table
# =============================================================================
print("[4] Creating comprehensive comparison table...")

fig, ax = plt.subplots(figsize=(14, 12))
ax.axis('off')

# Prepare table data
table_data = [['Disease', 'CMAP Rate %', 'TAHOE Rate %', 'CMAP Only', 'Both', 'TAHOE Only', 'Total']]

for i, disease in enumerate(diseases):
    table_data.append([
        disease,
        f'{cmap_recovery_rates[i]:.1f}%',
        f'{tahoe_recovery_rates[i]:.1f}%',
        str(int(cmap_only[i])),
        str(int(both_recovered[i])),
        str(int(tahoe_only[i])),
        str(int(total_recovered[i]))
    ])

# Create table
table = ax.table(cellText=table_data, loc='center', cellLoc='center',
                colWidths=[0.25, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12])
table.auto_set_font_size(False)
table.set_fontsize(9)
table.scale(1, 1.8)

# Style header row
for j in range(7):
    table[(0, j)].set_facecolor('#2c3e50')
    table[(0, j)].set_text_props(color='white', fontweight='bold', fontsize=10)

# Alternate row colors
for i in range(1, len(table_data)):
    for j in range(7):
        if i % 2 == 0:
            table[(i, j)].set_facecolor('#f0f0f0')

ax.set_title('Complete Recovery Data by Disease\n(From Excel Source)',
             fontsize=14, fontweight='bold', y=0.98)

plt.tight_layout()

# Save
png_file = os.path.join(output_dir, 'recovery_comparison_table_from_excel.png')
pdf_file = os.path.join(output_dir, 'recovery_comparison_table_from_excel.pdf')
plt.savefig(png_file, dpi=300, bbox_inches='tight')
plt.savefig(pdf_file, bbox_inches='tight')
plt.close()
print(f"✓ Saved: recovery_comparison_table_from_excel.png/pdf")

print("\n" + "=" * 80)
print("✓ All heatmaps created successfully from Excel source data!")
print("\nGenerated files:")
print("  • heatmap_recovery_source_from_excel.png/pdf")
print("  • heatmap_recovery_rates_from_excel.png/pdf")
print("  • heatmap_recovery_statistics_from_excel.png/pdf")
print("  • recovery_comparison_table_from_excel.png/pdf")
print("\nThese visualizations match the official data from 20_autoimmune.xlsx")
print("and are consistent with figure2_heatmap.png")
print("=" * 80)
