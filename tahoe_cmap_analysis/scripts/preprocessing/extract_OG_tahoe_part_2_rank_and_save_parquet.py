#!/usr/bin/env python3
"""
Tahoe Signatures Part 2: Rank and Checkpoint

Ranks gene expression signatures across all experiments with Entrez ID mapping.
Produces stable parquet checkpoint for downstream RData conversion. Handles
memory-intensive operations with parallel processing.
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
import pyreadr
from tqdm import tqdm

# =========================================================
# Logging Setup
# =========================================================
def setup_logging(log_dir, job_name="hpc_part2_rank_fix"):
    """Set up comprehensive logging."""
    log_dir = Path(log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{job_name}_{timestamp}.log"
    
    # Formatters
    file_formatter = logging.Formatter(
        '%(asctime)s | %(levelname)-8s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_formatter = logging.Formatter('%(levelname)s: %(message)s')
    
    # Handlers
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(file_formatter)
    
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
    logging.info("="*60)
    logging.info("SYSTEM RESOURCES:")
    logging.info(f"  CPU cores available: {psutil.cpu_count()}")
    logging.info(f"  RAM: {mem.total / (1024**3):.1f} GB total, "
                f"{mem.available / (1024**3):.1f} GB available "
                f"({mem.percent}% used)")
    logging.info("="*60)

# =========================================================
# Argument Parsing
# =========================================================
def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Run Part 2 (Ranking) of HPC pipeline and save Parquet",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Paths from your original log file
    parser.add_argument(
        "--input-parquet",
        default="../data/intermediate_hpc/tahoe_l2fc_all_genes_all_drugs.parquet",
        help="Input parquet file from HPC Part 1"
    )
    parser.add_argument(
        "--gene-map-file",
        default="../data/gene_id_conversion_table.tsv",
        help="Gene name -> Entrez ID mapping file"
    )
    parser.add_argument(
        "--output-checkpoint",
        default="../data/intermediate_hpc/checkpoint_ranked_all_genes_all_drugs.parquet",
        help="Output parquet checkpoint for Part 3 (R script)"
    )
    parser.add_argument(
        "--log-dir",
        default="../logs",
        help="Directory for log files"
    )
    parser.add_argument(
        "--rank-chunk-size",
        type=int,
        default=512,
        help="Chunk size for ranking operations"
    )
    
    return parser.parse_args()

# =========================================================
# Main Execution
# =========================================================
def main():
    args = parse_arguments()
    log_file = setup_logging(args.log_dir)
    
    logging.info("="*80)
    logging.info("HPC Pipeline - Part 2 (FIX): Rank and Save Parquet Checkpoint")
    logging.info("="*80)
    logging.info(f"Start time: {datetime.now()}")
    
    try:
        # Validate inputs
        if not Path(args.input_parquet).exists():
            raise FileNotFoundError(f"Input file not found: {args.input_parquet}")
        if not Path(args.gene_map_file).exists():
            raise FileNotFoundError(f"Gene map file not found: {args.gene_map_file}")
            
        Path(args.output_checkpoint).parent.mkdir(parents=True, exist_ok=True)

        # Load data
        logging.info("Loading intermediate Parquet file...")
        logging.info(f"  File: {args.input_parquet}")
        start_time = datetime.now()
        
        l2fc_df = pd.read_parquet(args.input_parquet)
        logging.info(f"  Loaded shape: {l2fc_df.shape}")
        logging.info(f"  Load time: {(datetime.now() - start_time).total_seconds():.1f}s")
        
        if "experiment_id" in l2fc_df.columns:
            l2fc_df = l2fc_df.set_index("experiment_id")
        
        # Load gene mapping
        logging.info("Loading gene name -> Entrez ID mapping...")
        gene_map = pd.read_csv(args.gene_map_file, sep='\t')
        gene_map = gene_map.dropna(subset=['Gene_name', 'entrezID'])
        gene_map = gene_map.drop_duplicates(subset=['Gene_name'])
        gene_name_to_entrez = dict(zip(gene_map["Gene_name"], gene_map["entrezID"]))
        logging.info(f"  Loaded {len(gene_name_to_entrez):,} gene mappings")
        
        # Transpose (MEMORY BOTTLENECK)
        logging.info("Transposing data (genes x experiments)...")
        logging.info("  This is the memory bottleneck!")
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
        
        logging.info(f"  Final ranked matrix shape: {ranked_matrix.shape}") # Should be (25084, 56827)
        
        # ---------------------------------------------------------
        # BUG FIX: Save to Parquet, not RData
        # ---------------------------------------------------------
        logging.info(f"Saving ranked checkpoint file: {args.output_checkpoint}")
        
        # Reset index to save 'entrezID' as a column in the parquet file
        ranked_matrix_to_save = ranked_matrix.reset_index()
        
        start_time = datetime.now()
        ranked_matrix_to_save.to_parquet(args.output_checkpoint, index=False, compression="zstd")
        elapsed = (datetime.now() - start_time).total_seconds()
        
        logging.info(f"Part 2 complete in {elapsed/60:.1f} minutes")
        logging.info(f"   Output checkpoint: {args.output_checkpoint}")
        
        logging.info("\n" + "="*80)
        logging.info("PYTHON PART 2 FINISHED SUCCESSFULLY")
        logging.info("Next step: Run the hpc_part3_convert_to_rdata.R script")
        logging.info("="*80)

    except Exception as e:
        logging.error(f"\nPIPELINE FAILED: {e}", exc_info=True)
        logging.error(f"Check log file for details: {log_file}")
        sys.exit(1)

if __name__ == "__main__":
    main()