"""
Drug Repurposing Pipeline - ALL Discoveries Analysis

This script analyzes ALL drugs discovered by the CMAP and Tahoe pipelines
(not just the recovered/validated ones), and prepares data for visualization.

Key Features:
- Extracts ALL drug predictions from pipeline results
- Limits to top 100 drugs per disease if >100 discovered
- Matches drugs to Open Targets data for drug target class information
- Creates output files for visualization

Input files:
- analysis_drug_lists_creed_manual_standardised_results_OG_exp_8_q0.05.csv (DR pipeline results)
- open_target_unique_drugs.csv (drug info for target class)
- creeds_diseases_with_known_drugs.csv (disease therapeutic areas)

Output files:
- all_discoveries_cmap.csv
- all_discoveries_tahoe.csv
"""

import pandas as pd
import ast
import re
from collections import defaultdict
import os

# =============================================================================
# CONFIGURATION
# =============================================================================

MAX_DRUGS_PER_DISEASE = 100  # Limit to top 100 drugs per disease

# =============================================================================
# LOAD DATA
# =============================================================================

print("=" * 70)
print("ALL DISCOVERIES ANALYSIS - Drug Repurposing Pipeline")
print("=" * 70)

print("\nLoading data files...")

# DR pipeline results
dr_results = pd.read_csv('analysis_drug_lists_creed_manual_standardised_results_OG_exp_8_q0.05.csv')

# Drug info for matching (drug target class)
drugs_info = pd.read_csv('../about_drugs/open_target_unique_drugs.csv')

# Disease therapeutic areas
diseases_info = pd.read_csv('../about_diseases/creeds_diseases_with_known_drugs.csv')

print(f"  DR results: {len(dr_results)} diseases analyzed")
print(f"  Drugs info: {len(drugs_info)} drugs in Open Targets")
print(f"  Diseases info: {len(diseases_info)} diseases with therapeutic areas")

# =============================================================================
# BUILD DRUG NAME LOOKUP
# =============================================================================

print("\nBuilding drug name to info lookup...")

drug_name_to_info = {}

def clean_name(name):
    """Normalize drug name for matching"""
    if not name or pd.isna(name):
        return ''
    return str(name).upper().strip()

# Index by common name
for _, row in drugs_info.iterrows():
    drug_id = row['drug_id']
    drug_name = clean_name(row['drug_common_name'])
    
    info = {
        'drug_id': drug_id,
        'drug_common_name': row['drug_common_name'],
        'drug_target_class': row['drug_target_class'] if pd.notna(row['drug_target_class']) else 'Unknown',
        'drug_synonyms': row['drug_synonyms'] if pd.notna(row['drug_synonyms']) else '',
        'drug_type': row['drug_type'] if pd.notna(row['drug_type']) else 'Unknown',
        'drug_mechanism_of_action': row['drug_mechanism_of_action'] if pd.notna(row['drug_mechanism_of_action']) else ''
    }
    
    if drug_name:
        drug_name_to_info[drug_name] = info
    
    # Also index by synonyms
    if pd.notna(row['drug_synonyms']):
        for syn in str(row['drug_synonyms']).split('|'):
            syn_clean = clean_name(syn)
            if syn_clean and syn_clean not in drug_name_to_info:
                drug_name_to_info[syn_clean] = info

print(f"  Drug names/synonyms indexed: {len(drug_name_to_info)}")

# =============================================================================
# BUILD DISEASE THERAPEUTIC AREAS LOOKUP
# =============================================================================

print("\nBuilding disease therapeutic areas lookup...")

disease_to_therapeutic_areas = {}
disease_id_to_name = {}

for _, row in diseases_info.iterrows():
    disease_id = row['disease_id']
    disease_name = row['creeds_disease']
    disease_to_therapeutic_areas[disease_id] = row['therapeutic_areas'] if pd.notna(row['therapeutic_areas']) else 'Unknown'
    disease_id_to_name[disease_id] = disease_name

