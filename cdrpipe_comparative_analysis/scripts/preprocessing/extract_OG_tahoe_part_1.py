#!/usr/bin/env python3
"""
Tahoe Signatures Part 1: Extract and Filter

HPC-optimized extraction of Tahoe H5 drug signature data. Reads L2FC matrix
and optional p-value filtering to produce parquet checkpoint for ranking.
Handles large-scale data with memory-efficient processing.
"""

import os
import sys
import gc
import argparse
import logging
import psutil
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import tables as tb
import pyarrow as pa
import pyarrow.parquet as pq
from tqdm import tqdm
from joblib import Parallel, delayed

# Define chunk size for safely reading the large p-value matrix
P_VALUE_CHUNK_SIZE = 1000 

# =========================================================
# Logging Setup
# =========================================================
def setup_logging(log_dir, job_name="tahoe_signatures_part1"):
    """Set up comprehensive logging to both file and console."""
    log_dir = Path(log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{job_name}_{timestamp}.log"
    
    # Create formatters
    file_formatter = logging.Formatter(
        '%(asctime)s | %(levelname)-8s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_formatter = logging.Formatter('%(levelname)s: %(message)s')
    
    # File handler
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(file_formatter)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(console_formatter)
    
    # Root logger
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    logging.info(f"Logging initialized. Log file: {log_file}")
    return log_file

# =========================================================
# Resource Monitoring
# =========================================================
def log_system_resources():
    """Log current system resource usage."""
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    logging.info("="*60)
    logging.info("SYSTEM RESOURCES:")
    logging.info(f"  CPU cores available: {psutil.cpu_count()}")
    logging.info(f"  RAM: {mem.total / (1024**3):.1f} GB total, "
                f"{mem.available / (1024**3):.1f} GB available "
                f"({mem.percent}% used)")
    logging.info(f"  Disk: {disk.total / (1024**3):.1f} GB total, "
                f"{disk.free / (1024**3):.1f} GB free "
                f"({disk.percent}% used)")
    logging.info("="*60)

def estimate_memory_requirement(n_genes, n_experiments):
    """Estimate memory requirement for the dataset."""
    base_size_gb = (n_genes * n_experiments * 4) / (1024**3)
    estimated_peak_gb = base_size_gb * 1.5 
    
    logging.info(f"Memory estimation for Part 1:")
    logging.info(f"  Filtered Dataset size: {base_size_gb:.2f} GB")
    logging.info(f"  Estimated peak usage: {estimated_peak_gb:.2f} GB")
    
    mem = psutil.virtual_memory()
    available_gb = mem.available / (1024**3)
    
    if estimated_peak_gb > available_gb * 0.8:
        logging.warning(f" WARNING: Estimated memory usage ({estimated_peak_gb:.1f} GB) "
                       f"is close to or exceeds available RAM ({available_gb:.1f} GB)")
        logging.warning(" Consider using a node with more memory or processing in smaller chunks")
    else:
        logging.info(f"Sufficient memory available ({available_gb:.1f} GB)")
    
    return estimated_peak_gb

def check_disk_space(output_dir, required_gb):
    """Check if sufficient disk space is available."""
    check_path = output_dir
    while not os.path.exists(check_path):
        parent = os.path.dirname(check_path)
        if parent == check_path or not parent:
            check_path = '/'
            break
        check_path = parent
    
    disk = psutil.disk_usage(check_path)
    available_gb = disk.free / (1024**3)
    
    if available_gb < required_gb:
        logging.error(f"Insufficient disk space! Need {required_gb:.1f} GB, "
                     f"only {available_gb:.1f} GB available")
        return False
    
    logging.info(f"Sufficient disk space: {available_gb:.1f} GB available (checked at: {check_path})")
    return True

# =========================================================
# Argument Parsing 
# =========================================================
def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Part 1: Convert Tahoe H5 to Parquet (HPC-optimized)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Input paths
    parser.add_argument(
        "--h5-file",
        default="../data/drug_signatures/tahoe/aggregated.h5",
        help="Path to Tahoe H5 file"
    )
    parser.add_argument(
        "--genes-file",
        default="../data/drug_signatures/tahoe/genes.parquet",
        help="Path to genes Parquet file"
    )
    parser.add_argument(
        "--experiments-file",
        default="../data/drug_signatures/tahoe/experiments.parquet",
        help="Path to experiments Parquet file"
    )
    
    # NEW FILTER PARAMETERS
    # Example usage to enable: python script.py --enable-filter
    parser.add_argument(
        "--enable-filter",
        action="store_true",
        # COMMENT: If this flag is present in the command, args.enable_filter will be True. 
        # If omitted, it will be False.
        help="Set this flag to enable adjusted p-value (padj) filtration."
    )
    parser.add_argument(
        "--padj-threshold",
        type=float,
        default=0.05,
        help="Maximum adjusted p-value for a gene to be considered significant in ANY experiment."
    )
    # End NEW FILTER PARAMETERS
    
    # Output paths
    parser.add_argument(
        "--intermediate-dir",
        default="../data/intermediate_hpc",
        help="Directory for intermediate files"
    )
    parser.add_argument(
        "--log-dir",
        default="../logs",
        help="Directory for log files"
    )
    
    # Processing parameters
    parser.add_argument(
        "--n-cores",
        type=int,
        default=None,
        help="Number of CPU cores to use (default: use $NSLOTS or all-1)"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force reprocessing even if output files exist"
    )
    
    return parser.parse_args()

# =========================================================
# Core Processing Functions 
# =========================================================
def process_h5_chunk(row_indices_chunk, h5_path, col_sorted, col_unsort, schema):
    """
    Process a chunk of rows (experiments) from H5 L2FC file in parallel.
    """
    try:
        with tb.open_file(h5_path, mode="r") as h5:
            node = h5.get_node("/l2fc")
            
            # Read assigned rows
            block_full = np.empty((len(row_indices_chunk), node.shape[1]), dtype=node.dtype)
            for i, row_idx in enumerate(row_indices_chunk):
                # Ensure we only read the rows present in the experiments file
                block_full[i, :] = node[row_idx, :]
            
            # Filter columns: This selects only the genes kept after padj filtering
            block_cols_sorted = np.take(block_full, col_sorted, axis=1)
            block_cols = block_cols_sorted[:, col_unsort]
            
            # Convert to PyArrow table
            arrs = [pa.array(row_indices_chunk.astype(np.int32))] + [
                pa.array(block_cols[:, j], type=pa.float32()) 
                for j in range(block_cols.shape[1])
            ]
            batch = pa.table(arrs, schema=schema)
            
            return batch
    except Exception as e:
        logging.error(f"Error processing chunk: {e}")
        raise

def part1_h5_to_parquet(args):
    """
    Part 1: Convert H5 file to Parquet format, optionally applying P-value filtration.
    """
    logging.info("\n" + "="*80)
    logging.info("PART 1: Convert H5 to Parquet (Optional Filtering)")
    logging.info("="*80)
    
    output_file = Path(args.intermediate_dir) / "tahoe_l2fc_all_genes_all_drugs.parquet"
    
    if output_file.exists() and not args.force:
        logging.info(f"Part 1 output already exists: {output_file}")
        logging.info("  Use --force to reprocess")
        return output_file
    
    # Validate inputs
    for path, name in [(args.h5_file, "H5"), (args.genes_file, "Genes"), 
                       (args.experiments_file, "Experiments")]:
        if not Path(path).exists():
            raise FileNotFoundError(f"{name} file not found: {path}")

    # Load gene and experiment information
    tahoe_genes_all = pd.read_parquet(args.genes_file)
    n_genes_all = len(tahoe_genes_all)
    experiments = pd.read_parquet(args.experiments_file)
    row_idx_keep = experiments["experiment_id"].astype(int).tolist()
    n_experiments = len(row_idx_keep)

    logging.info(f"Found {n_genes_all:,} total genes and {n_experiments:,} experiments.")
    
    # =========================================================================
    # CONDITIONAL P-ADJUSTED FILTRATION LOGIC
    # =========================================================================
    
    if args.enable_filter:
        logging.info("\n" + "-"*80)
        logging.info(f"ADJUSTED P-VALUE FILTER ENABLED: Threshold <= {args.padj_threshold}")
        col_idx_keep = []
        
        try:
            with tb.open_file(args.h5_file, mode="r") as h5:
                if '/padj' not in h5:
                    logging.warning("WARNING: '/padj' node not found in H5. Disabling P-value filter.")
                    # Fallback to keep all genes
                    col_idx_keep = sorted(tahoe_genes_all["gene_idx"].unique().tolist())
                else:
                    padj_node = h5.get_node("/padj")
                    n_rows_padj, n_cols_padj = padj_node.shape
                    
                    if n_cols_padj != n_genes_all:
                         raise ValueError("P-value matrix columns mismatch with gene metadata.")
                    
                    # Initialize a boolean array indicating if *any* p-value for a gene is significant
                    is_significant = np.zeros(n_cols_padj, dtype=bool)
                    
                    # Memory-safe chunked reading of the p-adj matrix (Row-wise)
                    logging.info(f"Chunked reading of /padj (Chunk size: {P_VALUE_CHUNK_SIZE})...")
                    for start in tqdm(range(0, n_rows_padj, P_VALUE_CHUNK_SIZE), desc="P-value Chunk"):
                        end = min(start + P_VALUE_CHUNK_SIZE, n_rows_padj)
                        padj_chunk = padj_node[start:end, :]
                        
                        # Update 'is_significant': keep a gene (column) if it's significant in ANY experiment
                        is_significant = is_significant | np.any(padj_chunk <= args.padj_threshold, axis=0)
                        
                        if np.all(is_significant):
                            logging.info("All genes found significant. Stopping chunked read early.")
                            break
                        
                        del padj_chunk
                        gc.collect()

                    # Get the original gene indices corresponding to the 'True' values
                    all_indices_in_h5_order = tahoe_genes_all.sort_values("gene_idx")["gene_idx"].to_numpy()
                    kept_indices_in_h5_order = all_indices_in_h5_order[is_significant]
                    
                    # Filter metadata and get final list of gene indices
                    tahoe_genes_filtered = tahoe_genes_all[
                        tahoe_genes_all["gene_idx"].isin(kept_indices_in_h5_order)
                    ]
                    col_idx_keep = sorted(tahoe_genes_filtered["gene_idx"].unique().tolist())

        except Exception as e:
            logging.error(f"Critical error during p-value filtering: {e}")
            raise

    else:
        # DEFAULT: Filter is NOT enabled, keep ALL genes
        logging.info("ADJUSTED P-VALUE FILTER DISABLED. Keeping ALL genes.")
        col_idx_keep = sorted(tahoe_genes_all["gene_idx"].unique().tolist())
        tahoe_genes_filtered = tahoe_genes_all
    
    # Finalize filtered lists and checks
    col_names_keep = tahoe_genes_filtered.sort_values("gene_idx")["gene_name"].tolist()
    n_genes = len(col_idx_keep)
    
    if args.enable_filter:
        logging.info(f"  Genes kept after filter: {n_genes:,} (from {n_genes_all:,} total)")
        logging.info("-" * 80 + "\n")

    if n_genes == 0:
         raise RuntimeError("No genes kept. Check filter threshold or input files.")
    
    # =========================================================================
    # CONTINUE WITH CORE PROCESSING (using filtered col_idx_keep)
    # =========================================================================

    # Estimate resources
    estimate_memory_requirement(n_genes, n_experiments)
    required_disk_gb = (n_genes * n_experiments * 4 * 1.5) / (1024**3)
    if not check_disk_space(args.intermediate_dir, required_disk_gb):
        raise RuntimeError("Insufficient disk space")
    
    # Prepare for parallel processing
    logging.info("Preparing parallel processing...")
    row_sorted = np.sort(np.asarray(row_idx_keep, dtype=np.int64))
    col_idx_keep_arr = np.asarray(col_idx_keep, dtype=np.int64)
    col_order = np.argsort(col_idx_keep_arr)
    col_sorted = col_idx_keep_arr[col_order]
    col_unsort = np.argsort(col_order)
    
    schema = pa.schema(
        [pa.field("experiment_id", pa.int32())] +
        [pa.field(name, pa.float32()) for name in col_names_keep]
    )
    
    # Determine number of cores
    if args.n_cores:
        n_cores = args.n_cores
    elif 'NSLOTS' in os.environ:
        n_cores = int(os.environ['NSLOTS'])
        logging.info(f"Using $NSLOTS={n_cores} cores from HPC scheduler")
    else:
        n_cores = max(1, psutil.cpu_count() - 1)
    
    logging.info(f"Using {n_cores} CPU cores for parallel processing")
    
    # Split work into chunks
    row_chunks = np.array_split(row_sorted, n_cores)
    
    # Process in parallel
    logging.info("Processing H5 L2FC data in parallel...")
    start_time = datetime.now()
    
    with Parallel(n_jobs=n_cores, verbose=10) as parallel:
        results = parallel(
            delayed(process_h5_chunk)(chunk, args.h5_file, col_sorted, col_unsort, schema)
            for chunk in row_chunks
        )
    
    # Write results
    logging.info("Writing results to Parquet...")
    Path(args.intermediate_dir).mkdir(parents=True, exist_ok=True)
    
    with pq.ParquetWriter(output_file, schema, compression="zstd") as writer:
        for batch in results:
            writer.write_table(batch)
    
    elapsed = (datetime.now() - start_time).total_seconds()
    file_size_gb = output_file.stat().st_size / (1024**3)
    
    logging.info(f"Part 1 complete in {elapsed/60:.1f} minutes")
    logging.info(f"   Output: {output_file} ({file_size_gb:.2f} GB)")
    
    # Cleanup
    del results, row_chunks, tahoe_genes_all, experiments
    gc.collect()
    
    return output_file

# =========================================================
# Main Execution
# =========================================================
def main():
    """Main execution function."""
    args = parse_arguments()
    
    # Setup logging
    log_file = setup_logging(args.log_dir)
    
    logging.info("="*80)
    logging.info("HPC-Optimized Tahoe Signature Creation Pipeline - PART 1 ONLY")
    logging.info("="*80)
    logging.info(f"Start time: {datetime.now()}")
    logging.info(f"Working directory: {os.getcwd()}")
    logging.info(f"Log file: {log_file}")
    
    # Log configuration
    logging.info("\nConfiguration:")
    for key, value in vars(args).items():
        if key not in ["gene_map_file", "output_dir", "rank_chunk_size", "skip_part1", "skip_part2"]:
             logging.info(f"  {key}: {value}")
    
    # Log system resources
    log_system_resources()
    
    try:
        # Part 1: H5 to Parquet
        parquet_file = part1_h5_to_parquet(args)
        
        # Final summary and result
        logging.info("\n" + "="*80)
        logging.info("STEP COMPLETED SUCCESSFULLY!")
        logging.info("="*80)
        logging.info(f"End time: {datetime.now()}")
        logging.info(f"RESULT: Intermediate Parquet file saved at: **{parquet_file}**")
        logging.info("This is the end of this step and script.")
        
        log_system_resources()
        
    except Exception as e:
        logging.error(f"\nSTEP FAILED: {e}", exc_info=True)
        logging.error(f"Check log file for details: {log_file}")
        sys.exit(1)

if __name__ == "__main__":
    main()