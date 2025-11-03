import pandas as pd
import os
import sys

# =========================================================
# 0) Paths
# =========================================================
PATH_CMAP_DATA   = "../data/Processed/drug_rep_cmap_ranks_shared_genes_drugs.parquet"
PATH_TAHOE_DATA  = "../data/Processed/drug_rep_tahoe_ranks_shared_genes_drugs.parquet"  # (genes x experiments)
PATH_SHARED_GENES = "../data/Comparison/shared_genes_tahoe_cmap_improved.csv"

print("--- Data Validation Script ---")
print(f"CMap file:   {os.path.basename(PATH_CMAP_DATA)}")
print(f"Tahoe file:  {os.path.basename(PATH_TAHOE_DATA)}")
print(f"Shared file: {os.path.basename(PATH_SHARED_GENES)}")

# =========================================================
# Helpers
# =========================================================
def load_parquet(path):
    try:
        return pd.read_parquet(path)
    except FileNotFoundError as e:
        print(f"\nERROR: File not found: {path}\nDetails: {e}")
        sys.exit(1)

def coerce_v1_to_int64(df, label):
    if "V1" not in df.columns:
        print(f"ERROR: '{label}' is missing 'V1' column.")
        sys.exit(1)
    v1 = pd.to_numeric(df["V1"], errors="coerce").astype("Int64")
    df = df.copy()
    df["V1"] = v1
    nulls = df["V1"].isna().sum()
    if nulls > 0:
        print(f"WARNING: {label} has {nulls} NaN gene IDs after coercion; they will be ignored in set checks.")
    return df

def load_shared_ids(path_shared):
    try:
        shared_df = pd.read_csv(path_shared)
    except FileNotFoundError as e:
        print(f"\nERROR: Shared genes file not found: {path_shared}\nDetails: {e}")
        sys.exit(1)

    possible_gene_cols = ["entrezID", "entrez_id", "EntrezID"]
    col_found = next((c for c in possible_gene_cols if c in shared_df.columns), None)
    if col_found is None:
        print(f"ERROR: Shared genes file missing Entrez column. Need one of {possible_gene_cols}. "
              f"Found: {list(shared_df.columns)}")
        sys.exit(1)

    shared_ids = pd.to_numeric(shared_df[col_found], errors="coerce").dropna().astype("Int64")
    return set(shared_ids.tolist())

def report_subset(name, ids, ref_name, ref_ids, max_show=25):
    extras = sorted(list(ids - ref_ids))
    if extras:
        print(f"   - ❌ {name} contains {len(extras)} IDs not in {ref_name}. Examples: {extras[:max_show]}")
    else:
        print(f"   - ✅ All {name} IDs are contained in {ref_name}.")
    return extras

def report_difference(left_name, left_ids, right_name, right_ids, max_show=25):
    only_in_left  = sorted(list(left_ids - right_ids))
    only_in_right = sorted(list(right_ids - left_ids))
    if not only_in_left and not only_in_right:
        print(f"   - ✅ {left_name} and {right_name} have identical ID sets.")
    else:
        if only_in_left:
            print(f"   - ⚠️  {len(only_in_left)} IDs in {left_name} not in {right_name}. "
                  f"Examples: {only_in_left[:max_show]}")
        if only_in_right:
            print(f"   - ⚠️  {len(only_in_right)} IDs in {right_name} not in {left_name}. "
                  f"Examples: {only_in_right[:max_show]}")
    return only_in_left, only_in_right

# =========================================================
# 1) Load Datasets
# =========================================================
print("\n[1] Loading datasets...")
cmap_df  = load_parquet(PATH_CMAP_DATA)
tahoe_df = load_parquet(PATH_TAHOE_DATA)
shared_ids = load_shared_ids(PATH_SHARED_GENES)
print("   - Files loaded successfully.")

# Normalize V1 dtypes
cmap_df  = coerce_v1_to_int64(cmap_df,  "CMap")
tahoe_df = coerce_v1_to_int64(tahoe_df, "Tahoe")

# Build ID sets (ignore NaNs)
cmap_genes_set  = set(cmap_df["V1"].dropna().astype(int).tolist())
tahoe_genes_set = set(tahoe_df["V1"].dropna().astype(int).tolist())

# =========================================================
# 2) Sanity Checks
# =========================================================
print("\n[2] Performing Sanity Checks...")

# --- Check 1: Shape Comparison ---
print("\n--- Check 1: Comparing Shapes ---")
print(f"   - CMap Shape:  {cmap_df.shape} (genes, experiments)")
print(f"   - Tahoe Shape: {tahoe_df.shape} (genes, experiments)")
if cmap_df.shape[0] == tahoe_df.shape[0]:
    print("   - ✅ PASS: The number of genes (rows) is identical.")
else:
    print("   - ❌ FAIL: The number of genes (rows) is DIFFERENT.")
print("   - Note: The number of experiments (columns) may differ, which is acceptable.")

# --- Check 2a: CMap vs Tahoe (set equality) ---
print("\n--- Check 2a: Comparing Gene ID Sets (CMap ↔ Tahoe) ---")
_ = report_difference("CMap", cmap_genes_set, "Tahoe", tahoe_genes_set)

# --- Check 2b: CMap ⊆ Shared, Tahoe ⊆ Shared ---
print("\n--- Check 2b: Membership Against Shared IDs ---")
print(f"   Shared IDs count: {len(shared_ids)}")
cmap_extras  = report_subset("CMap",  cmap_genes_set,  "Shared", shared_ids)
tahoe_extras = report_subset("Tahoe", tahoe_genes_set, "Shared", shared_ids)