print(f"  Diseases with therapeutic areas: {len(disease_to_therapeutic_areas)}")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def parse_drug_list(drug_list_str):
    """Parse drug list from string representation"""
    if pd.isna(drug_list_str) or drug_list_str == '[]':
        return []
    try:
        return ast.literal_eval(drug_list_str)
    except:
        return []

def find_drug_info(drug_name):
    """Find drug info from Open Targets by name"""
    if not drug_name:
        return None
    
    name_upper = clean_name(drug_name)
    
    # Direct match
    if name_upper in drug_name_to_info:
        return drug_name_to_info[name_upper]
    
    # Try without common salt forms
    name_base = re.sub(r'\s*(HYDROCHLORIDE|HCL|SODIUM|SULFATE|MESYLATE|MALEATE|ACETATE|HYDRATE|DIHYDRATE|MONOHYDRATE|TRIHYDRATE|TOSYLATE|PHOSPHATE|CITRATE|BROMIDE|CHLORIDE|SALT|SOLVATE|DMSO_TF).*$', '', name_upper)
    name_base = re.sub(r'\s+', ' ', name_base).strip()
    
    if name_base in drug_name_to_info:
        return drug_name_to_info[name_base]
    
    # Try partial matching for longer names
    if len(name_base) >= 6:
        for known_name, info in drug_name_to_info.items():
            if len(known_name) >= 6:
                # Check if one contains the other
                if name_base in known_name or known_name in name_base:
                    return info
    
    return None

# =============================================================================
# EXTRACT ALL DISCOVERIES
# =============================================================================

print("\n" + "=" * 70)
print("EXTRACTING ALL DRUG DISCOVERIES")
print("=" * 70)

cmap_discoveries = []
tahoe_discoveries = []

total_cmap_drugs = 0
total_tahoe_drugs = 0
cmap_limited_diseases = 0
tahoe_limited_diseases = 0
cmap_matched = 0
tahoe_matched = 0

print(f"\nProcessing {len(dr_results)} diseases...")
print(f"(Limiting to top {MAX_DRUGS_PER_DISEASE} drugs per disease)")

