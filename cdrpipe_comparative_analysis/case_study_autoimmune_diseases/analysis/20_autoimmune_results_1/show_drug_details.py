#!/usr/bin/env python3
"""
Show Recovered Drug Details by Disease

This script shows which specific drugs were recovered by CMAP, TAHOE, or both
for selected autoimmune diseases.
"""

import pandas as pd
import pyarrow.parquet as pq
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Paths
BASE_DIR = Path(__file__).resolve().parents[3]
# Use the exp_8 results which have hits with q<0.50
RESULTS_DIR = BASE_DIR / "creeds_diseases" / "results" / "creed_manual_standardised_results_OG_exp_8"
KNOWN_DRUGS_FILE = BASE_DIR / "data" / "known_drugs" / "known_drug_info_data.parquet"
OUTPUT_DIR = Path(__file__).parent / "drug_details"
OUTPUT_DIR.mkdir(exist_ok=True)

# Diseases of interest (matching directory names in results)
# All 20 autoimmune diseases from Table1_Disease_Summary.csv
DISEASES_OF_INTEREST = [
    "inclusion_body_myositis",
    "discoid_lupus_erythematosus",
    "psoriatic_arthritis",
    "childhood_type_dermatomyositis",
    "Sjogren's_syndrome",
    "Psoriasis_vulgaris",
    "autoimmune_thrombocytopenic_purpura",
    "colitis",
    "scleroderma",
    "psoriasis",
    "inflammatory_bowel_disease",
    "ankylosing_spondylitis",
    "Crohn's_disease",
    "relapsing-remitting_multiple_sclerosis",  # Uses hyphens in results directory
    "rheumatoid_arthritis",
    "systemic_lupus_erythematosus",
    "ulcerative_colitis",
    "multiple_sclerosis",
    "type_1_diabetes_mellitus",
    "arthritis"
]

# Disease name mapping for Open Targets lookup
DISEASE_NAME_MAP = {
    "inclusion_body_myositis": ["inclusion body myositis"],
    "discoid_lupus_erythematosus": ["discoid lupus"],
    "psoriatic_arthritis": ["psoriatic arthritis"],
    "childhood_type_dermatomyositis": ["dermatomyositis"],
    "Sjogren's_syndrome": ["Sjogren", "Sjögren"],
    "Psoriasis_vulgaris": ["psoriasis"],
    "autoimmune_thrombocytopenic_purpura": ["thrombocytopenic purpura", "ITP"],
    "colitis": ["colitis", "inflammatory bowel disease"],
    "scleroderma": ["scleroderma", "systemic sclerosis"],
    "psoriasis": ["psoriasis"],
    "inflammatory_bowel_disease": ["inflammatory bowel disease", "IBD"],
    "ankylosing_spondylitis": ["ankylosing spondylitis"],
    "Crohn's_disease": ["Crohn"],
    "relapsing_remitting_multiple_sclerosis": ["multiple sclerosis"],
    "rheumatoid_arthritis": ["rheumatoid arthritis"],
    "systemic_lupus_erythematosus": ["systemic lupus erythematosus", "lupus erythematosus"],
    "ulcerative_colitis": ["ulcerative colitis"],
    "multiple_sclerosis": ["multiple sclerosis"],
    "type_1_diabetes_mellitus": ["type 1 diabetes", "diabetes mellitus type 1", "insulin-dependent diabetes"],
    "arthritis": ["rheumatoid arthritis", "arthritis"]
}


def load_known_drugs():
    """Load known drugs from Open Targets."""
    df = pq.read_table(KNOWN_DRUGS_FILE).to_pandas()
    return df


def get_known_drugs_for_disease(ot_df, disease_key):
    """Get known drugs for a disease from Open Targets."""
    search_terms = DISEASE_NAME_MAP.get(disease_key, [disease_key.replace('_', ' ')])
    
    mask = pd.Series([False] * len(ot_df))
    for term in search_terms:
        mask |= ot_df['drug_disease_label'].str.contains(term, case=False, na=False)
    
    known_df = ot_df[mask][['drug_common_name', 'drug_phase', 'drug_status']].drop_duplicates()
    known_df = known_df.sort_values(['drug_phase', 'drug_common_name'], ascending=[False, True])
    
    # Get unique drug names (lowercase for comparison)
    known_drugs = set(known_df['drug_common_name'].str.lower().unique())
    
    return known_drugs, known_df


