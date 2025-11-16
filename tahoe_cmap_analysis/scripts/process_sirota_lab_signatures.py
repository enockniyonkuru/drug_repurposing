"""
Sirota Lab Disease Signature Processing Script

This script processes disease signatures from the Sirota Lab, which are stored
in mixed formats (Excel and CSV). It performs the following operations:

1.  Reads an Excel file ('LauraPaperSignature.xlsx') and converts each sheet
    into a separate CSV file in the source directory.
2.  Scans the source directory for ALL .csv files (including the newly converted
    ones and other existing ones like 'CoreFibroidSignature.csv').
3.  Standardizes each CSV file to match the CREEDS-style output format.
4.  Maps the primary logFC column found to 'mean_logfc', 'median_logfc', and
    'common_experiment'.
5.  Adds 'organism' column with a hardcoded value of 'human'.
6.  Saves the standardized files to a new 'sirota_lab_disease_signatures' directory.
7.  Generates a processing report.

Output Structure:
- Individual disease signature CSV files with columns:
  - gene_symbol: Gene identifier
  - mean_logfc: Mean log-fold change (mapped from source logFC)
  - median_logfc: Median log-fold change (mapped from source logFC)
  - common_experiment: Log-fold change from source
  - organism: Source organism (hardcoded "human")
"""

import pandas as pd
import numpy as np
import os
import re
from datetime import datetime
from collections import defaultdict
from typing import Optional, Dict, List, Set, Tuple

# --- ProcessingStats Class ---

class ProcessingStats:
    """
    Track statistics during disease signature processing.
    
    This class maintains comprehensive statistics about the disease signature
    processing workflow, including match rates, organism distribution, and
    detailed counts for reporting purposes.
    
    Attributes:
        total_diseases (int): Total number of unique diseases found
        diseases_processed (int): Number of diseases successfully processed
        total_signatures_found (int): Total number of signatures across all diseases
        total_genes_exported (int): Total number of genes exported
        disease_signature_counts (Dict[str, int]): Signature count per disease
        organism_counts (Dict[str, int]): Number of diseases per organism
        unique_diseases_processed (Set[str]): Set of unique disease names processed
        multi_disease_entries (int): Count of entries with multiple diseases
        pvalue_filter_stats (Dict[str, Dict]): P-value filtering statistics per disease
    """
    
    def __init__(self):
        """Initialize statistics tracking with default values."""
        self.total_diseases = 0
        self.diseases_processed = 0
        self.total_signatures_found = 0
        self.total_genes_exported = 0
        self.disease_signature_counts = {}
        self.organism_counts = defaultdict(int)
        self.unique_diseases_processed = set()
        self.multi_disease_entries = 0
        self.pvalue_filter_stats = {}
        
    def add_match(self, disease_name: str, num_signatures: int, num_genes: int, organism: str,
                  genes_before_filter: Optional[int] = None, pval_filtered: bool = False):
        """
        Record a successful disease match.
        
        Args:
            disease_name (str): Name of the matched disease
            num_signatures (int): Number of signatures found (always 1 for this script)
            num_genes (int): Number of genes in the exported signature
            organism (str): Organism type (e.g., "human", "mouse")
            genes_before_filter (Optional[int]): Number of genes before p-value filtering
            pval_filtered (bool): Whether p-value filtering was applied
        """
        self.diseases_processed += 1
        self.total_signatures_found += num_signatures
        self.total_genes_exported += num_genes
        self.disease_signature_counts[disease_name] = num_signatures
        self.organism_counts[organism] += 1
        self.unique_diseases_processed.add(disease_name.lower())
        
        # Track p-value filtering stats
        if pval_filtered and genes_before_filter is not None:
            self.pvalue_filter_stats[disease_name] = {
                'before': genes_before_filter,
                'after': num_genes,
                'dropped': genes_before_filter - num_genes
            }
        
    def generate_report(self, title: str, pvalue_threshold: float = 0.05) -> str:
        """
        Generate a formatted statistics report.
        
        Creates a comprehensive text report with sections for:
        - Summary statistics (totals, matches, unique counts)
        - Organism distribution
        - P-value filtering statistics (if applicable)
        
        Args:
            title (str): Title for the report
            pvalue_threshold (float): P-value threshold used for filtering
            
        Returns:
            str: Formatted multi-line report text
        """
        report_lines = [
            "=" * 80,
            f"{title}",
            "=" * 80,
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "SUMMARY STATISTICS",
            "-" * 80,
            f"Total signature files found:         {self.total_diseases}",
            f"Signatures successfully processed:   {self.diseases_processed}",
            f"Total genes exported:                {self.total_genes_exported}",
            "",
            "ORGANISM DISTRIBUTION",
            "-" * 80,
        ]
        
        if self.organism_counts:
            for organism, count in sorted(self.organism_counts.items()):
                report_lines.append(f"{organism:30s}: {count:5d} diseases")
        else:
            report_lines.append("No organism data available")
        
        # Add p-value filtering statistics if any diseases were filtered
        if self.pvalue_filter_stats:
            report_lines.extend([
                "",
                f"P-VALUE FILTERING STATISTICS (threshold: {pvalue_threshold})",
                "-" * 80,
                f"Diseases with p-value filtering:    {len(self.pvalue_filter_stats)}",
                ""
            ])
            
            # Calculate totals
            total_before = sum(stats['before'] for stats in self.pvalue_filter_stats.values())
            total_after = sum(stats['after'] for stats in self.pvalue_filter_stats.values())
            total_dropped = sum(stats['dropped'] for stats in self.pvalue_filter_stats.values())
            
            report_lines.extend([
                f"Total genes before filtering:        {total_before}",
                f"Total genes after filtering:         {total_after}",
                f"Total genes dropped:                 {total_dropped} ({100*total_dropped/total_before:.1f}%)",
                "",
                "PER-DISEASE FILTERING DETAILS:",
                "-" * 80,
            ])
            
            # Sort diseases by name for consistent reporting
            for disease_name in sorted(self.pvalue_filter_stats.keys()):
                stats = self.pvalue_filter_stats[disease_name]
                pct_dropped = 100 * stats['dropped'] / stats['before'] if stats['before'] > 0 else 0
                report_lines.append(
                    f"{disease_name:40s}: {stats['before']:6d} -> {stats['after']:6d} "
                    f"(dropped {stats['dropped']:5d}, {pct_dropped:5.1f}%)"
                )
                
        report_lines.append("=" * 80)
        return "\n".join(report_lines)

