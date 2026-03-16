#!/usr/bin/env python3
"""
Generate Part 1 Figures for Manuscript
- Figure 1A: Pie chart of drug target classes in CMAP
- Figure 1B: Pie chart of drug target classes in TAHOE
- Figure 1C: Bar chart of disease therapeutic areas
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from collections import Counter

# Set style for publication-quality figures
plt.style.use('seaborn-v0_8-whitegrid')
plt.rcParams['font.family'] = 'Arial'
plt.rcParams['font.size'] = 10
plt.rcParams['axes.labelsize'] = 12
plt.rcParams['axes.titlesize'] = 14
plt.rcParams['figure.dpi'] = 300

# Define consistent color mapping for drug target classes
# Using a comprehensive palette to ensure consistency across platforms
CLASS_COLORS = {
    'Membrane receptor': '#3498DB',      # Blue
    'Enzyme': '#E74C3C',                  # Red
    'Ion channel': '#2ECC71',             # Green
    'Transcription factor': '#F39C12',   # Orange
    'Transporter': '#9B59B6',             # Purple
    'Unclassified protein': '#1ABC9C',   # Teal
    'Epigenetic regulator': '#34495E',   # Dark Gray
    'Structural protein': '#95A5A6',     # Light Gray
    'Auxiliary transport protein': '#D35400',  # Dark Orange
    'Other cytosolic protein': '#C0392B',     # Dark Red
    'Other nuclear protein': '#8E44AD',       # Dark Purple
    'Other': '#95A5A6'                   # Light Gray
}

# Load data
print("Loading data...")
cmap_drugs = pd.read_csv('../about_drugs/open_target_drugs_in_cmap.csv')
tahoe_drugs = pd.read_csv('../about_drugs/open_target_drugs_in_tahoe.csv')
diseases = pd.read_csv('../about_diseases/creeds_diseases_with_known_drugs.csv')

print(f"CMAP drugs: {len(cmap_drugs)}")
print(f"TAHOE drugs: {len(tahoe_drugs)}")
print(f"Diseases: {len(diseases)}")

# ============================================================================
# Figure 1A: CMAP Drug Target Classes
# ============================================================================
def parse_target_classes(target_class_series):
    """Parse target classes handling multi-class entries separated by |"""
    all_classes = []
    for tc in target_class_series.dropna():
        classes = [c.strip() for c in str(tc).split('|')]
        all_classes.extend(classes)
    return Counter(all_classes)

# Get CMAP target class distribution
cmap_classes = parse_target_classes(cmap_drugs['drug_target_class'])
print("\nCMAP Target Classes:")
for k, v in cmap_classes.most_common(10):
    print(f"  {k}: {v}")

# Get TAHOE target class distribution
tahoe_classes = parse_target_classes(tahoe_drugs['drug_target_class'])
print("\nTAHOE Target Classes:")
for k, v in tahoe_classes.most_common(10):
    print(f"  {k}: {v}")

# Create pie chart for CMAP - names outside close to pie, numbers inside slices
fig1a, ax1a = plt.subplots(figsize=(14, 14))

# Get top classes and group smaller ones as "Other"
cmap_top = dict(cmap_classes.most_common(7))
cmap_other = sum(v for k, v in cmap_classes.items() if k not in cmap_top)
if cmap_other > 0:
    cmap_top['Other'] = cmap_other

labels_cmap = list(cmap_top.keys())
sizes_cmap = list(cmap_top.values())
total_cmap = sum(sizes_cmap)

# Get colors for each class (consistent with TAHOE)
colors_cmap = [CLASS_COLORS.get(label, '#95A5A6') for label in labels_cmap]

# Create pie chart with numbers inside
def make_autopct(values):
    def autopct(pct):
        val = int(round(pct/100.*sum(values)))
        return f'n={val}\n({pct:.1f}%)'
    return autopct

wedges, texts, autotexts = ax1a.pie(sizes_cmap, 
                                     labels=labels_cmap,
                                     colors=colors_cmap,
                                     autopct=make_autopct(sizes_cmap),
                                     startangle=90,
                                     explode=[0.05]*len(sizes_cmap),
                                     wedgeprops={'linewidth': 2, 'edgecolor': 'white'},
                                     textprops={'fontsize': 12, 'fontweight': 'bold'},
                                     pctdistance=0.55,
                                     labeldistance=1.15)

# Style the numbers inside
for autotext in autotexts:
    autotext.set_fontsize(10)
    autotext.set_fontweight('bold')
    autotext.set_color('white')

# Style the labels outside - make them larger and bolder
for text in texts:
    text.set_fontsize(13)
    text.set_fontweight('bold')

ax1a.set_title(f'CMAP Drug Target Class Distribution\n(n = {len(cmap_drugs)} drugs)', 
               fontsize=16, fontweight='bold', pad=25)

plt.tight_layout()
plt.savefig('figures/Figure_1A_CMAP_Drug_Classes.png', dpi=300, bbox_inches='tight', 
            facecolor='white', edgecolor='none')
plt.close()
print("Saved Figure 1A")

# ============================================================================
# Figure 1B: TAHOE Drug Target Classes
# ============================================================================
fig1b, ax1b = plt.subplots(figsize=(14, 14))

# Get top classes and group smaller ones as "Other"
tahoe_top = dict(tahoe_classes.most_common(7))
tahoe_other = sum(v for k, v in tahoe_classes.items() if k not in tahoe_top)
if tahoe_other > 0:
    tahoe_top['Other'] = tahoe_other

labels_tahoe = list(tahoe_top.keys())
sizes_tahoe = list(tahoe_top.values())
total_tahoe = sum(sizes_tahoe)

# Get colors for each class (consistent with CMAP)
colors_tahoe = [CLASS_COLORS.get(label, '#95A5A6') for label in labels_tahoe]

# Create pie chart with numbers inside
def make_autopct_tahoe(values):
    def autopct(pct):
        val = int(round(pct/100.*sum(values)))
        return f'n={val}\n({pct:.1f}%)'
    return autopct

wedges, texts, autotexts = ax1b.pie(sizes_tahoe, 
                                     labels=labels_tahoe,
                                     colors=colors_tahoe,
                                     autopct=make_autopct_tahoe(sizes_tahoe),
                                     startangle=90,
                                     explode=[0.05]*len(sizes_tahoe),
                                     wedgeprops={'linewidth': 2, 'edgecolor': 'white'},
                                     textprops={'fontsize': 12, 'fontweight': 'bold'},
                                     pctdistance=0.55,
                                     labeldistance=1.15)

# Style the numbers inside
for autotext in autotexts:
    autotext.set_fontsize(10)
    autotext.set_fontweight('bold')
    autotext.set_color('white')

# Style the labels outside - make them larger and bolder
for text in texts:
    text.set_fontsize(13)
    text.set_fontweight('bold')

ax1b.set_title(f'TAHOE Drug Target Class Distribution\n(n = {len(tahoe_drugs)} drugs)', 
               fontsize=16, fontweight='bold', pad=25)

plt.tight_layout()
plt.savefig('figures/Figure_1B_TAHOE_Drug_Classes.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.close()
print("Saved Figure 1B")

# ============================================================================
# Figure 1C: Disease Therapeutic Areas Distribution
# ============================================================================
# Use primary_therapeutic_area for cleaner visualization
disease_areas = diseases['primary_therapeutic_area'].value_counts()
print("\nDisease Therapeutic Areas:")
print(disease_areas)

fig1c, ax1c = plt.subplots(figsize=(12, 7))

# Sort by count
areas = disease_areas.index.tolist()
counts = disease_areas.values.tolist()

# Create horizontal bar chart
bars = ax1c.barh(range(len(areas)), counts, color='#3498DB', edgecolor='white', height=0.7)

# Add count labels
for i, (area, count) in enumerate(zip(areas, counts)):
    ax1c.text(count + 0.5, i, str(count), va='center', fontsize=10, fontweight='bold')

ax1c.set_yticks(range(len(areas)))
ax1c.set_yticklabels(areas, fontsize=11)
ax1c.set_xlabel('Number of Diseases', fontsize=12, fontweight='bold')
ax1c.set_title(f'Distribution of Diseases by Primary Therapeutic Area\n(n = {len(diseases)} diseases with known drug associations)', 
               fontsize=14, fontweight='bold', pad=15)

ax1c.invert_yaxis()  # Highest count at top
ax1c.set_xlim(0, max(counts) * 1.15)
ax1c.spines['top'].set_visible(False)
ax1c.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('figures/Figure_1C_Disease_Therapeutic_Areas.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.close()
print("Saved Figure 1C")

print("\n" + "="*60)
print("All Part 1 figures generated successfully!")
print("="*60)

# Print summary statistics for manuscript
print("\n--- Summary Statistics for Manuscript ---")
print(f"\nCMAP: {len(cmap_drugs)} drugs matched to Open Targets")
print(f"TAHOE: {len(tahoe_drugs)} drugs matched to Open Targets")
print(f"Diseases: {len(diseases)} with known drug associations")

# Count shared drugs
cmap_drug_ids = set(cmap_drugs['drug_id'])
tahoe_drug_ids = set(tahoe_drugs['drug_id'])
shared_drugs = cmap_drug_ids & tahoe_drug_ids
print(f"\nShared drugs between platforms: {len(shared_drugs)}")
print(f"  - As % of CMAP: {len(shared_drugs)/len(cmap_drug_ids)*100:.1f}%")
print(f"  - As % of TAHOE: {len(shared_drugs)/len(tahoe_drug_ids)*100:.1f}%")
