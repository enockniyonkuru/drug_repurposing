#!/usr/bin/env python3

"""
Processes disease signature files from specified folders.

1. Scans folders for files ending in '_signature.csv'.
2. Extracts disease names from filenames (e.g.,
   'Acute_myocardial_infarction_signature.csv' -> 'Acute myocardial infarction').
3. Matches extracted names against 'disease_info_data.parquet'
   using a two-pass approach (name, then synonyms) to get disease IDs.
4. For each disease, queries 'known_drug_info_data.parquet' for drug counts,
   pivoting by status and phase.
5. Saves a separate analysis CSV file for each input folder.
6. Generates a single summary report for all processed folders.

This script is designed to be run from its location in:
'tahoe_cmap_analysis/scripts/'
"""

import pandas as pd
import os
import io
import re
import glob

# --- 1. Configuration: Path Generation ---

# Get the absolute path of the directory containing this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Get the base 'tahoe_cmap_analysis' directory (one level up)
BASE_DIR = os.path.dirname(SCRIPT_DIR)

# --- 2. Configuration: File Paths ---

# Source data (processed in Task 1)
DISEASE_INFO_FILE = os.path.join(BASE_DIR, 'data/processed_data/disease_info_data.parquet')
DRUG_INFO_FILE = os.path.join(BASE_DIR, 'data/processed_data/known_drug_info_data.parquet')

# Input directories for disease signatures
INPUT_DIRS = {
    'creeds_automatic': os.path.join(BASE_DIR, 'data/disease_signatures/creeds_automatic_disease_signatures'),
    'creeds_manual': os.path.join(BASE_DIR, 'data/disease_signatures/creeds_manual_disease_signatures'),
    'sirota_lab': os.path.join(BASE_DIR, 'data/disease_signatures/sirota_lab_disease_signatures')
}

# Output locations
# We'll save the analysis CSVs in a new 'analysis_results' subfolder
OUTPUT_CSV_DIR = os.path.join(BASE_DIR, 'data/disease_signatures/analysis_results')
OUTPUT_REPORT_FILE = os.path.join(BASE_DIR, 'reports/disease_signature_analysis_report.txt')


# --- 3. Helper Functions ---

def clean_text(text: str) -> str:
    """
    Cleans a text string for matching:
    - Converts to lowercase
    - Removes punctuation and non-alphanumeric characters (except spaces)
    - Strips leading/trailing whitespace
    """
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text) # Keep words and spaces
    text = re.sub(r'\s+', ' ', text) # Condense multiple spaces
    return text.strip()

def extract_diseases_from_filenames(input_dir: str) -> pd.DataFrame:
    """
    Scans a directory for '*_signature.csv' files, extracts disease names,
    and returns a DataFrame ready for matching.
    """
    file_pattern = os.path.join(input_dir, "*_signature.csv")
    file_paths = glob.glob(file_pattern)
    
    if not file_paths:
        print(f"    [Warning] No '*_signature.csv' files found in: {input_dir}")
        return pd.DataFrame()

    data = []
    for fpath in file_paths:
        filename = os.path.basename(fpath)
        # Remove suffix and replace underscores
        disease_name = filename.replace("_signature.csv", "").replace("_", " ")
        cleaned_name = clean_text(disease_name)
        data.append([filename, disease_name, cleaned_name])
    
    df = pd.DataFrame(
        data,
        columns=['original_filename', 'extracted_disease_name', 'cleaned_name']
    )
    print(f"    -> Found and parsed {len(df)} signature files.")
    return df

