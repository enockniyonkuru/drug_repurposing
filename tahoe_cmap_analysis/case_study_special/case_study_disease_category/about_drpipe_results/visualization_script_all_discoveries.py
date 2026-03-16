"""
Drug Repurposing Visualization: ALL Pipeline Discoveries

Creates visualizations to explore the biological relationships between 
disease categories and drug mechanisms for ALL drugs discovered by the
CMAP and Tahoe pipelines (not just recovered/validated ones).

Color Convention:
  - TAHOE: Serene Blue (#5DADE2)
  - CMAP: Warm Orange (#F39C12)

Exceptions:
  - Bubble Charts: Use intensity colormaps (YlOrRd for CMAP, YlGnBu for Tahoe)
  - Chord Diagrams: Red (#E74C3C) for Disease Areas, Green (#27AE60) for Drug Targets

Output: figures_everything/ subfolder with multiple visualization types
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter, defaultdict
import warnings
warnings.filterwarnings('ignore')

# =============================================================================
# COLOR SCHEME - CONSISTENT ACROSS ALL FIGURES
# =============================================================================
TAHOE_COLOR = '#5DADE2'  # Serene Blue
CMAP_COLOR = '#F39C12'   # Warm Orange

# Colors for chord diagrams
DISEASE_AREA_COLOR = '#E74C3C'    # Red/Coral for diseases
DRUG_TARGET_COLOR = '#27AE60'     # Green for drug targets

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

# Output directory
OUTPUT_DIR = 'figures_everything'

# =============================================================================
# LOAD DATA
# =============================================================================

print("Loading all discoveries data...")
cmap_df = pd.read_csv('all_discoveries_cmap.csv')
tahoe_df = pd.read_csv('all_discoveries_tahoe.csv')

print(f"CMAP all discoveries: {len(cmap_df)} pairs")
print(f"Tahoe all discoveries: {len(tahoe_df)} pairs")

# =============================================================================
# DATA PREPARATION
# =============================================================================

def prepare_data(df, name):
    """Expand multi-membership and create cross-tabulation"""
    
    rows = []
    for _, row in df.iterrows():
        # Get therapeutic areas (can be multiple, pipe-separated)
        therapeutic_areas = str(row['disease_therapeutic_areas']).split('|') if pd.notna(row['disease_therapeutic_areas']) else ['Unknown']
        
        # Get drug target classes (can be multiple, pipe-separated)
        target_classes = str(row['drug_target_class']).split('|') if pd.notna(row['drug_target_class']) else ['Unknown']
        
        # Create row for each combination
        for ta in therapeutic_areas:
            ta = ta.strip()
            if not ta or ta == 'nan':
                ta = 'Unknown'
            for tc in target_classes:
                tc = tc.strip()
                if not tc or tc == 'nan':
                    tc = 'Unknown'
                rows.append({
                    'therapeutic_area': ta,
                    'drug_target_class': tc,
                    'disease_id': row['disease_id'],
                    'drug_id': row['drug_id'],
                    'drug_name': row['drug_common_name'],
                    'disease_name': row['disease_name'],
                    'drug_rank': row['drug_rank']
                })
    
    expanded_df = pd.DataFrame(rows)
    print(f"\n{name}: {len(df)} pairs -> {len(expanded_df)} expanded combinations")
    
    return expanded_df

cmap_expanded = prepare_data(cmap_df, "CMAP")
tahoe_expanded = prepare_data(tahoe_df, "Tahoe")

# Ensure figures directory exists
import os
os.makedirs(OUTPUT_DIR, exist_ok=True)

# =============================================================================
# 1. HEATMAP: Disease Therapeutic Areas vs Drug Target Classes
# =============================================================================

def create_heatmap(df, title, filename, cmap_colors):
    """Create heatmap of therapeutic areas vs drug target classes"""
    
    # Create cross-tabulation
    cross_tab = pd.crosstab(df['therapeutic_area'], df['drug_target_class'])
    
    # Sort by totals
    cross_tab = cross_tab.loc[cross_tab.sum(axis=1).sort_values(ascending=False).index]
    cross_tab = cross_tab[cross_tab.sum().sort_values(ascending=False).index]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(14, 10))
    
    # Create heatmap
    sns.heatmap(cross_tab, annot=True, fmt='d', cmap=cmap_colors, 
                linewidths=0.5, ax=ax, cbar_kws={'label': 'Number of Pairs'})
    
    ax.set_title(f'{title}\nDisease Therapeutic Areas vs Drug Target Classes', fontsize=14, fontweight='bold')
    ax.set_xlabel('Drug Target Class', fontsize=12)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=12)
    
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    plt.tight_layout()
    
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")
    
    return cross_tab

print("\n1. Creating heatmaps...")
cmap_crosstab = create_heatmap(cmap_expanded, "CMAP All Discoveries", "heatmap_cmap.png", CMAP_CMAP)
tahoe_crosstab = create_heatmap(tahoe_expanded, "Tahoe All Discoveries", "heatmap_tahoe.png", TAHOE_CMAP)

# =============================================================================
# 2. COMPARATIVE HEATMAP (Side by Side + Individual)
# =============================================================================

def create_comparative_heatmap(cmap_df, tahoe_df, filename):
    """Create side-by-side normalized heatmaps for comparison"""
    
    # Create cross-tabulations
    cmap_ct = pd.crosstab(cmap_df['therapeutic_area'], cmap_df['drug_target_class'])
    tahoe_ct = pd.crosstab(tahoe_df['therapeutic_area'], tahoe_df['drug_target_class'])
    
    # Get union of all categories
    all_tas = sorted(set(cmap_ct.index) | set(tahoe_ct.index))
    all_tcs = sorted(set(cmap_ct.columns) | set(tahoe_ct.columns))
    
    # Reindex to have same shape
    cmap_ct = cmap_ct.reindex(index=all_tas, columns=all_tcs, fill_value=0)
    tahoe_ct = tahoe_ct.reindex(index=all_tas, columns=all_tcs, fill_value=0)
    
    # Normalize by row (percentage within each disease area)
    cmap_norm = cmap_ct.div(cmap_ct.sum(axis=1), axis=0) * 100
    tahoe_norm = tahoe_ct.div(tahoe_ct.sum(axis=1), axis=0) * 100
    
    # Sort by total
    row_order = (cmap_ct.sum(axis=1) + tahoe_ct.sum(axis=1)).sort_values(ascending=False).index
    col_order = (cmap_ct.sum(axis=0) + tahoe_ct.sum(axis=0)).sort_values(ascending=False).index
    
    cmap_norm = cmap_norm.loc[row_order, col_order]
    tahoe_norm = tahoe_norm.loc[row_order, col_order]
    
    # ----- INDIVIDUAL FIGURES -----
    # CMAP Individual
    fig_cmap, ax_cmap = plt.subplots(figsize=(12, 10))
    sns.heatmap(cmap_norm, annot=True, fmt='.0f', cmap=CMAP_CMAP, 
                linewidths=0.5, ax=ax_cmap, vmin=0, vmax=50,
                cbar_kws={'label': '% within Disease Area'})
    ax_cmap.set_title('CMAP: Drug Target Distribution\n(% within each Disease Area)', fontsize=12, fontweight='bold')
    ax_cmap.set_xlabel('Drug Target Class')
    ax_cmap.set_ylabel('Disease Therapeutic Area')
    ax_cmap.set_xticklabels(ax_cmap.get_xticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/heatmap_comparative_cmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/heatmap_comparative_cmap.png")
    
    # Tahoe Individual
    fig_tahoe, ax_tahoe = plt.subplots(figsize=(12, 10))
    sns.heatmap(tahoe_norm, annot=True, fmt='.0f', cmap=TAHOE_CMAP, 
                linewidths=0.5, ax=ax_tahoe, vmin=0, vmax=50,
                cbar_kws={'label': '% within Disease Area'})
    ax_tahoe.set_title('Tahoe: Drug Target Distribution\n(% within each Disease Area)', fontsize=12, fontweight='bold')
    ax_tahoe.set_xlabel('Drug Target Class')
    ax_tahoe.set_ylabel('Disease Therapeutic Area')
    ax_tahoe.set_xticklabels(ax_tahoe.get_xticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/heatmap_comparative_tahoe.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/heatmap_comparative_tahoe.png")
    
    # ----- COMBINED PANEL FIGURE -----
    fig, axes = plt.subplots(1, 2, figsize=(20, 10))
    
    sns.heatmap(cmap_norm, annot=True, fmt='.0f', cmap=CMAP_CMAP, 
                linewidths=0.5, ax=axes[0], vmin=0, vmax=50,
                cbar_kws={'label': '% within Disease Area'})
    axes[0].set_title('CMAP: Drug Target Distribution\n(% within each Disease Area)', fontsize=12, fontweight='bold')
    axes[0].set_xlabel('Drug Target Class')
    axes[0].set_ylabel('Disease Therapeutic Area')
    
    sns.heatmap(tahoe_norm, annot=True, fmt='.0f', cmap=TAHOE_CMAP, 
                linewidths=0.5, ax=axes[1], vmin=0, vmax=50,
                cbar_kws={'label': '% within Disease Area'})
    axes[1].set_title('Tahoe: Drug Target Distribution\n(% within each Disease Area)', fontsize=12, fontweight='bold')
    axes[1].set_xlabel('Drug Target Class')
    axes[1].set_ylabel('')
    
    for ax in axes:
        ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    
    plt.suptitle('Comparative Drug Target Class Distribution by Disease Therapeutic Area\n(All Pipeline Discoveries)', 
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n2. Creating comparative heatmap...")
create_comparative_heatmap(cmap_expanded, tahoe_expanded, "heatmap_comparative.png")

# =============================================================================
# 3. BUBBLE CHART: Disease-Drug Relationship Strength (Intensity Colormaps)
# =============================================================================

def create_bubble_chart(df, title, filename, cmap_name):
    """Create bubble chart showing relationship strength with intensity colors"""
    
    # Count combinations
    combo_counts = df.groupby(['therapeutic_area', 'drug_target_class']).size().reset_index(name='count')
    
    # Get totals for sizing
    ta_totals = df['therapeutic_area'].value_counts()
    tc_totals = df['drug_target_class'].value_counts()
    
    # Top categories only for readability
    top_tas = ta_totals.head(10).index.tolist()
    top_tcs = tc_totals.head(8).index.tolist()
    
    combo_counts = combo_counts[
        combo_counts['therapeutic_area'].isin(top_tas) & 
        combo_counts['drug_target_class'].isin(top_tcs)
    ]
    
    # Create position mapping
    ta_pos = {ta: i for i, ta in enumerate(top_tas)}
    tc_pos = {tc: i for i, tc in enumerate(top_tcs)}
    
    combo_counts['x'] = combo_counts['drug_target_class'].map(tc_pos)
    combo_counts['y'] = combo_counts['therapeutic_area'].map(ta_pos)
    
    # Create figure
    fig, ax = plt.subplots(figsize=(14, 10))
    
    # Bubble sizes (scaled for larger dataset)
    sizes = combo_counts['count'] * 5  # Smaller multiplier for larger dataset
    sizes = np.clip(sizes, 50, 2000)  # Limit sizes
    
    # Use color to show intensity (count values)
    colors = combo_counts['count']
    
    scatter = ax.scatter(combo_counts['x'], combo_counts['y'], 
                        s=sizes, c=colors, cmap=cmap_name,
                        alpha=0.8, edgecolors='black', linewidths=1)
    
    # Colorbar to show intensity scale
    cbar = plt.colorbar(scatter, ax=ax, label='Number of Pairs', shrink=0.8)
    
    # Add count labels
    for _, row in combo_counts.iterrows():
        if row['count'] >= 20:  # Only label larger bubbles
            ax.annotate(str(row['count']), (row['x'], row['y']), 
                       ha='center', va='center', fontsize=8, fontweight='bold', color='white')
    
    # Customize axes
    ax.set_xticks(range(len(top_tcs)))
    ax.set_xticklabels(top_tcs, rotation=45, ha='right')
    ax.set_yticks(range(len(top_tas)))
    ax.set_yticklabels(top_tas)
    
    ax.set_xlabel('Drug Target Class', fontsize=12)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=12)
    ax.set_title(f'{title}\nBubble Size & Color = Number of Disease-Drug Pairs', fontsize=14, fontweight='bold')
    
    # Grid
    ax.set_axisbelow(True)
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n3. Creating bubble charts...")
create_bubble_chart(cmap_expanded, "CMAP All Discoveries", "bubble_cmap.png", 'YlOrRd')
create_bubble_chart(tahoe_expanded, "Tahoe All Discoveries", "bubble_tahoe.png", 'YlGnBu')

# =============================================================================
# 4. STACKED BAR CHART: Drug Target Distribution per Disease Area
# =============================================================================

def create_stacked_bar(df, title, filename, base_color):
    """Create stacked bar chart showing drug target distribution"""
    
    cross_tab = pd.crosstab(df['therapeutic_area'], df['drug_target_class'])
    
    # Sort by total
    cross_tab = cross_tab.loc[cross_tab.sum(axis=1).sort_values(ascending=False).head(15).index]
    
    # Normalize to percentages
    cross_tab_pct = cross_tab.div(cross_tab.sum(axis=1), axis=0) * 100
    
    # Sort columns by total
    col_order = cross_tab.sum().sort_values(ascending=False).index
    cross_tab_pct = cross_tab_pct[col_order]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # Generate color gradient based on base color
    if base_color == CMAP_COLOR:
        colors = plt.cm.Oranges(np.linspace(0.2, 0.9, len(cross_tab_pct.columns)))
    else:
        colors = plt.cm.Blues(np.linspace(0.2, 0.9, len(cross_tab_pct.columns)))
    
    cross_tab_pct.plot(kind='barh', stacked=True, ax=ax, color=colors, edgecolor='white', linewidth=0.5)
    
    ax.set_xlabel('Percentage (%)', fontsize=12)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=12)
    ax.set_title(f'{title}\nDrug Target Class Distribution (% within Disease Area)', fontsize=14, fontweight='bold')
    ax.legend(title='Drug Target Class', bbox_to_anchor=(1.02, 1), loc='upper left', fontsize=8)
    ax.set_xlim(0, 100)
    
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n4. Creating stacked bar charts...")
create_stacked_bar(cmap_expanded, "CMAP All Discoveries", "stacked_bar_cmap.png", CMAP_COLOR)
create_stacked_bar(tahoe_expanded, "Tahoe All Discoveries", "stacked_bar_tahoe.png", TAHOE_COLOR)

# =============================================================================
# 5. RADAR/SPIDER CHART: Disease Area Profiles (Panel + Individual)
# =============================================================================

def create_radar_chart(cmap_df, tahoe_df, filename):
    """Create radar chart comparing CMAP vs Tahoe drug target profiles"""
    
    # Get top therapeutic areas present in both
    cmap_tas = cmap_df['therapeutic_area'].value_counts()
    tahoe_tas = tahoe_df['therapeutic_area'].value_counts()
    
    common_tas = list(set(cmap_tas.head(12).index) & set(tahoe_tas.head(12).index))
    common_tas = sorted(common_tas)[:8]  # Limit for readability
    
    drug_classes = ['Enzyme', 'Membrane receptor', 'Transcription factor', 
                    'Ion channel', 'Transporter', 'Other']
    
    def get_profile(df, ta):
        subset = df[df['therapeutic_area'] == ta]
        counts = subset['drug_target_class'].value_counts()
        profile = []
        for dc in drug_classes[:-1]:
            profile.append(counts.get(dc, 0))
        # "Other" = everything else
        other = sum(counts.get(k, 0) for k in counts.index if k not in drug_classes[:-1])
        profile.append(other)
        # Normalize
        total = sum(profile)
        if total > 0:
            profile = [p/total * 100 for p in profile]
        return profile
    
    angles = np.linspace(0, 2*np.pi, len(drug_classes), endpoint=False).tolist()
    angles += angles[:1]  # Complete the circle
    
    # ----- INDIVIDUAL FIGURES for each disease area -----
    for ta in common_tas:
        fig_ind, ax_ind = plt.subplots(figsize=(8, 8), subplot_kw=dict(projection='polar'))
        
        cmap_profile = get_profile(cmap_df, ta) + [get_profile(cmap_df, ta)[0]]
        tahoe_profile = get_profile(tahoe_df, ta) + [get_profile(tahoe_df, ta)[0]]
        
        ax_ind.plot(angles, cmap_profile, 'o-', linewidth=2, label='CMAP', color=CMAP_COLOR, alpha=0.8)
        ax_ind.fill(angles, cmap_profile, alpha=0.25, color=CMAP_COLOR)
        ax_ind.plot(angles, tahoe_profile, 'o-', linewidth=2, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
        ax_ind.fill(angles, tahoe_profile, alpha=0.25, color=TAHOE_COLOR)
        
        ax_ind.set_xticks(angles[:-1])
        ax_ind.set_xticklabels(drug_classes, fontsize=9)
        ax_ind.set_title(f'{ta}\nDrug Target Class Profile', fontsize=12, fontweight='bold', pad=20)
        ax_ind.legend(loc='upper right', fontsize=10)
        
        safe_ta_name = ta.replace('/', '_').replace(' ', '_')[:30]
        plt.tight_layout()
        plt.savefig(f'{OUTPUT_DIR}/radar_{safe_ta_name}.png', dpi=300, bbox_inches='tight')
        plt.close()
    print(f"  Saved: {len(common_tas)} individual radar figures")
    
    # ----- COMBINED PANEL FIGURE -----
    fig, axes = plt.subplots(2, 4, figsize=(20, 10), subplot_kw=dict(projection='polar'))
    axes = axes.flatten()
    
    for idx, ta in enumerate(common_tas):
        ax = axes[idx]
        
        cmap_profile = get_profile(cmap_df, ta) + [get_profile(cmap_df, ta)[0]]
        tahoe_profile = get_profile(tahoe_df, ta) + [get_profile(tahoe_df, ta)[0]]
        
        ax.plot(angles, cmap_profile, 'o-', linewidth=2, label='CMAP', color=CMAP_COLOR, alpha=0.8)
        ax.fill(angles, cmap_profile, alpha=0.25, color=CMAP_COLOR)
        ax.plot(angles, tahoe_profile, 'o-', linewidth=2, label='Tahoe', color=TAHOE_COLOR, alpha=0.8)
        ax.fill(angles, tahoe_profile, alpha=0.25, color=TAHOE_COLOR)
        
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels([dc[:10] for dc in drug_classes], fontsize=7)
        ax.set_title(ta, fontsize=10, fontweight='bold', pad=10)
        
        if idx == 0:
            ax.legend(loc='upper right', fontsize=8)
    
    plt.suptitle('Drug Target Class Profiles by Disease Therapeutic Area\n(CMAP vs Tahoe - All Discoveries)', 
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n5. Creating radar charts...")
create_radar_chart(cmap_expanded, tahoe_expanded, "radar_comparison.png")

# =============================================================================
# 6. DIFFERENCE HEATMAP: Tahoe vs CMAP
# =============================================================================

def create_difference_heatmap(cmap_df, tahoe_df, filename):
    """Create heatmap showing differences between Tahoe and CMAP"""
    
    # Create normalized cross-tabulations
    cmap_ct = pd.crosstab(cmap_df['therapeutic_area'], cmap_df['drug_target_class'])
    tahoe_ct = pd.crosstab(tahoe_df['therapeutic_area'], tahoe_df['drug_target_class'])
    
    # Get union of categories
    all_tas = sorted(set(cmap_ct.index) | set(tahoe_ct.index))
    all_tcs = sorted(set(cmap_ct.columns) | set(tahoe_ct.columns))
    
    cmap_ct = cmap_ct.reindex(index=all_tas, columns=all_tcs, fill_value=0)
    tahoe_ct = tahoe_ct.reindex(index=all_tas, columns=all_tcs, fill_value=0)
    
    # Normalize
    cmap_norm = cmap_ct.div(cmap_ct.sum().sum()) * 100
    tahoe_norm = tahoe_ct.div(tahoe_ct.sum().sum()) * 100
    
    # Difference (Tahoe - CMAP)
    diff = tahoe_norm - cmap_norm
    
    # Sort by absolute difference
    row_order = diff.abs().sum(axis=1).sort_values(ascending=False).index
    col_order = diff.abs().sum(axis=0).sort_values(ascending=False).index
    diff = diff.loc[row_order, col_order]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(14, 10))
    
    # Diverging colormap: Orange (CMAP higher) -> White -> Blue (Tahoe higher)
    diff_cmap = LinearSegmentedColormap.from_list('diff_cmap', [CMAP_COLOR, 'white', TAHOE_COLOR])
    
    vmax = max(abs(diff.min().min()), abs(diff.max().max()))
    
    sns.heatmap(diff, annot=True, fmt='.1f', cmap=diff_cmap, center=0,
                linewidths=0.5, ax=ax, vmin=-vmax, vmax=vmax,
                cbar_kws={'label': 'Difference (Tahoe - CMAP) %'})
    
    ax.set_title('Tahoe vs CMAP: Differential Discovery Patterns\n(Blue = Tahoe Higher, Orange = CMAP Higher)', 
                 fontsize=14, fontweight='bold')
    ax.set_xlabel('Drug Target Class', fontsize=12)
    ax.set_ylabel('Disease Therapeutic Area', fontsize=12)
    
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n6. Creating difference heatmap...")
create_difference_heatmap(cmap_expanded, tahoe_expanded, "heatmap_difference.png")

# =============================================================================
# 7. SUMMARY DASHBOARD (Panel + Individual Components)
# =============================================================================

def create_summary_dashboard(cmap_df, tahoe_df, filename):
    """Create a summary dashboard with multiple small visualizations"""
    
    width = 0.35
    
    # ----- INDIVIDUAL COMPONENT FIGURES -----
    
    # 7a. Top Disease Areas Bar Chart
    fig1, ax1 = plt.subplots(figsize=(10, 8))
    cmap_tas = cmap_df['therapeutic_area'].value_counts().head(10)
    tahoe_tas = tahoe_df['therapeutic_area'].value_counts().head(10)
    all_tas = list(set(cmap_tas.index) | set(tahoe_tas.index))[:10]
    x = np.arange(len(all_tas))
    
    ax1.barh(x - width/2, [cmap_tas.get(ta, 0) for ta in all_tas], width, label='CMAP', color=CMAP_COLOR)
    ax1.barh(x + width/2, [tahoe_tas.get(ta, 0) for ta in all_tas], width, label='Tahoe', color=TAHOE_COLOR)
    ax1.set_yticks(x)
    ax1.set_yticklabels(all_tas, fontsize=9)
    ax1.set_xlabel('Count')
    ax1.set_title('Top Disease Therapeutic Areas\nCMAP vs Tahoe Comparison (All Discoveries)', fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.invert_yaxis()
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/bar_disease_areas.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/bar_disease_areas.png")
    
    # 7b. Top Drug Target Classes Bar Chart
    fig2, ax2 = plt.subplots(figsize=(10, 8))
    cmap_tcs = cmap_df['drug_target_class'].value_counts().head(8)
    tahoe_tcs = tahoe_df['drug_target_class'].value_counts().head(8)
    all_tcs = list(set(cmap_tcs.index) | set(tahoe_tcs.index))[:8]
    x = np.arange(len(all_tcs))
    
    ax2.barh(x - width/2, [cmap_tcs.get(tc, 0) for tc in all_tcs], width, label='CMAP', color=CMAP_COLOR)
    ax2.barh(x + width/2, [tahoe_tcs.get(tc, 0) for tc in all_tcs], width, label='Tahoe', color=TAHOE_COLOR)
    ax2.set_yticks(x)
    ax2.set_yticklabels(all_tcs, fontsize=9)
    ax2.set_xlabel('Count')
    ax2.set_title('Top Drug Target Classes\nCMAP vs Tahoe Comparison (All Discoveries)', fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.invert_yaxis()
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/bar_drug_classes.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/bar_drug_classes.png")
    
    # 7c. Pie charts - CMAP
    fig3, ax3 = plt.subplots(figsize=(10, 8))
    cmap_tc_counts = cmap_df['drug_target_class'].value_counts()
    colors_cmap = plt.cm.Oranges(np.linspace(0.3, 0.9, 6))
    ax3.pie(cmap_tc_counts.head(6), labels=cmap_tc_counts.head(6).index, autopct='%1.1f%%', colors=colors_cmap)
    ax3.set_title('CMAP: Drug Target Class Distribution (All Discoveries)', fontweight='bold', fontsize=14)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/pie_cmap_drug_classes.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/pie_cmap_drug_classes.png")
    
    # 7d. Pie charts - Tahoe
    fig4, ax4 = plt.subplots(figsize=(10, 8))
    tahoe_tc_counts = tahoe_df['drug_target_class'].value_counts()
    colors_tahoe = plt.cm.Blues(np.linspace(0.3, 0.9, 6))
    ax4.pie(tahoe_tc_counts.head(6), labels=tahoe_tc_counts.head(6).index, autopct='%1.1f%%', colors=colors_tahoe)
    ax4.set_title('Tahoe: Drug Target Class Distribution (All Discoveries)', fontweight='bold', fontsize=14)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/pie_tahoe_drug_classes.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/pie_tahoe_drug_classes.png")
    
    # 7e. Scatter: Diseases per area vs Drugs per area
    fig5, ax5 = plt.subplots(figsize=(10, 8))
    cmap_stats = cmap_df.groupby('therapeutic_area').agg({
        'disease_id': 'nunique',
        'drug_id': 'nunique'
    }).reset_index()
    tahoe_stats = tahoe_df.groupby('therapeutic_area').agg({
        'disease_id': 'nunique',
        'drug_id': 'nunique'
    }).reset_index()
    
    ax5.scatter(cmap_stats['disease_id'], cmap_stats['drug_id'], s=150, alpha=0.7, 
               label='CMAP', color=CMAP_COLOR, edgecolors='black', linewidths=1)
    ax5.scatter(tahoe_stats['disease_id'], tahoe_stats['drug_id'], s=150, alpha=0.7,
               label='Tahoe', color=TAHOE_COLOR, edgecolors='black', linewidths=1)
    ax5.set_xlabel('Unique Diseases', fontsize=12)
    ax5.set_ylabel('Unique Drugs', fontsize=12)
    ax5.set_title('Coverage: Diseases vs Drugs per Therapeutic Area\nCMAP vs Tahoe (All Discoveries)', fontweight='bold', fontsize=14)
    ax5.legend(fontsize=10)
    ax5.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/scatter_coverage.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/scatter_coverage.png")
    
    # 7f. Top Combinations Bar Chart
    fig6, ax6 = plt.subplots(figsize=(14, 8))
    cmap_combos = cmap_df.groupby(['therapeutic_area', 'drug_target_class']).size().sort_values(ascending=False).head(15)
    tahoe_combos = tahoe_df.groupby(['therapeutic_area', 'drug_target_class']).size().sort_values(ascending=False).head(15)
    
    combo_data = []
    for (ta, tc), count in cmap_combos.items():
        combo_data.append({'combo': f"{ta[:15]}\n→ {tc[:15]}", 'CMAP': count, 'Tahoe': 0})
    for (ta, tc), count in tahoe_combos.items():
        key = f"{ta[:15]}\n→ {tc[:15]}"
        found = False
        for item in combo_data:
            if item['combo'] == key:
                item['Tahoe'] = count
                found = True
                break
        if not found:
            combo_data.append({'combo': key, 'CMAP': 0, 'Tahoe': count})
    
    combo_df_plot = pd.DataFrame(combo_data).head(12)
    x = np.arange(len(combo_df_plot))
    
    ax6.bar(x - width/2, combo_df_plot['CMAP'], width, label='CMAP', color=CMAP_COLOR)
    ax6.bar(x + width/2, combo_df_plot['Tahoe'], width, label='Tahoe', color=TAHOE_COLOR)
    ax6.set_xticks(x)
    ax6.set_xticklabels(combo_df_plot['combo'], rotation=45, ha='right', fontsize=8)
    ax6.set_ylabel('Count')
    ax6.set_title('Top Disease → Drug Target Class Combinations (All Discoveries)', fontweight='bold', fontsize=14)
    ax6.legend(fontsize=10)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/bar_top_combinations.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/bar_top_combinations.png")
    
    # ----- COMBINED PANEL DASHBOARD -----
    fig = plt.figure(figsize=(20, 16))
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
    
    # 1. Top Disease Areas
    ax1 = fig.add_subplot(gs[0, 0])
    all_tas = list(set(cmap_tas.index) | set(tahoe_tas.index))[:10]
    x = np.arange(len(all_tas))
    ax1.barh(x - width/2, [cmap_tas.get(ta, 0) for ta in all_tas], width, label='CMAP', color=CMAP_COLOR)
    ax1.barh(x + width/2, [tahoe_tas.get(ta, 0) for ta in all_tas], width, label='Tahoe', color=TAHOE_COLOR)
    ax1.set_yticks(x)
    ax1.set_yticklabels(all_tas, fontsize=8)
    ax1.set_xlabel('Count')
    ax1.set_title('Top Disease Therapeutic Areas', fontweight='bold')
    ax1.legend(fontsize=8)
    ax1.invert_yaxis()
    
    # 2. Top Drug Target Classes
    ax2 = fig.add_subplot(gs[0, 1])
    all_tcs = list(set(cmap_tcs.index) | set(tahoe_tcs.index))[:8]
    x = np.arange(len(all_tcs))
    ax2.barh(x - width/2, [cmap_tcs.get(tc, 0) for tc in all_tcs], width, label='CMAP', color=CMAP_COLOR)
    ax2.barh(x + width/2, [tahoe_tcs.get(tc, 0) for tc in all_tcs], width, label='Tahoe', color=TAHOE_COLOR)
    ax2.set_yticks(x)
    ax2.set_yticklabels(all_tcs, fontsize=8)
    ax2.set_xlabel('Count')
    ax2.set_title('Top Drug Target Classes', fontweight='bold')
    ax2.legend(fontsize=8)
    ax2.invert_yaxis()
    
    # 3. Statistics
    ax3 = fig.add_subplot(gs[0, 2])
    ax3.axis('off')
    stats_text = f"""
    ALL DISCOVERIES STATISTICS
    
    CMAP (Orange):
      • Total pairs: {len(cmap_df)}
      • Unique diseases: {cmap_df['disease_id'].nunique()}
      • Unique drugs: {cmap_df['drug_id'].nunique()}
      • Disease areas: {cmap_df['therapeutic_area'].nunique()}
      • Drug classes: {cmap_df['drug_target_class'].nunique()}
    
    Tahoe (Blue):
      • Total pairs: {len(tahoe_df)}
      • Unique diseases: {tahoe_df['disease_id'].nunique()}
      • Unique drugs: {tahoe_df['drug_id'].nunique()}
      • Disease areas: {tahoe_df['therapeutic_area'].nunique()}
      • Drug classes: {tahoe_df['drug_target_class'].nunique()}
    
    Tahoe discovers {len(tahoe_df)/len(cmap_df):.1f}x more pairs
    """
    ax3.text(0.1, 0.9, stats_text, transform=ax3.transAxes, fontsize=10,
             verticalalignment='top', fontfamily='monospace',
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    ax3.set_title('Summary Statistics', fontweight='bold')
    
    # 4. Pie charts - CMAP
    ax4 = fig.add_subplot(gs[1, 0])
    ax4.pie(cmap_tc_counts.head(6), labels=cmap_tc_counts.head(6).index, autopct='%1.1f%%',
            colors=plt.cm.Oranges(np.linspace(0.3, 0.9, 6)))
    ax4.set_title('CMAP: Drug Target Classes', fontweight='bold')
    
    # 5. Pie charts - Tahoe
    ax5 = fig.add_subplot(gs[1, 1])
    ax5.pie(tahoe_tc_counts.head(6), labels=tahoe_tc_counts.head(6).index, autopct='%1.1f%%',
            colors=plt.cm.Blues(np.linspace(0.3, 0.9, 6)))
    ax5.set_title('Tahoe: Drug Target Classes', fontweight='bold')
    
    # 6. Scatter
    ax6 = fig.add_subplot(gs[1, 2])
    ax6.scatter(cmap_stats['disease_id'], cmap_stats['drug_id'], s=100, alpha=0.6, 
               label='CMAP', color=CMAP_COLOR, edgecolors='black')
    ax6.scatter(tahoe_stats['disease_id'], tahoe_stats['drug_id'], s=100, alpha=0.6,
               label='Tahoe', color=TAHOE_COLOR, edgecolors='black')
    ax6.set_xlabel('Unique Diseases')
    ax6.set_ylabel('Unique Drugs')
    ax6.set_title('Coverage: Diseases vs Drugs per Area', fontweight='bold')
    ax6.legend()
    
    # 7. Top Combinations
    ax7 = fig.add_subplot(gs[2, :])
    x = np.arange(len(combo_df_plot))
    ax7.bar(x - width/2, combo_df_plot['CMAP'], width, label='CMAP', color=CMAP_COLOR)
    ax7.bar(x + width/2, combo_df_plot['Tahoe'], width, label='Tahoe', color=TAHOE_COLOR)
    ax7.set_xticks(x)
    ax7.set_xticklabels(combo_df_plot['combo'], rotation=45, ha='right', fontsize=8)
    ax7.set_ylabel('Count')
    ax7.set_title('Top Disease → Drug Target Class Combinations', fontweight='bold')
    ax7.legend()
    
    plt.suptitle('Drug Repurposing All Discoveries: CMAP vs Tahoe Dashboard', 
                 fontsize=16, fontweight='bold', y=0.98)
    
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n7. Creating summary dashboard...")
create_summary_dashboard(cmap_expanded, tahoe_expanded, "dashboard_summary.png")

# =============================================================================
# 8. NETWORK-STYLE CHORD DIAGRAM
# =============================================================================

def create_chord_style(df, title, filename):
    """Create a chord-diagram style visualization using matplotlib
    
    Uses distinct colors:
    - Disease therapeutic areas: Red/Coral (#E74C3C)
    - Drug target classes: Green (#27AE60)
    """
    
    # Get top categories
    top_tas = df['therapeutic_area'].value_counts().head(8).index.tolist()
    top_tcs = df['drug_target_class'].value_counts().head(6).index.tolist()
    
    # Filter data
    filtered = df[df['therapeutic_area'].isin(top_tas) & df['drug_target_class'].isin(top_tcs)]
    
    # Create matrix
    matrix = pd.crosstab(filtered['therapeutic_area'], filtered['drug_target_class'])
    matrix = matrix.loc[top_tas, [tc for tc in top_tcs if tc in matrix.columns]]
    
    fig, ax = plt.subplots(figsize=(12, 12))
    
    n_tas = len(matrix.index)
    n_tcs = len(matrix.columns)
    
    # Position nodes on a circle
    ta_angles = np.linspace(np.pi/2 + 0.3, 3*np.pi/2 - 0.3, n_tas)
    tc_angles = np.linspace(-np.pi/2 + 0.3, np.pi/2 - 0.3, n_tcs)
    
    radius = 4
    
    # Plot disease area nodes (Red/Coral)
    ta_positions = {}
    for i, (ta, angle) in enumerate(zip(matrix.index, ta_angles)):
        x, y = radius * np.cos(angle), radius * np.sin(angle)
        ta_positions[ta] = (x, y)
        size = matrix.loc[ta].sum() * 0.5  # Scaled for larger dataset
        size = min(size, 3000)  # Cap size
        ax.scatter(x, y, s=size, c=DISEASE_AREA_COLOR, alpha=0.8, edgecolors='black', linewidths=2, zorder=3)
        
        ha = 'right' if x < 0 else 'left'
        ax.annotate(ta[:20], (x, y), xytext=(x - 0.5 if x < 0 else x + 0.5, y),
                   fontsize=9, ha=ha, va='center', fontweight='bold')
    
    # Plot drug class nodes (Green)
    tc_positions = {}
    for i, (tc, angle) in enumerate(zip(matrix.columns, tc_angles)):
        x, y = radius * np.cos(angle), radius * np.sin(angle)
        tc_positions[tc] = (x, y)
        size = matrix[tc].sum() * 0.5  # Scaled for larger dataset
        size = min(size, 3000)  # Cap size
        ax.scatter(x, y, s=size, c=DRUG_TARGET_COLOR, alpha=0.8, edgecolors='black', linewidths=2, zorder=3)
        
        ha = 'left' if x > 0 else 'right'
        ax.annotate(tc[:20], (x, y), xytext=(x + 0.5 if x > 0 else x - 0.5, y),
                   fontsize=9, ha=ha, va='center', fontweight='bold')
    
    # Draw connections
    max_val = matrix.values.max()
    for ta in matrix.index:
        for tc in matrix.columns:
            val = matrix.loc[ta, tc]
            if val > 0:
                x1, y1 = ta_positions[ta]
                x2, y2 = tc_positions[tc]
                
                linewidth = val / max_val * 8 + 0.5
                alpha = min(0.8, val / max_val + 0.2)
                
                ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                           arrowprops=dict(arrowstyle='-', color='gray', 
                                          alpha=alpha, linewidth=linewidth,
                                          connectionstyle='arc3,rad=0.2'))
    
    ax.set_xlim(-6, 6)
    ax.set_ylim(-6, 6)
    ax.set_aspect('equal')
    ax.axis('off')
    
    # Legend with distinct colors
    ax.scatter([], [], s=200, c=DISEASE_AREA_COLOR, label='Disease Therapeutic Area', edgecolors='black')
    ax.scatter([], [], s=200, c=DRUG_TARGET_COLOR, label='Drug Target Class', edgecolors='black')
    ax.legend(loc='upper left', fontsize=10)
    
    ax.set_title(f'{title}\nDisease-Drug Target Connections\n(Line thickness = Number of pairs)', 
                fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n8. Creating chord-style diagrams...")
create_chord_style(cmap_expanded, "CMAP All Discoveries", "chord_cmap.png")
create_chord_style(tahoe_expanded, "Tahoe All Discoveries", "chord_tahoe.png")

# =============================================================================
# 9. RANK DISTRIBUTION ANALYSIS (New for All Discoveries)
# =============================================================================

def create_rank_distribution(cmap_df, tahoe_df, filename):
    """Create analysis of drug rank distribution by target class"""
    
    fig, axes = plt.subplots(1, 2, figsize=(16, 6))
    
    # CMAP rank distribution
    ax1 = axes[0]
    cmap_rank_stats = cmap_df.groupby('drug_target_class')['drug_rank'].median().sort_values()
    top_classes = cmap_rank_stats.head(10).index
    cmap_subset = cmap_df[cmap_df['drug_target_class'].isin(top_classes)]
    cmap_subset.boxplot(column='drug_rank', by='drug_target_class', ax=ax1, vert=False)
    ax1.set_title('CMAP: Drug Rank Distribution by Target Class', fontweight='bold')
    ax1.set_xlabel('Drug Rank (lower = better)')
    ax1.set_ylabel('Drug Target Class')
    plt.suptitle('')  # Remove automatic title
    
    # Tahoe rank distribution
    ax2 = axes[1]
    tahoe_rank_stats = tahoe_df.groupby('drug_target_class')['drug_rank'].median().sort_values()
    top_classes = tahoe_rank_stats.head(10).index
    tahoe_subset = tahoe_df[tahoe_df['drug_target_class'].isin(top_classes)]
    tahoe_subset.boxplot(column='drug_rank', by='drug_target_class', ax=ax2, vert=False)
    ax2.set_title('Tahoe: Drug Rank Distribution by Target Class', fontweight='bold')
    ax2.set_xlabel('Drug Rank (lower = better)')
    ax2.set_ylabel('Drug Target Class')
    plt.suptitle('')  # Remove automatic title
    
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/{filename}', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  Saved: {OUTPUT_DIR}/{filename}")

print("\n9. Creating rank distribution analysis...")
create_rank_distribution(cmap_df, tahoe_df, "rank_distribution.png")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

print("\n" + "="*60)
print("VISUALIZATION COMPLETE - ALL DISCOVERIES")
print("="*60)
print("\nColor Convention:")
print(f"  • CMAP: Warm Orange ({CMAP_COLOR})")
print(f"  • Tahoe: Serene Blue ({TAHOE_COLOR})")
print("\nExceptions:")
print(f"  • Bubble Charts: YlOrRd (CMAP), YlGnBu (Tahoe) intensity colormaps")
print(f"  • Chord Diagrams: Red ({DISEASE_AREA_COLOR}) for diseases, Green ({DRUG_TARGET_COLOR}) for drug targets")
print(f"\nFiles created in {OUTPUT_DIR}/:")
print("  HEATMAPS:")
print("    - heatmap_cmap.png")
print("    - heatmap_tahoe.png")
print("    - heatmap_comparative.png (panel)")
print("    - heatmap_comparative_cmap.png (individual)")
print("    - heatmap_comparative_tahoe.png (individual)")
print("    - heatmap_difference.png")
print("  BUBBLE CHARTS:")
print("    - bubble_cmap.png")
print("    - bubble_tahoe.png")
print("  STACKED BARS:")
print("    - stacked_bar_cmap.png")
print("    - stacked_bar_tahoe.png")
print("  RADAR CHARTS:")
print("    - radar_comparison.png (panel)")
print("    - radar_[disease_area].png (8 individual)")
print("  DASHBOARD:")
print("    - dashboard_summary.png (panel)")
print("    - bar_disease_areas.png")
print("    - bar_drug_classes.png")
print("    - pie_cmap_drug_classes.png")
print("    - pie_tahoe_drug_classes.png")
print("    - scatter_coverage.png")
print("    - bar_top_combinations.png")
print("  CHORD DIAGRAMS:")
print("    - chord_cmap.png")
print("    - chord_tahoe.png")
print("  RANK ANALYSIS:")
print("    - rank_distribution.png")
print("="*60)
