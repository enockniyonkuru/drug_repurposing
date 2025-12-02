#!/usr/bin/env python3
"""
Analyze Pipeline Results Across Diseases

Comprehensively analyzes drug discovery pipeline outputs for multiple diseases.
Filters by q-value thresholds, compares CMAP vs Tahoe hits, and crossreferences
with known drugs. Generates detailed analysis summaries and reports.

This script is designed to be reusable. It:
1.  Accepts an input directory of pipeline results (e.g., .../sirota_lab_disease_results_genes_drugs).
2.  Scans the directory to find pairs of '..._CMAP_...' and '..._TAHOE_...' folders
    for each disease.
3.  Matches the disease name (from the folder) to an official 'disease_id' using
    the processed 'disease_info_data.parquet'.
4.  For q-value thresholds of 0.5, 0.1, and 0.05, it performs the following:
    a. Reads the hits CSV from each CMAP/TAHOE folder and filters by q-value.
    b. Extracts unique drug hits (from 'name' column).
    c. Compares TAHOE hits vs. CMAP hits (counts and common).
    d. Loads 'known_drug_info_data.parquet' to build a set of known drugs
       for the matched 'disease_id'.
    e. Compares pipeline hits (TAHOE, CMAP, common) against the known drugs list.
    f. For hits found in the known drugs list, it extracts and pivots their
       'drug_phase' and 'drug_status' into columns.
5.  Saves 3 sets of files (one per q-value threshold):
    - `analysis_summary...csv`: CSV with aggregate counts and phase/status pivots.
    - `analysis_drug_lists...csv`: CSV with lists of drug names for each category.
    - `analysis_details...json`: JSON file with a hierarchical structure of all hits.
6.  Generates a single summary report.

Example usage:
python tahoe_cmap_analysis/scripts/analysis/extract_pipeline_results_analysis.py \
    --input_dir tahoe_cmap_analysis/results/creed_manual_standardised_results_OG_exp_8 \
    --output_dir tahoe_cmap_analysis/data/creed_manual_analysis_exp_8

"""

import pandas as pd
import os
import glob
import re
import argparse
import io
import json
from collections import defaultdict

# --- 1. Configuration: Path Generation ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))  # Go up to tahoe_cmap_analysis

# --- 2. Constants ---
Q_THRESHOLDS = [0.5, 0.1, 0.05]
DISEASE_INFO_FILE = os.path.join(BASE_DIR, 'data/known_drugs/disease.parquet')
DRUG_INFO_FILE = os.path.join(BASE_DIR, 'data/known_drugs/known_drug_info_data.parquet')
CMAP_EXPERIMENTS_FILE = os.path.join(os.path.dirname(BASE_DIR), 'scripts/data/drug_signatures/cmap_drug_experiments_new.csv')
TAHOE_EXPERIMENTS_FILE = os.path.join(os.path.dirname(BASE_DIR), 'scripts/data/drug_signatures/tahoe_drug_experiments_new.csv')

# --- 3. Helper Functions ---

def clean_text(text: str) -> str:
    """
    Cleans a text string for matching.
    """
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text) # Keep words and spaces
    text = re.sub(r'\s+', ' ', text) # Condense multiple spaces
    return text.strip()

def load_available_drugs(cmap_file: str, tahoe_file: str) -> tuple:
    """
    Loads CMAP and Tahoe drug experiment files and returns sets of available drug names.
    Returns: (set_cmap_drugs, set_tahoe_drugs)
    """
    try:
        df_cmap = pd.read_csv(cmap_file)
        set_cmap_drugs = set(df_cmap['name'].apply(clean_text).unique())
        print(f"[Info] Loaded {len(set_cmap_drugs)} unique drugs from CMAP experiments.")
    except Exception as e:
        print(f"[Warning] Could not load CMAP experiments file: {e}")
        set_cmap_drugs = set()
    
    try:
        df_tahoe = pd.read_csv(tahoe_file)
        set_tahoe_drugs = set(df_tahoe['name'].apply(clean_text).unique())
        print(f"[Info] Loaded {len(set_tahoe_drugs)} unique drugs from Tahoe experiments.")
    except Exception as e:
        print(f"[Warning] Could not load Tahoe experiments file: {e}")
        set_tahoe_drugs = set()
    
    return set_cmap_drugs, set_tahoe_drugs

