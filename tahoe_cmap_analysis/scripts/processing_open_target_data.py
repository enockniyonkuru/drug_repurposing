#!/usr/bin/env python3

"""
Processes Open Targets data by:
1. Loading and renaming disease ontology data.
2. Loading, concatenating, and renaming known drug data.
3. Saving processed data to new Parquet files.
4. Generating text reports describing the new datasets.

This script is designed to be run from its location in:
'tahoe_cmap_analysis/scripts/'

It will access data from 'tahoe_cmap_analysis/data/drug_evidence/'
and write outputs to:
- 'tahoe_cmap_analysis/data/processed_data/'
- 'tahoe_cmap_analysis/reports/'

Required packages:
- pandas
- pyarrow (or fastparquet)
"""

import pandas as pd
import os
import io

# --- 1. Configuration: Path Generation ---

# Get the absolute path of the directory containing this script
# (e.g., /.../tahoe_cmap_analysis/scripts)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Get the base 'tahoe_cmap_analysis' directory (one level up from 'scripts')
BASE_DIR = os.path.dirname(SCRIPT_DIR)


# --- 2. Configuration: File Paths and Rename Maps ---

# Input file paths (now built from BASE_DIR)
DISEASE_FILE_PATH = os.path.join(BASE_DIR, 'data/drug_evidence/disease.parquet')
DRUG_FILE_PATHS = [
    os.path.join(BASE_DIR, 'data/drug_evidence/part-00000-ecc6ecd3-bcb5-4787-b899-6b8b54085883-c000.snappy.parquet'),
    os.path.join(BASE_DIR, 'data/drug_evidence/part-00001-ecc6ecd3-bcb5-4787-b899-6b8b54085883-c000.snappy.parquet')
]

# Output directories (now built from BASE_DIR)
OUTPUT_DATA_DIR = os.path.join(BASE_DIR, 'data/processed_data')
OUTPUT_REPORT_DIR = os.path.join(BASE_DIR, 'reports')

# Output file paths (these are built from the new output dirs)
OUTPUT_DISEASE_FILE = os.path.join(OUTPUT_DATA_DIR, 'disease_info_data.parquet')
OUTPUT_DRUG_FILE = os.path.join(OUTPUT_DATA_DIR, 'known_drug_info_data.parquet')
OUTPUT_DISEASE_REPORT = os.path.join(OUTPUT_REPORT_DIR, 'disease_info_data_report.txt')
OUTPUT_DRUG_REPORT = os.path.join(OUTPUT_REPORT_DIR, 'known_drug_info_data_report.txt')

# Column rename maps
# Note: Keys are the *original* column names from the schema.
# Values are the *new* column names you requested.
DISEASE_RENAMES = {
    'id': 'disease_id',
    'name': 'disease_name',
    'synonyms': 'disease_synonyms',
    'ontology': 'disease_ontology_sources', # Mapped from 'ontology' as 'ontology sources' isn't a valid column name
    'parents': 'disease_parents',
    'children': 'disease_children',
    'ancestors': 'disease_ancestors',      # Mapped from 'ancestors' (lowercase 'a')
    'therapeuticAreas': 'disease_therapeutic_areas'
}

KNOWN_DRUG_RENAMES = {
    'drugId': 'drug_id',                  # Mapped from 'drugId' (camelCase)
    'targetId': 'target_id',
    'diseaseId': 'disease_id',
    'phase': 'drug_phase',
    'status': 'drug_status',
    'urls': 'drug_urls',
    'label': 'drug_disease_label',
    'targetClass': 'drug_target_class',
    'prefName': 'drug_common_name',
    'tradeNames': 'drug_brand_name',          # Mapped from 'tradeNames' (plural)
    'synonyms': 'drug_synonyms',
    'drugType': 'drug_type',
    'mechanismOfAction': 'drug_mechanism_of_action',
    'targetName': 'drug_target_name',
    'ancestors': 'drug_ancestors',
    'approvedName': 'drug_gene_approved_name',
    'approvedSymbol': 'drug_gene_approved_symbol'
}


# --- 3. Helper Function: Generate Data Report ---

def generate_report(df: pd.DataFrame, rename_map: dict, report_path: str, title: str):
    """
    Generates a text report for a DataFrame, including schema,
    rename map, and data sample.
    """
    print(f"    -> Generating report: {report_path}")
    try:
        # Create the full directory path if it doesn't exist
        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(f"--- Data Report: {title} ---\n")
            f.write(f"Generated: {pd.Timestamp.now()}\n")
            f.write(f"Source File(s): See processing script\n")
            
            # Get relative output file path
            output_file = report_path.replace('_report.txt', '.parquet').replace('reports', 'data/processed_data')
            relative_data_path = os.path.relpath(output_file, BASE_DIR)
            f.write(f"Output File: {relative_data_path}\n")
            
            f.write("\n\n--- 1. Data Schema (df.info()) ---\n")
            # Capture df.info() output
            with io.StringIO() as buffer:
                df.info(buf=buffer)
                f.write(buffer.getvalue())

            f.write("\n\n--- 2. Column Renaming and Data Types ---\n")
            f.write("This section shows the mapping from the original dataset to this one.\n")
            for orig_name, new_name in rename_map.items():
                if new_name in df.columns:
                    col_type = df[new_name].dtype
                    f.write(f"  - Original: '{orig_name}'\n")
                    f.write(f"    New:      '{new_name}'\n")
                    f.write(f"    Type:     {col_type}\n")

            f.write("\n\n--- 3. Data Content Sample (First 5 Rows) ---\n")
            f.write(df.head().to_string())
            
            f.write("\n\n--- End of Report ---")
        
    except Exception as e:
        print(f"    [Error] Failed to write report {report_path}: {e}")


