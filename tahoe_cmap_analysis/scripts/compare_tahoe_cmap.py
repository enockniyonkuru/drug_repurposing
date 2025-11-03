# generate_comparison_report.py

import pandas as pd
import os
import pyreadr
try:
    from utils import normalize_cell_line_name, normalize_drug_name
except ImportError:
    print("Error: Could not import from 'utils.py'.")
    print("Please ensure 'utils.py' is in the same directory and contains:")
    print(" - normalize_cell_line_name(series)")
    print(" - normalize_drug_name(series)")
    exit()

# --- 1. Define All File Paths ---

# --- Input Data Paths ---
# Get the script directory and construct paths relative to project root
import sys
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

PATH_CMAP_EXP = os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap/cmap_drug_experiments_new.csv")
PATH_TAHOE_EXP = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/experiments.parquet")
PATH_CMAP_SIGS = os.path.join(PROJECT_ROOT, "data/drug_signatures/cmap/cmap_signatures.RData")
PATH_TAHOE_GENES = os.path.join(PROJECT_ROOT, "data/drug_signatures/tahoe/genes.parquet")
PATH_GENE_MAP = os.path.join(os.path.dirname(PROJECT_ROOT), "scripts/data/gene_id_conversion_table.tsv")

# --- Output Report/Data Paths ---
OUT_DIR = os.path.join(PROJECT_ROOT, "reports")
FINAL_REPORT_PATH = os.path.join(OUT_DIR, "compare_tahoe_cmap.txt")
PATH_SHARED_CELL_LINES = os.path.join(OUT_DIR, "shared_cell_lines_tahoe_cmap.csv")
PATH_SHARED_DRUGS = os.path.join(OUT_DIR, "shared_drugs_tahoe_cmap.csv")
PATH_SHARED_GENES_FINAL = os.path.join(OUT_DIR, "shared_genes_tahoe_cmap.csv")


def compare_cell_lines(cmap_experiments_df, tahoe_experiments_df):
    """
    Compares cell lines from CMap and Tahoe datasets, saves the shared list,
    and returns a formatted summary string.
    
    Args:
        cmap_experiments_df (pd.DataFrame): Loaded CMap experiment data.
        tahoe_experiments_df (pd.DataFrame): Loaded Tahoe experiment data.
    
    Returns:
        str: A multi-line string summarizing the cell line comparison.
    """
    # --- 2. Normalize Data ---
    cmap_cell_norm = normalize_cell_line_name(cmap_experiments_df["cell_line"])
    tahoe_cell_norm = normalize_cell_line_name(tahoe_experiments_df["cell_line_tahoe"])

    # --- 3. Compare Cell Line Sets and Summarize ---
    set_cmap_cells = set(cmap_cell_norm.dropna().unique())
    set_tahoe_cells = set(tahoe_cell_norm.dropna().unique())

    cell_intersection = set_cmap_cells & set_tahoe_cells
    cell_only_cmap = set_cmap_cells - set_tahoe_cells
    cell_only_tahoe = set_tahoe_cells - set_cmap_cells

    # Build the report string
    summary = [
        "--- 1. Cell Line Overlap Summary ---",
        f"- CMap Unique Cell Lines:  {len(set_cmap_cells)}",
        f"- Tahoe Unique Cell Lines: {len(set_tahoe_cells)}",
        f"- Shared Cell Lines:       {len(cell_intersection)}",
        f"- Cell Lines Only in CMap: {len(cell_only_cmap)}",
        f"- Cell Lines Only in Tahoe:{len(cell_only_tahoe)}"
    ]

    # --- 4. Save Shared Cell Lines ---
    if cell_intersection:
        shared_df = pd.DataFrame(sorted(list(cell_intersection)), columns=['shared_normalized_cell_line'])
        shared_df.to_csv(PATH_SHARED_CELL_LINES, index=False)
        summary.append(f"\n[SUCCESS] Saved {len(shared_df)} shared cell lines to: {PATH_SHARED_CELL_LINES}")
    else:
        summary.append("\n[INFO] No shared cell lines found after normalization.")
    
    return "\n".join(summary)


