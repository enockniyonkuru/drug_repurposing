#!/usr/bin/env python3
"""
TAHOE PART 1: Gene Filtering
Filters raw Tahoe H5 file (~300K genes) to 12,544 shared genes across all 56,827 experiments.
Input: aggregated.h5 (raw Tahoe data)
Output: tahoe_l2fc_shared_genes_all_drugs.parquet
Runtime: Hours (use create_tahoe_og_signatures_hpc.py on HPC for full dataset)
"""
import os
import gc
import numpy as np
import pandas as pd
import tables as tb
import pyarrow as pa
import pyarrow.parquet as pq
import pyreadr
from tqdm import tqdm
from joblib import Parallel, delayed, cpu_count

# =========================================================
# 0) Paths
# =========================================================
print("Initializing all paths and directories...")

# --- Input Directories ---
IN_DIR_TAHOE_RAW  = "../data/drug_signatures/tahoe"
IN_DIR_REPORTS    = "../reports"

# --- Input Files ---
PATH_H5 = os.path.join(IN_DIR_TAHOE_RAW, "aggregated.h5")
PATH_GENES_PARQ = os.path.join(IN_DIR_TAHOE_RAW, "genes.parquet")
PATH_EXPERIMENTS = os.path.join(IN_DIR_TAHOE_RAW, "experiments.parquet")
PATH_TAHOE_DRUG_EXP = os.path.join(IN_DIR_TAHOE_RAW, "tahoe_drug_experiments_new.csv")
PATH_SHARED_GENES = os.path.join(IN_DIR_REPORTS, "shared_genes_tahoe_cmap.csv")
PATH_SHARED_DRUGS = os.path.join(IN_DIR_REPORTS, "shared_drugs_tahoe_cmap.csv")

# --- Intermediate & Output Directories ---
DIR_FILTERED = "../data/filtered_tahoe"
DIR_OUTPUT = "../data/drug_signatures/tahoe"
DIR_OUT_REPORTS = "../reports"

# --- Intermediate File ---
OUT_L2FC_GENE_FILTERED_PARQUET = os.path.join(DIR_FILTERED, "tahoe_l2fc_shared_genes_all_drugs.parquet")

# --- Final Output Files ---
OUT_RDATA_GENES_FILTERED = os.path.join(DIR_OUTPUT, "tahoe_genes_filtered.RData")
OUT_RDATA_GENES_DRUGS_FILTERED = os.path.join(DIR_OUTPUT, "tahoe_genes_drugs.RData")
OUT_REPORT = os.path.join(DIR_OUT_REPORTS, "tahoe_signature_versions_report.txt")

# Create output directories
os.makedirs(DIR_FILTERED, exist_ok=True)
os.makedirs(DIR_OUTPUT, exist_ok=True)
os.makedirs(DIR_OUT_REPORTS, exist_ok=True)

# =========================================================
#
# 🚀 PART 1: Filter H5 by SHARED GENES (All Experiments)
#
# =========================================================
print("\n" + "="*80)
print("🚀 STARTING PART 1: Filter Large H5 by Shared Genes (All Experiments)")
print("THIS WILL TAKE A VERY LONG TIME.")
print("="*80)

# ----------------------------
# 1.1) Identify Shared Genes to Keep (Columns)
# ----------------------------
print("\n--- Part 1, Step 1: Identifying Shared Genes to Keep (Columns) ---")
shared_genes_df = pd.read_csv(PATH_SHARED_GENES)
shared_gene_names = set(shared_genes_df["gene_name"].unique())

tahoe_genes_full = pd.read_parquet(PATH_GENES_PARQ)
genes_to_keep_df = tahoe_genes_full[tahoe_genes_full['gene_name'].isin(shared_gene_names)].copy()

col_idx_keep = sorted(genes_to_keep_df["gene_idx"].unique().tolist())
col_names_keep = genes_to_keep_df.sort_values("gene_idx")["gene_name"].tolist()

print(f"Found {len(col_idx_keep)} shared genes to use as columns.")

