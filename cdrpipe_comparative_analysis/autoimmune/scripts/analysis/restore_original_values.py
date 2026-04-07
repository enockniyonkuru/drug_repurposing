#!/usr/bin/env python3
"""
Restore the xlsx with original values for non-merged diseases, 
keep correctly computed merged entries (psoriasis, dermatomyositis).
"""

import pandas as pd
import pyarrow.parquet as pq
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

BASE_DIR = Path(__file__).resolve().parents[3]
OT_FILE = BASE_DIR / "drug_evidence" / "data" / "open_targets" / "known_drug_info_data.parquet"
XLSX_FILE = BASE_DIR / "autoimmune" / "analysis" / "recovery_summary" / "20_autoimmune.xlsx"
RECOVERY_DIR = BASE_DIR / "autoimmune" / "analysis" / "per_disease_recovery"
CMAP_DRUGS = BASE_DIR / "drug_signatures" / "data" / "cmap" / "cmap_drug_experiments_new.csv"
TAHOE_DRUGS = BASE_DIR / "drug_signatures" / "data" / "tahoe" / "tahoe_drug_experiments_new.csv"

# Original values before merge (from the 19-disease xlsx snapshot)
ORIGINAL_DATA = {
    "multiple sclerosis": {"known": 1885, "avail_cmap": 43, "avail_tahoe": 16, "rec_cmap": 12, "rec_tahoe": 7, "cmap_hits": 247, "tahoe_hits": 141, "total_unique": 774, "common_hits": 1, "common_in_known": 0, "total_in_known": 18},
    "systemic lupus erythematosus": {"known": 1071, "avail_cmap": 20, "avail_tahoe": 15, "rec_cmap": 8, "rec_tahoe": 9, "cmap_hits": 268, "tahoe_hits": 267, "total_unique": 894, "common_hits": 5, "common_in_known": 1, "total_in_known": 16},
    "rheumatoid arthritis": {"known": 2397, "avail_cmap": 45, "avail_tahoe": 25, "rec_cmap": 8, "rec_tahoe": 16, "cmap_hits": 164, "tahoe_hits": 272, "total_unique": 859, "common_hits": 1, "common_in_known": 2, "total_in_known": 22},
    "type 1 diabetes mellitus": {"known": 1788, "avail_cmap": 31, "avail_tahoe": 12, "rec_cmap": 8, "rec_tahoe": 2, "cmap_hits": 201, "tahoe_hits": 178, "total_unique": 807, "common_hits": 1, "common_in_known": 0, "total_in_known": 10},
    "relapsing-remitting multiple sclerosis": {"known": 816, "avail_cmap": 19, "avail_tahoe": 9, "rec_cmap": 6, "rec_tahoe": 6, "cmap_hits": 679, "tahoe_hits": 248, "total_unique": 1065, "common_hits": 2, "common_in_known": 0, "total_in_known": 12},
    "sjogren's syndrome": {"known": 304, "avail_cmap": 6, "avail_tahoe": 4, "rec_cmap": 4, "rec_tahoe": 4, "cmap_hits": 701, "tahoe_hits": 315, "total_unique": 1086, "common_hits": 0, "common_in_known": 0, "total_in_known": 8},
    "ulcerative colitis": {"known": 1192, "avail_cmap": 24, "avail_tahoe": 10, "rec_cmap": 3, "rec_tahoe": 5, "cmap_hits": 68, "tahoe_hits": 207, "total_unique": 619, "common_hits": 0, "common_in_known": 0, "total_in_known": 8},
    "autoimmune thrombocytopenic purpura": {"known": 605, "avail_cmap": 16, "avail_tahoe": 11, "rec_cmap": 2, "rec_tahoe": 11, "cmap_hits": 28, "tahoe_hits": 379, "total_unique": 474, "common_hits": 0, "common_in_known": 0, "total_in_known": 13},
    "crohn's disease": {"known": 1283, "avail_cmap": 27, "avail_tahoe": 12, "rec_cmap": 2, "rec_tahoe": 9, "cmap_hits": 102, "tahoe_hits": 332, "total_unique": 476, "common_hits": 0, "common_in_known": 0, "total_in_known": 11},
    "scleroderma": {"known": 224, "avail_cmap": 4, "avail_tahoe": 1, "rec_cmap": 2, "rec_tahoe": 1, "cmap_hits": 300, "tahoe_hits": 230, "total_unique": 978, "common_hits": 0, "common_in_known": 0, "total_in_known": 3},
    "inflammatory bowel disease": {"known": 538, "avail_cmap": 11, "avail_tahoe": 7, "rec_cmap": 1, "rec_tahoe": 6, "cmap_hits": 109, "tahoe_hits": 345, "total_unique": 503, "common_hits": 0, "common_in_known": 0, "total_in_known": 6},
    "ankylosing spondylitis": {"known": 634, "avail_cmap": 12, "avail_tahoe": 9, "rec_cmap": 0, "rec_tahoe": 7, "cmap_hits": 7, "tahoe_hits": 272, "total_unique": 417, "common_hits": 0, "common_in_known": 0, "total_in_known": 7},
    "psoriatic arthritis": {"known": 630, "avail_cmap": 9, "avail_tahoe": 6, "rec_cmap": 0, "rec_tahoe": 6, "cmap_hits": 5, "tahoe_hits": 365, "total_unique": 709, "common_hits": 0, "common_in_known": 0, "total_in_known": 6},
    "discoid lupus erythematosus": {"known": 84, "avail_cmap": 1, "avail_tahoe": 2, "rec_cmap": 0, "rec_tahoe": 2, "cmap_hits": 6, "tahoe_hits": 357, "total_unique": 433, "common_hits": 0, "common_in_known": 0, "total_in_known": 2},
    "inclusion body myositis": {"known": 69, "avail_cmap": 1, "avail_tahoe": 1, "rec_cmap": 0, "rec_tahoe": 1, "cmap_hits": 7, "tahoe_hits": 357, "total_unique": 419, "common_hits": 0, "common_in_known": 0, "total_in_known": 1},
    "juvenile idiopathic arthritis (sjia)": {"known": 41, "avail_cmap": 11, "avail_tahoe": 8, "rec_cmap": 0, "rec_tahoe": 3, "cmap_hits": 72, "tahoe_hits": 81, "total_unique": 191, "common_hits": 0, "common_in_known": 0, "total_in_known": 3},
}