def load_disease_info_maps(disease_info_path: str) -> tuple:
    """Loads disease info and creates matching maps."""
    try:
        df_disease_info = pd.read_parquet(disease_info_path)
    except FileNotFoundError:
        print(f"[Error] Cannot find disease info file: {disease_info_path}")
        return None, None
    
    # Pass 1: Name-to-ID map
    df_disease_info['cleaned_name'] = df_disease_info['name'].apply(clean_text)
    name_to_id_map = df_disease_info.set_index('cleaned_name')['id'].to_dict()
    
    # Pass 2: Synonym-to-ID map
    print("[Info] Building disease synonym map...")
    synonym_to_id_map = {}
    synonym_keys = ['hasExactSynonym', 'hasRelatedSynonym', 'hasNarrowSynonym', 'hasBroadSynonym']
    
    for _, row in df_disease_info.iterrows():
        disease_id = row['id']
        synonyms_struct = row['synonyms']
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
                
    return name_to_id_map, synonym_to_id_map

def find_disease_id(disease_name: str, name_map: dict, syn_map: dict) -> tuple:
    """Matches a disease name using the 2-pass maps."""
    cleaned_name = clean_text(disease_name)
    
    # Pass 1: Check name
    disease_id = name_map.get(cleaned_name)
    if disease_id:
        return disease_id, "name"
    
    # Pass 2: Check synonyms
    disease_id = syn_map.get(cleaned_name)
    if disease_id:
        return disease_id, "synonym"
        
    return None, "no_match"

def get_pipeline_disease_folders(input_dir: str) -> dict:
    """
    Scans the input directory and groups TAHOE/CMAP folders by disease.
    Returns: {'Disease Name': {'CMAP': 'path/to/folder', 'TAHOE': ...}, ...}
    """
    folders = glob.glob(os.path.join(input_dir, "*/"))
    disease_map = defaultdict(dict)
    
    # Regex to capture (Disease Name), (CMAP or TAHOE), (Timestamp)
    # Allows for underscores in the disease name
    pattern = re.compile(r"(.+?)(?:_CMAP_|_TAHOE_)([\d\-]+)")
    
    print(f"[Info] Scanning {len(folders)} folders in {input_dir}...")
    
    for folder_path in folders:
        folder_name = os.path.basename(os.path.normpath(folder_path))
        match = pattern.search(folder_name)
        
        if match:
            # Replace underscores from filename to get space-separated name
            disease_name = match.group(1).replace("_", " ")
            source = "CMAP" if "_CMAP_" in folder_name else "TAHOE"
            disease_map[disease_name][source] = folder_path
        else:
            print(f"    [Warning] Folder name did not match pattern: {folder_name}")
            
    return disease_map

def load_hits_from_folder(folder_path: str, q_threshold: float) -> set:
    """Finds the CSV in a folder, loads it, filters, and returns a set of drug names."""
    try:
        # Find the single CSV file
        csv_files = glob.glob(os.path.join(folder_path, "*.csv"))
        if not csv_files:
            # print(f"    [Warning] No CSV file found in: {folder_path}")
            return set()
        
        df = pd.read_csv(csv_files[0])
        
        # Filter by q-value
        df_filtered = df[df['q'] < q_threshold]
        
        # Get unique, cleaned drug names
        return set(df_filtered['name'].apply(clean_text).unique())
        
    except Exception as e:
        print(f"    [Error] Could not process file in {folder_path}: {e}")
        return set()

def build_known_drug_name_map(df_known_drugs: pd.DataFrame, disease_id: str) -> dict:
    """
    For a given disease_id, builds a map of:
    {cleaned_drug_name: set((drug_id, drug_phase, drug_status), ...)}
    """
    df_disease_drugs = df_known_drugs[df_known_drugs['disease_id'] == disease_id]
    name_map = defaultdict(set)
    
    for _, row in df_disease_drugs.iterrows():
        # Store info tuple. Use 'Unknown' for NaNs
        info = (
            row['drug_id'],
            row['drug_phase'] if pd.notna(row['drug_phase']) else 'Unknown',
            row['drug_status'] if pd.notna(row['drug_status']) else 'Unknown'
        )
        
        # 1. Add common name
        if pd.notna(row['drug_common_name']):
            name_map[clean_text(row['drug_common_name'])].add(info)
            
        # 2. Add brand names (array)
        brand_names = row['drug_brand_name']
        if brand_names is not None:
            try:
                if hasattr(brand_names, '__iter__') and not isinstance(brand_names, str):
                    for name in brand_names:
                        if pd.notna(name):
                            name_map[clean_text(name)].add(info)
            except (TypeError, ValueError): 
                pass # Handle empty/malformed list
            
        # 3. Add synonyms (array)
        synonyms = row['drug_synonyms']
        if synonyms is not None:
            try:
                if hasattr(synonyms, '__iter__') and not isinstance(synonyms, str):
                    for name in synonyms:
                        if pd.notna(name):
                            name_map[clean_text(name)].add(info)
            except (TypeError, ValueError): 
                pass # Handle empty/malformed list
            
    return name_map