# --- Helper Functions ---

def clean_filename(sheet_name: str) -> str:
    """
    Cleans an Excel sheet name to be a safe CSV filename.
    Appends '_signature.csv' to match CREEDS format.
    """
    # Replace spaces with underscores
    safe_name = sheet_name.replace(' ', '_')
    # Remove any characters that aren't alphanumeric, underscore, or hyphen
    safe_name = re.sub(r'[^a-zA-Z0-9_-]', '', safe_name)
    return f"{safe_name}_signature.csv"

def find_column(df_columns: List[str], possibilities: List[str]) -> Optional[str]:
    """
    Finds the first matching column name from a list of possibilities,
    ignoring case.
    
    Args:
        df_columns (List[str]): Columns from the DataFrame.
        possibilities (List[str]): Lowercase column names to search for.
        
    Returns:
        Optional[str]: The original (cased) column name if found, else None.
    """
    lower_to_original_map = {col.lower(): col for col in df_columns}
    for col_name in possibilities:
        if col_name in lower_to_original_map:
            return lower_to_original_map[col_name]
    return None

def process_excel_to_csv(excel_path: str, output_dir: str) -> int:
    """
    Reads an Excel file and converts each sheet to a CSV file in the output_dir.
    
    Args:
        excel_path (str): Path to the input .xlsx file.
        output_dir (str): Directory to save the new .csv files.
        
    Returns:
        int: The number of sheets successfully converted.
    """
    print(f"Processing Excel file: {excel_path}")
    
    if not os.path.exists(excel_path):
        print(f"  - WARNING: Excel file not found: {excel_path}")
        return 0
    
    try:
        xls = pd.ExcelFile(excel_path)
    except Exception as e:
        print(f"  - ERROR: Could not read Excel file: {e}")
        return 0
        
    converted_count = 0
    for sheet_name in xls.sheet_names:
        try:
            df = pd.read_excel(xls, sheet_name=sheet_name)
            
            # Skip empty sheets
            if df.empty:
                print(f"  - WARNING: Skipping empty sheet: {sheet_name}")
                continue

            csv_filename = clean_filename(sheet_name)
            output_path = os.path.join(output_dir, csv_filename)
            
            df.to_csv(output_path, index=False)
            print(f"  -> Converted sheet '{sheet_name}' to '{csv_filename}'")
            converted_count += 1
        except Exception as e:
            print(f"  - ERROR: Failed to convert sheet '{sheet_name}': {e}")
            
    return converted_count

