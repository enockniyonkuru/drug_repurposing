"""
Drug Repurposing Recovery Analysis

This script identifies which known disease-drug pairs from Open Targets
were recovered by the CMAP and Tahoe drug repurposing pipelines.

Input files:
- analysis_drug_lists_creed_manual_standardised_results_OG_exp_8_q0.05.csv (DR pipeline results)
- open_target_unique_disease_drug_pairs.csv (known drug-disease pairs)
- open_target_unique_drugs.csv (drug info)
- creeds_diseases_with_known_drugs.csv (disease therapeutic areas)

Output files:
- open_target_cmap_recovered.csv
- open_target_tahoe_recovered.csv
- recovery_analysis_script.py (this script)
"""

import pandas as pd
import ast
import re
from collections import defaultdict

# =============================================================================
# LOAD DATA
# =============================================================================

print("Loading data files...")

# DR pipeline results
dr_results = pd.read_csv('analysis_drug_lists_creed_manual_standardised_results_OG_exp_8_q0.05.csv')

# Known drug-disease pairs from Open Targets
known_pairs = pd.read_csv('../open_target_unique_disease_drug_pairs.csv')

# Drug info for matching
drugs_info = pd.read_csv('../about_drugs/open_target_unique_drugs.csv')

# Disease therapeutic areas
diseases_info = pd.read_csv('../about_diseases/creeds_diseases_with_known_drugs.csv')

print(f"  DR results: {len(dr_results)} diseases")
print(f"  Known pairs: {len(known_pairs)} disease-drug pairs")
print(f"  Drugs info: {len(drugs_info)} drugs")
print(f"  Diseases info: {len(diseases_info)} diseases")

# =============================================================================
# BUILD DRUG NAME LOOKUP
# =============================================================================

print("\nBuilding drug name lookup...")

# Create mapping from drug names/synonyms to drug info
drug_name_to_id = {}
drug_id_to_info = {}

for _, row in drugs_info.iterrows():
    drug_id = row['drug_id']
    drug_name = str(row['drug_common_name']).upper().strip()
    
    # Store drug info
    drug_id_to_info[drug_id] = {
        'drug_id': drug_id,
        'drug_common_name': row['drug_common_name'],
        'drug_target_class': row['drug_target_class'],
        'drug_synonyms': row['drug_synonyms'],
        'drug_type': row['drug_type'],
        'drug_mechanism_of_action': row['drug_mechanism_of_action']
    }
    
    # Map common name
    drug_name_to_id[drug_name] = drug_id
    
    # Map synonyms
    if pd.notna(row['drug_synonyms']):
        for syn in str(row['drug_synonyms']).split('|'):
            syn_clean = syn.upper().strip()
            if syn_clean:
                drug_name_to_id[syn_clean] = drug_id

# Also add from known_pairs (may have additional synonyms)
for _, row in known_pairs.iterrows():
    drug_id = row['drug_id']
    drug_name = str(row['drug_common_name']).upper().strip()
    
    if drug_id not in drug_id_to_info:
        drug_id_to_info[drug_id] = {
            'drug_id': drug_id,
            'drug_common_name': row['drug_common_name'],
            'drug_target_class': row['drug_target_class'],
            'drug_synonyms': row['drug_synonyms'],
            'drug_type': row['drug_type'],
            'drug_mechanism_of_action': row['drug_mechanism_of_action']
        }
    
    drug_name_to_id[drug_name] = drug_id
    
    if pd.notna(row['drug_synonyms']):
        for syn in str(row['drug_synonyms']).split('|'):
            syn_clean = syn.upper().strip()
            if syn_clean:
                drug_name_to_id[syn_clean] = drug_id

print(f"  Drug names/synonyms indexed: {len(drug_name_to_id)}")

# =============================================================================
# BUILD KNOWN PAIRS LOOKUP
# =============================================================================

print("\nBuilding known pairs lookup...")

# Create lookup: disease_id -> set of drug_ids
known_pairs_by_disease = defaultdict(set)
known_pairs_by_disease_name = defaultdict(set)

for _, row in known_pairs.iterrows():
    disease_id = row['disease_id']
    drug_id = row['drug_id']
    disease_label = str(row['drug_disease_label']).upper().strip()
    
    known_pairs_by_disease[disease_id].add(drug_id)
    known_pairs_by_disease_name[disease_label].add(drug_id)

