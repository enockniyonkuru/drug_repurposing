#!/usr/bin/env python3
"""
Phase 1: Data Preparation for Precision & Recall Analysis

This script:
1. Loads all required datasets
2. Extracts drug universes for each platform
3. Identifies known disease-drug relationships from Open Targets
4. Creates summary of data availability per disease
"""

import pandas as pd
import numpy as np
import os
from pathlib import Path

print("=" * 80)
print("PHASE 1: DATA PREPARATION")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
data_dir = base_dir.parent  # Go up one level to about_drpipe_results
output_dir = base_dir / "intermediate_data"
output_dir.mkdir(exist_ok=True)

print(f"\nBase directory: {base_dir}")
print(f"Data directory: {data_dir}")
print(f"Output directory: {output_dir}")

# Load data
print("\nLoading datasets...")
try:
    cmap_recovered = pd.read_csv(data_dir / "open_target_cmap_recovered.csv")
    print(f"✓ CMAP recovered: {len(cmap_recovered)} rows")
except FileNotFoundError:
    print(f"✗ Error: open_target_cmap_recovered.csv not found")
    exit(1)

try:
    tahoe_recovered = pd.read_csv(data_dir / "open_target_tahoe_recovered.csv")
    print(f"✓ TAHOE recovered: {len(tahoe_recovered)} rows")
except FileNotFoundError:
    print(f"✗ Error: open_target_tahoe_recovered.csv not found")
    exit(1)

try:
    cmap_all = pd.read_csv(data_dir / "all_discoveries_cmap.csv")
    print(f"✓ CMAP all discoveries: {len(cmap_all)} rows")
except FileNotFoundError:
    print(f"✗ Error: all_discoveries_cmap.csv not found")
    exit(1)

try:
    tahoe_all = pd.read_csv(data_dir / "all_discoveries_tahoe.csv")
    print(f"✓ TAHOE all discoveries: {len(tahoe_all)} rows")
except FileNotFoundError:
    print(f"✗ Error: all_discoveries_tahoe.csv not found")
    exit(1)

# Normalize column names (handle case variations)
def normalize_cols(df):
    df.columns = df.columns.str.lower().str.strip()
    return df

cmap_recovered = normalize_cols(cmap_recovered)
tahoe_recovered = normalize_cols(tahoe_recovered)
cmap_all = normalize_cols(cmap_all)
tahoe_all = normalize_cols(tahoe_all)

print("\nColumn names detected:")
print(f"  CMAP recovered: {list(cmap_recovered.columns)}")
print(f"  TAHOE recovered: {list(tahoe_recovered.columns)}")
print(f"  CMAP all: {list(cmap_all.columns)}")
print(f"  TAHOE all: {list(tahoe_all.columns)}")

# Identify disease and drug columns
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

def get_drug_id_col(df):
    for col in ['drug_id', 'compound_id', 'drug_identifier']:
        if col in df.columns:
            return col
    return None

disease_col_cr = get_disease_col(cmap_recovered)
disease_col_tr = get_disease_col(tahoe_recovered)
disease_col_ca = get_disease_col(cmap_all)
disease_col_ta = get_disease_col(tahoe_all)

drug_col_cr = get_drug_col(cmap_recovered)
drug_col_tr = get_drug_col(tahoe_recovered)
drug_col_ca = get_drug_col(cmap_all)
drug_col_ta = get_drug_col(tahoe_all)

drug_id_col_cr = get_drug_id_col(cmap_recovered)
drug_id_col_tr = get_drug_id_col(tahoe_recovered)
drug_id_col_ca = get_drug_id_col(cmap_all)
drug_id_col_ta = get_drug_id_col(tahoe_all)

print(f"\nDetected columns:")
print(f"  Disease (CMAP recovered): {disease_col_cr}")
print(f"  Disease (TAHOE recovered): {disease_col_tr}")
print(f"  Drug (CMAP recovered): {drug_col_cr}")
print(f"  Drug (TAHOE recovered): {drug_col_tr}")

# Extract universes
print("\n" + "=" * 80)
print("EXTRACTING DRUG UNIVERSES")
print("=" * 80)

# CMAP universe: unique drugs in all_discoveries_cmap
cmap_universe = set(cmap_all[drug_col_ca].dropna().str.lower().str.strip())
print(f"\nCMAP drug universe: {len(cmap_universe)} unique drugs")

# TAHOE universe: unique drugs in all_discoveries_tahoe
tahoe_universe = set(tahoe_all[drug_col_ta].dropna().str.lower().str.strip())
print(f"TAHOE drug universe: {len(tahoe_universe)} unique drugs")

