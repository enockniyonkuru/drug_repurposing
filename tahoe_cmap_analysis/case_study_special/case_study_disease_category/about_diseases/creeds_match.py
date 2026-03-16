#!/usr/bin/env python3
"""
Match CREEDS diseases to Open Targets disease database
"""
import pandas as pd
import numpy as np

# Load files
creeds = pd.read_csv('../../data/disease_signatures/creeds_disease_gene_counts_across_stages.csv')
disease_df = pd.read_parquet('../../data/known_drugs/disease.parquet')

# Get unique CREEDS diseases
creeds_diseases = creeds['disease'].unique()

def clean_name(name):
    """Clean disease name for matching"""
    cleaned = name.replace('_', ' ').lower().strip()
    # Remove common variations
    cleaned = cleaned.replace("'s", "").replace("'", "")
    return cleaned

def normalize_for_match(name):
    """Further normalize for fuzzy matching"""
    return clean_name(name).replace(" disease", "").replace(" syndrome", "").strip()

# Create lookup dictionaries
# 1. By name (multiple normalizations)
name_lookup = {}
name_lookup_normalized = {}
for idx, row in disease_df.iterrows():
    name_lower = row['name'].lower().strip()
    name_lookup[name_lower] = row
    # Also without 's
    name_no_apos = name_lower.replace("'s", "").replace("'", "")
    name_lookup[name_no_apos] = row
    # Normalized version
    name_lookup_normalized[normalize_for_match(row['name'])] = row

# 2. By synonyms
synonym_lookup = {}
for idx, row in disease_df.iterrows():
    synonyms = row['synonyms']
    if isinstance(synonyms, dict):
        for syn_type in ['hasExactSynonym', 'hasRelatedSynonym', 'hasNarrowSynonym', 'hasBroadSynonym']:
            if syn_type in synonyms and synonyms[syn_type] is not None:
                try:
                    for syn in synonyms[syn_type]:
                        syn_lower = syn.lower().strip()
                        synonym_lookup[syn_lower] = row
                        # Also without 's
                        syn_no_apos = syn_lower.replace("'s", "").replace("'", "")
                        synonym_lookup[syn_no_apos] = row
                except:
                    pass

def get_synonyms_string(synonyms_dict):
    """Convert synonyms dict to pipe-separated string"""
    if not isinstance(synonyms_dict, dict):
        return ""
    all_syns = []
    for syn_type in ['hasExactSynonym', 'hasRelatedSynonym', 'hasNarrowSynonym', 'hasBroadSynonym']:
        if syn_type in synonyms_dict and synonyms_dict[syn_type] is not None:
            try:
                all_syns.extend(list(synonyms_dict[syn_type]))
            except:
                pass
    return '|'.join(all_syns) if all_syns else ""

def get_ontology_string(ontology):
    """Convert ontology to string"""
    if isinstance(ontology, dict):
        return str(ontology)
    return str(ontology) if ontology else ""

# Match each CREEDS disease
results = []
for disease in creeds_diseases:
    cleaned = clean_name(disease)
    normalized = normalize_for_match(disease)
    
    match_type = "no_match"
    matched_row = None
    
    # Try exact name match first
    if cleaned in name_lookup:
        matched_row = name_lookup[cleaned]
        match_type = "name_match"
    # Try normalized name match
    elif normalized in name_lookup_normalized:
        matched_row = name_lookup_normalized[normalized]
        match_type = "name_match"
    # Try synonym match
    elif cleaned in synonym_lookup:
        matched_row = synonym_lookup[cleaned]
        match_type = "synonym_match"
    elif normalized in synonym_lookup:
        matched_row = synonym_lookup[normalized]
        match_type = "synonym_match"
    
    if matched_row is not None:
        results.append({
            'creeds_disease': disease,
            'disease_id': matched_row['id'],
            'disease_name': matched_row['name'],
            'disease_synonyms': get_synonyms_string(matched_row['synonyms']),
            'disease_ontology': get_ontology_string(matched_row['ontology']),
            'match_type': match_type
        })
    else:
        results.append({
            'creeds_disease': disease,
            'disease_id': None,
            'disease_name': None,
            'disease_synonyms': None,
            'disease_ontology': None,
            'match_type': match_type
        })

# Create DataFrame and save
result_df = pd.DataFrame(results)
result_df.to_csv('creeds_diseases_info.csv', index=False)

print(f'Total CREEDS diseases: {len(creeds_diseases)}')
print(f'\nMatch type distribution:')
print(result_df['match_type'].value_counts())
print(f'\nSample matches:')
print(result_df[result_df['match_type'] != 'no_match'][['creeds_disease', 'disease_name', 'match_type']].head(10))
print(f'\nSample non-matches:')
print(result_df[result_df['match_type'] == 'no_match']['creeds_disease'].head(10).tolist())
print(f'\nFile saved to: creeds_diseases_info.csv')
