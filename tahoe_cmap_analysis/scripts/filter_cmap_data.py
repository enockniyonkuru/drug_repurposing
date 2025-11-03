import os
import pandas as pd
import pyreadr
from tqdm import tqdm
try:
    from utils import normalize_drug_name
except ImportError:
    print("Error: Could not import 'normalize_drug_name' from 'utils.py'.")
    print("Please ensure 'utils.py' is in the same directory.")
    exit()



# ----------------------------
# 1) Paths
# ----------------------------
# Get the script directory and project root
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))

# Inputs (relative to project root)
PATH_CMAP_SIG = os.path.join(PROJECT_ROOT, "tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_signatures.RData")
PATH_CMAP_EXP = os.path.join(PROJECT_ROOT, "tahoe_cmap_analysis/data/drug_signatures/cmap/cmap_drug_experiments_new.csv")
PATH_SHARED_GENES = os.path.join(PROJECT_ROOT, "tahoe_cmap_analysis/reports/shared_genes_tahoe_cmap.csv")
PATH_SHARED_DRUGS = os.path.join(PROJECT_ROOT, "tahoe_cmap_analysis/reports/shared_drugs_tahoe_cmap.csv")

# Outputs
OUT_DIR_DATA = os.path.join(PROJECT_ROOT, "tahoe_cmap_analysis/data/drug_signatures/cmap")
OUT_DIR_REPORTS = os.path.join(PROJECT_ROOT, "tahoe_cmap_analysis/reports")

# RData outputs
OUT_PATH_GENES_FILTERED = os.path.join(OUT_DIR_DATA, "cmap_genes_filtered.RData")
OUT_PATH_GENES_DRUGS_FILTERED = os.path.join(OUT_DIR_DATA, "cmap_genes_drugs.RData")

# Report output
OUT_REPORT = os.path.join(OUT_DIR_REPORTS, "cmap_signature_versions_report.txt")

# --- Parquet output path REMOVED ---
# OUT_PARQUET = os.path.join(OUT_DIR_DATA, "cmap_shared_drugs_signatures.parquet")

os.makedirs(OUT_DIR_DATA, exist_ok=True)
os.makedirs(OUT_DIR_REPORTS, exist_ok=True)

print("Starting the filtering process...")
pbar = tqdm(total=10, desc="Initializing...")

# ----------------------------
# 2) Load shared experiment IDs
# ----------------------------
pbar.set_description("Step 1/10: Load shared drugs & experiments")
try:
    # Load the list of shared normalized drug names
    shared_drugs_df = pd.read_csv(PATH_SHARED_DRUGS)
    if "drug_norm" not in shared_drugs_df.columns:
        raise ValueError(f"'drug_norm' not found in {PATH_SHARED_DRUGS}")
    set_shared_drug_norms = set(shared_drugs_df['drug_norm'])
    
    # Load the CMap experiment manifest
    cmap_exp_manifest_df = pd.read_csv(PATH_CMAP_EXP)
    
    # Check for required columns in the manifest
    if "name" not in cmap_exp_manifest_df.columns or "id" not in cmap_exp_manifest_df.columns:
        raise ValueError(f"'name' or 'id' not found in {PATH_CMAP_EXP}. Found columns: {list(cmap_exp_manifest_df.columns)}")

    # Rename 'id' to 'cmap_experiment_id' for consistency
    cmap_exp_manifest_df = cmap_exp_manifest_df.rename(columns={'id': 'cmap_experiment_id'})
    
    # Normalize drug names in the manifest to find matches
    cmap_exp_manifest_df['drug_norm'] = normalize_drug_name(cmap_exp_manifest_df["name"])
    
    # Filter manifest for rows matching shared drugs
    mapping_df_full = cmap_exp_manifest_df[
        cmap_exp_manifest_df['drug_norm'].isin(set_shared_drug_norms)
    ].copy()
    
    # Prepare mapping_df for QC check and get shared IDs
    mapping_df = mapping_df_full[['cmap_experiment_id', 'drug_norm']].rename(
        columns={'drug_norm': 'normalized_drug_name'}
    )
    mapping_df = mapping_df.drop_duplicates()

    shared_cmap_ids = pd.to_numeric(mapping_df["cmap_experiment_id"], errors="coerce").dropna().astype(int)
    shared_cmap_ids = shared_cmap_ids.drop_duplicates().tolist()
    
    print(f"  - Loaded {len(set_shared_drug_norms)} shared drug names.")
    print(f"  - Mapped to {len(shared_cmap_ids)} unique CMap experiment IDs.")
