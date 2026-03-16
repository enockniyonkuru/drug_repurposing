#!/usr/bin/env python3
"""
Phase 2: Calculate Precision & Recall Per Disease

This script:
1. For each disease, identifies:
   - S: Successfully recovered drugs (predictions in Open Targets)
   - I: All predictions made
   - P: All known drugs available in the platform universe
2. Calculates Precision = S / I and Recall = S / P
3. Outputs per-disease results for both CMAP and TAHOE
"""

import pandas as pd
import numpy as np
import pickle
from pathlib import Path

print("=" * 80)
print("PHASE 2: CALCULATE PRECISION & RECALL PER DISEASE")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
data_dir = base_dir.parent  # Go up one level to about_drpipe_results
output_dir = base_dir / "intermediate_data"
output_dir.mkdir(exist_ok=True)

# Load data
print("\nLoading datasets...")
cmap_recovered = pd.read_csv(data_dir / "open_target_cmap_recovered.csv")
tahoe_recovered = pd.read_csv(data_dir / "open_target_tahoe_recovered.csv")
cmap_all = pd.read_csv(data_dir / "all_discoveries_cmap.csv")
tahoe_all = pd.read_csv(data_dir / "all_discoveries_tahoe.csv")

# Normalize columns
def normalize_cols(df):
    df.columns = df.columns.str.lower().str.strip()
    return df

cmap_recovered = normalize_cols(cmap_recovered)
tahoe_recovered = normalize_cols(tahoe_recovered)
cmap_all = normalize_cols(cmap_all)
tahoe_all = normalize_cols(tahoe_all)

# Get column names
def get_disease_col(df):
    for col in ['disease_therapeutic_areas', 'disease', 'therapeutic_area']:
        if col in df.columns:
            return col
    raise ValueError("Disease column not found")

def get_drug_col(df):
    for col in ['drug_common_name', 'drug_name', 'drug', 'compound_name']:
        if col in df.columns:
            return col
    raise ValueError("Drug column not found")

disease_col_cr = get_disease_col(cmap_recovered)
disease_col_tr = get_disease_col(tahoe_recovered)
disease_col_ca = get_disease_col(cmap_all)
disease_col_ta = get_disease_col(tahoe_all)

drug_col_cr = get_drug_col(cmap_recovered)
drug_col_tr = get_drug_col(tahoe_recovered)
drug_col_ca = get_drug_col(cmap_all)
drug_col_ta = get_drug_col(tahoe_all)

# Load universe data
with open(output_dir / "universe_data.pkl", 'rb') as f:
    universe_data = pickle.load(f)

print("✓ Data loaded successfully")

# Helper function to normalize drug names
def normalize_drug(drug_name):
    return str(drug_name).lower().strip() if pd.notna(drug_name) else None

# Calculate precision and recall
print("\n" + "=" * 80)
print("CALCULATING PRECISION & RECALL")
print("=" * 80)

results = []

for universe_item in universe_data:
    platform = universe_item['Platform']
    disease = universe_item['Disease']
    P_drugs = universe_item['P_drugs']  # Known drugs available in platform
    I_drugs = universe_item['I_drugs']  # All predictions
    
    if platform == 'CMAP':
        # S: recovered drugs that are in predictions
        recovered_drugs = set(
            cmap_recovered[cmap_recovered[disease_col_cr] == disease][drug_col_cr]
            .dropna().apply(normalize_drug).unique()
        )
        recovered_drugs = {d for d in recovered_drugs if d is not None}
    else:  # TAHOE
        recovered_drugs = set(
            tahoe_recovered[tahoe_recovered[disease_col_tr] == disease][drug_col_tr]
            .dropna().apply(normalize_drug).unique()
        )
        recovered_drugs = {d for d in recovered_drugs if d is not None}
    
    # S: Successfully recovered = recovered drugs that are in our predictions
    S_drugs = recovered_drugs & I_drugs
    S = len(S_drugs)
    I = len(I_drugs)
    P = len(P_drugs)
    
    # Calculate metrics
    precision = (S / I * 100) if I > 0 else np.nan
    recall = (S / P * 100) if P > 0 else np.nan
    
    # Validation checks
    if S > I:
        print(f"⚠ WARNING: {platform} {disease} - S ({S}) > I ({I})")
    if S > P:
        print(f"⚠ WARNING: {platform} {disease} - S ({S}) > P ({P})")
    
    results.append({
        'Platform': platform,
        'Disease': disease,
        'I': I,  # Predictions
        'S': S,  # Recovered
        'P': P,  # Possible
        'Precision_%': precision,
        'Recall_%': recall
    })