def match_diseases(df_collab: pd.DataFrame, df_disease_info: pd.DataFrame) -> pd.DataFrame:
    """
    Matches collaborator diseases to disease info using a two-pass strategy.
    Assumes df_collab has a 'cleaned_name' column.
    """
    print("    -> Starting 2-pass disease matching...")
    
    # --- Pass 1: Match by 'disease_name' ---
    if 'cleaned_name' not in df_disease_info.columns:
        df_disease_info['cleaned_name'] = df_disease_info['disease_name'].apply(clean_text)
    
    name_to_id_map = df_disease_info.set_index('cleaned_name')['disease_id'].to_dict()
    df_collab['disease_id'] = df_collab['cleaned_name'].map(name_to_id_map)
    df_collab['match_type'] = df_collab['disease_id'].apply(lambda x: 'name' if pd.notna(x) else None)
    
    matched_count_pass1 = df_collab['disease_id'].notna().sum()
    print(f"        -> Pass 1 (Name): Matched {matched_count_pass1} diseases.")

    # --- Pass 2: Match by 'disease_synonyms' for remaining diseases ---
    unmatched_mask = df_collab['disease_id'].isna()
    if unmatched_mask.any():
        print("        -> Building synonym map for Pass 2...")
        
        synonym_to_id_map = {}
        synonym_keys = ['hasExactSynonym', 'hasRelatedSynonym', 'hasNarrowSynonym', 'hasBroadSynonym']
        
        for _, row in df_disease_info.iterrows():
            disease_id = row['disease_id']
            synonyms_struct = row['disease_synonyms']
            
            # Handle both dict and non-dict types safely
            # Check if it's a dict first to avoid ambiguous truth value errors
            if not isinstance(synonyms_struct, dict):
                continue
                
            all_synonyms = []
            for key in synonym_keys:
                syn_list = synonyms_struct.get(key)
                if syn_list is not None and len(syn_list) > 0:
                    all_synonyms.extend(syn_list)
            
            for syn in all_synonyms:
                cleaned_syn = clean_text(syn)
                if cleaned_syn:
                    synonym_to_id_map[cleaned_syn] = disease_id
        
        unmatched_names = df_collab.loc[unmatched_mask, 'cleaned_name']
        df_collab.loc[unmatched_mask, 'disease_id'] = unmatched_names.map(synonym_to_id_map)
        
        new_matches_mask = unmatched_mask & df_collab['disease_id'].notna()
        df_collab.loc[new_matches_mask, 'match_type'] = 'synonym'
        
        total_matched = df_collab['disease_id'].notna().sum()
        print(f"        -> Pass 2 (Synonym): Matched {total_matched - matched_count_pass1} new diseases.")
    
    print(f"    -> Total Matched: {df_collab['disease_id'].notna().sum()} / {len(df_collab)}")
    return df_collab

def generate_summary_report(results_list: list, report_path: str):
    """
    Generates a single text report summarizing all analysis runs.
    
    results_list is a list of tuples:
    (source_name, df_analysis)
    """
    print(f"\n[Info] Generating summary report: {report_path}")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    
    try:
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("--- Summary Report: Disease Signature Analysis ---\n")
            f.write(f"Generated: {pd.Timestamp.now()}\n\n")
            
            for source_name, df in results_list:
                f.write(f"--- Analysis for: {source_name} ---\n")
                
                total_files = len(df)
                total_matched = df['disease_id'].notna().sum()
                
                f.write(f"Total signature files processed: {total_files}\n")
                f.write(f"Total diseases matched to Open Targets ID: {total_matched}\n")
                f.write(f"Total unmatched diseases: {total_files - total_matched}\n")
                
                if total_matched > 0:
                    total_drugs = df['total_unique_drugs'].sum()
                    f.write(f"Total unique drug associations found (for matched): {total_drugs}\n")
                
                f.write("Unmatched disease names (from filenames):\n")
                unmatched_names = df[df['disease_id'].isna()]['extracted_disease_name'].tolist()
                
                if unmatched_names:
                    for name in unmatched_names:
                        f.write(f"  - {name}\n")
                else:
                    f.write("  (All diseases were successfully matched)\n")
                
                f.write("\n") # Add space before next section
            
            f.write("--- End of Report ---")
            
    except Exception as e:
        print(f"    [Error] Failed to write summary report: {e}")


# --- 4. Core Processing Function ---

