#!/usr/bin/env python3
"""
Merge disease entries for autoimmune case study:
1. Psoriasis + Psoriasis vulgaris → "Psoriasis"
2. Childhood type dermatomyositis + Dermatomyositis (adult) → "Dermatomyositis"

This script:
- Reads per-disease recovery CSVs
- Reads pipeline result hit files
- Reads Open Targets for known drug counts
- Reads platform drug libraries for "available" counts
- Computes merged statistics
- Updates the xlsx, Table1, and disease_recovery_summary
- Creates merged recovery CSVs
"""

import pandas as pd
import pyarrow.parquet as pq
from pathlib import Path
from copy import deepcopy
import warnings
warnings.filterwarnings('ignore')

BASE_DIR = Path(__file__).resolve().parents[3]
RESULTS_DIR = BASE_DIR / "creeds" / "results" / "manual_standardized_all_diseases_results"
OT_FILE = BASE_DIR / "drug_evidence" / "data" / "open_targets" / "known_drug_info_data.parquet"
RECOVERY_DIR = BASE_DIR / "autoimmune" / "analysis" / "per_disease_recovery"
SUMMARY_DIR = BASE_DIR / "autoimmune" / "analysis" / "recovery_summary"
XLSX_FILE = SUMMARY_DIR / "20_autoimmune.xlsx"

# Platform drug libraries
CMAP_DRUGS_FILE = BASE_DIR / "drug_signatures" / "data" / "cmap" / "cmap_drug_experiments_new.csv"
TAHOE_DRUGS_FILE = BASE_DIR / "drug_signatures" / "data" / "tahoe" / "tahoe_drug_experiments_new.csv"


def load_platform_libraries():
    cmap = set(pd.read_csv(CMAP_DRUGS_FILE)['name'].str.lower().unique())
    tahoe = set(pd.read_csv(TAHOE_DRUGS_FILE)['name'].str.lower().unique())
    return cmap, tahoe


def load_open_targets():
    return pq.read_table(OT_FILE).to_pandas()


def get_known_drugs(ot_df, search_terms):
    """Get known drug names from Open Targets matching search terms."""
    mask = pd.Series([False] * len(ot_df))
    for term in search_terms:
        mask |= ot_df['drug_disease_label'].str.contains(term, case=False, na=False)
    return set(ot_df[mask]['drug_common_name'].str.lower().unique())


def load_hits(disease_prefix, method):
    """Load significant hits from pipeline results. Returns set of lowercase drug names."""
    patterns = [
        f"{disease_prefix}_{method}_*",
        f"{disease_prefix}_{method.lower()}_*",
    ]
    dirs = []
    for p in patterns:
        dirs.extend(list(RESULTS_DIR.glob(p)))
    if not dirs:
        return None
    csv_files = list(dirs[0].glob("*hits*.csv"))
    if not csv_files:
        return None
    df = pd.read_csv(csv_files[0])
    sig = df[(df['q'] < 0.05) & (df['cmap_score'] < 0)]
    return set(sig['name'].str.lower().unique())


def load_recovery_csv(disease_name):
    """Load per-disease recovery CSV. Returns DataFrame or None."""
    matches = list(RECOVERY_DIR.glob(f"{disease_name}_recovered_drugs.csv"))
    if not matches:
        return None
    return pd.read_csv(matches[0])


def compute_recovered_sets(recovery_dfs):
    """From list of recovery DataFrames, compute union of CMAP and TAHOE recovered drug sets."""
    cmap_set = set()
    tahoe_set = set()
    for df in recovery_dfs:
        if df is None:
            continue
        for _, row in df.iterrows():
            drug = row['drug'].lower()
            if row['source'] in ['CMAP_ONLY', 'BOTH']:
                cmap_set.add(drug)
            if row['source'] in ['TAHOE_ONLY', 'BOTH']:
                tahoe_set.add(drug)
    return cmap_set, tahoe_set


