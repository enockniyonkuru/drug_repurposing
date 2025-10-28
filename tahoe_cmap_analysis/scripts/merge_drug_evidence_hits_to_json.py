import pandas as pd
import json
import os

# -----------------------------
# 1. File paths
# -----------------------------

# All drugs
PATH_EVIDENCE = "/Users/enockniyonkuru/Desktop/tahoe_analysis/data/drug_evidence/open_targets_by_disease.csv"
PATH_HITS = "/Users/enockniyonkuru/Desktop/drug_repurposing/results/all_drug_hits_compiled.csv"
OUTPUT_JSON = "/Users/enockniyonkuru/Desktop/drug_repurposing/results/drug_disease_combined.json"


# Shared drugs only
# PATH_EVIDENCE = "/Users/enockniyonkuru/Desktop/tahoe_analysis/data/drug_evidence/filtered_open_targets_by_disease.csv"
# PATH_HITS = "/Users/enockniyonkuru/Desktop/drug_repurposing/results/all_drug_hits_compiled_shared_only.csv"
# OUTPUT_JSON = "/Users/enockniyonkuru/Desktop/drug_repurposing/results/drug_disease_combined_shared.json"



# -----------------------------
# 2. Load datasets
# -----------------------------
df_evidence = pd.read_csv(PATH_EVIDENCE)
df_hits = pd.read_csv(PATH_HITS)

# Normalize case and trim spaces for matching
df_evidence["label_clean"] = df_evidence["label_clean"].astype(str).str.strip().str.lower()
df_hits["name"] = df_hits["name"].astype(str).str.strip().str.lower()
df_hits["disease"] = df_hits["disease"].astype(str).str.strip()

# -----------------------------
# 3. Initialize JSON structure
# -----------------------------
result = {}

# -----------------------------
# 4. Loop through each row in hits file
# -----------------------------
for _, hit_row in df_hits.iterrows():
    disease = hit_row["disease"]
    sig_type = hit_row["signature_type"]
    drug_name = hit_row["name"]

    # Try to match with evidence
    evidence_rows = df_evidence[df_evidence["label_clean"] == drug_name]

    if evidence_rows.empty:
        # Try matching using `label` or `prefName` if not found
        evidence_rows = df_evidence[
            (df_evidence["label"].str.lower() == drug_name)
            | (df_evidence["prefName"].str.lower() == drug_name)
        ]

    # Prepare nested structure
    if disease not in result:
        result[disease] = {}
    if sig_type not in result[disease]:
        result[disease][sig_type] = {}

    # Build Drug Info from first match (if available)
    if not evidence_rows.empty:
        ev = evidence_rows.iloc[0]
        drug_info = {
            "phase": ev.get("phase", ""),
            "status": ev.get("status", ""),
            "urls": ev.get("urls", ""),
            "label_clean": ev.get("label_clean", ""),
            "prefName": ev.get("prefName", ""),
            "targetName": ev.get("targetName", ""),
            "mechanismOfAction": ev.get("mechanismOfAction", ""),
            "drugType": ev.get("drugType", ""),
        }
    else:
        drug_info = {}

    # Experiment info
    exp_info = {
        "exp_id": hit_row.get("exp_id", ""),
        "cmap_score": hit_row.get("cmap_score", ""),
        "p": hit_row.get("p", ""),
        "q": hit_row.get("q", ""),
        "subset_comparison_id": hit_row.get("subset_comparison_id", ""),
        "name": hit_row.get("name", ""),
        "concentration": hit_row.get("concentration", ""),
        "duration": hit_row.get("duration", ""),
        "cell_line": hit_row.get("cell_line", ""),
        "array_platform": hit_row.get("array_platform", "")
    }

    # Combine
    result[disease][sig_type][drug_name] = {
        "DrugInfo": drug_info,
        "ExperimentInfo": exp_info
    }

# -----------------------------
# 5. Save JSON
# -----------------------------
os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
with open(OUTPUT_JSON, "w") as f:
    json.dump(result, f, indent=4)

print(f"✅ JSON file created successfully at: {OUTPUT_JSON}")
