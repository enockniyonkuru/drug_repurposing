#!/usr/bin/env python3

"""
Performs analysis on a collaborator's list of diseases (Theodoris Lab).

1. Loads the collaborator's disease list from a .txt file.
2. Matches these diseases against the processed 'disease_info_data.parquet'
   using a two-pass approach (name, then synonyms).
3. Filters 'known_drug_info_data.parquet' for matched diseases.
4. Saves the *detailed* drug information to a new Parquet file.
5. Aggregates drug data (counts, pivots) and saves to a summary CSV file.
6. Generates a text report summarizing the findings and output files.

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
# UPDATED: Changed to .csv and renamed for clarity
OUTPUT_ANALYSIS_SUMMARY_FILE = os.path.join(BASE_DIR, 'data/theodoris_lab/theodoris_lab_disease_analysis_summary.csv')
# NEW: Added a new file for the drug details
OUTPUT_DRUG_DETAILS_FILE = os.path.join(BASE_DIR, 'data/theodoris_lab/theodoris_lab_disease_drug_details.parquet')

OUTPUT_REPORT_FILE = os.path.join(BASE_DIR, 'data/theodoris_lab/theodoris_lab_disease_analysis_report.txt')


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
                    # This map can be overwritten, but it's a fast approach
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

def generate_analysis_report(final_df: pd.DataFrame, unmatched_names: list, report_path: str):
    """
    Generates a text report summarizing the analysis.
    """
    print(f"[Info] Generating analysis report: {report_path}")
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    
    total_collab_diseases = len(final_df)
    total_matched = final_df['disease_id'].notna().sum()
    
    try:
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("--- Analysis Report: Theodoris Lab Disease List ---\n\n")
            
            f.write("--- 1. Summary ---\n")
            f.write(f"Generated: {pd.Timestamp.now()}\n")
            f.write(f"Source Disease List: {os.path.basename(COLLAB_DISEASE_FILE)}\n")
            
            # UPDATED: Show both output files
            f.write(f"Analysis Summary CSV (Counts): {os.path.basename(OUTPUT_ANALYSIS_SUMMARY_FILE)}\n")
            f.write(f"Analysis Details Parquet (Drugs): {os.path.basename(OUTPUT_DRUG_DETAILS_FILE)}\n\n")

            f.write("--- 2. Matching Statistics ---\n")
            f.write(f"Total diseases in collaborator list: {total_collab_diseases}\n")
            f.write(f"Total diseases matched to Open Targets ID: {total_matched}\n")
            f.write(f"Total diseases NOT found: {total_collab_diseases - total_matched}\n\n")
            
            if total_matched > 0:
                match_counts = final_df['match_type'].value_counts()
                f.write(f"Matched by exact name: {match_counts.get('name', 0)}\n")
                f.write(f"Matched by synonym: {match_counts.get('synonym', 0)}\n\n")
            
            f.write("--- 3. Drug Analysis Summary (for matched diseases) ---\n")
            if total_matched > 0:
                diseases_with_drugs = final_df['total_unique_drugs'].gt(0).sum()
                f.write(f"Matched diseases with at least one known drug: {diseases_with_drugs}\n")
                
                total_drugs = final_df['total_unique_drugs'].sum()
                f.write(f"Total unique drug associations found: {total_drugs}\n")
                
                avg_drugs = final_df['total_unique_drugs'].mean()
                f.write(f"Average unique drugs per matched disease: {avg_drugs:.2f}\n")
            else:
                f.write("No diseases were matched, so no drug analysis was performed.\n")

            f.write("\n\n--- 4. Unmatched Disease Names ---\n")
            if unmatched_names:
                f.write("The following diseases from the list could not be matched:\n")
                for name in unmatched_names:
                    f.write(f"  - {name}\n")
            else:
                f.write("All diseases were successfully matched.\n")
                
            # UPDATED: Note this is from the CSV
            f.write("\n\n--- 5. Sample of Final Analysis Summary (from .csv file) ---\n")
            f.write(final_df.head().to_string())
            
            # NEW: Add sample of detailed drug data if file exists
            f.write("\n\n--- 6. Sample of Detailed Drug Data (from .parquet file) ---\n")
            if os.path.exists(OUTPUT_DRUG_DETAILS_FILE):
                try:
                    df_drug_sample = pd.read_parquet(OUTPUT_DRUG_DETAILS_FILE)
                    f.write(f"Total rows in detailed drug file: {len(df_drug_sample)}\n")
                    f.write(f"Columns: {', '.join(df_drug_sample.columns.tolist())}\n\n")
                    f.write("First 2 rows:\n")
                    f.write(df_drug_sample.head(2).to_string())
                except Exception as e:
                    f.write(f"Could not read parquet file: {e}\n")
            else:
                f.write("Detailed drug data file not found.\n")
            
            f.write("\n\n--- End of Report ---")

    except Exception as e:
        print(f"    [Error] Failed to write report: {e}")

# --- 4. Main Execution ---

def main():
    """
    Main function to run the analysis pipeline.
    """
    print("Starting Theodoris Lab Disease Analysis...")

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
    
    # Get list of matched disease IDs
    matched_disease_ids = df_matched['disease_id'].dropna().unique()
    
    final_analysis_df = df_matched.copy()
    
    if len(matched_disease_ids) > 0:
        print(f"[Info] Found {len(matched_disease_ids)} unique matched disease IDs.")
        
        # --- Filter drug data ---
        relevant_drugs_df = df_drug_info[
            df_drug_info['disease_id'].isin(matched_disease_ids)
        ]
        
        if not relevant_drugs_df.empty:
            print(f"    -> Found {len(relevant_drugs_df)} drug entries for these diseases.")
            
            # --- NEW: Save detailed drug data ---
            # Merge with collaborator names for context
            df_drug_details = df_matched[['disease_id', 'collaborator_disease_name', 'match_type']].merge(
                relevant_drugs_df, 
                on='disease_id', 
                how='right' # Use right merge to keep only rows with drugs
            )
            # Save as Parquet
            os.makedirs(os.path.dirname(OUTPUT_DRUG_DETAILS_FILE), exist_ok=True)
            df_drug_details.to_parquet(OUTPUT_DRUG_DETAILS_FILE, index=False)
            print(f"\n[Success] Detailed drug data saved to: {OUTPUT_DRUG_DETAILS_FILE}")
            # --- END NEW ---

            # --- Perform aggregations ---
            
            # 1. Total unique drugs per disease
            drugs_per_disease = relevant_drugs_df.groupby('disease_id')['drug_id'].nunique()
            drugs_per_disease = drugs_per_disease.to_frame('total_unique_drugs')

            # 2. Pivot on drug status
            # Fillna to handle cases where a disease doesn't have a drug in a certain status
            status_pivot = pd.crosstab(
                relevant_drugs_df['disease_id'],
                relevant_drugs_df['drug_status']
            ).add_prefix('status_')

            # 3. Pivot on drug phase
            # Ensure phase is a clean category
            relevant_drugs_df['drug_phase'] = relevant_drugs_df['drug_phase'].fillna('Unknown')
            phase_pivot = pd.crosstab(
                relevant_drugs_df['disease_id'],
                relevant_drugs_df['drug_phase']
            ).add_prefix('phase_')

            # --- Merge analyses back to the main dataframe ---
            final_analysis_df = final_analysis_df.merge(
                drugs_per_disease, on='disease_id', how='left'
            )
            final_analysis_df = final_analysis_df.merge(
                status_pivot, on='disease_id', how='left'
            )
            final_analysis_df = final_analysis_df.merge(
                phase_pivot, on='disease_id', how='left'
            )
            
            # Fill NaNs created by merges for diseases that had 0 drugs
            pivot_cols = list(status_pivot.columns) + list(phase_pivot.columns)
            final_analysis_df[pivot_cols] = final_analysis_df[pivot_cols].fillna(0).astype(int)
            final_analysis_df['total_unique_drugs'] = final_analysis_df['total_unique_drugs'].fillna(0).astype(int)

        else:
            print("    -> No drug entries found for any matched diseases.")
            final_analysis_df['total_unique_drugs'] = 0
    else:
        print("[Info] No diseases were matched. Skipping drug analysis.")
        final_analysis_df['total_unique_drugs'] = 0

    # --- Save results ---
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(OUTPUT_ANALYSIS_SUMMARY_FILE), exist_ok=True)
    
    # UPDATED: Save summary as CSV
    final_analysis_df.to_csv(OUTPUT_ANALYSIS_SUMMARY_FILE, index=False)
    print(f"\n[Success] Analysis summary saved to: {OUTPUT_ANALYSIS_SUMMARY_FILE}")
    
    # --- Generate report ---
    unmatched_names = final_analysis_df[
        final_analysis_df['disease_id'].isna()
    ]['collaborator_disease_name'].tolist()
    
    generate_analysis_report(final_analysis_df, unmatched_names, OUTPUT_REPORT_FILE)
    
    print("\nAll analysis complete.")


if __name__ == "__main__":
    main()
