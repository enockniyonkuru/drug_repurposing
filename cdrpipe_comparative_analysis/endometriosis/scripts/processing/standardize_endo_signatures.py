#!/usr/bin/env python3
"""
Standardize Endometriosis Disease Signatures (Microarray, CREEDS, Single-Cell)

Applies quality control filtering to disease signatures from multiple sources:
- QC1: Mean/median sign agreement
- QC2: Median effect size threshold (abs >= 0.02)
- QC3: Adjusted p-value < 0.05 (where available)

Produces standardized signatures for robust drug discovery analysis.
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
def filter_signature(df, verbose=False):
    """
    Filter signature genes based on QC criteria:
    - QC1: Mean/median sign agreement
    - QC2: Median effect size >= 0.02
    - QC3: Adjusted p-value < 0.05 (if column exists)
    """
    stats = {}
    stats["initial_genes"] = df.shape[0]

    # --- QC STAGE 1: Mean/Median Consistency ---
    same_sign = np.sign(df["mean_logfc"]) == np.sign(df["median_logfc"])
    strong_median = df["median_logfc"].abs() >= 0.02
    
    df_pool = df[same_sign & strong_median].copy()
    stats["after_qc1"] = df_pool.shape[0]

    # --- QC STAGE 2: P-value Filtering ---
    # Check which p-value column exists (adjusted p-value preferred)
    pval_col = None
    if "adj.P.Val" in df_pool.columns:
        pval_col = "adj.P.Val"
    elif "p_val_adj" in df_pool.columns:
        pval_col = "p_val_adj"
    elif "P.Value" in df_pool.columns:
        pval_col = "P.Value"
    elif "p_val" in df_pool.columns:
        pval_col = "p_val"
    
    if pval_col is not None:
        df_pool = df_pool[df_pool[pval_col] < 0.05].copy()
        stats["pval_column"] = pval_col
    else:
        stats["pval_column"] = "None (not available)"
    
    stats["after_qc2"] = df_pool.shape[0]

    # --- RANKING STAGE ---
    # Split by direction and rank by mean_logfc
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
    
    # Exclude Excel files and standard documentation
    files = [f for f in files if not f.endswith((".xlsx", "SUMMARY", "Summary"))]
    
    print(f"\n📂 Found {len(files)} disease signature files.\n")
    
    print(f"{'Filename':55s}   {'Initial':>7s}   {'QC1':>7s}   {'QC2 (PVal)':>12s}   {'Final':>7s}")
    print("-" * 95)

    success_count = 0
    failed_count = 0
    
    for fname in sorted(files):
        in_path = os.path.join(input_dir, fname)
        out_path = os.path.join(output_dir, fname)

        try:
            df = load_signature(in_path)
            
            # Validate required columns
            if "mean_logfc" not in df.columns or "median_logfc" not in df.columns:
                raise ValueError("Missing mean_logfc or median_logfc columns")

            filtered, stats = filter_signature(df, verbose=verbose)
            
            if filtered.shape[0] > 0:
                filtered.to_csv(out_path, index=False)
                success_count += 1
                
                print(
                    f"{fname:55s} → "
                    f"{stats['initial_genes']:7d} → "
                    f"{stats['after_qc1']:7d} → "
                    f"{stats['after_qc2']:12d} → "
                    f"{stats['final_genes']:7d}"
                )
            else:
                failed_count += 1
                print(
                    f"⚠️  {fname:53s} → No genes passed QC filters"
                )

        except Exception as e:
            failed_count += 1
            print(f"❌ Failed to process {fname}: {e}")
    
    print("-" * 95)
    print(f"\n✅ Successfully processed: {success_count} files")
    print(f"❌ Failed: {failed_count} files")

# ----------------------
# CLI Entry
# ----------------------
def main():
    parser = argparse.ArgumentParser(
        description="Standardize endometriosis disease signatures (QC1 + QC2 + PValue filtering)"
    )
    parser.add_argument("--input_dir", required=True, help="Input directory with disease signatures")
    parser.add_argument("--output_dir", required=True, help="Output directory for standardized signatures")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    args = parser.parse_args()

    process_directory(args.input_dir, args.output_dir, verbose=args.verbose)
    print(f"\n📁 Standardized signatures saved to: {args.output_dir}\n")

if __name__ == "__main__":
    main()