def generate_report(output_dir: str, input_folder_name: str, df_final: pd.DataFrame, input_dir: str):
    """Generates a summary report of the analysis."""
    report_path = os.path.join(output_dir, f"pipeline_analysis_report_{input_folder_name}.txt")
    print(f"[Info] Generating summary report: {report_path}")
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("--- Pipeline Analysis Report ---\n\n")
        f.write(f"Generated: {pd.Timestamp.now()}\n")
        f.write(f"Source Results Folder: {input_dir}\n")
        f.write(f"Output Analysis Directory: {output_dir}\n\n")
        
        f.write(f"Analyzed {len(df_final['disease_name'].unique())} unique diseases.\n")
        f.write(f"Ran analysis for {len(df_final['q_threshold'].unique())} q-value thresholds: {Q_THRESHOLDS}\n\n")

        f.write(f"--- Output File Naming Pattern (per q-value) ---\n")
        f.write(f"1. Summary CSV (Counts): analysis_summary_{input_folder_name}_q[X].csv\n")
        f.write(f"2. Drug Lists CSV:     analysis_drug_lists_{input_folder_name}_q[X].csv\n")
        f.write(f"3. Details JSON:       analysis_details_{input_folder_name}_q[X].json\n\n")
        
        f.write("--- Match Summary ---\n")
        match_counts = df_final[df_final['q_threshold'] == Q_THRESHOLDS[0]]['match_type'].value_counts()
        f.write(f"Disease Name Matches (from folders):\n")
        f.write(f"  - Matched by name:     {match_counts.get('name', 0)}\n")
        f.write(f"  - Matched by synonym:  {match_counts.get('synonym', 0)}\n")
        f.write(f"  - No match found:    {match_counts.get('no_match', 0)}\n\n")
        
        f.write("--- Data Sample (Summary, q < 0.5) ---\n")
        summary_cols = [col for col in df_final.columns if not col.endswith('_list')]
        f.write(df_final[df_final['q_threshold'] == 0.5][summary_cols].head().to_string())
        
        f.write("\n\n--- End of Report ---")

# --- 4. Main Execution ---