except Exception as e:
    pbar.close()
    raise RuntimeError(f"ERROR loading experiment mapping: {e}")
pbar.update(1)

# ----------------------------
# 3) Prepare candidate column schemes
# ----------------------------
pbar.set_description("Step 2/10: Prepare column schemes")
columns_scheme_A = ['V1'] + [f"V{id_ + 1}" for id_ in shared_cmap_ids]  # common scheme
columns_scheme_B = ['V1'] + [f"V{id_}"     for id_ in shared_cmap_ids]  # fallback scheme
print("  - Prepared two candidate schemes: A = V{id+1}, B = V{id}")
pbar.update(1)

# ----------------------------
# 4) Load shared genes (Entrez IDs)
# ----------------------------
pbar.set_description("Step 3/10: Load shared genes")
try:
    shared_genes_df = pd.read_csv(PATH_SHARED_GENES)
    possible_gene_cols = {"entrezID", "entrez_id", "EntrezID"}
    col_found = next((c for c in possible_gene_cols if c in shared_genes_df.columns), None)
    if col_found is None:
        raise ValueError(f"Shared genes file missing an Entrez column. Need one of {possible_gene_cols}. "
                         f"Found: {list(shared_genes_df.columns)}")
    shared_entrez_ids = pd.to_numeric(shared_genes_df[col_found], errors="coerce").dropna().astype("Int64")
    shared_entrez_ids = set(shared_entrez_ids.tolist())
    print(f"  - Loaded {len(shared_entrez_ids)} shared Entrez IDs.")
except Exception as e:
    pbar.close()
    raise RuntimeError(f"ERROR loading shared genes: {e}")
pbar.update(1)

# ----------------------------
# 5) Load CMap signatures (RData)
# ----------------------------
pbar.set_description("Step 4/10: Load CMap signatures (RData)")
try:
    rdata_objects = pyreadr.read_r(PATH_CMAP_SIG)
    if not rdata_objects:
        raise ValueError("No objects found in RData file.")
    data_object_name = list(rdata_objects.keys())[0]
    cmap_signatures_df = rdata_objects[data_object_name]
    if 'V1' not in cmap_signatures_df.columns:
        raise ValueError("Column 'V1' not found in CMap signatures (gene ID column).")
    print(f"  - Loaded CMap signatures: shape={cmap_signatures_df.shape}, "
          f"V1 dtype={cmap_signatures_df['V1'].dtype}")
except Exception as e:
    pbar.close()
    raise RuntimeError(f"ERROR loading CMap signatures: {e}")
pbar.update(1)

# ----------------------------
# 6) Normalize dtypes & filter by genes
# ----------------------------
pbar.set_description("Step 5/10: Normalize & filter by genes")

# Coerce V1 to nullable Int64 to match shared_entrez_ids dtype
v1_as_int = pd.to_numeric(cmap_signatures_df['V1'], errors="coerce").astype("Int64")
cmap_signatures_df = cmap_signatures_df.assign(V1=v1_as_int)

before_rows = cmap_signatures_df.shape[0]
cmap_genes_filtered_df = cmap_signatures_df[cmap_signatures_df['V1'].isin(shared_entrez_ids)].copy()
print(f"  - Gene filter: rows before={before_rows}, after={cmap_genes_filtered_df.shape[0]}")