# ----------------------------
# 1.2) Get ALL Experiments to Keep (Rows)
# ----------------------------
print("\n--- Part 1, Step 2: Identifying ALL Experiments to Keep (Rows) ---")
exp_full = pd.read_parquet(PATH_EXPERIMENTS)
# The H5 file rows correspond 1:1 with `experiments.parquet`
row_idx_keep = exp_full["experiment_id"].astype(int).tolist()
n_total_rows = len(row_idx_keep)
print(f"Found {n_total_rows:,} total experiments to process.")

# ----------------------------
# 1.3) Parallel Stream and Filter H5 data
# ----------------------------
print("\n--- Part 1, Step 3: Streaming and Filtering H5 Data (in Parallel) ---")

def process_chunk(row_indices_chunk, h5_path, col_sorted, col_unsort, schema):
    """
    Function to be run in parallel. Reads a chunk of rows from the H5 file,
    filters columns, and returns a PyArrow Table.
    """
    with tb.open_file(h5_path, mode="r") as h5:
        node = h5.get_node("/l2fc")
        
        block_full = np.empty((len(row_indices_chunk), node.shape[1]), dtype=node.dtype)
        for i, row_idx in enumerate(row_indices_chunk):
            block_full[i, :] = node[row_idx, :]
            
        block_cols_sorted = np.take(block_full, col_sorted, axis=1)
        block_cols = block_cols_sorted[:, col_unsort]
        
        # Keep experiment_id as int64 to avoid overflow
        arrs = [pa.array(row_indices_chunk, type=pa.int64())] + [
            pa.array(block_cols[:, j], type=pa.float32()) for j in range(block_cols.shape[1])
        ]
        batch = pa.table(arrs, schema=schema)
        
        return batch

# Prepare common variables for parallel processing
row_sorted = np.sort(np.asarray(row_idx_keep, dtype=np.int64))
col_idx_keep_arr = np.asarray(col_idx_keep, dtype=np.int64)
col_order = np.argsort(col_idx_keep_arr)
col_sorted = col_idx_keep_arr[col_order]
col_unsort = np.argsort(col_order)

# Use int64 for experiment_id to avoid overflow
schema = pa.schema(
    [pa.field("experiment_id", pa.int64())] +
    [pa.field(name, pa.float32()) for name in col_names_keep]
)

n_cores = max(1, cpu_count() - 1)
print(f"Splitting work across {n_cores} CPU cores.")

# Split the list of rows into chunks for each core
row_chunks = np.array_split(row_sorted, n_cores)

# Run the processing in parallel
print(f"Processing {len(row_chunks)} chunks in parallel...")
with Parallel(n_jobs=n_cores, verbose=10) as parallel:
    results = parallel(
        delayed(process_chunk)(chunk, PATH_H5, col_sorted, col_unsort, schema)
        for chunk in row_chunks
    )

# Write the collected results to the Parquet file sequentially
print("Writing results to intermediate Parquet file...")
with pq.ParquetWriter(OUT_L2FC_GENE_FILTERED_PARQUET, schema, compression="zstd") as writer:
    for batch in tqdm(results, desc="Writing batches"):
        writer.write_table(batch)

print(f"Finished streaming. Saved intermediate data to: {OUT_L2FC_GENE_FILTERED_PARQUET}")
print("✅ PART 1 COMPLETE.\n")
del results, row_chunks, exp_full
gc.collect()

# =========================================================
#
# 📊 PART 2: Rank Gene-Filtered Data
#
# =========================================================
print("\n" + "="*80)
print("📊 STARTING PART 2: Rank Gene-Filtered Data and Save")
print("="*80)

# ----------------------------
# 2.1) Load intermediate L2FC data
# ----------------------------
print("\n[Part 2, Step 1] Loading gene-filtered L2FC data...")
try:
    l2fc_df = pd.read_parquet(OUT_L2FC_GENE_FILTERED_PARQUET)
    print(f"  - Loaded data with shape: {l2fc_df.shape}")
except FileNotFoundError:
    raise SystemExit(f"ERROR: Input file not found at {OUT_L2FC_GENE_FILTERED_PARQUET}")

