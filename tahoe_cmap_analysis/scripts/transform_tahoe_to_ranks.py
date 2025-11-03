import os
import gc
import pandas as pd
from tqdm.auto import tqdm

# =========================================================
# 0) Paths
# =========================================================
IN_DIR_FILTERED    = "../data/Filtered/"
IN_DIR_COMPARISON  = "../data/Comparison/"
PATH_TAHOE_L2FC    = os.path.join(IN_DIR_FILTERED,   "tahoe_l2fc_shared_genes_drugs.parquet")
PATH_SHARED_GENES  = os.path.join(IN_DIR_COMPARISON, "shared_genes_tahoe_cmap_improved.csv")


OUT_DIR                    = "../data/Processed/"
PATH_TAHOE_RANKS_MATRIX    = os.path.join(OUT_DIR, "tahoe_ranks_matrix_shared.parquet")
PATH_TAHOE_RANKS_CMAPLIKE  = os.path.join(OUT_DIR, "drug_rep_tahoe_ranks_shared_genes_drugs.parquet")
PATH_TAHOE_RANKS_SUMMARY   = os.path.join(OUT_DIR, "tahoe_ranks_summary.csv")

os.makedirs(OUT_DIR, exist_ok=True)
print("Initialized paths.")

# =========================================================
# 1) Load filtered Tahoe L2FC (experiments × genes)
# =========================================================
print("\n[1] Loading filtered Tahoe L2FC data...")
try:
    l2fc_df = pd.read_parquet(PATH_TAHOE_L2FC)
    print(f"  - Loaded data with shape: {l2fc_df.shape}")
except FileNotFoundError:
    raise SystemExit(f"ERROR: Input file not found at {PATH_TAHOE_L2FC}")

# Set experiment_id as the index if present
if "experiment_id" in l2fc_df.columns:
    l2fc_df = l2fc_df.set_index("experiment_id")

# =========================================================
# 2) Load Gene Name -> Entrez ID Mapping + shared set
# =========================================================
print("\n[2] Loading gene name to Entrez ID mapping...")
try:
    gene_map_used = pd.read_csv(PATH_SHARED_GENES)
except FileNotFoundError:
    raise SystemExit(f"ERROR: Shared genes file not found at {PATH_SHARED_GENES}")

# be robust to column naming
needed_cols = {"gene_name", "entrezID"}
missing = needed_cols - set(gene_map_used.columns)
if missing:
    raise SystemExit(f"ERROR: Missing columns in shared genes CSV: {missing}")

# mapping + shared set
gene_name_to_entrez = dict(zip(gene_map_used["gene_name"], gene_map_used["entrezID"]))
shared_entrez_ids = set(pd.to_numeric(gene_map_used["entrezID"], errors="coerce").dropna().astype(int).tolist())
print(f"  - Created gene map with {len(gene_name_to_entrez)} entries.")
print(f"  - Shared Entrez IDs: {len(shared_entrez_ids)}")

# =========================================================
# 3) Transpose (genes × experiments), map → Entrez, drop dup symbols
# =========================================================
print("\n[3] Transposing, mapping to Entrez, and handling duplicates...")
transposed = l2fc_df.T  # rows: gene symbols, cols: experiment_id
# Map symbols → Entrez
transposed["entrezID"] = transposed.index.map(gene_name_to_entrez)

before_drop = transposed.shape[0]
transposed = transposed.dropna(subset=["entrezID"])
after_drop = transposed.shape[0]
print(f"  - Dropped unmapped symbols: {before_drop - after_drop}")

# convert to int Entrez (consistent dtype)
transposed["entrezID"] = pd.to_numeric(transposed["entrezID"], errors="coerce").astype("Int64")
transposed = transposed.dropna(subset=["entrezID"])
transposed["entrezID"] = transposed["entrezID"].astype(int)

# average duplicates that map to same Entrez ID
print(f"  - Shape before collapsing duplicates: {transposed.shape}")
transposed = transposed.groupby("entrezID").mean(numeric_only=True)
print(f"  - Shape after collapsing to unique Entrez IDs: {transposed.shape}")

