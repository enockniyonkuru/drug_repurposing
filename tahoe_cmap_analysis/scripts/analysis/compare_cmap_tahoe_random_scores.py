#!/usr/bin/env python3
"""
Compare CMAP and Tahoe Random Scores Distributions

Loads random score distributions from RData files and performs statistical
comparison between CMAP and Tahoe drug discovery datasets. Generates summary
statistics and visualizations to assess scoring consistency.
"""

import pyreadr
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from scipy import stats

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (16, 10)

# File paths (relative to drug_repurposing root directory)
cmap_path = "tahoe_cmap_analysis/results/sirota_lab_disease_results_filtered/CoreFibroid_CMAP_20251104-211901/file548b4a836da2_random_scores_logFC_0.RData"
tahoe_path = "tahoe_cmap_analysis/results/sirota_lab_disease_results_filtered/CoreFibroid_TAHOE_20251104-211901/file548b7a92cce5_random_scores_logFC_0.RData"

print("="*80)
print("LOADING DATA")
print("="*80)

# Load CMAP data
print(f"\nLoading CMAP: {cmap_path}")
cmap_result = pyreadr.read_r(cmap_path)
cmap_key = list(cmap_result.keys())[0]
cmap_scores = cmap_result[cmap_key][cmap_result[cmap_key].columns[0]].dropna()
print(f"  Loaded {len(cmap_scores):,} CMAP scores")

# Load Tahoe data
print(f"\nLoading Tahoe: {tahoe_path}")
tahoe_result = pyreadr.read_r(tahoe_path)
tahoe_key = list(tahoe_result.keys())[0]
tahoe_scores = tahoe_result[tahoe_key][tahoe_result[tahoe_key].columns[0]].dropna()
print(f"  Loaded {len(tahoe_scores):,} Tahoe scores")

# Statistics comparison
print("\n" + "="*80)
print("STATISTICS COMPARISON")
print("="*80)

stats_df = pd.DataFrame({
    'CMAP': [
        len(cmap_scores),
        cmap_scores.mean(),
        cmap_scores.median(),
        cmap_scores.std(),
        cmap_scores.min(),
        cmap_scores.max(),
        cmap_scores.quantile(0.25),
        cmap_scores.quantile(0.75),
        (cmap_scores == 0).sum(),
        (cmap_scores == 0).sum() / len(cmap_scores) * 100
    ],
    'Tahoe': [
        len(tahoe_scores),
        tahoe_scores.mean(),
        tahoe_scores.median(),
        tahoe_scores.std(),
        tahoe_scores.min(),
        tahoe_scores.max(),
        tahoe_scores.quantile(0.25),
        tahoe_scores.quantile(0.75),
        (tahoe_scores == 0).sum(),
        (tahoe_scores == 0).sum() / len(tahoe_scores) * 100
    ]
}, index=['Count', 'Mean', 'Median', 'Std Dev', 'Min', 'Max', '25th %ile', '75th %ile', 'Zeros', 'Zeros %'])

print(stats_df.to_string())

# Create comprehensive visualization
fig = plt.figure(figsize=(18, 12))
gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)

# Row 1: Histograms
ax1 = fig.add_subplot(gs[0, 0])
ax1.hist(cmap_scores, bins=50, edgecolor='black', alpha=0.7, color='steelblue')
ax1.axvline(cmap_scores.mean(), color='red', linestyle='--', linewidth=2, label=f'Mean: {cmap_scores.mean():.4f}')
ax1.axvline(cmap_scores.median(), color='green', linestyle='--', linewidth=2, label=f'Median: {cmap_scores.median():.4f}')
ax1.set_xlabel('Random Score', fontsize=11)
ax1.set_ylabel('Frequency', fontsize=11)
ax1.set_title('CMAP Random Scores - Histogram', fontsize=13, fontweight='bold')
ax1.legend(fontsize=9)
ax1.grid(True, alpha=0.3)

ax2 = fig.add_subplot(gs[0, 1])
ax2.hist(tahoe_scores, bins=50, edgecolor='black', alpha=0.7, color='coral')
ax2.axvline(tahoe_scores.mean(), color='red', linestyle='--', linewidth=2, label=f'Mean: {tahoe_scores.mean():.4f}')
ax2.axvline(tahoe_scores.median(), color='green', linestyle='--', linewidth=2, label=f'Median: {tahoe_scores.median():.4f}')
ax2.set_xlabel('Random Score', fontsize=11)
ax2.set_ylabel('Frequency', fontsize=11)
ax2.set_title('Tahoe Random Scores - Histogram', fontsize=13, fontweight='bold')
ax2.legend(fontsize=9)
ax2.grid(True, alpha=0.3)

# Overlaid histogram
ax3 = fig.add_subplot(gs[0, 2])
ax3.hist(cmap_scores, bins=50, alpha=0.5, color='steelblue', label='CMAP', edgecolor='black')
ax3.hist(tahoe_scores, bins=50, alpha=0.5, color='coral', label='Tahoe', edgecolor='black')
ax3.set_xlabel('Random Score', fontsize=11)
ax3.set_ylabel('Frequency', fontsize=11)
ax3.set_title('Overlaid Histograms', fontsize=13, fontweight='bold')
ax3.legend(fontsize=10)
ax3.grid(True, alpha=0.3)

