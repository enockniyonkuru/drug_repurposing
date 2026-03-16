#!/usr/bin/env python3
"""
Phase 3: Aggregate Statistics

This script:
1. Loads per-disease precision and recall results
2. Calculates comprehensive summary statistics
3. Creates comparison tables (CMAP vs TAHOE)
4. Exports summary data for visualization
"""

import pandas as pd
import numpy as np
from pathlib import Path
from scipy import stats

print("=" * 80)
print("PHASE 3: AGGREGATE STATISTICS")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "intermediate_data"
output_dir.mkdir(exist_ok=True)

# Load per-disease results
print("\nLoading per-disease results...")
cmap_results = pd.read_csv(output_dir / "cmap_precision_recall_per_disease.csv")
tahoe_results = pd.read_csv(output_dir / "tahoe_precision_recall_per_disease.csv")

print(f"✓ CMAP: {len(cmap_results)} diseases")
print(f"✓ TAHOE: {len(tahoe_results)} diseases")

# Function to calculate comprehensive statistics
def calc_stats(series, metric_name):
    """Calculate comprehensive statistics for a metric"""
    valid = series.dropna()
    
    stats_dict = {
        'Metric': metric_name,
        'N': len(valid),
        'Mean': valid.mean(),
        'SD': valid.std(),
        'Median': valid.median(),
        'Q1': valid.quantile(0.25),
        'Q3': valid.quantile(0.75),
        'Min': valid.min(),
        'Max': valid.max(),
        'IQR': valid.quantile(0.75) - valid.quantile(0.25),
        'P5': valid.quantile(0.05),
        'P95': valid.quantile(0.95),
        'Skewness': valid.skew(),
        'Kurtosis': valid.kurtosis()
    }
    return stats_dict

# Calculate statistics
print("\n" + "=" * 80)
print("CALCULATING STATISTICS")
print("=" * 80)

summary_stats = []

# CMAP Precision
cmap_prec_stats = calc_stats(cmap_results['Precision_%'], 'CMAP Precision (%)')
summary_stats.append(cmap_prec_stats)

# CMAP Recall
cmap_recall_stats = calc_stats(cmap_results['Recall_%'], 'CMAP Recall (%)')
summary_stats.append(cmap_recall_stats)

# TAHOE Precision
tahoe_prec_stats = calc_stats(tahoe_results['Precision_%'], 'TAHOE Precision (%)')
summary_stats.append(tahoe_prec_stats)

# TAHOE Recall
tahoe_recall_stats = calc_stats(tahoe_results['Recall_%'], 'TAHOE Recall (%)')
summary_stats.append(tahoe_recall_stats)

summary_df = pd.DataFrame(summary_stats)
summary_df.to_csv(output_dir / "summary_statistics.csv", index=False)
print(f"\n✓ Saved to: {output_dir / 'summary_statistics.csv'}")

# Print summary
print("\n" + "=" * 80)
print("SUMMARY STATISTICS")
print("=" * 80)

for _, row in summary_df.iterrows():
    print(f"\n{row['Metric']}:")
    print(f"  N:       {row['N']:.0f}")
    print(f"  Mean:    {row['Mean']:.2f} ± {row['SD']:.2f}")
    print(f"  Median:  {row['Median']:.2f}")
    print(f"  Q1-Q3:   {row['Q1']:.2f} - {row['Q3']:.2f}")
    print(f"  Min-Max: {row['Min']:.2f} - {row['Max']:.2f}")

# Create platform comparison
print("\n" + "=" * 80)
print("PLATFORM COMPARISON")
print("=" * 80)

comparison_data = {
    'Metric': ['Precision (%)', 'Recall (%)'],
    'CMAP_Mean': [
        cmap_results['Precision_%'].mean(),
        cmap_results['Recall_%'].mean()
    ],
    'CMAP_SD': [
        cmap_results['Precision_%'].std(),
        cmap_results['Recall_%'].std()
    ],
    'CMAP_Median': [
        cmap_results['Precision_%'].median(),
        cmap_results['Recall_%'].median()
    ],
    'TAHOE_Mean': [
        tahoe_results['Precision_%'].mean(),
        tahoe_results['Recall_%'].mean()
    ],
    'TAHOE_SD': [
        tahoe_results['Precision_%'].std(),
        tahoe_results['Recall_%'].std()
    ],
    'TAHOE_Median': [
        tahoe_results['Precision_%'].median(),
        tahoe_results['Recall_%'].median()
    ]
}

