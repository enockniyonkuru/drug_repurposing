#!/usr/bin/env python3
"""
Compare CMAP and Tahoe Q-values Across Diseases

Visualizes statistical significance thresholds for drug hits across diseases.
Generates comparison plots and diagnostic summaries to assess pipeline quality
and identify systematic q-value distribution issues.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from typing import Dict, List, Tuple
import warnings
warnings.filterwarnings('ignore')

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 6)

def get_disease_list(results_dir: Path) -> List[str]:
    """Extract list of diseases from directory structure."""
    diseases = set()
    for item in results_dir.iterdir():
        if item.is_dir() and ('CMAP' in item.name or 'TAHOE' in item.name):
            # Extract disease name (everything before _CMAP or _TAHOE)
            disease = item.name.split('_CMAP_')[0].split('_TAHOE_')[0]
            diseases.add(disease)
    return sorted(list(diseases))

def load_results_file(disease: str, dataset: str, results_dir: Path) -> pd.DataFrame:
    """Load results file for a given disease and dataset (CMAP or TAHOE)."""
    # Find the directory
    pattern = f"{disease}_{dataset}_*"
    matching_dirs = list(results_dir.glob(pattern))
    
    if not matching_dirs:
        print(f"  ⚠️  No directory found for {disease} {dataset}")
        return None
    
    disease_dir = matching_dirs[0]
    
    # Find the CSV file
    csv_files = list(disease_dir.glob("*_hits_*.csv"))
    
    if not csv_files:
        print(f"  ⚠️  No CSV file found in {disease_dir.name}")
        return None
    
    csv_file = csv_files[0]
    
    try:
        df = pd.read_csv(csv_file)
        return df
    except Exception as e:
        print(f"  ⚠️  Error loading {csv_file.name}: {e}")
        return None

def compute_summary_stats(df: pd.DataFrame, disease: str, dataset: str) -> Dict:
    """Compute summary statistics for a dataset."""
    if df is None or len(df) == 0:
        return None
    
    stats = {
        'disease': disease,
        'dataset': dataset,
        'n_drugs': len(df),
        'pct_q0': (df['q'] == 0).mean() * 100,
        'pct_p0': (df['p'] == 0).mean() * 100,
        'mean_score': df['cmap_score'].mean(),
        'median_score': df['cmap_score'].median(),
        'std_score': df['cmap_score'].std(),
        'min_score': df['cmap_score'].min(),
        'max_score': df['cmap_score'].max(),
        'all_negative': (df['cmap_score'] < 0).all(),
        'all_positive': (df['cmap_score'] > 0).all(),
        'unique_p_values': df['p'].nunique(),
        'unique_q_values': df['q'].nunique()
    }
    
    return stats

def determine_issue_flag(cmap_stats: Dict, tahoe_stats: Dict) -> str:
    """Determine the issue flag based on statistics."""
    if cmap_stats is None and tahoe_stats is None:
        return "NO_DATA"
    
    if cmap_stats is None:
        return "NO_CMAP"
    
    if tahoe_stats is None:
        return "NO_TAHOE"
    
    cmap_q0 = cmap_stats['pct_q0']
    tahoe_q0 = tahoe_stats['pct_q0']
    
    if tahoe_q0 == 100 and cmap_q0 == 100:
        return "BOTH_FLAT"
    elif tahoe_q0 == 100 and cmap_q0 < 100:
        return "TAHOE_FLAT"
    elif cmap_q0 == 100 and tahoe_q0 < 100:
        return "CMAP_FLAT"
    else:
        return "HEALTHY"

def plot_disease_comparison(disease: str, cmap_df: pd.DataFrame, tahoe_df: pd.DataFrame, 
                           output_dir: Path):
    """Create comparison plots for a disease."""
    fig, axes = plt.subplots(2, 3, figsize=(18, 10))
    fig.suptitle(f'{disease} - CMAP vs TAHOE Comparison', fontsize=16, fontweight='bold')
    
    # Row 1: Connectivity Scores
    # CMAP histogram
    if cmap_df is not None:
        axes[0, 0].hist(cmap_df['cmap_score'], bins=40, edgecolor='black', 
                       alpha=0.7, color='steelblue')
        axes[0, 0].axvline(0, color='red', linestyle='--', linewidth=2)
        axes[0, 0].set_xlabel('Connectivity Score')
        axes[0, 0].set_ylabel('Frequency')
        axes[0, 0].set_title(f'CMAP Scores (n={len(cmap_df)})')
        axes[0, 0].text(0.02, 0.98, f'Mean: {cmap_df["cmap_score"].mean():.3f}',
                       transform=axes[0, 0].transAxes, verticalalignment='top',
                       bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    else:
        axes[0, 0].text(0.5, 0.5, 'No CMAP Data', ha='center', va='center',
                       transform=axes[0, 0].transAxes, fontsize=14)
        axes[0, 0].set_title('CMAP Scores')
    
    # TAHOE histogram
    if tahoe_df is not None:
        axes[0, 1].hist(tahoe_df['cmap_score'], bins=40, edgecolor='black', 
                       alpha=0.7, color='coral')
        axes[0, 1].axvline(0, color='red', linestyle='--', linewidth=2)
        axes[0, 1].set_xlabel('Connectivity Score')
        axes[0, 1].set_ylabel('Frequency')
        axes[0, 1].set_title(f'TAHOE Scores (n={len(tahoe_df)})')
        axes[0, 1].text(0.02, 0.98, f'Mean: {tahoe_df["cmap_score"].mean():.3f}',
                       transform=axes[0, 1].transAxes, verticalalignment='top',
                       bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    else:
        axes[0, 1].text(0.5, 0.5, 'No TAHOE Data', ha='center', va='center',
                       transform=axes[0, 1].transAxes, fontsize=14)
        axes[0, 1].set_title('TAHOE Scores')
    
    # Side-by-side comparison
    if cmap_df is not None and tahoe_df is not None:
        data_to_plot = [cmap_df['cmap_score'], tahoe_df['cmap_score']]
        bp = axes[0, 2].boxplot(data_to_plot, labels=['CMAP', 'TAHOE'], patch_artist=True)
        bp['boxes'][0].set_facecolor('steelblue')
        bp['boxes'][1].set_facecolor('coral')
        axes[0, 2].axhline(0, color='red', linestyle='--', linewidth=2, alpha=0.5)
        axes[0, 2].set_ylabel('Connectivity Score')
        axes[0, 2].set_title('Score Comparison')
        axes[0, 2].grid(True, alpha=0.3)
    else:
        axes[0, 2].text(0.5, 0.5, 'Insufficient Data', ha='center', va='center',
                       transform=axes[0, 2].transAxes, fontsize=14)
        axes[0, 2].set_title('Score Comparison')
    
    # Row 2: P-values and Q-values
    # CMAP p-values
    if cmap_df is not None:
        axes[1, 0].hist(cmap_df['p'], bins=50, edgecolor='black', 
                       alpha=0.7, color='steelblue')
        axes[1, 0].set_xlabel('P-value')
        axes[1, 0].set_ylabel('Frequency')
        axes[1, 0].set_title(f'CMAP P-values')
        axes[1, 0].set_xlim(-0.05, 1.05)
        pct_p0 = (cmap_df['p'] == 0).mean() * 100
        axes[1, 0].text(0.98, 0.98, f'P=0: {pct_p0:.1f}%',
                       transform=axes[1, 0].transAxes, verticalalignment='top',
                       horizontalalignment='right',
                       bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    else:
        axes[1, 0].text(0.5, 0.5, 'No CMAP Data', ha='center', va='center',
                       transform=axes[1, 0].transAxes, fontsize=14)
        axes[1, 0].set_title('CMAP P-values')
    
    # TAHOE p-values
    if tahoe_df is not None:
        axes[1, 1].hist(tahoe_df['p'], bins=50, edgecolor='black', 
                       alpha=0.7, color='coral')
        axes[1, 1].set_xlabel('P-value')
        axes[1, 1].set_ylabel('Frequency')
        axes[1, 1].set_title(f'TAHOE P-values')
        axes[1, 1].set_xlim(-0.05, 1.05)
        pct_p0 = (tahoe_df['p'] == 0).mean() * 100
        axes[1, 1].text(0.98, 0.98, f'P=0: {pct_p0:.1f}%',
                       transform=axes[1, 1].transAxes, verticalalignment='top',
                       horizontalalignment='right',
                       bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    else:
        axes[1, 1].text(0.5, 0.5, 'No TAHOE Data', ha='center', va='center',
                       transform=axes[1, 1].transAxes, fontsize=14)
        axes[1, 1].set_title('TAHOE P-values')
    
    # Q-value comparison
    if cmap_df is not None and tahoe_df is not None:
        cmap_q0 = (cmap_df['q'] == 0).mean() * 100
        tahoe_q0 = (tahoe_df['q'] == 0).mean() * 100
        
        categories = ['CMAP', 'TAHOE']
        q0_pcts = [cmap_q0, tahoe_q0]
        colors = ['steelblue', 'coral']
        
        bars = axes[1, 2].bar(categories, q0_pcts, color=colors, alpha=0.7, edgecolor='black')
        axes[1, 2].set_ylabel('% of Drugs with Q=0')
        axes[1, 2].set_title('Q-value = 0 Comparison')
        axes[1, 2].set_ylim(0, 105)
        axes[1, 2].axhline(100, color='red', linestyle='--', linewidth=2, alpha=0.5)
        
        # Add value labels on bars
        for bar, val in zip(bars, q0_pcts):
            height = bar.get_height()
            axes[1, 2].text(bar.get_x() + bar.get_width()/2., height,
                          f'{val:.1f}%', ha='center', va='bottom', fontweight='bold')
    else:
        axes[1, 2].text(0.5, 0.5, 'Insufficient Data', ha='center', va='center',
                       transform=axes[1, 2].transAxes, fontsize=14)
        axes[1, 2].set_title('Q-value Comparison')
    
    plt.tight_layout()
    
    # Save plot
    safe_disease_name = disease.replace('/', '_').replace(' ', '_')
    output_file = output_dir / f'{safe_disease_name}_comparison.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved plot: {output_file.name}")
    plt.close()

def main():
    """Main execution function."""
    print("\n" + "="*70)
    print("CMAP vs TAHOE Q-VALUE COMPARISON ANALYSIS")
    print("="*70)
    
    # Setup paths
    base_dir = Path(__file__).parent.parent
    results_dir = base_dir / 'results' / 'creeds_manual_disease_results_filtered'
    output_dir = base_dir / 'reports' / 'comparison_plots_creeds_manual_disease_results_filtered'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\nResults directory: {results_dir}")
    print(f"Output directory: {output_dir}")
    
    # Get list of diseases
    diseases = get_disease_list(results_dir)
    print(f"\nFound {len(diseases)} diseases to analyze:")
    for disease in diseases:
        print(f"  - {disease}")
    
    # Collect statistics for all diseases
    all_stats = []
    
    print("\n" + "="*70)
    print("PROCESSING DISEASES")
    print("="*70)
    
    for disease in diseases:
        print(f"\n📊 Processing: {disease}")
        print("-" * 70)
        
        # Load CMAP results
        print("  Loading CMAP results...")
        cmap_df = load_results_file(disease, 'CMAP', results_dir)
        cmap_stats = compute_summary_stats(cmap_df, disease, 'CMAP') if cmap_df is not None else None
        
        # Load TAHOE results
        print("  Loading TAHOE results...")
        tahoe_df = load_results_file(disease, 'TAHOE', results_dir)
        tahoe_stats = compute_summary_stats(tahoe_df, disease, 'TAHOE') if tahoe_df is not None else None
        
        # Determine issue flag
        issue_flag = determine_issue_flag(cmap_stats, tahoe_stats)
        
        # Add to collection
        if cmap_stats:
            cmap_stats['issue_flag'] = issue_flag
            all_stats.append(cmap_stats)
        
        if tahoe_stats:
            tahoe_stats['issue_flag'] = issue_flag
            all_stats.append(tahoe_stats)
        
        # Print summary
        if cmap_stats and tahoe_stats:
            print(f"  CMAP:  {cmap_stats['n_drugs']} drugs, {cmap_stats['pct_q0']:.1f}% q=0")
            print(f"  TAHOE: {tahoe_stats['n_drugs']} drugs, {tahoe_stats['pct_q0']:.1f}% q=0")
            print(f"  Issue Flag: {issue_flag}")
        
        # Create comparison plot
        print("  Creating comparison plot...")
        plot_disease_comparison(disease, cmap_df, tahoe_df, output_dir)
    
    # Create summary DataFrame
    summary_df = pd.DataFrame(all_stats)
    
    # Save summary table
    summary_file = base_dir / 'reports' / 'tahoe_cmap_qvalue_comparison_summary.csv'
    summary_df.to_csv(summary_file, index=False)
    print(f"\n✓ Saved summary table: {summary_file}")
    
    # Generate diagnostic summary
    print("\n" + "="*70)
    print("DIAGNOSTIC SUMMARY")
    print("="*70)
    
    # Count issue flags
    issue_counts = summary_df.groupby('issue_flag').size()
    
    print("\nIssue Flag Distribution:")
    print("-" * 70)
    for flag, count in issue_counts.items():
        print(f"  {flag}: {count} datasets")
    
    # Analyze by dataset type
    print("\nBy Dataset Type:")
    print("-" * 70)
    for dataset in ['CMAP', 'TAHOE']:
        dataset_df = summary_df[summary_df['dataset'] == dataset]
        if len(dataset_df) > 0:
            avg_q0 = dataset_df['pct_q0'].mean()
            n_flat = (dataset_df['pct_q0'] == 100).sum()
            print(f"  {dataset}:")
            print(f"    Average % q=0: {avg_q0:.1f}%")
            print(f"    Datasets with 100% q=0: {n_flat}/{len(dataset_df)}")
    
    # Key findings
    print("\nKey Findings:")
    print("-" * 70)
    
    tahoe_df = summary_df[summary_df['dataset'] == 'TAHOE']
    cmap_df = summary_df[summary_df['dataset'] == 'CMAP']
    
    tahoe_flat_count = (tahoe_df['pct_q0'] == 100).sum()
    cmap_flat_count = (cmap_df['pct_q0'] == 100).sum()
    
    print(f"  TAHOE datasets with 100% q=0: {tahoe_flat_count}/{len(tahoe_df)}")
    print(f"  CMAP datasets with 100% q=0: {cmap_flat_count}/{len(cmap_df)}")
    
    if tahoe_flat_count > 0 and cmap_flat_count == 0:
        print("\n  ⚠️  CONCLUSION: TAHOE-SPECIFIC ISSUE")
        print("      All TAHOE datasets have q=0 problem, but CMAP is fine.")
        print("      → Debug TAHOE permutation/FDR code")
    elif tahoe_flat_count > 0 and cmap_flat_count > 0:
        print("\n  ⚠️  CONCLUSION: GLOBAL PIPELINE ISSUE")
        print("      Both CMAP and TAHOE have q=0 problems.")
        print("      → Inspect disease signatures and FDR implementation")
    elif tahoe_flat_count == 0 and cmap_flat_count == 0:
        print("\n  ✓ CONCLUSION: NO SYSTEMATIC ISSUES")
        print("      Both datasets appear healthy.")
    else:
        print("\n  ⚠️  CONCLUSION: MIXED RESULTS")
        print("      Some datasets have issues. Review individual cases.")
    
    # Detailed table
    print("\n" + "="*70)
    print("DETAILED COMPARISON TABLE")
    print("="*70)
    print("\nTop diseases by TAHOE q=0 percentage:")
    tahoe_sorted = tahoe_df.sort_values('pct_q0', ascending=False).head(10)
    print(tahoe_sorted[['disease', 'n_drugs', 'pct_q0', 'pct_p0', 'mean_score']].to_string(index=False))
    
    print("\n" + "="*70)
    print("ANALYSIS COMPLETE")
    print("="*70)
    print(f"\nGenerated files:")
    print(f"  1. {summary_file.name}")
    print(f"  2. {len(diseases)} comparison plots in {output_dir.name}/")
    print()

if __name__ == '__main__':
    main()