# --- Handle duplicate V* column names by collapsing them via mean ---
dup_mask = pd.Series(cmap_genes_filtered_df.columns).duplicated(keep=False)
if dup_mask.any():
    num_dup_cols = int(dup_mask.sum())
    num_dup_names = int(pd.Series(cmap_genes_filtered_df.columns)[dup_mask].nunique())
    print(f"WARNING: Detected {num_dup_cols} columns across {num_dup_names} duplicate V-names. "
          f"Collapsing duplicates by mean.")
    cmap_genes_filtered_df = cmap_genes_filtered_df.T.groupby(level=0).mean().T

pbar.update(1)

# ----------------------------
# 7) Save gene-filtered RData
# ----------------------------
pbar.set_description(f"Step 6/10: Save gene-filtered RData")
try:
    pyreadr.write_rdata(OUT_PATH_GENES_FILTERED, cmap_genes_filtered_df, df_name="cmap_genes_filtered")
    print(f"  - Saved gene-filtered RData: {OUT_PATH_GENES_FILTERED} (shape={cmap_genes_filtered_df.shape})")
except Exception as e:
    print(f"  - WARNING: Could not save {OUT_PATH_GENES_FILTERED}. Error: {e}")
pbar.update(1)


# ----------------------------
# 8) Select experiment columns (robust scheme) & sanity check V1
# ----------------------------
pbar.set_description("Step 7/10: Select drug/experiment columns")

# Decide which column scheme fits best
existing_A = [c for c in columns_scheme_A if c in cmap_genes_filtered_df.columns]
existing_B = [c for c in columns_scheme_B if c in cmap_genes_filtered_df.columns]
chosen = 'A' if len(existing_A) >= len(existing_B) else 'B'
print(f"  - Column scheme chosen: {chosen} "
      f"(matched {len(existing_A)} vs {len(existing_B)} columns)")

# Preserve mapping order (after 'V1')
if chosen == 'A':
    ordered_exps = [f"V{id_ + 1}" for id_ in shared_cmap_ids if f"V{id_ + 1}" in cmap_genes_filtered_df.columns]
else:
    ordered_exps = [f"V{id_}" for id_ in shared_cmap_ids if f"V{id_}" in cmap_genes_filtered_df.columns]

# Ensure uniqueness while preserving order
seen = set()
ordered_exps_unique = []
for c in ordered_exps:
    if c not in seen:
        seen.add(c)
        ordered_exps_unique.append(c)

columns_ordered = ['V1'] + ordered_exps_unique
if len(columns_ordered) <= 1:
    print("WARNING: No experiment columns matched. Check mapping vs CMap column scheme.")

cmap_subset_df = cmap_genes_filtered_df.loc[:, columns_ordered].copy()

# Final guard: if duplicates still somehow present, collapse again
if not pd.Index(cmap_subset_df.columns).is_unique:
    print("WARNING: Duplicate columns still present. Collapsing again by mean.")
    cmap_subset_df = cmap_subset_df.T.groupby(level=0).mean().T

# --- Sanity check: output V1 ⊆ shared genes ---
final_v1_series = pd.to_numeric(cmap_subset_df['V1'], errors="coerce").astype("Int64").dropna()
final_ids = set(final_v1_series.tolist())
extra_in_output = final_ids - shared_entrez_ids             # Should be empty
missing_from_output = shared_entrez_ids - final_ids         # Informational

if extra_in_output:
    example = sorted(list(extra_in_output))[:10]
    raise ValueError(f"Sanity check FAILED: {len(extra_in_output)} gene IDs in final output "
                     f"are NOT in the shared genes CSV. Examples: {example}")

print("  - Sanity check PASSED: all output gene IDs are in the shared genes list.")
if missing_from_output:
    print(f"  - NOTE: {len(missing_from_output)} shared gene IDs not in final output "
          f"(e.g., absent from CMap).")
