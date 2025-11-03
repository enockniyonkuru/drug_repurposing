#!/usr/bin/env python3
"""
Validation script to check that filter_cmap_data.py and filter_tahoe_data.py
produce outputs with exactly 85 unique drugs and 12544 genes.
"""

import pandas as pd
import sys
from pathlib import Path

# Expected values
EXPECTED_DRUGS = 85
EXPECTED_GENES = 12544

# Output files from the filter scripts
CMAP_OUTPUT = "../data/Filtered/cmap_shared_drugs_signatures.parquet"
TAHOE_OUTPUT = "../data/Filtered/tahoe_l2fc_shared_genes_drugs.parquet"
TAHOE_META_OUTPUT = "../data/Filtered/tahoe_experiments_shared_meta.parquet"

# Mapping file to get drug information
MAPPING_FILE = "../data/Comparison/shared_drug_experiments_mapping.csv"

def validate_file_exists(filepath):
    """Check if file exists."""
    path = Path(filepath)
    if not path.exists():
        print(f"❌ ERROR: File not found: {filepath}")
        return False
    print(f"✓ File exists: {filepath}")
    return True

def validate_cmap_output():
    """Validate CMap filter output."""
    print("\n" + "="*70)
    print("VALIDATING CMAP OUTPUT")
    print("="*70)
    
    if not validate_file_exists(CMAP_OUTPUT):
        return False
    
    try:
        # Load the CMap output
        cmap_df = pd.read_parquet(CMAP_OUTPUT)
        print(f"✓ Loaded CMap output: shape={cmap_df.shape}")
        
        # Check genes (rows in CMap data, first column is V1 gene ID)
        if 'V1' in cmap_df.columns:
            n_genes = len(cmap_df)
            print(f"  - Number of genes (rows): {n_genes}")
            if n_genes == EXPECTED_GENES:
                print(f"  ✓ Gene count matches expected: {EXPECTED_GENES}")
            else:
                print(f"  ❌ Gene count mismatch! Expected {EXPECTED_GENES}, got {n_genes}")
                print(f"     Difference: {n_genes - EXPECTED_GENES}")
        else:
            print("  ⚠ Warning: 'V1' column not found, cannot validate gene count")
        
        # Check drugs (columns, excluding V1)
        experiment_cols = [col for col in cmap_df.columns if col != 'V1']
        n_experiments = len(experiment_cols)
        print(f"  - Number of experiment columns: {n_experiments}")
        
        # Load mapping to get unique drugs from CMap experiments
        mapping_df = pd.read_csv(MAPPING_FILE)
        
        # Try to convert column names to integers (they might be strings like "V12")
        cmap_exp_ids = []
        for col in experiment_cols:
            try:
                # Handle both direct integers and "V" prefixed strings
                # Column names are V{id+1}, so subtract 1 to get the actual experiment ID
                if isinstance(col, str) and col.startswith('V'):
                    cmap_exp_ids.append(int(col[1:]) - 1)  # Remove 'V' prefix and subtract 1
                else:
                    cmap_exp_ids.append(int(col))
            except (ValueError, TypeError):
                # Column name is not numeric, skip it
                pass
        
        print(f"  - Number of experiment IDs extracted: {len(cmap_exp_ids)}")
        
        # Get unique drugs for these CMap experiments
        cmap_drugs = mapping_df[mapping_df['cmap_experiment_id'].isin(cmap_exp_ids)]
        n_unique_drugs = cmap_drugs['normalized_drug_name'].nunique()
        
        print(f"  - Number of unique drugs: {n_unique_drugs}")
        if n_unique_drugs == EXPECTED_DRUGS:
            print(f"  ✓ Drug count matches expected: {EXPECTED_DRUGS}")
        else:
            print(f"  ❌ Drug count mismatch! Expected {EXPECTED_DRUGS}, got {n_unique_drugs}")
            print(f"     Difference: {n_unique_drugs - EXPECTED_DRUGS}")
            
            # Show which drugs are present
            unique_drugs = sorted(cmap_drugs['normalized_drug_name'].unique())
            print(f"\n  Unique drugs found ({len(unique_drugs)}):")
            for i, drug in enumerate(unique_drugs, 1):
                print(f"    {i:2d}. {drug}")
        
        return n_genes == EXPECTED_GENES and n_unique_drugs == EXPECTED_DRUGS
        
    except Exception as e:
        print(f"❌ ERROR validating CMap output: {e}")
        import traceback
        traceback.print_exc()
        return False

