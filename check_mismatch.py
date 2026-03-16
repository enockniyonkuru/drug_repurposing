#!/usr/bin/env python3
import pandas as pd
import glob
import os

# Load reference
ref_df = pd.read_csv('endo_tomiko_code/replication/drug_hits_comparison/drug_instances_ESE.csv', index_col=0)

# Load DRpipe
ese_dir = glob.glob('scripts/results/*/CMAP_Endometriosis_ESE_Strict_*')[0]
drpipe_df = pd.read_csv(glob.glob(os.path.join(ese_dir, '*_q<0.*.csv'))[0])

print("=" * 60)
print("Q-VALUE ANALYSIS")
print("=" * 60)
print(f"Reference q-value range: {ref_df['q'].min()} to {ref_df['q'].max()}")
print(f"DRpipe q-value range:    {drpipe_df['q'].min():.2e} to {drpipe_df['q'].max():.2e}")

print(f"\nDRpipe: {len(drpipe_df[drpipe_df['q'] < 0.0001])} hits with q < 0.0001")
print(f"Reference: {len(ref_df[ref_df['q'] < 0.0001])} hits with q < 0.0001")

print("\n" + "=" * 60)
print("WEAKEST HIT ANALYSIS")
print("=" * 60)
print("\nWeakest DRpipe hit (highest q):")
weak_hit = drpipe_df[['name', 'cmap_score', 'p', 'q']].iloc[-1]
print(f"  Drug: {weak_hit['name']}")
print(f"  Score: {weak_hit['cmap_score']:.6f}")
print(f"  p-value: {weak_hit['p']:.2e}")
print(f"  q-value: {weak_hit['q']:.2e}")

print("\n" + "=" * 60)
print("MISSING DRUGS ANALYSIS")
print("=" * 60)

ref_drugs_lower = set(ref_df['name'].str.lower())
drpipe_drugs_lower = set(drpipe_df['name'].str.lower())
missing = sorted(list(ref_drugs_lower - drpipe_drugs_lower))

print(f"\nTotal missing drugs: {len(missing)}")
print(f"First 10 missing drugs with their q-values:")

for i, drug in enumerate(missing[:10]):
    ref_rows = ref_df[ref_df['name'].str.lower() == drug]
    if not ref_rows.empty:
        p_val = ref_rows['p'].values[0]
        q_val = ref_rows['q'].values[0]
        score = ref_rows['cmap_score'].values[0]
        print(f"  {i+1}. {drug}: p={p_val:.2e}, q={q_val:.2e}, score={score:.4f}")

print("\n" + "=" * 60)
print("P-VALUE CALCULATION METHOD DIFFERENCE")
print("=" * 60)

# With 1000 permutations, discrete p-values should be multiples of 0.001
print("\nWith 1000 permutations, discrete p-values are: 0, 0.001, 0.002, ..., 1.0")
print("This means there are only 1001 possible p-values.")
print("\nReference uses p=0 which likely means:")
print("  - 0 permutations had |random_score| >= |observed_score|")
print("  - Or uses a correction (e.g., p = 1/(N+1) = 0.001 then displayed as 0)")
print("\nDRpipe's discrete method gives:")
print("  - p = 1/100000 when 0 perms >= observed (continuous method)")
print("  - p = 0.001 when 0 perms >= observed (discrete method with 1000 perms)")
print("\nReference's lower q-values suggest they may be using:")
print("  - More permutations (e.g., 100,000)")
print("  - A different p-value correction")
print("  - Or a different gene set (different gene mapping)")
