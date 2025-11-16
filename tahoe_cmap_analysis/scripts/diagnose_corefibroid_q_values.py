#!/usr/bin/env python3
"""
Diagnostic Analysis for CoreFibroid TAHOE Results
==================================================
This script performs diagnostic checks on the CoreFibroid TAHOE results
to investigate why all 379 drugs have q=0.

Part 1: Basic Diagnostic Checks
- Load and inspect the data
- Calculate basic statistics
- Plot distributions
- Generate summary table
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Set style for better-looking plots
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)

def load_corefibroid_data(filepath):
    """Load the CoreFibroid results file."""
    print(f"Loading data from: {filepath}")
    df = pd.read_csv(filepath)
    print(f"✓ Loaded {len(df)} rows")
    return df

def inspect_data_structure(df):
    """Inspect the data structure and columns."""
    print("\n" + "="*70)
    print("DATA STRUCTURE INSPECTION")
    print("="*70)
    
    print(f"\nDataFrame shape: {df.shape}")
    print(f"Number of drugs: {len(df)}")
    
    print("\nColumn names:")
    for col in df.columns:
        print(f"  - {col}")
    
    print("\nFirst few rows:")
    print(df[['name', 'cmap_score', 'p', 'q']].head(10))
    
    print("\nData types:")
    print(df[['cmap_score', 'p', 'q']].dtypes)
    
    return df

def calculate_basic_stats(df):
    """Calculate and display basic statistics."""
    print("\n" + "="*70)
    print("BASIC STATISTICS")
    print("="*70)
    
    stats_cols = ['cmap_score', 'p', 'q']
    
    print("\nDescriptive Statistics:")
    print("-" * 70)
    stats = df[stats_cols].describe()
    print(stats)
    
    print("\n\nDetailed Statistics:")
    print("-" * 70)
    for col in stats_cols:
        print(f"\n{col.upper()}:")
        print(f"  Min:    {df[col].min():.10f}")
        print(f"  Max:    {df[col].max():.10f}")
        print(f"  Mean:   {df[col].mean():.10f}")
        print(f"  Median: {df[col].median():.10f}")
        print(f"  Std:    {df[col].std():.10f}")
        print(f"  Unique values: {df[col].nunique()}")
    
    return stats

def check_q_values(df):
    """Analyze q-value distribution."""
    print("\n" + "="*70)
    print("Q-VALUE ANALYSIS")
    print("="*70)
    
    # Count drugs with q=0
    n_drugs = len(df)
    n_q0 = (df['q'] == 0).sum()
    percent_q0 = (n_q0 / n_drugs) * 100
    
    print(f"\nTotal drugs: {n_drugs}")
    print(f"Drugs with q=0: {n_q0}")
    print(f"Percentage with q=0: {percent_q0:.2f}%")
    
    # Check unique q-values
    unique_q = df['q'].unique()
    print(f"\nUnique q-values: {len(unique_q)}")
    print(f"Q-values: {sorted(unique_q)}")
    
    # Check p-values
    unique_p = df['p'].unique()
    print(f"\nUnique p-values: {len(unique_p)}")
    print(f"P-values: {sorted(unique_p)}")
    
    return n_drugs, n_q0, percent_q0

def plot_connectivity_score_distribution(df, output_dir):
    """Plot connectivity score distribution."""
    print("\n" + "="*70)
    print("PLOTTING CONNECTIVITY SCORE DISTRIBUTION")
    print("="*70)
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # Histogram
    axes[0, 0].hist(df['cmap_score'], bins=50, edgecolor='black', alpha=0.7)
    axes[0, 0].set_xlabel('Connectivity Score')
    axes[0, 0].set_ylabel('Frequency')
    axes[0, 0].set_title('Histogram of Connectivity Scores')
    axes[0, 0].axvline(0, color='red', linestyle='--', linewidth=2, label='Zero')
    axes[0, 0].legend()
    
    # KDE plot
    df['cmap_score'].plot(kind='kde', ax=axes[0, 1], linewidth=2)
    axes[0, 1].set_xlabel('Connectivity Score')
    axes[0, 1].set_ylabel('Density')
    axes[0, 1].set_title('KDE Plot of Connectivity Scores')
    axes[0, 1].axvline(0, color='red', linestyle='--', linewidth=2, label='Zero')
    axes[0, 1].legend()
    
    # Box plot
    axes[1, 0].boxplot(df['cmap_score'], vert=True)
    axes[1, 0].set_ylabel('Connectivity Score')
    axes[1, 0].set_title('Box Plot of Connectivity Scores')
    axes[1, 0].axhline(0, color='red', linestyle='--', linewidth=2)
    
    # Violin plot
    parts = axes[1, 1].violinplot([df['cmap_score']], positions=[1], 
                                   showmeans=True, showmedians=True)
    axes[1, 1].set_ylabel('Connectivity Score')
    axes[1, 1].set_title('Violin Plot of Connectivity Scores')
    axes[1, 1].axhline(0, color='red', linestyle='--', linewidth=2)
    axes[1, 1].set_xticks([1])
    axes[1, 1].set_xticklabels(['All Drugs'])
    
    plt.tight_layout()
    
    output_file = output_dir / 'connectivity_score_distribution.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"✓ Saved plot to: {output_file}")
    plt.close()
    
    # Print statistics
    print(f"\nConnectivity Score Statistics:")
    print(f"  Range: [{df['cmap_score'].min():.6f}, {df['cmap_score'].max():.6f}]")
    print(f"  All negative: {(df['cmap_score'] < 0).all()}")
    print(f"  All positive: {(df['cmap_score'] > 0).all()}")
    print(f"  Mixed signs: {(df['cmap_score'] < 0).any() and (df['cmap_score'] > 0).any()}")

def plot_pvalue_qvalue_distributions(df, output_dir):
    """Plot p-value and q-value distributions."""
    print("\n" + "="*70)
    print("PLOTTING P-VALUE AND Q-VALUE DISTRIBUTIONS")
    print("="*70)
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # P-value histogram
    axes[0, 0].hist(df['p'], bins=50, edgecolor='black', alpha=0.7, color='steelblue')
    axes[0, 0].set_xlabel('P-value')
    axes[0, 0].set_ylabel('Frequency')
    axes[0, 0].set_title('Histogram of P-values')
    axes[0, 0].set_xlim(-0.05, 1.05)
    
    # Q-value histogram
    axes[0, 1].hist(df['q'], bins=50, edgecolor='black', alpha=0.7, color='coral')
    axes[0, 1].set_xlabel('Q-value')
    axes[0, 1].set_ylabel('Frequency')
    axes[0, 1].set_title('Histogram of Q-values')
    axes[0, 1].set_xlim(-0.05, 1.05)
    
    # P-value vs Connectivity Score
    axes[1, 0].scatter(df['cmap_score'], df['p'], alpha=0.5, s=20)
    axes[1, 0].set_xlabel('Connectivity Score')
    axes[1, 0].set_ylabel('P-value')
    axes[1, 0].set_title('P-value vs Connectivity Score')
    axes[1, 0].axvline(0, color='red', linestyle='--', alpha=0.5)
    
    # Q-value vs Connectivity Score
    axes[1, 1].scatter(df['cmap_score'], df['q'], alpha=0.5, s=20, color='coral')
    axes[1, 1].set_xlabel('Connectivity Score')
    axes[1, 1].set_ylabel('Q-value')
    axes[1, 1].set_title('Q-value vs Connectivity Score')
    axes[1, 1].axvline(0, color='red', linestyle='--', alpha=0.5)
    
    plt.tight_layout()
    
    output_file = output_dir / 'pvalue_qvalue_distributions.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"✓ Saved plot to: {output_file}")
    plt.close()
    
    # Additional analysis
    print(f"\nP-value Analysis:")
    print(f"  100% are 0: {(df['p'] == 0).all()}")
    print(f"  Unique p-values: {df['p'].nunique()}")
    
    print(f"\nQ-value Analysis:")
    print(f"  100% are 0: {(df['q'] == 0).all()}")
    print(f"  Unique q-values: {df['q'].nunique()}")

def create_summary_table(df, n_drugs, n_q0, percent_q0, output_dir):
    """Create and save summary table."""
    print("\n" + "="*70)
    print("CREATING SUMMARY TABLE")
    print("="*70)
    
    summary = pd.DataFrame({
        'n_drugs': [n_drugs],
        'n_q0': [n_q0],
        'percent_q0': [percent_q0],
        'median_p': [df['p'].median()],
        'median_q': [df['q'].median()],
        'median_abs_score': [df['cmap_score'].abs().median()],
        'mean_score': [df['cmap_score'].mean()],
        'min_score': [df['cmap_score'].min()],
        'max_score': [df['cmap_score'].max()],
        'std_score': [df['cmap_score'].std()],
        'all_scores_negative': [(df['cmap_score'] < 0).all()],
        'all_p_zero': [(df['p'] == 0).all()],
        'all_q_zero': [(df['q'] == 0).all()]
    })
    
    output_file = output_dir / 'tahoe_corefibroid_summary.csv'
    summary.to_csv(output_file, index=False)
    print(f"✓ Saved summary table to: {output_file}")
    
    print("\nSummary Table:")
    print("-" * 70)
    print(summary.to_string(index=False))
    
    return summary

def generate_diagnostic_report(df, summary, output_dir):
    """Generate a comprehensive diagnostic report."""
    print("\n" + "="*70)
    print("GENERATING DIAGNOSTIC REPORT")
    print("="*70)
    
    report_lines = []
    report_lines.append("="*70)
    report_lines.append("COREFIBROID TAHOE RESULTS - DIAGNOSTIC REPORT")
    report_lines.append("="*70)
    report_lines.append("")
    
    report_lines.append("SUMMARY")
    report_lines.append("-"*70)
    report_lines.append(f"Total drugs analyzed: {summary['n_drugs'].values[0]}")
    report_lines.append(f"Drugs with q=0: {summary['n_q0'].values[0]}")
    report_lines.append(f"Percentage with q=0: {summary['percent_q0'].values[0]:.2f}%")
    report_lines.append("")
    
    report_lines.append("KEY FINDINGS")
    report_lines.append("-"*70)
    
    # Finding 1: All q-values are 0
    if summary['all_q_zero'].values[0]:
        report_lines.append("⚠️  FINDING 1: ALL q-values are exactly 0")
        report_lines.append("   This is highly unusual and suggests a potential issue.")
    
    # Finding 2: All p-values are 0
    if summary['all_p_zero'].values[0]:
        report_lines.append("⚠️  FINDING 2: ALL p-values are exactly 0")
        report_lines.append("   This indicates that all drugs are considered 'significant'")
        report_lines.append("   at the p-value level, which is suspicious.")
    
    # Finding 3: All connectivity scores are negative
    if summary['all_scores_negative'].values[0]:
        report_lines.append("⚠️  FINDING 3: ALL connectivity scores are NEGATIVE")
        report_lines.append("   Range: [{:.6f}, {:.6f}]".format(
            summary['min_score'].values[0], summary['max_score'].values[0]))
        report_lines.append("   This suggests all drugs have negative connectivity,")
        report_lines.append("   meaning they all reverse the disease signature.")
    
    # Finding 4: Score distribution
    report_lines.append("")
    report_lines.append("CONNECTIVITY SCORE DISTRIBUTION")
    report_lines.append("-"*70)
    report_lines.append(f"Mean: {summary['mean_score'].values[0]:.6f}")
    report_lines.append(f"Median (absolute): {summary['median_abs_score'].values[0]:.6f}")
    report_lines.append(f"Std Dev: {summary['std_score'].values[0]:.6f}")
    report_lines.append(f"Range: [{summary['min_score'].values[0]:.6f}, {summary['max_score'].values[0]:.6f}]")
    
    report_lines.append("")
    report_lines.append("INTERPRETATION")
    report_lines.append("-"*70)
    report_lines.append("The combination of:")
    report_lines.append("  1. All p-values = 0")
    report_lines.append("  2. All q-values = 0")
    report_lines.append("  3. All connectivity scores negative")
    report_lines.append("")
    report_lines.append("Suggests one of the following scenarios:")
    report_lines.append("")
    report_lines.append("A) PIPELINE BUG:")
    report_lines.append("   - The FDR correction step may not be working properly")
    report_lines.append("   - P-values being set to 0 artificially")
    report_lines.append("   - Q-values not being calculated correctly")
    report_lines.append("")
    report_lines.append("B) EXTREME SIGNAL:")
    report_lines.append("   - All drugs genuinely reverse the disease signature")
    report_lines.append("   - All effects are extremely significant")
    report_lines.append("   - This would be biologically unusual")
    report_lines.append("")
    report_lines.append("C) DATA ISSUE:")
    report_lines.append("   - Disease signature may be problematic")
    report_lines.append("   - Drug signatures may have systematic bias")
    report_lines.append("")
    
    report_lines.append("RECOMMENDATIONS")
    report_lines.append("-"*70)
    report_lines.append("1. Examine the raw p-value calculation code")
    report_lines.append("2. Check the FDR correction implementation")
    report_lines.append("3. Compare with other diseases in the same batch")
    report_lines.append("4. Verify the CoreFibroid disease signature")
    report_lines.append("5. Check if this pattern exists in CMAP results for CoreFibroid")
    report_lines.append("")
    
    report_lines.append("="*70)
    
    # Save report
    output_file = output_dir / 'diagnostic_report.txt'
    with open(output_file, 'w') as f:
        f.write('\n'.join(report_lines))
    
    print(f"✓ Saved diagnostic report to: {output_file}")
    
    # Print to console
    print("\n" + "\n".join(report_lines))

def main():
    """Main execution function."""
    print("\n" + "="*70)
    print("COREFIBROID TAHOE RESULTS - DIAGNOSTIC ANALYSIS")
    print("="*70)
    
    # Define paths
    base_dir = Path(__file__).parent.parent
    results_dir = base_dir / 'results' / 'sirota_lab_disease_results_filtered' / 'CoreFibroid_TAHOE_20251104-211901'
    input_file = results_dir / 'file548b7a92cce5_hits_logFC_0.00_q<0.50.csv'
    
    # Create output directory
    output_dir = base_dir / 'reports' / 'corefibroid_diagnostics'
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"\nOutput directory: {output_dir}")
    
    # Load data
    df = load_corefibroid_data(input_file)
    
    # Inspect data structure
    df = inspect_data_structure(df)
    
    # Calculate basic statistics
    stats = calculate_basic_stats(df)
    
    # Check q-values
    n_drugs, n_q0, percent_q0 = check_q_values(df)
    
    # Plot connectivity score distribution
    plot_connectivity_score_distribution(df, output_dir)
    
    # Plot p-value and q-value distributions
    plot_pvalue_qvalue_distributions(df, output_dir)
    
    # Create summary table
    summary = create_summary_table(df, n_drugs, n_q0, percent_q0, output_dir)
    
    # Generate diagnostic report
    generate_diagnostic_report(df, summary, output_dir)
    
    print("\n" + "="*70)
    print("ANALYSIS COMPLETE")
    print("="*70)
    print(f"\nAll outputs saved to: {output_dir}")
    print("\nGenerated files:")
    print("  1. connectivity_score_distribution.png")
    print("  2. pvalue_qvalue_distributions.png")
    print("  3. tahoe_corefibroid_summary.csv")
    print("  4. diagnostic_report.txt")
    print("\n")

if __name__ == '__main__':
    main()
