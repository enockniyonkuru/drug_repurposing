#!/usr/bin/env python3
"""
Fix known drug counts for all diseases in the xlsx to be consistent.
Uses the same method as the merge script: unique drug_common_name from Open Targets.
Also updates Available counts (known ∩ platform library).
Recovered and Hits counts remain unchanged.
"""

import pandas as pd
import pyarrow.parquet as pq
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

BASE_DIR = Path(__file__).resolve().parents[3]
OT_FILE = BASE_DIR / "drug_evidence" / "data" / "open_targets" / "known_drug_info_data.parquet"
XLSX_FILE = BASE_DIR / "autoimmune" / "analysis" / "recovery_summary" / "20_autoimmune.xlsx"
CMAP_DRUGS = BASE_DIR / "drug_signatures" / "data" / "cmap" / "cmap_drug_experiments_new.csv"
TAHOE_DRUGS = BASE_DIR / "drug_signatures" / "data" / "tahoe" / "tahoe_drug_experiments_new.csv"

# Disease name → Open Targets search terms (same as show_drug_details.py)
DISEASE_NAME_MAP = {
    "inclusion body myositis": ["inclusion body myositis"],
    "discoid lupus erythematosus": ["discoid lupus"],
    "psoriatic arthritis": ["psoriatic arthritis"],
    "dermatomyositis": ["dermatomyositis"],
    "sjogren's syndrome": ["Sjogren", "Sjögren"],
    "autoimmune thrombocytopenic purpura": ["thrombocytopenic purpura", "ITP"],
    "scleroderma": ["scleroderma", "systemic sclerosis"],
    "psoriasis": ["psoriasis"],
    "inflammatory bowel disease": ["inflammatory bowel disease", "IBD"],
    "ankylosing spondylitis": ["ankylosing spondylitis"],
    "crohn's disease": ["Crohn"],
    "relapsing-remitting multiple sclerosis": ["multiple sclerosis"],
    "rheumatoid arthritis": ["rheumatoid arthritis"],
    "systemic lupus erythematosus": ["systemic lupus erythematosus", "lupus erythematosus"],
    "ulcerative colitis": ["ulcerative colitis"],
    "multiple sclerosis": ["multiple sclerosis"],
    "type 1 diabetes mellitus": ["type 1 diabetes", "diabetes mellitus type 1", "insulin-dependent diabetes"],
    "juvenile idiopathic arthritis (sjia)": ["systemic juvenile idiopathic arthritis", "juvenile idiopathic arthritis"],
}


def main():
    ot_df = pq.read_table(OT_FILE).to_pandas()
    cmap_lib = set(pd.read_csv(CMAP_DRUGS)['name'].str.lower().unique())
    tahoe_lib = set(pd.read_csv(TAHOE_DRUGS)['name'].str.lower().unique())
    xlsx_df = pd.read_excel(XLSX_FILE)

    print(f"{'Disease':<50s} {'Old Known':>10s} {'New Known':>10s} {'Old Av.C':>8s} {'New Av.C':>8s} {'Old Av.T':>8s} {'New Av.T':>8s}")
    print("-" * 106)

    for idx, row in xlsx_df.iterrows():
        disease = row['disease_name'].lower()
        search_terms = DISEASE_NAME_MAP.get(disease)
        if search_terms is None:
            print(f"  WARNING: No mapping for '{row['disease_name']}' - skipping")
            continue

        # Compute known drugs
        mask = pd.Series([False] * len(ot_df))
        for term in search_terms:
            mask |= ot_df['drug_disease_label'].str.contains(term, case=False, na=False)
        known = set(ot_df[mask]['drug_common_name'].str.lower().unique())

        # Available in libraries
        avail_cmap = len(known & cmap_lib)
        avail_tahoe = len(known & tahoe_lib)

        old_known = int(row['total_known_drugs_in_database_count'])
        old_ac = int(row['known_drugs_available_in_cmap_count'])
        old_at = int(row['known_drugs_available_in_tahoe_count'])

        print(f"  {row['disease_name']:<48s} {old_known:>10d} {len(known):>10d} {old_ac:>8d} {avail_cmap:>8d} {old_at:>8d} {avail_tahoe:>8d}")

        # Update
        xlsx_df.at[idx, 'total_known_drugs_in_database_count'] = len(known)
        xlsx_df.at[idx, 'known_drugs_available_in_cmap_count'] = avail_cmap
        xlsx_df.at[idx, 'known_drugs_available_in_tahoe_count'] = avail_tahoe

        # Recompute recovery rates
        rec_cmap = int(row['cmap_in_known_count'])
        rec_tahoe = int(row['tahoe_in_known_count'])
        xlsx_df.at[idx, 'CMAP Recovery Rate'] = rec_cmap / avail_cmap if avail_cmap > 0 else 0
        xlsx_df.at[idx, 'TAHOE Recovery Rate'] = rec_tahoe / avail_tahoe if avail_tahoe > 0 else 0

        total_rec = int(row['total_in_known_count'])
        total_unique = int(row['total_unique_drugs_cmap_tahoe'])
        xlsx_df.at[idx, 'Overall Recovery Rate'] = total_rec / total_unique if total_unique > 0 else 0

    xlsx_df.to_excel(XLSX_FILE, index=False)
    print(f"\nSaved updated xlsx with consistent known drug counts.")


if __name__ == "__main__":
    main()
