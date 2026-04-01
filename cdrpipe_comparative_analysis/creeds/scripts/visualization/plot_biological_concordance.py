#!/usr/bin/env python3
"""
Generate Biological Concordance Figures
  - Butterfly chart: drug target class distribution (Recovered vs All)
  - Lollipop chart: distribution shift
  - Concordance heatmap + scatter
  - Comparative heatmap: recovered (side-by-side CMAP vs Tahoe, row-normalised)
  - Comparative heatmap: all discoveries (side-by-side CMAP vs Tahoe, row-normalised)
  - Stacked bar: CMAP drug target distribution by disease area
  - Stacked bar: TAHOE drug target distribution by disease area

Outputs (to creeds/figures/biological_concordance/):
  - butterfly_drug_classes.png
  - drug_class_distribution_shift_lollipop.png
  - drug_class_concordance_heatmap.png
  - comparative_heatmap_recovered.png
  - comparative_heatmap_all_discoveries.png
  - difference_heatmap_recovered.png
  - difference_heatmap_all_discoveries.png
  - stacked_bar_drug_targets_cmap.png
  - stacked_bar_drug_targets_tahoe.png

Data sources (relative to comparative-analysis root):
  - creeds/results/biological_concordance/all_discoveries_cmap.csv
  - creeds/results/biological_concordance/all_discoveries_tahoe.csv
  - creeds/results/biological_concordance/open_target_cmap_recovered.csv
  - creeds/results/biological_concordance/open_target_tahoe_recovered.csv
"""

import os
from pathlib import Path

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.patches import Patch
from matplotlib.colors import LinearSegmentedColormap
from scipy.spatial.distance import cosine
from scipy.stats import pearsonr

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[3]
DATA_PATH = REPO_ROOT / "creeds" / "results" / "biological_concordance"
OUTPUT_DIR = REPO_ROOT / "creeds" / "figures" / "biological_concordance"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

if not DATA_PATH.exists():
    raise FileNotFoundError(f"Missing figure input directory: {DATA_PATH}")

# Color scheme
CMAP_COLOR = '#F39C12'
TAHOE_COLOR = '#5DADE2'

plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
print("Loading data...")
cmap_all = pd.read_csv(DATA_PATH / "all_discoveries_cmap.csv")
cmap_recovered = pd.read_csv(DATA_PATH / "open_target_cmap_recovered.csv")
tahoe_all = pd.read_csv(DATA_PATH / "all_discoveries_tahoe.csv")
tahoe_recovered = pd.read_csv(DATA_PATH / "open_target_tahoe_recovered.csv")
print(f"  CMAP: {len(cmap_all)} all, {len(cmap_recovered)} recovered")
print(f"  TAHOE: {len(tahoe_all)} all, {len(tahoe_recovered)} recovered")

TARGET_CLASSES = [
    'Enzyme', 'Membrane receptor', 'Transcription factor', 'Ion channel',
    'Transporter', 'Epigenetic regulator', 'Unclassified protein',
    'Other cytosolic protein', 'Structural protein', 'Other nuclear protein',
]


def get_class_percentages(df):
    all_classes = df['drug_target_class'].str.split('|').explode()
    counts = all_classes.value_counts()
    total = counts.sum()
    return {cls: counts.get(cls, 0) / total * 100 for cls in TARGET_CLASSES}


cmap_all_pct = get_class_percentages(cmap_all)
cmap_rec_pct = get_class_percentages(cmap_recovered)
tahoe_all_pct = get_class_percentages(tahoe_all)
tahoe_rec_pct = get_class_percentages(tahoe_recovered)

# ---------------------------------------------------------------------------
# Butterfly Chart
# ---------------------------------------------------------------------------
print("\nButterfly Chart")
fig, axes = plt.subplots(1, 2, figsize=(16, 10), sharey=True)
y_pos = np.arange(len(TARGET_CLASSES))
width = 0.4