def validate_tahoe_output():
    """Validate Tahoe filter output."""
    print("\n" + "="*70)
    print("VALIDATING TAHOE OUTPUT")
    print("="*70)
    
    if not validate_file_exists(TAHOE_OUTPUT):
        return False
    
    try:
        # Load the Tahoe output
        tahoe_df = pd.read_parquet(TAHOE_OUTPUT)
        print(f"✓ Loaded Tahoe output: shape={tahoe_df.shape}")
        
        # Check genes (columns in Tahoe data)
        n_genes = len(tahoe_df.columns)
        print(f"  - Number of genes (columns): {n_genes}")
        if n_genes == EXPECTED_GENES:
            print(f"  ✓ Gene count matches expected: {EXPECTED_GENES}")
        else:
            print(f"  ❌ Gene count mismatch! Expected {EXPECTED_GENES}, got {n_genes}")
            print(f"     Difference: {n_genes - EXPECTED_GENES}")
        
        # Check experiments (rows)
        n_experiments = len(tahoe_df)
        print(f"  - Number of experiment rows: {n_experiments}")
        
        # Load metadata to get drug information
        if validate_file_exists(TAHOE_META_OUTPUT):
            meta_df = pd.read_parquet(TAHOE_META_OUTPUT)
            print(f"✓ Loaded Tahoe metadata: shape={meta_df.shape}")
            
            # Get unique drugs from metadata
            if 'experiment_id' in meta_df.columns:
                # Match with mapping file
                mapping_df = pd.read_csv(MAPPING_FILE)
                tahoe_exp_ids = meta_df['experiment_id'].unique()
                
                tahoe_drugs = mapping_df[mapping_df['tahoe_experiment_id'].isin(tahoe_exp_ids)]
                n_unique_drugs = tahoe_drugs['normalized_drug_name'].nunique()
                
                print(f"  - Number of unique drugs: {n_unique_drugs}")
                if n_unique_drugs == EXPECTED_DRUGS:
                    print(f"  ✓ Drug count matches expected: {EXPECTED_DRUGS}")
                else:
                    print(f"  ❌ Drug count mismatch! Expected {EXPECTED_DRUGS}, got {n_unique_drugs}")
                    print(f"     Difference: {n_unique_drugs - EXPECTED_DRUGS}")
                    
                    # Show which drugs are present
                    unique_drugs = sorted(tahoe_drugs['normalized_drug_name'].unique())
                    print(f"\n  Unique drugs found ({len(unique_drugs)}):")
                    for i, drug in enumerate(unique_drugs, 1):
                        print(f"    {i:2d}. {drug}")
                
                return n_genes == EXPECTED_GENES and n_unique_drugs == EXPECTED_DRUGS
            else:
                print("  ⚠ Warning: 'experiment_id' column not found in metadata")
                return n_genes == EXPECTED_GENES
        else:
            print("  ⚠ Warning: Metadata file not found, cannot validate drug count")
            return n_genes == EXPECTED_GENES
        
    except Exception as e:
        print(f"❌ ERROR validating Tahoe output: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main validation function."""
    print("\n" + "="*70)
    print("FILTER OUTPUT VALIDATION SCRIPT")
    print("="*70)
    print(f"Expected: {EXPECTED_DRUGS} unique drugs, {EXPECTED_GENES} genes")
    
    cmap_valid = validate_cmap_output()
    tahoe_valid = validate_tahoe_output()
    
    print("\n" + "="*70)
    print("VALIDATION SUMMARY")
    print("="*70)
    
    if cmap_valid:
        print("✓ CMap output: PASSED")
    else:
        print("❌ CMap output: FAILED")
    
    if tahoe_valid:
        print("✓ Tahoe output: PASSED")
    else:
        print("❌ Tahoe output: FAILED")
    
    if cmap_valid and tahoe_valid:
        print("\n🎉 ALL VALIDATIONS PASSED!")
        return 0
    else:
        print("\n⚠️  SOME VALIDATIONS FAILED")
        return 1

if __name__ == "__main__":
    sys.exit(main())