def load_hits_file(disease, method):
    """Load hits file for a disease and method."""
    # Find the directory
    # Handle both underscore and hyphen versions
    patterns = [f"{disease}_{method}_*", f"{disease.replace('_', '-')}_{method}_*"]
    matching_dirs = []
    
    for pattern in patterns:
        matching_dirs.extend(list(RESULTS_DIR.glob(pattern)))
    
    if not matching_dirs:
        print(f"  ⚠️  No directory found for {disease} {method}")
        return None
    
    disease_dir = matching_dirs[0]
    
    # Find the CSV file
    csv_files = list(disease_dir.glob("*_hits_*.csv"))
    
    if not csv_files:
        print(f"  ⚠️  No CSV file found in {disease_dir.name}")
        return None
    
    try:
        df = pd.read_csv(csv_files[0])
        return df
    except Exception as e:
        print(f"  ⚠️  Error loading: {e}")
        return None


def analyze_disease(disease, ot_df):
    """Analyze drug recovery for a disease."""
    print(f"\n{'='*70}")
    print(f"DISEASE: {disease.replace('_', ' ').title()}")
    print('='*70)
    
    # Load known drugs
    known_drugs, known_df = get_known_drugs_for_disease(ot_df, disease)
    print(f"\n📚 Known drugs in Open Targets: {len(known_drugs)}")
    
    # Load CMAP hits
    cmap_df = load_hits_file(disease, "CMAP")
    tahoe_df = load_hits_file(disease, "TAHOE")
    
    if cmap_df is None or tahoe_df is None:
        print("  ❌ Could not load data for this disease")
        return None
    
    # Get drug names from hits
    cmap_drugs = set(cmap_df['name'].str.lower().unique())
    tahoe_drugs = set(tahoe_df['name'].str.lower().unique())
    
    print(f"\n📊 Total drug hits:")
    print(f"   CMAP:  {len(cmap_drugs)} unique drugs")
    print(f"   TAHOE: {len(tahoe_drugs)} unique drugs")
    
    # Find overlaps with known drugs
    cmap_known_overlap = cmap_drugs & known_drugs
    tahoe_known_overlap = tahoe_drugs & known_drugs
    both_overlap = cmap_known_overlap & tahoe_known_overlap
    cmap_only = cmap_known_overlap - tahoe_known_overlap
    tahoe_only = tahoe_known_overlap - cmap_known_overlap
    
    print(f"\n✅ Known drugs recovered:")
    print(f"   By CMAP only:  {len(cmap_only)}")
    print(f"   By TAHOE only: {len(tahoe_only)}")
    print(f"   By BOTH:       {len(both_overlap)}")
    print(f"   Total unique:  {len(cmap_known_overlap | tahoe_known_overlap)}")
    
    # Recovery rates
    cmap_available = len(cmap_drugs & known_drugs) + len([d for d in known_drugs if d in cmap_drugs])
    tahoe_available = len(tahoe_drugs & known_drugs) + len([d for d in known_drugs if d in tahoe_drugs])
    
    # Get drug details from hits files
    def get_drug_details(df, drug_name):
        """Get details for a drug from hits dataframe."""
        drug_row = df[df['name'].str.lower() == drug_name.lower()]
        if len(drug_row) > 0:
            return {
                'score': drug_row.iloc[0].get('cmap_score', 'N/A'),
                'q': drug_row.iloc[0].get('q', 'N/A'),
            }
        return None
    
    # Build results
    results = []
    
    print("\n" + "-"*70)
    print("DRUGS RECOVERED BY BOTH METHODS (Agreement)")
    print("-"*70)
    if both_overlap:
        for drug in sorted(both_overlap):
            cmap_details = get_drug_details(cmap_df, drug)
            tahoe_details = get_drug_details(tahoe_df, drug)
            phase_info = known_df[known_df['drug_common_name'].str.lower() == drug]['drug_phase'].max()
            print(f"  ✓ {drug.upper()}")
            print(f"      Phase: {phase_info}")
            if cmap_details:
                print(f"      CMAP score: {cmap_details['score']:.4f}, q: {cmap_details['q']:.4f}")
            if tahoe_details:
                print(f"      TAHOE score: {tahoe_details['score']:.4f}, q: {tahoe_details['q']:.4f}")
            results.append({
                'drug': drug.upper(),
                'source': 'BOTH',
                'phase': phase_info,
                'cmap_score': cmap_details['score'] if cmap_details else None,
                'tahoe_score': tahoe_details['score'] if tahoe_details else None,
            })
    else:
        print("  (None)")
    
    print("\n" + "-"*70)
    print("DRUGS RECOVERED BY CMAP ONLY")
    print("-"*70)
    if cmap_only:
        for drug in sorted(cmap_only):
            cmap_details = get_drug_details(cmap_df, drug)
            phase_info = known_df[known_df['drug_common_name'].str.lower() == drug]['drug_phase'].max()
            print(f"  ▸ {drug.upper()}")
            print(f"      Phase: {phase_info}")
            if cmap_details:
                print(f"      CMAP score: {cmap_details['score']:.4f}, q: {cmap_details['q']:.4f}")
            results.append({
                'drug': drug.upper(),
                'source': 'CMAP_ONLY',
                'phase': phase_info,
                'cmap_score': cmap_details['score'] if cmap_details else None,
                'tahoe_score': None,
            })
    else:
        print("  (None)")
    
    print("\n" + "-"*70)
    print("DRUGS RECOVERED BY TAHOE ONLY")
    print("-"*70)
    if tahoe_only:
        for drug in sorted(tahoe_only):
            tahoe_details = get_drug_details(tahoe_df, drug)
            phase_info = known_df[known_df['drug_common_name'].str.lower() == drug]['drug_phase'].max()
            print(f"  ▸ {drug.upper()}")
            print(f"      Phase: {phase_info}")
            if tahoe_details:
                print(f"      TAHOE score: {tahoe_details['score']:.4f}, q: {tahoe_details['q']:.4f}")
            results.append({
                'drug': drug.upper(),
                'source': 'TAHOE_ONLY',
                'phase': phase_info,
                'cmap_score': None,
                'tahoe_score': tahoe_details['score'] if tahoe_details else None,
            })
    else:
        print("  (None)")
    
    # Save to CSV
    if results:
        results_df = pd.DataFrame(results)
        # Normalize disease name for output file (replace hyphens with underscores)
        safe_disease_name = disease.replace('-', '_')
        output_file = OUTPUT_DIR / f"{safe_disease_name}_recovered_drugs.csv"
        results_df.to_csv(output_file, index=False)
        print(f"\n💾 Saved to: {output_file.name}")
    
    return {
        'disease': disease,
        'known_total': len(known_drugs),
        'cmap_only': len(cmap_only),
        'tahoe_only': len(tahoe_only),
        'both': len(both_overlap),
        'drugs_both': list(both_overlap),
        'drugs_cmap_only': list(cmap_only),
        'drugs_tahoe_only': list(tahoe_only)
    }


