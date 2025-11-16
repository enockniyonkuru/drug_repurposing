#!/usr/bin/env python3
"""
HPC-Optimized Script: Create Tahoe OG Signatures
=================================================

This script processes Tahoe H5 data to create ranked gene signatures compatible
with CMap format. Optimized for HPC environments with:
- Command-line arguments
- Checkpointing
- Resource monitoring
- Comprehensive logging
- Error handling

Author: Drug Repurposing Pipeline
Version: 2.0 (HPC-optimized)
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
import pyreadr
from tqdm import tqdm
from joblib import Parallel, delayed

# =========================================================
# Logging Setup
# =========================================================
def setup_logging(log_dir, job_name="tahoe_signatures"):
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
    # Each float32 = 4 bytes
    # Need memory for: original data + transposed + ranked + overhead
    base_size_gb = (n_genes * n_experiments * 4) / (1024**3)
    estimated_peak_gb = base_size_gb * 3.5  # Conservative estimate
    
    logging.info(f"Memory estimation:")
    logging.info(f"  Dataset size: {base_size_gb:.2f} GB")
    logging.info(f"  Estimated peak usage: {estimated_peak_gb:.2f} GB")
    
    mem = psutil.virtual_memory()
    available_gb = mem.available / (1024**3)
    
    if estimated_peak_gb > available_gb * 0.8:
        logging.warning(f"⚠️  WARNING: Estimated memory usage ({estimated_peak_gb:.1f} GB) "
                       f"is close to or exceeds available RAM ({available_gb:.1f} GB)")
        logging.warning("⚠️  Consider using a node with more memory or processing in smaller chunks")
    else:
        logging.info(f"✓ Sufficient memory available ({available_gb:.1f} GB)")
    
    return estimated_peak_gb

def check_disk_space(output_dir, required_gb):
    """Check if sufficient disk space is available."""
    # If directory doesn't exist, check parent directory or root
    check_path = output_dir
    while not os.path.exists(check_path):
        parent = os.path.dirname(check_path)
        if parent == check_path or not parent:  # Reached root
            check_path = '/'
            break
        check_path = parent
    
    disk = psutil.disk_usage(check_path)
    available_gb = disk.free / (1024**3)
    
    if available_gb < required_gb:
        logging.error(f"❌ Insufficient disk space! Need {required_gb:.1f} GB, "
                     f"only {available_gb:.1f} GB available")
        return False
    
    logging.info(f"✓ Sufficient disk space: {available_gb:.1f} GB available (checked at: {check_path})")
    return True

# =========================================================
# Argument Parsing
# =========================================================
def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Create Tahoe OG signatures for drug repurposing (HPC-optimized)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Input paths (relative to tahoe_cmap_analysis/scripts/)
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
    parser.add_argument(
        "--gene-map-file",
        default="../data/gene_id_conversion_table.tsv",
        help="Path to gene name → Entrez ID mapping file"
    )
    
    # Output paths
    parser.add_argument(
        "--intermediate-dir",
        default="../data/intermediate_hpc",
        help="Directory for intermediate files"
    )
    parser.add_argument(
        "--output-dir",
        default="../data/drug_signatures/tahoe",
        help="Directory for final output"
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
        "--rank-chunk-size",
        type=int,
        default=512,
        help="Chunk size for ranking operations"
    )
    parser.add_argument(
        "--skip-part1",
        action="store_true",
        help="Skip Part 1 (H5 to Parquet conversion) if already completed"
    )
    parser.add_argument(
        "--skip-part2",
        action="store_true",
        help="Skip Part 2 (ranking and RData creation) if already completed"
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
    Process a chunk of rows from H5 file in parallel.
    
    Parameters:
    -----------
    row_indices_chunk : array
        Row indices to process
    h5_path : str
        Path to H5 file
    col_sorted : array
        Sorted column indices
    col_unsort : array
        Unsort indices for columns
    schema : pyarrow.Schema
        Schema for output table
    
    Returns:
    --------
    pyarrow.Table
        Processed data chunk
    """
    try:
        with tb.open_file(h5_path, mode="r") as h5:
            node = h5.get_node("/l2fc")
            
            # Read assigned rows
            block_full = np.empty((len(row_indices_chunk), node.shape[1]), dtype=node.dtype)
            for i, row_idx in enumerate(row_indices_chunk):
                block_full[i, :] = node[row_idx, :]
            
            # Filter columns
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
    Part 1: Convert H5 file to Parquet format.
    
    This streams data from H5 in parallel and writes to Parquet.
    """
    logging.info("\n" + "="*80)
    logging.info("🚀 PART 1: Convert H5 to Parquet (All Genes, All Experiments)")
    logging.info("="*80)
    
    output_file = Path(args.intermediate_dir) / "tahoe_l2fc_all_genes_all_drugs.parquet"
    
    # Check if already completed
    if output_file.exists() and not args.force:
        logging.info(f"✓ Part 1 output already exists: {output_file}")
        logging.info("  Use --force to reprocess or --skip-part1 to skip")
        return output_file
    
    # Validate inputs
    for path, name in [(args.h5_file, "H5"), (args.genes_file, "Genes"), 
                       (args.experiments_file, "Experiments")]:
        if not Path(path).exists():
            raise FileNotFoundError(f"{name} file not found: {path}")
    
    # Load gene information
    logging.info("Loading gene information...")
    tahoe_genes = pd.read_parquet(args.genes_file)
    col_idx_keep = sorted(tahoe_genes["gene_idx"].unique().tolist())
    col_names_keep = tahoe_genes.sort_values("gene_idx")["gene_name"].tolist()
    n_genes = len(col_idx_keep)
    logging.info(f"  Found {n_genes:,} genes")
    
    # Load experiment information
    logging.info("Loading experiment information...")
    experiments = pd.read_parquet(args.experiments_file)
    row_idx_keep = experiments["experiment_id"].astype(int).tolist()
    n_experiments = len(row_idx_keep)
    logging.info(f"  Found {n_experiments:,} experiments")
    
    # Estimate resources
    estimate_memory_requirement(n_genes, n_experiments)
    required_disk_gb = (n_genes * n_experiments * 4 * 2) / (1024**3)  # 2x for safety
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
    logging.info("Processing H5 data in parallel...")
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
    
    logging.info(f"✅ Part 1 complete in {elapsed/60:.1f} minutes")
    logging.info(f"   Output: {output_file} ({file_size_gb:.2f} GB)")
    
    # Cleanup
    del results, row_chunks, tahoe_genes, experiments
    gc.collect()
    
    return output_file

def part2_rank_and_save(args, parquet_file):
    """
    Part 2: Load Parquet, rank genes, and save as RData.
    
    This is the memory-intensive part.
    """
    logging.info("\n" + "="*80)
    logging.info("📊 PART 2: Load, Rank, and Save RData")
    logging.info("⚠️  WARNING: This part requires substantial RAM")
    logging.info("="*80)
    
    output_file = Path(args.output_dir) / "tahoe_signatures.RData"
    
    # Check if already completed
    if output_file.exists() and not args.force:
        logging.info(f"✓ Part 2 output already exists: {output_file}")
        logging.info("  Use --force to reprocess")
        return output_file
    
    # Validate gene mapping file
    if not Path(args.gene_map_file).exists():
        raise FileNotFoundError(f"Gene mapping file not found: {args.gene_map_file}")
    
    # Load data
    logging.info("Loading intermediate Parquet file...")
    logging.info(f"  File: {parquet_file}")
    start_time = datetime.now()
    
    l2fc_df = pd.read_parquet(parquet_file)
    logging.info(f"  Loaded shape: {l2fc_df.shape}")
    logging.info(f"  Load time: {(datetime.now() - start_time).total_seconds():.1f}s")
    
    if "experiment_id" in l2fc_df.columns:
        l2fc_df = l2fc_df.set_index("experiment_id")
    
    # Load gene mapping
    logging.info("Loading gene name → Entrez ID mapping...")
    gene_map = pd.read_csv(args.gene_map_file, sep='\t')
    gene_map = gene_map.dropna(subset=['Gene_name', 'entrezID'])
    gene_map = gene_map.drop_duplicates(subset=['Gene_name'])
    gene_name_to_entrez = dict(zip(gene_map["Gene_name"], gene_map["entrezID"]))
    logging.info(f"  Loaded {len(gene_name_to_entrez):,} gene mappings")
    
    # Transpose (MEMORY BOTTLENECK)
    logging.info("Transposing data (genes × experiments)...")
    logging.info("  ⚠️  This is the memory bottleneck - monitor RAM usage!")
    log_system_resources()
    
    start_time = datetime.now()
    transposed = l2fc_df.T
    logging.info(f"  Transposed shape: {transposed.shape}")
    logging.info(f"  Transpose time: {(datetime.now() - start_time).total_seconds():.1f}s")
    
    del l2fc_df
    gc.collect()
    log_system_resources()
    
    # Map to Entrez IDs
    logging.info("Mapping gene names to Entrez IDs...")
    transposed["entrezID"] = transposed.index.map(gene_name_to_entrez)
    
    n_before = len(transposed)
    transposed = transposed.dropna(subset=["entrezID"])
    n_after = len(transposed)
    logging.info(f"  Mapped {n_after:,} / {n_before:,} genes ({100*n_after/n_before:.1f}%)")
    
    transposed["entrezID"] = pd.to_numeric(transposed["entrezID"], errors="coerce").astype("Int64")
    transposed = transposed.dropna(subset=["entrezID"])
    transposed["entrezID"] = transposed["entrezID"].astype(int)
    
    # Collapse duplicate Entrez IDs
    logging.info("Collapsing duplicate Entrez IDs (taking mean)...")
    n_before = len(transposed)
    transposed = transposed.groupby("entrezID").mean(numeric_only=True)
    n_after = len(transposed)
    logging.info(f"  Collapsed to {n_after:,} unique Entrez IDs (from {n_before:,})")
    
    # Rank genes (chunked to manage memory)
    logging.info(f"Ranking genes (chunk size: {args.rank_chunk_size})...")
    cols = transposed.columns
    n_chunks = (len(cols) + args.rank_chunk_size - 1) // args.rank_chunk_size
    
    ranked_chunks = []
    for start in tqdm(range(0, len(cols), args.rank_chunk_size), 
                     desc="Ranking chunks", total=n_chunks):
        end = min(start + args.rank_chunk_size, len(cols))
        sub_df = transposed.iloc[:, start:end]
        sub_rank = sub_df.rank(axis=0, method="first", ascending=False, na_option="bottom")
        ranked_chunks.append(sub_rank.astype("int32"))
        del sub_df, sub_rank
        gc.collect()
    
    logging.info("Concatenating ranked chunks...")
    ranked_matrix = pd.concat(ranked_chunks, axis=1)
    del ranked_chunks, transposed
    gc.collect()
    
    logging.info(f"  Final ranked matrix shape: {ranked_matrix.shape}")
    
    # Convert to CMap format
    logging.info("Converting to CMap-like format...")
    cmap_like = pd.DataFrame({"V1": ranked_matrix.index})
    
    for j, col in enumerate(tqdm(ranked_matrix.columns, desc="Converting columns"), start=2):
        cmap_like[f"V{j}"] = ranked_matrix[col].to_numpy()
    
    del ranked_matrix
    gc.collect()
    
    # Save RData
    logging.info(f"Saving RData file: {output_file}")
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)
    
    start_time = datetime.now()
    pyreadr.write_rdata(str(output_file), {"tahoe_signatures": cmap_like})
    elapsed = (datetime.now() - start_time).total_seconds()
    file_size_gb = output_file.stat().st_size / (1024**3)
    
    logging.info(f"✅ Part 2 complete in {elapsed/60:.1f} minutes")
    logging.info(f"   Output: {output_file} ({file_size_gb:.2f} GB)")
    logging.info(f"   Final shape: {cmap_like.shape}")
    
    del cmap_like
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
    logging.info("HPC-Optimized Tahoe Signature Creation Pipeline")
    logging.info("="*80)
    logging.info(f"Start time: {datetime.now()}")
    logging.info(f"Working directory: {os.getcwd()}")
    logging.info(f"Log file: {log_file}")
    
    # Log configuration
    logging.info("\nConfiguration:")
    for key, value in vars(args).items():
        logging.info(f"  {key}: {value}")
    
    # Log system resources
    log_system_resources()
    
    try:
        # Part 1: H5 to Parquet
        if not args.skip_part1:
            parquet_file = part1_h5_to_parquet(args)
        else:
            parquet_file = Path(args.intermediate_dir) / "tahoe_l2fc_all_genes_all_drugs.parquet"
            logging.info(f"Skipping Part 1, using existing file: {parquet_file}")
            if not parquet_file.exists():
                raise FileNotFoundError(f"Intermediate file not found: {parquet_file}")
        
        # Part 2: Rank and save
        if not args.skip_part2:
            output_file = part2_rank_and_save(args, parquet_file)
        else:
            output_file = Path(args.output_dir) / "tahoe_signatures.RData"
            logging.info(f"Skipping Part 2, output should be at: {output_file}")
        
        # Final summary
        logging.info("\n" + "="*80)
        logging.info("✅✅✅ PIPELINE COMPLETED SUCCESSFULLY! ✅✅✅")
        logging.info("="*80)
        logging.info(f"End time: {datetime.now()}")
        logging.info(f"Log file: {log_file}")
        
        if not args.skip_part2 and output_file.exists():
            logging.info(f"Final output: {output_file}")
            logging.info(f"File size: {output_file.stat().st_size / (1024**3):.2f} GB")
        
        log_system_resources()
        
    except Exception as e:
        logging.error(f"\n❌ PIPELINE FAILED: {e}", exc_info=True)
        logging.error(f"Check log file for details: {log_file}")
        sys.exit(1)

if __name__ == "__main__":
    main()
