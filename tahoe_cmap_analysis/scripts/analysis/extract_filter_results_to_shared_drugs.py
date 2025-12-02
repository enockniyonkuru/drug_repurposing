#!/usr/bin/env python3
"""
Filter Results to Shared Drugs

Filters drug hit results to include only drugs that appear in both CMAP
and Tahoe datasets. Creates clean subsets for comparative analysis between
the two signature databases.
"""

import pandas as pd
import os
import glob
import re
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent.parent
SHARED_DRUGS_FILE = BASE_DIR / "reports/shared_drugs_tahoe_cmap.csv"
INPUT_DIR = BASE_DIR / "results/creeds_manual_disease_results_filtered"
OUTPUT_DIR = BASE_DIR / "results/creeds_manual_disease_results_filtered_SHARED_ONLY"



def clean_drug_name(name):
    """Clean drug name for matching."""
    if not isinstance(name, str):
        return ""
    # Remove quotes and extra whitespace
    name = name.strip().strip('"').strip("'")
    return name.lower()

def load_shared_drugs():
    """Load the list of shared drugs and create a set of normalized names."""
    print(f"[Info] Loading shared drugs from: {SHARED_DRUGS_FILE}")
    df = pd.read_csv(SHARED_DRUGS_FILE)
    
    # Get all drug names (normalized, CMAP original, TAHOE original)
    shared_drugs = set()
    
    # Add normalized names
    shared_drugs.update(df['drug_norm'].apply(clean_drug_name))
    
    # Add CMAP original names
    shared_drugs.update(df['cmap_original_name'].apply(clean_drug_name))
    
    # Add TAHOE original names
    shared_drugs.update(df['tahoe_original_name'].apply(clean_drug_name))
    
    print(f"[Info] Loaded {len(df)} shared drug entries")
    print(f"[Info] Total unique drug name variations: {len(shared_drugs)}")
    
    return shared_drugs

def filter_csv_file(input_path, output_path, shared_drugs):
    """Filter a single CSV file to only include shared drugs."""
    try:
        df = pd.read_csv(input_path)
        
        if 'name' not in df.columns:
            print(f"  [Warning] No 'name' column in {input_path}")
            return 0, 0
        
        original_count = len(df)
        
        # Filter to only shared drugs
        df['name_clean'] = df['name'].apply(clean_drug_name)
        df_filtered = df[df['name_clean'].isin(shared_drugs)].copy()
        df_filtered = df_filtered.drop(columns=['name_clean'])
        
        filtered_count = len(df_filtered)
        
        # Save filtered results
        df_filtered.to_csv(output_path, index=False)
        
        return original_count, filtered_count
        
    except Exception as e:
        print(f"  [Error] Failed to process {input_path}: {e}")
        return 0, 0

def main():
    print("="*80)
    print("FILTERING PIPELINE RESULTS TO SHARED DRUGS ONLY")
    print("="*80)
    
    # Load shared drugs
    shared_drugs = load_shared_drugs()
    
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"\n[Info] Output directory: {OUTPUT_DIR}")
    
    # Find all result folders
    result_folders = [d for d in INPUT_DIR.iterdir() if d.is_dir()]
    print(f"\n[Info] Found {len(result_folders)} result folders to process")
    
    # Statistics
    total_original = 0
    total_filtered = 0
    processed_files = 0
    
    # Process each folder
    for folder in sorted(result_folders):
        folder_name = folder.name
        print(f"\n[Processing] {folder_name}")
        
        # Create corresponding output folder
        output_folder = OUTPUT_DIR / folder_name
        output_folder.mkdir(parents=True, exist_ok=True)
        
        # Find CSV files in this folder
        csv_files = list(folder.glob("*.csv"))
        
        for csv_file in csv_files:
            output_file = output_folder / csv_file.name
            
            orig, filt = filter_csv_file(csv_file, output_file, shared_drugs)
            
            if orig > 0:
                processed_files += 1
                total_original += orig
                total_filtered += filt
                removed = orig - filt
                pct_kept = (filt / orig * 100) if orig > 0 else 0
                print(f"  {csv_file.name}: {orig} → {filt} drugs ({removed} removed, {pct_kept:.1f}% kept)")
        
        # Copy other files (RData, logs, etc.) - just copy the directory structure
        for item in folder.iterdir():
            if item.is_dir():
                # Copy subdirectories (like img/)
                output_subdir = output_folder / item.name
                output_subdir.mkdir(parents=True, exist_ok=True)
                print(f"  Created subdirectory: {item.name}/")
    
    # Print summary
    print("\n" + "="*80)
    print("FILTERING COMPLETE")
    print("="*80)
    print(f"Processed files: {processed_files}")
    print(f"Total drugs before filtering: {total_original}")
    print(f"Total drugs after filtering: {total_filtered}")
    print(f"Total drugs removed: {total_original - total_filtered}")
    if total_original > 0:
        print(f"Percentage kept: {total_filtered / total_original * 100:.1f}%")
    print(f"\nFiltered results saved to: {OUTPUT_DIR}")
    
    # Create a summary file
    summary_file = OUTPUT_DIR / "filtering_summary.txt"
    with open(summary_file, 'w') as f:
        f.write("SHARED DRUGS FILTERING SUMMARY\n")
        f.write("="*80 + "\n\n")
        f.write(f"Generated: {pd.Timestamp.now()}\n")
        f.write(f"Input directory: {INPUT_DIR}\n")
        f.write(f"Output directory: {OUTPUT_DIR}\n")
        f.write(f"Shared drugs file: {SHARED_DRUGS_FILE}\n\n")
        f.write(f"Number of shared drugs: {len(shared_drugs)} (including name variations)\n")
        f.write(f"Processed files: {processed_files}\n")
        f.write(f"Total drugs before filtering: {total_original}\n")
        f.write(f"Total drugs after filtering: {total_filtered}\n")
        f.write(f"Total drugs removed: {total_original - total_filtered}\n")
        if total_original > 0:
            f.write(f"Percentage kept: {total_filtered / total_original * 100:.1f}%\n")
    
    print(f"\nSummary saved to: {summary_file}")

if __name__ == "__main__":
    main()
