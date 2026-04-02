#!/usr/bin/env python3
"""
Generate Drug Class Distributions and Disease Therapeutic Areas

Outputs:
  - creeds/figures/drug_class_distributions/cmap_drug_target_classes.png
  - creeds/figures/drug_class_distributions/tahoe_drug_target_classes.png
  - creeds/figures/drug_class_distributions/disease_therapeutic_areas.png

Data sources (relative to comparative-analysis root):
  - creeds/results/drug_class_distributions/open_target_drug_tables/open_target_drugs_in_cmap.csv
  - creeds/results/drug_class_distributions/open_target_drug_tables/open_target_drugs_in_tahoe.csv
  - creeds/results/drug_class_distributions/disease_therapeutic_area_tables/creeds_diseases_with_known_drugs.csv
"""

import os
import sys
from pathlib import Path
from collections import Counter

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# ---------------------------------------------------------------------------
# Paths – everything relative to the repository root
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[3]

DATA_DIR = REPO_ROOT / "creeds" / "results" / "drug_class_distributions"
OUTPUT_DIR = REPO_ROOT / "creeds" / "figures" / "drug_class_distributions"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

if not DATA_DIR.exists():
    raise FileNotFoundError(f"Missing figure input directory: {DATA_DIR}")

# ---------------------------------------------------------------------------
# Style
# ---------------------------------------------------------------------------
plt.style.use('seaborn-v0_8-whitegrid')
plt.rcParams.update({
    'font.family': 'Arial',
    'font.size': 10,
    'axes.labelsize': 12,
    'axes.titlesize': 14,
    'figure.dpi': 300,
})

CLASS_COLORS = {
    'Membrane receptor': '#3498DB',
    'Enzyme': '#E74C3C',
    'Ion channel': '#2ECC71',
    'Transcription factor': '#F39C12',
    'Transporter': '#9B59B6',
    'Unclassified protein': '#1ABC9C',
    'Epigenetic regulator': '#34495E',
    'Structural protein': '#95A5A6',
    'Auxiliary transport protein': '#D35400',
    'Other cytosolic protein': '#C0392B',
    'Other nuclear protein': '#8E44AD',
    'Other': '#95A5A6',
}

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
print("Loading data...")
cmap_drugs = pd.read_csv(DATA_DIR / "open_target_drug_tables" / "open_target_drugs_in_cmap.csv")
tahoe_drugs = pd.read_csv(DATA_DIR / "open_target_drug_tables" / "open_target_drugs_in_tahoe.csv")
diseases = pd.read_csv(DATA_DIR / "disease_therapeutic_area_tables" / "creeds_diseases_with_known_drugs.csv")

print(f"  CMAP drugs: {len(cmap_drugs)}")
print(f"  TAHOE drugs: {len(tahoe_drugs)}")
print(f"  Diseases: {len(diseases)}")


def parse_target_classes(series):
    all_classes = []
    for tc in series.dropna():
        all_classes.extend(c.strip() for c in str(tc).split('|'))
    return Counter(all_classes)


def _make_autopct(values):
    def autopct(pct):
        val = int(round(pct / 100.0 * sum(values)))
        return f'n={val}\n({pct:.1f}%)'
    return autopct


# ---------------------------------------------------------------------------
# CMAP drug target classes
# ---------------------------------------------------------------------------
print("\nCMAP Drug Target Classes")
cmap_classes = parse_target_classes(cmap_drugs['drug_target_class'])

cmap_top = dict(cmap_classes.most_common(7))
cmap_other = sum(v for k, v in cmap_classes.items() if k not in cmap_top)
if cmap_other > 0:
    cmap_top['Other'] = cmap_other

labels_cmap = list(cmap_top.keys())
sizes_cmap = list(cmap_top.values())
colors_cmap = [CLASS_COLORS.get(l, '#95A5A6') for l in labels_cmap]

fig1a, ax1a = plt.subplots(figsize=(10, 10))
wedges, texts, autotexts = ax1a.pie(
    sizes_cmap, labels=None, colors=colors_cmap,
    autopct='%1.1f%%', startangle=90,
    pctdistance=0.78,
    wedgeprops={'linewidth': 2.5, 'edgecolor': 'white', 'width': 0.45},
    textprops={'fontsize': 10, 'fontweight': 'bold'},
)
for at in autotexts:
    at.set(fontsize=9, fontweight='bold', color='white')
# Draw centre circle for donut effect
centre_circle = plt.Circle((0, 0), 0.55, fc='white')
ax1a.add_artist(centre_circle)
ax1a.text(0, 0.04, f'n = {len(cmap_drugs)}', ha='center', va='center',
          fontsize=16, fontweight='bold', color='#333333')
