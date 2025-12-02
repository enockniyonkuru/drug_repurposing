#!/usr/bin/env python3
"""
Compile Drug Repurposing Results

Aggregates drug hit results from multiple disease-signature experiments.
Produces consolidated output files with hit statistics and summary metrics
for overall drug repurposing analysis.
"""

import pandas as pd
import os
import glob
from pathlib import Path

def main():
    # Read the batch run summary
    
    summary_file = "../results/batch_run_summary_20251027-015445.csv"
    summary_df = pd.read_csv(summary_file)
    
    # Filter only successful runs
    successful_runs = summary_df[summary_df['status'] == 'SUCCESS'].copy()
    
    print(f"Processing {len(successful_runs)} successful experiments...")
    
    # List to store all compiled hits
    all_hits = []
    
    # Dictionary to store summary statistics
    summary_stats = {}
    
    # Process each experiment
    for idx, row in successful_runs.iterrows():
        disease = row['disease']
        signature_type = row['signature_type']
        output_dir = row['output_dir']
        
        # Make sure we have the full path (output_dir is relative to project root)
        # Since we're running from scripts/, we need to go up one level
        if not output_dir.startswith('/'):
            output_dir = os.path.join('..', output_dir)
        
        # Find the hits file in the output directory
        # Look for files containing 'hits_q<' in the name
        hits_pattern = os.path.join(output_dir, "*_hits_q*.csv")
        hits_files = glob.glob(hits_pattern)
        
        if not hits_files:
            print(f"Warning: No hits file found for {disease} - {signature_type}")
            continue
        
        hits_file = hits_files[0]
        
        # Read the hits file
        try:
            hits_df = pd.read_csv(hits_file)
            
            # Check if there are any hits (beyond just the header)
            if len(hits_df) > 0:
                # Add disease and signature_type columns
                hits_df.insert(0, 'disease', disease)
                hits_df.insert(1, 'signature_type', signature_type)
                all_hits.append(hits_df)
                num_hits = len(hits_df)
                print(f"  {disease} - {signature_type}: {num_hits} hits")
            else:
                # No hits - create a row with NaN values
                empty_row = pd.DataFrame({
                    'disease': [disease],
                    'signature_type': [signature_type],
                    'exp_id': [pd.NA],
                    'cmap_score': [pd.NA],
                    'p': [pd.NA],
                    'q': [pd.NA],
                    'subset_comparison_id': [pd.NA],
                    'analysis_id': [pd.NA],
                    'name': [pd.NA],
                    'concentration': [pd.NA],
                    'duration': [pd.NA],
                    'cell_line': [pd.NA],
                    'array_platform': [pd.NA],
                    'vehicle': [pd.NA],
                    'vendor': [pd.NA],
                    'vendor_catalog_id': [pd.NA],
                    'vendor_catalog_name': [pd.NA],
                    'drug_concept_id': [pd.NA],
                    'cas_number': [pd.NA],
                    'DrugBank.ID': [pd.NA],
                    'valid': [pd.NA]
                })
                all_hits.append(empty_row)
                num_hits = 0
                print(f"  {disease} - {signature_type}: 0 hits (empty)")
            
            # Update summary statistics
            if disease not in summary_stats:
                summary_stats[disease] = {'CMAP': 0, 'TAHOE': 0, 'common_drugs': set()}
            
            summary_stats[disease][signature_type] = num_hits
            
            # Store drug names for finding common drugs
            if num_hits > 0:
                drug_names = set(hits_df['name'].dropna().unique())
                if signature_type == 'CMAP':
                    summary_stats[disease]['cmap_drugs'] = drug_names
                else:
                    summary_stats[disease]['tahoe_drugs'] = drug_names
                    
        except Exception as e:
            print(f"Error processing {disease} - {signature_type}: {str(e)}")
            continue
    
    # Compile all hits into a single dataframe
    if all_hits:
        compiled_df = pd.concat(all_hits, ignore_index=True)
        output_file = "../results/all_drug_hits_compiled.csv"
        compiled_df.to_csv(output_file, index=False)
        print(f"\n✓ Compiled hits saved to: {output_file}")
        print(f"  Total rows: {len(compiled_df)}")
    else:
        print("\nNo hits found to compile!")
        return
    
    # Create summary statistics dataframe
    summary_rows = []
    for disease, stats in summary_stats.items():
        # Calculate common drugs
        cmap_drugs = stats.get('cmap_drugs', set())
        tahoe_drugs = stats.get('tahoe_drugs', set())
        common_drugs = cmap_drugs.intersection(tahoe_drugs)
        
        summary_rows.append({
            'disease': disease,
            'CMAP_hits': stats['CMAP'],
            'TAHOE_hits': stats['TAHOE'],
            'common_drug_hits': len(common_drugs)
        })
    
    summary_df = pd.DataFrame(summary_rows)
    summary_df = summary_df.sort_values('disease')
    
    summary_output = "../results/drug_hits_summary.csv"
    summary_df.to_csv(summary_output, index=False)
    print(f"\n✓ Summary statistics saved to: {summary_output}")
    print(f"  Total diseases: {len(summary_df)}")
    
    # Print some summary statistics
    print("\n=== Summary Statistics ===")
    print(f"Total CMAP hits: {summary_df['CMAP_hits'].sum()}")
    print(f"Total TAHOE hits: {summary_df['TAHOE_hits'].sum()}")
    print(f"Total common drug hits: {summary_df['common_drug_hits'].sum()}")
    print(f"Diseases with CMAP hits: {(summary_df['CMAP_hits'] > 0).sum()}")
    print(f"Diseases with TAHOE hits: {(summary_df['TAHOE_hits'] > 0).sum()}")
    print(f"Diseases with common hits: {(summary_df['common_drug_hits'] > 0).sum()}")

if __name__ == "__main__":
    main()
