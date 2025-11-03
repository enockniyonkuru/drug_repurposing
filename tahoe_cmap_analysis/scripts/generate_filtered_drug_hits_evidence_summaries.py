"""
generate_filtered_drug_hits_evidence_summaries.py

This script creates filtered drug repurposing hit summaries based on q-value thresholds
and incorporates clinical trial phase and status information from Open Targets evidence.

Key features:
1. Filters hits by q-value thresholds (q < 0.05 and q < 0.10)
2. Processes both full and shared-only datasets
3. Includes clinical trial phase and status in summaries
4. Generates detailed evidence annotations

Outputs for each q-value threshold and dataset combination:
- Annotated merged CSVs with phase/status info
- Summary counts by disease
- Summary drug sets by disease with phase/status details
- Summaries with total rows

"""

import pandas as pd
import os
from collections import defaultdict

# =========================================================
# Helper functions
# =========================================================
def clean_name(series):
    """Convert names to lowercase stripped strings, handle NaNs."""
    return series.astype(str).str.strip().str.lower()

def aggregate_phase_status(evidence_df, drug_name):
    """
    Get all phases and statuses for a given drug from evidence.
    Returns a dict with phase and status lists.
    """
    drug_evidence = evidence_df[evidence_df["prefName_clean"] == drug_name]
    if drug_evidence.empty:
        return {"phases": [], "statuses": []}
    
    phases = drug_evidence["phase"].dropna().unique().tolist()
    statuses = drug_evidence["status"].dropna().unique().tolist()
    
    return {
        "phases": sorted([str(p) for p in phases]),
        "statuses": sorted([str(s) for s in statuses])
    }

def generate_summary_with_phase_status(df, evidence_df):
    """Generate numeric summary counts comparing hits vs evidence with phase/status info."""
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

        # Aggregate phase/status info for drugs in evidence
        cmap_phase_info = defaultdict(int)
        tahoe_phase_info = defaultdict(int)
        common_phase_info = defaultdict(int)
        
        for drug in cmap_evidence:
            info = aggregate_phase_status(evidence_df, drug)
            for phase in info["phases"]:
                cmap_phase_info[phase] += 1
        
        for drug in tahoe_evidence:
            info = aggregate_phase_status(evidence_df, drug)
            for phase in info["phases"]:
                tahoe_phase_info[phase] += 1
        
        for drug in common_evidence:
            info = aggregate_phase_status(evidence_df, drug)
            for phase in info["phases"]:
                common_phase_info[phase] += 1

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
            "CMAP_phase_distribution": dict(cmap_phase_info),
            "TAHOE_phase_distribution": dict(tahoe_phase_info),
            "common_phase_distribution": dict(common_phase_info),
        })
    return pd.DataFrame(summary)

def generate_drug_set_summary_with_phase_status(df, evidence_df):
    """Generate detailed lists of drugs for each disease with phase/status information."""
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

        # Create detailed drug info with phase/status
        def get_drug_details(drug_set):
            details = []
            for drug in sorted(drug_set):
                info = aggregate_phase_status(evidence_df, drug)
                if info["phases"] or info["statuses"]:
                    details.append({
                        "drug": drug,
                        "phases": "; ".join(info["phases"]) if info["phases"] else "N/A",
                        "statuses": "; ".join(info["statuses"]) if info["statuses"] else "N/A"
                    })
                else:
                    details.append({
                        "drug": drug,
                        "phases": "N/A",
                        "statuses": "N/A"
                    })
            return details

        summary.append({
            "disease": disease,
            "CMAP_drugs": sorted(cmap_drugs),
            "TAHOE_drugs": sorted(tahoe_drugs),
            "common_CMAP_TAHOE": sorted(common_drugs),
            "CMAP_in_evidence": get_drug_details(cmap_evidence),
            "TAHOE_in_evidence": get_drug_details(tahoe_evidence),
            "common_in_evidence": get_drug_details(common_evidence),
            "CMAP_novel": sorted(cmap_drugs - cmap_evidence),
            "TAHOE_novel": sorted(tahoe_drugs - tahoe_evidence),
            "common_novel": sorted(common_drugs - common_evidence),
        })
    return pd.DataFrame(summary)

