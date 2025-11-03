

"""
generate_drug_hits_evidence_summaries.py

This script merges drug repurposing hits (CMap and Tahoe) with Open Targets
evidence and generates summary statistics and annotated outputs.

It runs two analyses:
1. Full dataset (all drug hits)
2. Shared-only dataset (common genes/drugs subset)

Outputs:
- Annotated merged CSVs
- Summary counts by disease
- Summary drug sets by disease
- Summaries with total rows

"""

import pandas as pd
import os

# =========================================================
# Helper functions
# =========================================================
def clean_name(series):
    """Convert names to lowercase stripped strings, handle NaNs."""
    return series.astype(str).str.strip().str.lower()

def generate_summary(df, evidence_df):
    """Generate numeric summary counts comparing hits vs evidence."""
    summary = []
    valid_evidence_set = set(evidence_df["prefName_clean"])
    for disease in df["disease"].dropna().unique():
        sub_df = df[df["disease"] == disease]
        cmap_drugs = set(sub_df[(sub_df["signature_type"] == "CMAP")]["name_clean"].dropna())
        tahoe_drugs = set(sub_df[(sub_df["signature_type"] == "TAHOE")]["name_clean"].dropna())
        common_drugs = cmap_drugs & tahoe_drugs

        cmap_evidence = cmap_drugs & valid_evidence_set
        tahoe_evidence = tahoe_drugs & valid_evidence_set
        common_evidence = common_drugs & valid_evidence_set

        summary.append({
            "disease": disease,
            "CMAP_total": len(cmap_drugs),
            "TAHOE_total": len(tahoe_drugs),
            "common_CMAP_TAHOE": len(common_drugs),
            "CMAP_in_evidence": len(cmap_evidence),
            "TAHOE_in_evidence": len(tahoe_evidence),
            "common_in_evidence": len(common_evidence),
            "CMAP_novel": len(cmap_drugs - cmap_evidence),
            "TAHOE_novel": len(tahoe_drugs - tahoe_evidence),
            "common_novel": len(common_drugs - common_evidence),
        })
    return pd.DataFrame(summary)

def generate_drug_set_summary(df, evidence_df):
    """Generate detailed lists of drugs for each disease."""
    summary = []
    valid_evidence_set = set(evidence_df["prefName_clean"])
    for disease in df["disease"].dropna().unique():
        sub_df = df[df["disease"] == disease]
        cmap_drugs = set(sub_df[(sub_df["signature_type"] == "CMAP")]["name_clean"].dropna())
        tahoe_drugs = set(sub_df[(sub_df["signature_type"] == "TAHOE")]["name_clean"].dropna())
        common_drugs = cmap_drugs & tahoe_drugs

        cmap_evidence = cmap_drugs & valid_evidence_set
        tahoe_evidence = tahoe_drugs & valid_evidence_set
        common_evidence = common_drugs & valid_evidence_set

        summary.append({
            "disease": disease,
            "CMAP_drugs": sorted(cmap_drugs),
            "TAHOE_drugs": sorted(tahoe_drugs),
            "common_CMAP_TAHOE": sorted(common_drugs),
            "CMAP_in_evidence": sorted(cmap_evidence),
            "TAHOE_in_evidence": sorted(tahoe_evidence),
            "common_in_evidence": sorted(common_evidence),
            "CMAP_novel": sorted(cmap_drugs - cmap_evidence),
            "TAHOE_novel": sorted(tahoe_drugs - tahoe_evidence),
            "common_novel": sorted(common_drugs - common_evidence),
        })
    return pd.DataFrame(summary)

def process_dataset(hits_path, evidence_path, output_prefix):
    """Run merge + summary generation for a given dataset."""
    print(f"🔹 Processing dataset:\n  Hits: {hits_path}\n  Evidence: {evidence_path}\n")

    hits_df = pd.read_csv(hits_path)
    evidence_df = pd.read_csv(evidence_path)

    # Clean names
    hits_df["name_clean"] = clean_name(hits_df["name"])
    evidence_df["prefName_clean"] = clean_name(evidence_df["prefName"])

    # Remove blanks
    hits_df = hits_df[~hits_df["name_clean"].isin(["", "nan"])]

    # Merge with evidence
    merged_df = pd.merge(hits_df, evidence_df, how="left", left_on="name_clean", right_on="prefName_clean")
    annotated_output_path = f"../results/{output_prefix}_annotated_hits_with_open_targets.csv"
    merged_df.to_csv(annotated_output_path, index=False)
    print(f"✅ Annotated merged file saved: {annotated_output_path}")

    # Summary 1: numeric counts
    summary_df = generate_summary(hits_df, evidence_df)
    summary_count_path = f"../results/{output_prefix}_summary_hits_vs_evidence_by_disease.csv"
    summary_df.to_csv(summary_count_path, index=False)
    print(f"✅ Summary counts saved: {summary_count_path}")

    # Summary 2: drug sets
    drug_set_df = generate_drug_set_summary(hits_df, evidence_df)
    summary_set_path = f"../results/{output_prefix}_summary_drug_sets_by_disease.csv"
    drug_set_df.to_csv(summary_set_path, index=False)
    print(f"✅ Summary drug sets saved: {summary_set_path}")

    # Add total row
    total_summary_row = summary_df.drop(columns=["disease"]).sum(numeric_only=True)
    total_summary_row.name = "TOTAL"
    total_summary_df = pd.concat([summary_df.set_index("disease"), total_summary_row.to_frame().T])
    total_summary_path = f"../results/{output_prefix}_summary_with_total_row.csv"
    total_summary_df.to_csv(total_summary_path)
    print(f"✅ Total summary with totals saved: {total_summary_path}\n")


# =========================================================
# Run for both datasets
# =========================================================
if __name__ == "__main__":
    os.makedirs("../results", exist_ok=True)

    # --- 1) Full dataset ---
    process_dataset(
        hits_path="/Users/enockniyonkuru/Desktop/drug_repurposing/results/all_drug_hits_compiled.csv",
        evidence_path="/Users/enockniyonkuru/Desktop/tahoe_analysis/data/drug_evidence/open_targets_by_disease.csv",
        output_prefix="full"
    )

    # --- 2) Shared-only dataset ---
    process_dataset(
        hits_path="/Users/enockniyonkuru/Desktop/drug_repurposing/results/all_drug_hits_compiled_shared_only.csv",
        evidence_path="/Users/enockniyonkuru/Desktop/tahoe_analysis/data/drug_evidence/filtered_open_targets_by_disease.csv",
        output_prefix="shared"
    )

    print("🎯 All analyses completed successfully.")


