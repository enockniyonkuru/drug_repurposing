#!/usr/bin/env python3
"""
Phase 4: Generate Visualizations

This script creates comprehensive figures:
1. Distribution plots (histograms and density)
2. Box plots comparing CMAP vs TAHOE
3. Scatter plots (Precision vs Recall)
4. Heatmap of per-disease metrics
5. Summary comparison tables
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

print("=" * 80)
print("PHASE 4: GENERATE VISUALIZATIONS")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "intermediate_data"
fig_dir = base_dir / "figures"
fig_dir.mkdir(exist_ok=True)

# Set style
sns.set_style("whitegrid")
sns.set_palette("husl")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 11

# Load data
print("\nLoading data...")
cmap_results = pd.read_csv(output_dir / "cmap_precision_recall_per_disease.csv")
tahoe_results = pd.read_csv(output_dir / "tahoe_precision_recall_per_disease.csv")
combined_results = pd.read_csv(output_dir / "combined_precision_recall.csv")
summary_stats = pd.read_csv(output_dir / "summary_statistics.csv")

print(f"✓ Data loaded successfully")

# =============================================================================
# FIGURE 1: PRECISION DISTRIBUTION
# =============================================================================
print("\nGenerating Figure 1: Precision Distribution...")

fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Histogram
ax1 = axes[0]
ax1.hist(cmap_results['Precision_%'].dropna(), bins=20, alpha=0.6, label='CMAP', edgecolor='black')
ax1.hist(tahoe_results['Precision_%'].dropna(), bins=20, alpha=0.6, label='TAHOE', edgecolor='black')
ax1.axvline(cmap_results['Precision_%'].mean(), color='C0', linestyle='--', linewidth=2, label=f'CMAP mean: {cmap_results["Precision_%"].mean():.1f}%')
ax1.axvline(tahoe_results['Precision_%'].mean(), color='C1', linestyle='--', linewidth=2, label=f'TAHOE mean: {tahoe_results["Precision_%"].mean():.1f}%')
ax1.set_xlabel('Precision (%)')
ax1.set_ylabel('Number of Diseases')
ax1.set_title('Distribution of Precision Across Diseases')
ax1.legend()
ax1.grid(True, alpha=0.3)

# Density plot
ax2 = axes[1]
cmap_results['Precision_%'].dropna().plot(kind='density', ax=ax2, label='CMAP', linewidth=2)
tahoe_results['Precision_%'].dropna().plot(kind='density', ax=ax2, label='TAHOE', linewidth=2)
ax2.set_xlabel('Precision (%)')
ax2.set_ylabel('Density')
ax2.set_title('Kernel Density Estimate: Precision')
ax2.legend()
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(fig_dir / "figure_01_precision_distribution.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"✓ Saved: {fig_dir / 'figure_01_precision_distribution.png'}")

# =============================================================================
# FIGURE 2: RECALL DISTRIBUTION
# =============================================================================
print("Generating Figure 2: Recall Distribution...")

fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Histogram
ax1 = axes[0]
ax1.hist(cmap_results['Recall_%'].dropna(), bins=20, alpha=0.6, label='CMAP', edgecolor='black')
ax1.hist(tahoe_results['Recall_%'].dropna(), bins=20, alpha=0.6, label='TAHOE', edgecolor='black')
ax1.axvline(cmap_results['Recall_%'].mean(), color='C0', linestyle='--', linewidth=2, label=f'CMAP mean: {cmap_results["Recall_%"].mean():.1f}%')
ax1.axvline(tahoe_results['Recall_%'].mean(), color='C1', linestyle='--', linewidth=2, label=f'TAHOE mean: {tahoe_results["Recall_%"].mean():.1f}%')
ax1.set_xlabel('Recall (%)')
ax1.set_ylabel('Number of Diseases')
ax1.set_title('Distribution of Recall Across Diseases')
ax1.legend()
ax1.grid(True, alpha=0.3)

# Density plot
ax2 = axes[1]
cmap_results['Recall_%'].dropna().plot(kind='density', ax=ax2, label='CMAP', linewidth=2)
tahoe_results['Recall_%'].dropna().plot(kind='density', ax=ax2, label='TAHOE', linewidth=2)
ax2.set_xlabel('Recall (%)')
ax2.set_ylabel('Density')
ax2.set_title('Kernel Density Estimate: Recall')
ax2.legend()
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(fig_dir / "figure_02_recall_distribution.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"✓ Saved: {fig_dir / 'figure_02_recall_distribution.png'}")

# =============================================================================
# FIGURE 3: PRECISION VS RECALL SCATTER
# =============================================================================
print("Generating Figure 3: Precision vs Recall Scatter...")

fig, ax = plt.subplots(figsize=(10, 8))

# CMAP
ax.scatter(cmap_results['Precision_%'], cmap_results['Recall_%'], 
          alpha=0.6, s=100, label='CMAP', color='C0', edgecolors='black', linewidth=0.5)

# TAHOE
ax.scatter(tahoe_results['Precision_%'], tahoe_results['Recall_%'], 
          alpha=0.6, s=100, label='TAHOE', color='C1', edgecolors='black', linewidth=0.5)

ax.set_xlabel('Precision (%)', fontsize=12)
ax.set_ylabel('Recall (%)', fontsize=12)
ax.set_title('Precision vs Recall: Per-Disease Analysis', fontsize=14)
ax.legend(fontsize=11)
ax.grid(True, alpha=0.3)

# Add mean markers
cmap_mean_prec = cmap_results['Precision_%'].mean()
cmap_mean_recall = cmap_results['Recall_%'].mean()
tahoe_mean_prec = tahoe_results['Precision_%'].mean()
tahoe_mean_recall = tahoe_results['Recall_%'].mean()

ax.scatter([cmap_mean_prec], [cmap_mean_recall], s=300, marker='*', color='C0', 
          edgecolors='black', linewidth=2, label='CMAP mean', zorder=5)
ax.scatter([tahoe_mean_prec], [tahoe_mean_recall], s=300, marker='*', color='C1', 
          edgecolors='black', linewidth=2, label='TAHOE mean', zorder=5)

ax.legend(fontsize=11, loc='best')
plt.tight_layout()
plt.savefig(fig_dir / "figure_03_precision_vs_recall_scatter.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"✓ Saved: {fig_dir / 'figure_03_precision_vs_recall_scatter.png'}")

# =============================================================================
# FIGURE 4: BOX PLOTS COMPARISON
# =============================================================================
print("Generating Figure 4: Box Plot Comparison...")

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# Precision box plot
ax1 = axes[0]
data_precision = [cmap_results['Precision_%'].dropna(), tahoe_results['Precision_%'].dropna()]
bp1 = ax1.boxplot(data_precision, labels=['CMAP', 'TAHOE'], patch_artist=True)
for patch, color in zip(bp1['boxes'], ['C0', 'C1']):
    patch.set_facecolor(color)
    patch.set_alpha(0.6)
ax1.set_ylabel('Precision (%)')
ax1.set_title('Precision Comparison')
ax1.grid(True, alpha=0.3, axis='y')

# Recall box plot
ax2 = axes[1]
data_recall = [cmap_results['Recall_%'].dropna(), tahoe_results['Recall_%'].dropna()]
bp2 = ax2.boxplot(data_recall, labels=['CMAP', 'TAHOE'], patch_artist=True)
for patch, color in zip(bp2['boxes'], ['C0', 'C1']):
    patch.set_facecolor(color)
    patch.set_alpha(0.6)
ax2.set_ylabel('Recall (%)')
ax2.set_title('Recall Comparison')
ax2.grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig(fig_dir / "figure_04_comparison_boxplot.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"✓ Saved: {fig_dir / 'figure_04_comparison_boxplot.png'}")

# =============================================================================
# FIGURE 5: HEATMAP OF PER-DISEASE METRICS
# =============================================================================
print("Generating Figure 5: Per-Disease Heatmap...")

# Prepare data for heatmap (sorted by TAHOE recall)
heatmap_data_cmap = cmap_results.set_index('Disease')[['Precision_%', 'Recall_%']]
heatmap_data_tahoe = tahoe_results.set_index('Disease')[['Precision_%', 'Recall_%']]

# Top 30 diseases by average of both metrics
top_diseases_cmap = cmap_results.nlargest(15, 'Recall_%')['Disease'].tolist()
top_diseases_tahoe = tahoe_results.nlargest(15, 'Recall_%')['Disease'].tolist()
top_diseases = list(set(top_diseases_cmap + top_diseases_tahoe))[:20]

heatmap_matrix = pd.DataFrame(index=top_diseases, 
                              columns=['CMAP Prec', 'CMAP Recall', 'TAHOE Prec', 'TAHOE Recall'])

for disease in top_diseases:
    if disease in cmap_results['Disease'].values:
        cmap_row = cmap_results[cmap_results['Disease'] == disease].iloc[0]
        heatmap_matrix.loc[disease, 'CMAP Prec'] = cmap_row['Precision_%']
        heatmap_matrix.loc[disease, 'CMAP Recall'] = cmap_row['Recall_%']
    
    if disease in tahoe_results['Disease'].values:
        tahoe_row = tahoe_results[tahoe_results['Disease'] == disease].iloc[0]
        heatmap_matrix.loc[disease, 'TAHOE Prec'] = tahoe_row['Precision_%']
        heatmap_matrix.loc[disease, 'TAHOE Recall'] = tahoe_row['Recall_%']

heatmap_matrix = heatmap_matrix.fillna(0).astype(float)

fig, ax = plt.subplots(figsize=(10, 12))
sns.heatmap(heatmap_matrix, annot=True, fmt='.1f', cmap='RdYlGn', cbar_kws={'label': 'Percentage (%)'}, ax=ax)
ax.set_title('Per-Disease Precision and Recall Heatmap (Top Diseases)')
ax.set_xlabel('Metric')
ax.set_ylabel('Disease')
plt.tight_layout()
plt.savefig(fig_dir / "figure_05_disease_heatmap.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"✓ Saved: {fig_dir / 'figure_05_disease_heatmap.png'}")

# =============================================================================
# FIGURE 6: SUMMARY TABLE
# =============================================================================
print("Generating Figure 6: Summary Table Figure...")

fig, ax = plt.subplots(figsize=(12, 6))
ax.axis('tight')
ax.axis('off')

# Create summary table
summary_table_data = [
    ['Metric', 'CMAP Mean', 'CMAP SD', 'TAHOE Mean', 'TAHOE SD'],
    ['Precision (%)', 
     f"{cmap_results['Precision_%'].mean():.2f}",
     f"{cmap_results['Precision_%'].std():.2f}",
     f"{tahoe_results['Precision_%'].mean():.2f}",
     f"{tahoe_results['Precision_%'].std():.2f}"],
    ['Recall (%)', 
     f"{cmap_results['Recall_%'].mean():.2f}",
     f"{cmap_results['Recall_%'].std():.2f}",
     f"{tahoe_results['Recall_%'].mean():.2f}",
     f"{tahoe_results['Recall_%'].std():.2f}"],
    ['Diseases (N)', 
     f"{len(cmap_results)}",
     '',
     f"{len(tahoe_results)}",
     '']
]

table = ax.table(cellText=summary_table_data, cellLoc='center', loc='center',
                colWidths=[0.2, 0.15, 0.15, 0.15, 0.15])
table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1, 2)

# Style header row
for i in range(5):
    table[(0, i)].set_facecolor('#4CAF50')
    table[(0, i)].set_text_props(weight='bold', color='white')

# Alternate row colors
for i in range(1, len(summary_table_data)):
    for j in range(5):
        if i % 2 == 0:
            table[(i, j)].set_facecolor('#f0f0f0')

plt.title('Summary Statistics: Precision & Recall Analysis', fontsize=14, pad=20)
plt.savefig(fig_dir / "figure_06_summary_table.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"✓ Saved: {fig_dir / 'figure_06_summary_table.png'}")

print("\n" + "=" * 80)
print("PHASE 4 COMPLETE - ALL VISUALIZATIONS GENERATED")
print("=" * 80)
print(f"\nFigures saved to: {fig_dir}")