def compare_drugs(cmap_experiments_df, tahoe_experiments_df):
    """
    Compares drugs from CMap and Tahoe datasets, saves the shared mapping,
    and returns a formatted summary string.
    
    Args:
        cmap_experiments_df (pd.DataFrame): Loaded CMap experiment data.
        tahoe_experiments_df (pd.DataFrame): Loaded Tahoe experiment data.
    
    Returns:
        str: A multi-line string summarizing the drug comparison.
    """
    # --- 2. Normalize Data ---
    cmap_experiments_df['drug_norm'] = normalize_drug_name(cmap_experiments_df["name"])
    tahoe_experiments_df['drug_norm'] = normalize_drug_name(tahoe_experiments_df["drug"])

    # --- 3. Compare Drug Sets and Summarize ---
    set_cmap_drugs = set(cmap_experiments_df['drug_norm'].dropna().unique())
    set_tahoe_drugs = set(tahoe_experiments_df['drug_norm'].dropna().unique())

    drug_intersection = set_cmap_drugs & set_tahoe_drugs
    drug_only_cmap = set_cmap_drugs - set_tahoe_drugs
    drug_only_tahoe = set_tahoe_drugs - set_cmap_drugs

    summary = [
        "--- 2. Drug Overlap Summary ---",
        f"- CMap Unique Drugs:  {len(set_cmap_drugs)}",
        f"- Tahoe Unique Drugs: {len(set_tahoe_drugs)}",
        f"- Shared Drugs:       {len(drug_intersection)}",
        f"- Drugs Only in CMap: {len(drug_only_cmap)}",
        f"- Drugs Only in Tahoe:{len(drug_only_tahoe)}"
    ]

    # --- 4. Create and Save Mapping for Shared Drugs ---
    if drug_intersection:
        cmap_map = cmap_experiments_df[cmap_experiments_df['drug_norm'].isin(drug_intersection)][['name', 'drug_norm']].drop_duplicates().rename(columns={'name': 'cmap_original_name'})
        tahoe_map = tahoe_experiments_df[tahoe_experiments_df['drug_norm'].isin(drug_intersection)][['drug', 'drug_norm']].drop_duplicates().rename(columns={'drug': 'tahoe_original_name'})

        merged_df = pd.merge(cmap_map, tahoe_map, on='drug_norm')
        merged_df = merged_df[['drug_norm', 'cmap_original_name', 'tahoe_original_name']].sort_values('drug_norm').reset_index(drop=True)
        
        merged_df.to_csv(PATH_SHARED_DRUGS, index=False)
        summary.append(f"\n[SUCCESS] Saved {len(merged_df)} shared drug mappings to: {PATH_SHARED_DRUGS}")
    else:
        summary.append("\n[INFO] No shared drugs found.")
    
    return "\n".join(summary)