for ax, color, all_pct, rec_pct, label in [
    (axes[0], CMAP_COLOR, cmap_all_pct, cmap_rec_pct, 'CMAP'),
    (axes[1], TAHOE_COLOR, tahoe_all_pct, tahoe_rec_pct, 'TAHOE'),
]:
    all_vals = [-all_pct[c] for c in TARGET_CLASSES]
    rec_vals = [rec_pct[c] for c in TARGET_CLASSES]
    ax.barh(y_pos - width / 2, all_vals, width, label='All Discoveries', color=color, alpha=0.5, edgecolor='white')
    ax.barh(y_pos + width / 2, rec_vals, width, label='Recovered', color=color, alpha=1.0, edgecolor='white')
    ax.set_xlabel('Percentage (%)', fontsize=12, fontweight='bold')
    ax.set_title(label, fontsize=14, fontweight='bold', color=color)
    ax.axvline(0, color='black', linewidth=1)
    ax.set_xlim(-50, 50)
    ax.set_xticks([-40, -20, 0, 20, 40])
    ax.set_xticklabels(['40', '20', '0', '20', '40'])
    ax.legend(loc='lower left' if label == 'CMAP' else 'lower right', fontsize=10)
    for i, cls in enumerate(TARGET_CLASSES):
        diff = rec_pct[cls] - all_pct[cls]
        if abs(diff) > 3:
            ax.annotate(f'{diff:+.1f}%', xy=(rec_vals[i] + 2, i + width / 2),
                        fontsize=8, color='darkred' if diff > 0 else 'darkblue', fontweight='bold')

axes[0].set_yticks(y_pos)
axes[0].set_yticklabels(TARGET_CLASSES, fontsize=11)
fig.suptitle('Drug Target Class Distribution – Recovered vs All Discoveries', fontsize=16, fontweight='bold', y=1.02)
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'butterfly_drug_classes.png', dpi=300, bbox_inches='tight')
plt.close(fig)
print("  Saved butterfly_drug_classes.png")

# ---------------------------------------------------------------------------
# Lollipop Shift Chart
# ---------------------------------------------------------------------------
print("Lollipop Shift")
fig, ax = plt.subplots(figsize=(14, 8))
cmap_shifts = [cmap_rec_pct[c] - cmap_all_pct[c] for c in TARGET_CLASSES]
tahoe_shifts = [tahoe_rec_pct[c] - tahoe_all_pct[c] for c in TARGET_CLASSES]
y_pos = np.arange(len(TARGET_CLASSES))
height = 0.35

for i in range(len(TARGET_CLASSES)):
    ax.hlines(y=i - height / 2, xmin=0, xmax=cmap_shifts[i], color=CMAP_COLOR, linewidth=2, alpha=0.8)
    ax.scatter(cmap_shifts[i], i - height / 2, color=CMAP_COLOR, s=150, zorder=5, edgecolor='white', linewidth=2)
    ax.hlines(y=i + height / 2, xmin=0, xmax=tahoe_shifts[i], color=TAHOE_COLOR, linewidth=2, alpha=0.8)
    ax.scatter(tahoe_shifts[i], i + height / 2, color=TAHOE_COLOR, s=150, zorder=5, edgecolor='white', linewidth=2)

ax.axvline(0, color='black', linewidth=1.5)
ax.set_yticks(y_pos)
ax.set_yticklabels(TARGET_CLASSES, fontsize=11)
ax.set_xlabel('Percentage Point Shift (Recovered − All Discoveries)', fontsize=13, fontweight='bold')
ax.set_title('Distribution Shift Between Recovered and All Discoveries', fontsize=16, fontweight='bold')
ax.legend(handles=[Patch(facecolor=CMAP_COLOR, label='CMAP'), Patch(facecolor=TAHOE_COLOR, label='TAHOE')],
          loc='upper right', fontsize=12)