def create_summary_table(all_results):
    """Create a summary table of all results."""
    print("\n" + "="*70)
    print("SUMMARY: Drug Recovery Across Selected Diseases")
    print("="*70)
    
    summary_data = []
    for r in all_results:
        if r is None:
            continue
        summary_data.append({
            'Disease': r['disease'].replace('_', ' ').title(),
            'Known Drugs': r['known_total'],
            'CMAP Only': r['cmap_only'],
            'TAHOE Only': r['tahoe_only'],
            'Both Methods': r['both'],
            'Total Recovered': r['cmap_only'] + r['tahoe_only'] + r['both']
        })
    
    summary_df = pd.DataFrame(summary_data)
    print("\n")
    print(summary_df.to_string(index=False))
    
    # Save summary
    summary_df.to_csv(OUTPUT_DIR / "disease_recovery_summary.csv", index=False)
    print(f"\n💾 Summary saved to: disease_recovery_summary.csv")
    
    return summary_df


def main():
    print("\n" + "="*70)
    print("DRUG RECOVERY ANALYSIS FOR SELECTED AUTOIMMUNE DISEASES")
    print("="*70)
    
    # Load known drugs
    print("\n[1] Loading Open Targets known drugs database...")
    ot_df = load_known_drugs()
    print(f"    Loaded {len(ot_df)} drug-disease associations")
    
    # Analyze each disease
    print("\n[2] Analyzing each disease...")
    all_results = []
    
    for disease in DISEASES_OF_INTEREST:
        result = analyze_disease(disease, ot_df)
        all_results.append(result)
    
    # Create summary
    print("\n[3] Creating summary...")
    summary_df = create_summary_table(all_results)
    
    print("\n" + "="*70)
    print("✓ Analysis complete!")
    print(f"  Output directory: {OUTPUT_DIR}")
    print("="*70)


if __name__ == "__main__":
    main()