print(f"  - Final V1 count={len(final_ids)} | Shared genes count={len(shared_entrez_ids)}")

pbar.update(1)

# ----------------------------
# 9) Save to RData (UPDATED)
# ----------------------------
pbar.set_description("Step 8/10: Save final RData")
try:
    # Double-check uniqueness before writing
    if not pd.Index(cmap_subset_df.columns).is_unique:
        raise ValueError("Duplicate column names remain; RData requires unique column names.")
    
    # --- Parquet save REMOVED ---
    # cmap_subset_df.to_parquet(OUT_PARQUET, index=False)
    # print(f"  - Saved Parquet: {OUT_PARQUET} (shape={cmap_subset_df.shape})")
    
    # Save final RData
    pyreadr.write_rdata(OUT_PATH_GENES_DRUGS_FILTERED, cmap_subset_df, df_name="cmap_genes_drugs")
    print(f"  - Saved final RData: {OUT_PATH_GENES_DRUGS_FILTERED} (shape={cmap_subset_df.shape})")
    
except Exception as e:
    pbar.close()
    raise RuntimeError(f"ERROR saving output file: {e}")
pbar.update(1)

# ----------------------------
# 10) Quality Control Checks
# ----------------------------
pbar.set_description("Step 9/10: Quality Control Checks")

print("\n" + "="*70)
print("QUALITY CONTROL CHECKS")
print("="*70)

# Expected values
EXPECTED_DRUGS = len(set_shared_drug_norms)
EXPECTED_GENES = len(shared_entrez_ids)

qc_passed = True

# QC 1: Check gene count
n_genes_output = len(cmap_subset_df)
print(f"\n1. Gene Count Check:")
print(f"   - Expected: {EXPECTED_GENES} (from {PATH_SHARED_GENES})")
print(f"   - Actual:   {n_genes_output}")
if n_genes_output == EXPECTED_GENES:
    print(f"   ✓ PASSED")
else:
    print(f"   ❌ FAILED (Difference: {n_genes_output - EXPECTED_GENES})")
    qc_passed = False

# QC 2: Check drug count (OPTIMIZED - uses already-determined scheme)
experiment_cols = [col for col in cmap_subset_df.columns if col != 'V1']
cmap_exp_ids_in_output = []
for col in experiment_cols:
    try:
        if isinstance(col, str) and col.startswith('V'):
            col_num = int(col[1:])
            # Use the scheme that was already chosen
            if chosen == 'A':
                exp_id = col_num - 1  # V{id+1} -> id
            else:
                exp_id = col_num      # V{id} -> id
            cmap_exp_ids_in_output.append(exp_id)
        else:
            cmap_exp_ids_in_output.append(int(col))
    except (ValueError, TypeError):
        pass

cmap_drugs = mapping_df[mapping_df['cmap_experiment_id'].isin(cmap_exp_ids_in_output)]
n_unique_drugs = cmap_drugs['normalized_drug_name'].nunique()

print(f"\n2. Drug Count Check:")
print(f"   - Expected: {EXPECTED_DRUGS} (from {PATH_SHARED_DRUGS})")
print(f"   - Actual:   {n_unique_drugs}")
if n_unique_drugs == EXPECTED_DRUGS:
    print(f"   ✓ PASSED")
else:
    print(f"   ❌ FAILED (Difference: {n_unique_drugs - EXPECTED_DRUGS})")
    qc_passed = False
    
    # Show which drugs are present/missing
    all_drugs = set_shared_drug_norms
    found_drugs = set(cmap_drugs['normalized_drug_name'].unique())
    missing_drugs = sorted(all_drugs - found_drugs)
    
    if missing_drugs:
        print(f"\n   Missing drugs ({len(missing_drugs)}):")
        for i, drug in enumerate(missing_drugs[:20], 1):  # Show first 20
            print(f"      {i:2d}. {drug}")
        if len(missing_drugs) > 20:
            print(f"      ... and {len(missing_drugs) - 20} more")