for idx, row in dr_results.iterrows():
    disease_id = row['disease_id']
    disease_name = row['disease_name']
    
    # Get therapeutic areas
    therapeutic_areas = disease_to_therapeutic_areas.get(disease_id, 'Unknown')
    if not therapeutic_areas or therapeutic_areas == '' or pd.isna(therapeutic_areas):
        therapeutic_areas = 'Unknown'
    
    # Parse Tahoe drug list
    tahoe_drugs = parse_drug_list(row['tahoe_hits_list'])
    total_tahoe_drugs += len(tahoe_drugs)
    
    # Limit to top 100 (they are already ranked)
    if len(tahoe_drugs) > MAX_DRUGS_PER_DISEASE:
        tahoe_limited_diseases += 1
        tahoe_drugs = tahoe_drugs[:MAX_DRUGS_PER_DISEASE]
    
    # Process Tahoe drugs
    for rank, drug_name in enumerate(tahoe_drugs, 1):
        drug_info = find_drug_info(drug_name)
        
        if drug_info:
            tahoe_matched += 1
            tahoe_discoveries.append({
                'disease_id': disease_id,
                'disease_name': disease_name,
                'disease_therapeutic_areas': therapeutic_areas,
                'drug_rank': rank,
                'drug_name_original': drug_name,
                'drug_id': drug_info['drug_id'],
                'drug_common_name': drug_info['drug_common_name'],
                'drug_target_class': drug_info['drug_target_class'],
                'drug_type': drug_info['drug_type'],
                'drug_mechanism_of_action': drug_info['drug_mechanism_of_action'],
                'drug_synonyms': drug_info['drug_synonyms']
            })
        else:
            tahoe_discoveries.append({
                'disease_id': disease_id,
                'disease_name': disease_name,
                'disease_therapeutic_areas': therapeutic_areas,
                'drug_rank': rank,
                'drug_name_original': drug_name,
                'drug_id': 'UNMATCHED',
                'drug_common_name': drug_name,
                'drug_target_class': 'Unknown',
                'drug_type': 'Unknown',
                'drug_mechanism_of_action': '',
                'drug_synonyms': ''
            })
    
    # Parse CMAP drug list
    cmap_drugs = parse_drug_list(row['cmap_hits_list'])
    total_cmap_drugs += len(cmap_drugs)
    
    # Limit to top 100 (they are already ranked)
    if len(cmap_drugs) > MAX_DRUGS_PER_DISEASE:
        cmap_limited_diseases += 1
        cmap_drugs = cmap_drugs[:MAX_DRUGS_PER_DISEASE]
    
    # Process CMAP drugs
    for rank, drug_name in enumerate(cmap_drugs, 1):
        drug_info = find_drug_info(drug_name)
        
        if drug_info:
            cmap_matched += 1
            cmap_discoveries.append({
                'disease_id': disease_id,
                'disease_name': disease_name,
                'disease_therapeutic_areas': therapeutic_areas,
                'drug_rank': rank,
                'drug_name_original': drug_name,
                'drug_id': drug_info['drug_id'],
                'drug_common_name': drug_info['drug_common_name'],
                'drug_target_class': drug_info['drug_target_class'],
                'drug_type': drug_info['drug_type'],
                'drug_mechanism_of_action': drug_info['drug_mechanism_of_action'],
                'drug_synonyms': drug_info['drug_synonyms']
            })
        else:
            cmap_discoveries.append({
                'disease_id': disease_id,
                'disease_name': disease_name,
                'disease_therapeutic_areas': therapeutic_areas,
                'drug_rank': rank,
                'drug_name_original': drug_name,
                'drug_id': 'UNMATCHED',
                'drug_common_name': drug_name,
                'drug_target_class': 'Unknown',
                'drug_type': 'Unknown',
                'drug_mechanism_of_action': '',
                'drug_synonyms': ''
            })

# =============================================================================
# CREATE DATAFRAMES AND SAVE
# =============================================================================

print("\n" + "=" * 70)
print("RESULTS SUMMARY")
print("=" * 70)

cmap_df = pd.DataFrame(cmap_discoveries)
tahoe_df = pd.DataFrame(tahoe_discoveries)

# Calculate unique counts
cmap_unique_diseases = cmap_df['disease_id'].nunique()
cmap_unique_drugs = cmap_df[cmap_df['drug_id'] != 'UNMATCHED']['drug_id'].nunique()
tahoe_unique_diseases = tahoe_df['disease_id'].nunique()
tahoe_unique_drugs = tahoe_df[tahoe_df['drug_id'] != 'UNMATCHED']['drug_id'].nunique()

print(f"\nTAHOE Pipeline:")
print(f"  Total drug predictions (before limit): {total_tahoe_drugs}")
print(f"  Diseases with >100 drugs (limited): {tahoe_limited_diseases}")
print(f"  Disease-drug pairs (after limit): {len(tahoe_df)}")
print(f"  Unique diseases: {tahoe_unique_diseases}")
print(f"  Unique matched drugs: {tahoe_unique_drugs}")
print(f"  Drugs matched to Open Targets: {tahoe_matched} ({tahoe_matched/len(tahoe_df)*100:.1f}%)")

print(f"\nCMAP Pipeline:")
print(f"  Total drug predictions (before limit): {total_cmap_drugs}")
print(f"  Diseases with >100 drugs (limited): {cmap_limited_diseases}")
print(f"  Disease-drug pairs (after limit): {len(cmap_df)}")
print(f"  Unique diseases: {cmap_unique_diseases}")
print(f"  Unique matched drugs: {cmap_unique_drugs}")
print(f"  Drugs matched to Open Targets: {cmap_matched} ({cmap_matched/len(cmap_df)*100:.1f}%)")

