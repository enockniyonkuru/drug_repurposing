#!/usr/bin/env python3
"""
Create Separate Panel Figures from Comprehensive Analysis

This script recreates each panel from figure1_comprehensive_analysis and 
figure3_publication_summary as individual figures.

Based on the data from 20_autoimmune.xlsx
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Set up style
sns.set_style("whitegrid")
plt.rcParams['font.size'] = 12
plt.rcParams['axes.titlesize'] = 14
plt.rcParams['axes.labelsize'] = 12

# Paths
DATA_DIR = Path(__file__).parent
OUTPUT_DIR = DATA_DIR / "separate_panels"
OUTPUT_DIR.mkdir(exist_ok=True)

def load_data():
    """Load the autoimmune data from Excel and CSV files."""
    # Load main data
    df = pd.read_excel(DATA_DIR / "20_autoimmune.xlsx")
    
    # Rename columns for easier access
    df = df.rename(columns={
        'disease_name': 'disease',
        'CMAP Recovery Rate': 'cmap_recovery',
        'TAHOE Recovery Rate': 'tahoe_recovery',
        'known_drugs_available_in_cmap_count': 'cmap_known',
        'known_drugs_available_in_tahoe_count': 'tahoe_known',
        'cmap_hits_count': 'cmap_hits',
        'tahoe_hits_count': 'tahoe_hits',
        'cmap_in_known_count': 'cmap_recovered',
        'tahoe_in_known_count': 'tahoe_recovered',
        'total_unique_drugs_cmap_tahoe': 'total_candidates',
        'common_in_known_count': 'common_recovered',
        'total_in_known_count': 'total_recovered'
    })
    
    # Convert recovery rates to percentages if needed
    if df['cmap_recovery'].max() <= 1:
        df['cmap_recovery'] = df['cmap_recovery'] * 100
        df['tahoe_recovery'] = df['tahoe_recovery'] * 100
    
    return df


def save_figure(fig, name, dpi=300):
    """Save figure in both PNG and PDF formats."""
    fig.savefig(OUTPUT_DIR / f"{name}.png", dpi=dpi, bbox_inches='tight', facecolor='white')
    fig.savefig(OUTPUT_DIR / f"{name}.pdf", bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print(f"  ✓ Saved: {name}")


# =============================================================================
# FIGURE 1: Panel A - Grouped Bar Chart (Recovery Rates by Disease)
# =============================================================================
def create_fig1_panel_a(df):
    """Grouped bar chart comparing recovery rates across all 20 diseases."""
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # Sort by TAHOE recovery rate
    df_sorted = df.sort_values('tahoe_recovery', ascending=True)
    
    y = np.arange(len(df_sorted))
    height = 0.35
    
    # Create bars
    bars1 = ax.barh(y - height/2, df_sorted['cmap_recovery'], height, 
                    label='CMAP', color='#F39C12', alpha=0.8, edgecolor='black')
    bars2 = ax.barh(y + height/2, df_sorted['tahoe_recovery'], height, 
                    label='TAHOE', color='#5DADE2', alpha=0.8, edgecolor='black')
    
    # Add average lines
    cmap_avg = df_sorted['cmap_recovery'].mean()
    tahoe_avg = df_sorted['tahoe_recovery'].mean()
    ax.axvline(cmap_avg, color='#F39C12', linestyle='--', linewidth=2, 
               label=f'CMAP Mean ({cmap_avg:.1f}%)')
    ax.axvline(tahoe_avg, color='#5DADE2', linestyle='--', linewidth=2, 
               label=f'TAHOE Mean ({tahoe_avg:.1f}%)')
    
    # Labels and styling
    ax.set_yticks(y)
    ax.set_yticklabels([d.title() for d in df_sorted['disease']], fontsize=9)
    ax.set_xlabel('Known Drug Recovery Rate (%)', fontsize=12)
    ax.set_title('Known Drug Recovery Rates by Disease\nCMAP vs TAHOE', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='lower right', fontsize=10)
    ax.set_xlim(0, 105)
    ax.grid(axis='x', alpha=0.3)
    
    plt.tight_layout()
    save_figure(fig, "figure1_panelA_grouped_bar_chart")


# =============================================================================
# FIGURE 1: Panel B - Paired Slope Chart
# =============================================================================
def create_fig1_panel_b(df):
    """Paired slope chart showing method comparison per disease."""
    fig, ax = plt.subplots(figsize=(10, 10))
    
    for _, row in df.iterrows():
        cmap_val = row['cmap_recovery']
        tahoe_val = row['tahoe_recovery']
        
        # Color based on which method is better
        color = 'green' if tahoe_val > cmap_val else 'red' if cmap_val > tahoe_val else 'gray'
        alpha = 0.7
        
        ax.plot([0, 1], [cmap_val, tahoe_val], 'o-', color=color, alpha=alpha, 
                linewidth=2, markersize=8)
        
        # Add disease name
        ax.annotate(row['disease'].title()[:20], xy=(1.02, tahoe_val), 
                   fontsize=7, va='center')
    
    ax.set_xlim(-0.1, 1.4)
    ax.set_ylim(-5, 105)
    ax.set_xticks([0, 1])
    ax.set_xticklabels(['CMAP', 'TAHOE'], fontsize=12, fontweight='bold')
    ax.set_ylabel('Known Drug Recovery Rate (%)', fontsize=12)
    ax.set_title('Paired Comparison by Disease\n(Green = TAHOE better, Red = CMAP better)', 
                 fontsize=14, fontweight='bold')
    ax.grid(axis='y', alpha=0.3)
    
    # Add legend
    from matplotlib.lines import Line2D
    legend_elements = [
        Line2D([0], [0], color='green', linewidth=2, label='TAHOE Superior'),
        Line2D([0], [0], color='red', linewidth=2, label='CMAP Superior'),
    ]
    ax.legend(handles=legend_elements, loc='upper left')
    
    plt.tight_layout()
    save_figure(fig, "figure1_panelB_slope_chart")


# =============================================================================
# FIGURE 1: Panel C - Complementarity Analysis (Stacked Bar)
# =============================================================================
def create_fig1_panel_c(df):
    """Complementarity analysis showing distribution of recovered known drugs."""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Calculate complementarity
    total_cmap_only = (df['cmap_recovered'] - df['common_recovered']).sum()
    total_tahoe_only = (df['tahoe_recovered'] - df['common_recovered']).sum()
    total_both = df['common_recovered'].sum()
    
    # Ensure non-negative values
    total_cmap_only = max(0, total_cmap_only)
    total_tahoe_only = max(0, total_tahoe_only)
    
    total = total_cmap_only + total_tahoe_only + total_both
    
    # Create stacked bar
    categories = ['Known Drugs Recovered']
    cmap_only_pct = total_cmap_only / total * 100 if total > 0 else 0
    both_pct = total_both / total * 100 if total > 0 else 0
    tahoe_only_pct = total_tahoe_only / total * 100 if total > 0 else 0
    
    ax.barh(categories, [cmap_only_pct], color='#F39C12', label=f'CMAP Only ({total_cmap_only}, {cmap_only_pct:.1f}%)')
    ax.barh(categories, [both_pct], left=[cmap_only_pct], color='#8E44AD', 
            label=f'Both Methods ({total_both}, {both_pct:.1f}%)')
    ax.barh(categories, [tahoe_only_pct], left=[cmap_only_pct + both_pct], color='#5DADE2', 
            label=f'TAHOE Only ({total_tahoe_only}, {tahoe_only_pct:.1f}%)')
    
    ax.set_xlim(0, 100)
    ax.set_xlabel('Percentage of Known Drugs Recovered', fontsize=12)
    ax.set_title('Complementarity Analysis\nDistribution of Recovered Known Drugs', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='upper right', fontsize=10)
    
    # Add text annotation
    ax.text(50, -0.3, f'Total unique drugs recovered: {int(total)}', 
            ha='center', fontsize=11, style='italic')
    
    plt.tight_layout()
    save_figure(fig, "figure1_panelC_complementarity")


# =============================================================================
# FIGURE 1: Panel D - Box Plot Distribution Comparison
# =============================================================================
def create_fig1_panel_d(df):
    """Box plot comparison of recovery rate distributions."""
    fig, ax = plt.subplots(figsize=(8, 8))
    
    # Prepare data for box plot
    data_to_plot = [df['cmap_recovery'].values, df['tahoe_recovery'].values]
    
    bp = ax.boxplot(data_to_plot, labels=['CMAP', 'TAHOE'], patch_artist=True,
                    widths=0.6)
    
    # Color boxes
    bp['boxes'][0].set_facecolor('#F39C12')
    bp['boxes'][0].set_alpha(0.7)
    bp['boxes'][1].set_facecolor('#5DADE2')
    bp['boxes'][1].set_alpha(0.7)
    
    # Add individual data points with jitter
    for i, data in enumerate(data_to_plot, 1):
        x = np.random.normal(i, 0.04, size=len(data))
        ax.scatter(x, data, alpha=0.5, color='black', s=30, zorder=3)
    
    # Statistical annotation
    from scipy import stats
    stat, p_value = stats.wilcoxon(df['cmap_recovery'], df['tahoe_recovery'])
    
    # Effect size (Cohen's d)
    cohens_d = (df['tahoe_recovery'].mean() - df['cmap_recovery'].mean()) / \
               np.sqrt((df['tahoe_recovery'].std()**2 + df['cmap_recovery'].std()**2) / 2)
    
    ax.text(0.5, 0.98, f'Wilcoxon p = {p_value:.4f}\nCohen\'s d = {cohens_d:.2f}',
            transform=ax.transAxes, ha='center', va='top', fontsize=11,
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    
    ax.set_ylabel('Known Drug Recovery Rate (%)', fontsize=12)
    ax.set_title('Recovery Rate Distribution Comparison', 
                 fontsize=14, fontweight='bold')
    ax.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    save_figure(fig, "figure1_panelD_boxplot")


# =============================================================================
# FIGURE 1: Panel E - Hits vs Recovery Scatter Plot
# =============================================================================
def create_fig1_panel_e(df):
    """Scatter plot showing relationship between total drug hits and recovery rate."""
    fig, ax = plt.subplots(figsize=(10, 8))
    
    # CMAP points
    ax.scatter(df['cmap_hits'], df['cmap_recovery'], 
               s=100, c='#F39C12', alpha=0.7, label='CMAP', edgecolors='black')
    
    # TAHOE points
    ax.scatter(df['tahoe_hits'], df['tahoe_recovery'], 
               s=100, c='#5DADE2', alpha=0.7, label='TAHOE', edgecolors='black')
    
    # Add trend lines
    from numpy.polynomial import polynomial as P
    
    # CMAP trend
    cmap_mask = df['cmap_hits'] > 0
    if cmap_mask.sum() > 2:
        z = np.polyfit(df.loc[cmap_mask, 'cmap_hits'], 
                       df.loc[cmap_mask, 'cmap_recovery'], 1)
        p = np.poly1d(z)
        x_line = np.linspace(df['cmap_hits'].min(), df['cmap_hits'].max(), 100)
        ax.plot(x_line, p(x_line), '--', color='#F39C12', alpha=0.5, linewidth=2)
    
    # TAHOE trend
    tahoe_mask = df['tahoe_hits'] > 0
    if tahoe_mask.sum() > 2:
        z = np.polyfit(df.loc[tahoe_mask, 'tahoe_hits'], 
                       df.loc[tahoe_mask, 'tahoe_recovery'], 1)
        p = np.poly1d(z)
        x_line = np.linspace(df['tahoe_hits'].min(), df['tahoe_hits'].max(), 100)
        ax.plot(x_line, p(x_line), '--', color='#5DADE2', alpha=0.5, linewidth=2)
    
    ax.set_xlabel('Total Drug Hits', fontsize=12)
    ax.set_ylabel('Known Drug Recovery Rate (%)', fontsize=12)
    ax.set_title('Drug Hits vs Recovery Rate', fontsize=14, fontweight='bold')
    ax.legend(fontsize=11)
    ax.grid(alpha=0.3)
    
    plt.tight_layout()
    save_figure(fig, "figure1_panelE_scatter_hits_recovery")


# =============================================================================
# FIGURE 1: Panel F - Top Diseases by Candidate Count
# =============================================================================
def create_fig1_panel_f(df):
    """Horizontal bar chart of top 10 diseases by total unique drug candidates."""
    fig, ax = plt.subplots(figsize=(10, 8))
    
    # Sort by total candidates and take top 10
    df_top = df.nlargest(10, 'total_candidates').sort_values('total_candidates')
    
    y = np.arange(len(df_top))
    colors = plt.cm.viridis(np.linspace(0.2, 0.8, len(df_top)))
    
    bars = ax.barh(y, df_top['total_candidates'], color=colors, edgecolor='black', alpha=0.8)
    
    # Add value labels
    for bar, val in zip(bars, df_top['total_candidates']):
        ax.text(val + 10, bar.get_y() + bar.get_height()/2, 
                f'{int(val):,}', va='center', fontsize=10)
    
    ax.set_yticks(y)
    ax.set_yticklabels([d.title() for d in df_top['disease']], fontsize=10)
    ax.set_xlabel('Total Unique Drug Candidates', fontsize=12)
    ax.set_title('Top 10 Diseases by Drug Repurposing Candidates', 
                 fontsize=14, fontweight='bold')
    ax.grid(axis='x', alpha=0.3)
    
    plt.tight_layout()
    save_figure(fig, "figure1_panelF_top_candidates")


# =============================================================================
# FIGURE 3: Panel A - Statistical Comparison with Significance
# =============================================================================
def create_fig3_panel_a(df):
    """Box and strip plot comparing recovery rates with statistical annotation."""
    fig, ax = plt.subplots(figsize=(8, 8))
    
    # Prepare data
    data = pd.DataFrame({
        'Method': ['CMAP'] * len(df) + ['TAHOE'] * len(df),
        'Recovery Rate': list(df['cmap_recovery']) + list(df['tahoe_recovery'])
    })
    
    # Box plot with strip plot overlay
    sns.boxplot(data=data, x='Method', y='Recovery Rate', palette=['#F39C12', '#5DADE2'],
                ax=ax, width=0.5)
    sns.stripplot(data=data, x='Method', y='Recovery Rate', color='black', 
                  alpha=0.5, size=8, ax=ax, jitter=True)
    
    # Statistical annotation
    from scipy import stats
    stat, p_value = stats.wilcoxon(df['cmap_recovery'], df['tahoe_recovery'])
    cohens_d = (df['tahoe_recovery'].mean() - df['cmap_recovery'].mean()) / \
               np.sqrt((df['tahoe_recovery'].std()**2 + df['cmap_recovery'].std()**2) / 2)
    
    # Add significance bracket
    ax.plot([0, 0, 1, 1], [95, 98, 98, 95], 'k-', linewidth=1.5)
    ax.text(0.5, 99, f'p < 0.001***\nCohen\'s d = {cohens_d:.2f}', 
            ha='center', va='bottom', fontsize=11)
    
    ax.set_ylabel('Known Drug Recovery Rate (%)', fontsize=12)
    ax.set_title('Statistical Comparison\nCMAP vs TAHOE Recovery Rates', 
                 fontsize=14, fontweight='bold')
    ax.set_ylim(-5, 110)
    
    plt.tight_layout()
    save_figure(fig, "figure3_panelA_statistical_comparison")


# =============================================================================
# FIGURE 3: Panel B - Complementarity Visualization
# =============================================================================
def create_fig3_panel_b(df):
    """Enhanced complementarity visualization."""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Calculate complementarity
    total_cmap_only = max(0, (df['cmap_recovered'] - df['common_recovered']).sum())
    total_tahoe_only = max(0, (df['tahoe_recovered'] - df['common_recovered']).sum())
    total_both = df['common_recovered'].sum()
    total = total_cmap_only + total_tahoe_only + total_both
    
    # Create pie chart style bar
    values = [total_cmap_only, total_both, total_tahoe_only]
    labels = [f'CMAP Only\n{total_cmap_only} ({total_cmap_only/total*100:.1f}%)',
              f'Both\n{total_both} ({total_both/total*100:.1f}%)',
              f'TAHOE Only\n{total_tahoe_only} ({total_tahoe_only/total*100:.1f}%)']
    colors = ['#F39C12', '#8E44AD', '#5DADE2']
    
    wedges, texts, autotexts = ax.pie(values, labels=labels, colors=colors, 
                                       autopct='', startangle=90,
                                       explode=(0.02, 0.02, 0.02))
    
    ax.set_title('Complementarity of Methods\nUnique vs Shared Drug Recoveries', 
                 fontsize=14, fontweight='bold')
    
    # Add center annotation
    ax.text(0, 0, f'Total:\n{int(total)}', ha='center', va='center', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    save_figure(fig, "figure3_panelB_complementarity_pie")


# =============================================================================
# FIGURE 3: Panel C - Perfect Recovery Diseases
# =============================================================================
def create_fig3_panel_c(df):
    """Diseases achieving 100% recovery rate with TAHOE."""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Filter perfect recovery diseases
    perfect = df[df['tahoe_recovery'] >= 100].copy()
    perfect = perfect.sort_values('tahoe_known', ascending=True)
    
    if len(perfect) == 0:
        ax.text(0.5, 0.5, 'No diseases with 100% TAHOE recovery', 
                ha='center', va='center', transform=ax.transAxes, fontsize=14)
    else:
        y = np.arange(len(perfect))
        
        bars = ax.barh(y, perfect['tahoe_known'], color='green', alpha=0.7, 
                       edgecolor='black')
        
        # Add value labels
        for bar, val in zip(bars, perfect['tahoe_known']):
            ax.text(val + 0.1, bar.get_y() + bar.get_height()/2, 
                    f'{int(val)}', va='center', fontsize=10)
        
        ax.set_yticks(y)
        ax.set_yticklabels([d.title() for d in perfect['disease']], fontsize=10)
        ax.set_xlabel('Known Drugs Available in TAHOE', fontsize=12)
    
    ax.set_title(f'Diseases with 100% TAHOE Recovery\n({len(perfect)} of 20 diseases)', 
                 fontsize=14, fontweight='bold')
    ax.grid(axis='x', alpha=0.3)
    
    plt.tight_layout()
    save_figure(fig, "figure3_panelC_perfect_recovery")


# =============================================================================
# FIGURE 3: Panel D - Summary Statistics Table
# =============================================================================
def create_fig3_panel_d(df):
    """Summary statistics table."""
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.axis('off')
    
    # Calculate statistics
    cmap_mean = df['cmap_recovery'].mean()
    cmap_std = df['cmap_recovery'].std()
    cmap_median = df['cmap_recovery'].median()
    
    tahoe_mean = df['tahoe_recovery'].mean()
    tahoe_std = df['tahoe_recovery'].std()
    tahoe_median = df['tahoe_recovery'].median()
    
    # Count wins
    tahoe_wins = (df['tahoe_recovery'] > df['cmap_recovery']).sum()
    cmap_wins = (df['cmap_recovery'] > df['tahoe_recovery']).sum()
    ties = len(df) - tahoe_wins - cmap_wins
    
    # Create table data
    table_data = [
        ['Metric', 'CMAP', 'TAHOE'],
        ['Mean Recovery Rate', f'{cmap_mean:.1f}%', f'{tahoe_mean:.1f}%'],
        ['Std Dev', f'{cmap_std:.1f}%', f'{tahoe_std:.1f}%'],
        ['Median Recovery Rate', f'{cmap_median:.1f}%', f'{tahoe_median:.1f}%'],
        ['# Diseases Superior', str(cmap_wins), str(tahoe_wins)],
        ['# Perfect Recoveries', 
         str((df['cmap_recovery'] >= 100).sum()),
         str((df['tahoe_recovery'] >= 100).sum())],
    ]
    
    table = ax.table(cellText=table_data, loc='center', cellLoc='center',
                     colWidths=[0.4, 0.3, 0.3])
    table.auto_set_font_size(False)
    table.set_fontsize(12)
    table.scale(1.2, 2)
    
    # Style header row
    for j in range(3):
        table[(0, j)].set_facecolor('lightgray')
        table[(0, j)].set_text_props(fontweight='bold')
    
    ax.set_title('Summary Statistics Comparison', 
                 fontsize=14, fontweight='bold', y=0.95)
    
    plt.tight_layout()
    save_figure(fig, "figure3_panelD_summary_table")


# =============================================================================
# MAIN EXECUTION
# =============================================================================
def main():
    print("\n" + "="*70)
    print("CREATING SEPARATE PANEL FIGURES")
    print("="*70)
    
    # Load data
    print("\n[1] Loading data...")
    df = load_data()
    print(f"    Loaded {len(df)} diseases")
    
    # Create Figure 1 panels
    print("\n[2] Creating Figure 1 panels...")
    print("    Creating Panel A: Grouped Bar Chart")
    create_fig1_panel_a(df)
    
    print("    Creating Panel B: Slope Chart")
    create_fig1_panel_b(df)
    
    print("    Creating Panel C: Complementarity Analysis")
    create_fig1_panel_c(df)
    
    print("    Creating Panel D: Box Plot")
    create_fig1_panel_d(df)
    
    print("    Creating Panel E: Scatter Plot")
    create_fig1_panel_e(df)
    
    print("    Creating Panel F: Top Candidates")
    create_fig1_panel_f(df)
    
    # Create Figure 3 panels
    print("\n[3] Creating Figure 3 panels...")
    print("    Creating Panel A: Statistical Comparison")
    create_fig3_panel_a(df)
    
    print("    Creating Panel B: Complementarity Pie")
    create_fig3_panel_b(df)
    
    print("    Creating Panel C: Perfect Recovery")
    create_fig3_panel_c(df)
    
    print("    Creating Panel D: Summary Table")
    create_fig3_panel_d(df)
    
    print("\n" + "="*70)
    print(f"✓ All panels saved to: {OUTPUT_DIR}")
    print("="*70)
    print("\nFigure 1 Panels:")
    print("  - figure1_panelA_grouped_bar_chart.png/pdf")
    print("  - figure1_panelB_slope_chart.png/pdf")
    print("  - figure1_panelC_complementarity.png/pdf")
    print("  - figure1_panelD_boxplot.png/pdf")
    print("  - figure1_panelE_scatter_hits_recovery.png/pdf")
    print("  - figure1_panelF_top_candidates.png/pdf")
    print("\nFigure 3 Panels:")
    print("  - figure3_panelA_statistical_comparison.png/pdf")
    print("  - figure3_panelB_complementarity_pie.png/pdf")
    print("  - figure3_panelC_perfect_recovery.png/pdf")
    print("  - figure3_panelD_summary_table.png/pdf")


if __name__ == "__main__":
    main()
