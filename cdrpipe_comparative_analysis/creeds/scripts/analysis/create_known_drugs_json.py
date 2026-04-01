import pandas as pd
import json
from collections import defaultdict

# Load files
csv_file = 'validation/step_4_drpipe_validation/step4_233_diseases_open_targets_comparison.csv'
pairs_file = 'validation/step_4_drpipe_validation/step4_233_diseases_disease_drug_pairs.json'
ot_file = 'validation/known_drugs/open_target_known_drugs/open_targets_data.parquet'
analysis_file = 'creeds/analysis/manual_standardized_all_diseases_analysis/analysis_details_creeds_manual_all_diseases_q0.05.json'

# Load comparison CSV
comp_df = pd.read_csv(csv_file)
print(f"Loaded comparison CSV: {len(comp_df)} diseases")

# Load disease-drug pairs
with open(pairs_file) as f:
    disease_drug_pairs = json.load(f)
print(f"Loaded disease-drug pairs: {len(disease_drug_pairs)} diseases")

# Load Open Targets data
ot_df = pd.read_parquet(ot_file)
print(f"Loaded Open Targets data: {len(ot_df)} rows")

# Load analysis results
with open(analysis_file) as f:
    analysis_data = json.load(f)
print(f"Loaded analysis data: {len(analysis_data)} diseases")

# Create disease_id to disease_name mapping from comp_df
disease_id_map = dict(zip(comp_df['disease_name'], comp_df['disease_id']))

# Build Open Targets drug lookup: disease_id -> list of drug info
ot_disease_drugs = defaultdict(list)
for _, row in ot_df.iterrows():
    drug_info = {
        'drug_name': row['drug_common_name'],
        'phase': row['drug_phase'],
        'status': row['drug_status'],
        'drug_type': row['drug_type']
    }
    ot_disease_drugs[row['disease_id']].append(drug_info)

print(f"\nOpen Targets diseases with drugs: {len(ot_disease_drugs)}")

# Build the final JSON structure
result = {}

for _, row in comp_df.iterrows():
    disease_name = row['disease_name']
    disease_id = row['disease_id']
    total_in_known = int(row['total_in_known_count'])
    
    if total_in_known == 0:
        continue
    
    # Get the drugs found by pipeline for this disease
    tahoe_drugs = set()
    cmap_drugs = set()
    if disease_name in disease_drug_pairs:
        tahoe_drugs = set(d.lower() for d in disease_drug_pairs[disease_name].get('tahoe_drugs', []))
        cmap_drugs = set(d.lower() for d in disease_drug_pairs[disease_name].get('cmap_drugs', []))
    
    # Get known drugs from Open Targets for this disease
    known_drugs = ot_disease_drugs.get(disease_id, [])
    
    # Find which known drugs were hit by pipeline
    known_drugs_details = []
    for drug in known_drugs:
        drug_name = drug['drug_name']
        if drug_name:
            drug_lower = drug_name.lower()
            found_by_tahoe = drug_lower in tahoe_drugs
            found_by_cmap = drug_lower in cmap_drugs
            
            if found_by_tahoe or found_by_cmap:
                known_drugs_details.append({
                    'drug_name': drug_name,
                    'phase': drug['phase'],
                    'status': drug['status'],
                    'drug_type': drug['drug_type'],
                    'found_by_tahoe': found_by_tahoe,
                    'found_by_cmap': found_by_cmap
                })
    
    if not known_drugs_details:
        continue
    
    # Aggregate stats
    phase_counts = defaultdict(int)
    status_counts = defaultdict(int)
    tahoe_count = 0
    cmap_count = 0
    
    for d in known_drugs_details:
        if d['phase']:
            phase_counts[f"phase_{d['phase']}"] += 1
        if d['status']:
            status_counts[d['status']] += 1
        if d['found_by_tahoe']:
            tahoe_count += 1
        if d['found_by_cmap']:
            cmap_count += 1
    
    result[disease_name] = {
        'disease_id': disease_id,
        'total_in_known_count': total_in_known,
        'known_drugs_found': len(known_drugs_details),
        'found_by_tahoe': tahoe_count,
        'found_by_cmap': cmap_count,
        'phase_breakdown': dict(phase_counts),
        'status_breakdown': dict(status_counts),
        'drugs': known_drugs_details
    }

print(f"\nDiseases with known drugs found: {len(result)}")

# Save JSON
output_file = 'validation/step_4_drpipe_validation/step4_known_drugs_detailed_breakdown.json'
with open(output_file, 'w') as f:
    json.dump(result, f, indent=2)
print(f"\nSaved to: {output_file}")

# Print summary
print("\n=== SUMMARY ===")
total_drugs_found = sum(d['known_drugs_found'] for d in result.values())
total_tahoe = sum(d['found_by_tahoe'] for d in result.values())
total_cmap = sum(d['found_by_cmap'] for d in result.values())
print(f"Total diseases with known drug hits: {len(result)}")
print(f"Total known drugs found: {total_drugs_found}")
print(f"Found by TAHOE: {total_tahoe}")
print(f"Found by CMAP: {total_cmap}")