# Find overlap
print("\n" + "-" * 50)
print("OVERLAP ANALYSIS:")

# Get unique disease-drug pairs
cmap_pairs = set(zip(cmap_df['disease_id'], cmap_df['drug_common_name'].str.upper()))
tahoe_pairs = set(zip(tahoe_df['disease_id'], tahoe_df['drug_common_name'].str.upper()))
overlap_pairs = cmap_pairs & tahoe_pairs

print(f"  CMAP unique pairs: {len(cmap_pairs)}")
print(f"  Tahoe unique pairs: {len(tahoe_pairs)}")
print(f"  Overlapping pairs: {len(overlap_pairs)}")

# Unique to each
cmap_only = len(cmap_pairs - tahoe_pairs)
tahoe_only = len(tahoe_pairs - cmap_pairs)
print(f"  CMAP-only pairs: {cmap_only}")
print(f"  Tahoe-only pairs: {tahoe_only}")

# =============================================================================
# FILTER TO MATCHED DRUGS ONLY
# =============================================================================

print("\n" + "=" * 70)
print("FILTERING TO MATCHED DRUGS ONLY")
print("=" * 70)

# Count unmatched before filtering
cmap_unmatched_count = (cmap_df['drug_id'] == 'UNMATCHED').sum()
tahoe_unmatched_count = (tahoe_df['drug_id'] == 'UNMATCHED').sum()
cmap_unmatched_drugs = cmap_df[cmap_df['drug_id'] == 'UNMATCHED']['drug_name_original'].unique()
tahoe_unmatched_drugs = tahoe_df[tahoe_df['drug_id'] == 'UNMATCHED']['drug_name_original'].unique()

print(f"\nCMAP unmatched: {cmap_unmatched_count} pairs ({len(cmap_unmatched_drugs)} unique drugs)")
print(f"Tahoe unmatched: {tahoe_unmatched_count} pairs ({len(tahoe_unmatched_drugs)} unique drugs)")

# Save unmatched drug names for documentation
unmatched_cmap_list = sorted(list(cmap_unmatched_drugs))
unmatched_tahoe_list = sorted(list(tahoe_unmatched_drugs))

# Filter to matched only
cmap_df_matched = cmap_df[cmap_df['drug_id'] != 'UNMATCHED'].copy()
tahoe_df_matched = tahoe_df[tahoe_df['drug_id'] != 'UNMATCHED'].copy()

print(f"\nAfter filtering:")
print(f"  CMAP: {len(cmap_df)} -> {len(cmap_df_matched)} pairs ({len(cmap_df_matched)/len(cmap_df)*100:.1f}% retained)")
print(f"  Tahoe: {len(tahoe_df)} -> {len(tahoe_df_matched)} pairs ({len(tahoe_df_matched)/len(tahoe_df)*100:.1f}% retained)")

# Also filter out Unknown therapeutic areas for cleaner visualization
cmap_df_clean = cmap_df_matched[cmap_df_matched['disease_therapeutic_areas'] != 'Unknown'].copy()
tahoe_df_clean = tahoe_df_matched[tahoe_df_matched['disease_therapeutic_areas'] != 'Unknown'].copy()

print(f"\nAfter removing Unknown therapeutic areas:")
print(f"  CMAP: {len(cmap_df_matched)} -> {len(cmap_df_clean)} pairs")
print(f"  Tahoe: {len(tahoe_df_matched)} -> {len(tahoe_df_clean)} pairs")

# Use cleaned data for final output
cmap_df = cmap_df_clean
tahoe_df = tahoe_df_clean

# =============================================================================
# SAVE OUTPUT FILES
# =============================================================================

print("\n" + "=" * 70)
print("SAVING OUTPUT FILES")
print("=" * 70)

# Create output directory
os.makedirs('figures_everything', exist_ok=True)