def process_filtered_dataset(hits_path, evidence_path, output_prefix, q_threshold):
    """
    Run merge + summary generation for a given dataset with q-value filtering.
    
    Args:
        hits_path: Path to drug hits CSV
        evidence_path: Path to Open Targets evidence CSV
        output_prefix: Prefix for output files
        q_threshold: Q-value threshold for filtering (e.g., 0.05, 0.10)
    """
    print(f"🔹 Processing dataset with q < {q_threshold}:")
    print(f"  Hits: {hits_path}")
    print(f"  Evidence: {evidence_path}\n")

    # Load data
    hits_df = pd.read_csv(hits_path)
    evidence_df = pd.read_csv(evidence_path)

    # Filter by q-value threshold
    initial_count = len(hits_df)
    hits_df = hits_df[hits_df["q"] < q_threshold]
    filtered_count = len(hits_df)
    print(f"  Filtered from {initial_count} to {filtered_count} hits (q < {q_threshold})")

    if hits_df.empty:
        print(f"  ⚠️  No hits remaining after filtering with q < {q_threshold}. Skipping.\n")
        return

    # Clean names
    hits_df["name_clean"] = clean_name(hits_df["name"])
    evidence_df["prefName_clean"] = clean_name(evidence_df["prefName"])

    # Remove blanks
    hits_df = hits_df[~hits_df["name_clean"].isin(["", "nan"])]

    # Merge with evidence
    merged_df = pd.merge(hits_df, evidence_df, how="left", left_on="name_clean", right_on="prefName_clean")
    
    # Create output directory
    q_str = str(q_threshold).replace(".", "p")
    output_dir = f"../results/filtered_q{q_str}"
    os.makedirs(output_dir, exist_ok=True)
    
    annotated_output_path = f"{output_dir}/{output_prefix}_annotated_hits_with_open_targets.csv"
    merged_df.to_csv(annotated_output_path, index=False)
    print(f"✅ Annotated merged file saved: {annotated_output_path}")

    # Summary 1: numeric counts with phase distribution
    summary_df = generate_summary_with_phase_status(hits_df, evidence_df)
    summary_count_path = f"{output_dir}/{output_prefix}_summary_hits_vs_evidence_by_disease.csv"
    summary_df.to_csv(summary_count_path, index=False)
    print(f"✅ Summary counts saved: {summary_count_path}")

    # Summary 2: drug sets with phase/status details
    drug_set_df = generate_drug_set_summary_with_phase_status(hits_df, evidence_df)
    summary_set_path = f"{output_dir}/{output_prefix}_summary_drug_sets_by_disease.csv"
    drug_set_df.to_csv(summary_set_path, index=False)
    print(f"✅ Summary drug sets saved: {summary_set_path}")

    # Add total row
    numeric_cols = ["CMAP_total", "TAHOE_total", "common_CMAP_TAHOE", 
                    "CMAP_in_evidence", "TAHOE_in_evidence", "common_in_evidence",
                    "CMAP_novel", "TAHOE_novel", "common_novel"]
    total_summary_row = summary_df[numeric_cols].sum()
    total_summary_row.name = "TOTAL"
    total_summary_df = pd.concat([summary_df.set_index("disease")[numeric_cols], 
                                   total_summary_row.to_frame().T])
    total_summary_path = f"{output_dir}/{output_prefix}_summary_with_total_row.csv"
    total_summary_df.to_csv(total_summary_path)
    print(f"✅ Total summary with totals saved: {total_summary_path}\n")


# =========================================================
# Run for all combinations
# =========================================================
if __name__ == "__main__":
    # Define q-value thresholds
    q_thresholds = [0.05, 0.10, 0.5]
    
    # Define dataset configurations
    datasets = [
        {
            "name": "full",
            "hits_path": "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/all_drug_hits_compiled.csv",
            "evidence_path": "/Users/enockniyonkuru/Desktop/tahoe_analysis/data/drug_evidence/open_targets_by_disease.csv"
        },
        {
            "name": "shared",
            "hits_path": "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/all_drug_hits_compiled_shared_only.csv",
            "evidence_path": "/Users/enockniyonkuru/Desktop/tahoe_analysis/data/drug_evidence/filtered_open_targets_by_disease.csv"
        }
    ]
    
    print("=" * 70)
    print("FILTERED DRUG HITS EVIDENCE SUMMARY GENERATION")
    print("=" * 70)
    print()
    
    # Process each combination of dataset and q-threshold
    for dataset in datasets:
        for q_threshold in q_thresholds:
            process_filtered_dataset(
                hits_path=dataset["hits_path"],
                evidence_path=dataset["evidence_path"],
                output_prefix=dataset["name"],
                q_threshold=q_threshold
            )
    
    print("=" * 70)
    print("🎯 All filtered analyses completed successfully.")
    print("=" * 70)
    print("\nOutput directories created:")
    print("  - ../results/filtered_q0p05/  (q < 0.05)")
    print("  - ../results/filtered_q0p1/   (q < 0.10)")
    print("  - ../results/filtered_q0p5/   (q < 0.50)")