results_df = pd.DataFrame(results)

# Split by platform
cmap_results = results_df[results_df['Platform'] == 'CMAP'].drop('Platform', axis=1)
tahoe_results = results_df[results_df['Platform'] == 'TAHOE'].drop('Platform', axis=1)

# Save results
cmap_results.to_csv(output_dir / "cmap_precision_recall_per_disease.csv", index=False)
tahoe_results.to_csv(output_dir / "tahoe_precision_recall_per_disease.csv", index=False)

print(f"\n✓ CMAP results: {len(cmap_results)} diseases")
print(f"✓ TAHOE results: {len(tahoe_results)} diseases")

# Summary statistics per platform
print("\n" + "=" * 80)
print("PRELIMINARY STATISTICS")
print("=" * 80)

for platform_name, df in [('CMAP', cmap_results), ('TAHOE', tahoe_results)]:
    print(f"\n{platform_name}:")
    print(f"  Diseases analyzed: {len(df)}")
    
    # Precision statistics (excluding NaN)
    prec_valid = df['Precision_%'].dropna()
    print(f"\n  Precision (%):")
    print(f"    N valid: {len(prec_valid)}")
    print(f"    Mean: {prec_valid.mean():.2f}")
    print(f"    Median: {prec_valid.median():.2f}")
    print(f"    SD: {prec_valid.std():.2f}")
    print(f"    Min-Max: {prec_valid.min():.2f} - {prec_valid.max():.2f}")
    
    # Recall statistics (excluding NaN)
    recall_valid = df['Recall_%'].dropna()
    print(f"\n  Recall (%):")
    print(f"    N valid: {len(recall_valid)}")
    print(f"    Mean: {recall_valid.mean():.2f}")
    print(f"    Median: {recall_valid.median():.2f}")
    print(f"    SD: {recall_valid.std():.2f}")
    print(f"    Min-Max: {recall_valid.min():.2f} - {recall_valid.max():.2f}")
    
    # Top and bottom performers
    print(f"\n  Top 5 by Precision:")
    top_prec = df.nlargest(5, 'Precision_%')[['Disease', 'Precision_%', 'Recall_%']]
    for idx, row in top_prec.iterrows():
        print(f"    {row['Disease']}: Prec={row['Precision_%']:.1f}%, Recall={row['Recall_%']:.1f}%")
    
    print(f"\n  Top 5 by Recall:")
    top_recall = df.nlargest(5, 'Recall_%')[['Disease', 'Precision_%', 'Recall_%']]
    for idx, row in top_recall.iterrows():
        print(f"    {row['Disease']}: Prec={row['Precision_%']:.1f}%, Recall={row['Recall_%']:.1f}%")

# Summary comparison
print("\n" + "=" * 80)
print("PLATFORM COMPARISON")
print("=" * 80)

prec_cmap = cmap_results['Precision_%'].dropna()
prec_tahoe = tahoe_results['Precision_%'].dropna()
recall_cmap = cmap_results['Recall_%'].dropna()
recall_tahoe = tahoe_results['Recall_%'].dropna()

print(f"\nPrecision:")
print(f"  CMAP:  {prec_cmap.mean():.2f}% ± {prec_cmap.std():.2f}%")
print(f"  TAHOE: {prec_tahoe.mean():.2f}% ± {prec_tahoe.std():.2f}%")

print(f"\nRecall:")
print(f"  CMAP:  {recall_cmap.mean():.2f}% ± {recall_cmap.std():.2f}%")
print(f"  TAHOE: {recall_tahoe.mean():.2f}% ± {recall_tahoe.std():.2f}%")

print("\n" + "=" * 80)
print("PHASE 2 COMPLETE")
print("=" * 80)
print(f"\nOutputs saved:")
print(f"  - {output_dir / 'cmap_precision_recall_per_disease.csv'}")
print(f"  - {output_dir / 'tahoe_precision_recall_per_disease.csv'}")
