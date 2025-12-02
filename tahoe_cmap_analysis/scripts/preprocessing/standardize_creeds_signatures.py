#!/usr/bin/env python3
"""
Standardize CREEDS Signatures

Applies quality control filtering to CREEDS disease signatures. Validates
mean-median consistency and median effect sizes. Produces standardized
signatures for robust drug discovery analysis.
"""

import os
import argparse
import numpy as np
import pandas as pd

# ----------------------
# Helper: Load a CSV
# ----------------------
def load_signature(path):
    return pd.read_csv(path)

# ----------------------
# Core Filtering Function
# ----------------------
### CHANGED ###
# This function is modified to ONLY use QC1, NO FALLBACK, and NO CAP.
def filter_signature(df, experiment_cols=None, verbose=False):
    stats = {}
    stats["initial_genes"] = df.shape[0]

    # --- QC STAGE ---
    
    # Step 1: Mean/median consistency (QC1)
    same_sign = np.sign(df["mean_logfc"]) == np.sign(df["median_logfc"])
    strong_median = df["median_logfc"].abs() >= 0.02
    
    # Apply the filter and use .copy()
    # This is now the final pool of genes to be ranked.
    df_pool = df[same_sign & strong_median].copy()
    stats["after_qc1"] = df_pool.shape[0]


        
    # --- RANKING AND CAPPING STAGE ---
    # We rank the results of QC1.
    
    # Step 2: UP/DOWN split
    # Rank by mean_logfc, as in the original script
    up_final = df_pool[df_pool["mean_logfc"] > 0].sort_values("mean_logfc", ascending=False)
    down_final = df_pool[df_pool["mean_logfc"] < 0].sort_values("mean_logfc")


    
    df_final = pd.concat([up_final, down_final], axis=0)
    df_final["signature_type"] = np.where(df_final["mean_logfc"] > 0, "UP", "DOWN")

    stats["final_genes"] = df_final.shape[0]
    return df_final, stats

# ----------------------
# Process Directory
# ----------------------
def process_directory(input_dir, output_dir, verbose=False):
    os.makedirs(output_dir, exist_ok=True)
    files = [f for f in os.listdir(input_dir) if f.endswith(".csv")]

    print(f"\n📂 Found {len(files)} disease signature files.\n")
    
    ### CHANGED ### - Removed Note column
    print(f"{'Filename':55s}   {'Initial':>7s}   {'QC1 (Mean/Med)':>12s}   {'Final':>7s}")
    print("-" * 85)

    for fname in sorted(files):
        in_path = os.path.join(input_dir, fname)
        out_path = os.path.join(output_dir, fname)

        try:
            df = load_signature(in_path)
            exp_cols = [c for c in df.columns if c.startswith("logfc_")]

            if "mean_logfc" not in df.columns or "median_logfc" not in df.columns:
                raise ValueError("Missing mean_logfc or median_logfc")

            ### CHANGED ### - Removed cap_per_direction
            filtered, stats = filter_signature(df, experiment_cols=exp_cols, verbose=verbose)
            filtered.to_csv(out_path, index=False)
            
            ### CHANGED ### - Updated print statements
            print(
                f"{fname:55s} → "
                f"{stats['initial_genes']:7d} → "
                f"{stats['after_qc1']:12d} → "
                f"{stats['final_genes']:7d}"
            )

        except Exception as e:
            print(f"❌ Failed to process {fname}: {e}")

# ----------------------
# CLI Entry
# ----------------------
def main():
    parser = argparse.ArgumentParser(description="Standardize CREEDS disease signatures (QC1 Only, No Fallback, No Cap)")
    parser.add_argument("--input_dir", required=True)
    parser.add_argument("--output_dir", required=True)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    process_directory(args.input_dir, args.output_dir, verbose=args.verbose)

if __name__ == "__main__":
    main()