def calculate_aggregate_logfc(df: pd.DataFrame, logfc_columns: List[str]) -> pd.Series:
    """
    Calculate mean logFC from multiple logFC columns.
    
    Args:
        df (pd.DataFrame): DataFrame containing logFC columns
        logfc_columns (List[str]): List of column names containing logFC values
        
    Returns:
        pd.Series: Mean logFC values across all columns
    """
    # Convert to numeric, coercing errors to NaN
    logfc_data = df[logfc_columns].apply(pd.to_numeric, errors='coerce')
    # Calculate mean across columns, ignoring NaN
    return logfc_data.mean(axis=1)

def calculate_aggregate_pvalue(df: pd.DataFrame, pval_columns: List[str]) -> pd.Series:
    """
    Calculate minimum (most significant) p-value from multiple p-value columns.
    
    Args:
        df (pd.DataFrame): DataFrame containing p-value columns
        pval_columns (List[str]): List of column names containing p-values
        
    Returns:
        pd.Series: Minimum p-value across all columns
    """
    # Convert to numeric, coercing errors to NaN
    pval_data = df[pval_columns].apply(pd.to_numeric, errors='coerce')
    # Take minimum (most significant) p-value across columns, ignoring NaN
    return pval_data.min(axis=1)

def standardize_signature_csv(input_path: str, output_path: str, 
                             final_cols: List[str], pvalue_threshold: float = 0.05) -> Tuple[bool, int, Optional[int], bool]:
    """
    Reads a source CSV, standardizes its columns, and saves it to a new location.
    
    This function intelligently maps existing columns to the required format:
    ['gene_symbol', 'mean_logfc', 'median_logfc', 'common_experiment', 'organism']
    
    For files with multiple logFC columns (e.g., log2FC_pub1, log2FC_pub2), it:
    - Calculates the mean across all logFC columns for mean_logfc
    - Uses the mean for median_logfc and common_experiment as well
    
    For files with p-value columns, it filters genes to keep only statistically
    significant ones (p-value < threshold).
    
    Args:
        input_path (str): Path to the source .csv file.
        output_path (str): Path to save the standardized .csv file.
        final_cols (List[str]): The exact output columns required.
        pvalue_threshold (float): P-value threshold for filtering (default: 0.05)
        
    Returns:
        Tuple[bool, int, Optional[int], bool]: (Success boolean, number of genes after filtering, 
                                                 number of genes before filtering, was p-value filtered)
    """
    try:
        df = pd.read_csv(input_path)
        if df.empty:
            print(f"  - WARNING: Skipping empty file: {os.path.basename(input_path)}")
            return False, 0
    except Exception as e:
        print(f"  - ERROR: Could not read {os.path.basename(input_path)}: {e}")
        return False, 0

    df_out = pd.DataFrame()

    # 1. Find Gene Symbol Column
    gene_col_names = ['gene_symbol', 'symbol', 'gene', 'genesymbol']
    gene_col = find_column(df.columns, gene_col_names)
    
    if not gene_col:
        print(f"  - ERROR: No gene symbol column found in {os.path.basename(input_path)}. "
              f"Searched for: {gene_col_names}")
        return False, 0
        
    df_out['gene_symbol'] = df[gene_col]

    # 2. Find logFC Column(s)
    # First check if there's already a mean_logfc column
    if 'mean_logfc' in [col.lower() for col in df.columns]:
        mean_logfc_col = find_column(df.columns, ['mean_logfc'])
        df_out['mean_logfc'] = pd.to_numeric(df[mean_logfc_col], errors='coerce')
        print(f"  - Using existing 'mean_logfc' column")
    else:
        # Look for multiple logFC columns (e.g., log2FC_pub1, log2FC_pub2, log2FC_pub3)
        logfc_pattern = re.compile(r'log.*fc.*\d+', re.IGNORECASE)
        multi_logfc_cols = [col for col in df.columns if logfc_pattern.match(col)]
        
        if multi_logfc_cols:
            # Calculate mean from multiple logFC columns
            df_out['mean_logfc'] = calculate_aggregate_logfc(df, multi_logfc_cols)
            print(f"  - Calculated mean from {len(multi_logfc_cols)} logFC columns: {multi_logfc_cols}")
        else:
            # Fall back to single logFC column
            logfc_col_names = ['logfc', 'avg_logfc', 'avg_log2fc', 'log2foldchange', 
                             'log_fc', 'median_logfc', 'common_experiment']
            logfc_col = find_column(df.columns, logfc_col_names)
            
            if not logfc_col:
                print(f"  - ERROR: No logFC column found in {os.path.basename(input_path)}. "
                      f"Searched for: {logfc_col_names}")
                return False, 0
                
            df_out['mean_logfc'] = pd.to_numeric(df[logfc_col], errors='coerce')
            print(f"  - Mapping '{logfc_col}' -> logFC stats")

    # 3. Check for p-value columns and filter if present
    pval_filtered = False
    genes_before_pval_filter = len(df_out)
    
    # Look for p-value or adjusted p-value columns
    pval_col_names = ['p_val', 'pval', 'p_value', 'pvalue', 'p_val_adj', 'padj', 'p_adj', 'fdr']
    pval_col = find_column(df.columns, pval_col_names)
    
    # Also look for multiple p-value columns (e.g., padj_pub1, padj_pub2, padj_pub3)
    pval_pattern = re.compile(r'p.*adj.*\d+|padj.*\d+', re.IGNORECASE)
    multi_pval_cols = [col for col in df.columns if pval_pattern.match(col)]
    
    if pval_col:
        # Single p-value column found
        pval_series = pd.to_numeric(df[pval_col], errors='coerce')
        # Filter to keep only statistically significant genes
        sig_mask = pval_series < pvalue_threshold
        df_out = df_out[sig_mask].copy()
        pval_filtered = True
        print(f"  - Filtered by p-value column '{pval_col}' (threshold: {pvalue_threshold})")
    elif multi_pval_cols:
        # Multiple p-value columns found - use minimum (most significant)
        min_pval = calculate_aggregate_pvalue(df, multi_pval_cols)
        # Filter to keep only statistically significant genes
        sig_mask = min_pval < pvalue_threshold
        df_out = df_out[sig_mask].copy()
        pval_filtered = True
        print(f"  - Filtered by minimum p-value from {len(multi_pval_cols)} columns (threshold: {pvalue_threshold})")
    
    if pval_filtered:
        genes_after_pval_filter = len(df_out)
        dropped_pval = genes_before_pval_filter - genes_after_pval_filter
        print(f"  - Dropped {dropped_pval} genes with p-value >= {pvalue_threshold}")

    # 4. Map logFC to all required statistical columns
    df_out['median_logfc'] = df_out['mean_logfc']
    df_out['common_experiment'] = df_out['mean_logfc']

    # 5. Add Organism
    df_out['organism'] = 'human'

    # 6. Filter to final columns, clean up, and save
    try:
        # Ensure we only have the columns we want
        df_out = df_out[final_cols]
        
        # Drop rows with missing gene symbols or logfc values
        initial_count = len(df_out)
        df_out = df_out.dropna(subset=['gene_symbol', 'mean_logfc'])
        dropped_na = initial_count - len(df_out)
        
        # Remove duplicate genes, keeping the first entry
        df_out = df_out.drop_duplicates(subset=['gene_symbol'], keep='first')
        dropped_dup = initial_count - dropped_na - len(df_out)
        
        if dropped_na > 0 or dropped_dup > 0:
            print(f"  - Dropped {dropped_na} rows with missing values, {dropped_dup} duplicates")
        
        df_out.to_csv(output_path, index=False)
        return True, len(df_out), genes_before_pval_filter if pval_filtered else None, pval_filtered
        
    except Exception as e:
        print(f"  - ERROR: Failed to save standardized file {os.path.basename(output_path)}: {e}")
        return False, 0, None, False