ax.axvspan(-2, 2, alpha=0.1, color='green')
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'drug_class_distribution_shift_lollipop.png', dpi=300, bbox_inches='tight')
plt.close(fig)
print("  Saved drug_class_distribution_shift_lollipop.png")

# ---------------------------------------------------------------------------
# Concordance Heatmap
# ---------------------------------------------------------------------------
print("Concordance Heatmap")
data_matrix = np.array([
    [cmap_all_pct[c], cmap_rec_pct[c], tahoe_all_pct[c], tahoe_rec_pct[c]]
    for c in TARGET_CLASSES
])

fig, ax = plt.subplots(figsize=(12, 10))
im = ax.imshow(data_matrix, cmap='YlOrRd', aspect='auto', vmin=0, vmax=50)
cbar = plt.colorbar(im, ax=ax, shrink=0.8)
cbar.set_label('Percentage (%)', fontsize=12, fontweight='bold')
ax.set_xticks([0, 1, 2, 3])
ax.set_xticklabels(['CMAP\nAll', 'CMAP\nRecovered', 'TAHOE\nAll', 'TAHOE\nRecovered'], fontsize=11, fontweight='bold')
ax.set_yticks(range(len(TARGET_CLASSES)))
ax.set_yticklabels(TARGET_CLASSES, fontsize=11)
for i in range(len(TARGET_CLASSES)):
    for j in range(4):
        color = 'white' if data_matrix[i, j] > 25 else 'black'
        ax.text(j, i, f'{data_matrix[i, j]:.1f}%', ha='center', va='center', fontsize=10, fontweight='bold', color=color)
ax.axvline(1.5, color='black', linewidth=3)
ax.text(0.5, -1.2, 'CMAP', ha='center', fontsize=14, fontweight='bold', color=CMAP_COLOR)
ax.text(2.5, -1.2, 'TAHOE', ha='center', fontsize=14, fontweight='bold', color=TAHOE_COLOR)
ax.set_title('Drug Target Class Distribution Comparison\n(All Discoveries vs Recovered)', fontsize=16, fontweight='bold', y=1.08)
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'drug_class_concordance_heatmap.png', dpi=300, bbox_inches='tight')
plt.close(fig)
print("  Saved drug_class_concordance_heatmap.png")

# ---------------------------------------------------------------------------
# Cross-tabulation helpers (disease area × drug target class)
# ---------------------------------------------------------------------------

THERAPEUTIC_AREAS = [
    'Cancer/Tumor', 'Genetic/Congenital', 'Immune System', 'Nervous System',
    'Gastrointestinal', 'Musculoskeletal', 'Respiratory', 'Hematologic',
    'Endocrine System', 'Skin/Integumentary', 'Cardiovascular',
    'Infectious Disease', 'Metabolic', 'Reproductive/Breast', 'Urinary System',
    'Psychiatric', 'Visual System', 'Pancreas', 'Pregnancy/Perinatal',
    'Phenotype', 'Other',
]

DRUG_TARGET_CLASSES = [
    'Enzyme', 'Membrane receptor', 'Transcription factor', 'Ion channel',
    'Transporter', 'Epigenetic regulator', 'Unclassified protein',
    'Other cytosolic protein', 'Secreted protein', 'Structural protein',
    'Other nuclear protein', 'Auxiliary transport protein', 'Other',
]

TOP_THERAPEUTIC_AREAS = 12
TOP_DRUG_CLASSES = 10


def expand_and_standardize(df, ta_col='disease_therapeutic_areas', tc_col='drug_target_class'):
    """Expand pipe-separated multi-membership values into individual rows."""
    rows = []
    for _, row in df.iterrows():
        tas = [t.strip() for t in str(row[ta_col]).split('|')] if pd.notna(row[ta_col]) and str(row[ta_col]).strip() else ['Other']
        tcs = [t.strip() for t in str(row[tc_col]).split('|')] if pd.notna(row[tc_col]) and str(row[tc_col]).strip() else ['Other']
        tas = [t if t in THERAPEUTIC_AREAS else 'Other' for t in tas]
        tcs = [t if t in DRUG_TARGET_CLASSES else 'Other' for t in tcs]
        for ta in dict.fromkeys(tas):
            for tc in dict.fromkeys(tcs):
                rows.append({'therapeutic_area': ta, 'drug_target_class_expanded': tc})
    return pd.DataFrame(rows)