comparison_df = pd.DataFrame(comparison_data)

# Add statistical tests (t-test)
from scipy.stats import ttest_ind

cmap_prec_valid = cmap_results['Precision_%'].dropna()
tahoe_prec_valid = tahoe_results['Precision_%'].dropna()
t_prec, p_prec = ttest_ind(cmap_prec_valid, tahoe_prec_valid, nan_policy='omit')

cmap_recall_valid = cmap_results['Recall_%'].dropna()
tahoe_recall_valid = tahoe_results['Recall_%'].dropna()
t_recall, p_recall = ttest_ind(cmap_recall_valid, tahoe_recall_valid, nan_policy='omit')

comparison_df['Precision_ttest_p'] = [p_prec, np.nan]
comparison_df['Recall_ttest_p'] = [np.nan, p_recall]

comparison_df.to_csv(output_dir / "platform_comparison.csv", index=False)
print(f"\n✓ Saved to: {output_dir / 'platform_comparison.csv'}")

print("\nPlatform Comparison:")
print(f"\nPrecision (%):")
print(f"  CMAP:  {cmap_results['Precision_%'].mean():.2f} ± {cmap_results['Precision_%'].std():.2f}")
print(f"  TAHOE: {tahoe_results['Precision_%'].mean():.2f} ± {tahoe_results['Precision_%'].std():.2f}")
print(f"  t-test p-value: {p_prec:.4f}")

print(f"\nRecall (%):")
print(f"  CMAP:  {cmap_results['Recall_%'].mean():.2f} ± {cmap_results['Recall_%'].std():.2f}")
print(f"  TAHOE: {tahoe_results['Recall_%'].mean():.2f} ± {tahoe_results['Recall_%'].std():.2f}")
print(f"  t-test p-value: {p_recall:.4f}")

# Additional analyses
print("\n" + "=" * 80)
print("ADDITIONAL ANALYSES")
print("=" * 80)

# Precision > threshold
thresholds = [25, 50, 75]
for thresh in thresholds:
    cmap_pct = (cmap_results['Precision_%'] > thresh).sum() / len(cmap_results) * 100
    tahoe_pct = (tahoe_results['Precision_%'] > thresh).sum() / len(tahoe_results) * 100
    print(f"\nPrecision > {thresh}%:")
    print(f"  CMAP:  {cmap_pct:.1f}%")
    print(f"  TAHOE: {tahoe_pct:.1f}%")

# Recall > threshold
for thresh in [10, 20, 30]:
    cmap_pct = (cmap_results['Recall_%'] > thresh).sum() / len(cmap_results) * 100
    tahoe_pct = (tahoe_results['Recall_%'] > thresh).sum() / len(tahoe_results) * 100
    print(f"\nRecall > {thresh}%:")
    print(f"  CMAP:  {cmap_pct:.1f}%")
    print(f"  TAHOE: {tahoe_pct:.1f}%")

# Correlation between precision and recall
cmap_corr = cmap_results[['Precision_%', 'Recall_%']].corr().iloc[0, 1]
tahoe_corr = tahoe_results[['Precision_%', 'Recall_%']].corr().iloc[0, 1]

print(f"\nCorrelation between Precision and Recall:")
print(f"  CMAP:  r = {cmap_corr:.3f}")
print(f"  TAHOE: r = {tahoe_corr:.3f}")

# Save combined results for next phase
combined_results = pd.concat([
    cmap_results.assign(Platform='CMAP'),
    tahoe_results.assign(Platform='TAHOE')
], ignore_index=True)
combined_results.to_csv(output_dir / "combined_precision_recall.csv", index=False)
print(f"\n✓ Saved combined results to: {output_dir / 'combined_precision_recall.csv'}")

print("\n" + "=" * 80)
print("PHASE 3 COMPLETE")
print("=" * 80)