def main(args):
    """
    Main function to orchestrate the analysis.
    """
    print("Starting Pipeline Results Analysis...")
    
    # --- 1. Load Prerequisite Data ---
    print("[Info] Loading disease and drug reference data...")
    name_map, syn_map = load_disease_info_maps(DISEASE_INFO_FILE)
    if name_map is None:
        print("[Fatal] Could not load disease data. Exiting.")
        return
        
    try:
        df_known_drugs = pd.read_parquet(DRUG_INFO_FILE)
    except FileNotFoundError:
        print(f"[Fatal] Cannot find known drug file: {DRUG_INFO_FILE}. Exiting.")
        return
    
    # Load available drugs from CMAP and Tahoe experiments
    set_cmap_available_drugs, set_tahoe_available_drugs = load_available_drugs(
        CMAP_EXPERIMENTS_FILE, TAHOE_EXPERIMENTS_FILE
    )

    # --- 2. Scan Pipeline Folders ---
    disease_folder_map = get_pipeline_disease_folders(args.input_dir)
    if not disease_folder_map:
        print(f"[Fatal] No valid disease folders found in {args.input_dir}. Exiting.")
        return
    print(f"[Info] Found {len(disease_folder_map)} diseases to analyze.")
    
    # --- 3. Run Analysis for each Q-value ---
    all_results_data = [] # List to hold all result rows
    
    for q_value in Q_THRESHOLDS:
        print(f"\n--- Processing for Q-Value < {q_value} ---")
        
        all_disease_json_data = {} # For hierarchical JSON output
        
        for disease_name, sources in disease_folder_map.items():
            if "CMAP" not in sources or "TAHOE" not in sources:
                print(f"    [Skipping] '{disease_name}' is missing a CMAP or TAHOE folder.")
                continue
            
            # print(f"    -> Analyzing '{disease_name}'...")
            
            # --- a. Basic Info & Disease Matching ---
            row = {'disease_name': disease_name, 'q_threshold': q_value}
            disease_id, match_type = find_disease_id(disease_name, name_map, syn_map)
            row['disease_id'] = disease_id
            row['match_type'] = match_type
            
            # --- b. Load Pipeline Hits ---
            set_tahoe_hits = load_hits_from_folder(sources['TAHOE'], q_value)
            set_cmap_hits = load_hits_from_folder(sources['CMAP'], q_value)
            set_common_hits = set_tahoe_hits.intersection(set_cmap_hits)
            set_all_pipeline_hits = set_tahoe_hits.union(set_cmap_hits)
            
            row['tahoe_hits_count'] = len(set_tahoe_hits)
            row['tahoe_hits_list'] = list(set_tahoe_hits)
            row['cmap_hits_count'] = len(set_cmap_hits)
            row['cmap_hits_list'] = list(set_cmap_hits)
            row['common_hits_count'] = len(set_common_hits)
            row['common_hits_list'] = list(set_common_hits)

            # --- c. Compare vs. Known Drugs ---
            unique_found_drug_details = set() # (drug_id, phase, status)
            # For JSON output
            unique_tahoe_known_details = set()
            unique_cmap_known_details = set()
            
            # Initialize these variables
            set_tahoe_in_known = set()
            set_cmap_in_known = set()
            set_common_in_known = set()
            set_total_in_known = set()
            
            if disease_id:
                # Build the map of known drug names for this specific disease
                known_drug_name_map = build_known_drug_name_map(df_known_drugs, disease_id)
                set_known_drug_names = set(known_drug_name_map.keys())
                
                # Calculate intersections
                set_tahoe_in_known = set_tahoe_hits.intersection(set_known_drug_names)
                set_cmap_in_known = set_cmap_hits.intersection(set_known_drug_names)
                set_common_in_known = set_common_hits.intersection(set_known_drug_names)
                set_total_in_known = set_all_pipeline_hits.intersection(set_known_drug_names)
                
                row['known_drugs_in_database_count'] = len(set_known_drug_names)
                row['tahoe_in_known_count'] = len(set_tahoe_in_known)
                row['tahoe_in_known_list'] = list(set_tahoe_in_known)
                row['cmap_in_known_count'] = len(set_cmap_in_known)
                row['cmap_in_known_list'] = list(set_cmap_in_known)
                row['common_in_known_count'] = len(set_common_in_known)
                row['common_in_known_list'] = list(set_common_in_known)
                row['total_in_known_count'] = len(set_total_in_known)
                row['total_in_known_list'] = list(set_total_in_known)
                
                # Calculate how many known drugs are available in CMAP and Tahoe
                set_known_in_cmap = set_known_drug_names.intersection(set_cmap_available_drugs)
                set_known_in_tahoe = set_known_drug_names.intersection(set_tahoe_available_drugs)
                
                row['known_drugs_available_in_cmap_count'] = len(set_known_in_cmap)
                row['known_drugs_available_in_tahoe_count'] = len(set_known_in_tahoe)
                
                # --- d. Get Phase/Status for found drugs ---
                for name in set_total_in_known:
                    # Update the set with all tuples (drug_id, phase, status)
                    unique_found_drug_details.update(known_drug_name_map[name])
                
                # For JSON: get granular details
                for name in set_tahoe_in_known:
                    unique_tahoe_known_details.update(known_drug_name_map[name])
                for name in set_cmap_in_known:
                    unique_cmap_known_details.update(known_drug_name_map[name])
            
            else:
                # No disease ID, so all known counts are 0
                row['known_drugs_in_database_count'] = 0
                row['tahoe_in_known_count'] = 0
                row['tahoe_in_known_list'] = []
                row['cmap_in_known_count'] = 0
                row['cmap_in_known_list'] = []
                row['common_in_known_count'] = 0
                row['common_in_known_list'] = []
                row['total_in_known_count'] = 0
                row['total_in_known_list'] = []
                row['known_drugs_available_in_cmap_count'] = 0
                row['known_drugs_available_in_tahoe_count'] = 0

            # --- e. Pivot Phase/Status Stats (for CSV) ---
            if unique_found_drug_details:
                phases = [info[1] for info in unique_found_drug_details]
                statuses = [info[2] for info in unique_found_drug_details]
                
                phase_counts = pd.Series(phases).value_counts()
                for phase, count in phase_counts.items():
                    row[f'phase_{phase}'] = count
                    
                status_counts = pd.Series(statuses).value_counts()
                for status, count in status_counts.items():
                    row[f'status_{status}'] = count
            
            all_results_data.append(row)
            
            # --- f. Build JSON data for this disease ---
            all_disease_json_data[disease_name] = {
                'disease_id': disease_id,
                'match_type': match_type,
                'TAHOE': {
                    'pipeline_hits_count': len(set_tahoe_hits),
                    'pipeline_hits_list': list(set_tahoe_hits),
                    'known_drug_hits_count': len(set_tahoe_in_known),
                    'known_drug_hits_list': list(set_tahoe_in_known),
                    'known_drug_hits_details': [list(d) for d in unique_tahoe_known_details]
                },
                'CMAP': {
                    'pipeline_hits_count': len(set_cmap_hits),
                    'pipeline_hits_list': list(set_cmap_hits),
                    'known_drug_hits_count': len(set_cmap_in_known),
                    'known_drug_hits_list': list(set_cmap_in_known),
                    'known_drug_hits_details': [list(d) for d in unique_cmap_known_details]
                },
                'COMMON': {
                    'pipeline_hits_count': len(set_common_hits),
                    'pipeline_hits_list': list(set_common_hits),
                    'known_drug_hits_count': len(set_common_in_known),
                    'known_drug_hits_list': list(set_common_in_known)
                }
            }

        # --- End of Disease Loop ---
        
        # Save JSON file for this q-value
        os.makedirs(args.output_dir, exist_ok=True)
        input_folder_name = os.path.basename(os.path.normpath(args.input_dir))
        json_filename = f"analysis_details_{input_folder_name}_q{q_value}.json"
        json_output_path = os.path.join(args.output_dir, json_filename)
        
        try:
            with open(json_output_path, 'w', encoding='utf-8') as f:
                json.dump(all_disease_json_data, f, indent=2)
            print(f"    -> Saved JSON details to: {json_output_path}")
        except Exception as e:
            print(f"    [Error] Failed to save JSON {json_output_path}: {e}")

    # --- 4. Finalize and Save CSV Results ---
    print("\n[Info] Aggregating final CSV results...")
    
    if not all_results_data:
        print("[Error] No results were generated. Exiting.")
        return

    df_final = pd.DataFrame(all_results_data)
    df_final = df_final.fillna(0)
    
    # Define columns for different CSV files
    core_cols = ['disease_name', 'disease_id', 'match_type', 'q_threshold']
    
    count_cols = ['tahoe_hits_count', 'cmap_hits_count', 'common_hits_count',
                  'known_drugs_in_database_count', 'known_drugs_available_in_cmap_count', 
                  'known_drugs_available_in_tahoe_count', 'tahoe_in_known_count', 'cmap_in_known_count', 
                  'common_in_known_count', 'total_in_known_count']
    
    list_cols = ['tahoe_hits_list', 'cmap_hits_list', 'common_hits_list',
                 'tahoe_in_known_list', 'cmap_in_known_list',
                 'common_in_known_list', 'total_in_known_list']
    
    pivot_cols = sorted([col for col in df_final.columns if col.startswith('phase_') or col.startswith('status_')])
    
    # Save separate CSV files for each q-value threshold
    input_folder_name = os.path.basename(os.path.normpath(args.input_dir))
    
    for q_value in Q_THRESHOLDS:
        df_q = df_final[df_final['q_threshold'] == q_value]
        
        # 1. Summary CSV (counts + pivots)
        summary_cols = core_cols + count_cols + pivot_cols
        df_summary = df_q[summary_cols]
        summary_filename = f"analysis_summary_{input_folder_name}_q{q_value}.csv"
        summary_path = os.path.join(args.output_dir, summary_filename)
        df_summary.to_csv(summary_path, index=False)
        print(f"    -> Saved summary to: {summary_path}")
        
        # 2. Drug Lists CSV
        drug_list_cols = core_cols + list_cols
        df_lists = df_q[drug_list_cols]
        lists_filename = f"analysis_drug_lists_{input_folder_name}_q{q_value}.csv"
        lists_path = os.path.join(args.output_dir, lists_filename)
        df_lists.to_csv(lists_path, index=False)
        print(f"    -> Saved drug lists to: {lists_path}")
    
    # --- 5. Generate Report ---
    generate_report(args.output_dir, input_folder_name, df_final, args.input_dir)
    
    print("\n[Success] Pipeline analysis complete!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Analyze and aggregate drug discovery pipeline results."
    )
    parser.add_argument(
        "--input_dir",
        type=str,
        required=True,
        help="Path to the root results folder (e.g., .../sirota_lab_disease_results_genes_drugs)"
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        required=True,
        help="Path to save analysis outputs"
    )
    
    args = parser.parse_args()
    main(args)


"""
Example command to run the script:
python scripts/extract_pipeline_results_analysis.py --input_dir results/sirota_lab_disease_results_genes_drugs_SHARED_ONLY --output_dir data/analysis_shared_only
"""
