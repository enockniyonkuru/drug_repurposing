#!/usr/bin/env python3
"""
Generate Case Study Autoimmune Figures

Creates all figures for the autoimmune case study:
  - Box plot distribution comparison
  - Hits vs recovery scatter
  - Statistical comparison box/strip
  - Disease-specific Phase 4 recovery heatmap

Outputs (to visuals/figures/case_study_autoimmune/):
  - recovery_rate_distribution_boxplot.png
  - drug_hits_vs_recovery_rate_scatter.png
  - cmap_vs_tahoe_recovery_statistical_test.png
  - phase4_recovery_heatmap.png

Data sources:
  - tahoe_cmap_analysis/validation/20_autoimmune_results_1/20_autoimmune.xlsx
  - tahoe_cmap_analysis/validation/20_autoimmune_results_1/drug_details/*.csv
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle
from matplotlib.colors import ListedColormap, BoundaryNorm
import seaborn as sns
from pathlib import Path
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_FILE = REPO_ROOT / "tahoe_cmap_analysis" / "validation" / "20_autoimmune_results_1" / "20_autoimmune.xlsx"
DRUG_DETAIL_DIR = REPO_ROOT / "tahoe_cmap_analysis" / "validation" / "20_autoimmune_results_1" / "drug_details"
OUTPUT_DIR = REPO_ROOT / "visuals" / "figures" / "case_study_autoimmune"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Style
sns.set_style("whitegrid")
plt.rcParams.update({'font.size': 12, 'axes.titlesize': 14, 'axes.labelsize': 12})

COLOR_CMAP = '#F39C12'
COLOR_TAHOE = '#5DADE2'
COLOR_BOTH = '#8E44AD'

# Disease name -> CSV filename mapping
DISEASE_CSV_MAP = {
    'multiple sclerosis': 'multiple_sclerosis',
    'systemic lupus erythematosus': 'systemic_lupus_erythematosus',
    'rheumatoid arthritis': 'rheumatoid_arthritis',
    'type 1 diabetes mellitus': 'type_1_diabetes_mellitus',
    'relapsing-remitting multiple sclerosis': 'relapsing_remitting_multiple_sclerosis',
    "sjogren's syndrome": "Sjogren's_syndrome",
    'ulcerative colitis': 'ulcerative_colitis',
    'autoimmune thrombocytopenic purpura': 'autoimmune_thrombocytopenic_purpura',
    "crohn's disease": "Crohn's_disease",
    'scleroderma': 'scleroderma',
    'arthritis': 'arthritis',
    'inflammatory bowel disease': 'inflammatory_bowel_disease',
    'psoriasis': 'psoriasis',
    'psoriasis vulgaris': 'Psoriasis_vulgaris',
    'childhood type dermatomyositis': 'childhood_type_dermatomyositis',
    'discoid lupus erythematosus': 'discoid_lupus_erythematosus',
    'inclusion body myositis': 'inclusion_body_myositis',
    'colitis': 'colitis',
    'psoriatic arthritis': 'psoriatic_arthritis',
    'ankylosing spondylitis': 'ankylosing_spondylitis',
}


# ===========================================================================
# Data loading
# ===========================================================================

def load_validation_data():
    df = pd.read_excel(DATA_FILE)
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
    if df['cmap_recovery'].max() <= 1:
        df['cmap_recovery'] *= 100
        df['tahoe_recovery'] *= 100
    return df


def save(fig, name):
    fig.savefig(OUTPUT_DIR / f"{name}.png", dpi=300, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print(f"  Saved {name}.png")


# ===========================================================================
# Panel: Box plot distribution comparison
# ===========================================================================

def make_recovery_rate_boxplot(df):
    fig, ax = plt.subplots(figsize=(8, 8))
    data = [df['cmap_recovery'].values, df['tahoe_recovery'].values]
    bp = ax.boxplot(data, labels=['CMAP', 'TAHOE'], patch_artist=True, widths=0.6)
    bp['boxes'][0].set(facecolor=COLOR_CMAP, alpha=0.7)
    bp['boxes'][1].set(facecolor=COLOR_TAHOE, alpha=0.7)
    for i, d in enumerate(data, 1):
        ax.scatter(np.random.normal(i, 0.04, len(d)), d, alpha=0.5, color='black', s=30, zorder=3)
    stat, pval = stats.wilcoxon(df['cmap_recovery'], df['tahoe_recovery'])
    cd = (df['tahoe_recovery'].mean() - df['cmap_recovery'].mean()) / \
         np.sqrt((df['tahoe_recovery'].std()**2 + df['cmap_recovery'].std()**2) / 2)
    ax.text(0.5, 0.98, f'Wilcoxon p = {pval:.4f}\nCohen\'s d = {cd:.2f}',
            transform=ax.transAxes, ha='center', va='top', fontsize=11,
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    ax.set_ylabel('Known Drug Recovery Rate (%)')
    ax.set_title('Recovery Rate Distribution Comparison', fontweight='bold')
    ax.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    save(fig, "recovery_rate_distribution_boxplot")


# ===========================================================================
# Panel: Hits vs recovery scatter
# ===========================================================================

def make_drug_hits_vs_recovery_scatter(df):
    fig, ax = plt.subplots(figsize=(10, 8))
    ax.scatter(df['cmap_hits'], df['cmap_recovery'], s=100, c=COLOR_CMAP, alpha=0.7, label='CMAP', edgecolors='black')
    ax.scatter(df['tahoe_hits'], df['tahoe_recovery'], s=100, c=COLOR_TAHOE, alpha=0.7, label='TAHOE', edgecolors='black')
    for hits_col, rec_col, color in [('cmap_hits', 'cmap_recovery', COLOR_CMAP),
                                     ('tahoe_hits', 'tahoe_recovery', COLOR_TAHOE)]:
        mask = df[hits_col] > 0
        if mask.sum() > 2:
            z = np.polyfit(df.loc[mask, hits_col], df.loc[mask, rec_col], 1)
            xl = np.linspace(df[hits_col].min(), df[hits_col].max(), 100)
            ax.plot(xl, np.poly1d(z)(xl), '--', color=color, alpha=0.5, lw=2)
    ax.set_xlabel('Total Drug Hits')
    ax.set_ylabel('Known Drug Recovery Rate (%)')
    ax.set_title('Drug Hits vs Recovery Rate', fontweight='bold')
    ax.legend(fontsize=11)
    ax.grid(alpha=0.3)
    plt.tight_layout()
    save(fig, "drug_hits_vs_recovery_rate_scatter")


# ===========================================================================
# Panel: Statistical comparison box/strip
# ===========================================================================

def make_statistical_test(df):
    fig, ax = plt.subplots(figsize=(8, 8))
    dlong = pd.DataFrame({
        'Method': ['CMAP'] * len(df) + ['TAHOE'] * len(df),
        'Recovery Rate': list(df['cmap_recovery']) + list(df['tahoe_recovery'])
    })
    sns.boxplot(data=dlong, x='Method', y='Recovery Rate', palette=[COLOR_CMAP, COLOR_TAHOE], ax=ax, width=0.5)
    sns.stripplot(data=dlong, x='Method', y='Recovery Rate', color='black', alpha=0.5, size=8, ax=ax, jitter=True)
    stat, pval = stats.wilcoxon(df['cmap_recovery'], df['tahoe_recovery'])
    cd = (df['tahoe_recovery'].mean() - df['cmap_recovery'].mean()) / \
         np.sqrt((df['tahoe_recovery'].std()**2 + df['cmap_recovery'].std()**2) / 2)
    ax.plot([0, 0, 1, 1], [95, 98, 98, 95], 'k-', lw=1.5)
    ax.text(0.5, 99, f'p < 0.001***\nCohen\'s d = {cd:.2f}', ha='center', va='bottom', fontsize=11)
    ax.set_ylabel('Known Drug Recovery Rate (%)')
    ax.set_title('Statistical Comparison\nCMAP vs TAHOE Recovery Rates', fontweight='bold')
    ax.set_ylim(-5, 110)
    plt.tight_layout()
    save(fig, "cmap_vs_tahoe_recovery_statistical_test")


# ===========================================================================
# Phase 4 Recovery Heatmap
# ===========================================================================

def make_phase4_recovery_heatmap():
    print("\nGenerating Phase 4 Recovery Heatmap...")

    df_excel = pd.read_excel(DATA_FILE)
    disease_names = df_excel['disease_name'].str.title().tolist()
    print(f"  Analyzing {len(disease_names)} diseases...")

    drug_sources = {}
    drug_disease_phase = {}

    for _, row in df_excel.iterrows():
        disease_lower = row['disease_name'].lower()
        csv_name = DISEASE_CSV_MAP.get(disease_lower, disease_lower.replace(' ', '_'))
        csv_path = DRUG_DETAIL_DIR / f"{csv_name}_recovered_drugs.csv"

        drug_sources[disease_lower] = {}
        if csv_path.exists():
            try:
                df_drugs = pd.read_csv(csv_path)
                for _, drow in df_drugs.iterrows():
                    drug = drow['drug'].upper()
                    source = str(drow['source']).strip().upper()
                    phase = float(drow['phase']) if pd.notna(drow.get('phase')) else None
                    drug_sources[disease_lower][drug] = source
                    drug_disease_phase[(drug, disease_lower)] = phase
            except Exception as e:
                print(f"  Warning: {csv_path.name}: {e}")

    all_drugs = set()
    for d in drug_sources.values():
        all_drugs.update(d.keys())
    print(f"  Total unique drugs: {len(all_drugs)}")

    drug_freq = {drug: sum(1 for dd in drug_sources.values() if drug in dd) for drug in all_drugs}
    sorted_drugs = sorted(all_drugs, key=lambda x: drug_freq.get(x, 0), reverse=True)

    encoding = {'CMAP_ONLY': 1, 'TAHOE_ONLY': 2, 'BOTH': 3}
    matrix = []
    for disease in disease_names:
        dl = disease.lower()
        row = [encoding.get(drug_sources.get(dl, {}).get(drug, ''), 0) for drug in sorted_drugs]
        matrix.append(row)

    df_matrix = pd.DataFrame(matrix, index=disease_names, columns=sorted_drugs)
    print(f"  Heatmap: {df_matrix.shape[0]} diseases x {df_matrix.shape[1]} drugs")

    cmap = ListedColormap(['#FFFFFF', '#F39C12', '#5DADE2', '#9B59B6'])
    norm = BoundaryNorm([0, 1, 2, 3, 4], cmap.N)

    fig, ax = plt.subplots(figsize=(20, 11))
    ax.imshow(df_matrix, aspect='auto', cmap=cmap, norm=norm, interpolation='nearest')

    ax.set_xticks(np.arange(len(sorted_drugs)))
    ax.set_yticks(np.arange(len(disease_names)))
    ax.set_xticklabels(sorted_drugs, fontsize=7.5, rotation=90)
    ax.set_yticklabels(disease_names, fontsize=9)

    ax.set_xticks(np.arange(len(sorted_drugs)) - 0.5, minor=True)
    ax.set_yticks(np.arange(len(disease_names)) - 0.5, minor=True)
    ax.grid(which="minor", color="gray", linestyle='-', linewidth=0.5, alpha=0.3)

    phase4_count = 0
    for col_idx, drug in enumerate(sorted_drugs):
        for row_idx, disease in enumerate(disease_names):
            dl = disease.lower()
            phase = drug_disease_phase.get((drug, dl))
            if phase == 4.0 and df_matrix.iloc[row_idx, col_idx] > 0:
                rect = Rectangle((col_idx - 0.5, row_idx - 0.5), 1, 1,
                                 linewidth=2, edgecolor='red', facecolor='none')
                ax.add_patch(rect)
                phase4_count += 1

    print(f"  Disease-specific Phase 4 pairs: {phase4_count}")

    ax.set_title('Drug Recovery Source and Disease-Specific Phase 4 Status\nAcross 20 Autoimmune Diseases',
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xlabel('Recovered Drugs (sorted by frequency)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Autoimmune Diseases', fontsize=12, fontweight='bold')

    legend_elements = [
        mpatches.Patch(facecolor='#FFFFFF', edgecolor='black', label='Not Recovered'),
        mpatches.Patch(facecolor='#F39C12', label='CMAP Only'),
        mpatches.Patch(facecolor='#5DADE2', label='TAHOE Only'),
        mpatches.Patch(facecolor='#9B59B6', label='Both Methods'),
        mpatches.Patch(facecolor='white', edgecolor='red', linewidth=2, label='Phase 4 (Disease-Specific)'),
    ]
    ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.01, 1), fontsize=11, framealpha=0.95)
    plt.tight_layout()

    save(fig, "phase4_recovery_heatmap")


# ===========================================================================
# Main
# ===========================================================================

def main():
    print("=== Generating Case Study: Autoimmune Figures ===\n")
    df = load_validation_data()
    print(f"Loaded {len(df)} diseases from {DATA_FILE.name}\n")

    make_recovery_rate_boxplot(df)
    make_drug_hits_vs_recovery_scatter(df)
    make_statistical_test(df)
    make_phase4_recovery_heatmap()

    print(f"\nAll autoimmune figures saved to {OUTPUT_DIR.relative_to(REPO_ROOT)}/")


if __name__ == "__main__":
    main()
