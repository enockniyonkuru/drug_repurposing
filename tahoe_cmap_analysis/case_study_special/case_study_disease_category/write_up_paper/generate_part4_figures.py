#!/usr/bin/env python3
"""
Generate Part 4 Figures - Combined Recovered vs All Discoveries Visualizations
Creative visualizations comparing biological concordance between platforms
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.patches import Patch
import os

# Set style
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

# File paths
BASE_PATH = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special/case_study_disease_category"
DATA_PATH = f"{BASE_PATH}/about_drpipe_results"
OUTPUT_DIR = f"{BASE_PATH}/write_up_paper/figures"

# Color scheme - consistent with manuscript
CMAP_COLOR = '#F39C12'  # Warm Orange
TAHOE_COLOR = '#5DADE2'  # Serene Blue
RECOVERED_ALPHA = 1.0
ALL_ALPHA = 0.5

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Load data
print("Loading data...")
cmap_all = pd.read_csv(f"{DATA_PATH}/all_discoveries_cmap.csv")
cmap_recovered = pd.read_csv(f"{DATA_PATH}/open_target_cmap_recovered.csv")
tahoe_all = pd.read_csv(f"{DATA_PATH}/all_discoveries_tahoe.csv")
tahoe_recovered = pd.read_csv(f"{DATA_PATH}/open_target_tahoe_recovered.csv")

print(f"CMAP: {len(cmap_all)} all discoveries, {len(cmap_recovered)} recovered")
print(f"TAHOE: {len(tahoe_all)} all discoveries, {len(tahoe_recovered)} recovered")

# ============================================================================
# Helper function to get distribution
# ============================================================================
def get_distribution(df, column):
    """Get percentage distribution of a column"""
    counts = df[column].str.split('|').explode().value_counts()
    percentages = counts / counts.sum() * 100
    return percentages

def get_top_categories(df, column, n=10):
    """Get top n categories"""
    counts = df[column].str.split('|').explode().value_counts()
    return counts.head(n)

# ============================================================================
# Figure 4C: Butterfly Chart - Drug Target Class Comparison
# ============================================================================
print("\nGenerating Figure 4C: Butterfly Chart - Drug Target Class Comparison...")

# Get drug target class distributions
target_classes = ['Enzyme', 'Membrane receptor', 'Transcription factor', 'Ion channel', 
                  'Transporter', 'Epigenetic regulator', 'Unclassified protein', 
                  'Other cytosolic protein', 'Structural protein', 'Other nuclear protein']

def get_class_percentages(df):
    """Get percentage for each target class"""
    all_classes = df['drug_target_class'].str.split('|').explode()
    counts = all_classes.value_counts()
    total = counts.sum()
    return {cls: counts.get(cls, 0) / total * 100 for cls in target_classes}

cmap_all_pct = get_class_percentages(cmap_all)
cmap_rec_pct = get_class_percentages(cmap_recovered)
tahoe_all_pct = get_class_percentages(tahoe_all)
tahoe_rec_pct = get_class_percentages(tahoe_recovered)

fig, axes = plt.subplots(1, 2, figsize=(16, 10), sharey=True)

# CMAP butterfly
ax1 = axes[0]
y_pos = np.arange(len(target_classes))
width = 0.4

# All discoveries (left side - negative)
all_vals = [-cmap_all_pct[cls] for cls in target_classes]
rec_vals = [cmap_rec_pct[cls] for cls in target_classes]

bars1 = ax1.barh(y_pos - width/2, all_vals, width, label='All Discoveries', 
                  color=CMAP_COLOR, alpha=0.5, edgecolor='white')
bars2 = ax1.barh(y_pos + width/2, rec_vals, width, label='Recovered', 
                  color=CMAP_COLOR, alpha=1.0, edgecolor='white')

ax1.set_yticks(y_pos)
ax1.set_yticklabels(target_classes, fontsize=11)
ax1.set_xlabel('Percentage (%)', fontsize=12, fontweight='bold')
ax1.set_title('CMAP', fontsize=14, fontweight='bold', color=CMAP_COLOR)
ax1.axvline(0, color='black', linewidth=1)
ax1.set_xlim(-50, 50)
ax1.set_xticks([-40, -20, 0, 20, 40])
ax1.set_xticklabels(['40', '20', '0', '20', '40'])
ax1.legend(loc='lower left', fontsize=10)

# Add annotations for significant differences
for i, cls in enumerate(target_classes):
    diff = cmap_rec_pct[cls] - cmap_all_pct[cls]
    if abs(diff) > 3:  # Significant difference threshold
        ax1.annotate(f'{diff:+.1f}%', xy=(rec_vals[i] + 2, i + width/2), 
                    fontsize=8, color='darkred' if diff > 0 else 'darkblue', fontweight='bold')

# TAHOE butterfly
ax2 = axes[1]

all_vals = [-tahoe_all_pct[cls] for cls in target_classes]
rec_vals = [tahoe_rec_pct[cls] for cls in target_classes]

bars3 = ax2.barh(y_pos - width/2, all_vals, width, label='All Discoveries', 
                  color=TAHOE_COLOR, alpha=0.5, edgecolor='white')
bars4 = ax2.barh(y_pos + width/2, rec_vals, width, label='Recovered', 
                  color=TAHOE_COLOR, alpha=1.0, edgecolor='white')

ax2.set_xlabel('Percentage (%)', fontsize=12, fontweight='bold')
ax2.set_title('TAHOE', fontsize=14, fontweight='bold', color=TAHOE_COLOR)
ax2.axvline(0, color='black', linewidth=1)
ax2.set_xlim(-50, 50)
ax2.set_xticks([-40, -20, 0, 20, 40])
ax2.set_xticklabels(['40', '20', '0', '20', '40'])
ax2.legend(loc='lower right', fontsize=10)

# Add annotations for significant differences
for i, cls in enumerate(target_classes):
    diff = tahoe_rec_pct[cls] - tahoe_all_pct[cls]
    if abs(diff) > 3:
        ax2.annotate(f'{diff:+.1f}%', xy=(rec_vals[i] + 2, i + width/2), 
                    fontsize=8, color='darkred' if diff > 0 else 'darkblue', fontweight='bold')

fig.suptitle('Figure 4C: Drug Target Class Distribution - Recovered vs All Discoveries\n(Butterfly Chart)', 
             fontsize=16, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_4C_Butterfly_Drug_Classes.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_4C_Butterfly_Drug_Classes.png")

# ============================================================================
# Figure 4D: Parallel Coordinates Plot - Concordance Visualization
# ============================================================================
print("\nGenerating Figure 4D: Divergence Lollipop Chart...")

fig, ax = plt.subplots(figsize=(14, 8))

# Calculate the shift (recovered - all) for each target class
cmap_shifts = [cmap_rec_pct[cls] - cmap_all_pct[cls] for cls in target_classes]
tahoe_shifts = [tahoe_rec_pct[cls] - tahoe_all_pct[cls] for cls in target_classes]

y_pos = np.arange(len(target_classes))
height = 0.35

# Create lollipop chart
for i, cls in enumerate(target_classes):
    # CMAP lollipop
    ax.hlines(y=i - height/2, xmin=0, xmax=cmap_shifts[i], 
              color=CMAP_COLOR, linewidth=2, alpha=0.8)
    ax.scatter(cmap_shifts[i], i - height/2, color=CMAP_COLOR, s=150, 
               zorder=5, edgecolor='white', linewidth=2)
    
    # TAHOE lollipop
    ax.hlines(y=i + height/2, xmin=0, xmax=tahoe_shifts[i], 
              color=TAHOE_COLOR, linewidth=2, alpha=0.8)
    ax.scatter(tahoe_shifts[i], i + height/2, color=TAHOE_COLOR, s=150, 
               zorder=5, edgecolor='white', linewidth=2)

# Styling
ax.axvline(0, color='black', linewidth=1.5, linestyle='-')
ax.set_yticks(y_pos)
ax.set_yticklabels(target_classes, fontsize=11)
ax.set_xlabel('Percentage Point Shift (Recovered - All Discoveries)', fontsize=13, fontweight='bold')
ax.set_title('Figure 4D: Distribution Shift Between Recovered and All Discoveries\n(Lollipop Chart)', 
             fontsize=16, fontweight='bold')

# Add legend
legend_elements = [
    Patch(facecolor=CMAP_COLOR, label='CMAP'),
    Patch(facecolor=TAHOE_COLOR, label='TAHOE')
]
ax.legend(handles=legend_elements, loc='upper right', fontsize=12)

# Add reference zones
ax.axvspan(-2, 2, alpha=0.1, color='green', label='Minimal shift zone')
ax.text(0, len(target_classes) - 0.5, 'Minimal\nShift', ha='center', fontsize=9, 
        color='green', alpha=0.7, fontweight='bold')

# Add annotations
ax.text(ax.get_xlim()[1] * 0.95, -0.5, 'Enriched in\nRecovered →', ha='right', fontsize=10, 
        color='darkgreen', fontweight='bold')
ax.text(ax.get_xlim()[0] * 0.95, -0.5, '← Depleted in\nRecovered', ha='left', fontsize=10, 
        color='darkred', fontweight='bold')

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_4D_Lollipop_Shift.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_4D_Lollipop_Shift.png")

# ============================================================================
# Figure 4E: Sankey-style Flow Diagram Alternative - Concordance Heatmap
# ============================================================================
print("\nGenerating Figure 4E: Concordance Comparison Heatmap...")

# Create a matrix showing all_discoveries vs recovered percentages for both platforms
# Rows: target classes, Columns: CMAP_All, CMAP_Rec, TAHOE_All, TAHOE_Rec

data_matrix = np.array([
    [cmap_all_pct[cls], cmap_rec_pct[cls], tahoe_all_pct[cls], tahoe_rec_pct[cls]]
    for cls in target_classes
])

fig, ax = plt.subplots(figsize=(12, 10))

# Create annotated heatmap
im = ax.imshow(data_matrix, cmap='YlOrRd', aspect='auto', vmin=0, vmax=50)

# Add colorbar
cbar = plt.colorbar(im, ax=ax, shrink=0.8)
cbar.set_label('Percentage (%)', fontsize=12, fontweight='bold')

# Set ticks
ax.set_xticks([0, 1, 2, 3])
ax.set_xticklabels(['CMAP\nAll', 'CMAP\nRecovered', 'TAHOE\nAll', 'TAHOE\nRecovered'], 
                   fontsize=11, fontweight='bold')
ax.set_yticks(range(len(target_classes)))
ax.set_yticklabels(target_classes, fontsize=11)

# Add text annotations
for i in range(len(target_classes)):
    for j in range(4):
        text_color = 'white' if data_matrix[i, j] > 25 else 'black'
        ax.text(j, i, f'{data_matrix[i, j]:.1f}%', ha='center', va='center', 
                fontsize=10, fontweight='bold', color=text_color)

# Add platform divider
ax.axvline(1.5, color='black', linewidth=3)

# Add platform labels at top
ax.text(0.5, -1.2, 'CMAP', ha='center', fontsize=14, fontweight='bold', color=CMAP_COLOR)
ax.text(2.5, -1.2, 'TAHOE', ha='center', fontsize=14, fontweight='bold', color=TAHOE_COLOR)

ax.set_title('Figure 4E: Drug Target Class Distribution Comparison\n(All Discoveries vs Recovered)', 
             fontsize=16, fontweight='bold', y=1.08)

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_4E_Concordance_Heatmap.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_4E_Concordance_Heatmap.png")

# ============================================================================
# Alternative Figure 4E: Scatter Plot showing Concordance
# ============================================================================
print("\nGenerating Figure 4E Alternative: Concordance Scatter Plot...")

fig, ax = plt.subplots(figsize=(12, 10))

# Plot CMAP: All vs Recovered percentages
cmap_all_vals = [cmap_all_pct[cls] for cls in target_classes]
cmap_rec_vals = [cmap_rec_pct[cls] for cls in target_classes]
tahoe_all_vals = [tahoe_all_pct[cls] for cls in target_classes]
tahoe_rec_vals = [tahoe_rec_pct[cls] for cls in target_classes]

# Scatter with connecting lines
for i, cls in enumerate(target_classes):
    # CMAP point
    ax.scatter(cmap_all_vals[i], cmap_rec_vals[i], s=200, c=CMAP_COLOR, 
               marker='o', edgecolor='white', linewidth=2, zorder=5, alpha=0.8)
    # TAHOE point
    ax.scatter(tahoe_all_vals[i], tahoe_rec_vals[i], s=200, c=TAHOE_COLOR, 
               marker='s', edgecolor='white', linewidth=2, zorder=5, alpha=0.8)
    
    # Label
    offset_x = 1 if cmap_all_vals[i] < 30 else -1
    ax.annotate(cls, xy=(max(cmap_all_vals[i], tahoe_all_vals[i]) + 1, 
                         max(cmap_rec_vals[i], tahoe_rec_vals[i]) + 1),
                fontsize=8, alpha=0.8)

# Add perfect concordance line
max_val = max(max(cmap_all_vals + tahoe_all_vals), max(cmap_rec_vals + tahoe_rec_vals)) + 5
ax.plot([0, max_val], [0, max_val], 'k--', alpha=0.5, linewidth=2, label='Perfect Concordance')

# Add ±5% deviation lines
ax.fill_between([0, max_val], [0, max_val-5], [5, max_val], alpha=0.1, color='green')

ax.set_xlabel('All Discoveries (%)', fontsize=14, fontweight='bold')
ax.set_ylabel('Recovered (%)', fontsize=14, fontweight='bold')
ax.set_title('Figure 4E: Concordance Between All Discoveries and Recovered Predictions\n(Each point = one drug target class)', 
             fontsize=16, fontweight='bold')

# Legend
legend_elements = [
    plt.scatter([], [], s=200, c=CMAP_COLOR, marker='o', label='CMAP', edgecolor='white'),
    plt.scatter([], [], s=200, c=TAHOE_COLOR, marker='s', label='TAHOE', edgecolor='white'),
    plt.Line2D([0], [0], linestyle='--', color='black', alpha=0.5, label='Perfect Concordance')
]
ax.legend(handles=legend_elements, loc='upper left', fontsize=11)

ax.set_xlim(0, max_val)
ax.set_ylim(0, max_val)
ax.set_aspect('equal')

plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/Figure_4E_Concordance_Scatter.png", dpi=300, bbox_inches='tight')
plt.close()
print(f"  Saved: Figure_4E_Concordance_Scatter.png")

# ============================================================================
# Summary Statistics
# ============================================================================
print("\n" + "="*60)
print("CONCORDANCE SUMMARY")
print("="*60)

# Calculate concordance metrics
from scipy.spatial.distance import cosine
from scipy.stats import pearsonr, spearmanr

cmap_all_vec = np.array([cmap_all_pct[cls] for cls in target_classes])
cmap_rec_vec = np.array([cmap_rec_pct[cls] for cls in target_classes])
tahoe_all_vec = np.array([tahoe_all_pct[cls] for cls in target_classes])
tahoe_rec_vec = np.array([tahoe_rec_pct[cls] for cls in target_classes])

print("\nCMAP Concordance:")
print(f"  Cosine Similarity: {1 - cosine(cmap_all_vec, cmap_rec_vec):.3f}")
print(f"  Pearson Correlation: {pearsonr(cmap_all_vec, cmap_rec_vec)[0]:.3f}")
print(f"  Max Shift: {max(abs(cmap_rec_vec - cmap_all_vec)):.1f}%")

print("\nTAHOE Concordance:")
print(f"  Cosine Similarity: {1 - cosine(tahoe_all_vec, tahoe_rec_vec):.3f}")
print(f"  Pearson Correlation: {pearsonr(tahoe_all_vec, tahoe_rec_vec)[0]:.3f}")
print(f"  Max Shift: {max(abs(tahoe_rec_vec - tahoe_all_vec)):.1f}%")

print("\n" + "="*60)
print("All Part 4 figures generated successfully!")
print(f"Output directory: {OUTPUT_DIR}")
print("="*60)
