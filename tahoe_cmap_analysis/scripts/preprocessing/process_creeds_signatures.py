#!/usr/bin/env python3
"""
Process CREEDS Disease Signatures

Extracts and processes disease signatures from CREEDS database. Aggregates
gene expression data across experiments, calculates statistics, and exports
standardized signatures ready for drug discovery analysis.
"""

import json
import pandas as pd
from collections import defaultdict
import numpy as np
import os
import hashlib
from datetime import datetime
from typing import Optional, Dict, List, Set, Tuple


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
        
    def add_match(self, disease_name: str, num_signatures: int, num_genes: int, organism: str):
        """
        Record a successful disease match.
        
        Args:
            disease_name (str): Name of the matched disease
            num_signatures (int): Number of signatures found for this disease
            num_genes (int): Number of genes in the exported signature
            organism (str): Organism type (e.g., "human", "mouse")
        """
        self.diseases_processed += 1
        self.total_signatures_found += num_signatures
        self.total_genes_exported += num_genes
        self.disease_signature_counts[disease_name] = num_signatures
        self.organism_counts[organism] += 1
        self.unique_diseases_processed.add(disease_name.lower())
        
    def generate_report(self, title: str) -> str:
        """
        Generate a formatted statistics report.
        
        Creates a comprehensive text report with sections for:
        - Summary statistics (totals, matches, unique counts)
        - Organism distribution
        - Top diseases by signature count
        
        Args:
            title (str): Title for the report
            
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
            f"Total unique diseases found:         {self.total_diseases}",
            f"Diseases successfully processed:     {self.diseases_processed}",
            f"Unique diseases processed:           {len(self.unique_diseases_processed)}",
            f"Multi-disease entries split:         {self.multi_disease_entries}",
            f"Total signatures found:              {self.total_signatures_found}",
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
            
        report_lines.extend([
            "",
            "SIGNATURE COUNTS PER DISEASE (Top 20)",
            "-" * 80,
        ])
        
        if self.disease_signature_counts:
            # Sort by number of signatures (descending)
            sorted_diseases = sorted(
                self.disease_signature_counts.items(), 
                key=lambda x: x[1], 
                reverse=True
            )
            for disease, count in sorted_diseases[:20]:  # Top 20
                report_lines.append(f"{disease:50s}: {count:3d} signatures")
            if len(sorted_diseases) > 20:
                report_lines.append(f"... and {len(sorted_diseases) - 20} more diseases")
        else:
            report_lines.append("No diseases processed")
                
        report_lines.append("=" * 80)
        return "\n".join(report_lines)


def extract_all_diseases_from_json(
    json_path: str,
    output_dir: str,
    report_path: str,
    organism: Optional[str] = None,
    split_multi_disease: bool = True,
    only_common_genes: bool = False
) -> ProcessingStats:
    """
    Extract ALL diseases from CREEDS JSON database and export gene signatures.
    
    This function processes all diseases found in the CREEDS database:
    1. Loads the entire CREEDS JSON database
    2. Extracts all unique diseases (optionally splitting multi-disease entries)
    3. Aggregates gene expression data across experiments for each disease
    4. Exports individual CSV files for each disease
    5. Generates comprehensive statistics
    
    Args:
        json_path (str): Path to CREEDS JSON signature database
        output_dir (str): Directory where disease signature CSV files will be saved
        report_path (str): Path where the statistics report will be saved
        organism (Optional[str]): Filter signatures by organism (e.g., "human").
                                 If None, includes all organisms.
        split_multi_disease (bool): If True, split entries with multiple diseases
                                   (separated by |) into individual disease files.
                                   Default: True.
        only_common_genes (bool): If True, only export genes present in ALL 
                                 experiments for a disease. Default: False.
    
    Returns:
        ProcessingStats: Object containing comprehensive processing statistics
        
    Raises:
        FileNotFoundError: If JSON file doesn't exist
        ValueError: If JSON file cannot be read
        
    Output CSV Format:
        Each disease gets a separate CSV file with columns:
        - gene_symbol: Gene identifier
        - logfc_<sig_id>: Log-fold change for each signature
        - mean_logfc: Mean log-fold change across experiments
        - median_logfc: Median log-fold change across experiments
        - common_experiment: Log-fold change from most comprehensive experiment
        - organism: Source organism
    """
    stats = ProcessingStats()
    
    # Load JSON signature database
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"JSON signature database not found: {json_path}")
    except Exception as e:
        raise ValueError(f"Could not read JSON database {json_path}: {e}")

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Filter by organism if specified
    organism_filter_lower = organism.lower() if organism else None
    
    # Group signatures by disease
    disease_signatures = defaultdict(list)
    
    for entry in data:
        # Check organism filter
        entry_org = entry.get('organism', '')
        if isinstance(entry_org, list):
            entry_org = '|'.join(entry_org)
        entry_org = entry_org.lower() if entry_org else ''
        
        if organism_filter_lower and organism_filter_lower != entry_org:
            continue
        
        # Get disease name(s)
        disease_name = entry.get('disease_name')
        if not disease_name:
            continue
            
        # Handle list type
        if isinstance(disease_name, list):
            disease_name = '|'.join(disease_name)
        
        # Split multi-disease entries if requested
        if split_multi_disease and '|' in disease_name:
            stats.multi_disease_entries += 1
            # Split and process each disease separately
            individual_diseases = [d.strip() for d in disease_name.split('|')]
            for individual_disease in individual_diseases:
                if individual_disease:  # Skip empty strings
                    disease_signatures[individual_disease].append(entry)
        else:
            # Keep as-is
            disease_signatures[disease_name].append(entry)
    
    stats.total_diseases = len(disease_signatures)
    
    # Process each disease
    for disease_name, matched_entries in disease_signatures.items():
        if not matched_entries:
            continue

        # Aggregate gene signatures
        gene_logfc, top_experiment_id = aggregate_gene_signatures(
            matched_entries, only_common_genes
        )

        if not gene_logfc:
            continue

        # Create output DataFrame
        df_out = create_signature_dataframe(
            gene_logfc, top_experiment_id, organism if organism else "mixed"
        )

        # Export to CSV with safe filename handling
        safe_name = str(disease_name).replace(" ", "_").replace("/", "_").replace("\\", "_")
        safe_name = safe_name.replace("|", "_")  # Replace pipe characters
        
        # Truncate very long filenames and add hash for uniqueness
        max_filename_length = 200
        if len(safe_name) > max_filename_length:
            name_hash = hashlib.md5(disease_name.encode()).hexdigest()[:8]
            safe_name = safe_name[:max_filename_length] + "_" + name_hash
        
        output_path = os.path.join(output_dir, f"{safe_name}_signature.csv")
        df_out.to_csv(output_path, index=False)

        # Update statistics
        stats.add_match(
            disease_name, 
            len(matched_entries), 
            len(df_out), 
            organism if organism else "mixed"
        )

    return stats


def aggregate_gene_signatures(matched_entries: List[Dict], only_common_genes: bool = False) -> Tuple[Dict, str]:
    """
    Aggregate gene expression data across multiple signature experiments.
    
    Combines gene signatures from multiple experiments for the same disease:
    - Collects log-fold changes for each gene across all experiments
    - Identifies the most comprehensive experiment (highest gene count)
    - Optionally filters to genes common across all experiments
    
    Args:
        matched_entries (List[Dict]): List of signature entries to aggregate
        only_common_genes (bool): If True, only include genes present in ALL
                                 experiments. Default: False.
    
    Returns:
        Tuple[Dict, str]: 
            - gene_logfc: {gene: {sig_col: logfc}} nested dictionary
            - top_experiment_id: ID of the most comprehensive experiment
    """
    gene_logfc = defaultdict(dict)
    gene_sets = []
    experiment_gene_counts = {}

    for i, entry in enumerate(matched_entries):
        sig_id = entry.get("id", f"sig_{i}")
        sig_col = f"logfc_{sig_id}"
        this_sig_genes = set()

        # Process up and down regulated genes
        for gene_list in entry.get("up_genes", []) + entry.get("down_genes", []):
            if isinstance(gene_list, list) and len(gene_list) >= 2:
                gene, logfc = gene_list[0], gene_list[1]
                gene_logfc[gene][sig_col] = logfc
                this_sig_genes.add(gene)

        gene_sets.append(this_sig_genes)
        experiment_gene_counts[sig_id] = len(this_sig_genes)

    # Find experiment with most genes
    top_experiment_id = max(experiment_gene_counts, key=experiment_gene_counts.get) if experiment_gene_counts else None

    # Filter to common genes if specified
    if only_common_genes and gene_sets:
        common_genes = set.intersection(*gene_sets)
        gene_logfc = {g: d for g, d in gene_logfc.items() if g in common_genes}

    return gene_logfc, top_experiment_id


def create_signature_dataframe(gene_logfc: Dict, top_experiment_id: str, organism: str) -> pd.DataFrame:
    """
    Create a formatted DataFrame from aggregated gene signature data.
    
    Transforms the nested gene-signature dictionary into a structured DataFrame
    with calculated statistics:
    - Individual experiment log-fold changes
    - Mean log-fold change across experiments
    - Median log-fold change across experiments
    - Log-fold change from the most comprehensive experiment
    - Organism annotation
    
    Args:
        gene_logfc (Dict): Nested dictionary {gene: {sig_col: logfc}}
        top_experiment_id (str): ID of the most comprehensive experiment
        organism (str): Organism type for annotation
    
    Returns:
        pd.DataFrame: Formatted signature DataFrame with all columns
    """
    # Create base DataFrame
    df_out = pd.DataFrame.from_dict(gene_logfc, orient="index").reset_index()
    df_out.rename(columns={"index": "gene_symbol"}, inplace=True)

    # Calculate aggregate statistics
    logfc_cols = [col for col in df_out.columns if col.startswith("logfc_")]
    
    if logfc_cols:
        df_out["mean_logfc"] = df_out[logfc_cols].mean(axis=1, skipna=True)
        df_out["median_logfc"] = df_out[logfc_cols].median(axis=1, skipna=True)
    else:
        df_out["mean_logfc"] = np.nan
        df_out["median_logfc"] = np.nan

    # Add common_experiment column (from most comprehensive experiment)
    if top_experiment_id:
        top_col = f"logfc_{top_experiment_id}"
        df_out["common_experiment"] = df_out[top_col] if top_col in df_out.columns else np.nan
    else:
        df_out["common_experiment"] = np.nan

    # Add organism column
    df_out["organism"] = organism

    return df_out


def compare_disease_overlap(manual_stats: ProcessingStats, auto_stats: ProcessingStats, 
                           report_path: str) -> Dict[str, Set[str]]:
    """
    Compare diseases between manual and automatic signatures to find overlaps.
    
    Args:
        manual_stats (ProcessingStats): Statistics from manual signature processing
        auto_stats (ProcessingStats): Statistics from automatic signature processing
        report_path (str): Path where the overlap report will be saved
    
    Returns:
        Dict[str, Set[str]]: Dictionary with keys:
            - 'overlap': Diseases in both manual and automatic
            - 'manual_only': Diseases only in manual
            - 'auto_only': Diseases only in automatic
    """
    manual_diseases = manual_stats.unique_diseases_processed
    auto_diseases = auto_stats.unique_diseases_processed
    
    overlap = manual_diseases & auto_diseases
    manual_only = manual_diseases - auto_diseases
    auto_only = auto_diseases - manual_diseases
    
    # Generate overlap report
    report_lines = [
        "=" * 80,
        "CREEDS DISEASE OVERLAP ANALYSIS",
        "=" * 80,
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "SUMMARY",
        "-" * 80,
        f"Total diseases in MANUAL signatures:     {len(manual_diseases)}",
        f"Total diseases in AUTOMATIC signatures:  {len(auto_diseases)}",
        f"Diseases in BOTH datasets:               {len(overlap)}",
        f"Diseases ONLY in MANUAL:                 {len(manual_only)}",
        f"Diseases ONLY in AUTOMATIC:              {len(auto_only)}",
        "",
        f"Overlap percentage (of manual):          {len(overlap)/len(manual_diseases)*100:.1f}%",
        f"Overlap percentage (of automatic):       {len(overlap)/len(auto_diseases)*100:.1f}%",
        "",
    ]
    
    if overlap:
        report_lines.extend([
            "DISEASES IN BOTH MANUAL AND AUTOMATIC",
            "-" * 80,
        ])
        for disease in sorted(overlap):
            manual_sigs = manual_stats.disease_signature_counts.get(disease, 0)
            auto_sigs = auto_stats.disease_signature_counts.get(disease, 0)
            report_lines.append(f"{disease:50s} | Manual: {manual_sigs:3d} | Auto: {auto_sigs:3d}")
    
    if manual_only:
        report_lines.extend([
            "",
            f"DISEASES ONLY IN MANUAL ({len(manual_only)} diseases)",
            "-" * 80,
        ])
        for disease in sorted(list(manual_only)[:50]):  # Show first 50
            sigs = manual_stats.disease_signature_counts.get(disease, 0)
            report_lines.append(f"{disease:50s} | Signatures: {sigs:3d}")
        if len(manual_only) > 50:
            report_lines.append(f"... and {len(manual_only) - 50} more diseases")
    
    if auto_only:
        report_lines.extend([
            "",
            f"DISEASES ONLY IN AUTOMATIC ({len(auto_only)} diseases)",
            "-" * 80,
        ])
        for disease in sorted(list(auto_only)[:50]):  # Show first 50
            sigs = auto_stats.disease_signature_counts.get(disease, 0)
            report_lines.append(f"{disease:50s} | Signatures: {sigs:3d}")
        if len(auto_only) > 50:
            report_lines.append(f"... and {len(auto_only) - 50} more diseases")
    
    report_lines.append("=" * 80)
    
    # Save report
    with open(report_path, 'w') as f:
        f.write("\n".join(report_lines))
    
    return {
        'overlap': overlap,
        'manual_only': manual_only,
        'auto_only': auto_only
    }


def main():
    """
    Main execution function for processing CREEDS disease signatures.
    
    Processes both manual (v1.0) and automatic (p1.0) CREEDS signature sets:
    - Extracts ALL diseases from the JSON databases
    - Splits multi-disease entries into individual disease files
    - Exports individual disease signature files
    - Generates comprehensive statistics reports
    - Compares overlap between manual and automatic signatures
    - Saves reports to the reports/ directory
    
    The function handles errors gracefully and provides progress feedback.
    """
    
    # Define base paths
    creeds_base_dir = "../data/disease_signatures/CREEDS"
    output_base_dir = "../data/disease_signatures"
    reports_dir = "../reports"
    
    # Ensure reports directory exists
    os.makedirs(reports_dir, exist_ok=True)
    
    manual_stats = None
    auto_stats = None
    
    # Process MANUAL signatures (v1.0)
    print("\n" + "="*80)
    print("Processing MANUAL signatures (v1.0)")
    print("="*80)
    
    manual_json_path = os.path.join(creeds_base_dir, "disease_signatures-v1.0.json")
    manual_output_dir = os.path.join(output_base_dir, "creeds_manual_disease_signatures")
    manual_report_path = os.path.join(reports_dir, "creeds_manual_signatures_report.txt")
    
    try:
        manual_stats = extract_all_diseases_from_json(
            json_path=manual_json_path,
            output_dir=manual_output_dir,
            report_path=manual_report_path,
            organism="human",
            split_multi_disease=True,
            only_common_genes=False
        )
        
        # Generate and save report
        manual_report = manual_stats.generate_report("CREEDS MANUAL SIGNATURES (v1.0) - PROCESSING REPORT")
        with open(manual_report_path, 'w') as f:
            f.write(manual_report)
        print(f"✓ Total unique diseases found: {manual_stats.total_diseases}")
        print(f"✓ Diseases processed: {manual_stats.diseases_processed}")
        print(f"✓ Unique diseases: {len(manual_stats.unique_diseases_processed)}")
        print(f"✓ Multi-disease entries split: {manual_stats.multi_disease_entries}")
        print(f"✓ Report saved to: {manual_report_path}")
        
    except Exception as e:
        print(f"✗ Error processing manual signatures: {e}")

    # Process AUTOMATIC signatures (p1.0)
    print("\n" + "="*80)
    print("Processing AUTOMATIC signatures (p1.0)")
    print("="*80)
    
    auto_json_path = os.path.join(creeds_base_dir, "disease_signatures-p1.0.json")
    auto_output_dir = os.path.join(output_base_dir, "creeds_automatic_disease_signatures")
    auto_report_path = os.path.join(reports_dir, "creeds_automatic_signatures_report.txt")
    
    try:
        auto_stats = extract_all_diseases_from_json(
            json_path=auto_json_path,
            output_dir=auto_output_dir,
            report_path=auto_report_path,
            organism="human",
            split_multi_disease=True,
            only_common_genes=False
        )
        
        # Generate and save report
        auto_report = auto_stats.generate_report("CREEDS AUTOMATIC SIGNATURES (p1.0) - PROCESSING REPORT")
        with open(auto_report_path, 'w') as f:
            f.write(auto_report)
        print(f"✓ Total unique diseases found: {auto_stats.total_diseases}")
        print(f"✓ Diseases processed: {auto_stats.diseases_processed}")
        print(f"✓ Unique diseases: {len(auto_stats.unique_diseases_processed)}")
        print(f"✓ Multi-disease entries split: {auto_stats.multi_disease_entries}")
        print(f"✓ Report saved to: {auto_report_path}")
        
    except Exception as e:
        print(f"✗ Error processing automatic signatures: {e}")
    
    # Compare overlap between manual and automatic
    if manual_stats and auto_stats:
        print("\n" + "="*80)
        print("Comparing MANUAL vs AUTOMATIC overlap")
        print("="*80)
        
        overlap_report_path = os.path.join(reports_dir, "creeds_manual_vs_automatic_overlap.txt")
        
        try:
            overlap_results = compare_disease_overlap(manual_stats, auto_stats, overlap_report_path)
            print(f"✓ Diseases in BOTH datasets: {len(overlap_results['overlap'])}")
            print(f"✓ Diseases ONLY in MANUAL: {len(overlap_results['manual_only'])}")
            print(f"✓ Diseases ONLY in AUTOMATIC: {len(overlap_results['auto_only'])}")
            print(f"✓ Overlap report saved to: {overlap_report_path}")
        except Exception as e:
            print(f"✗ Error comparing overlap: {e}")
    
    print("\n" + "="*80)
    print("All processing complete!")
    print("="*80)


if __name__ == "__main__":
    main()
