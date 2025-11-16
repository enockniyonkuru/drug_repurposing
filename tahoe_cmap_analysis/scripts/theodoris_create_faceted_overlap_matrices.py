#!/usr/bin/env python3

"""
Generates multiple pairwise disease-drug overlap matrices for the Theodoris Lab list.

1. Loads the collaborator's disease list from a .txt file.
2. Matches these diseases against the processed 'disease_info_data.parquet'.
3. Filters 'known_drug_info_data.parquet' for matched diseases.
4. Creates a main drug set for "all known drugs".
5. Creates individual drug sets for each unique 'drug_status' (e.s., Approved).
6. Creates individual drug sets for each unique 'drug_phase' (e.g., Phase 4).
7. For each drug set, it calculates the pairwise overlap (count of shared drugs)
   between all matched diseases.
8. Saves each overlap analysis as a separate disease-vs-disease matrix
   to a .csv file in a dedicated output directory.

This script is designed to be run from its location in:
'tahoe_cmap_analysis/scripts/'
"""

import pandas as pd
import os
import io
import ast
import re
from collections import defaultdict

# --- 1. Configuration: Path Generation ---

# Get the absolute path of the directory containing this script
# (e.g., /.../tahoe_cmap_analysis/scripts)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Get the base 'tahoe_cmap_analysis' directory (one level up from 'scripts')
BASE_DIR = os.path.dirname(SCRIPT_DIR)

# --- 2. Configuration: File Paths ---

# Input file paths (built from BASE_DIR)
COLLAB_DISEASE_FILE = os.path.join(BASE_DIR, 'data/theodoris_lab/theodoris_lab_diseases_names.txt')
DISEASE_INFO_FILE = os.path.join(BASE_DIR, 'data/processed_data/disease_info_data.parquet')
DRUG_INFO_FILE = os.path.join(BASE_DIR, 'data/processed_data/known_drug_info_data.parquet')

# --- Output file paths ---
# UPDATED: Changed to a directory to hold all the matrices
OUTPUT_MATRIX_DIR = os.path.join(BASE_DIR, 'data/theodoris_lab/overlap_matrices')


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

def load_collaborator_diseases(file_path: str) -> pd.DataFrame:
    """
    Loads the collaborator's .txt file, which is formatted as a
    Python dictionary string.
    """
    print(f"[Info] Loading collaborator file: {file_path}")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Safely parse the string as a Python literal
        disease_dict = ast.literal_eval(content)
        
        df = pd.DataFrame(
            disease_dict.items(),
            columns=['collaborator_disease_name', 'collaborator_id']
        )
        
        # Create a cleaned name column for matching
        df['cleaned_name'] = df['collaborator_disease_name'].apply(clean_text)
        print(f"    -> Loaded {len(df)} diseases from collaborator.")
        return df

    except FileNotFoundError:
        print(f"    [Error] Collaborator file not found: {file_path}")
        return pd.DataFrame()
    except Exception as e:
        print(f"    [Error] Failed to parse collaborator file: {e}")
        return pd.DataFrame()