def build_merged_recovery_csv(recovery_dfs, cmap_recovered, tahoe_recovered):
    """Build a merged recovery DataFrame with correct source labels."""
    both = cmap_recovered & tahoe_recovered
    cmap_only = cmap_recovered - tahoe_recovered
    tahoe_only = tahoe_recovered - cmap_recovered

    # Collect best scores from original CSVs
    drug_scores = {}
    for df in recovery_dfs:
        if df is None:
            continue
        for _, row in df.iterrows():
            drug = row['drug'].upper()
            key = drug.lower()
            if key not in drug_scores:
                drug_scores[key] = {'drug': drug, 'phase': row.get('phase', None),
                                     'cmap_score': None, 'tahoe_score': None}
            if pd.notna(row.get('cmap_score')):
                existing = drug_scores[key]['cmap_score']
                if existing is None or abs(row['cmap_score']) > abs(existing):
                    drug_scores[key]['cmap_score'] = row['cmap_score']
            if pd.notna(row.get('tahoe_score')):
                existing = drug_scores[key]['tahoe_score']
                if existing is None or abs(row['tahoe_score']) > abs(existing):
                    drug_scores[key]['tahoe_score'] = row['tahoe_score']

    rows = []
    for drug_lower in sorted(cmap_recovered | tahoe_recovered):
        info = drug_scores.get(drug_lower, {'drug': drug_lower.upper(), 'phase': None,
                                              'cmap_score': None, 'tahoe_score': None})
        if drug_lower in both:
            source = 'BOTH'
        elif drug_lower in cmap_only:
            source = 'CMAP_ONLY'
        else:
            source = 'TAHOE_ONLY'
        rows.append({
            'drug': info['drug'],
            'source': source,
            'phase': info['phase'],
            'cmap_score': info['cmap_score'],
            'tahoe_score': info['tahoe_score'],
        })
    return pd.DataFrame(rows)


def merge_psoriasis(ot_df, cmap_lib, tahoe_lib, xlsx_df):
    """Merge psoriasis + psoriasis vulgaris."""
    print("\n=== MERGING: Psoriasis + Psoriasis Vulgaris → Psoriasis ===")

    # Known drugs
    known = get_known_drugs(ot_df, ["psoriasis"])
    print(f"  Known drugs (Open Targets 'psoriasis'): {len(known)}")

    # Available in platform libraries
    avail_cmap = known & cmap_lib
    avail_tahoe = known & tahoe_lib
    print(f"  Available: CMAP={len(avail_cmap)}, TAHOE={len(avail_tahoe)}")

    # Pipeline CMAP hits (can compute union from directories)
    p_cmap_hits = load_hits("psoriasis", "CMAP")
    pv_cmap_hits = load_hits("Psoriasis_vulgaris", "CMAP") or load_hits("psoriasis_vulgaris", "CMAP")
    pv_tahoe_hits = load_hits("Psoriasis_vulgaris", "TAHOE") or load_hits("psoriasis_vulgaris", "TAHOE")

    # For psoriasis TAHOE: no pipeline directory exists, but recovery CSV has TAHOE data
    # Use existing recovery CSV as ground truth + PV TAHOE pipeline hits
    merged_cmap_hits = set()
    if p_cmap_hits:
        merged_cmap_hits |= p_cmap_hits
    if pv_cmap_hits:
        merged_cmap_hits |= pv_cmap_hits
    print(f"  CMAP hits (merged union): {len(merged_cmap_hits)}")

    # For TAHOE hits: we have PV TAHOE pipeline results + psoriasis TAHOE from xlsx
    # Use PV TAHOE pipeline results as base, plus any extra from psoriasis xlsx
    merged_tahoe_hits = pv_tahoe_hits or set()
    # The psoriasis xlsx had 332 TAHOE hits; PV has its own. 
    # Since psoriasis TAHOE pipeline dir is gone, take max as conservative estimate
    p_tahoe_from_xlsx = int(xlsx_df.loc[xlsx_df['disease_name'] == 'psoriasis', 'tahoe_hits_count'].values[0]) if len(xlsx_df[xlsx_df['disease_name'] == 'psoriasis']) > 0 else 0
    tahoe_hits_count = max(len(merged_tahoe_hits), p_tahoe_from_xlsx)
    print(f"  TAHOE hits: PV pipeline={len(merged_tahoe_hits)}, psoriasis_xlsx={p_tahoe_from_xlsx}, using max={tahoe_hits_count}")

    # Recovered drugs from recovery CSVs
    p_recov = load_recovery_csv("psoriasis")
    pv_recov = load_recovery_csv("Psoriasis_vulgaris")
    cmap_recovered, tahoe_recovered = compute_recovered_sets([p_recov, pv_recov])
    both_recovered = cmap_recovered & tahoe_recovered
    total_recovered = cmap_recovered | tahoe_recovered
    print(f"  Recovered: CMAP={len(cmap_recovered)}, TAHOE={len(tahoe_recovered)}, BOTH={len(both_recovered)}, Total={len(total_recovered)}")
    print(f"  CMAP rate: {len(cmap_recovered)}/{len(avail_cmap)} = {len(cmap_recovered)/len(avail_cmap)*100:.1f}%")
    print(f"  TAHOE rate: {len(tahoe_recovered)}/{len(avail_tahoe)} = {len(tahoe_recovered)/len(avail_tahoe)*100:.1f}%")

    # Build merged recovery CSV
    merged_csv = build_merged_recovery_csv([p_recov, pv_recov], cmap_recovered, tahoe_recovered)
    out_path = RECOVERY_DIR / "psoriasis_merged_recovered_drugs.csv"
    merged_csv.to_csv(out_path, index=False)
    print(f"  Saved merged recovery CSV: {out_path.name}")

    # Common hits (across both platforms)
    common_hits = merged_cmap_hits & merged_tahoe_hits if merged_tahoe_hits else set()
    common_in_known = (cmap_recovered & tahoe_recovered)

    # Total unique drugs across platforms
    total_unique = len(merged_cmap_hits | merged_tahoe_hits) if merged_tahoe_hits else len(merged_cmap_hits) + tahoe_hits_count

    # Overall recovery rate = total_recovered / total_unique
    overall_rate = len(total_recovered) / total_unique if total_unique > 0 else 0

    return {
        'disease_name': 'psoriasis',
        'disease_id': 'EFO_0000676',
        'total_known_drugs_in_database_count': len(known),
        'total_unique_drugs_cmap_tahoe': total_unique,
        'known_drugs_available_in_cmap_count': len(avail_cmap),
        'cmap_hits_count': len(merged_cmap_hits),
        'cmap_in_known_count': len(cmap_recovered),
        'CMAP Recovery Rate': len(cmap_recovered) / len(avail_cmap) if avail_cmap else 0,
        'known_drugs_available_in_tahoe_count': len(avail_tahoe),
        'tahoe_hits_count': tahoe_hits_count,
        'tahoe_in_known_count': len(tahoe_recovered),
        'TAHOE Recovery Rate': len(tahoe_recovered) / len(avail_tahoe) if avail_tahoe else 0,
        'common_hits_count': len(common_hits),
        'common_in_known_count': len(common_in_known),
        'total_in_known_count': len(total_recovered),
        'Overall Recovery Rate': overall_rate,
    }


