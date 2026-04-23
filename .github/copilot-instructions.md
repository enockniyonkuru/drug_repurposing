# Copilot Instructions for CDRPipe

This workspace contains **CDRPipe**, an R package and Shiny application for computational drug repurposing using gene expression signatures.

## Quick Reference

### Build & Test Commands

```bash
# Run tests and R CMD check (primary CI command)
Rscript scripts/ci/check_cdrpipe.R

# Development workflow (preferred over source())
devtools::load_all("CDRPipe")

# Install package locally
devtools::install("CDRPipe")

# Run tests only
testthat::test_local("CDRPipe")

# Regenerate documentation
roxygen2::roxygenise("CDRPipe")

# Run single-profile analysis
Rscript scripts/runall.R

# Run multi-profile comparison
Rscript scripts/compare_profiles.R

# Launch Shiny app
Rscript shiny_app/run.R
```

### Key Entry Points

| Entry Point | Purpose |
|-------------|---------|
| `CDRPipe::DRP$new(...)` | Drug Repurposing Processing pipeline (R6 class) |
| `CDRPipe::DRA$new(...)` | Drug Repurposing Analysis pipeline (R6 class) |
| `CDRPipe::run_dr(...)` | High-level pipeline runner |
| `CDRPipe::load_dr_config(...)` | Load config.yml profiles |

## Project Structure

```
drug_repurposing/
├── CDRPipe/                    # Main R package
│   ├── R/                      # Package source
│   │   ├── pipeline_processing.R  # DRP class - main processing pipeline
│   │   ├── pipeline_analysis.R    # DRA class - analysis/visualization
│   │   ├── processing.R           # Core scoring functions
│   │   ├── analysis.R             # Analysis helpers
│   │   ├── io_config.R            # Config and I/O utilities
│   │   └── cli.R                  # CLI interface
│   ├── tests/testthat/         # Unit tests
│   └── man/                    # Generated docs (via roxygen2)
├── scripts/                    # Command-line entry points
│   ├── config.yml              # Analysis profiles configuration
│   ├── runall.R                # Single-profile execution
│   ├── compare_profiles.R      # Multi-profile comparison
│   └── data/                   # Input data files
└── shiny_app/                  # Interactive web application
```

Manuscript-specific comparative analyses and case studies now live in the separate `cdrpipe-comparative-analysis` repository: https://github.com/enockniyonkuru/cdrpipe-comparative-analysis

## Architecture

### R6 Pipeline Classes

- **DRP (Drug Repurposing Processing)**: Orchestrates disease signature processing, drug scoring, and statistical analysis
- **DRA (Drug Repurposing Analysis)**: Handles post-processing, filtering, visualization, and cross-run comparisons

### Analysis Modes

- **Single mode**: One fold-change threshold for disease signature filtering
- **Sweep mode**: Tests multiple thresholds, aggregates results for robust hits
- **Percentile filtering**: Data-adaptive threshold based on gene distribution (recommended)

### Configuration System

Profiles in `scripts/config.yml` define:
- `paths`: Input/output file locations
- `params`: Gene filtering, scoring, and statistical parameters

## Coding Conventions

### R Package Development

- Use `devtools::load_all("CDRPipe")` instead of `source()` for development
- Document functions with roxygen2 (`@param`, `@return`, `@export`, `@examples`)
- After changing documentation, run `roxygen2::roxygenise("CDRPipe")`
- Keep NAMESPACE and man/ in sync with source (CI enforces this)

### Function Naming

- `pl_*` - Plot/visualization functions (e.g., `pl_heatmap`, `pl_upset`)
- `io_*` - I/O utility functions (e.g., `io_save_table`, `io_resolve_path`)
- `cfg_*` - Configuration functions (e.g., `cfg_params`, `cfg_paths`)

### Testing

- Tests use testthat (edition 3)
- Test files: `test-*.R` in `CDRPipe/tests/testthat/`
- Helper data: `helper-toy-data.R` creates synthetic test fixtures
- Run tests before committing: `testthat::test_local("CDRPipe")`

### Config Profiles

When creating new profiles in `config.yml`:
1. Copy an existing profile as template
2. Use descriptive names: `{Database}_{Disease}_{Variant}` (e.g., `CMAP_Acne_Standard`)
3. Document non-obvious parameter choices with comments

## Common Pitfalls

1. **Missing column headers in disease CSV**: Verify CSV has proper headers
2. **Gene identifier mismatch**: `gene_key` must match actual column name exactly
3. **Large Tahoe runs**: Use `ncores` parameter and consider smoke profiles first
4. **Percentile vs fixed cutoff**: Don't set both `logfc_cutoff` and `percentile_filtering.enabled: true`

## Key Data Files (not in repo - must be downloaded)

- `cmap_signatures.RData` - CMap drug expression signatures
- `tahoe_signatures.RData` - TAHOE drug expression signatures
- `*_drug_experiments_new.csv` - Drug metadata
- `*_valid_instances.csv` - Curated valid experiments

## Documentation Links

- [Main README](../README.md) - Full setup and usage guide
- [CDRPipe Package README](../CDRPipe/README.md) - Package API documentation
- [Scripts README](../scripts/README.md) - CLI workflow documentation
- [Shiny App README](../shiny_app/README.md) - Web interface guide
