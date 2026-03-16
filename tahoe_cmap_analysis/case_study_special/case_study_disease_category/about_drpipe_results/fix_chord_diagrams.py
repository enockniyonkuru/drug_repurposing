"""
Regenerate chord diagrams with improved label positioning
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

from consistent_categories import expand_and_standardize, THERAPEUTIC_AREAS, DRUG_TARGET_CLASSES

# Colors
DISEASE_COLOR = '#E74C3C'
DRUG_TARGET_COLOR = '#27AE60'

# Load data
print("Loading data...")
cmap_rec = pd.read_csv('open_target_cmap_recovered.csv')
tahoe_rec = pd.read_csv('open_target_tahoe_recovered.csv')
cmap_all = pd.read_csv('all_discoveries_cmap.csv')
tahoe_all = pd.read_csv('all_discoveries_tahoe.csv')

# Expand
print("Expanding categories...")
cmap_rec_exp = expand_and_standardize(cmap_rec)
tahoe_rec_exp = expand_and_standardize(tahoe_rec)
cmap_all_exp = expand_and_standardize(cmap_all)
tahoe_all_exp = expand_and_standardize(tahoe_all)

# Combine to get top categories
all_data = pd.concat([cmap_rec_exp, tahoe_rec_exp, cmap_all_exp, tahoe_all_exp])
ta_counts = all_data['therapeutic_area'].value_counts()
tc_counts = all_data['drug_target_class_expanded'].value_counts()

SELECTED_TA = [ta for ta in THERAPEUTIC_AREAS if ta in ta_counts.index and ta != 'Other'][:12]
SELECTED_TC = [tc for tc in DRUG_TARGET_CLASSES if tc in tc_counts.index and tc != 'Other'][:10]

def create_consistent_crosstab(expanded_df):
    ct = pd.crosstab(expanded_df['therapeutic_area'], expanded_df['drug_target_class_expanded'])
    ct = ct.reindex(index=SELECTED_TA, columns=SELECTED_TC, fill_value=0)
    return ct

ct_cmap_rec = create_consistent_crosstab(cmap_rec_exp)
ct_tahoe_rec = create_consistent_crosstab(tahoe_rec_exp)
ct_cmap_all = create_consistent_crosstab(cmap_all_exp)
ct_tahoe_all = create_consistent_crosstab(tahoe_all_exp)

def create_chord_diagram(ct, title, filename):
    """Create chord-style network diagram with improved label positioning"""
    fig, ax = plt.subplots(figsize=(20, 20))
    
    disease_nodes = ct.index.tolist()
    drug_nodes = ct.columns.tolist()
    
    n_disease = len(disease_nodes)
    n_drug = len(drug_nodes)
    
    # Add padding to separate sections and spread nodes more
    padding = 0.2
    disease_angles = np.linspace(padding, np.pi - padding, n_disease)
    drug_angles = np.linspace(np.pi + padding, 2*np.pi - padding, n_drug)
    
    radius = 1.0
    label_radius = 1.35  # Labels even further out
    
    disease_sizes = ct.sum(axis=1)
    drug_sizes = ct.sum(axis=0)
    max_size = max(disease_sizes.max(), drug_sizes.max())
    
    # Draw connections first (behind nodes)
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
    
    # Draw disease nodes (top semicircle)
    for i, disease in enumerate(disease_nodes):
        x = radius * np.cos(disease_angles[i])
        y = radius * np.sin(disease_angles[i])
        size = 150 + (disease_sizes[disease] / max_size) * 600
        ax.scatter(x, y, s=size, c=DISEASE_COLOR, zorder=2, edgecolors='white', linewidth=2)
        
        # Label - positioned radially outward with rotation for readability
        lx = label_radius * np.cos(disease_angles[i])
        ly = label_radius * np.sin(disease_angles[i])
        
        # Determine alignment based on angle
        angle_deg = np.degrees(disease_angles[i])
        
        # For left side (angle > 90), right-align text
        # For right side (angle < 90), left-align text
        if angle_deg <= 90:
            ha = 'left'
            rotation = angle_deg - 10  # Slight rotation to follow the arc
        else:
            ha = 'right'
            rotation = angle_deg - 170  # Mirror rotation for left side
        
        ax.annotate(disease, (lx, ly), fontsize=10, ha=ha, va='center', fontweight='bold',
                   rotation=rotation, rotation_mode='anchor')
    
    # Draw drug nodes (bottom semicircle)
    for j, drug in enumerate(drug_nodes):
        x = radius * np.cos(drug_angles[j])
        y = radius * np.sin(drug_angles[j])
        size = 150 + (drug_sizes[drug] / max_size) * 600
        ax.scatter(x, y, s=size, c=DRUG_TARGET_COLOR, zorder=2, edgecolors='white', linewidth=2)
        
        # Label - positioned radially outward
        lx = label_radius * np.cos(drug_angles[j])
        ly = label_radius * np.sin(drug_angles[j])
        
        # Determine alignment based on angle
        angle_deg = np.degrees(drug_angles[j])
        
        # For left side of bottom (angle 180-270), right-align
        # For right side of bottom (angle 270-360), left-align  
        if angle_deg <= 270:
            ha = 'right'
            rotation = angle_deg + 10  # Slight rotation
        else:
            ha = 'left'
            rotation = angle_deg - 350  # Mirror rotation
        
        ax.annotate(drug, (lx, ly), fontsize=10, ha=ha, va='center', fontweight='bold',
                   rotation=rotation, rotation_mode='anchor')
    
    # Legend
    ax.scatter([], [], c=DISEASE_COLOR, s=200, label='Disease Areas (top)')
    ax.scatter([], [], c=DRUG_TARGET_COLOR, s=200, label='Drug Target Classes (bottom)')
    ax.legend(loc='upper left', fontsize=12, framealpha=0.9)
    
    ax.set_xlim(-2.2, 2.2)
    ax.set_ylim(-2.2, 2.2)
    ax.set_aspect('equal')
    ax.axis('off')
    ax.set_title(title, fontsize=16, fontweight='bold', pad=20)
    
    plt.tight_layout()
    plt.savefig(filename, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f'  Saved: {filename}')

print("Regenerating chord diagrams with improved labels...")
create_chord_diagram(ct_cmap_rec, 'CMAP Recovered: Disease-Drug Connections', 'figures_recovered/chord_cmap.png')
create_chord_diagram(ct_tahoe_rec, 'Tahoe Recovered: Disease-Drug Connections', 'figures_recovered/chord_tahoe.png')
create_chord_diagram(ct_cmap_all, 'CMAP All: Disease-Drug Connections', 'figures_everything/chord_cmap.png')
create_chord_diagram(ct_tahoe_all, 'Tahoe All: Disease-Drug Connections', 'figures_everything/chord_tahoe.png')
print("Done!")
