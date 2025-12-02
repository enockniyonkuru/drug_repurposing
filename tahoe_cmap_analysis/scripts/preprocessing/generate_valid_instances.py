#!/usr/bin/env python3
"""
Calculate Valid Signature Instances

Assesses drug signature quality based on replicate consistency using
Leave-One-Out correlation analysis. Supports flexible filtering modes
for quality control (p-value, r-value, percentile-based).
"""

import os
import sys
import pandas as pd
import numpy as np
import pyreadr
import argparse
from scipy.stats import pearsonr

# --- 1. Define File Paths ---
try:
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
except NameError:
    SCRIPT_DIR = os.getcwd()
    PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

PATH_CMAP_EXP = os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap/cmap_drug_experiments_new.csv")
PATH_CMAP_SIGS = os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap/cmap_signatures.RData")
PATH_TAHOE_EXP = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/tahoe_drug_experiments_new.csv")
PATH_TAHOE_SIGS = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/tahoe_signatures.RData")
PATH_TAHOE_SIGS_PARQUET = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/checkpoint_ranked_all_genes_all_drugs.parquet")

os.makedirs(os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap"), exist_ok=True)
os.makedirs(os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe"), exist_ok=True)

PATH_CMAP_VALID = os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap/cmap_valid_instances_OG_15.csv")
PATH_TAHOE_VALID = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/tahoe_valid_instances_OG_045.csv")
PATH_CMAP_REPORT = os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap/cmap_valid_instances_OG_report_15.txt")
PATH_TAHOE_REPORT = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/tahoe_valid_instances_OG_report_045.txt")


def generate_summary(results_df, dataset_name, mode, threshold):
    """
    Prints a validation summary report.
    """
    total = len(results_df)
    summary_lines = []
    
    header = f"\n=== {dataset_name} VALIDATION STATISTICS ==="
    mode_info = f"Filter Mode: {mode} | Threshold: {threshold}"
    
    if total == 0:
        print(header)
        print("No instances processed.")
        return "No instances processed."

    valid = results_df['valid'].sum()
    invalid = total - valid
    percent_valid = (valid / total) * 100

    summary = [
        header,
        mode_info,
        "-" * 30,
        f"Total experiments: {total}",
        f"Valid (1):         {valid}",
        f"Invalid (0):       {invalid}",
        f"Percentage valid:  {percent_valid:.2f}%"
    ]
    
    summary_str = "\n".join(summary)
    print(summary_str)
    return summary_str


def load_cmap_data():
    """Loads CMAP signature matrix and metadata."""
    print("Loading CMAP metadata...")
    try:
        cmap_meta = pd.read_csv(PATH_CMAP_EXP)
        cmap_meta['id'] = cmap_meta['id'].astype(str)
        print(f"Loaded {len(cmap_meta)} CMAP metadata entries.")
    except Exception as e:
        print(f"FATAL ERROR loading {PATH_CMAP_EXP}: {e}", file=sys.stderr)
        return None, None

    print("Loading CMAP signature matrix (RData)...")
    try:
        rdata = pyreadr.read_r(PATH_CMAP_SIGS)
        cmap_sigs_raw = rdata[list(rdata.keys())[0]]
        
        if 'V1' not in cmap_sigs_raw.columns:
            print("FATAL ERROR: 'V1' (gene ID) column not found in RData.", file=sys.stderr)
            return None, None
            
        cmap_sigs = cmap_sigs_raw.set_index('V1')
        cmap_sigs.columns = [str(int(col[1:])) for col in cmap_sigs.columns]
        print(f"Loaded CMAP matrix: {cmap_sigs.shape[0]} genes, {cmap_sigs.shape[1]} instances.")
        
        return cmap_sigs, cmap_meta
        
    except Exception as e:
        print(f"FATAL ERROR loading {PATH_CMAP_SIGS}: {e}", file=sys.stderr)
        return None, None


def load_tahoe_data():
    """Loads TAHOE signature matrix and metadata."""
    print("Loading TAHOE metadata...")
    try:
        tahoe_meta = pd.read_csv(PATH_TAHOE_EXP) 
        tahoe_meta['id'] = tahoe_meta['id'].astype(str)
        print(f"Loaded {len(tahoe_meta)} TAHOE metadata entries.")
    except Exception as e:
        print(f"FATAL ERROR loading {PATH_TAHOE_EXP}: {e}", file=sys.stderr)
        return None, None

    print("Loading TAHOE signature matrix (Parquet)...")
    try:
        # Try loading from parquet first (more reliable than RData with pyreadr)
        if os.path.exists(PATH_TAHOE_SIGS_PARQUET):
            print(f"  Using parquet file: {PATH_TAHOE_SIGS_PARQUET}")
            tahoe_sigs_raw = pd.read_parquet(PATH_TAHOE_SIGS_PARQUET)
            
            if 'entrezID' not in tahoe_sigs_raw.columns:
                print("FATAL ERROR: 'entrezID' column not found in parquet.", file=sys.stderr)
                return None, None
            
            # Set entrezID as index and convert column names to match expected format
            tahoe_sigs = tahoe_sigs_raw.set_index('entrezID')
            # Column names are already '0', '1', '2', etc. which match the instance IDs
            print(f"Loaded TAHOE matrix: {tahoe_sigs.shape[0]} genes, {tahoe_sigs.shape[1]} instances.")
            
            return tahoe_sigs, tahoe_meta
        else:
            print(f"  Parquet file not found, trying RData: {PATH_TAHOE_SIGS}")
            # Fallback to RData if parquet doesn't exist
            rdata = pyreadr.read_r(PATH_TAHOE_SIGS)
            tahoe_sigs_raw = rdata[list(rdata.keys())[0]]

            if 'V1' not in tahoe_sigs_raw.columns:
                print("FATAL ERROR: 'V1' (gene ID) column not found in RData.", file=sys.stderr)
                return None, None
                
            tahoe_sigs = tahoe_sigs_raw.set_index('V1')
            tahoe_sigs.columns = [str(int(col[1:]) - 2) for col in tahoe_sigs.columns]
            print(f"Loaded TAHOE matrix: {tahoe_sigs.shape[0]} genes, {tahoe_sigs.shape[1]} instances.")
            
            return tahoe_sigs, tahoe_meta
    except Exception as e:
        print(f"FATAL ERROR loading TAHOE signatures: {e}", file=sys.stderr)
        return None, None


def calculate_raw_stats(sig_matrix, metadata, drug_col_name, instance_col_name):
    """
    Calculates raw 'r' and 'p' values using Leave-One-Out (LOO).
    Does NOT assign 'valid' yet.
    """
    results = []
    drug_groups = metadata.groupby(drug_col_name)
    num_drugs = len(drug_groups)
    
    print(f"Calculating stats for {num_drugs} drugs...")
    
    for i, (drug_name, group) in enumerate(drug_groups):
        if (i + 1) % 100 == 0:
            print(f"  ...processing drug {i+1} / {num_drugs} ({drug_name})")
            
        instance_ids = group[instance_col_name].tolist()
        valid_matrix_ids = [pid for pid in instance_ids if pid in sig_matrix.columns]
        num_instances = len(valid_matrix_ids)

        # If only 1 instance exists, it cannot be validated against peers
        if num_instances <= 1:
            for inst_id in instance_ids:
                results.append({
                    'id': inst_id,
                    'drug_name': drug_name,
                    'r': np.nan,
                    'p': np.nan,
                    'num_peers': 0
                })
            continue

        drug_sig_matrix = sig_matrix[valid_matrix_ids]
        total_sum_vector = drug_sig_matrix.sum(axis=1)

        for inst_id in valid_matrix_ids:
            current_instance_sig = drug_sig_matrix[inst_id]
            peer_sum_vector = total_sum_vector - current_instance_sig
            peer_consensus = peer_sum_vector / (num_instances - 1)

            try:
                r, p = pearsonr(current_instance_sig, peer_consensus)
                if pd.isna(r):
                    r, p = 0.0, 1.0
            except ValueError:
                r, p = 0.0, 1.0
            
            results.append({
                'id': inst_id,
                'drug_name': drug_name,
                'r': r,
                'p': p,
                'num_peers': num_instances - 1
            })

    print("...Calculation complete.")
    return pd.DataFrame(results)


def apply_filters(results_df, mode, threshold):
    """
    Applies the specific filter logic to determine 'valid'.
    """
    print(f"\nApplying Filter Mode: '{mode}' with Threshold: {threshold}")
    
    # Initialize valid to 0
    results_df['valid'] = 0
    
    # Valid results must have valid stats (not NaN)
    valid_stats_mask = results_df['r'].notna()
    
    if mode == 'pvalue':
        # Logic: Valid if p < threshold AND r > 0 (Positive correlation only)
        # Standard threshold: 0.05
        mask = (results_df['p'] < threshold) & (results_df['r'] > 0)
        results_df.loc[valid_stats_mask & mask, 'valid'] = 1
        
    elif mode == 'rvalue':
        # Logic: Valid if r > threshold
        # Good standard: 0.2
        mask = (results_df['r'] > threshold)
        results_df.loc[valid_stats_mask & mask, 'valid'] = 1
        
    elif mode == 'percentile':
        # Logic: Keep top N percent of rankable instances based on 'r'
        # Filter to only rows that have stats
        rankable = results_df[valid_stats_mask]
        
        if rankable.empty:
            print("Warning: No data to rank.")
        else:
            percentile_cutoff = 100.0 - threshold
            r_cutoff = np.nanpercentile(rankable['r'], percentile_cutoff)
            print(f"  -> {threshold}% cutoff corresponds to r > {r_cutoff:.4f}")
            
            # Must be above cutoff AND have positive correlation
            mask = (results_df['r'] >= r_cutoff) & (results_df['r'] > 0)
            results_df.loc[valid_stats_mask & mask, 'valid'] = 1

    return results_df


def main():
    parser = argparse.ArgumentParser(
        description="Calculate replicate self-consistency with flexible filtering.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('--dataset', required=True, choices=['cmap', 'tahoe'], help="Dataset to process.")
    
    # NEW ARGUMENTS
    parser.add_argument(
        '--filter-mode', 
        choices=['pvalue', 'rvalue', 'percentile'], 
        default='pvalue',
        help="Choose filtering logic:\n"
             "  pvalue:     Keep if p < threshold (and r>0). Default threshold=0.05\n"
             "  rvalue:     Keep if r > threshold. Recommended threshold=0.2\n"
             "  percentile: Keep top N percent. e.g. threshold=50"
    )
    parser.add_argument(
        '--threshold', 
        type=float, 
        default=0.05,
        help="Value for the filter mode (e.g., 0.05 for pvalue, 0.2 for rvalue, 50 for percentile)."
    )

    args = parser.parse_args()

    # Setup paths based on dataset
    if args.dataset == 'cmap':
        print("\n--- Processing CMAP ---")
        sigs, meta = load_cmap_data()
        dataset_name = "CMAP"
        output_csv_path = PATH_CMAP_VALID
        output_report_path = PATH_CMAP_REPORT
        drug_col_name = "name"
    else:
        print("\n--- Processing TAHOE ---")
        sigs, meta = load_tahoe_data()
        dataset_name = "TAHOE"
        output_csv_path = PATH_TAHOE_VALID
        output_report_path = PATH_TAHOE_REPORT
        drug_col_name = "name"

    if sigs is not None and meta is not None:
        common_ids = set(sigs.columns) & set(meta['id'])
        print(f"Found {len(common_ids)} overlapping instances.")
        
        sigs_filt = sigs[list(common_ids)]
        meta_filt = meta[meta['id'].isin(common_ids)]

        # 1. Calculate Stats (r and p)
        results_df = calculate_raw_stats(
            sigs_filt, meta_filt, 
            drug_col_name=drug_col_name, 
            instance_col_name='id'
        )
        
        # 2. Apply chosen filter
        results_df = apply_filters(results_df, args.filter_mode, args.threshold)
        
        # 3. Save
        results_df.to_csv(output_csv_path, index=False)
        print(f"\n[SUCCESS] Saved CSV to: {output_csv_path}")
        
        summary_str = generate_summary(results_df, dataset_name, args.filter_mode, args.threshold)
        with open(output_report_path, 'w') as f:
            f.write(summary_str)
        print(f"[SUCCESS] Saved report to: {output_report_path}")

    print("\n=== Validation Complete ===")

if __name__ == "__main__":
    main()