# Save filtered data to CSV
cmap_df.to_csv('all_discoveries_cmap.csv', index=False)
tahoe_df.to_csv('all_discoveries_tahoe.csv', index=False)

# Save unmatched drugs list for documentation
with open('unmatched_drugs_cmap.txt', 'w') as f:
    f.write(f"# CMAP Unmatched Drugs ({len(unmatched_cmap_list)} unique names)\n")
    f.write(f"# These drugs from the pipeline could not be matched to Open Targets\n\n")
    for drug in unmatched_cmap_list:
        f.write(f"{drug}\n")

with open('unmatched_drugs_tahoe.txt', 'w') as f:
    f.write(f"# Tahoe Unmatched Drugs ({len(unmatched_tahoe_list)} unique names)\n")
    f.write(f"# These drugs from the pipeline could not be matched to Open Targets\n\n")
    for drug in unmatched_tahoe_list:
        f.write(f"{drug}\n")

print(f"\n  Saved: all_discoveries_cmap.csv ({len(cmap_df)} rows - matched only)")
print(f"  Saved: all_discoveries_tahoe.csv ({len(tahoe_df)} rows - matched only)")
print(f"  Saved: unmatched_drugs_cmap.txt ({len(unmatched_cmap_list)} drugs)")
print(f"  Saved: unmatched_drugs_tahoe.txt ({len(unmatched_tahoe_list)} drugs)")

# =============================================================================
# DRUG TARGET CLASS DISTRIBUTION
# =============================================================================

print("\n" + "=" * 70)
print("DRUG TARGET CLASS DISTRIBUTION")
print("=" * 70)

def get_target_class_distribution(df, name):
    """Get distribution of drug target classes"""
    
    # Filter to matched drugs only
    matched_df = df[df['drug_id'] != 'UNMATCHED']
    
    # Expand multi-valued target classes
    target_classes = []
    for _, row in matched_df.iterrows():
        if pd.notna(row['drug_target_class']):
            classes = str(row['drug_target_class']).split('|')
            for tc in classes:
                tc = tc.strip()
                if tc and tc != 'nan':
                    target_classes.append(tc)
    
    # Count
    from collections import Counter
    counts = Counter(target_classes)
    total = sum(counts.values())
    
    print(f"\n{name} - Top Drug Target Classes:")
    for target_class, count in counts.most_common(10):
        print(f"  {target_class}: {count} ({count/total*100:.1f}%)")
    
    return counts

cmap_target_dist = get_target_class_distribution(cmap_df, "CMAP")
tahoe_target_dist = get_target_class_distribution(tahoe_df, "TAHOE")

# =============================================================================
# THERAPEUTIC AREA DISTRIBUTION
# =============================================================================

print("\n" + "=" * 70)
print("THERAPEUTIC AREA DISTRIBUTION")
print("=" * 70)

def get_therapeutic_area_distribution(df, name):
    """Get distribution of disease therapeutic areas"""
    
    # Expand multi-valued therapeutic areas
    areas = []
    for _, row in df.iterrows():
        if pd.notna(row['disease_therapeutic_areas']):
            tas = str(row['disease_therapeutic_areas']).split('|')
            for ta in tas:
                ta = ta.strip()
                if ta and ta != 'nan' and ta != 'Unknown':
                    areas.append(ta)
    
    # Count
    from collections import Counter
    counts = Counter(areas)
    total = sum(counts.values())
    
    print(f"\n{name} - Top Therapeutic Areas:")
    for area, count in counts.most_common(10):
        print(f"  {area}: {count} ({count/total*100:.1f}%)")
    
    return counts

cmap_ta_dist = get_therapeutic_area_distribution(cmap_df, "CMAP")
tahoe_ta_dist = get_therapeutic_area_distribution(tahoe_df, "TAHOE")

print("\n" + "=" * 70)
print("ANALYSIS COMPLETE!")
print("=" * 70)
print("\nNext step: Run visualization_script_all_discoveries.py")
