# Scripts

This directory contains the command-line entry points, configuration, and example inputs for running the CDRPipe workflows outside the Shiny app.

The scripts resolve their own location, so you can run them either from the repository root or from inside `scripts/`.

## Quick Start

From the repository root:

```bash
R -e 'devtools::install("CDRPipe")'
Rscript scripts/runall.R
Rscript scripts/compare_profiles.R
```

From inside `scripts/`:

```bash
Rscript runall.R
Rscript compare_profiles.R
```

Results are written under `scripts/results/`.

## Directory Layout

```text
scripts/
├── config.yml                # Analysis profiles and execution defaults
├── runall.R                  # Single-profile analysis entry point
├── compare_profiles.R        # Multi-profile comparison entry point
├── load_execution_config.R   # Config parsing and DRP construction helpers
├── preprocess_disease_file.R # Utility for standardizing disease CSV columns
├── ci/check_cdrpipe.R        # Package test/build/check helper
├── data/
│   ├── disease_signatures/   # Small example disease inputs shipped in the repo
│   ├── drug_signatures/      # Local drug-signature resources
│   └── gene_id_conversion_table.tsv
└── results/                  # Generated outputs (gitignored)
```

## Entry Points

### `runall.R`

Runs one profile selected by `execution.runall_profile` in `config.yml`.

Current public default:
- `CMAP_Acne_Standard`

What it does:
- Loads the selected profile from `config.yml`
- Resolves paths relative to `scripts/config.yml`
- Builds a timestamped output directory
- Runs the `DRP` pipeline
- Saves results, plots, `config_effective.yml`, and `sessionInfo.txt`

### `compare_profiles.R`

Runs every profile listed in `execution.compare_profiles`, then creates a comparison report and shared plots.

What it does:
- Runs each configured profile sequentially
- Reuses the same config parsing logic as `runall.R`
- Collects hit tables or result objects from each run
- Writes combined hits, summary statistics, overlap plots, and a markdown report

## Configuration

`config.yml` has two parts:

- `execution`: which profile(s) to run by default
- named profiles: path settings plus analysis parameters

Minimal example:

```yaml
execution:
  runall_profile: "CMAP_Acne_Standard"
  compare_profiles: ["CMAP_Acne_Lenient", "CMAP_Acne_Standard", "CMAP_Acne_Strict"]

CMAP_Acne_Standard:
  paths:
    signatures: "data/drug_signatures/cmap_signatures.RData"
    disease_file: "data/disease_signatures/acne_signature.csv"
    drug_meta: "data/drug_signatures/cmap_drug_experiments_new.csv"
    drug_valid: "data/drug_signatures/cmap_valid_instances.csv"
    out_dir: "results"
  params:
    gene_key: "gene_symbol"
    logfc_cols_pref: "logfc_dz"
    logfc_cutoff: 0.055
    q_thresh: 0.05
    reversal_only: true
    n_permutations: 100000
    mode: "single"
```

Notes:
- Relative paths are resolved from the directory containing `config.yml`, not from your shell working directory.
- The public example profiles use only the shipped acne, arthritis, and glaucoma disease signatures.
- `config.yml` contains both CMAP and TAHOE profiles backed by files present in `scripts/data/disease_signatures/`.

## Parallelization And Progress

Single-mode runs now support optional parallel scoring through `params$ncores`.

Example:

```yaml
TAHOE_Acne_Standard:
  params:
    ncores: 4
```

What this affects:
- `random_score()` null-score generation
- `query_score()` observed-score generation
- progress bars in `Rscript` runs for both stages

Notes:
- `ncores` is most useful for large runs such as TAHOE.
- Parallel single-mode scoring is enabled only when `ncores > 1`.
- The current implementation is intended for Unix-like systems such as macOS and Linux.

## Permutation Guidance

Use `n_permutations: 100000` for final analyses and publication-quality runs when you want the best p-value resolution.

For faster validation or development runs, it is reasonable to lower the count, for example:
- `1000` for smoke tests and wiring checks
- `10000` for intermediate validation runs

Lowering the permutation count speeds up execution, but it reduces p-value resolution and can change which hits survive an FDR threshold near the cutoff.

## Public Example Profiles

Useful shipped profiles include:

- `CMAP_Acne_Standard`
- `CMAP_Acne_Lenient`
- `CMAP_Acne_Strict`
- `TAHOE_Acne_Standard`
- `TAHOE_Acne_Standard_Smoke`

`TAHOE_Acne_Standard_Smoke` is a reduced-cost verification profile that uses:
- `n_permutations: 1000`
- `ncores: 4`

It is useful for confirming that the Tahoe workflow runs end to end before launching a much heavier final run.

## Input Data

### Shipped Example Disease Files

These are included in the repo and are useful for validation runs:

- `data/disease_signatures/acne_signature.csv`
- `data/disease_signatures/arthritis_signature.csv`
- `data/disease_signatures/glaucoma_signature.csv`

### Drug Signature Inputs

The larger drug-signature resources are treated as local data. Typical files are:

- `data/drug_signatures/cmap_signatures.RData`
- `data/drug_signatures/cmap_drug_experiments_new.csv`
- `data/drug_signatures/cmap_valid_instances.csv`
- `data/drug_signatures/tahoe_signatures.RData`
- `data/drug_signatures/tahoe_drug_experiments_new.csv`
- `data/drug_signatures/tahoe_valid_instances_OG_035.csv`

If you are setting up a new machine, make sure the profile you plan to run points only to files you actually have.

## Outputs

Single-profile runs create directories like:

```text
scripts/results/<ProfileName>_<YYYYMMDD-HHMMSS>/
├── <dataset>_results.RData
├── <dataset>_hits_*.csv
├── <dataset>_random_scores_*.RData
├── img/
├── config_effective.yml
└── sessionInfo.txt
```

Comparative runs create directories like:

```text
scripts/results/profile_comparison/<YYYYMMDD-HHMMSS>/
├── <profile>_hits.csv
├── combined_profile_hits.csv
├── profile_summary_stats.csv
├── profile_comparison_report.md
└── img/
```

## Utility Scripts

### `preprocess_disease_file.R`

Use this when a disease CSV needs simple column standardization:

```bash
Rscript scripts/preprocess_disease_file.R input.csv output.csv
```

### `ci/check_cdrpipe.R`

Runs package tests plus package build/check from the repository root:

```bash
Rscript scripts/ci/check_cdrpipe.R
```

## Suggested Publish Cleanup

Before publishing the whole repository, keep this directory focused on:

- working public example profiles
- entry scripts that run from a fresh checkout
- documentation that only mentions files that are actually shipped

That means:
- keep `runall.R`, `compare_profiles.R`, `config.yml`, and the helper scripts in sync
- avoid setting defaults to private or local-only disease files
- treat `scripts/results/` and large local drug signature files as generated/local state