def merge_dermatomyositis(ot_df, cmap_lib, tahoe_lib, xlsx_df):
    """Merge childhood type dermatomyositis + adult dermatomyositis."""
    print("\n=== MERGING: Childhood + Adult Dermatomyositis → Dermatomyositis ===")

    # Known drugs
    known = get_known_drugs(ot_df, ["dermatomyositis"])
    print(f"  Known drugs (Open Targets 'dermatomyositis'): {len(known)}")

    avail_cmap = known & cmap_lib
    avail_tahoe = known & tahoe_lib
    print(f"  Available: CMAP={len(avail_cmap)}, TAHOE={len(avail_tahoe)}")

    # CMAP hits from pipeline results
    child_cmap = load_hits("childhood_type_dermatomyositis", "CMAP")
    adult_cmap = load_hits("dermatomyositis", "CMAP")
    merged_cmap_hits = set()
    if child_cmap:
        merged_cmap_hits |= child_cmap
        print(f"  Childhood CMAP hits: {len(child_cmap)}")
    if adult_cmap:
        merged_cmap_hits |= adult_cmap
        print(f"  Adult CMAP hits: {len(adult_cmap)}")
    print(f"  Merged CMAP hits: {len(merged_cmap_hits)}")

    # TAHOE: neither has pipeline TAHOE results directory
    # But childhood has TAHOE data in recovery CSV (from xlsx/previous run)
    child_tahoe = load_hits("childhood_type_dermatomyositis", "TAHOE")
    adult_tahoe = load_hits("dermatomyositis", "TAHOE")
    merged_tahoe_hits = set()
    if child_tahoe:
        merged_tahoe_hits |= child_tahoe
    if adult_tahoe:
        merged_tahoe_hits |= adult_tahoe

    # Get TAHOE hits from xlsx for childhood (if pipeline dir missing)
    child_tahoe_from_xlsx = 0
    child_row = xlsx_df[xlsx_df['disease_name'] == 'childhood type dermatomyositis']
    if len(child_row) > 0:
        child_tahoe_from_xlsx = int(child_row['tahoe_hits_count'].values[0])
    tahoe_hits_count = max(len(merged_tahoe_hits), child_tahoe_from_xlsx)
    print(f"  TAHOE hits: pipeline={len(merged_tahoe_hits)}, xlsx={child_tahoe_from_xlsx}, using max={tahoe_hits_count}")

    # Recovered drugs from existing recovery CSV (only childhood has one)
    child_recov = load_recovery_csv("childhood_type_dermatomyositis")

    # For adult dermatomyositis: compute recovered from CMAP hits ∩ known drugs
    adult_cmap_recovered = set()
    if adult_cmap:
        adult_cmap_recovered = adult_cmap & known
        print(f"  Adult CMAP recovered (hit ∩ known): {len(adult_cmap_recovered)}")

    # Merge recovered sets
    cmap_recovered, tahoe_recovered = compute_recovered_sets([child_recov])
    # Add adult CMAP recovered
    cmap_recovered |= adult_cmap_recovered

    both_recovered = cmap_recovered & tahoe_recovered
    total_recovered = cmap_recovered | tahoe_recovered
    print(f"  Merged recovered: CMAP={len(cmap_recovered)}, TAHOE={len(tahoe_recovered)}, BOTH={len(both_recovered)}, Total={len(total_recovered)}")

    if avail_cmap:
        print(f"  CMAP rate: {len(cmap_recovered)}/{len(avail_cmap)} = {len(cmap_recovered)/len(avail_cmap)*100:.1f}%")
    if avail_tahoe:
        print(f"  TAHOE rate: {len(tahoe_recovered)}/{len(avail_tahoe)} = {len(tahoe_recovered)/len(avail_tahoe)*100:.1f}%")

    # Build merged recovery CSV
    # For adult, if any CMAP recovered, we need to add them
    adult_recov_rows = []
    if adult_cmap_recovered:
        for drug in adult_cmap_recovered:
            adult_recov_rows.append(pd.DataFrame([{
                'drug': drug.upper(), 'source': 'CMAP_ONLY', 'phase': None,
                'cmap_score': None, 'tahoe_score': None
            }]))
    adult_recov_df = pd.concat(adult_recov_rows) if adult_recov_rows else None

    merged_csv = build_merged_recovery_csv(
        [child_recov, adult_recov_df], cmap_recovered, tahoe_recovered
    )
    out_path = RECOVERY_DIR / "dermatomyositis_merged_recovered_drugs.csv"
    merged_csv.to_csv(out_path, index=False)
    print(f"  Saved merged recovery CSV: {out_path.name}")

    # Common hits
    common_hits = merged_cmap_hits & merged_tahoe_hits if merged_tahoe_hits else set()
    common_in_known = cmap_recovered & tahoe_recovered

    total_unique = len(merged_cmap_hits | merged_tahoe_hits) if merged_tahoe_hits else len(merged_cmap_hits) + tahoe_hits_count
    overall_rate = len(total_recovered) / total_unique if total_unique > 0 else 0

    return {
        'disease_name': 'dermatomyositis',
        'disease_id': 'EFO_0000557',
        'total_known_drugs_in_database_count': len(known),
        'total_unique_drugs_cmap_tahoe': total_unique,
        'known_drugs_available_in_cmap_count': len(avail_cmap),
        'cmap_hits_count': len(merged_cmap_hits),
        'cmap_in_known_count': len(cmap_recovered),
        'CMAP Recovery Rate': len(cmap_recovered) / len(avail_cmap) if avail_cmap else 0,
        'known_drugs_available_in_tahoe_count': len(avail_tahoe),
        'tahoe_hits_count': tahoe_hits_count,
        'tahoe_in_known_count': len(tahoe_recovered),
        'TAHOE Recovery Rate': len(tahoe_recovered) / len(avail_tahoe) if avail_tahoe else 0,
        'common_hits_count': len(common_hits),
        'common_in_known_count': len(common_in_known),
        'total_in_known_count': len(total_recovered),
        'Overall Recovery Rate': overall_rate,
    }