def compare_genes():
    """
    Compares gene sets from CMap and Tahoe datasets, saves the shared list,
    and returns a formatted summary string.
    
    Returns:
        str: A multi-line string summarizing the gene comparison.
    """
    summary = ["--- 3. Gene Overlap Summary ---"]
    
    # --- 2. Extract CMap Entrez IDs ---
    try:
        rdata = pyreadr.read_r(PATH_CMAP_SIGS)
        cmap_df = rdata[list(rdata.keys())[0]]
        cmap_entrez_ids = set(pd.to_numeric(cmap_df['V1'], errors='coerce').dropna().astype(int))
        summary.append(f"Loaded {len(cmap_entrez_ids):,} unique Entrez IDs from CMap.")
    except Exception as e:
        return f"--- 3. Gene Overlap Summary ---\n[ERROR] Failed to read CMap file: {e}"

    # --- 3. Map Tahoe Gene Names to Entrez IDs ---
    try:
        gene_map_df = pd.read_csv(PATH_GENE_MAP, sep='\t')
        tahoe_genes_df = pd.read_parquet(PATH_TAHOE_GENES)
        
        name_to_entrez = gene_map_df.dropna(subset=['Gene_name', 'entrezID']).drop_duplicates(subset=['Gene_name']).set_index('Gene_name')['entrezID']
        
        tahoe_genes_df['entrezID'] = tahoe_genes_df['gene_name'].map(name_to_entrez)
        tahoe_mapped_df = tahoe_genes_df.dropna(subset=['entrezID'])
        tahoe_entrez_ids = set(tahoe_mapped_df['entrezID'].astype(int))
        
        summary.append(f"Mapped {len(tahoe_entrez_ids):,} out of {len(tahoe_genes_df):,} Tahoe genes.")
    except Exception as e:
         return f"--- 3. Gene Overlap Summary ---\n[ERROR] Failed to process Tahoe/gene map files: {e}"

    # --- 4. Compare Gene Sets and Summarize ---
    shared_entrez_ids = cmap_entrez_ids.intersection(tahoe_entrez_ids)
    unique_to_cmap = cmap_entrez_ids.difference(tahoe_entrez_ids)
    unique_to_tahoe = tahoe_entrez_ids.difference(cmap_entrez_ids)

    summary.extend([
        "\n--- Gene Statistics ---",
        f"{'Total Unique CMap Genes:':<25} {len(cmap_entrez_ids):,}",
        f"{'Total Mapped Tahoe Genes:':<25} {len(tahoe_entrez_ids):,}",
        "-" * 35,
        f"{'Shared Genes (in both):':<25} {len(shared_entrez_ids):,}",
        f"{'Genes Unique to CMap:':<25} {len(unique_to_cmap):,}",
        f"{'Genes Unique to Tahoe:':<25} {len(unique_to_tahoe):,}"
    ])
    
    # --- 5. Save Final Shared Genes File ---
    if shared_entrez_ids:
        shared_genes_df = tahoe_mapped_df[tahoe_mapped_df['entrezID'].isin(shared_entrez_ids)]
        final_df = shared_genes_df[['gene_name', 'entrezID']].drop_duplicates()
        final_df['entrezID'] = final_df['entrezID'].astype(int)
        
        final_df.to_csv(PATH_SHARED_GENES_FINAL, index=False)
        summary.append(f"\n[SUCCESS] Saved {len(final_df)} shared genes to: {PATH_SHARED_GENES_FINAL}")
    else:
        summary.append("\n[INFO] No shared genes found.")

    return "\n".join(summary)


def main():
    """
    Main function to run all comparisons and generate a single aggregate report.
    """
    os.makedirs(OUT_DIR, exist_ok=True)
    
    # This list will hold the text for the final report
    report_content = [
        "========================================",
        "  Tahoe vs. CMap Comparison Report",
        "========================================",
    ]

    # --- Load shared data ONCE ---
    try:
        print("Loading CMap experiment data...")
        cmap_experiments_df = pd.read_csv(PATH_CMAP_EXP)
        print("Loading Tahoe experiment data...")
        tahoe_experiments_df = pd.read_parquet(PATH_TAHOE_EXP)
        print("...Experiment data loaded.")
    except Exception as e:
        print(f"FATAL ERROR: Could not load experiment files: {e}")
        print("Aborting.")
        return

    # --- Run Comparisons ---
    print("\nRunning cell line comparison...")
    cell_report = compare_cell_lines(cmap_experiments_df.copy(), tahoe_experiments_df.copy())
    report_content.append(cell_report)
    print("...Done cell lines.")

    print("\nRunning drug comparison...")
    drug_report = compare_drugs(cmap_experiments_df.copy(), tahoe_experiments_df.copy())
    report_content.append(drug_report)
    print("...Done drugs.")

    print("\nRunning gene comparison...")
    gene_report = compare_genes() # This one loads its own data
    report_content.append(gene_report)
    print("...Done genes.")

    # --- Write the final report ---
    print(f"\nWriting final report to {FINAL_REPORT_PATH}...")
    try:
        with open(FINAL_REPORT_PATH, 'w') as f:
            f.write("\n\n".join(report_content))
        print("...Report writing complete.")
    except Exception as e:
        print(f"ERROR: Could not write final report: {e}")

    print("\n=== Analysis Complete ===")
    print(f"Summary report saved to: {FINAL_REPORT_PATH}")
    print(f"Shared cells saved to:   {PATH_SHARED_CELL_LINES}")
    print(f"Shared drugs saved to:   {PATH_SHARED_DRUGS}")
    print(f"Shared genes saved to:   {PATH_SHARED_GENES_FINAL}")


if __name__ == "__main__":
    main()