ax1a.text(0, -0.06, 'drugs', ha='center', va='center',
          fontsize=11, color='#666666')
ax1a.legend(wedges, [f'{l}  ({s})' for l, s in zip(labels_cmap, sizes_cmap)],
            title='Target Class', loc='center left', bbox_to_anchor=(1.0, 0.5),
            fontsize=10, title_fontsize=11, frameon=True, fancybox=True,
            shadow=False, edgecolor='#cccccc')
ax1a.set_title('CMAP Drug Target Class Distribution',
               fontsize=15, fontweight='bold', pad=20)
plt.tight_layout()
fig1a.savefig(OUTPUT_DIR / 'cmap_drug_target_classes.png',
              dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
plt.close(fig1a)
print("  Saved cmap_drug_target_classes.png")

# ---------------------------------------------------------------------------
# TAHOE drug target classes
# ---------------------------------------------------------------------------
print("TAHOE Drug Target Classes")
tahoe_classes = parse_target_classes(tahoe_drugs['drug_target_class'])

tahoe_top = dict(tahoe_classes.most_common(7))
tahoe_other = sum(v for k, v in tahoe_classes.items() if k not in tahoe_top)
if tahoe_other > 0:
    tahoe_top['Other'] = tahoe_other

labels_tahoe = list(tahoe_top.keys())
sizes_tahoe = list(tahoe_top.values())
colors_tahoe = [CLASS_COLORS.get(l, '#95A5A6') for l in labels_tahoe]

fig1b, ax1b = plt.subplots(figsize=(10, 10))
wedges, texts, autotexts = ax1b.pie(
    sizes_tahoe, labels=None, colors=colors_tahoe,
    autopct='%1.1f%%', startangle=90,
    pctdistance=0.78,
    wedgeprops={'linewidth': 2.5, 'edgecolor': 'white', 'width': 0.45},
    textprops={'fontsize': 10, 'fontweight': 'bold'},
)
for at in autotexts:
    at.set(fontsize=9, fontweight='bold', color='white')
# Draw centre circle for donut effect
centre_circle = plt.Circle((0, 0), 0.55, fc='white')
ax1b.add_artist(centre_circle)
ax1b.text(0, 0.04, f'n = {len(tahoe_drugs)}', ha='center', va='center',
          fontsize=16, fontweight='bold', color='#333333')
ax1b.text(0, -0.06, 'drugs', ha='center', va='center',
          fontsize=11, color='#666666')
ax1b.legend(wedges, [f'{l}  ({s})' for l, s in zip(labels_tahoe, sizes_tahoe)],
            title='Target Class', loc='center left', bbox_to_anchor=(1.0, 0.5),
            fontsize=10, title_fontsize=11, frameon=True, fancybox=True,
            shadow=False, edgecolor='#cccccc')
ax1b.set_title('TAHOE Drug Target Class Distribution',
               fontsize=15, fontweight='bold', pad=20)
plt.tight_layout()
fig1b.savefig(OUTPUT_DIR / 'tahoe_drug_target_classes.png',
              dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
plt.close(fig1b)
print("  Saved tahoe_drug_target_classes.png")

# ---------------------------------------------------------------------------
# Disease Therapeutic Areas
# ---------------------------------------------------------------------------
print("Disease Therapeutic Areas")
disease_areas = diseases['primary_therapeutic_area'].value_counts()

fig1c, ax1c = plt.subplots(figsize=(12, 7))
areas = disease_areas.index.tolist()
counts = disease_areas.values.tolist()

ax1c.barh(range(len(areas)), counts, color='#3498DB', edgecolor='white', height=0.7)
for i, (area, count) in enumerate(zip(areas, counts)):
    ax1c.text(count + 0.5, i, str(count), va='center', fontsize=10, fontweight='bold')

ax1c.set_yticks(range(len(areas)))
ax1c.set_yticklabels(areas, fontsize=11)
ax1c.set_xlabel('Number of Diseases', fontsize=12, fontweight='bold')
ax1c.set_title(
    f'Distribution of Diseases by Primary Therapeutic Area\n(n = {len(diseases)} diseases with known drug associations)',
    fontsize=14, fontweight='bold', pad=15,
)
ax1c.invert_yaxis()
ax1c.set_xlim(0, max(counts) * 1.15)
ax1c.spines['top'].set_visible(False)
ax1c.spines['right'].set_visible(False)
plt.tight_layout()
fig1c.savefig(OUTPUT_DIR / 'disease_therapeutic_areas.png',
              dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
plt.close(fig1c)
print("  Saved disease_therapeutic_areas.png")

print("\nAll drug class distribution panels generated successfully!")