def main():
    print("Loading data sources...")
    ot_df = load_open_targets()
    cmap_lib, tahoe_lib = load_platform_libraries()
    xlsx_df = pd.read_excel(XLSX_FILE)
    
    print(f"Open Targets: {len(ot_df)} rows")
    print(f"CMAP library: {len(cmap_lib)} drugs, TAHOE library: {len(tahoe_lib)} drugs")
    print(f"Current xlsx: {len(xlsx_df)} diseases")

    # Perform merges
    psoriasis_merged = merge_psoriasis(ot_df, cmap_lib, tahoe_lib, xlsx_df)
    dermatomyositis_merged = merge_dermatomyositis(ot_df, cmap_lib, tahoe_lib, xlsx_df)

    # Update xlsx
    # Remove old entries
    remove_names = [
        'psoriasis', 'Psoriasis vulgaris', 'psoriasis vulgaris',
        'childhood type dermatomyositis'
    ]
    new_df = xlsx_df[~xlsx_df['disease_name'].str.lower().isin([n.lower() for n in remove_names])].copy()

    # Add merged entries
    for merged in [psoriasis_merged, dermatomyositis_merged]:
        new_df = pd.concat([new_df, pd.DataFrame([merged])], ignore_index=True)

    # Sort by TAHOE recovery rate descending (matching original order style)
    new_df = new_df.sort_values('TAHOE Recovery Rate', ascending=False).reset_index(drop=True)

    print(f"\n=== UPDATED XLSX: {len(new_df)} diseases ===")
    for _, row in new_df.iterrows():
        print(f"  {row['disease_name']:45s} Known={int(row['total_known_drugs_in_database_count']):5d}  "
              f"CMAP={row['CMAP Recovery Rate']*100:5.1f}%  TAHOE={row['TAHOE Recovery Rate']*100:5.1f}%")

    # Save
    new_df.to_excel(XLSX_FILE, index=False)
    print(f"\nSaved updated xlsx: {XLSX_FILE.name}")

    # Update disease_recovery_summary.csv
    summary_rows = []
    for _, row in new_df.iterrows():
        summary_rows.append({
            'Disease': row['disease_name'].replace('_', ' ').title() if row['disease_name'].islower() else row['disease_name'],
            'Known Drugs': int(row['total_known_drugs_in_database_count']),
            'CMAP Only': int(row['cmap_in_known_count'] - row.get('common_in_known_count', 0)),
            'TAHOE Only': int(row['tahoe_in_known_count'] - row.get('common_in_known_count', 0)),
            'Both Methods': int(row.get('common_in_known_count', 0)),
            'Total Recovered': int(row['total_in_known_count']),
        })
    summary_df = pd.DataFrame(summary_rows)
    summary_df.to_csv(RECOVERY_DIR / "disease_recovery_summary.csv", index=False)
    print(f"Saved: disease_recovery_summary.csv")

    # Also rename recovery CSVs
    # Remove old ones, keep merged
    old_files = [
        RECOVERY_DIR / "psoriasis_recovered_drugs.csv",
        RECOVERY_DIR / "Psoriasis_vulgaris_recovered_drugs.csv",
        RECOVERY_DIR / "childhood_type_dermatomyositis_recovered_drugs.csv",
    ]
    for f in old_files:
        if f.exists():
            new_name = f.parent / f"ARCHIVED_{f.name}"
            f.rename(new_name)
            print(f"Archived: {f.name} → ARCHIVED_{f.name}")

    # Rename merged files to standard names
    merged_psor = RECOVERY_DIR / "psoriasis_merged_recovered_drugs.csv"
    if merged_psor.exists():
        merged_psor.rename(RECOVERY_DIR / "psoriasis_recovered_drugs.csv")
        print("Renamed: psoriasis_merged → psoriasis_recovered_drugs.csv")

    merged_derm = RECOVERY_DIR / "dermatomyositis_merged_recovered_drugs.csv"
    if merged_derm.exists():
        merged_derm.rename(RECOVERY_DIR / "dermatomyositis_recovered_drugs.csv")
        print("Renamed: dermatomyositis_merged → dermatomyositis_recovered_drugs.csv")

    print("\n✓ Merge complete!")


if __name__ == "__main__":
    main()
