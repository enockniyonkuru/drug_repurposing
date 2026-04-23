# Drug Repurposing Shiny App

Interactive web application for running and visualizing `CDRPipe` analyses without editing scripts by hand.

The app now stays aligned with the current `CDRPipe` package and `scripts/config.yml` profiles, including:
- profile loading from `scripts/config.yml`
- percentile-based profiles
- in-app custom controls for `n_permutations`
- an opt-in parallel scoring toggle that reveals `ncores`
- single-mode `ncores` support for large runs
- profile-level `n_permutations`
- the `TAHOE_Acne_Standard_Smoke` verification profile

## What The App Is Best For

Use the Shiny app when you want:
- a graphical interface for a single analysis
- quick parameter exploration
- profile-based runs without editing YAML by hand
- interactive result browsing and plots

Use the terminal pipeline when you want:
- persistent outputs on disk
- long Tahoe or batch runs
- multiple profiles in sequence
- easier reproducibility and sharing

## Launching The App

From the repository root:

```bash
Rscript shiny_app/run.R
```

Or from R:

```r
shiny::runApp("shiny_app")
```

The launcher checks dependencies, verifies key `scripts/data/` files, and starts the app.

## Dependencies

The app expects:
- `CDRPipe`
- `shiny`
- `shinydashboard`
- `fresh`
- `shinyWidgets`
- `shinycssloaders`
- `shinyjs`
- `DT`
- `plotly`
- `tidyverse`
- `yaml`

It also expects the repository structure to remain intact, especially:
- `scripts/config.yml`
- `scripts/data/disease_signatures/`
- `scripts/data/drug_signatures/`

## Data Files

The app uses the same script-side data as the command-line workflow.

Typical local files:
- `scripts/data/drug_signatures/cmap_signatures.RData`
- `scripts/data/drug_signatures/cmap_drug_experiments_new.csv`
- `scripts/data/drug_signatures/cmap_valid_instances.csv`
- `scripts/data/drug_signatures/tahoe_signatures.RData`
- `scripts/data/drug_signatures/tahoe_drug_experiments_new.csv`
- `scripts/data/gene_id_conversion_table.tsv`

Shipped example disease files:
- `scripts/data/disease_signatures/acne_signature.csv`
- `scripts/data/disease_signatures/arthritis_signature.csv`
- `scripts/data/disease_signatures/glaucoma_signature.csv`

## How The App Uses Profiles

On startup, the app reads available profiles from `scripts/config.yml`.

When you choose an existing profile in the UI, the app now respects profile settings for:
- `signatures`
- `drug_meta`
- `drug_valid`
- `gene_conversion_table`
- `percentile_filtering`
- `logfc_cutoff`
- `mode`
- `n_permutations`
- `ncores`
- `pvalue_method`
- `phipson_smyth_correction`

This matters most for Tahoe profiles, because large runs benefit from both lower-cost verification profiles and optional parallel scoring.

When you create a custom run in the UI, you can now also set:
- `Permutation Count`
- `Enable Parallel Scoring`
- `CPU Cores` after enabling parallel mode

The app also shows the number of CPU cores detected on the machine running the Shiny session and warns that using too many cores can hurt responsiveness or increase memory usage.

## Runtime Guidance

Browser-based runs happen in the current Shiny session, so they are best for shorter or exploratory analyses.

Recommended interpretation of permutation settings:
- `n_permutations: 100000` for final or publication-quality analyses
- `n_permutations: 1000` or `10000` for faster validation runs

Important tradeoff:
- higher permutation counts improve p-value resolution
- lower permutation counts run faster but can change borderline FDR calls

For Tahoe:
- full Tahoe profiles can take a long time
- `ncores` helps on Unix-like systems
- `TAHOE_Acne_Standard_Smoke` is the best first verification profile

## Browser Run vs Terminal Run

### Browser Run

Good for:
- one-off interactive work
- checking a profile quickly
- immediate visualization

Limits:
- keep the browser open
- long runs are less comfortable here
- outputs are session-scoped unless you download them

### Terminal Run

Good for:
- long CMAP or Tahoe runs
- multiple profiles
- background execution
- persistent result folders in `scripts/results/`

Typical commands:

```bash
Rscript scripts/runall.R
Rscript scripts/compare_profiles.R
```

Then upload a generated `*_hits_*.csv` file back into the app for visualization if needed.

## Upload Results Mode

The app can load precomputed hit tables from the terminal workflow.

Typical source:
- `scripts/results/<analysis_folder>/*_hits_*.csv`

This is the easiest way to visualize a long background run without re-running it in the browser.

## Publish Notes

Before publishing the app:
- keep `run.R`, `app.R`, and `scripts/config.yml` in sync
- treat browser-run outputs as temporary unless explicitly downloaded
- document heavy Tahoe runs as long-running
- keep the smoke profile available for verification

Nonessential local state such as `.Rhistory` should not be shipped.
