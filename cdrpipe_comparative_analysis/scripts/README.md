# Scripts

This folder was trimmed to keep the reusable pipeline, preprocessing, analysis, and manuscript-facing visualization scripts.

## Kept on purpose

- `execution/`: batch runners and YAML configs for reproducible CDRPipe runs
- `preprocessing/`: data preparation utilities for CMAP, TAHOE, CREEDS, and case-study signatures
- `analysis/`: comparative summaries and result-extraction scripts
- `visualization/`: manuscript and `Exp8` figure-generation scripts
- `singularity/`: Tahoe extraction launchers

## Removed during cleanup

- broken comparison scripts tied to deleted local `scripts/results/` runs
- one-off endometriosis runner scripts superseded by the batch-config workflow
- temporary diagnostics and local debugging plots
- older simulated `CORRECTED` chart scripts that were not part of the curated public workflow

## Working Assumption

Run the curated batch, analysis, and visualization scripts from the `cdrpipe_comparative_analysis/` root. A few low-level preprocessing and HPC helper scripts still preserve older script-local relative paths because they were written for stepwise data-prep runs.