def main():
    df = pd.read_excel(XLSX_FILE)
    
    # Restore original values for non-merged diseases
    for idx, row in df.iterrows():
        disease = row['disease_name'].lower()
        if disease in ['psoriasis', 'dermatomyositis']:
            continue  # Keep merged values
        
        orig = ORIGINAL_DATA.get(disease)
        if orig is None:
            print(f"  WARNING: No original data for '{row['disease_name']}'")
            continue
        
        df.at[idx, 'total_known_drugs_in_database_count'] = orig['known']
        df.at[idx, 'known_drugs_available_in_cmap_count'] = orig['avail_cmap']
        df.at[idx, 'cmap_hits_count'] = orig['cmap_hits']
        df.at[idx, 'cmap_in_known_count'] = orig['rec_cmap']
        df.at[idx, 'known_drugs_available_in_tahoe_count'] = orig['avail_tahoe']
        df.at[idx, 'tahoe_hits_count'] = orig['tahoe_hits']
        df.at[idx, 'tahoe_in_known_count'] = orig['rec_tahoe']
        df.at[idx, 'total_unique_drugs_cmap_tahoe'] = orig['total_unique']
        df.at[idx, 'common_hits_count'] = orig['common_hits']
        df.at[idx, 'common_in_known_count'] = orig['common_in_known']
        df.at[idx, 'total_in_known_count'] = orig['total_in_known']
        
        # Recompute rates
        df.at[idx, 'CMAP Recovery Rate'] = orig['rec_cmap'] / orig['avail_cmap'] if orig['avail_cmap'] > 0 else 0
        df.at[idx, 'TAHOE Recovery Rate'] = orig['rec_tahoe'] / orig['avail_tahoe'] if orig['avail_tahoe'] > 0 else 0
        df.at[idx, 'Overall Recovery Rate'] = orig['total_in_known'] / orig['total_unique'] if orig['total_unique'] > 0 else 0
    
    # Sort by TAHOE recovery rate descending
    df = df.sort_values('TAHOE Recovery Rate', ascending=False).reset_index(drop=True)
    
    # Verify no recovered > available issues
    print("Verification:")
    issues = 0
    for _, r in df.iterrows():
        d = r['disease_name']
        ac = int(r['known_drugs_available_in_cmap_count'])
        rc = int(r['cmap_in_known_count'])
        at = int(r['known_drugs_available_in_tahoe_count'])
        rt = int(r['tahoe_in_known_count'])
        flag = ""
        if rc > ac or rt > at:
            flag = " ← ISSUE"
            issues += 1
        print(f"  {d:<48s} Known={int(r['total_known_drugs_in_database_count']):>5d}  "
              f"CMAP={rc}/{ac} ({r['CMAP Recovery Rate']*100:.1f}%)  "
              f"TAHOE={rt}/{at} ({r['TAHOE Recovery Rate']*100:.1f}%){flag}")
    
    df.to_excel(XLSX_FILE, index=False)
    print(f"\n{'✓' if issues == 0 else '⚠'} Saved xlsx with {issues} issues remaining")
    print(f"  18 diseases: original values restored for non-merged, correct values for merged")


if __name__ == "__main__":
    main()