print(f"  Diseases with known drugs: {len(known_pairs_by_disease)}")

# =============================================================================
# BUILD DISEASE THERAPEUTIC AREAS LOOKUP
# =============================================================================

print("\nBuilding disease therapeutic areas lookup...")

disease_therapeutic_areas = {}
for _, row in diseases_info.iterrows():
    disease_id = row['disease_id']
    disease_therapeutic_areas[disease_id] = row['therapeutic_areas'] if pd.notna(row['therapeutic_areas']) else ''

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def clean_drug_name(name):
    """Clean and normalize drug name for matching"""
    if not name:
        return ''
    # Remove common suffixes/salts
    name = str(name).upper().strip()
    # Remove common salt forms for matching
    name = re.sub(r'\s*(HYDROCHLORIDE|HCL|SODIUM|SULFATE|MESYLATE|MALEATE|ACETATE|HYDRATE|DIHYDRATE|MONOHYDRATE|TRIHYDRATE|TOSYLATE|PHOSPHATE|CITRATE|BROMIDE|CHLORIDE).*$', '', name)
    name = re.sub(r'\s+', ' ', name).strip()
    return name

def parse_drug_list(drug_list_str):
    """Parse drug list from string representation"""
    if pd.isna(drug_list_str) or drug_list_str == '[]':
        return []
    try:
        return ast.literal_eval(drug_list_str)
    except:
        return []

def find_drug_id(drug_name):
    """Find drug ID from name, trying various matching strategies"""
    if not drug_name:
        return None
    
    name_upper = str(drug_name).upper().strip()
    
    # Direct match
    if name_upper in drug_name_to_id:
        return drug_name_to_id[name_upper]
    
    # Try cleaned name
    cleaned = clean_drug_name(name_upper)
    if cleaned in drug_name_to_id:
        return drug_name_to_id[cleaned]
    
    # Try partial match (drug name contains or is contained in known name)
    for known_name, drug_id in drug_name_to_id.items():
        if cleaned and (cleaned in known_name or known_name in cleaned):
            if len(cleaned) >= 5 and len(known_name) >= 5:  # Avoid short false matches
                return drug_id
    
    return None

def check_if_known(disease_id, disease_name, drug_id):
    """Check if a disease-drug pair is known"""
    # Check by disease ID
    if disease_id in known_pairs_by_disease:
        if drug_id in known_pairs_by_disease[disease_id]:
            return True
    
    # Check by disease name
    disease_name_upper = str(disease_name).upper().strip().replace('_', ' ')
    for known_disease_name, known_drugs in known_pairs_by_disease_name.items():
        if disease_name_upper in known_disease_name or known_disease_name in disease_name_upper:
            if drug_id in known_drugs:
                return True
    
    return False

# =============================================================================
# FIND RECOVERED PAIRS
# =============================================================================

print("\nFinding recovered pairs...")

cmap_recovered = []
tahoe_recovered = []

for _, row in dr_results.iterrows():
    disease_name = row['disease_name']
    disease_id = row['disease_id']
    
    # Get therapeutic areas for this disease
    therapeutic_areas = disease_therapeutic_areas.get(disease_id, '')
    
    # Parse hit lists
    tahoe_hits = parse_drug_list(row['tahoe_hits_list'])
    cmap_hits = parse_drug_list(row['cmap_hits_list'])
    
    # Check CMAP hits
    for drug_name in cmap_hits:
        drug_id = find_drug_id(drug_name)
        if drug_id and check_if_known(disease_id, disease_name, drug_id):
            drug_info = drug_id_to_info.get(drug_id, {})
            cmap_recovered.append({
                'disease_id': disease_id,
                'disease_name': disease_name,
                'drug_id': drug_id,
                'drug_common_name': drug_info.get('drug_common_name', ''),
                'drug_target_class': drug_info.get('drug_target_class', ''),
                'drug_synonyms': drug_info.get('drug_synonyms', ''),
                'drug_type': drug_info.get('drug_type', ''),
                'drug_mechanism_of_action': drug_info.get('drug_mechanism_of_action', ''),
                'disease_therapeutic_areas': therapeutic_areas,
                'hit_drug_name': drug_name  # Original name from hit list
            })
    
    # Check Tahoe hits
    for drug_name in tahoe_hits:
        drug_id = find_drug_id(drug_name)
        if drug_id and check_if_known(disease_id, disease_name, drug_id):
            drug_info = drug_id_to_info.get(drug_id, {})
            tahoe_recovered.append({
                'disease_id': disease_id,
                'disease_name': disease_name,
                'drug_id': drug_id,
                'drug_common_name': drug_info.get('drug_common_name', ''),
                'drug_target_class': drug_info.get('drug_target_class', ''),
                'drug_synonyms': drug_info.get('drug_synonyms', ''),
                'drug_type': drug_info.get('drug_type', ''),
                'drug_mechanism_of_action': drug_info.get('drug_mechanism_of_action', ''),
                'disease_therapeutic_areas': therapeutic_areas,
                'hit_drug_name': drug_name  # Original name from hit list
            })

