#!/usr/bin/env python3
"""
Create Drug Recovery Consistency Figures

Generates visualizations showing which drugs were recovered by CMAP, TAHOE, or both
for selected autoimmune diseases.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Paths
REPO_ROOT = Path(__file__).resolve().parents[3]
OUTPUT_DIR = REPO_ROOT / "autoimmune" / "analysis" / "per_disease_recovery"
FIGURES_DIR = REPO_ROOT / "autoimmune" / "figures"
FIGURES_DIR.mkdir(exist_ok=True, parents=True)

# Disease files
DISEASES = [
    "Sjogren's_syndrome",
    "Crohn's_disease",
    "multiple_sclerosis",
    "rheumatoid_arthritis",
    "type_1_diabetes_mellitus",
    "systemic_lupus_erythematosus"
]

DISEASE_LABELS = {
    "Sjogren's_syndrome": "Sjögren's Syndrome",
    "Crohn's_disease": "Crohn's Disease",
    "multiple_sclerosis": "Multiple Sclerosis",
    "rheumatoid_arthritis": "Rheumatoid Arthritis",
    "type_1_diabetes_mellitus": "Type 1 Diabetes Mellitus",
    "systemic_lupus_erythematosus": "Systemic Lupus Erythematosus"
}


def load_disease_data(disease):
    """Load recovered drugs data for a disease."""
    file_path = OUTPUT_DIR / f"{disease}_recovered_drugs.csv"
    if file_path.exists():
        return pd.read_csv(file_path)
    return None


def create_drug_recovery_figure(disease, df):
    """Create a figure showing recovered drugs for a disease."""
    fig, ax = plt.subplots(figsize=(12, max(6, len(df) * 0.4)))
    
    disease_label = DISEASE_LABELS.get(disease, disease.replace('_', ' ').title())
    
    # Sort by source then by phase
    df = df.sort_values(['source', 'phase'], ascending=[True, False])
    
    # Create y positions
    y_pos = np.arange(len(df))
    
    # Color mapping (CMAP: Warm Orange, TAHOE: Serene Blue, Both: Purple)
    colors = {'BOTH': '#8E44AD', 'CMAP_ONLY': '#F39C12', 'TAHOE_ONLY': '#5DADE2'}
    bar_colors = [colors[s] for s in df['source']]
    
    # Create horizontal bars - use CMAP score for CMAP_ONLY, TAHOE score for TAHOE_ONLY, average for BOTH
    scores = []
    for _, row in df.iterrows():
        if row['source'] == 'BOTH':
            score = (abs(row['cmap_score']) + abs(row['tahoe_score'])) / 2
        elif row['source'] == 'CMAP_ONLY':
            score = abs(row['cmap_score'])
        else:
            score = abs(row['tahoe_score'])
        scores.append(score)
    
    bars = ax.barh(y_pos, scores, color=bar_colors, alpha=0.8, edgecolor='black', height=0.7)
    
    # Add drug names and phase info
    for i, (_, row) in enumerate(df.iterrows()):
        phase_str = f"Phase {int(row['phase'])}" if pd.notna(row['phase']) else ""
        ax.text(-0.02, i, f"{row['drug']} ({phase_str})", ha='right', va='center', fontsize=9)
    
    # Styling
    ax.set_yticks([])
    ax.set_xlabel('|Connectivity Score|', fontsize=12)
    ax.set_title(f"Known Drugs Recovered for {disease_label}\nCMAP vs TAHOE Consistency", 
                 fontsize=14, fontweight='bold')
    ax.set_xlim(0, max(scores) * 1.1 if scores else 1)
    
    # Legend
    legend_patches = [
        mpatches.Patch(color='#8E44AD', label='Both Methods'),
        mpatches.Patch(color='#F39C12', label='CMAP Only'),
        mpatches.Patch(color='#5DADE2', label='TAHOE Only')
    ]
    ax.legend(handles=legend_patches, loc='lower right', fontsize=10)
    
    ax.invert_yaxis()
    ax.grid(axis='x', alpha=0.3)
    
    plt.tight_layout()
    
    # Save
    fig.savefig(FIGURES_DIR / f"{disease}_drug_recovery.png", dpi=300, bbox_inches='tight', facecolor='white')
    fig.savefig(FIGURES_DIR / f"{disease}_drug_recovery.pdf", bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print(f"  ✓ Saved: {disease}_drug_recovery")


def create_combined_summary_figure():
    """Create a combined summary figure for all diseases."""
    fig, axes = plt.subplots(2, 4, figsize=(20, 10))
    axes = axes.flatten()
    
    # Load summary
    summary_df = pd.read_csv(OUTPUT_DIR / "disease_recovery_summary.csv")
    
    # Plot 1: Stacked bar chart of drug sources
    ax = axes[0]
    diseases = summary_df['Disease']
    x = np.arange(len(diseases))
    width = 0.6
    
    ax.bar(x, summary_df['CMAP Only'], width, label='CMAP Only', color='#F39C12', alpha=0.8)
    ax.bar(x, summary_df['Both Methods'], width, bottom=summary_df['CMAP Only'], 
           label='Both Methods', color='#8E44AD', alpha=0.8)
    ax.bar(x, summary_df['TAHOE Only'], width, 
           bottom=summary_df['CMAP Only'] + summary_df['Both Methods'],
           label='TAHOE Only', color='#5DADE2', alpha=0.8)
    
    ax.set_xticks(x)
    ax.set_xticklabels([d.split()[0] for d in diseases], rotation=45, ha='right', fontsize=9)
    ax.set_ylabel('Number of Known Drugs Recovered')
    ax.set_title('Drug Recovery by Method', fontsize=12, fontweight='bold')
    ax.legend(fontsize=9)
    
    # Plot 2-7: Individual disease plots
    for i, disease in enumerate(DISEASES):
        ax = axes[i + 1]
        df = load_disease_data(disease)
        
        if df is None or len(df) == 0:
            ax.text(0.5, 0.5, f'No data for\n{DISEASE_LABELS.get(disease, disease)}', 
                   ha='center', va='center', transform=ax.transAxes)
            continue
        
        # Count by source
        source_counts = df['source'].value_counts()
        sources = ['CMAP_ONLY', 'BOTH', 'TAHOE_ONLY']
        counts = [source_counts.get(s, 0) for s in sources]
        colors = ['#F39C12', '#8E44AD', '#5DADE2']
        labels = ['CMAP\nOnly', 'Both', 'TAHOE\nOnly']
        
        bars = ax.bar(labels, counts, color=colors, alpha=0.8, edgecolor='black')
        
        # Add count labels
        for bar, count in zip(bars, counts):
            if count > 0:
                ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.2, 
                       str(count), ha='center', va='bottom', fontsize=11, fontweight='bold')
        
        ax.set_ylabel('Count')
        ax.set_title(DISEASE_LABELS.get(disease, disease), fontsize=11, fontweight='bold')
        ax.set_ylim(0, max(counts) * 1.3 if max(counts) > 0 else 1)
    
    # Hide unused subplot (8th position in 2x4 grid)
    axes[7].axis('off')
    
    plt.suptitle('Known Drug Recovery: CMAP vs TAHOE Consistency\nAcross Selected Autoimmune Diseases', 
                 fontsize=16, fontweight='bold', y=1.02)
    plt.tight_layout()
    
    fig.savefig(FIGURES_DIR / "combined_drug_recovery_summary.png", dpi=300, bbox_inches='tight', facecolor='white')
    fig.savefig(FIGURES_DIR / "combined_drug_recovery_summary.pdf", bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print("  ✓ Saved: combined_drug_recovery_summary")


def create_venn_style_figure():
    """Create a Venn-diagram style visualization for each disease."""
    fig, axes = plt.subplots(2, 3, figsize=(15, 8))
    axes = axes.flatten()
    
    for i, disease in enumerate(DISEASES):
        ax = axes[i]
        df = load_disease_data(disease)
        
        if df is None:
            continue
            
        source_counts = df['source'].value_counts()
        cmap_only = source_counts.get('CMAP_ONLY', 0)
        both = source_counts.get('BOTH', 0)
        tahoe_only = source_counts.get('TAHOE_ONLY', 0)
        
        # Simple circles representation
        from matplotlib.patches import Circle
        
        # CMAP circle (left) - Warm Orange
        circle1 = Circle((0.35, 0.5), 0.3, color='#F39C12', alpha=0.5)
        ax.add_patch(circle1)
        
        # TAHOE circle (right) - Serene Blue
        circle2 = Circle((0.65, 0.5), 0.3, color='#5DADE2', alpha=0.5)
        ax.add_patch(circle2)
        
        # Labels
        ax.text(0.2, 0.5, str(cmap_only), ha='center', va='center', fontsize=16, fontweight='bold')
        ax.text(0.5, 0.5, str(both), ha='center', va='center', fontsize=16, fontweight='bold', color='white')
        ax.text(0.8, 0.5, str(tahoe_only), ha='center', va='center', fontsize=16, fontweight='bold')
        
        ax.text(0.2, 0.15, 'CMAP', ha='center', fontsize=10)
        ax.text(0.8, 0.15, 'TAHOE', ha='center', fontsize=10)
        
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        ax.set_aspect('equal')
        ax.axis('off')
        ax.set_title(DISEASE_LABELS.get(disease, disease).split()[0], fontsize=11, fontweight='bold')
    
    plt.suptitle('Drug Recovery Overlap: CMAP vs TAHOE', fontsize=14, fontweight='bold')
    plt.tight_layout()
    
    fig.savefig(FIGURES_DIR / "venn_drug_recovery.png", dpi=300, bbox_inches='tight', facecolor='white')
    fig.savefig(FIGURES_DIR / "venn_drug_recovery.pdf", bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print("  ✓ Saved: venn_drug_recovery")


def create_drug_table_figure(disease):
    """Create a table-style figure showing drug details."""
    df = load_disease_data(disease)
    if df is None or len(df) == 0:
        return
    
    disease_label = DISEASE_LABELS.get(disease, disease.replace('_', ' ').title())
    
    # Prepare table data
    df = df.sort_values(['source', 'phase'], ascending=[True, False])
    
    fig, ax = plt.subplots(figsize=(14, max(4, len(df) * 0.35 + 2)))
    ax.axis('off')
    
    # Table data
    table_data = []
    for _, row in df.iterrows():
        source_label = {'BOTH': '✓ Both', 'CMAP_ONLY': 'CMAP', 'TAHOE_ONLY': 'TAHOE'}[row['source']]
        cmap_score = f"{row['cmap_score']:.4f}" if pd.notna(row['cmap_score']) else '-'
        tahoe_score = f"{row['tahoe_score']:.4f}" if pd.notna(row['tahoe_score']) else '-'
        phase = f"{int(row['phase'])}" if pd.notna(row['phase']) else '-'
        table_data.append([row['drug'], phase, source_label, cmap_score, tahoe_score])
    
    columns = ['Drug Name', 'Phase', 'Recovered By', 'CMAP Score', 'TAHOE Score']
    
    table = ax.table(cellText=table_data, colLabels=columns, loc='center', cellLoc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1.2, 1.5)
    
    # Style header
    for j in range(len(columns)):
        table[(0, j)].set_facecolor('#2c3e50')
        table[(0, j)].set_text_props(color='white', fontweight='bold')
    
    # Color code by source (CMAP: Warm Orange, TAHOE: Serene Blue, Both: Purple)
    for i, row in enumerate(df.iterrows(), 1):
        source = row[1]['source']
        if source == 'BOTH':
            color = '#D7BDE2'  # Light purple
        elif source == 'CMAP_ONLY':
            color = '#FAD7A0'  # Light orange
        else:
            color = '#AED6F1'  # Light blue
        for j in range(len(columns)):
            table[(i, j)].set_facecolor(color)
    
    ax.set_title(f'Known Drugs Recovered for {disease_label}', fontsize=14, fontweight='bold', pad=20)
    
    plt.tight_layout()
    fig.savefig(FIGURES_DIR / f"{disease}_drug_table.png", dpi=300, bbox_inches='tight', facecolor='white')
    fig.savefig(FIGURES_DIR / f"{disease}_drug_table.pdf", bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print(f"  ✓ Saved: {disease}_drug_table")


def main():
    print("\n" + "="*70)
    print("CREATING DRUG RECOVERY CONSISTENCY FIGURES")
    print("="*70)
    
    print("\n[1] Creating individual disease figures...")
    for disease in DISEASES:
        df = load_disease_data(disease)
        if df is not None and len(df) > 0:
            create_drug_recovery_figure(disease, df)
            create_drug_table_figure(disease)
        else:
            print(f"  ⚠️  No data for {disease}")
    
    print("\n[2] Creating combined summary figure...")
    create_combined_summary_figure()
    
    print("\n[3] Creating Venn-style figure...")
    create_venn_style_figure()
    
    print("\n" + "="*70)
    print(f"✓ All figures saved to: {FIGURES_DIR}")
    print("="*70)


if __name__ == "__main__":
    main()