# Row 2: Density plots
ax4 = fig.add_subplot(gs[1, 0])
cmap_scores.plot(kind='kde', ax=ax4, color='steelblue', linewidth=2, label='CMAP')
ax4.axvline(cmap_scores.mean(), color='red', linestyle='--', linewidth=2, alpha=0.7)
ax4.set_xlabel('Random Score', fontsize=11)
ax4.set_ylabel('Density', fontsize=11)
ax4.set_title('CMAP Random Scores - Density', fontsize=13, fontweight='bold')
ax4.legend(fontsize=10)
ax4.grid(True, alpha=0.3)

ax5 = fig.add_subplot(gs[1, 1])
tahoe_scores.plot(kind='kde', ax=ax5, color='coral', linewidth=2, label='Tahoe')
ax5.axvline(tahoe_scores.mean(), color='red', linestyle='--', linewidth=2, alpha=0.7)
ax5.set_xlabel('Random Score', fontsize=11)
ax5.set_ylabel('Density', fontsize=11)
ax5.set_title('Tahoe Random Scores - Density', fontsize=13, fontweight='bold')
ax5.legend(fontsize=10)
ax5.grid(True, alpha=0.3)

# Overlaid density
ax6 = fig.add_subplot(gs[1, 2])
cmap_scores.plot(kind='kde', ax=ax6, color='steelblue', linewidth=2.5, label='CMAP')
tahoe_scores.plot(kind='kde', ax=ax6, color='coral', linewidth=2.5, label='Tahoe')
ax6.set_xlabel('Random Score', fontsize=11)
ax6.set_ylabel('Density', fontsize=11)
ax6.set_title('Overlaid Density Plots', fontsize=13, fontweight='bold')
ax6.legend(fontsize=10)
ax6.grid(True, alpha=0.3)

# Row 3: Box plots and Q-Q plots
ax7 = fig.add_subplot(gs[2, 0])
bp = ax7.boxplot([cmap_scores, tahoe_scores], labels=['CMAP', 'Tahoe'], 
                  patch_artist=True, widths=0.6)
bp['boxes'][0].set_facecolor('lightblue')
bp['boxes'][1].set_facecolor('lightcoral')
for box in bp['boxes']:
    box.set_edgecolor('black')
for median in bp['medians']:
    median.set_color('red')
    median.set_linewidth(2)
ax7.set_ylabel('Random Score', fontsize=11)
ax7.set_title('Box Plot Comparison', fontsize=13, fontweight='bold')
ax7.grid(True, alpha=0.3, axis='y')

# Q-Q plots
ax8 = fig.add_subplot(gs[2, 1])
stats.probplot(cmap_scores, dist="norm", plot=ax8)
ax8.set_title('CMAP Q-Q Plot (Normal)', fontsize=13, fontweight='bold')
ax8.grid(True, alpha=0.3)

ax9 = fig.add_subplot(gs[2, 2])
stats.probplot(tahoe_scores, dist="norm", plot=ax9)
ax9.set_title('Tahoe Q-Q Plot (Normal)', fontsize=13, fontweight='bold')
ax9.grid(True, alpha=0.3)

plt.suptitle('CMAP vs Tahoe Random Scores Distribution Comparison\nCoreFibroid Analysis', 
             fontsize=16, fontweight='bold', y=0.995)

# Save the figure
output_path = "../data/analysis/temp_sirota_all/CoreFibroid_cmap_vs_tahoe_random_scores_comparison_100k.png"
plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"\n✓ Visualization saved to: {output_path}")

# Statistical tests
print("\n" + "="*80)
print("STATISTICAL TESTS")
print("="*80)

# Kolmogorov-Smirnov test
ks_stat, ks_pval = stats.ks_2samp(cmap_scores, tahoe_scores)
print(f"\nKolmogorov-Smirnov Test:")
print(f"  Statistic: {ks_stat:.6f}")
print(f"  P-value: {ks_pval:.6e}")
print(f"  Interpretation: {'Distributions are DIFFERENT' if ks_pval < 0.05 else 'Distributions are SIMILAR'}")

# Mann-Whitney U test
mw_stat, mw_pval = stats.mannwhitneyu(cmap_scores, tahoe_scores, alternative='two-sided')
print(f"\nMann-Whitney U Test:")
print(f"  Statistic: {mw_stat:.6f}")
print(f"  P-value: {mw_pval:.6e}")
print(f"  Interpretation: {'Medians are DIFFERENT' if mw_pval < 0.05 else 'Medians are SIMILAR'}")

# Levene's test for equality of variances
lev_stat, lev_pval = stats.levene(cmap_scores, tahoe_scores)
print(f"\nLevene's Test (Variance Equality):")
print(f"  Statistic: {lev_stat:.6f}")
print(f"  P-value: {lev_pval:.6e}")
print(f"  Interpretation: {'Variances are DIFFERENT' if lev_pval < 0.05 else 'Variances are SIMILAR'}")

plt.show()

print("\n" + "="*80)
print("Analysis complete!")
print("="*80)
