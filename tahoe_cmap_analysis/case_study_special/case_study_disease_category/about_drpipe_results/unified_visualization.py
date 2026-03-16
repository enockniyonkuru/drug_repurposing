"""
Unified Drug Repurposing Visualization Script

Generates CONSISTENT visualizations for:
1. CMAP Recovered vs Tahoe Recovered
2. CMAP All vs Tahoe All
3. Recovered vs All Discoveries

All figures use the SAME rows (therapeutic areas) and columns (drug target classes)
to enable direct visual comparison.

Color Convention:
  - TAHOE: Serene Blue (#5DADE2)
  - CMAP: Warm Orange (#F39C12)
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter, defaultdict
import warnings
warnings.filterwarnings('ignore')
import os

# Import consistent categories
from consistent_categories import (
    THERAPEUTIC_AREAS, DRUG_TARGET_CLASSES,
    expand_and_standardize, create_crosstab, filter_to_top_categories
)

# =============================================================================
# COLOR SCHEME - CONSISTENT ACROSS ALL FIGURES
# =============================================================================
TAHOE_COLOR = '#5DADE2'  # Serene Blue
CMAP_COLOR = '#F39C12'   # Warm Orange

# Chord diagram colors
DISEASE_COLOR = '#E74C3C'  # Red for Disease Therapeutic Areas
DRUG_TARGET_COLOR = '#27AE60'  # Green for Drug Target Classes

# Custom colormaps for heatmaps
from matplotlib.colors import LinearSegmentedColormap
TAHOE_CMAP = LinearSegmentedColormap.from_list('tahoe_cmap', ['white', '#AED6F1', TAHOE_COLOR, '#1B4F72'])
CMAP_CMAP = LinearSegmentedColormap.from_list('cmap_cmap', ['white', '#FAD7A0', CMAP_COLOR, '#935116'])

# Set style
plt.style.use('seaborn-v0_8-whitegrid')
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['font.size'] = 10
plt.rcParams['axes.titlesize'] = 12
plt.rcParams['axes.labelsize'] = 10

# =============================================================================
# CONFIGURATION - TOP N CATEGORIES TO SHOW
# =============================================================================
TOP_THERAPEUTIC_AREAS = 12  # Number of disease areas to show
TOP_DRUG_CLASSES = 10       # Number of drug classes to show

# These will be determined from ALL data combined to ensure consistency
SELECTED_THERAPEUTIC_AREAS = None
SELECTED_DRUG_CLASSES = None

# =============================================================================
# LOAD ALL DATA
# =============================================================================

print("=" * 70)
print("UNIFIED VISUALIZATION - Consistent Categories")
print("=" * 70)

print("\nLoading data files...")

# Recovered data
cmap_rec = pd.read_csv('open_target_cmap_recovered.csv')
tahoe_rec = pd.read_csv('open_target_tahoe_recovered.csv')

# All discoveries data
cmap_all = pd.read_csv('all_discoveries_cmap.csv')
tahoe_all = pd.read_csv('all_discoveries_tahoe.csv')

print(f"  CMAP Recovered: {len(cmap_rec)} pairs")
print(f"  Tahoe Recovered: {len(tahoe_rec)} pairs")
print(f"  CMAP All Discoveries: {len(cmap_all)} pairs")
print(f"  Tahoe All Discoveries: {len(tahoe_all)} pairs")

# =============================================================================
# EXPAND AND STANDARDIZE ALL DATA
# =============================================================================

print("\nExpanding and standardizing categories...")

cmap_rec_exp = expand_and_standardize(cmap_rec)
tahoe_rec_exp = expand_and_standardize(tahoe_rec)
cmap_all_exp = expand_and_standardize(cmap_all)
tahoe_all_exp = expand_and_standardize(tahoe_all)

print(f"  CMAP Recovered: {len(cmap_rec)} -> {len(cmap_rec_exp)} expanded")
print(f"  Tahoe Recovered: {len(tahoe_rec)} -> {len(tahoe_rec_exp)} expanded")
print(f"  CMAP All: {len(cmap_all)} -> {len(cmap_all_exp)} expanded")
print(f"  Tahoe All: {len(tahoe_all)} -> {len(tahoe_all_exp)} expanded")

# =============================================================================
# DETERMINE CONSISTENT CATEGORIES FROM ALL DATA
# =============================================================================

print("\nDetermining consistent categories from all datasets...")

# Combine all expanded data
all_data = pd.concat([cmap_rec_exp, tahoe_rec_exp, cmap_all_exp, tahoe_all_exp], ignore_index=True)

# Count therapeutic areas
ta_counts = all_data['therapeutic_area'].value_counts()
# Filter to master list and get top N
SELECTED_THERAPEUTIC_AREAS = [ta for ta in THERAPEUTIC_AREAS 
                               if ta in ta_counts.index and ta != 'Other'][:TOP_THERAPEUTIC_AREAS]

# Count drug target classes  
tc_counts = all_data['drug_target_class_expanded'].value_counts()
# Filter to master list and get top N
SELECTED_DRUG_CLASSES = [tc for tc in DRUG_TARGET_CLASSES 
                          if tc in tc_counts.index and tc != 'Other'][:TOP_DRUG_CLASSES]

print(f"\nSelected {len(SELECTED_THERAPEUTIC_AREAS)} Therapeutic Areas:")
for ta in SELECTED_THERAPEUTIC_AREAS:
    print(f"  - {ta}")

print(f"\nSelected {len(SELECTED_DRUG_CLASSES)} Drug Target Classes:")
for tc in SELECTED_DRUG_CLASSES:
    print(f"  - {tc}")

# =============================================================================
# CREATE CROSS-TABULATIONS WITH CONSISTENT CATEGORIES
# =============================================================================

def create_consistent_crosstab(expanded_df):
    """Create crosstab with consistent rows and columns"""
    ct = pd.crosstab(
        expanded_df['therapeutic_area'], 
        expanded_df['drug_target_class_expanded']
    )
    # Reindex with selected categories (ensures same rows/cols for all)
    ct = ct.reindex(index=SELECTED_THERAPEUTIC_AREAS, 
                    columns=SELECTED_DRUG_CLASSES, 
                    fill_value=0)
    return ct

print("\nCreating consistent cross-tabulations...")

ct_cmap_rec = create_consistent_crosstab(cmap_rec_exp)
ct_tahoe_rec = create_consistent_crosstab(tahoe_rec_exp)
ct_cmap_all = create_consistent_crosstab(cmap_all_exp)
ct_tahoe_all = create_consistent_crosstab(tahoe_all_exp)

print(f"  All matrices: {ct_cmap_rec.shape[0]} rows x {ct_cmap_rec.shape[1]} columns")

# =============================================================================
# CREATE OUTPUT DIRECTORIES
# =============================================================================

os.makedirs('figures_recovered', exist_ok=True)
os.makedirs('figures_everything', exist_ok=True)

# =============================================================================
# 1. HEATMAPS - Individual
# =============================================================================

def create_heatmap(ct, title, cmap, filename, vmax=None):
    """Create individual heatmap"""
    fig, ax = plt.subplots(figsize=(14, 10))
    
    sns.heatmap(ct, annot=True, fmt='d', cmap=cmap, ax=ax,
                cbar_kws={'label': 'Number of Drug-Disease Pairs'},
                vmax=vmax, linewidths=0.5, linecolor='white')
    
    ax.set_title(title, fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Drug Target Class', fontsize=11)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=11)
    
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    
    plt.tight_layout()
    plt.savefig(filename, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {filename}")

print("\n1. Creating individual heatmaps...")

# Calculate global vmax for each comparison pair
vmax_recovered = max(ct_cmap_rec.values.max(), ct_tahoe_rec.values.max())
vmax_all = max(ct_cmap_all.values.max(), ct_tahoe_all.values.max())

# Recovered heatmaps
create_heatmap(ct_cmap_rec, 'CMAP Recovered: Disease Areas vs Drug Target Classes', 
               CMAP_CMAP, 'figures_recovered/heatmap_cmap.png', vmax=vmax_recovered)
create_heatmap(ct_tahoe_rec, 'Tahoe Recovered: Disease Areas vs Drug Target Classes', 
               TAHOE_CMAP, 'figures_recovered/heatmap_tahoe.png', vmax=vmax_recovered)

# All discoveries heatmaps
create_heatmap(ct_cmap_all, 'CMAP All Discoveries: Disease Areas vs Drug Target Classes', 
               CMAP_CMAP, 'figures_everything/heatmap_cmap.png', vmax=vmax_all)
create_heatmap(ct_tahoe_all, 'Tahoe All Discoveries: Disease Areas vs Drug Target Classes', 
               TAHOE_CMAP, 'figures_everything/heatmap_tahoe.png', vmax=vmax_all)

# =============================================================================
# 2. COMPARATIVE HEATMAPS (Side-by-side normalized)
# =============================================================================

def create_comparative_heatmap(ct_cmap, ct_tahoe, title_suffix, output_dir):
    """Create side-by-side normalized heatmaps"""
    
    # Normalize by row (percentage within each therapeutic area)
    ct_cmap_norm = ct_cmap.div(ct_cmap.sum(axis=1), axis=0) * 100
    ct_tahoe_norm = ct_tahoe.div(ct_tahoe.sum(axis=1), axis=0) * 100
    
    # Replace NaN with 0
    ct_cmap_norm = ct_cmap_norm.fillna(0)
    ct_tahoe_norm = ct_tahoe_norm.fillna(0)
    
    # Get shared vmax
    vmax = max(ct_cmap_norm.values.max(), ct_tahoe_norm.values.max())
    
    # Create figure with two subplots
    fig, axes = plt.subplots(1, 2, figsize=(24, 10))
    
    # CMAP
    sns.heatmap(ct_cmap_norm, annot=True, fmt='.1f', cmap=CMAP_CMAP, ax=axes[0],
                cbar_kws={'label': '% within Disease Area'}, vmax=vmax,
                linewidths=0.5, linecolor='white')
    axes[0].set_title(f'CMAP {title_suffix}\n(% distribution)', fontsize=12, fontweight='bold')
    axes[0].set_xlabel('Drug Target Class', fontsize=10)
    axes[0].set_ylabel('Disease Therapeutic Area', fontsize=10)
    axes[0].tick_params(axis='x', rotation=45)
    
    # Tahoe
    sns.heatmap(ct_tahoe_norm, annot=True, fmt='.1f', cmap=TAHOE_CMAP, ax=axes[1],
                cbar_kws={'label': '% within Disease Area'}, vmax=vmax,
                linewidths=0.5, linecolor='white')
    axes[1].set_title(f'Tahoe {title_suffix}\n(% distribution)', fontsize=12, fontweight='bold')
    axes[1].set_xlabel('Drug Target Class', fontsize=10)
    axes[1].set_ylabel('')
    axes[1].tick_params(axis='x', rotation=45)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/heatmap_comparative.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {output_dir}/heatmap_comparative.png")
    
    # Also save individual normalized heatmaps
    for ct_norm, name, cmap in [(ct_cmap_norm, 'cmap', CMAP_CMAP), (ct_tahoe_norm, 'tahoe', TAHOE_CMAP)]:
        fig, ax = plt.subplots(figsize=(14, 10))
        sns.heatmap(ct_norm, annot=True, fmt='.1f', cmap=cmap, ax=ax,
                    cbar_kws={'label': '% within Disease Area'}, vmax=vmax,
                    linewidths=0.5, linecolor='white')
        ax.set_title(f'{name.upper()} {title_suffix} (% distribution)', fontsize=12, fontweight='bold')
        ax.set_xlabel('Drug Target Class', fontsize=10)
        ax.set_ylabel('Disease Therapeutic Area', fontsize=10)
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(f'{output_dir}/heatmap_comparative_{name}.png', dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        print(f"  Saved: {output_dir}/heatmap_comparative_{name}.png")

print("\n2. Creating comparative heatmaps...")
create_comparative_heatmap(ct_cmap_rec, ct_tahoe_rec, 'Recovered', 'figures_recovered')
create_comparative_heatmap(ct_cmap_all, ct_tahoe_all, 'All Discoveries', 'figures_everything')

# =============================================================================
# 3. DIFFERENCE HEATMAPS
# =============================================================================

def create_difference_heatmap(ct_cmap, ct_tahoe, title_suffix, output_dir):
    """Create heatmap showing Tahoe - CMAP differences (normalized)"""
    
    # Normalize by row
    ct_cmap_norm = ct_cmap.div(ct_cmap.sum(axis=1), axis=0) * 100
    ct_tahoe_norm = ct_tahoe.div(ct_tahoe.sum(axis=1), axis=0) * 100
    
    # Replace NaN with 0
    ct_cmap_norm = ct_cmap_norm.fillna(0)
    ct_tahoe_norm = ct_tahoe_norm.fillna(0)
    
    # Calculate difference (Tahoe - CMAP)
    diff = ct_tahoe_norm - ct_cmap_norm
    
    # Create diverging heatmap
    fig, ax = plt.subplots(figsize=(14, 10))
    
    vmax = max(abs(diff.values.min()), abs(diff.values.max()))
    
    sns.heatmap(diff, annot=True, fmt='.1f', cmap='RdBu', ax=ax,
                center=0, vmin=-vmax, vmax=vmax,
                cbar_kws={'label': 'Tahoe - CMAP (% points)'},
                linewidths=0.5, linecolor='white')
    
    ax.set_title(f'Differential Pattern: Tahoe vs CMAP {title_suffix}\n(Blue = Tahoe higher, Red = CMAP higher)', 
                 fontsize=12, fontweight='bold')
    ax.set_xlabel('Drug Target Class', fontsize=10)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=10)
    
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(f'{output_dir}/heatmap_difference.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {output_dir}/heatmap_difference.png")

print("\n3. Creating difference heatmaps...")
create_difference_heatmap(ct_cmap_rec, ct_tahoe_rec, 'Recovered', 'figures_recovered')
create_difference_heatmap(ct_cmap_all, ct_tahoe_all, 'All Discoveries', 'figures_everything')

# =============================================================================
# 4. BUBBLE CHARTS
# =============================================================================

def create_bubble_chart(ct, title, colormap, filename):
    """Create bubble chart with intensity colormap"""
    fig, ax = plt.subplots(figsize=(16, 12))
    
    # Prepare data
    x_labels = ct.columns.tolist()
    y_labels = ct.index.tolist()
    
    max_val = ct.values.max()
    
    for i, ta in enumerate(y_labels):
        for j, tc in enumerate(x_labels):
            val = ct.loc[ta, tc]
            if val > 0:
                # Size proportional to value
                size = (val / max_val) * 2000 + 50
                # Color from colormap
                color = plt.cm.get_cmap(colormap)(val / max_val)
                ax.scatter(j, i, s=size, c=[color], alpha=0.7, edgecolors='gray', linewidth=0.5)
    
    ax.set_xticks(range(len(x_labels)))
    ax.set_xticklabels(x_labels, rotation=45, ha='right')
    ax.set_yticks(range(len(y_labels)))
    ax.set_yticklabels(y_labels)
    
    ax.set_xlabel('Drug Target Class', fontsize=11)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=11)
    ax.set_title(title, fontsize=14, fontweight='bold', pad=20)
    
    ax.set_xlim(-0.5, len(x_labels) - 0.5)
    ax.set_ylim(-0.5, len(y_labels) - 0.5)
    ax.invert_yaxis()
    ax.grid(True, alpha=0.3)
    
    # Add colorbar
    sm = plt.cm.ScalarMappable(cmap=colormap, norm=plt.Normalize(vmin=0, vmax=max_val))
    sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax, shrink=0.6)
    cbar.set_label('Number of Pairs', fontsize=10)
    
    plt.tight_layout()
    plt.savefig(filename, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {filename}")

print("\n4. Creating bubble charts...")
create_bubble_chart(ct_cmap_rec, 'CMAP Recovered: Disease-Drug Relationships', 
                    'YlOrRd', 'figures_recovered/bubble_cmap.png')
create_bubble_chart(ct_tahoe_rec, 'Tahoe Recovered: Disease-Drug Relationships', 
                    'YlGnBu', 'figures_recovered/bubble_tahoe.png')
create_bubble_chart(ct_cmap_all, 'CMAP All Discoveries: Disease-Drug Relationships', 
                    'YlOrRd', 'figures_everything/bubble_cmap.png')
create_bubble_chart(ct_tahoe_all, 'Tahoe All Discoveries: Disease-Drug Relationships', 
                    'YlGnBu', 'figures_everything/bubble_tahoe.png')

# =============================================================================
# 5. STACKED BAR CHARTS
# =============================================================================

def create_stacked_bar(ct, title, cmap_name, filename):
    """Create horizontal stacked bar chart"""
    fig, ax = plt.subplots(figsize=(14, 10))
    
    # Normalize by row
    ct_norm = ct.div(ct.sum(axis=1), axis=0) * 100
    ct_norm = ct_norm.fillna(0)
    
    # Get colors from colormap
    colors = plt.cm.get_cmap(cmap_name)(np.linspace(0.2, 0.9, len(ct.columns)))
    
    ct_norm.plot(kind='barh', stacked=True, ax=ax, color=colors, width=0.8)
    
    ax.set_xlabel('Percentage (%)', fontsize=11)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=11)
    ax.set_title(title, fontsize=14, fontweight='bold')
    ax.legend(title='Drug Target Class', bbox_to_anchor=(1.02, 1), loc='upper left', fontsize=8)
    
    ax.set_xlim(0, 100)
    
    plt.tight_layout()
    plt.savefig(filename, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {filename}")

print("\n5. Creating stacked bar charts...")
create_stacked_bar(ct_cmap_rec, 'CMAP Recovered: Drug Target Distribution by Disease', 
                   'Oranges', 'figures_recovered/stacked_bar_cmap.png')
create_stacked_bar(ct_tahoe_rec, 'Tahoe Recovered: Drug Target Distribution by Disease', 
                   'Blues', 'figures_recovered/stacked_bar_tahoe.png')
create_stacked_bar(ct_cmap_all, 'CMAP All: Drug Target Distribution by Disease', 
                   'Oranges', 'figures_everything/stacked_bar_cmap.png')
create_stacked_bar(ct_tahoe_all, 'Tahoe All: Drug Target Distribution by Disease', 
                   'Blues', 'figures_everything/stacked_bar_tahoe.png')

# =============================================================================
# 6. RADAR CHARTS
# =============================================================================

def create_radar_charts(ct_cmap, ct_tahoe, title_suffix, output_dir):
    """Create radar charts comparing CMAP vs Tahoe for top disease areas"""
    
    # Normalize by row
    ct_cmap_norm = ct_cmap.div(ct_cmap.sum(axis=1), axis=0) * 100
    ct_tahoe_norm = ct_tahoe.div(ct_tahoe.sum(axis=1), axis=0) * 100
    ct_cmap_norm = ct_cmap_norm.fillna(0)
    ct_tahoe_norm = ct_tahoe_norm.fillna(0)
    
    # Get top 8 disease areas by total count
    total_counts = ct_cmap.sum(axis=1) + ct_tahoe.sum(axis=1)
    top_areas = total_counts.nlargest(8).index.tolist()
    
    # Radar chart setup
    categories = ct_cmap.columns.tolist()
    num_cats = len(categories)
    angles = np.linspace(0, 2 * np.pi, num_cats, endpoint=False).tolist()
    angles += angles[:1]  # Complete the loop
    
    # Create panel figure
    fig, axes = plt.subplots(2, 4, figsize=(20, 12), subplot_kw=dict(projection='polar'))
    axes = axes.flatten()
    
    for idx, area in enumerate(top_areas):
        ax = axes[idx]
        
        # Get values for this area
        cmap_vals = ct_cmap_norm.loc[area].tolist()
        tahoe_vals = ct_tahoe_norm.loc[area].tolist()
        cmap_vals += cmap_vals[:1]
        tahoe_vals += tahoe_vals[:1]
        
        # Plot
        ax.plot(angles, cmap_vals, 'o-', linewidth=2, color=CMAP_COLOR, label='CMAP', markersize=4)
        ax.fill(angles, cmap_vals, alpha=0.25, color=CMAP_COLOR)
        ax.plot(angles, tahoe_vals, 'o-', linewidth=2, color=TAHOE_COLOR, label='Tahoe', markersize=4)
        ax.fill(angles, tahoe_vals, alpha=0.25, color=TAHOE_COLOR)
        
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(categories, fontsize=7)
        ax.set_title(area.replace('/', '/\n'), fontsize=10, fontweight='bold', pad=10)
        
        if idx == 0:
            ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.1), fontsize=8)
    
    plt.suptitle(f'Drug Target Profiles by Disease Area ({title_suffix})', 
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/radar_comparison.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {output_dir}/radar_comparison.png")
    
    # Save individual radar charts
    for area in top_areas:
        fig, ax = plt.subplots(figsize=(8, 8), subplot_kw=dict(projection='polar'))
        
        cmap_vals = ct_cmap_norm.loc[area].tolist() + [ct_cmap_norm.loc[area].tolist()[0]]
        tahoe_vals = ct_tahoe_norm.loc[area].tolist() + [ct_tahoe_norm.loc[area].tolist()[0]]
        
        ax.plot(angles, cmap_vals, 'o-', linewidth=2, color=CMAP_COLOR, label='CMAP', markersize=6)
        ax.fill(angles, cmap_vals, alpha=0.25, color=CMAP_COLOR)
        ax.plot(angles, tahoe_vals, 'o-', linewidth=2, color=TAHOE_COLOR, label='Tahoe', markersize=6)
        ax.fill(angles, tahoe_vals, alpha=0.25, color=TAHOE_COLOR)
        
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(categories, fontsize=9)
        ax.set_title(f'{area} ({title_suffix})', fontsize=12, fontweight='bold')
        ax.legend(loc='upper right', bbox_to_anchor=(1.2, 1.1))
        
        safe_name = area.replace('/', '_').replace(' ', '_')
        plt.tight_layout()
        plt.savefig(f'{output_dir}/radar_{safe_name}.png', dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
    
    print(f"  Saved: 8 individual radar charts to {output_dir}/")

print("\n6. Creating radar charts...")
create_radar_charts(ct_cmap_rec, ct_tahoe_rec, 'Recovered', 'figures_recovered')
create_radar_charts(ct_cmap_all, ct_tahoe_all, 'All Discoveries', 'figures_everything')

# =============================================================================
# 7. BAR CHARTS - Disease Areas and Drug Classes
# =============================================================================

def create_bar_charts(ct_cmap, ct_tahoe, title_suffix, output_dir):
    """Create bar charts comparing totals"""
    
    # Disease areas comparison
    fig, ax = plt.subplots(figsize=(12, 8))
    
    disease_totals = pd.DataFrame({
        'CMAP': ct_cmap.sum(axis=1),
        'Tahoe': ct_tahoe.sum(axis=1)
    })
    
    x = np.arange(len(disease_totals))
    width = 0.35
    
    ax.barh(x - width/2, disease_totals['CMAP'], width, label='CMAP', color=CMAP_COLOR, alpha=0.8)
    ax.barh(x + width/2, disease_totals['Tahoe'], width, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
    
    ax.set_yticks(x)
    ax.set_yticklabels(disease_totals.index)
    ax.set_xlabel('Number of Drug-Disease Pairs')
    ax.set_title(f'Disease Therapeutic Areas: CMAP vs Tahoe ({title_suffix})', fontweight='bold')
    ax.legend()
    ax.invert_yaxis()
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/bar_disease_areas.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {output_dir}/bar_disease_areas.png")
    
    # Drug classes comparison
    fig, ax = plt.subplots(figsize=(12, 8))
    
    drug_totals = pd.DataFrame({
        'CMAP': ct_cmap.sum(axis=0),
        'Tahoe': ct_tahoe.sum(axis=0)
    })
    
    x = np.arange(len(drug_totals))
    
    ax.barh(x - width/2, drug_totals['CMAP'], width, label='CMAP', color=CMAP_COLOR, alpha=0.8)
    ax.barh(x + width/2, drug_totals['Tahoe'], width, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
    
    ax.set_yticks(x)
    ax.set_yticklabels(drug_totals.index)
    ax.set_xlabel('Number of Drug-Disease Pairs')
    ax.set_title(f'Drug Target Classes: CMAP vs Tahoe ({title_suffix})', fontweight='bold')
    ax.legend()
    ax.invert_yaxis()
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/bar_drug_classes.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {output_dir}/bar_drug_classes.png")

print("\n7. Creating bar charts...")
create_bar_charts(ct_cmap_rec, ct_tahoe_rec, 'Recovered', 'figures_recovered')
create_bar_charts(ct_cmap_all, ct_tahoe_all, 'All Discoveries', 'figures_everything')

# =============================================================================
# 8. PIE CHARTS
# =============================================================================

def create_pie_charts(ct_cmap, ct_tahoe, title_suffix, output_dir):
    """Create pie charts for drug target class distribution"""
    
    for ct, name, color_base in [(ct_cmap, 'CMAP', 'Oranges'), (ct_tahoe, 'Tahoe', 'Blues')]:
        fig, ax = plt.subplots(figsize=(10, 10))
        
        totals = ct.sum(axis=0)
        colors = plt.cm.get_cmap(color_base)(np.linspace(0.3, 0.9, len(totals)))
        
        wedges, texts, autotexts = ax.pie(totals, labels=totals.index, autopct='%1.1f%%',
                                           colors=colors, pctdistance=0.8)
        
        for autotext in autotexts:
            autotext.set_fontsize(8)
        for text in texts:
            text.set_fontsize(9)
        
        ax.set_title(f'{name} Drug Target Classes ({title_suffix})', fontsize=12, fontweight='bold')
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/pie_{name.lower()}_drug_classes.png', dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
    
    print(f"  Saved: {output_dir}/pie_cmap_drug_classes.png")
    print(f"  Saved: {output_dir}/pie_tahoe_drug_classes.png")

print("\n8. Creating pie charts...")
create_pie_charts(ct_cmap_rec, ct_tahoe_rec, 'Recovered', 'figures_recovered')
create_pie_charts(ct_cmap_all, ct_tahoe_all, 'All Discoveries', 'figures_everything')

# =============================================================================
# 9. CHORD-STYLE DIAGRAMS
# =============================================================================

def create_chord_diagram(ct, title, filename):
    """Create chord-style network diagram with improved label positioning"""
    fig, ax = plt.subplots(figsize=(18, 18))  # Larger figure
    
    # Get nodes
    disease_nodes = ct.index.tolist()
    drug_nodes = ct.columns.tolist()
    
    n_disease = len(disease_nodes)
    n_drug = len(drug_nodes)
    
    # Position nodes in circle with padding to avoid overlap at boundaries
    # Add padding at the top and bottom to separate disease and drug sections
    padding = 0.15  # radians of padding
    disease_angles = np.linspace(padding, np.pi - padding, n_disease)
    drug_angles = np.linspace(np.pi + padding, 2*np.pi - padding, n_drug)
    
    radius = 1.0
    label_radius = 1.25  # Labels further out from nodes
    
    # Calculate node sizes based on total connections
    disease_sizes = ct.sum(axis=1)
    drug_sizes = ct.sum(axis=0)
    
    max_size = max(disease_sizes.max(), drug_sizes.max())
    
    # Draw connections
    for i, disease in enumerate(disease_nodes):
        for j, drug in enumerate(drug_nodes):
            weight = ct.loc[disease, drug]
            if weight > 0:
                x1 = radius * np.cos(disease_angles[i])
                y1 = radius * np.sin(disease_angles[i])
                x2 = radius * np.cos(drug_angles[j])
                y2 = radius * np.sin(drug_angles[j])
                
                alpha = min(0.6, 0.1 + (weight / ct.values.max()) * 0.5)
                linewidth = 0.5 + (weight / ct.values.max()) * 4
                
                ax.plot([x1, x2], [y1, y2], color='gray', alpha=alpha, linewidth=linewidth, zorder=1)
    
    # Draw disease nodes with improved label positioning
    for i, disease in enumerate(disease_nodes):
        x = radius * np.cos(disease_angles[i])
        y = radius * np.sin(disease_angles[i])
        size = 100 + (disease_sizes[disease] / max_size) * 800
        ax.scatter(x, y, s=size, c=DISEASE_COLOR, zorder=2, edgecolors='white', linewidth=2)
        
        # Label position - further out and angled
        lx = label_radius * np.cos(disease_angles[i])
        ly = label_radius * np.sin(disease_angles[i])
        
        # Determine text alignment based on position
        angle_deg = np.degrees(disease_angles[i])
        if angle_deg < 45:
            ha, va = 'left', 'bottom'
        elif angle_deg < 90:
            ha, va = 'left', 'center'
        elif angle_deg < 135:
            ha, va = 'right', 'center'
        else:
            ha, va = 'right', 'bottom'
        
        # Calculate rotation angle for text (tangent to circle)
        rotation = angle_deg - 90 if angle_deg <= 90 else angle_deg - 90
        if angle_deg > 90:
            rotation = angle_deg + 90
            ha = 'right'
        
        ax.annotate(disease, (lx, ly), fontsize=9, ha=ha, va=va, fontweight='bold',
                   rotation=0)  # Keep horizontal for readability
    
    # Draw drug nodes with improved label positioning
    for j, drug in enumerate(drug_nodes):
        x = radius * np.cos(drug_angles[j])
        y = radius * np.sin(drug_angles[j])
        size = 100 + (drug_sizes[drug] / max_size) * 800
        ax.scatter(x, y, s=size, c=DRUG_TARGET_COLOR, zorder=2, edgecolors='white', linewidth=2)
        
        # Label position - further out
        lx = label_radius * np.cos(drug_angles[j])
        ly = label_radius * np.sin(drug_angles[j])
        
        # Determine text alignment based on position
        angle_deg = np.degrees(drug_angles[j])
        if angle_deg < 225:  # left side of bottom half
            ha, va = 'right', 'top'
        elif angle_deg < 270:
            ha, va = 'right', 'center'
        elif angle_deg < 315:
            ha, va = 'left', 'center'
        else:
            ha, va = 'left', 'top'
        
        ax.annotate(drug, (lx, ly), fontsize=9, ha=ha, va=va, fontweight='bold',
                   rotation=0)  # Keep horizontal for readability
    
    # Legend
    ax.scatter([], [], c=DISEASE_COLOR, s=200, label='Disease Areas (top)')
    ax.scatter([], [], c=DRUG_TARGET_COLOR, s=200, label='Drug Target Classes (bottom)')
    ax.legend(loc='upper left', fontsize=11, framealpha=0.9)
    
    ax.set_xlim(-2.0, 2.0)
    ax.set_ylim(-2.0, 2.0)
    ax.set_aspect('equal')
    ax.axis('off')
    ax.set_title(title, fontsize=14, fontweight='bold', pad=20)
    
    plt.tight_layout()
    plt.savefig(filename, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {filename}")

print("\n9. Creating chord diagrams...")
create_chord_diagram(ct_cmap_rec, 'CMAP Recovered: Disease-Drug Connections', 'figures_recovered/chord_cmap.png')
create_chord_diagram(ct_tahoe_rec, 'Tahoe Recovered: Disease-Drug Connections', 'figures_recovered/chord_tahoe.png')
create_chord_diagram(ct_cmap_all, 'CMAP All: Disease-Drug Connections', 'figures_everything/chord_cmap.png')
create_chord_diagram(ct_tahoe_all, 'Tahoe All: Disease-Drug Connections', 'figures_everything/chord_tahoe.png')

# =============================================================================
# 10. SUMMARY DASHBOARD
# =============================================================================

def create_dashboard(ct_cmap, ct_tahoe, exp_cmap, exp_tahoe, title_suffix, output_dir):
    """Create summary dashboard"""
    fig = plt.figure(figsize=(20, 16))
    
    # Layout
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
    
    # 1. Disease areas bar chart
    ax1 = fig.add_subplot(gs[0, 0])
    disease_totals = pd.DataFrame({
        'CMAP': ct_cmap.sum(axis=1),
        'Tahoe': ct_tahoe.sum(axis=1)
    }).head(8)
    x = np.arange(len(disease_totals))
    width = 0.35
    ax1.barh(x - width/2, disease_totals['CMAP'], width, label='CMAP', color=CMAP_COLOR, alpha=0.8)
    ax1.barh(x + width/2, disease_totals['Tahoe'], width, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
    ax1.set_yticks(x)
    ax1.set_yticklabels(disease_totals.index, fontsize=8)
    ax1.set_title('Top Disease Areas', fontweight='bold')
    ax1.legend(fontsize=8)
    ax1.invert_yaxis()
    
    # 2. Drug classes bar chart
    ax2 = fig.add_subplot(gs[0, 1])
    drug_totals = pd.DataFrame({
        'CMAP': ct_cmap.sum(axis=0),
        'Tahoe': ct_tahoe.sum(axis=0)
    }).head(8)
    x = np.arange(len(drug_totals))
    ax2.barh(x - width/2, drug_totals['CMAP'], width, label='CMAP', color=CMAP_COLOR, alpha=0.8)
    ax2.barh(x + width/2, drug_totals['Tahoe'], width, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
    ax2.set_yticks(x)
    ax2.set_yticklabels(drug_totals.index, fontsize=8)
    ax2.set_title('Top Drug Classes', fontweight='bold')
    ax2.legend(fontsize=8)
    ax2.invert_yaxis()
    
    # 3. Summary stats
    ax3 = fig.add_subplot(gs[0, 2])
    ax3.axis('off')
    stats_text = f"""
    SUMMARY STATISTICS ({title_suffix})
    
    CMAP:
      • Pairs: {len(exp_cmap):,}
      • Unique Diseases: {exp_cmap['disease_id'].nunique()}
      • Unique Drugs: {exp_cmap['drug_id'].nunique() if 'drug_id' in exp_cmap.columns else 'N/A'}
    
    Tahoe:
      • Pairs: {len(exp_tahoe):,}
      • Unique Diseases: {exp_tahoe['disease_id'].nunique()}
      • Unique Drugs: {exp_tahoe['drug_id'].nunique() if 'drug_id' in exp_tahoe.columns else 'N/A'}
    
    Ratio (Tahoe/CMAP): {len(exp_tahoe)/len(exp_cmap):.1f}x
    """
    ax3.text(0.1, 0.5, stats_text, transform=ax3.transAxes, fontsize=11,
             verticalalignment='center', fontfamily='monospace',
             bbox=dict(boxstyle='round', facecolor='lightgray', alpha=0.3))
    
    # 4-5. Pie charts
    for idx, (ct, name, color_base) in enumerate([(ct_cmap, 'CMAP', 'Oranges'), (ct_tahoe, 'Tahoe', 'Blues')]):
        ax = fig.add_subplot(gs[1, idx])
        totals = ct.sum(axis=0).head(6)
        colors = plt.cm.get_cmap(color_base)(np.linspace(0.3, 0.9, len(totals)))
        ax.pie(totals, labels=totals.index, autopct='%1.0f%%', colors=colors, textprops={'fontsize': 8})
        ax.set_title(f'{name} Drug Classes', fontweight='bold')
    
    # 6. Scatter: diseases vs drugs by area
    ax6 = fig.add_subplot(gs[1, 2])
    for ct, name, color in [(ct_cmap, 'CMAP', CMAP_COLOR), (ct_tahoe, 'Tahoe', TAHOE_COLOR)]:
        for area in ct.index:
            n_pairs = ct.loc[area].sum()
            n_classes = (ct.loc[area] > 0).sum()
            ax6.scatter(n_classes, n_pairs, c=color, s=100, alpha=0.7, label=name if area == ct.index[0] else "")
    ax6.set_xlabel('Number of Drug Classes')
    ax6.set_ylabel('Total Pairs')
    ax6.set_title('Coverage per Disease Area', fontweight='bold')
    ax6.legend()
    
    # 7-8. Mini heatmaps
    ax7 = fig.add_subplot(gs[2, 0])
    sns.heatmap(ct_cmap.iloc[:6, :6], annot=True, fmt='d', cmap=CMAP_CMAP, ax=ax7, cbar=False)
    ax7.set_title('CMAP Heatmap (Top)', fontweight='bold', fontsize=10)
    ax7.tick_params(axis='both', labelsize=7)
    
    ax8 = fig.add_subplot(gs[2, 1])
    sns.heatmap(ct_tahoe.iloc[:6, :6], annot=True, fmt='d', cmap=TAHOE_CMAP, ax=ax8, cbar=False)
    ax8.set_title('Tahoe Heatmap (Top)', fontweight='bold', fontsize=10)
    ax8.tick_params(axis='both', labelsize=7)
    
    # 9. Top combinations
    ax9 = fig.add_subplot(gs[2, 2])
    
    # Get top combinations
    top_combos_cmap = []
    top_combos_tahoe = []
    for ta in ct_cmap.index:
        for tc in ct_cmap.columns:
            top_combos_cmap.append((f"{ta[:15]}→{tc[:10]}", ct_cmap.loc[ta, tc]))
            top_combos_tahoe.append((f"{ta[:15]}→{tc[:10]}", ct_tahoe.loc[ta, tc]))
    
    top_cmap = sorted(top_combos_cmap, key=lambda x: x[1], reverse=True)[:5]
    top_tahoe = sorted(top_combos_tahoe, key=lambda x: x[1], reverse=True)[:5]
    
    y = np.arange(5)
    ax9.barh(y + 0.2, [x[1] for x in top_cmap], 0.4, label='CMAP', color=CMAP_COLOR, alpha=0.8)
    ax9.barh(y - 0.2, [x[1] for x in top_tahoe], 0.4, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
    ax9.set_yticks(y)
    ax9.set_yticklabels([x[0] for x in top_cmap], fontsize=7)
    ax9.set_title('Top Combinations', fontweight='bold')
    ax9.legend(fontsize=8)
    ax9.invert_yaxis()
    
    plt.suptitle(f'Drug Repurposing Dashboard: CMAP vs Tahoe ({title_suffix})', 
                 fontsize=16, fontweight='bold', y=1.02)
    
    plt.savefig(f'{output_dir}/dashboard_summary.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  Saved: {output_dir}/dashboard_summary.png")

print("\n10. Creating summary dashboards...")
create_dashboard(ct_cmap_rec, ct_tahoe_rec, cmap_rec_exp, tahoe_rec_exp, 'Recovered', 'figures_recovered')
create_dashboard(ct_cmap_all, ct_tahoe_all, cmap_all_exp, tahoe_all_exp, 'All Discoveries', 'figures_everything')

# =============================================================================
# 11. CROSS-COMPARISON: Recovered vs All (NEW!)
# =============================================================================

print("\n11. Creating Recovered vs All comparison figures...")

def create_recovered_vs_all_comparison():
    """Create figures comparing recovered vs all discoveries"""
    
    os.makedirs('figures_comparison', exist_ok=True)
    
    # 1. CMAP: Recovered vs All
    fig, axes = plt.subplots(1, 2, figsize=(24, 10))
    
    vmax = max(ct_cmap_rec.values.max(), ct_cmap_all.values.max())
    
    sns.heatmap(ct_cmap_rec, annot=True, fmt='d', cmap=CMAP_CMAP, ax=axes[0],
                vmax=vmax, linewidths=0.5, linecolor='white')
    axes[0].set_title('CMAP Recovered', fontsize=12, fontweight='bold')
    axes[0].set_xlabel('Drug Target Class')
    axes[0].set_ylabel('Disease Therapeutic Area')
    axes[0].tick_params(axis='x', rotation=45)
    
    sns.heatmap(ct_cmap_all, annot=True, fmt='d', cmap=CMAP_CMAP, ax=axes[1],
                vmax=vmax, linewidths=0.5, linecolor='white')
    axes[1].set_title('CMAP All Discoveries', fontsize=12, fontweight='bold')
    axes[1].set_xlabel('Drug Target Class')
    axes[1].set_ylabel('')
    axes[1].tick_params(axis='x', rotation=45)
    
    plt.suptitle('CMAP: Recovered vs All Discoveries', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig('figures_comparison/cmap_recovered_vs_all.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print("  Saved: figures_comparison/cmap_recovered_vs_all.png")
    
    # 2. Tahoe: Recovered vs All
    fig, axes = plt.subplots(1, 2, figsize=(24, 10))
    
    vmax = max(ct_tahoe_rec.values.max(), ct_tahoe_all.values.max())
    
    sns.heatmap(ct_tahoe_rec, annot=True, fmt='d', cmap=TAHOE_CMAP, ax=axes[0],
                vmax=vmax, linewidths=0.5, linecolor='white')
    axes[0].set_title('Tahoe Recovered', fontsize=12, fontweight='bold')
    axes[0].set_xlabel('Drug Target Class')
    axes[0].set_ylabel('Disease Therapeutic Area')
    axes[0].tick_params(axis='x', rotation=45)
    
    sns.heatmap(ct_tahoe_all, annot=True, fmt='d', cmap=TAHOE_CMAP, ax=axes[1],
                vmax=vmax, linewidths=0.5, linecolor='white')
    axes[1].set_title('Tahoe All Discoveries', fontsize=12, fontweight='bold')
    axes[1].set_xlabel('Drug Target Class')
    axes[1].set_ylabel('')
    axes[1].tick_params(axis='x', rotation=45)
    
    plt.suptitle('Tahoe: Recovered vs All Discoveries', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig('figures_comparison/tahoe_recovered_vs_all.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print("  Saved: figures_comparison/tahoe_recovered_vs_all.png")
    
    # 3. 2x2 Grid: All four conditions
    fig, axes = plt.subplots(2, 2, figsize=(24, 20))
    
    vmax = max(ct_cmap_rec.values.max(), ct_tahoe_rec.values.max(), 
               ct_cmap_all.values.max(), ct_tahoe_all.values.max())
    
    for ax, ct, cmap, title in [
        (axes[0, 0], ct_cmap_rec, CMAP_CMAP, 'CMAP Recovered'),
        (axes[0, 1], ct_tahoe_rec, TAHOE_CMAP, 'Tahoe Recovered'),
        (axes[1, 0], ct_cmap_all, CMAP_CMAP, 'CMAP All Discoveries'),
        (axes[1, 1], ct_tahoe_all, TAHOE_CMAP, 'Tahoe All Discoveries')
    ]:
        sns.heatmap(ct, annot=True, fmt='d', cmap=cmap, ax=ax,
                    vmax=vmax, linewidths=0.5, linecolor='white',
                    annot_kws={'fontsize': 8})
        ax.set_title(title, fontsize=12, fontweight='bold')
        ax.set_xlabel('Drug Target Class', fontsize=10)
        ax.set_ylabel('Disease Therapeutic Area', fontsize=10)
        ax.tick_params(axis='x', rotation=45, labelsize=8)
        ax.tick_params(axis='y', labelsize=8)
    
    plt.suptitle('Comprehensive Comparison: CMAP vs Tahoe, Recovered vs All', 
                 fontsize=16, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig('figures_comparison/comprehensive_2x2.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print("  Saved: figures_comparison/comprehensive_2x2.png")
    
    # 4. Normalized 2x2 Grid
    fig, axes = plt.subplots(2, 2, figsize=(24, 20))
    
    ct_cmap_rec_norm = ct_cmap_rec.div(ct_cmap_rec.sum(axis=1), axis=0) * 100
    ct_tahoe_rec_norm = ct_tahoe_rec.div(ct_tahoe_rec.sum(axis=1), axis=0) * 100
    ct_cmap_all_norm = ct_cmap_all.div(ct_cmap_all.sum(axis=1), axis=0) * 100
    ct_tahoe_all_norm = ct_tahoe_all.div(ct_tahoe_all.sum(axis=1), axis=0) * 100
    
    for df in [ct_cmap_rec_norm, ct_tahoe_rec_norm, ct_cmap_all_norm, ct_tahoe_all_norm]:
        df.fillna(0, inplace=True)
    
    vmax = max(ct_cmap_rec_norm.values.max(), ct_tahoe_rec_norm.values.max(),
               ct_cmap_all_norm.values.max(), ct_tahoe_all_norm.values.max())
    
    for ax, ct, cmap, title in [
        (axes[0, 0], ct_cmap_rec_norm, CMAP_CMAP, 'CMAP Recovered (%)'),
        (axes[0, 1], ct_tahoe_rec_norm, TAHOE_CMAP, 'Tahoe Recovered (%)'),
        (axes[1, 0], ct_cmap_all_norm, CMAP_CMAP, 'CMAP All (%)'),
        (axes[1, 1], ct_tahoe_all_norm, TAHOE_CMAP, 'Tahoe All (%)')
    ]:
        sns.heatmap(ct, annot=True, fmt='.1f', cmap=cmap, ax=ax,
                    vmax=vmax, linewidths=0.5, linecolor='white',
                    annot_kws={'fontsize': 8})
        ax.set_title(title, fontsize=12, fontweight='bold')
        ax.set_xlabel('Drug Target Class', fontsize=10)
        ax.set_ylabel('Disease Therapeutic Area', fontsize=10)
        ax.tick_params(axis='x', rotation=45, labelsize=8)
        ax.tick_params(axis='y', labelsize=8)
    
    plt.suptitle('Normalized Comparison (% within Disease Area)', 
                 fontsize=16, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig('figures_comparison/comprehensive_2x2_normalized.png', dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print("  Saved: figures_comparison/comprehensive_2x2_normalized.png")

create_recovered_vs_all_comparison()

# =============================================================================
# COMPLETION
# =============================================================================

print("\n" + "=" * 70)
print("UNIFIED VISUALIZATION COMPLETE")
print("=" * 70)

print(f"""
Consistent Categories Used:
  • {len(SELECTED_THERAPEUTIC_AREAS)} Therapeutic Areas (rows)
  • {len(SELECTED_DRUG_CLASSES)} Drug Target Classes (columns)

Output Folders:
  • figures_recovered/  - CMAP vs Tahoe (validated pairs)
  • figures_everything/ - CMAP vs Tahoe (all discoveries)  
  • figures_comparison/ - Cross-comparisons (NEW!)

Color Convention:
  • CMAP: Warm Orange (#F39C12)
  • Tahoe: Serene Blue (#5DADE2)
  • Bubble Charts: YlOrRd (CMAP), YlGnBu (Tahoe) intensity
  • Chord Diagrams: Red (#E74C3C) diseases, Green (#27AE60) drug targets

All figures now have IDENTICAL rows and columns for direct comparison!
""")