# Expand all four datasets
print("\nExpanding and standardising categories...")
cmap_rec_exp = expand_and_standardize(cmap_recovered)
tahoe_rec_exp = expand_and_standardize(tahoe_recovered)
cmap_all_exp = expand_and_standardize(cmap_all)
tahoe_all_exp = expand_and_standardize(tahoe_all)

# Determine top categories from combined data (consistent across all charts)
all_data = pd.concat([cmap_rec_exp, tahoe_rec_exp, cmap_all_exp, tahoe_all_exp], ignore_index=True)
ta_counts = all_data['therapeutic_area'].value_counts()
tc_counts = all_data['drug_target_class_expanded'].value_counts()

SELECTED_TA = [ta for ta in THERAPEUTIC_AREAS if ta in ta_counts.index and ta != 'Other'][:TOP_THERAPEUTIC_AREAS]
SELECTED_TC = [tc for tc in DRUG_TARGET_CLASSES if tc in tc_counts.index and tc != 'Other'][:TOP_DRUG_CLASSES]


def consistent_crosstab(expanded_df):
    ct = pd.crosstab(expanded_df['therapeutic_area'], expanded_df['drug_target_class_expanded'])
    return ct.reindex(index=SELECTED_TA, columns=SELECTED_TC, fill_value=0)


ct_cmap_rec = consistent_crosstab(cmap_rec_exp)
ct_tahoe_rec = consistent_crosstab(tahoe_rec_exp)
ct_cmap_all = consistent_crosstab(cmap_all_exp)
ct_tahoe_all = consistent_crosstab(tahoe_all_exp)

# Custom colormaps
TAHOE_CMAP = LinearSegmentedColormap.from_list('tahoe_cmap', ['white', '#AED6F1', TAHOE_COLOR, '#1B4F72'])
CMAP_CMAP = LinearSegmentedColormap.from_list('cmap_cmap', ['white', '#FAD7A0', CMAP_COLOR, '#935116'])

# ---------------------------------------------------------------------------
# Comparative Heatmap – Recovered
# ---------------------------------------------------------------------------
print("\nComparative Heatmap (Recovered)")

ct_cmap_norm = ct_cmap_rec.div(ct_cmap_rec.sum(axis=1), axis=0).mul(100).fillna(0)
ct_tahoe_norm = ct_tahoe_rec.div(ct_tahoe_rec.sum(axis=1), axis=0).mul(100).fillna(0)
vmax_rec = max(ct_cmap_norm.values.max(), ct_tahoe_norm.values.max())

fig, axes = plt.subplots(1, 2, figsize=(24, 10))
sns.heatmap(ct_cmap_norm, annot=True, fmt='.1f', cmap=CMAP_CMAP, ax=axes[0],
            cbar_kws={'label': '% within Disease Area'}, vmax=vmax_rec,
            linewidths=0.5, linecolor='white')
axes[0].set_title('CMAP Recovered\n(% distribution)', fontsize=12, fontweight='bold')
axes[0].set_xlabel('Drug Target Class', fontsize=10)
axes[0].set_ylabel('Disease Therapeutic Area', fontsize=10)
axes[0].tick_params(axis='x', rotation=45)

sns.heatmap(ct_tahoe_norm, annot=True, fmt='.1f', cmap=TAHOE_CMAP, ax=axes[1],
            cbar_kws={'label': '% within Disease Area'}, vmax=vmax_rec,
            linewidths=0.5, linecolor='white')
