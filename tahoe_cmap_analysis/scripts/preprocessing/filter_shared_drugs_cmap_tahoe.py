#!/usr/bin/env python3
"""
Identify Shared Drugs Between CMAP and Tahoe

Finds drug overlaps between CMAP and Tahoe databases. Generates shared drug
lists and filtered results for integrated comparative analysis.
"""

import pandas as pd
import os

def main():
    print("=" * 80)
    print("FILTERING FOR SHARED DRUGS BETWEEN CMAP AND TAHOE")
    print("=" * 80)
    
    # Load metadata files
    print("\n1. Loading metadata files...")
    cmap_meta = pd.read_csv("data/cmap_drug_experiments_new.csv")
    tahoe_meta = pd.read_csv("data/tahoe_drug_experiments_new.csv")
    
    print(f"   CMAP experiments: {len(cmap_meta)}")
    print(f"   TAHOE experiments: {len(tahoe_meta)}")
    
    # Get unique drug names (case-insensitive)
    print("\n2. Identifying unique drugs...")
    cmap_drugs = set(cmap_meta['name'].str.lower().unique())
    tahoe_drugs = set(tahoe_meta['name'].str.lower().unique())
    
    print(f"   Unique CMAP drugs: {len(cmap_drugs)}")
    print(f"   Unique TAHOE drugs: {len(tahoe_drugs)}")
    
    # Find shared drugs (case-insensitive)
    print("\n3. Finding shared drugs...")
    shared_drugs_lower = sorted(cmap_drugs.intersection(tahoe_drugs))
    
    print(f"   Shared drugs (case-insensitive): {len(shared_drugs_lower)}")
    
    # Create a mapping to preserve original case from both datasets
    # We'll use CMAP's capitalization as the standard
    drug_mapping = {}
    for drug_lower in shared_drugs_lower:
        # Find original case in CMAP
        cmap_original = cmap_meta[cmap_meta['name'].str.lower() == drug_lower]['name'].iloc[0]
        drug_mapping[drug_lower] = cmap_original
    
    # Save the shared drugs list
    print("\n4. Saving shared drugs list...")
    shared_drugs_df = pd.DataFrame({
        'drug_name_lowercase': shared_drugs_lower,
        'drug_name_standard': [drug_mapping[d] for d in shared_drugs_lower]
    })
    
    output_file = "../results/shared_drugs_cmap_tahoe.csv"
    shared_drugs_df.to_csv(output_file, index=False)
    print(f"   ✓ Shared drugs list saved to: {output_file}")
    
    # Display first 20 shared drugs
    print("\n   First 20 shared drugs:")
    for i, drug in enumerate(shared_drugs_lower[:20], 1):
        print(f"      {i:2d}. {drug_mapping[drug]}")
    
    if len(shared_drugs_lower) > 20:
        print(f"      ... and {len(shared_drugs_lower) - 20} more")
    
    # Load the compiled results
    print("\n5. Loading compiled drug hits...")
    compiled_file = "../results/all_drug_hits_compiled.csv"
    
    if not os.path.exists(compiled_file):
        print(f"   Error: {compiled_file} not found!")
        return
    
    df = pd.read_csv(compiled_file)
    print(f"   Total rows in compiled results: {len(df)}")
    
    # Filter for shared drugs (case-insensitive matching)
    print("\n6. Filtering for shared drugs only...")
    df['name_lower'] = df['name'].str.lower()
    df_filtered = df[df['name_lower'].isin(shared_drugs_lower)].copy()
    df_filtered = df_filtered.drop('name_lower', axis=1)
    
    print(f"   Rows after filtering: {len(df_filtered)}")
    print(f"   Rows removed: {len(df) - len(df_filtered)}")
    
    # Save filtered results
    filtered_output = "../results/all_drug_hits_compiled_shared_only.csv"
    df_filtered.to_csv(filtered_output, index=False)
    print(f"\n   ✓ Filtered results saved to: {filtered_output}")
    
    # Generate summary statistics
    print("\n7. Summary statistics for shared drugs only:")
    print("   " + "-" * 60)
    
    # Count by disease and signature type
    summary = df_filtered.groupby(['disease', 'signature_type']).size().reset_index(name='hit_count')
    
    # Count unique drugs per disease/signature
    unique_drugs = df_filtered.groupby(['disease', 'signature_type'])['name'].nunique().reset_index(name='unique_drugs')
    summary = summary.merge(unique_drugs, on=['disease', 'signature_type'])
    
    # Calculate totals
    cmap_total = summary[summary['signature_type'] == 'CMAP']['hit_count'].sum()
    tahoe_total = summary[summary['signature_type'] == 'TAHOE']['hit_count'].sum()
    cmap_unique = df_filtered[df_filtered['signature_type'] == 'CMAP']['name'].nunique()
    tahoe_unique = df_filtered[df_filtered['signature_type'] == 'TAHOE']['name'].nunique()
    
    print(f"   Total CMAP hits (shared drugs only): {cmap_total}")
    print(f"   Total TAHOE hits (shared drugs only): {tahoe_total}")
    print(f"   Unique CMAP drugs with hits: {cmap_unique}")
    print(f"   Unique TAHOE drugs with hits: {tahoe_unique}")
    
    # Diseases with most hits
    print("\n   Top 10 diseases by total hits (shared drugs):")
    disease_totals = df_filtered.groupby('disease').size().sort_values(ascending=False).head(10)
    for i, (disease, count) in enumerate(disease_totals.items(), 1):
        print(f"      {i:2d}. {disease}: {count} hits")
    
    # Save detailed summary
    summary_output = "../results/drug_hits_summary_shared_only.csv"
    summary_pivot = summary.pivot(index='disease', columns='signature_type', values='hit_count').fillna(0).astype(int)
    summary_pivot.columns = [f'{col}_hits' for col in summary_pivot.columns]
    summary_pivot = summary_pivot.reset_index()
    summary_pivot.to_csv(summary_output, index=False)
    print(f"\n   ✓ Summary statistics saved to: {summary_output}")
    
    print("\n" + "=" * 80)
    print("FILTERING COMPLETE")
    print("=" * 80)
    print(f"\nOutput files created:")
    print(f"  1. {output_file}")
    print(f"  2. {filtered_output}")
    print(f"  3. {summary_output}")

if __name__ == "__main__":
    main()
