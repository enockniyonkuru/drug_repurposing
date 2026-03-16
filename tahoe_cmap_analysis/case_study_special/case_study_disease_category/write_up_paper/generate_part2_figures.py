#!/usr/bin/env python3
"""
Generate Part 2 Figures for Results Manuscript
Using DISEASE-LEVEL data (actual disease names, not therapeutic area combinations)

Figures:
- Figure 2A: Recall Distribution Histogram by Platform
- Figure 2B: Recall Distribution Density
- Figure 2C: Precision Distribution Density  
- Figure 2D: Recall Violin Plot by Platform
- Figure 2E: Precision Violin Plot by Platform
- Figure 2F: Heatmap of Top 20 Diseases by Recall (showing actual disease names)
- Figure 2G: Precision vs Recall Scatter Plot
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from scipy.stats import mannwhitneyu
import os

# Set style
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

# File paths - DISEASE-LEVEL data (actual disease names)
BASE_PATH = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special/case_study_disease_category"
CMAP_DATA = f"{BASE_PATH}/about_drpipe_results/recall_precision/outputs/Table_S3_CMAP_Per_Disease_Precision_Recall.csv"
TAHOE_DATA = f"{BASE_PATH}/about_drpipe_results/recall_precision/outputs/Table_S4_TAHOE_Per_Disease_Precision_Recall.csv"
OUTPUT_DIR = f"{BASE_PATH}/write_up_paper/figures"

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Load disease-level data
print("Loading disease-level data...")
cmap_df = pd.read_csv(CMAP_DATA)
tahoe_df = pd.read_csv(TAHOE_DATA)

print(f"CMAP: {len(cmap_df)} diseases")
print(f"TAHOE: {len(tahoe_df)} diseases")

# Add platform column
cmap_df['Platform'] = 'CMAP'
tahoe_df['Platform'] = 'TAHOE'

# Combine for comparison plots
combined_df = pd.concat([cmap_df, tahoe_df], ignore_index=True)

# Clean data - handle empty/missing recall values
combined_df['Recall'] = pd.to_numeric(combined_df['Recall'], errors='coerce').fillna(0)
combined_df['Precision'] = pd.to_numeric(combined_df['Precision'], errors='coerce').fillna(0)

cmap_df['Recall'] = pd.to_numeric(cmap_df['Recall'], errors='coerce').fillna(0)
cmap_df['Precision'] = pd.to_numeric(cmap_df['Precision'], errors='coerce').fillna(0)
tahoe_df['Recall'] = pd.to_numeric(tahoe_df['Recall'], errors='coerce').fillna(0)
tahoe_df['Precision'] = pd.to_numeric(tahoe_df['Precision'], errors='coerce').fillna(0)

# Color palette - Consistent with manuscript
# CMAP: Warm Orange, TAHOE: Serene Blue
COLORS = {'CMAP': '#F39C12', 'TAHOE': '#5DADE2'}

# Calculate statistics
cmap_mean = cmap_df['Recall'].mean()
tahoe_mean = tahoe_df['Recall'].mean()
cmap_median = cmap_df['Recall'].median()
tahoe_median = tahoe_df['Recall'].median()
cmap_prec_mean = cmap_df['Precision'].mean()
tahoe_prec_mean = tahoe_df['Precision'].mean()

# ============================================================================
# Figure 2A: Recall Distribution Histogram by Platform
# ============================================================================
print("\nGenerating Figure 2A: Recall Distribution Histogram...")

fig, ax = plt.subplots(figsize=(12, 7))

# Create histogram with overlapping bars
bins = np.arange(0, 105, 5)
ax.hist(cmap_df['Recall'], bins=bins, alpha=0.6, label=f'CMAP (n={len(cmap_df)})', 
        color=COLORS['CMAP'], edgecolor='white', linewidth=1.2)
ax.hist(tahoe_df['Recall'], bins=bins, alpha=0.6, label=f'TAHOE (n={len(tahoe_df)})', 
        color=COLORS['TAHOE'], edgecolor='white', linewidth=1.2)

ax.set_xlabel('Recall (%)', fontsize=14, fontweight='bold')
ax.set_ylabel('Number of Diseases', fontsize=14, fontweight='bold')
ax.set_title('Figure 2A: Recall Distribution by Platform\n(Disease-Level Analysis)', fontsize=16, fontweight='bold')
ax.legend(fontsize=12, frameon=True, fancybox=True, shadow=True)
ax.set_xlim(0, 100)
ax.tick_params(axis='both', labelsize=12)

# Add statistics text box
stats_text = f'CMAP: Mean={cmap_mean:.1f}%, Median={cmap_median:.1f}%\n'
stats_text += f'TAHOE: Mean={tahoe_mean:.1f}%, Median={tahoe_median:.1f}%'
ax.text(0.98, 0.95, stats_text, transform=ax.transAxes, fontsize=11,
        verticalalignment='top', horizontalalignment='right',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='white', alpha=0.9, edgecolor='gray'))

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2A_Recall_Distribution_Histogram.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2A_Recall_Distribution_Histogram.png")

# ============================================================================
# Figure 2B: Recall Distribution Density
# ============================================================================
print("\nGenerating Figure 2B: Recall Distribution Density...")

fig, ax = plt.subplots(figsize=(12, 7))

# KDE plots for recall
sns.kdeplot(data=cmap_df, x='Recall', ax=ax, color=COLORS['CMAP'], 
            label=f'CMAP (n={len(cmap_df)})', linewidth=3, fill=True, alpha=0.3)
sns.kdeplot(data=tahoe_df, x='Recall', ax=ax, color=COLORS['TAHOE'], 
            label=f'TAHOE (n={len(tahoe_df)})', linewidth=3, fill=True, alpha=0.3)

ax.set_xlabel('Recall (%)', fontsize=14, fontweight='bold')
ax.set_ylabel('Density', fontsize=14, fontweight='bold')
ax.set_title('Figure 2B: Recall Distribution Density\n(Disease-Level Analysis)', fontsize=16, fontweight='bold')
ax.legend(fontsize=12, frameon=True, fancybox=True, shadow=True)
ax.set_xlim(0, 100)
ax.tick_params(axis='both', labelsize=12)

# Add vertical lines for means
ax.axvline(cmap_mean, color=COLORS['CMAP'], linestyle='--', linewidth=2, alpha=0.8)
ax.axvline(tahoe_mean, color=COLORS['TAHOE'], linestyle='--', linewidth=2, alpha=0.8)

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2B_Recall_Density.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2B_Recall_Density.png")

# ============================================================================
# Figure 2C: Precision Distribution Density
# ============================================================================
print("\nGenerating Figure 2C: Precision Distribution Density...")

fig, ax = plt.subplots(figsize=(12, 7))

# KDE plots for precision
sns.kdeplot(data=cmap_df, x='Precision', ax=ax, color=COLORS['CMAP'], 
            label=f'CMAP (n={len(cmap_df)})', linewidth=3, fill=True, alpha=0.3)
sns.kdeplot(data=tahoe_df, x='Precision', ax=ax, color=COLORS['TAHOE'], 
            label=f'TAHOE (n={len(tahoe_df)})', linewidth=3, fill=True, alpha=0.3)

ax.set_xlabel('Precision (%)', fontsize=14, fontweight='bold')
ax.set_ylabel('Density', fontsize=14, fontweight='bold')
ax.set_title('Figure 2C: Precision Distribution Density\n(Disease-Level Analysis)', fontsize=16, fontweight='bold')
ax.legend(fontsize=12, frameon=True, fancybox=True, shadow=True)
ax.set_xlim(0, max(cmap_df['Precision'].max(), tahoe_df['Precision'].max()) + 5)
ax.tick_params(axis='both', labelsize=12)

# Add vertical lines for means
ax.axvline(cmap_prec_mean, color=COLORS['CMAP'], linestyle='--', linewidth=2, alpha=0.8)
ax.axvline(tahoe_prec_mean, color=COLORS['TAHOE'], linestyle='--', linewidth=2, alpha=0.8)

# Add statistics text box
stats_text = f'CMAP: Mean={cmap_prec_mean:.1f}%, Median={cmap_df["Precision"].median():.1f}%\n'
stats_text += f'TAHOE: Mean={tahoe_prec_mean:.1f}%, Median={tahoe_df["Precision"].median():.1f}%'
ax.text(0.98, 0.95, stats_text, transform=ax.transAxes, fontsize=11,
        verticalalignment='top', horizontalalignment='right',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='white', alpha=0.9, edgecolor='gray'))

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2C_Precision_Density.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2C_Precision_Density.png")

# ============================================================================
# Figure 2D: Recall Violin Plot by Platform
# ============================================================================
print("\nGenerating Figure 2D: Recall Violin Plot...")

fig, ax = plt.subplots(figsize=(10, 8))

colors_list = [COLORS['CMAP'], COLORS['TAHOE']]

# Create violin plot
violin_parts = ax.violinplot([cmap_df['Recall'], tahoe_df['Recall']], 
                              positions=[1, 2], showmeans=True, showmedians=True)

# Color the violins
for i, pc in enumerate(violin_parts['bodies']):
    pc.set_facecolor(colors_list[i])
    pc.set_alpha(0.7)

# Style the lines
for partname in ['cmeans', 'cmedians', 'cbars', 'cmins', 'cmaxes']:
    if partname in violin_parts:
        violin_parts[partname].set_edgecolor('black')
        violin_parts[partname].set_linewidth(1.5)

# Add box plot inside
bp = ax.boxplot([cmap_df['Recall'], tahoe_df['Recall']], positions=[1, 2], 
                widths=0.15, patch_artist=True, showfliers=True)
for i, patch in enumerate(bp['boxes']):
    patch.set_facecolor('white')
    patch.set_alpha(0.8)

ax.set_xticks([1, 2])
ax.set_xticklabels([f'CMAP\n(n={len(cmap_df)})', f'TAHOE\n(n={len(tahoe_df)})'], fontsize=13, fontweight='bold')
ax.set_ylabel('Recall (%)', fontsize=14, fontweight='bold')
ax.set_title('Figure 2D: Recall Distribution by Platform\n(Violin Plot - Disease-Level)', fontsize=16, fontweight='bold')
ax.tick_params(axis='both', labelsize=12)
ax.set_ylim(0, 105)

# Add mean/median annotations
ax.annotate(f'Mean: {cmap_mean:.1f}%', xy=(1, cmap_mean), xytext=(0.6, cmap_mean + 8),
            fontsize=10, ha='center', color=COLORS['CMAP'], fontweight='bold')
ax.annotate(f'Mean: {tahoe_mean:.1f}%', xy=(2, tahoe_mean), xytext=(2.4, tahoe_mean + 8),
            fontsize=10, ha='center', color=COLORS['TAHOE'], fontweight='bold')

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2D_Recall_Violin.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2D_Recall_Violin.png")

# ============================================================================
# Figure 2E: Precision Violin Plot by Platform
# ============================================================================
print("\nGenerating Figure 2E: Precision Violin Plot...")

fig, ax = plt.subplots(figsize=(10, 8))

# Create violin plot
violin_parts = ax.violinplot([cmap_df['Precision'], tahoe_df['Precision']], 
                              positions=[1, 2], showmeans=True, showmedians=True)

# Color the violins
for i, pc in enumerate(violin_parts['bodies']):
    pc.set_facecolor(colors_list[i])
    pc.set_alpha(0.7)

# Style the lines
for partname in ['cmeans', 'cmedians', 'cbars', 'cmins', 'cmaxes']:
    if partname in violin_parts:
        violin_parts[partname].set_edgecolor('black')
        violin_parts[partname].set_linewidth(1.5)

# Add box plot inside
bp = ax.boxplot([cmap_df['Precision'], tahoe_df['Precision']], positions=[1, 2], 
                widths=0.15, patch_artist=True, showfliers=True)
for i, patch in enumerate(bp['boxes']):
    patch.set_facecolor('white')
    patch.set_alpha(0.8)

ax.set_xticks([1, 2])
ax.set_xticklabels([f'CMAP\n(n={len(cmap_df)})', f'TAHOE\n(n={len(tahoe_df)})'], fontsize=13, fontweight='bold')
ax.set_ylabel('Precision (%)', fontsize=14, fontweight='bold')
ax.set_title('Figure 2E: Precision Distribution by Platform\n(Violin Plot - Disease-Level)', fontsize=16, fontweight='bold')
ax.tick_params(axis='both', labelsize=12)

# Add mean annotations
ax.annotate(f'Mean: {cmap_prec_mean:.1f}%', xy=(1, cmap_prec_mean), xytext=(0.6, cmap_prec_mean + 5),
            fontsize=10, ha='center', color=COLORS['CMAP'], fontweight='bold')
ax.annotate(f'Mean: {tahoe_prec_mean:.1f}%', xy=(2, tahoe_prec_mean), xytext=(2.4, tahoe_prec_mean + 5),
            fontsize=10, ha='center', color=COLORS['TAHOE'], fontweight='bold')

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2E_Precision_Violin.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2E_Precision_Violin.png")

# ============================================================================
# Figure 2F: Heatmap of Top 20 Diseases - Recall AND Precision for both platforms
# ============================================================================
print("\nGenerating Figure 2F: Heatmap of Top 20 Diseases (Recall & Precision)...")

# Get top diseases by recall for each platform
top_n = 20

# For CMAP - top by recall
cmap_top = cmap_df.nlargest(top_n, 'Recall')[['Disease', 'Recall', 'Precision']].copy()

# For TAHOE - top by recall
tahoe_top = tahoe_df.nlargest(top_n, 'Recall')[['Disease', 'Recall', 'Precision']].copy()

# Create pivot table for heatmap - combine unique diseases from both platforms
all_top_diseases = list(set(cmap_top['Disease'].tolist() + tahoe_top['Disease'].tolist()))

# Create comparison dataframe
comparison_data = []
for disease in all_top_diseases:
    cmap_row = cmap_df[cmap_df['Disease'] == disease]
    tahoe_row = tahoe_df[tahoe_df['Disease'] == disease]
    
    cmap_recall = cmap_row['Recall'].values[0] if len(cmap_row) > 0 else np.nan
    tahoe_recall = tahoe_row['Recall'].values[0] if len(tahoe_row) > 0 else np.nan
    cmap_prec = cmap_row['Precision'].values[0] if len(cmap_row) > 0 else np.nan
    tahoe_prec = tahoe_row['Precision'].values[0] if len(tahoe_row) > 0 else np.nan
    
    comparison_data.append({
        'Disease': disease,
        'CMAP_Recall': cmap_recall,
        'TAHOE_Recall': tahoe_recall,
        'CMAP_Precision': cmap_prec,
        'TAHOE_Precision': tahoe_prec
    })

comparison_df = pd.DataFrame(comparison_data)

# Sort by max recall across platforms
comparison_df['Max_Recall'] = comparison_df[['CMAP_Recall', 'TAHOE_Recall']].max(axis=1)
comparison_df = comparison_df.nlargest(top_n, 'Max_Recall')

# Prepare heatmap data with 4 columns: CMAP Recall, TAHOE Recall, CMAP Precision, TAHOE Precision
heatmap_data = comparison_df[['Disease', 'CMAP_Recall', 'TAHOE_Recall', 'CMAP_Precision', 'TAHOE_Precision']].set_index('Disease')
heatmap_data.columns = ['CMAP\nRecall', 'TAHOE\nRecall', 'CMAP\nPrecision', 'TAHOE\nPrecision']

# Sort by TAHOE recall (since TAHOE generally performs better)
heatmap_data = heatmap_data.sort_values('TAHOE\nRecall', ascending=True)

# Create figure with appropriate size for disease names and 4 columns
fig, ax = plt.subplots(figsize=(12, 14))

# Create heatmap with custom colormap
sns.heatmap(heatmap_data, annot=True, fmt='.1f', cmap='YlOrRd', 
            ax=ax, cbar_kws={'label': 'Value (%)'}, linewidths=0.8,
            annot_kws={'size': 9, 'fontweight': 'bold'},
            vmin=0, vmax=100)

ax.set_xlabel('Metric by Platform', fontsize=14, fontweight='bold')
ax.set_ylabel('Disease', fontsize=14, fontweight='bold')
ax.set_title('Figure 2F: Top 20 Diseases - Recall & Precision\n(CMAP vs TAHOE)', fontsize=16, fontweight='bold')

# Rotate y-axis labels for readability
ax.set_yticklabels(ax.get_yticklabels(), rotation=0, fontsize=10)
ax.set_xticklabels(ax.get_xticklabels(), fontsize=11, fontweight='bold', rotation=0)

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2F_Top20_Diseases_Heatmap.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2F_Top20_Diseases_Heatmap.png")

# ============================================================================
# Figure 2G: Combined Precision-Recall Scatter Plot
# ============================================================================
print("\nGenerating Figure 2G: Precision vs Recall Scatter Plot...")

fig, ax = plt.subplots(figsize=(12, 10))

# Scatter plot for both platforms
ax.scatter(cmap_df['Precision'], cmap_df['Recall'], alpha=0.6, s=80, 
           c=COLORS['CMAP'], label=f'CMAP (n={len(cmap_df)})', edgecolors='white', linewidth=0.5)
ax.scatter(tahoe_df['Precision'], tahoe_df['Recall'], alpha=0.6, s=80, 
           c=COLORS['TAHOE'], label=f'TAHOE (n={len(tahoe_df)})', edgecolors='white', linewidth=0.5)

ax.set_xlabel('Precision (%)', fontsize=14, fontweight='bold')
ax.set_ylabel('Recall (%)', fontsize=14, fontweight='bold')
ax.set_title('Figure 2G: Precision vs Recall by Disease\n(Each point = one disease)', fontsize=16, fontweight='bold')
ax.legend(fontsize=12, frameon=True, fancybox=True, shadow=True, loc='upper right')
ax.tick_params(axis='both', labelsize=12)

# Add reference lines
ax.axhline(y=50, color='gray', linestyle=':', alpha=0.5, linewidth=1)
ax.axvline(x=50, color='gray', linestyle=':', alpha=0.5, linewidth=1)

# Add diagonal reference line (Precision = Recall)
max_val = max(ax.get_xlim()[1], ax.get_ylim()[1])
ax.plot([0, max_val], [0, max_val], 'k--', alpha=0.3, linewidth=1, label='P = R')

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_2G_Precision_Recall_Scatter.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_2G_Precision_Recall_Scatter.png")

# ============================================================================
# Summary Statistics
# ============================================================================
print("\n" + "="*60)
print("SUMMARY STATISTICS (Disease-Level)")
print("="*60)

print(f"\nCMAP Platform ({len(cmap_df)} diseases):")
print(f"  Recall:    Mean = {cmap_df['Recall'].mean():.2f}%, Median = {cmap_df['Recall'].median():.2f}%, Std = {cmap_df['Recall'].std():.2f}%")
print(f"  Precision: Mean = {cmap_df['Precision'].mean():.2f}%, Median = {cmap_df['Precision'].median():.2f}%, Std = {cmap_df['Precision'].std():.2f}%")
print(f"  Diseases with >0% recall: {(cmap_df['Recall'] > 0).sum()} ({(cmap_df['Recall'] > 0).sum()/len(cmap_df)*100:.1f}%)")

print(f"\nTAHOE Platform ({len(tahoe_df)} diseases):")
print(f"  Recall:    Mean = {tahoe_df['Recall'].mean():.2f}%, Median = {tahoe_df['Recall'].median():.2f}%, Std = {tahoe_df['Recall'].std():.2f}%")
print(f"  Precision: Mean = {tahoe_df['Precision'].mean():.2f}%, Median = {tahoe_df['Precision'].median():.2f}%, Std = {tahoe_df['Precision'].std():.2f}%")
print(f"  Diseases with >0% recall: {(tahoe_df['Recall'] > 0).sum()} ({(tahoe_df['Recall'] > 0).sum()/len(tahoe_df)*100:.1f}%)")

# Statistical comparison
recall_stat, recall_pval = mannwhitneyu(cmap_df['Recall'], tahoe_df['Recall'], alternative='two-sided')
prec_stat, prec_pval = mannwhitneyu(cmap_df['Precision'], tahoe_df['Precision'], alternative='two-sided')

print(f"\nStatistical Comparison (Mann-Whitney U test):")
print(f"  Recall: U = {recall_stat:.1f}, p = {recall_pval:.2e}")
print(f"  Precision: U = {prec_stat:.1f}, p = {prec_pval:.2e}")

print("\n" + "="*60)
print("All Part 2 figures generated successfully!")
print(f"Output directory: {OUTPUT_DIR}")
print("="*60)
