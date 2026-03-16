#!/usr/bin/env python3
"""
Overlap analysis between TAHOE and CMAP drug repurposing results
"""
import pandas as pd
import os
from collections import defaultdict

# Define directories
tahoe_dir = "scripts/results/endo_v5_tahoe"
cmap_dir = "scripts/results/endo_v4_cmap"

# Mapping of subdirectories
subtype_map = {
    "ESE": ("endo_tahoe_ESE", "endo_v4_ESE"),
    "IIInIV": ("endo_tahoe_IIInIV", "endo_v4_IIInIV"),
    "InII": ("endo_tahoe_InII", "endo_v4_InII"),
    "MSE": ("endo_tahoe_MSE", "endo_v4_MSE"),
    "PE": ("endo_tahoe_PE", "endo_v4_PE"),
    "Unstratified": ("endo_tahoe_Unstratified", "endo_v4_Unstratified"),
}

def find_hits_file(directory):
    """Find the hits CSV file in a directory"""
    for f in os.listdir(directory):
        if f.endswith(".csv") and "hits" in f and "logFC_1.1" in f:
            return os.path.join(directory, f)
    return None

def normalize_drug_name(name):
    """Normalize drug names for comparison"""
    if pd.isna(name):
        return ""
    name = str(name).lower().strip()
    # Remove common suffixes
    for suffix in [" hydrochloride", " sodium", " dihydrochloride", " calcium", 
                   " maleate", " fumarate", " sulfate", " acetate", " tartrate",
                   "(hydrochloride)", "(sodium)", "(calcium)", "(hemifumarate)",
                   "(dihydrochloride)", "(olamine)"]:
        name = name.replace(suffix.lower(), "")
    return name.strip()

print("=" * 80)
print("TAHOE vs CMAP Drug Repurposing - Overlap Analysis")
print("=" * 80)
print()

# Summary table
summary_data = []

all_tahoe_drugs = set()
all_cmap_drugs = set()
all_overlap_drugs = set()

for subtype, (tahoe_subdir, cmap_subdir) in subtype_map.items():
    print(f"\n{'='*60}")
    print(f"Subtype: {subtype}")
    print(f"{'='*60}")
    
    tahoe_path = find_hits_file(os.path.join(tahoe_dir, tahoe_subdir))
    cmap_path = find_hits_file(os.path.join(cmap_dir, cmap_subdir))
    
    if not tahoe_path or not cmap_path:
        print(f"  Could not find hits files for {subtype}")
        continue
    
    # Read data
    tahoe_df = pd.read_csv(tahoe_path)
    cmap_df = pd.read_csv(cmap_path)
    
    # Get drug names
    tahoe_drugs_raw = set(tahoe_df['name'].dropna().unique())
    cmap_drugs_raw = set(cmap_df['name'].dropna().unique())
    
    # Normalize for comparison
    tahoe_drugs_norm = {normalize_drug_name(d): d for d in tahoe_drugs_raw}
    cmap_drugs_norm = {normalize_drug_name(d): d for d in cmap_drugs_raw}
    
    # Find overlap
    overlap_norm = set(tahoe_drugs_norm.keys()) & set(cmap_drugs_norm.keys())
    tahoe_only_norm = set(tahoe_drugs_norm.keys()) - set(cmap_drugs_norm.keys())
    cmap_only_norm = set(cmap_drugs_norm.keys()) - set(tahoe_drugs_norm.keys())
    
    # Track across all subtypes
    all_tahoe_drugs.update(tahoe_drugs_norm.keys())
    all_cmap_drugs.update(cmap_drugs_norm.keys())
    all_overlap_drugs.update(overlap_norm)
    
    print(f"\n  TAHOE hits: {len(tahoe_drugs_raw)}")
    print(f"  CMAP hits: {len(cmap_drugs_raw)}")
    print(f"  Overlapping drugs: {len(overlap_norm)}")
    print(f"  TAHOE only: {len(tahoe_only_norm)}")
    print(f"  CMAP only: {len(cmap_only_norm)}")
    
    if overlap_norm:
        print(f"\n  Overlapping drugs:")
        for norm_name in sorted(overlap_norm):
            tahoe_name = tahoe_drugs_norm[norm_name]
            cmap_name = cmap_drugs_norm[norm_name]
            print(f"    - {tahoe_name} (TAHOE) / {cmap_name} (CMAP)")
    
    if tahoe_only_norm:
        print(f"\n  TAHOE-only drugs:")
        for norm_name in sorted(tahoe_only_norm):
            print(f"    - {tahoe_drugs_norm[norm_name]}")
    
    summary_data.append({
        'Subtype': subtype,
        'TAHOE_hits': len(tahoe_drugs_raw),
        'CMAP_hits': len(cmap_drugs_raw),
        'Overlap': len(overlap_norm),
        'TAHOE_only': len(tahoe_only_norm),
        'CMAP_only': len(cmap_only_norm),
        'Overlap_pct_TAHOE': round(100 * len(overlap_norm) / len(tahoe_drugs_raw), 1) if tahoe_drugs_raw else 0,
        'Overlap_pct_CMAP': round(100 * len(overlap_norm) / len(cmap_drugs_raw), 1) if cmap_drugs_raw else 0,
    })

# Overall summary
print("\n" + "=" * 80)
print("OVERALL SUMMARY")
print("=" * 80)

summary_df = pd.DataFrame(summary_data)
print("\n" + summary_df.to_string(index=False))

print(f"\n\nTotal unique drugs across all subtypes:")
print(f"  TAHOE: {len(all_tahoe_drugs)} unique drugs")
print(f"  CMAP: {len(all_cmap_drugs)} unique drugs")
print(f"  Overlapping: {len(all_overlap_drugs)} unique drugs")

# Key statistics
total_tahoe = sum(d['TAHOE_hits'] for d in summary_data)
total_cmap = sum(d['CMAP_hits'] for d in summary_data)
total_overlap = sum(d['Overlap'] for d in summary_data)

print(f"\n\nAggregate statistics (sum across all subtypes):")
print(f"  Total TAHOE hits: {total_tahoe}")
print(f"  Total CMAP hits: {total_cmap}")
print(f"  Total overlapping: {total_overlap}")
print(f"  CMAP has {total_cmap - total_tahoe} more hits than TAHOE ({round(100*total_cmap/total_tahoe,1)}x)")

print("\n" + "=" * 80)
print("POSSIBLE REASONS FOR FEWER TAHOE HITS:")
print("=" * 80)
print("""
1. DATABASE SIZE DIFFERENCE:
   - CMAP has ~6,100 perturbation profiles
   - TAHOE may have a different number of drug profiles

2. GENE OVERLAP:
   - Different gene coverage between CMAP and TAHOE platforms
   - Disease signature genes may not all be present in TAHOE

3. SCORING METHOD:
   - Different connectivity scoring algorithms
   - Different permutation/p-value calculation methods

4. THRESHOLD SENSITIVITY:
   - Both use q < 0.00, but underlying distributions differ
   - TAHOE may have tighter score distributions

5. CELL LINE COVERAGE:
   - CMAP uses MCF7, PC3, HL60 (cancer cell lines)
   - TAHOE may use different cell lines

6. CONCENTRATION/DURATION:
   - CMAP: typically 6-hour exposures at specific concentrations
   - TAHOE: 24-hour exposures (as seen in results)
""")