# =========================================================
# 3b) HARD FILTER to the shared Entrez set (prevents leakage)
# =========================================================
kept_before = transposed.shape[0]
transposed = transposed.loc[transposed.index.intersection(shared_entrez_ids)]
print(f"  - Enforced shared set: kept {transposed.shape[0]} / {kept_before} genes")

# =========================================================
# 4) Rank Genes within each experiment (highest L2FC -> 1)
# =========================================================
print("\n[4] Ranking genes within each experiment (CMap-style)...")
cols = transposed.columns
CHUNK_SIZE = 512

ranked_chunks = []
for start in tqdm(range(0, len(cols), CHUNK_SIZE), desc="Ranking Chunks"):
    end = min(start + CHUNK_SIZE, len(cols))
    sub_df = transposed.iloc[:, start:end]
    sub_rank = sub_df.rank(axis=0, method="first", ascending=False, na_option="bottom")
    ranked_chunks.append(sub_rank.astype("int32"))
    del sub_df, sub_rank
    gc.collect()

ranked_genes_x_exper = pd.concat(ranked_chunks, axis=1)
del ranked_chunks
gc.collect()

# =========================================================
# 5) Save Outputs in Two Formats
# =========================================================
print("\n[5] Saving outputs in two formats...")

# --- A) Standard Matrix Format (experiments × genes) ---
ranked_exper_x_genes = ranked_genes_x_exper.T
ranked_exper_x_genes.index.name = "experiment_id"
# Sort gene columns by Entrez ID for consistency
ranked_exper_x_genes = ranked_exper_x_genes.reindex(sorted(ranked_exper_x_genes.columns), axis=1)
ranked_exper_x_genes.to_parquet(PATH_TAHOE_RANKS_MATRIX, index=True)
print(f"  - Saved matrix: {PATH_TAHOE_RANKS_MATRIX} (shape={ranked_exper_x_genes.shape})")

# --- B) CMap-like Format ---
print("  - Creating CMap-like format...")
# V1: Entrez IDs (row index)
cmap_like = pd.DataFrame({"V1": ranked_genes_x_exper.index})
# Experiments as V2, V3, ... in order
for j, col in enumerate(ranked_genes_x_exper.columns, start=2):
    cmap_like[f"V{j}"] = ranked_genes_x_exper[col].to_numpy()

cmap_like.to_parquet(PATH_TAHOE_RANKS_CMAPLIKE, index=False)
print(f"  - Saved CMap-like: {PATH_TAHOE_RANKS_CMAPLIKE} (shape={cmap_like.shape})")

# =========================================================
# 6) Sanity checks & summary
# =========================================================
print("\n[6] Sanity checks...")

# Check A: V1 ⊆ shared AND equals shared (size & membership)
final_ids = set(pd.to_numeric(cmap_like["V1"], errors="coerce").dropna().astype(int).tolist())
extra_in_output = final_ids - shared_entrez_ids
missing_in_output = shared_entrez_ids - final_ids

if extra_in_output:
    raise ValueError(
        f"Sanity check FAILED: {len(extra_in_output)} IDs in output not in shared.\n"
        f"Examples: {sorted(list(extra_in_output))[:25]}"
    )

if missing_in_output:
    # This can happen if Tahoe lacks some shared genes; warn but allow, or raise if you require 1:1
    print(f"WARNING: {len(missing_in_output)} shared IDs missing from Tahoe output.")
    print(f"Examples: {sorted(list(missing_in_output))[:25]}")

print("  - Sanity PASSED: output V1 is a subset of shared IDs.")

# Save summary
summary = pd.DataFrame({
    "metric": ["genes_final", "experiments_final", "output_format_1", "output_format_2"],
    "value": [
        ranked_exper_x_genes.shape[1],
        ranked_exper_x_genes.shape[0],
        f"matrix: {ranked_exper_x_genes.shape}",
        f"cmap-like: {cmap_like.shape}",
    ]
})
summary.to_csv(PATH_TAHOE_RANKS_SUMMARY, index=False)
print(f"\nSaved summary to: {PATH_TAHOE_RANKS_SUMMARY}")

print("\n✅ Process finished successfully!")