axes[1].set_title('Tahoe Recovered\n(% distribution)', fontsize=12, fontweight='bold')
axes[1].set_xlabel('Drug Target Class', fontsize=10)
axes[1].set_ylabel('')
axes[1].tick_params(axis='x', rotation=45)

plt.tight_layout()
out_rec = OUTPUT_DIR / 'comparative_heatmap_recovered.png'
fig.savefig(out_rec, dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig)
print("  Saved comparative_heatmap_recovered.png")

# ---------------------------------------------------------------------------
# Comparative Heatmap – All Discoveries
# ---------------------------------------------------------------------------
print("Comparative Heatmap (All Discoveries)")

ct_cmap_norm_all = ct_cmap_all.div(ct_cmap_all.sum(axis=1), axis=0).mul(100).fillna(0)
ct_tahoe_norm_all = ct_tahoe_all.div(ct_tahoe_all.sum(axis=1), axis=0).mul(100).fillna(0)
vmax_all = max(ct_cmap_norm_all.values.max(), ct_tahoe_norm_all.values.max())

fig, axes = plt.subplots(1, 2, figsize=(24, 10))
sns.heatmap(ct_cmap_norm_all, annot=True, fmt='.1f', cmap=CMAP_CMAP, ax=axes[0],
            cbar_kws={'label': '% within Disease Area'}, vmax=vmax_all,
            linewidths=0.5, linecolor='white')
axes[0].set_title('CMAP All Discoveries\n(% distribution)', fontsize=12, fontweight='bold')
axes[0].set_xlabel('Drug Target Class', fontsize=10)
axes[0].set_ylabel('Disease Therapeutic Area', fontsize=10)
axes[0].tick_params(axis='x', rotation=45)

sns.heatmap(ct_tahoe_norm_all, annot=True, fmt='.1f', cmap=TAHOE_CMAP, ax=axes[1],
            cbar_kws={'label': '% within Disease Area'}, vmax=vmax_all,
            linewidths=0.5, linecolor='white')
axes[1].set_title('Tahoe All Discoveries\n(% distribution)', fontsize=12, fontweight='bold')
axes[1].set_xlabel('Drug Target Class', fontsize=10)
axes[1].set_ylabel('')
axes[1].tick_params(axis='x', rotation=45)

plt.tight_layout()
out_all = OUTPUT_DIR / 'comparative_heatmap_all_discoveries.png'
fig.savefig(out_all, dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig)
print("  Saved comparative_heatmap_all_discoveries.png")

# ---------------------------------------------------------------------------
# Difference Heatmap – Recovered (Tahoe − CMAP)
# ---------------------------------------------------------------------------
print("Difference Heatmap (Recovered)")

ct_cmap_norm = ct_cmap_rec.div(ct_cmap_rec.sum(axis=1), axis=0).mul(100).fillna(0)
ct_tahoe_norm = ct_tahoe_rec.div(ct_tahoe_rec.sum(axis=1), axis=0).mul(100).fillna(0)
diff_rec = ct_tahoe_norm - ct_cmap_norm

fig, ax = plt.subplots(figsize=(14, 10))
vabs = max(abs(diff_rec.values.min()), abs(diff_rec.values.max()))
sns.heatmap(diff_rec, annot=True, fmt='.1f', cmap='RdBu', ax=ax,
            center=0, vmin=-vabs, vmax=vabs,
            cbar_kws={'label': 'Tahoe - CMAP (% points)'},
            linewidths=0.5, linecolor='white')
ax.set_title('Differential Pattern: Tahoe vs CMAP Recovered\n(Blue = Tahoe higher, Red = CMAP higher)',
             fontsize=12, fontweight='bold')
ax.set_xlabel('Drug Target Class', fontsize=10)
ax.set_ylabel('Disease Therapeutic Area', fontsize=10)
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'difference_heatmap_recovered.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig)
print("  Saved difference_heatmap_recovered.png")