# --- 4. Processing Function: Disease Data ---

def process_disease_data():
    """
    Loads, filters, renames, and saves the disease ontology data.
    """
    print("[Task 1] Processing Disease Ontology Data...")
    try:
        df_disease = pd.read_parquet(DISEASE_FILE_PATH)
        
        # Filter to only the columns we care about
        cols_to_keep = list(DISEASE_RENAMES.keys())
        
        # Check for missing columns
        missing_cols = [col for col in cols_to_keep if col not in df_disease.columns]
        if missing_cols:
            print(f"    [Warning] Missing original columns in '{DISEASE_FILE_PATH}': {missing_cols}")
            # Remove missing columns from our 'keep' list to avoid errors
            cols_to_keep = [col for col in cols_to_keep if col in df_disease.columns]

        df_processed = df_disease[cols_to_keep].copy()
        
        # Rename columns
        df_processed = df_processed.rename(columns=DISEASE_RENAMES)
        
        # Save processed data
        os.makedirs(os.path.dirname(OUTPUT_DISEASE_FILE), exist_ok=True)
        df_processed.to_parquet(OUTPUT_DISEASE_FILE, index=False)
        print(f"    -> Saved processed disease data to: {OUTPUT_DISEASE_FILE}")
        
        return df_processed

    except FileNotFoundError:
        print(f"    [Error] Input file not found: {DISEASE_FILE_PATH}")
        return None
    except Exception as e:
        print(f"    [Error] Failed to process disease data: {e}")
        return None


# --- 5. Processing Function: Known Drug Data ---

def process_drug_data():
    """
    Loads, concatenates, filters, renames, and saves the known drug data.
    """
    print("[Task 2] Processing Known Drug Data...")
    df_list = []
    try:
        for fpath in DRUG_FILE_PATHS:
            df_list.append(pd.read_parquet(fpath))
        
        # Combine the two data parts
        df_drug = pd.concat(df_list, ignore_index=True)
        print(f"    -> Combined {len(DRUG_FILE_PATHS)} files. Total rows: {len(df_drug)}")

        # Filter to only the columns we care about
        cols_to_keep = list(KNOWN_DRUG_RENAMES.keys())
        
        # Check for missing columns
        missing_cols = [col for col in cols_to_keep if col not in df_drug.columns]
        if missing_cols:
            print(f"    [Warning] Missing original columns in drug files: {missing_cols}")
            cols_to_keep = [col for col in cols_to_keep if col in df_drug.columns]
        
        df_processed = df_drug[cols_to_keep].copy()
        
        # Rename columns
        df_processed = df_processed.rename(columns=KNOWN_DRUG_RENAMES)
        
        # Save processed data
        os.makedirs(os.path.dirname(OUTPUT_DRUG_FILE), exist_ok=True)
        df_processed.to_parquet(OUTPUT_DRUG_FILE, index=False)
        print(f"    -> Saved processed drug data to: {OUTPUT_DRUG_FILE}")

        return df_processed

    except FileNotFoundError:
        print(f"    [Error] Input file(s) not found. Checked paths: {DRUG_FILE_PATHS}")
        return None
    except Exception as e:
        print(f"    [Error] Failed to process drug data: {e}")
        return None


# --- 6. Main Execution ---

def main():
    """
    Main function to run the data processing pipeline.
    """
    print("Starting Open Targets Data Processing...")
    
    # NOTE: Directories are created inside the helper functions
    # to ensure they exist before writing files.
    
    # Process Disease Data
    df_disease_processed = process_disease_data()
    
    # Process Drug Data
    df_drug_processed = process_drug_data()
    
    # Generate Reports
    print("[Task 3] Generating Reports...")
    if df_disease_processed is not None:
        generate_report(df_disease_processed, DISEASE_RENAMES, OUTPUT_DISEASE_REPORT, "Disease Info Data")
        
    if df_drug_processed is not None:
        generate_report(df_drug_processed, KNOWN_DRUG_RENAMES, OUTPUT_DRUG_REPORT, "Known Drug Info Data")

    print("\nAll processing complete.")
    print(f"Processed data saved to: '{OUTPUT_DATA_DIR}/'")
    print(f"Reports saved to: '{OUTPUT_REPORT_DIR}/'")


if __name__ == "__main__":
    main()
