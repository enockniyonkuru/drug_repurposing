#!/usr/bin/env python3
"""
TAHOE PART 2: Ranking
Ranks gene expression values (CMap-style) for all experiments.
Input: tahoe_l2fc_shared_genes_all_drugs.parquet (from Part 1)
Output: tahoe_ranked_shared_genes_all_drugs.parquet, checkpoint_ranked_genes_x_exper.parquet
Runtime: ~2-3 minutes
"""
import os
import gc
import numpy as np
import pandas as pd
import pyreadr
from tqdm import tqdm

# =========================================================
# 0) Paths
# =========================================================
print("Initializing all paths and directories...")

# --- Input Directories ---
IN_DIR_TAHOE_RAW  = "../data/drug_signatures/tahoe"
IN_DIR_REPORTS    = "../reports"
DIR_FILTERED = "../data/filtered_tahoe"

# --- Input Files ---
PATH_SHARED_GENES = os.path.join(IN_DIR_REPORTS, "shared_genes_tahoe_cmap.csv")

# --- Intermediate Input File (from Part 1) ---
IN_L2FC_GENE_FILTERED_PARQUET = os.path.join(DIR_FILTERED, "tahoe_l2fc_shared_genes_all_drugs.parquet")

# --- Intermediate Output File (for Part 2B) ---
OUT_RANKED_PARQUET = os.path.join(DIR_FILTERED, "tahoe_ranked_shared_genes_all_drugs.parquet")

# --- Output Directories ---
DIR_OUTPUT = "../data/drug_signatures/tahoe"

# --- Final Output Files ---
OUT_RDATA_GENES_FILTERED = os.path.join(DIR_OUTPUT, "tahoe_genes_filtered.RData")

# Create output directories
os.makedirs(DIR_OUTPUT, exist_ok=True)
os.makedirs(DIR_FILTERED, exist_ok=True)

print("\n" + "="*80)
print("🚀 STARTING PART 2A: Ranking Gene-Filtered Data")
print("="*80)

# =========================================================
#
# 📊 PART 2A: Rank Gene-Filtered Data
#
# =========================================================

# ----------------------------
# 2A.1) Load intermediate L2FC data
# ----------------------------
print("\n[Part 2A, Step 1] Loading gene-filtered L2FC data...")
try:
    l2fc_df = pd.read_parquet(IN_L2FC_GENE_FILTERED_PARQUET)
    print(f"  - Loaded data with shape: {l2fc_df.shape}")
except FileNotFoundError:
    raise SystemExit(f"ERROR: Input file not found at {IN_L2FC_GENE_FILTERED_PARQUET}")

if "experiment_id" in l2fc_df.columns:
    l2fc_df = l2fc_df.set_index("experiment_id")

# ----------------------------
# 2A.2) Load Gene Name -> Entrez ID Mapping
# ----------------------------
print("\n[Part 2A, Step 2] Loading gene name to Entrez ID mapping...")
shared_genes_df = pd.read_csv(PATH_SHARED_GENES)
gene_name_to_entrez = dict(zip(shared_genes_df["gene_name"], shared_genes_df["entrezID"]))
shared_entrez_ids = set(pd.to_numeric(shared_genes_df["entrezID"], errors="coerce").dropna().astype(int).tolist())
print(f"  - Created gene map with {len(gene_name_to_entrez)} entries.")
print(f"  - Shared Entrez IDs: {len(shared_entrez_ids)}")

# ----------------------------
# 2A.3) Transpose, map → Entrez, and Filter
# ----------------------------
print("\n[Part 2A, Step 3] Transposing, mapping to Entrez, and filtering...")
transposed = l2fc_df.T  # rows: gene symbols, cols: experiment_id
del l2fc_df
gc.collect()

transposed["entrezID"] = transposed.index.map(gene_name_to_entrez)
transposed = transposed.dropna(subset=["entrezID"])
transposed["entrezID"] = pd.to_numeric(transposed["entrezID"], errors="coerce").astype("Int64")
transposed = transposed.dropna(subset=["entrezID"])
transposed["entrezID"] = transposed["entrezID"].astype(int)

print(f"  - Shape before collapsing duplicates: {transposed.shape}")
transposed = transposed.groupby("entrezID").mean(numeric_only=True)
print(f"  - Shape after collapsing to unique Entrez IDs: {transposed.shape}")

# HARD FILTER to the shared Entrez set
transposed = transposed.loc[transposed.index.intersection(shared_entrez_ids)]
print(f"  - Enforced shared set: {transposed.shape[0]} genes kept.")

# ----------------------------
# 2A.4) Rank Genes (CMap-style) in Chunks
# ----------------------------
print("\n[Part 2A, Step 4] Ranking all experiments (in chunks)...")
cols = transposed.columns
CHUNK_SIZE = 512

ranked_chunks = []
for start in tqdm(range(0, len(cols), CHUNK_SIZE), desc="Part 2A: Ranking Chunks"):
    end = min(start + CHUNK_SIZE, len(cols))
    sub_df = transposed.iloc[:, start:end]
    sub_rank = sub_df.rank(axis=0, method="first", ascending=False, na_option="bottom")
    ranked_chunks.append(sub_rank.astype("int32"))
    del sub_df, sub_rank
    gc.collect()

ranked_genes_x_exper = pd.concat(ranked_chunks, axis=1)
del ranked_chunks, transposed
gc.collect()
print(f"  - Final ranked matrix shape: {ranked_genes_x_exper.shape}")

# ----------------------------
# 2A.5) Save Intermediate Ranked Parquet File
# ----------------------------
print(f"\n[Part 2A, Step 5] Saving intermediate ranked data to parquet...")
# Reset index to save entrezID as a column
ranked_genes_x_exper_to_save = ranked_genes_x_exper.reset_index()
ranked_genes_x_exper_to_save.to_parquet(OUT_RANKED_PARQUET, index=False)
print(f"  - Saved ranked data: {OUT_RANKED_PARQUET} (shape={ranked_genes_x_exper_to_save.shape})")
del ranked_genes_x_exper_to_save
gc.collect()

# Save a checkpoint for Step 6 to avoid re-running Steps 1-5
CHECKPOINT_RANKED = os.path.join(DIR_FILTERED, "checkpoint_ranked_genes_x_exper.parquet")
checkpoint_to_save = ranked_genes_x_exper.reset_index()
checkpoint_to_save.to_parquet(CHECKPOINT_RANKED, index=False)
print(f"  - Saved checkpoint: {CHECKPOINT_RANKED}")
del checkpoint_to_save
gc.collect()

print("\n" + "="*80)
print("✅ PART 2 COMPLETE - Ranked data saved to parquet")
print("="*80)
print(f"\nIntermediate files created:")
print(f"  - {OUT_RANKED_PARQUET}")
print(f"  - {CHECKPOINT_RANKED}")
print(f"\nNext steps:")
print(f"  1. Run filter_tahoe_part3a_rdata_all.R to create tahoe_genes_filtered.RData")
print(f"  2. Run filter_tahoe_part3b_rdata_shared_drugs.R to create tahoe_genes_drugs.RData")