def match_diseases(df_collab: pd.DataFrame, df_disease_info: pd.DataFrame) -> pd.DataFrame:
    """
    Matches collaborator diseases to disease info using a two-pass strategy.
    """
    print("[Info] Starting 2-pass disease matching...")
    
    # --- Pass 1: Match by 'disease_name' ---
    
    # Create a cleaned name -> disease_id map
    if 'cleaned_name' not in df_disease_info.columns:
        df_disease_info['cleaned_name'] = df_disease_info['disease_name'].apply(clean_text)
    name_to_id_map = df_disease_info.set_index('cleaned_name')['disease_id'].to_dict()
    
    # Apply the map
    df_collab['disease_id'] = df_collab['cleaned_name'].map(name_to_id_map)
    df_collab['match_type'] = df_collab['disease_id'].apply(lambda x: 'name' if pd.notna(x) else None)
    
    matched_count_pass1 = df_collab['disease_id'].notna().sum()
    print(f"    -> Pass 1 (Name): Matched {matched_count_pass1} diseases.")

    # --- Pass 2: Match by 'disease_synonyms' for remaining diseases ---
    
    unmatched_mask = df_collab['disease_id'].isna()
    if unmatched_mask.any():
        print("[Info] Building synonym map for Pass 2...")
        
        # Build a comprehensive map from cleaned synonym -> disease_id
        synonym_to_id_map = {}
        
        # Define synonym keys from the original struct
        synonym_keys = [
            'hasExactSynonym', 'hasRelatedSynonym', 
            'hasNarrowSynonym', 'hasBroadSynonym'
        ]
        
        for _, row in df_disease_info.iterrows():
            disease_id = row['disease_id']
            synonyms_struct = row['disease_synonyms']
            
            if not isinstance(synonyms_struct, dict):
                continue
                
            all_synonyms = []
            for key in synonym_keys:
                # Safely get synonym list, default to empty list
                syn_list = synonyms_struct.get(key)
                if syn_list is not None and len(syn_list) > 0:
                    all_synonyms.extend(syn_list)
            
            for syn in all_synonyms:
                cleaned_syn = clean_text(syn)
                if cleaned_syn:
                    synonym_to_id_map[cleaned_syn] = disease_id
        
        print(f"    -> Built map with {len(synonym_to_id_map)} unique synonyms.")

        # Apply the synonym map to the remaining unmatched diseases
        unmatched_names = df_collab.loc[unmatched_mask, 'cleaned_name']
        df_collab.loc[unmatched_mask, 'disease_id'] = unmatched_names.map(synonym_to_id_map)
        
        # Update match_type for new matches
        new_matches_mask = unmatched_mask & df_collab['disease_id'].notna()
        df_collab.loc[new_matches_mask, 'match_type'] = 'synonym'

    total_matched = df_collab['disease_id'].notna().sum()
    print(f"    -> Pass 2 (Synonym): Matched {total_matched - matched_count_pass1} new diseases.")
    print(f"    -> Total Matched: {total_matched} / {len(df_collab)}")
    
    return df_collab

def generate_clean_key(prefix: str, value: str) -> str:
    """Helper to create clean filenames."""
    clean_value = str(value).replace(" ", "_").replace("-", "_").lower()
    return f"{prefix}_{clean_value}"

# --- 4. Main Execution ---