# Open Targets universe: unique drugs in recovered data
ot_universe_cmap = set(cmap_recovered[drug_col_cr].dropna().str.lower().str.strip())
ot_universe_tahoe = set(tahoe_recovered[drug_col_tr].dropna().str.lower().str.strip())
print(f"Open Targets universe (CMAP): {len(ot_universe_cmap)} unique drugs")
print(f"Open Targets universe (TAHOE): {len(ot_universe_tahoe)} unique drugs")

# Per-disease analysis
print("\n" + "=" * 80)
print("PER-DISEASE ANALYSIS")
print("=" * 80)

# Get unique diseases
diseases_cmap = set(cmap_all[disease_col_ca].dropna().unique())
diseases_tahoe = set(tahoe_all[disease_col_ta].dropna().unique())

print(f"\nCMAP diseases: {len(diseases_cmap)}")
print(f"TAHOE diseases: {len(diseases_tahoe)}")

# Build universe summary per disease
universe_data = []

for disease in sorted(diseases_cmap):
    # U: All known drugs in Open Targets for this disease (CMAP)
    u_drugs = set(
        cmap_recovered[cmap_recovered[disease_col_cr] == disease][drug_col_cr]
        .dropna().str.lower().str.strip()
    )
    
    # P: Known drugs that exist in CMAP universe
    p_drugs = u_drugs & cmap_universe
    
    # I: All predicted drugs for this disease (CMAP)
    i_drugs = set(
        cmap_all[cmap_all[disease_col_ca] == disease][drug_col_ca]
        .dropna().str.lower().str.strip()
    )
    
    universe_data.append({
        'Platform': 'CMAP',
        'Disease': disease,
        'U_count': len(u_drugs),  # Open Targets universe
        'P_count': len(p_drugs),  # Possible (max recoverable)
        'I_count': len(i_drugs),  # Predicted
        'U_drugs': u_drugs,
        'P_drugs': p_drugs,
        'I_drugs': i_drugs
    })

for disease in sorted(diseases_tahoe):
    # U: All known drugs in Open Targets for this disease (TAHOE)
    u_drugs = set(
        tahoe_recovered[tahoe_recovered[disease_col_tr] == disease][drug_col_tr]
        .dropna().str.lower().str.strip()
    )
    
    # P: Known drugs that exist in TAHOE universe
    p_drugs = u_drugs & tahoe_universe
    
    # I: All predicted drugs for this disease (TAHOE)
    i_drugs = set(
        tahoe_all[tahoe_all[disease_col_ta] == disease][drug_col_ta]
        .dropna().str.lower().str.strip()
    )
    
    universe_data.append({
        'Platform': 'TAHOE',
        'Disease': disease,
        'U_count': len(u_drugs),  # Open Targets universe
        'P_count': len(p_drugs),  # Possible (max recoverable)
        'I_count': len(i_drugs),  # Predicted
        'U_drugs': u_drugs,
        'P_drugs': p_drugs,
        'I_drugs': i_drugs
    })

universe_df = pd.DataFrame(universe_data)

# Summary statistics
print("\n" + "=" * 80)
print("UNIVERSE SUMMARY STATISTICS")
print("=" * 80)

for platform in ['CMAP', 'TAHOE']:
    platform_df = universe_df[universe_df['Platform'] == platform]
    print(f"\n{platform}:")
    print(f"  Diseases: {len(platform_df)}")
    print(f"  U (Open Targets universe):")
    print(f"    Mean: {platform_df['U_count'].mean():.1f}, Median: {platform_df['U_count'].median():.0f}")
    print(f"    Min: {platform_df['U_count'].min()}, Max: {platform_df['U_count'].max()}")
    print(f"  P (Possible recoverable):")
    print(f"    Mean: {platform_df['P_count'].mean():.1f}, Median: {platform_df['P_count'].median():.0f}")
    print(f"    Min: {platform_df['P_count'].min()}, Max: {platform_df['P_count'].max()}")
    print(f"  I (Predictions):")
    print(f"    Mean: {platform_df['I_count'].mean():.1f}, Median: {platform_df['I_count'].median():.0f}")
    print(f"    Min: {platform_df['I_count'].min()}, Max: {platform_df['I_count'].max()}")

# Save universes to CSV (without set columns for readability)
universe_export = universe_df[['Platform', 'Disease', 'U_count', 'P_count', 'I_count']].copy()
universe_export.to_csv(output_dir / "disease_universes.csv", index=False)
print(f"\n✓ Saved to: {output_dir / 'disease_universes.csv'}")

# Also save the full universe data as pickle for next phase
import pickle
with open(output_dir / "universe_data.pkl", 'wb') as f:
    pickle.dump(universe_data, f)
print(f"✓ Saved universe data to: {output_dir / 'universe_data.pkl'}")

print("\n" + "=" * 80)
print("PHASE 1 COMPLETE")
print("=" * 80)
