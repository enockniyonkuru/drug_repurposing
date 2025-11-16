#!/usr/bin/env python3
"""
Script to load and visualize random scores from RData file
"""

import pyreadr
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)

# File path
rdata_path = "results/temp_sirota_lab_disease_results_filtered/CoreFibroid_CMAP_20251105-135442/file14d646cbdf14c_random_scores_logFC_0.RData"

print(f"Loading RData file: {rdata_path}")
print("=" * 80)

# Load the RData file
result = pyreadr.read_r(rdata_path)

# Display what objects are in the RData file
print(f"\nObjects in RData file: {list(result.keys())}")
print("=" * 80)

# Get the data (assuming it's the first/only object or named 'random_scores')
if len(result) == 1:
    data_key = list(result.keys())[0]
    random_scores = result[data_key]
else:
    # Try common names
    for key in ['random_scores', 'scores', 'data']:
        if key in result:
            data_key = key
            random_scores = result[key]
            break
    else:
        # Just use the first one
        data_key = list(result.keys())[0]
        random_scores = result[data_key]

print(f"\nUsing data object: '{data_key}'")
print(f"Data shape: {random_scores.shape}")
print(f"Data type: {type(random_scores)}")
print("\nFirst few rows:")
print(random_scores.head())
print("\nData info:")
print(random_scores.info())
print("\nColumn names:")
print(random_scores.columns.tolist())

# If it's a DataFrame, find the column with scores
if isinstance(random_scores, pd.DataFrame):
    # Try to identify the score column
    score_columns = [col for col in random_scores.columns if 'score' in col.lower() or 'random' in col.lower()]
    
    if score_columns:
        score_col = score_columns[0]
        print(f"\nUsing score column: '{score_col}'")
    else:
        # Use the first numeric column
        numeric_cols = random_scores.select_dtypes(include=[np.number]).columns
        if len(numeric_cols) > 0:
            score_col = numeric_cols[0]
            print(f"\nUsing first numeric column: '{score_col}'")
        else:
            print("\nWarning: No numeric columns found. Using first column.")
            score_col = random_scores.columns[0]
    
    scores = random_scores[score_col].dropna()
else:
    # If it's a Series or array
    scores = pd.Series(random_scores).dropna()

print("\n" + "=" * 80)
print("RANDOM SCORES STATISTICS")
print("=" * 80)
print(f"Number of scores: {len(scores)}")
print(f"Mean: {scores.mean():.6f}")
print(f"Median: {scores.median():.6f}")
print(f"Std Dev: {scores.std():.6f}")
print(f"Min: {scores.min():.6f}")
print(f"Max: {scores.max():.6f}")
print(f"25th percentile: {scores.quantile(0.25):.6f}")
print(f"75th percentile: {scores.quantile(0.75):.6f}")

# Create visualizations
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# 1. Histogram
axes[0, 0].hist(scores, bins=50, edgecolor='black', alpha=0.7, color='steelblue')
axes[0, 0].axvline(scores.mean(), color='red', linestyle='--', linewidth=2, label=f'Mean: {scores.mean():.4f}')
axes[0, 0].axvline(scores.median(), color='green', linestyle='--', linewidth=2, label=f'Median: {scores.median():.4f}')
axes[0, 0].set_xlabel('Random Score', fontsize=12)
axes[0, 0].set_ylabel('Frequency', fontsize=12)
axes[0, 0].set_title('Distribution of Random Scores (Histogram)', fontsize=14, fontweight='bold')
axes[0, 0].legend()
axes[0, 0].grid(True, alpha=0.3)

# 2. Density plot (KDE)
axes[0, 1].hist(scores, bins=50, density=True, alpha=0.5, color='steelblue', edgecolor='black')
scores.plot(kind='kde', ax=axes[0, 1], color='darkblue', linewidth=2)
axes[0, 1].axvline(scores.mean(), color='red', linestyle='--', linewidth=2, label=f'Mean: {scores.mean():.4f}')
axes[0, 1].set_xlabel('Random Score', fontsize=12)
axes[0, 1].set_ylabel('Density', fontsize=12)
axes[0, 1].set_title('Distribution of Random Scores (Density)', fontsize=14, fontweight='bold')
axes[0, 1].legend()
axes[0, 1].grid(True, alpha=0.3)

# 3. Box plot
bp = axes[1, 0].boxplot(scores, vert=True, patch_artist=True, widths=0.5)
bp['boxes'][0].set_facecolor('lightblue')
bp['boxes'][0].set_edgecolor('black')
bp['medians'][0].set_color('red')
bp['medians'][0].set_linewidth(2)
axes[1, 0].set_ylabel('Random Score', fontsize=12)
axes[1, 0].set_title('Box Plot of Random Scores', fontsize=14, fontweight='bold')
axes[1, 0].grid(True, alpha=0.3, axis='y')
axes[1, 0].set_xticklabels(['Random Scores'])

# 4. Q-Q plot (to check normality)
from scipy import stats
stats.probplot(scores, dist="norm", plot=axes[1, 1])
axes[1, 1].set_title('Q-Q Plot (Normal Distribution)', fontsize=14, fontweight='bold')
axes[1, 1].grid(True, alpha=0.3)

plt.tight_layout()

# Save the figure
output_path = "results/temp_sirota_lab_disease_results_filtered/CoreFibroid_CMAP_20251105-135442/random_scores_distribution.png"
plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"\n✓ Visualization saved to: {output_path}")

# Show the plot
plt.show()

print("\n" + "=" * 80)
print("Analysis complete!")
print("=" * 80)