# =============================================================================
# CREATE DATAFRAMES AND REMOVE DUPLICATES
# =============================================================================

print("\nCreating output files...")

# Create DataFrames
cmap_df = pd.DataFrame(cmap_recovered)
tahoe_df = pd.DataFrame(tahoe_recovered)

# Remove duplicates (same disease-drug pair)
if len(cmap_df) > 0:
    cmap_df = cmap_df.drop_duplicates(subset=['disease_id', 'drug_id'])
if len(tahoe_df) > 0:
    tahoe_df = tahoe_df.drop_duplicates(subset=['disease_id', 'drug_id'])

# Reorder columns
columns_order = [
    'disease_id', 'disease_name', 'drug_id', 'drug_common_name',
    'drug_target_class', 'drug_synonyms', 'drug_type', 
    'drug_mechanism_of_action', 'disease_therapeutic_areas'
]

if len(cmap_df) > 0:
    cmap_df = cmap_df[columns_order]
if len(tahoe_df) > 0:
    tahoe_df = tahoe_df[columns_order]

# Save to CSV
cmap_df.to_csv('open_target_cmap_recovered.csv', index=False)
tahoe_df.to_csv('open_target_tahoe_recovered.csv', index=False)

# =============================================================================
# PRINT SUMMARY
# =============================================================================

print("\n" + "="*60)
print("RECOVERY ANALYSIS SUMMARY")
print("="*60)

print(f"\nCMAP Recovered Pairs:")
print(f"  Total recovered: {len(cmap_df)}")
if len(cmap_df) > 0:
    print(f"  Unique diseases: {cmap_df['disease_id'].nunique()}")
    print(f"  Unique drugs: {cmap_df['drug_id'].nunique()}")

print(f"\nTahoe Recovered Pairs:")
print(f"  Total recovered: {len(tahoe_df)}")
if len(tahoe_df) > 0:
    print(f"  Unique diseases: {tahoe_df['disease_id'].nunique()}")
    print(f"  Unique drugs: {tahoe_df['drug_id'].nunique()}")

# Show sample of recovered pairs
if len(cmap_df) > 0:
    print("\n--- Sample CMAP Recovered Pairs ---")
    print(cmap_df[['disease_name', 'drug_common_name', 'drug_target_class']].head(10).to_string())

if len(tahoe_df) > 0:
    print("\n--- Sample Tahoe Recovered Pairs ---")
    print(tahoe_df[['disease_name', 'drug_common_name', 'drug_target_class']].head(10).to_string())

# Overlap analysis
if len(cmap_df) > 0 and len(tahoe_df) > 0:
    cmap_pairs = set(zip(cmap_df['disease_id'], cmap_df['drug_id']))
    tahoe_pairs = set(zip(tahoe_df['disease_id'], tahoe_df['drug_id']))
    common_pairs = cmap_pairs & tahoe_pairs
    
    print(f"\n--- Overlap ---")
    print(f"  CMAP only: {len(cmap_pairs - tahoe_pairs)}")
    print(f"  Tahoe only: {len(tahoe_pairs - cmap_pairs)}")
    print(f"  Both: {len(common_pairs)}")

print("\n" + "="*60)
print("Files saved:")
print("  - open_target_cmap_recovered.csv")
print("  - open_target_tahoe_recovered.csv")
print("="*60)