def main():
    """
    Main function to run the overlap matrix generation.
    """
    print("Starting Theodoris Lab Disease Overlap Matrix Generation...")

    # Load collaborator data
    df_collab = load_collaborator_diseases(COLLAB_DISEASE_FILE)
    if df_collab.empty:
        print("[Fatal Error] Could not load collaborator data. Exiting.")
        return

    # Load processed Open Targets data
    try:
        df_disease_info = pd.read_parquet(DISEASE_INFO_FILE)
        df_drug_info = pd.read_parquet(DRUG_INFO_FILE)
        print(f"[Info] Loaded 'disease_info_data.parquet' ({len(df_disease_info)} rows)")
        print(f"[Info] Loaded 'known_drug_info_data.parquet' ({len(df_drug_info)} rows)")
    except FileNotFoundError as e:
        print(f"[Fatal Error] Could not find processed data file: {e}. Exiting.")
        return
    except Exception as e:
        print(f"[Fatal Error] Could not read processed data: {e}. Exiting.")
        return

    # --- Match diseases ---
    df_matched = match_diseases(df_collab, df_disease_info)
    
    # --- Get list of matched diseases ---
    df_matched_only = df_matched.dropna(subset=['disease_id']).copy()
    
    # Get a mapping of disease_id -> collaborator_name
    id_to_name_map = df_matched_only.set_index('disease_id')['collaborator_disease_name'].to_dict()
    
    # Get sorted lists of the names and corresponding IDs
    disease_names_sorted = sorted(id_to_name_map.values())
    name_to_id_map = {v: k for k, v in id_to_name_map.items()}
    disease_ids_sorted = [name_to_id_map[name] for name in disease_names_sorted]

    if not disease_ids_sorted:
        print("[Info] No diseases were matched. Exiting.")
        return
        
    print(f"[Info] Found {len(disease_ids_sorted)} unique matched disease IDs.")

    # --- Filter drug data ---
    relevant_drugs_df = df_drug_info[
        df_drug_info['disease_id'].isin(disease_ids_sorted)
    ].copy()
    
    if relevant_drugs_df.empty:
        print("[Warning] No known drugs found for any of the matched diseases. Exiting.")
        return
    else:
        print(f"    -> Found {len(relevant_drugs_df)} drug entries for these diseases.")
    
    # --- NEW: Handle NaNs in status and phase columns ---
    relevant_drugs_df['drug_phase'] = relevant_drugs_df['drug_phase'].fillna('Unknown')
    relevant_drugs_df['drug_status'] = relevant_drugs_df['drug_status'].fillna('Unknown')
    
    # --- NEW: Create Grouped Drug Sets for Each Filter ---
    print("[Info] Creating drug sets for all filters...")
    
    all_drug_sets = {} # This will hold all our different drug set dictionaries

    # 1. The "all drugs" matrix (original behavior)
    all_drug_sets['all_known_drugs'] = relevant_drugs_df.groupby('disease_id')['drug_id'].apply(set).to_dict()

    # 2. Matrices for each 'drug_status'
    all_statuses = relevant_drugs_df['drug_status'].unique()
    print(f"    -> Found statuses: {list(all_statuses)}")
    for status in all_statuses:
        key_name = generate_clean_key('status', status)
        df_filtered = relevant_drugs_df[relevant_drugs_df['drug_status'] == status]
        all_drug_sets[key_name] = df_filtered.groupby('disease_id')['drug_id'].apply(set).to_dict()

    # 3. Matrices for each 'drug_phase'
    all_phases = relevant_drugs_df['drug_phase'].unique()
    print(f"    -> Found phases: {list(all_phases)}")
    for phase in all_phases:
        key_name = generate_clean_key('phase', phase)
        df_filtered = relevant_drugs_df[relevant_drugs_df['drug_phase'] == phase]
        all_drug_sets[key_name] = df_filtered.groupby('disease_id')['drug_id'].apply(set).to_dict()

    # --- NEW: Main loop to build and save all matrices ---
    print("\n[Info] Starting matrix generation for all filters...")
    
    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_MATRIX_DIR, exist_ok=True)
    
    for matrix_key, disease_drug_sets in all_drug_sets.items():
        print(f"--- Building matrix for: {matrix_key} ---")
        
        # Initialize an empty matrix (DataFrame)
        overlap_matrix = pd.DataFrame(index=disease_names_sorted, columns=disease_names_sorted, dtype=int)
        
        # Iterate over all pairs of diseases to populate the matrix
        for i, row_id in enumerate(disease_ids_sorted):
            row_name = id_to_name_map[row_id]
            set_A = disease_drug_sets.get(row_id, set())
            
            # Simple progress print
            # if (i + 1) % 10 == 0 or i == len(disease_ids_sorted) - 1:
            #     print(f"    -> Processing row {i+1}/{len(disease_ids_sorted)}: {row_name}")

            for j, col_id in enumerate(disease_ids_sorted):
                col_name = id_to_name_map[col_id]

                if j < i:
                    overlap_matrix.loc[row_name, col_name] = overlap_matrix.loc[col_name, row_name]
                    continue

                set_B = disease_drug_sets.get(col_id, set())
                overlap_count = len(set_A.intersection(set_B))
                
                overlap_matrix.loc[row_name, col_name] = overlap_count
                overlap_matrix.loc[col_name, row_name] = overlap_count

        # --- Save This Matrix to CSV ---
        
        # Generate dynamic filename
        output_filename = f"overlap_matrix_{matrix_key}.csv"
        output_path = os.path.join(OUTPUT_MATRIX_DIR, output_filename)
        
        # Save the matrix
        overlap_matrix.to_csv(output_path, index=True, index_label='disease_name')
        print(f"[Success] Saved matrix to: {output_path}")

    print("\nAll analysis complete.")


if __name__ == "__main__":
    main()