# --- Check 2c: Tahoe-only relative to CMap & also in Shared? ---
print("\n--- Check 2c: Tahoe IDs not in CMap (and whether they are in Shared) ---")
tahoe_not_in_cmap = sorted(list(tahoe_genes_set - cmap_genes_set))
if tahoe_not_in_cmap:
    print(f"   - ⚠️  {len(tahoe_not_in_cmap)} Tahoe IDs not in CMap. Examples: {tahoe_not_in_cmap[:25]}")
    tahoe_not_in_cmap_not_in_shared = [g for g in tahoe_not_in_cmap if g not in shared_ids]
    if tahoe_not_in_cmap_not_in_shared:
        print(f"      • Of those, {len(tahoe_not_in_cmap_not_in_shared)} are also NOT in Shared. "
              f"Examples: {tahoe_not_in_cmap_not_in_shared[:25]}")
    else:
        print("      • All Tahoe-not-in-CMap IDs ARE present in Shared.")
else:
    print("   - ✅ No Tahoe-only IDs relative to CMap.")

# --- Check 2d: CMap-only relative to Tahoe & also in Shared? ---
print("\n--- Check 2d: CMap IDs not in Tahoe (and whether they are in Shared) ---")
cmap_not_in_tahoe = sorted(list(cmap_genes_set - tahoe_genes_set))
if cmap_not_in_tahoe:
    print(f"   - ⚠️  {len(cmap_not_in_tahoe)} CMap IDs not in Tahoe. Examples: {cmap_not_in_tahoe[:25]}")
    cmap_not_in_tahoe_not_in_shared = [g for g in cmap_not_in_tahoe if g not in shared_ids]
    if cmap_not_in_tahoe_not_in_shared:
        print(f"      • Of those, {len(cmap_not_in_tahoe_not_in_shared)} are also NOT in Shared. "
              f"Examples: {cmap_not_in_tahoe_not_in_shared[:25]}")
    else:
        print("      • All CMap-not-in-Tahoe IDs ARE present in Shared.")
else:
    print("   - ✅ No CMap-only IDs relative to Tahoe.")

# --- Check 3: Data Type Verification ---
print("\n--- Check 3: Verifying Data Types ---")
print(f"   - CMap 'V1' dtype:  {cmap_df['V1'].dtype}")
print(f"   - Tahoe 'V1' dtype: {tahoe_df['V1'].dtype}")

# sample rank columns (skip V1)
if cmap_df.shape[1] > 1 and tahoe_df.shape[1] > 1:
    cmap_rank_dtype  = cmap_df.iloc[:, 1].dtype
    tahoe_rank_dtype = tahoe_df.iloc[:, 1].dtype
    print(f"   - CMap rank dtype (sample):  {cmap_rank_dtype}")
    print(f"   - Tahoe rank dtype (sample): {tahoe_rank_dtype}")
    if "int" in str(cmap_rank_dtype) and "int" in str(tahoe_rank_dtype):
        print("   - ✅ PASS: Rank data appears integer-based as expected.")
    else:
        print("   - ⚠️  WARN: Rank data is not integer-based. Review the transformation scripts.")
else:
    print("   - NOTE: Not enough columns to sample rank dtypes.")

# --- Check 4: Rank Range Check ---
print("\n--- Check 4: Checking Rank Ranges (sample up to 5 experiments) ---")
def rank_min_max(df):
    cols = df.columns[1:6]  # skip V1
    if len(cols) == 0:
        return None, None
    return df[cols].min().min(), df[cols].max().max()

cmap_min, cmap_max = rank_min_max(cmap_df)
tahoe_min, tahoe_max = rank_min_max(tahoe_df)
print(f"   - CMap sample ranks:  Min={cmap_min}, Max={cmap_max}")
print(f"   - Tahoe sample ranks: Min={tahoe_min}, Max={tahoe_max}")

n_genes_cmap  = cmap_df.shape[0]
n_genes_tahoe = tahoe_df.shape[0]
if cmap_max is not None and tahoe_max is not None:
    if cmap_max <= n_genes_cmap and tahoe_max <= n_genes_tahoe:
        print("   - ✅ PASS: Max ranks within expected range (≤ number of genes).")
    else:
        print("   - ⚠️  WARN: Max rank seems too high. Check ranking logic.")

# =========================================================
# 3) Visual Inspection
# =========================================================
print("\n[3] Visual Inspection (head of each DataFrame):")
print("\n--- CMap Data Head ---")
print(cmap_df.head())
print("\n--- Tahoe Data Head ---")
print(tahoe_df.head())

# =========================================================
# 4) Final Verdict
# =========================================================
print("\n[4] Final Verdict:")
aligned_rows = (cmap_df.shape[0] == tahoe_df.shape[0])
same_sets    = (cmap_genes_set == tahoe_genes_set)
cmap_ok_vs_shared  = (len(cmap_extras)  == 0)
tahoe_ok_vs_shared = (len(tahoe_extras) == 0)

if aligned_rows and same_sets and cmap_ok_vs_shared and tahoe_ok_vs_shared:
    print("   - ✅ SUCCESS: CMap and Tahoe gene sets align and both are consistent with Shared.")
else:
    print("   - ❌ ATTENTION: One or more checks failed. Review messages above before proceeding.")