if "experiment_id" in l2fc_df.columns:
    l2fc_df = l2fc_df.set_index("experiment_id")

# ----------------------------
# 2.2) Load Gene Name -> Entrez ID Mapping
# ----------------------------
print("\n[Part 2, Step 2] Loading gene name to Entrez ID mapping...")
gene_name_to_entrez = dict(zip(shared_genes_df["gene_name"], shared_genes_df["entrezID"]))
shared_entrez_ids = set(pd.to_numeric(shared_genes_df["entrezID"], errors="coerce").dropna().astype(int).tolist())
print(f"  - Created gene map with {len(gene_name_to_entrez)} entries.")
print(f"  - Shared Entrez IDs: {len(shared_entrez_ids)}")

# ----------------------------
# 2.3) Transpose, map → Entrez, and Rank
# ----------------------------
print("\n[Part 2, Step 3] Transposing, mapping to Entrez, and filtering...")
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
# 2.4) Rank Genes (CMap-style) in Chunks
# ----------------------------
print("\n[Part 2, Step 4] Ranking all experiments (in chunks)...")
cols = transposed.columns
CHUNK_SIZE = 512

ranked_chunks = []
for start in tqdm(range(0, len(cols), CHUNK_SIZE), desc="Part 2: Ranking Chunks"):
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
# 2.5) Save `tahoe_genes_filtered.RData`
# ----------------------------
print(f"\n[Part 2, Step 5] Saving {OUT_RDATA_GENES_FILTERED}...")
# Convert to CMap-like format (V1, V2, ...) using pd.concat for efficiency
print("  - Building CMap-like DataFrame...")
data_dict = {"V1": ranked_genes_x_exper.index}
for j, col in enumerate(tqdm(ranked_genes_x_exper.columns, desc="Converting to CMap-like"), start=2):
    data_dict[f"V{j}"] = ranked_genes_x_exper[col].to_numpy()

cmap_like_genes_filtered = pd.DataFrame(data_dict)
print(f"  - DataFrame created with shape: {cmap_like_genes_filtered.shape}")

pyreadr.write_rdata(OUT_RDATA_GENES_FILTERED, {"tahoe_genes_filtered": cmap_like_genes_filtered})
print(f"  - Saved gene-filtered RData: {OUT_RDATA_GENES_FILTERED} (shape={cmap_like_genes_filtered.shape})")
shape_genes_filtered = cmap_like_genes_filtered.shape

del cmap_like_genes_filtered
gc.collect()
print("✅ PART 2 COMPLETE.\n")

# =========================================================
#
# 🎯 PART 3: Filter Ranked Data by SHARED DRUGS
#
# =========================================================
print("\n" + "="*80)
print("🎯 STARTING PART 3: Filter Ranked Data by Shared Drugs")
print("="*80)

# ----------------------------
# 3.1) Identify Shared Experiment IDs to Keep
# ----------------------------
print("\n[Part 3, Step 1] Identifying shared experiment IDs...")
shared_drugs_df = pd.read_csv(PATH_SHARED_DRUGS)
tahoe_drug_exp_df = pd.read_csv(PATH_TAHOE_DRUG_EXP)

# Get the set of shared drug names from Tahoe
shared_tahoe_drug_names = set(shared_drugs_df['tahoe_original_name'].dropna())
print(f"  - Found {len(shared_tahoe_drug_names)} shared drug names in Tahoe")

# Filter tahoe_drug_experiments to get experiment IDs for shared drugs
shared_drug_exp_ids = set(
    tahoe_drug_exp_df[tahoe_drug_exp_df['name'].isin(shared_tahoe_drug_names)]['id'].astype(int)
)
print(f"  - Found {len(shared_drug_exp_ids)} experiment IDs for shared drugs")

# Find which columns from our ranked matrix are in this set
cols_to_keep = ranked_genes_x_exper.columns.intersection(shared_drug_exp_ids)
print(f"  - Found {len(cols_to_keep)} shared experiments in the ranked matrix.")