# ---------------------------------------------------------------------------
# Difference Heatmap – All Discoveries (Tahoe − CMAP)
# ---------------------------------------------------------------------------
print("Difference Heatmap (All Discoveries)")

ct_cmap_norm_all = ct_cmap_all.div(ct_cmap_all.sum(axis=1), axis=0).mul(100).fillna(0)
ct_tahoe_norm_all = ct_tahoe_all.div(ct_tahoe_all.sum(axis=1), axis=0).mul(100).fillna(0)
diff_all = ct_tahoe_norm_all - ct_cmap_norm_all

fig, ax = plt.subplots(figsize=(14, 10))
vabs = max(abs(diff_all.values.min()), abs(diff_all.values.max()))
sns.heatmap(diff_all, annot=True, fmt='.1f', cmap='RdBu', ax=ax,
            center=0, vmin=-vabs, vmax=vabs,
            cbar_kws={'label': 'Tahoe - CMAP (% points)'},
            linewidths=0.5, linecolor='white')
ax.set_title('Differential Pattern: Tahoe vs CMAP All Discoveries\n(Blue = Tahoe higher, Red = CMAP higher)',
             fontsize=12, fontweight='bold')
ax.set_xlabel('Drug Target Class', fontsize=10)
ax.set_ylabel('Disease Therapeutic Area', fontsize=10)
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'difference_heatmap_all_discoveries.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig)
print("  Saved difference_heatmap_all_discoveries.png")

# ---------------------------------------------------------------------------
# Stacked Bar – CMAP (Recovered)
# ---------------------------------------------------------------------------
print("Stacked Bar (CMAP)")
fig, ax = plt.subplots(figsize=(14, 10))
ct_norm = ct_cmap_rec.div(ct_cmap_rec.sum(axis=1), axis=0).mul(100).fillna(0)
colors = plt.colormaps['Oranges'](np.linspace(0.2, 0.9, len(ct_norm.columns)))
ct_norm.plot(kind='barh', stacked=True, ax=ax, color=colors, width=0.8)
ax.set_xlabel('Percentage (%)', fontsize=11)
ax.set_ylabel('Disease Therapeutic Area', fontsize=11)
ax.set_title('CMAP Recovered: Drug Target Distribution by Disease', fontsize=14, fontweight='bold')
ax.legend(title='Drug Target Class', bbox_to_anchor=(1.02, 1), loc='upper left', fontsize=8)
ax.set_xlim(0, 100)
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'stacked_bar_drug_targets_cmap.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig)
print("  Saved stacked_bar_drug_targets_cmap.png")

# ---------------------------------------------------------------------------
# Stacked Bar – TAHOE (Recovered)
# ---------------------------------------------------------------------------
print("Stacked Bar (TAHOE)")
fig, ax = plt.subplots(figsize=(14, 10))
ct_norm = ct_tahoe_rec.div(ct_tahoe_rec.sum(axis=1), axis=0).mul(100).fillna(0)
colors = plt.colormaps['Blues'](np.linspace(0.2, 0.9, len(ct_norm.columns)))
ct_norm.plot(kind='barh', stacked=True, ax=ax, color=colors, width=0.8)
ax.set_xlabel('Percentage (%)', fontsize=11)
ax.set_ylabel('Disease Therapeutic Area', fontsize=11)
ax.set_title('Tahoe Recovered: Drug Target Distribution by Disease', fontsize=14, fontweight='bold')
ax.legend(title='Drug Target Class', bbox_to_anchor=(1.02, 1), loc='upper left', fontsize=8)
ax.set_xlim(0, 100)
plt.tight_layout()
fig.savefig(OUTPUT_DIR / 'stacked_bar_drug_targets_tahoe.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig)
print("  Saved stacked_bar_drug_targets_tahoe.png")

print("\nAll biological concordance panels generated successfully!")
