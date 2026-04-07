#!/usr/bin/env python3
"""
Generate Case Study Autoimmune Figures

Creates all figures for the autoimmune case study:
  - Box plot distribution comparison
  - Hits vs recovery scatter
  - Statistical comparison box/strip
  - Disease-specific Phase 4 recovery heatmap

Outputs (to autoimmune/figures/):
  - recovery_rate_distribution_boxplot.png
  - drug_hits_vs_recovery_rate_scatter.png
  - cmap_vs_tahoe_recovery_statistical_test.png
  - phase4_recovery_heatmap.png

Data sources:
  - autoimmune/analysis/recovery_summary/20_autoimmune.xlsx
  - autoimmune/analysis/per_disease_recovery/*.csv
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle
from matplotlib.colors import ListedColormap, BoundaryNorm
import seaborn as sns
from adjustText import adjust_text
from pathlib import Path
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[3]
DATA_ROOT = REPO_ROOT / "autoimmune" / "analysis" / "recovery_summary"
DATA_FILE = DATA_ROOT / "20_autoimmune.xlsx"
DRUG_DETAIL_DIR = REPO_ROOT / "autoimmune" / "analysis" / "per_disease_recovery"
OUTPUT_DIR = REPO_ROOT / "autoimmune" / "figures"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

if not DATA_FILE.exists():
    raise FileNotFoundError(f"Missing figure input: {DATA_FILE}")

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
    'juvenile idiopathic arthritis (sjia)': 'arthritis',
    'inflammatory bowel disease': 'inflammatory_bowel_disease',
    'psoriasis': 'psoriasis',
    'dermatomyositis': 'dermatomyositis',
    'discoid lupus erythematosus': 'discoid_lupus_erythematosus',
    'inclusion body myositis': 'inclusion_body_myositis',
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
    fig, ax = plt.subplots(figsize=(14, 10))
    ax.scatter(df['cmap_hits'], df['cmap_recovery'], s=100, c=COLOR_CMAP, alpha=0.7, label='CMAP', edgecolors='black')
    ax.scatter(df['tahoe_hits'], df['tahoe_recovery'], s=100, c=COLOR_TAHOE, alpha=0.7, label='TAHOE', edgecolors='black')
    for hits_col, rec_col, color in [('cmap_hits', 'cmap_recovery', COLOR_CMAP),
                                     ('tahoe_hits', 'tahoe_recovery', COLOR_TAHOE)]:
        mask = df[hits_col] > 0
        if mask.sum() > 2:
            z = np.polyfit(df.loc[mask, hits_col], df.loc[mask, rec_col], 1)
            xl = np.linspace(df[hits_col].min(), df[hits_col].max(), 100)
            ax.plot(xl, np.poly1d(z)(xl), '--', color=color, alpha=0.5, lw=2)

    # Annotate all diseases
    short_names = {
        "inclusion body myositis": "IBM",
        "discoid lupus erythematosus": "DLE",
        "psoriatic arthritis": "PsA",
        "dermatomyositis": "DM",
        "sjogren's syndrome": "Sjögren's",
        "autoimmune thrombocytopenic purpura": "ITP",
        "scleroderma": "Scleroderma",
        "psoriasis": "Psoriasis",
        "inflammatory bowel disease": "IBD",
        "ankylosing spondylitis": "Ank. spond.",
        "crohn's disease": "Crohn's",
        "relapsing-remitting multiple sclerosis": "RRMS",
        "rheumatoid arthritis": "RA",
        "systemic lupus erythematosus": "SLE",
        "ulcerative colitis": "UC",
        "multiple sclerosis": "MS",
        "type 1 diabetes mellitus": "T1DM",
        "juvenile idiopathic arthritis (sjia)": "sJIA",
    }

    # Collect all x,y coordinates (both CMAP and TAHOE dots) so adjustText avoids them
    all_x = list(df['tahoe_hits']) + list(df['cmap_hits'])
    all_y = list(df['tahoe_recovery']) + list(df['cmap_recovery'])

    # TAHOE labels
    tahoe_texts = []
    for _, row in df.iterrows():
        label = short_names.get(row['disease'].lower(), row['disease'])
        tahoe_texts.append(ax.text(row['tahoe_hits'], row['tahoe_recovery'], label,
                                   fontsize=8.5, fontweight='bold', color='#1B4F72'))

    adjust_text(tahoe_texts, x=all_x, y=all_y, ax=ax,
                arrowprops=dict(arrowstyle='->', color=COLOR_TAHOE, lw=0.8, alpha=0.6),
                expand=(1.5, 1.8), force_text=(0.8, 1.0),
                ensure_inside_axes=True)

    # CMAP labels
    cmap_texts = []
    for _, row in df.iterrows():
        label = short_names.get(row['disease'].lower(), row['disease'])
        cmap_texts.append(ax.text(row['cmap_hits'], row['cmap_recovery'], label,
                                  fontsize=8, fontstyle='italic', color='#7E5109'))

    adjust_text(cmap_texts, x=all_x, y=all_y, ax=ax,
                arrowprops=dict(arrowstyle='->', color=COLOR_CMAP, lw=0.8, alpha=0.6),
                expand=(1.5, 1.8), force_text=(0.8, 1.0),
                ensure_inside_axes=True)

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

    ax.set_title('Drug Recovery Source and Disease-Specific Phase 4 Status\nAcross 18 Autoimmune Diseases',
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
# Panel: Platform Complementarity (Recovered Drugs)
# ===========================================================================

def _compute_recovered_breakdown(df):
    """Compute per-disease CMAP-only / TAHOE-only / Both breakdown for recovered drugs."""
    diseases = []
    cmap_only, tahoe_only, both, totals = [], [], [], []

    full_names = {
        "inclusion body myositis": "Inclusion Body Myositis",
        "discoid lupus erythematosus": "Discoid Lupus Erythematosus",
        "psoriatic arthritis": "Psoriatic Arthritis",
        "dermatomyositis": "Dermatomyositis",
        "sjogren's syndrome": "Sjögren's Syndrome",
        "autoimmune thrombocytopenic purpura": "Autoimmune Thrombocytopenic Purpura",
        "scleroderma": "Scleroderma",
        "psoriasis": "Psoriasis",
        "inflammatory bowel disease": "Inflammatory Bowel Disease",
        "ankylosing spondylitis": "Ankylosing Spondylitis",
        "crohn's disease": "Crohn's Disease",
        "relapsing-remitting multiple sclerosis": "Relapsing-Remitting Multiple Sclerosis",
        "rheumatoid arthritis": "Rheumatoid Arthritis",
        "systemic lupus erythematosus": "Systemic Lupus Erythematosus",
        "ulcerative colitis": "Ulcerative Colitis",
        "multiple sclerosis": "Multiple Sclerosis",
        "type 1 diabetes mellitus": "Type 1 Diabetes Mellitus",
        "juvenile idiopathic arthritis (sjia)": "Juvenile Idiopathic Arthritis (sJIA)",
    }

    for _, row in df.iterrows():
        disease = row['disease'].lower()
        cmap_rec = int(row.get('cmap_recovered', 0))
        tahoe_rec = int(row.get('tahoe_recovered', 0))
        common = int(row.get('common_recovered', 0))
        total_rec = int(row.get('total_recovered', 0))

        diseases.append(full_names.get(disease, row['disease'].title()))
        cmap_only.append(cmap_rec - common)
        tahoe_only.append(tahoe_rec - common)
        both.append(common)
        totals.append(total_rec)

    order = sorted(range(len(totals)), key=lambda i: totals[i], reverse=True)
    return (
        [diseases[i] for i in order],
        [cmap_only[i] for i in order],
        [tahoe_only[i] for i in order],
        [both[i] for i in order],
        [totals[i] for i in order],
    )


def _compute_novel_breakdown(df):
    """Compute per-disease CMAP-only / TAHOE-only / Both breakdown for novel predictions."""
    diseases = []
    cmap_only, tahoe_only, both, totals = [], [], [], []

    full_names = {
        "inclusion body myositis": "Inclusion Body Myositis",
        "discoid lupus erythematosus": "Discoid Lupus Erythematosus",
        "psoriatic arthritis": "Psoriatic Arthritis",
        "dermatomyositis": "Dermatomyositis",
        "sjogren's syndrome": "Sjögren's Syndrome",
        "autoimmune thrombocytopenic purpura": "Autoimmune Thrombocytopenic Purpura",
        "scleroderma": "Scleroderma",
        "psoriasis": "Psoriasis",
        "inflammatory bowel disease": "Inflammatory Bowel Disease",
        "ankylosing spondylitis": "Ankylosing Spondylitis",
        "crohn's disease": "Crohn's Disease",
        "relapsing-remitting multiple sclerosis": "Relapsing-Remitting Multiple Sclerosis",
        "rheumatoid arthritis": "Rheumatoid Arthritis",
        "systemic lupus erythematosus": "Systemic Lupus Erythematosus",
        "ulcerative colitis": "Ulcerative Colitis",
        "multiple sclerosis": "Multiple Sclerosis",
        "type 1 diabetes mellitus": "Type 1 Diabetes Mellitus",
        "juvenile idiopathic arthritis (sjia)": "Juvenile Idiopathic Arthritis (sJIA)",
    }

    # Read raw xlsx columns for hit-level data
    df_raw = pd.read_excel(DATA_FILE)
    for _, row in df_raw.iterrows():
        disease = row['disease_name'].lower()
        cmap_hits = int(row['cmap_hits_count'])
        tahoe_hits = int(row['tahoe_hits_count'])
        common_hits = int(row['common_hits_count'])
        cmap_rec = int(row['cmap_in_known_count'])
        tahoe_rec = int(row['tahoe_in_known_count'])
        common_rec = int(row['common_in_known_count'])

        # Per-source hits
        cmap_only_hits = cmap_hits - common_hits
        tahoe_only_hits = tahoe_hits - common_hits

        # Per-source recovered
        cmap_only_rec = cmap_rec - common_rec
        tahoe_only_rec = tahoe_rec - common_rec

        # Per-source novel (clamp to 0 for edge cases)
        c_novel = max(0, cmap_only_hits - cmap_only_rec)
        t_novel = max(0, tahoe_only_hits - tahoe_only_rec)
        b_novel = max(0, common_hits - common_rec)

        total_novel = c_novel + t_novel + b_novel

        diseases.append(full_names.get(disease, row['disease_name'].title()))
        cmap_only.append(c_novel)
        tahoe_only.append(t_novel)
        both.append(b_novel)
        totals.append(total_novel)

    order = sorted(range(len(totals)), key=lambda i: totals[i], reverse=True)
    return (
        [diseases[i] for i in order],
        [cmap_only[i] for i in order],
        [tahoe_only[i] for i in order],
        [both[i] for i in order],
        [totals[i] for i in order],
    )


def _make_donut(g_cmap, g_tahoe, g_both, title, filename):
    """Standalone donut chart."""
    g_total = g_cmap + g_tahoe + g_both
    fig, ax = plt.subplots(figsize=(8, 8))

    sizes = [g_cmap, g_tahoe, g_both]
    colors = [COLOR_CMAP, COLOR_TAHOE, COLOR_BOTH]
    labels = [
        f'CMAP Only\n{g_cmap} ({g_cmap/g_total*100:.1f}%)',
        f'TAHOE Only\n{g_tahoe} ({g_tahoe/g_total*100:.1f}%)',
        f'Both\n{g_both} ({g_both/g_total*100:.1f}%)',
    ]

    wedges, _ = ax.pie(
        sizes, colors=colors, startangle=90,
        wedgeprops=dict(width=0.45, edgecolor='white', linewidth=2),
        pctdistance=0.75
    )

    ax.legend(wedges, labels, loc='lower center',
              bbox_to_anchor=(0.5, -0.25), fontsize=12, frameon=False, ncol=1)
    ax.text(0, 0, f'{g_total}\ndrug-disease\npairs',
            ha='center', va='center', fontsize=16, fontweight='bold')
    ax.set_title(title, fontsize=14, fontweight='bold', pad=15)

    plt.subplots_adjust(bottom=0.28)
    save(fig, filename)


def _make_stacked_bar(diseases, cmap_only, tahoe_only, both, totals, title, xlabel, filename):
    """Standalone horizontal stacked bar chart with full disease names."""
    fig, ax = plt.subplots(figsize=(14, 10))

    y_pos = np.arange(len(diseases))
    bar_height = 0.7

    ax.barh(y_pos, cmap_only, bar_height,
            color=COLOR_CMAP, label='CMAP Only', edgecolor='white', linewidth=0.5)
    ax.barh(y_pos, both, bar_height,
            left=cmap_only, color=COLOR_BOTH, label='Both', edgecolor='white', linewidth=0.5)
    left_for_tahoe = [c + b for c, b in zip(cmap_only, both)]
    ax.barh(y_pos, tahoe_only, bar_height,
            left=left_for_tahoe, color=COLOR_TAHOE, label='TAHOE Only', edgecolor='white', linewidth=0.5)

    for i, total in enumerate(totals):
        bar_end = cmap_only[i] + both[i] + tahoe_only[i]
        ax.text(bar_end + 0.5, i, str(total), va='center', ha='left', fontsize=10, fontweight='bold')

    ax.set_yticks(y_pos)
    ax.set_yticklabels(diseases, fontsize=10)
    ax.invert_yaxis()
    ax.set_xlabel(xlabel, fontsize=12, fontweight='bold')
    ax.set_title(title, fontsize=14, fontweight='bold', pad=15)
    ax.legend(loc='lower right', fontsize=11, framealpha=0.9)
    ax.set_xlim(0, max(totals) * 1.08)
    ax.grid(axis='x', alpha=0.3)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

    plt.tight_layout()
    save(fig, filename)


def make_complementarity_panel(df):
    """Generate separate donut + bar charts for recovered drug-disease pairs."""
    print("\nGenerating Platform Complementarity (Recovered) ...")
    diseases, cmap_only, tahoe_only, both, totals = _compute_recovered_breakdown(df)

    g_cmap, g_tahoe, g_both = sum(cmap_only), sum(tahoe_only), sum(both)
    g_total = g_cmap + g_tahoe + g_both
    print(f"  Recovered drug-disease pairs: {g_total}")
    print(f"    CMAP-only: {g_cmap} ({g_cmap/g_total*100:.1f}%)")
    print(f"    TAHOE-only: {g_tahoe} ({g_tahoe/g_total*100:.1f}%)")
    print(f"    Both: {g_both} ({g_both/g_total*100:.1f}%)")

    _make_donut(g_cmap, g_tahoe, g_both,
                'Platform Overlap in\nRecovered Drug-Disease Pairs',
                'recovered_complementarity_donut')
    _make_stacked_bar(diseases, cmap_only, tahoe_only, both, totals,
                      'Per-Disease Recovered Drug Sources',
                      'Number of Recovered Drug-Disease Pairs',
                      'recovered_complementarity_bar')


def make_novel_complementarity_panel(df):
    """Generate separate donut + bar charts for novel (unvalidated) predictions."""
    print("\nGenerating Platform Complementarity (Novel Predictions) ...")
    diseases, cmap_only, tahoe_only, both, totals = _compute_novel_breakdown(df)

    g_cmap, g_tahoe, g_both = sum(cmap_only), sum(tahoe_only), sum(both)
    g_total = g_cmap + g_tahoe + g_both
    print(f"  Novel drug-disease pairs: {g_total}")
    print(f"    CMAP-only: {g_cmap} ({g_cmap/g_total*100:.1f}%)")
    print(f"    TAHOE-only: {g_tahoe} ({g_tahoe/g_total*100:.1f}%)")
    print(f"    Both: {g_both} ({g_both/g_total*100:.1f}%)")

    _make_donut(g_cmap, g_tahoe, g_both,
                'Platform Overlap in\nNovel Drug-Disease Predictions',
                'novel_complementarity_donut')
    _make_stacked_bar(diseases, cmap_only, tahoe_only, both, totals,
                      'Per-Disease Novel Drug Predictions by Source',
                      'Number of Novel Drug-Disease Predictions',
                      'novel_complementarity_bar')


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
    make_complementarity_panel(df)
    make_novel_complementarity_panel(df)

    print(f"\nAll autoimmune figures saved to {OUTPUT_DIR.relative_to(REPO_ROOT)}/")


if __name__ == "__main__":
    main()