def process_signature_folder(input_dir: str, output_csv_path: str, df_disease_info: pd.DataFrame, df_drug_info: pd.DataFrame) -> pd.DataFrame:
    """
    Runs the full pipeline for a single signature folder.
    """
    # 1. Get disease names from filenames
    df_analysis = extract_diseases_from_filenames(input_dir)
    if df_analysis.empty:
        return pd.DataFrame() # Return empty if no files
        
    # 2. Match diseases
    df_analysis = match_diseases(df_analysis, df_disease_info)
    
    # 3. Get drug info for matched diseases
    matched_disease_ids = df_analysis['disease_id'].dropna().unique()
    
    all_pivot_cols = []
    
    if len(matched_disease_ids) > 0:
        relevant_drugs_df = df_drug_info[
            df_drug_info['disease_id'].isin(matched_disease_ids)
        ].copy() # Use .copy() to avoid SettingWithCopyWarning
        
        if not relevant_drugs_df.empty:
            print(f"    -> Found {len(relevant_drugs_df)} drug entries for matched diseases.")
            
            # 1. Total unique drugs per disease
            drugs_per_disease = relevant_drugs_df.groupby('disease_id')['drug_id'].nunique()
            drugs_per_disease = drugs_per_disease.to_frame('total_unique_drugs')

            # 2. Pivot on drug status
            status_pivot = pd.crosstab(
                relevant_drugs_df['disease_id'],
                relevant_drugs_df['drug_status']
            ).add_prefix('status_')
            all_pivot_cols.extend(status_pivot.columns.tolist())

            # 3. Pivot on drug phase
            relevant_drugs_df['drug_phase'] = relevant_drugs_df['drug_phase'].fillna('Unknown')
            phase_pivot = pd.crosstab(
                relevant_drugs_df['disease_id'],
                relevant_drugs_df['drug_phase']
            ).add_prefix('phase_')
            all_pivot_cols.extend(phase_pivot.columns.tolist())

            # 4. Merge analyses back to the main dataframe
            df_analysis = df_analysis.merge(drugs_per_disease, on='disease_id', how='left')
            df_analysis = df_analysis.merge(status_pivot, on='disease_id', how='left')
            df_analysis = df_analysis.merge(phase_pivot, on='disease_id', how='left')

        else:
            print("    -> No drug entries found for any matched diseases.")
            df_analysis['total_unique_drugs'] = 0
    else:
        print("    -> No diseases were matched. Skipping drug analysis.")
        df_analysis['total_unique_drugs'] = 0

    # 4. Clean up and Save
    # Fill NaNs created by merges (e.g., matched diseases with 0 drugs)
    df_analysis[all_pivot_cols] = df_analysis[all_pivot_cols].fillna(0).astype(int)
    df_analysis['total_unique_drugs'] = df_analysis['total_unique_drugs'].fillna(0).astype(int)
    
    # Reorder columns for clarity
    core_cols = ['original_filename', 'extracted_disease_name', 'disease_id', 'match_type', 'total_unique_drugs']
    other_cols = [col for col in df_analysis.columns if col not in core_cols and col != 'cleaned_name']
    df_final = df_analysis[core_cols + sorted(other_cols)]
    
    df_final.to_csv(output_csv_path, index=False)
    print(f"    -> Analysis saved to: {output_csv_path}")
    
    return df_final


# --- 5. Main Execution ---

def main():
    """
    Main function to run the full analysis pipeline.
    """
    print("Starting Disease Signature Analysis...")
    
    # Create output directory
    os.makedirs(OUTPUT_CSV_DIR, exist_ok=True)

    # Load main data sources
    try:
        df_disease_info = pd.read_parquet(DISEASE_INFO_FILE)
        # Pre-clean the disease names once
        df_disease_info['cleaned_name'] = df_disease_info['disease_name'].apply(clean_text)
        
        df_drug_info = pd.read_parquet(DRUG_INFO_FILE)
        print(f"[Info] Loaded 'disease_info_data.parquet' ({len(df_disease_info)} rows)")
        print(f"[Info] Loaded 'known_drug_info_data.parquet' ({len(df_drug_info)} rows)\n")
    except FileNotFoundError as e:
        print(f"[Fatal Error] Could not find processed data file: {e}. Exiting.")
        return
    except Exception as e:
        print(f"[Fatal Error] Could not read processed data: {e}. Exiting.")
        return

    # --- Process each folder ---
    
    analysis_results = [] # To store DFs for final report
    
    for source_name, input_dir in INPUT_DIRS.items():
        print(f"[Processing] Starting analysis for: {source_name}")
        
        output_csv_path = os.path.join(OUTPUT_CSV_DIR, f"{source_name}_analysis.csv")
        
        try:
            df_result = process_signature_folder(
                input_dir,
                output_csv_path,
                df_disease_info, # Pass the pre-loaded DF
                df_drug_info     # Pass the pre-loaded DF
            )
            
            if not df_result.empty:
                analysis_results.append((source_name, df_result))
            
        except Exception as e:
            print(f"    [Error] Failed to process {source_name}. Reason: {e}")
        
        print("-" * 40) # Separator

    # --- Generate final summary report ---
    if analysis_results:
        generate_summary_report(analysis_results, OUTPUT_REPORT_FILE)
    else:
        print("[Info] No results were generated. Skipping summary report.")

    print("\nAll processing complete.")


if __name__ == "__main__":
    main()