# --- Main Execution ---

def main():
    """
    Main execution function to process Sirota Lab signatures.
    """
    # --- Configuration ---
    # Assume script is in 'tahoe_cmap_analysis/scripts/'
    # and data is in '../data/'
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # FIXED: Use old_sirota_lab_signatures as source directory
    source_dir = os.path.abspath(os.path.join(base_dir, '..', 'data', 'disease_signatures', 'old_sirota_lab_signatures'))
    
    # New directory for standardized output files
    output_dir = os.path.abspath(os.path.join(base_dir, '..', 'data', 'disease_signatures', 'sirota_lab_disease_signatures'))
    
    # Path to the report file
    reports_dir = os.path.abspath(os.path.join(base_dir, '..', 'reports'))
    report_path = os.path.join(reports_dir, "sirota_lab_signatures_report.txt")

    # The Excel file to be processed
    excel_file_path = os.path.join(source_dir, "LauraPaperSignature.xlsx")
    
    # The required final column structure
    FINAL_COLS = ['gene_symbol', 'mean_logfc', 'median_logfc', 'common_experiment', 'organism']
    
    # P-value threshold for statistical significance filtering
    PVALUE_THRESHOLD = 0.05  # Adjust this value to change stringency (e.g., 0.01 for more stringent)
    
    # --- End Configuration ---
    
    print("="*80)
    print("Sirota Lab Signature Processing Script")
    print("="*80)
    
    # Ensure output directories exist
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(reports_dir, exist_ok=True)
    
    stats = ProcessingStats()

    # --- Step 1: Convert Excel sheets to CSV files ---
    # Files are saved to the output_dir (not source_dir to avoid modifying source)
    print(f"\n[Step 1] Converting Excel sheets from:\n{excel_file_path}")
    converted_count = process_excel_to_csv(excel_file_path, output_dir)
    print(f"✓ Converted {converted_count} sheets to CSV.")
    
    # --- Step 2: Scan source directory for existing CSVs to process ---
    print(f"\n[Step 2] Scanning for CSV files in source directory:\n{source_dir}")
    try:
        source_csvs = [f for f in os.listdir(source_dir) 
                      if f.lower().endswith('.csv') and not f.startswith('~$')]
        print(f"✓ Found {len(source_csvs)} CSV files in source directory.")
    except Exception as e:
        print(f"✗ ERROR: Could not scan source directory: {e}")
        source_csvs = []

    # --- Step 3: Scan output directory for converted Excel sheets ---
    print(f"\n[Step 3] Scanning for converted CSV files in output directory:\n{output_dir}")
    try:
        converted_csvs = [f for f in os.listdir(output_dir) 
                         if f.lower().endswith('.csv') and not f.startswith('~$')]
        print(f"✓ Found {len(converted_csvs)} converted CSV files.")
    except Exception as e:
        print(f"✗ ERROR: Could not scan output directory: {e}")
        converted_csvs = []

    # Combine all files to process
    all_files_to_process = []
    
    # Add source CSVs with their paths
    for csv_file in source_csvs:
        all_files_to_process.append((os.path.join(source_dir, csv_file), csv_file, 'source'))
    
    # Add converted CSVs (already in output_dir, just need standardization)
    for csv_file in converted_csvs:
        all_files_to_process.append((os.path.join(output_dir, csv_file), csv_file, 'converted'))
    
    stats.total_diseases = len(all_files_to_process)
    print(f"\n✓ Total files to process: {stats.total_diseases}")

    # --- Step 4: Standardize all found CSVs ---
    print(f"\n[Step 4] Standardizing files and saving to:\n{output_dir}")
    
    for input_path, csv_filename, source_type in all_files_to_process:
        # For converted files, we'll overwrite them with standardized version
        output_path = os.path.join(output_dir, csv_filename)
        
        # Get a clean disease name from the filename for reporting
        disease_name = csv_filename.replace("_signature.csv", "").replace(".csv", "")
        
        print(f"\nProcessing [{source_type}]: {csv_filename}")
        
        success, gene_count, genes_before_filter, pval_filtered = standardize_signature_csv(input_path, output_path, FINAL_COLS, PVALUE_THRESHOLD)
        
        if success:
            # Record the successful processing
            stats.add_match(
                disease_name=disease_name,
                num_signatures=1,  # Each file is one signature
                num_genes=gene_count,
                organism="human",
                genes_before_filter=genes_before_filter,
                pval_filtered=pval_filtered
            )
            print(f"  ✓ Standardized {gene_count} genes -> {csv_filename}")
        else:
            print(f"  ✗ Failed to standardize {csv_filename}.")
            
    # --- Step 5: Generate and save final report ---
    print("\n[Step 5] Generating processing report...")
    try:
        report_title = "SIROTA LAB SIGNATURES - PROCESSING REPORT"
        report_content = stats.generate_report(report_title, PVALUE_THRESHOLD)
        
        with open(report_path, 'w') as f:
            f.write(report_content)
        
        print(f"✓ Report saved to: {report_path}")
        print("\n" + report_content)
        
    except Exception as e:
        print(f"✗ ERROR: Could not generate or save report: {e}")

    print("\n" + "="*80)
    print("Processing complete.")
    print("="*80)


if __name__ == "__main__":
    main()