# QC 3: Check experiment count
n_experiments = len(experiment_cols)
n_expected_experiments = len(shared_cmap_ids)
print(f"\n3. Experiment Count Check:")
print(f"   - Expected: {n_expected_experiments} (from mapping)")
print(f"   - Actual:   {n_experiments}")
if n_experiments == n_expected_experiments:
    print(f"   ✓ PASSED")
else:
    print(f"   ⚠ WARNING (Difference: {n_experiments - n_expected_experiments})")

# QC 4: Check for duplicate columns
print(f"\n4. Duplicate Column Check:")
if pd.Index(cmap_subset_df.columns).is_unique:
    print(f"   ✓ PASSED - All columns are unique")
else:
    print(f"   ❌ FAILED - Duplicate columns detected")
    qc_passed = False

# QC 5: Check for missing values
n_missing = cmap_subset_df.isnull().sum().sum()
print(f"\n5. Missing Values Check:")
print(f"   - Total missing values: {n_missing}")
if n_missing == 0:
    print(f"   ✓ PASSED - No missing values")
else:
    pct_missing = (n_missing / (cmap_subset_df.shape[0] * cmap_subset_df.shape[1])) * 100
    print(f"   ⚠ WARNING - {pct_missing:.2f}% of values are missing")

print("\n" + "="*70)
if qc_passed:
    print("✓ ALL CRITICAL QC CHECKS PASSED")
else:
    print("❌ SOME CRITICAL QC CHECKS FAILED")
    print("\nPlease review the issues above before proceeding.")
print("="*70)

pbar.update(1)

# ----------------------------
# 11) Generate Report
# ----------------------------
pbar.set_description("Step 10/10: Generate summary report")

try:
    # Get shape (rows, cols) and correct for gene column 'V1'
    shape_orig = cmap_signatures_df.shape
    shape_genes = cmap_genes_filtered_df.shape
    shape_final = cmap_subset_df.shape

    report_lines = [
        "===============================================",
        "  CMap Drug Signature Versions Report",
        "===============================================",
        "\nThis report summarizes the dimensions (genes, signatures) of the three",
        "generated CMap .RData files.",
        "\n",
        "--- 1. Original Signatures ---",
        f"File:     {os.path.basename(PATH_CMAP_SIG)}",
        f"Genes:    {shape_orig[0]:,}",
        f"Sigs:     {shape_orig[1] - 1:,} (Total columns - 1 for gene ID)",
        f"Shape:    {shape_orig}",
        "\n",
        "--- 2. Gene-Filtered Signatures ---",
        f"File:     {os.path.basename(OUT_PATH_GENES_FILTERED)}",
        "Filter:   Filtered to include ONLY genes shared with Tahoe.",
        f"Genes:    {shape_genes[0]:,}",
        f"Sigs:     {shape_genes[1] - 1:,} (Total columns - 1 for gene ID)",
        f"Shape:    {shape_genes}",
        "\n",
        "--- 3. Gene- and Drug-Filtered Signatures ---",
        f"File:     {os.path.basename(OUT_PATH_GENES_DRUGS_FILTERED)}",
        "Filter:   Filtered by shared genes AND shared drugs.",
        f"Genes:    {shape_final[0]:,}",
        f"Sigs:     {shape_final[1] - 1:,} (Total columns - 1 for gene ID)",
        f"Shape:    {shape_final}",
    ]
    
    with open(OUT_REPORT, 'w') as f:
        f.write("\n".join(report_lines))
    
    print(f"\nSuccessfully generated report: {OUT_REPORT}")
    
except Exception as e:
    print(f"\nERROR: Could not generate summary report: {e}")

pbar.update(1)
pbar.close()
print("\nProcess finished.")