if len(cols_to_keep) == 0:
    print("WARNING: No shared drug experiments found in ranked matrix!")
    print("This may indicate a mismatch between experiment IDs.")

# ----------------------------
# 3.2) Filter and Save `tahoe_genes_drugs.RData`
# ----------------------------
print(f"\n[Part 3, Step 2] Filtering and saving {OUT_RDATA_GENES_DRUGS_FILTERED}...")
ranked_genes_drugs_df = ranked_genes_x_exper[cols_to_keep]
del ranked_genes_x_exper
gc.collect()

# Convert to CMap-like format (V1, V2, ...) using pd.concat for efficiency
print("  - Building CMap-like DataFrame...")
data_dict = {"V1": ranked_genes_drugs_df.index}
for j, col in enumerate(tqdm(ranked_genes_drugs_df.columns, desc="Converting to CMap-like"), start=2):
    data_dict[f"V{j}"] = ranked_genes_drugs_df[col].to_numpy()

cmap_like_genes_drugs = pd.DataFrame(data_dict)
print(f"  - DataFrame created with shape: {cmap_like_genes_drugs.shape}")

pyreadr.write_rdata(OUT_RDATA_GENES_DRUGS_FILTERED, {"tahoe_genes_drugs": cmap_like_genes_drugs})
print(f"  - Saved gene-and-drug-filtered RData: {OUT_RDATA_GENES_DRUGS_FILTERED} (shape={cmap_like_genes_drugs.shape})")
shape_genes_drugs_filtered = cmap_like_genes_drugs.shape

del cmap_like_genes_drugs, ranked_genes_drugs_df
gc.collect()
print("✅ PART 3 COMPLETE.\n")

# =========================================================
#
# 📝 PART 4: Generate Final Report
#
# =========================================================
print("\n" + "="*80)
print("📝 STARTING PART 4: Generate Final Report")
print("="*80)

try:
    report_lines = [
        "===============================================",
        "  Tahoe Drug Signature Versions Report",
        "===============================================",
        "\nThis report summarizes the dimensions (genes, signatures) of the two",
        "generated Tahoe .RData files. These files contain RANKED data.",
        "\n",
        "--- 1. `tahoe_signatures.RData` ---",
        "Status:   NOT CREATED",
        "Reason:   The full Tahoe dataset ('aggregated.h5') is too large to",
        "          process into a single RData file. The pipeline starts",
        "          by filtering for shared genes.",
        "\n",
        "--- 2. Gene-Filtered Signatures ---",
        f"File:     {os.path.basename(OUT_RDATA_GENES_FILTERED)}",
        "Filter:   Filtered to include ONLY shared genes (all experiments).",
        f"Genes:    {shape_genes_filtered[0]:,}",
        f"Sigs:     {shape_genes_filtered[1] - 1:,} (Total columns - 1 for gene ID)",
        f"Shape:    {shape_genes_filtered}",
        "\n",
        "--- 3. Gene- and Drug-Filtered Signatures ---",
        f"File:     {os.path.basename(OUT_RDATA_GENES_DRUGS_FILTERED)}",
        "Filter:   Filtered by shared genes AND shared drugs.",
        f"Genes:    {shape_genes_drugs_filtered[0]:,}",
        f"Sigs:     {shape_genes_drugs_filtered[1] - 1:,} (Total columns - 1 for gene ID)",
        f"Shape:    {shape_genes_drugs_filtered}",
        "\n",
        "--- Summary ---",
        f"Shared genes used: {len(shared_entrez_ids):,}",
        f"Shared drugs used: {len(shared_tahoe_drug_names):,}",
        f"Shared drug experiments: {len(shared_drug_exp_ids):,}",
    ]
    
    with open(OUT_REPORT, 'w') as f:
        f.write("\n".join(report_lines))
    
    print(f"Successfully generated report: {OUT_REPORT}")
    
except Exception as e:
    print(f"\nERROR: Could not generate summary report: {e}")

print("✅ PART 4 COMPLETE.\n")
print("\n" + "="*80)
print("✅✅✅ ALL STEPS FINISHED SUCCESSFULLY! ✅✅✅")
print("="*80)
