
# Drug Repurposing Analysis Project


This repository contains **DRpipe**, a comprehensive R package for drug repurposing analysis using disease gene expression signatures and the Connectivity Map (CMap) to identify potential therapeutic compounds.

The project aims to identify existing drugs that could be repurposed for new therapeutic applications by analyzing their ability to reverse disease-associated gene expression patterns. The analysis uses the Connectivity Map database to find compounds that produce transcriptional signatures opposite to those observed in disease states.


## 0. Outline (Table of Contents)
1. [Project Overview](#1-project-overview)  
2. [Repository Structure](#2-repository-structure)  
3. [Prerequisites](#3-prerequisites)  
4. [Installation](#4-installation)  
5. [Data Formats (Inputs)](#5-data-formats-inputs)  
6. [Configure Once (configyml)](#6-configure-once-configyml)  
7. [Single-Run Pipeline (end-to-end)](#7-single-run-pipeline-end-to-end)  
8. [Cross-Run Analysis (compare many runs)](#8-cross-run-analysis-compare-many-runs)  
9. [Command-Line Usage (optional)](#9-command-line-usage-optional)  
10. [Customizing for Your Dataset](#10-customizing-for-your-dataset)  
11. [Outputs Cheat-Sheet](#11-outputs-cheat-sheet)  
12. [Troubleshooting](#12-troubleshooting)  
13. [Methodology (What the pipeline does)](#13-methodology-what-the-pipeline-does)  
14. [Citation, Authors, License](#14-citation-authors-license)  
15. [Appendix: Run Everything from R](#15-appendix-run-everything-from-r)  

---

## 1. Project Overview

This repo contains:

* **DRpipe/** — an R package with processing + analysis pipelines and helpers.
* **scripts/** — tiny drivers (`runall.R`, `analyze.R`) and a **single** YAML config.
* **dump/** — legacy/dev scripts (kept for reference).

What you can do:

* Build & install the package.
* Run a **single dataset** end-to-end (clean → score → stats → per-run plots).
* Run a **cross-run analysis** (overlap heatmaps, UpSet plots, combined summaries).
* Swap in **your own disease signature** with minimal changes.

---

## 2. Repository Structure

```
drug_repurposing/
├── README.md
├── DRpipe/
│   ├── DESCRIPTION, NAMESPACE, LICENSE, renv.lock
│   └── R/
│       ├── processing.R               # core processing funcs
│       ├── analysis.R                 # plotting/summary helpers
│       ├── pipeline_processing.R      # DRP class + run_dr()
│       ├── pipeline_analysis.R        # DRA class + analyze_runs()
│       ├── io_config.R                # config & IO helpers
│       ├── cli.R                      # dr_cli() for shell usage
│       └── zzz-imports.R
├── scripts/
│   ├── config.yml                     # single source of truth
│   ├── runall.R                       # one dataset end-to-end
│   ├── analyze.R                      # cross-run analysis driver
│   └── data/, results/
└── dump/                               # legacy/dev scripts (optional)
```

---

## 3. Prerequisites

* **R ≥ 4.2** (recommended)
* When you install `DRpipe`, R will also install required **Imports** automatically:

  * `R6`, `dplyr`, `config`, `docopt`, `qvalue`, `pbapply`
* Optional **Suggests** (for visualization; skip on headless servers):

  * `pheatmap`, `UpSetR`, `gplots`, `grid`
    To get all plots:

  ```r
  install.packages(c("pheatmap", "UpSetR", "gplots"))
  ```
* A **CMap/LINCS reference signatures** file (`cmap_signatures.RData`). See §5.

---

## 4. Installation

1. **Clone the repo**

```bash
git clone https://github.com/enockniyonkuru/drug_repurposing.git
cd drug_repurposing
```

2. **Install the package**

```r
install.packages("devtools", repos = "https://cloud.r-project.org")

# Build docs and install DRpipe
devtools::document("DRpipe")
devtools::install("DRpipe")

# Optional: restore a locked environment
# renv::restore(lockfile = "DRpipe/renv.lock")
```

3. **Verify**

```r
library(DRpipe)
?run_dr
?analyze_runs
```

---

## 5. Data Formats (Inputs)

### 5.1 Disease Signature CSV (your dataset)

* Columns:

  * **Gene ID column** (default name: `SYMBOL`; configurable by `gene_key`)
  * **One or more fold-change columns** sharing a prefix (default: `log2FC`), e.g. `log2FC_1`, `log2FC_2`, …
    The pipeline averages these into a single `logFC`.

**Minimum columns**

| column    | type      | notes                                |
| --------- | --------- | ------------------------------------ |
| `SYMBOL`  | character | or another namespace; set `gene_key` |
| `log2FC*` | numeric   | one or more columns (prefix matched) |

*(Optional)* `pval`/`padj` can exist but are not required.

### 5.2 CMap Signatures (`cmap_signatures.RData`)

* An `.RData` file that, when loaded, provides a reference signatures object (ideally named `cmap_signatures`).
* The pipeline infers the gene universe from:

  * a column named `V1`, or
  * `gene`, or
  * as a fallback, the unique values across the object.

### 5.3 CMap Metadata (optional but recommended)

* `cmap_drug_experiments_new.csv` (experiment annotations)
* `cmap_valid_instances.csv` (curated flags / DrugBank IDs)

---

## 6. Configure Once (config.yml)

Edit `scripts/config.yml` to point to your data:

```yaml
default:
  paths:
    signatures: "scripts/data/cmap_signatures.RData"

    # Use exactly one of:
    disease_file: "scripts/data/CoreFibroidSignature_All_Datasets.csv"
    # disease_dir: "scripts/data/"
    # disease_pattern: "CoreFibroidSignature_All_Datasets\\.csv"

    cmap_meta: "scripts/data/cmap_drug_experiments_new.csv"
    cmap_valid: "scripts/data/cmap_valid_instances.csv"
    out_dir: "scripts/results"
  params:
    gene_key: "SYMBOL"
    logfc_cols_pref: "log2FC"
    logfc_cutoff: 1
    q_thresh: 0.05
    reversal_only: true
    seed: 123
  analysis:
    results_dir: "scripts/results"
    analysis_dir: "scripts/results/analysis"
    pattern: "_results\\.RData$"
```

> You can add multiple profiles (e.g., `production`, `demo`) and select them later.

---

## 7. Single-Run Pipeline (end-to-end)

### 7.1 Script (recommended)

```bash
Rscript scripts/runall.R
```

This will:

* Read `scripts/config.yml` (`default` profile).
* Create `scripts/results/<YYYYMMDD-HHMMSS>/`.
* Run the full pipeline (load → clean → null → score → stats → per-run plots).
* Save:

  * `<dataset>_results.RData` (list: `drugs`, `signature_clean`)
  * `<dataset>_random_scores_logFC_<cutoff>.RData`
  * `<dataset>_hits_q<…>.csv` (if metadata provided)
  * images under `img/` when enabled
  * `sessionInfo.txt` + effective config snapshot

### 7.2 R Console (power users)

```r
library(DRpipe)
cfg <- load_dr_config("default", "scripts/config.yml")

run_dr(
  signatures_rdata = cfg$paths$signatures,
  disease_path     = cfg$paths$disease_file %||% cfg$paths$disease_dir,
  disease_pattern  = if (is.null(cfg$paths$disease_file)) cfg$paths$disease_pattern else NULL,
  cmap_meta_path   = cfg$paths$cmap_meta,
  cmap_valid_path  = cfg$paths$cmap_valid,
  out_dir          = cfg$paths$out_dir,
  gene_key         = cfg$params$gene_key,
  logfc_cols_pref  = cfg$params$logfc_cols_pref,
  logfc_cutoff     = cfg$params$logfc_cutoff,
  q_thresh         = cfg$params$q_thresh,
  reversal_only    = isTRUE(cfg$params$reversal_only),
  seed             = cfg$params$seed,
  make_plots       = TRUE,
  verbose          = TRUE
)
```

---

## 8. Cross-Run Analysis (compare many runs)

After you have ≥1 per-run outputs in `scripts/results/`:

```bash
Rscript scripts/analyze.R
```

This will:

* Read `analysis.*` settings from the config.
* Load all `*_results.RData` under `results_dir` (matching `pattern`).
* Annotate & filter with metadata.
* Produce:

  * Per-run plots (`cmap_score.jpg`, `heatmap_cmap_hits.jpg`)
  * Overlap heatmaps (`hits_overlap_heatmap.jpg`, `hits_overlap_atleast2_heatmap.jpg`)
  * UpSet plot (`upset.jpg`)
  * Per-run CSVs (`*_hits.csv`, `*_drug_dz_signature_all_hits.csv`)
* Write everything to `analysis_dir/<YYYYMMDD-HHMMSS>/`.

---

## 9. Command-Line Usage (optional)

Prefer a single command over scripts? Use the package CLI:

```bash
# Single run
Rscript -e 'DRpipe::dr_cli()' run --config scripts/config.yml --profile default --make-plots --verbose

# Cross-run
Rscript -e 'DRpipe::dr_cli()' analyze --config scripts/config.yml --profile default --verbose

# Debug merged config
Rscript -e 'DRpipe::dr_cli()' run --config scripts/config.yml --profile default --print-config
```

*(You can also ship an executable wrapper under `inst/scripts` to call `drugrep` directly.)*

---

## 10. Customizing for Your Dataset

* Place your disease CSV under `scripts/data/…`.
* Choose **one**:

  * Single file → set `paths.disease_file`, or
  * Many files → set `paths.disease_dir` **and** `paths.disease_pattern` (regex).
* If your genes aren’t HGNC symbols, set `params.gene_key` accordingly.
* If your fold-change columns use a different prefix, set `params.logfc_cols_pref` (e.g., `fc_`).

**Tuning knobs**

* `params.logfc_cutoff` — absolute cutoff before scoring (default: **1**).
* `params.q_thresh` — FDR threshold for significance (default: **0.05**).
* `params.reversal_only` — keep only negative connectivity (default: **TRUE**).
* `params.seed` — reproducibility for the null simulations.

---

## 11. Outputs Cheat-Sheet

**Per-run results folder**

* `*_results.RData`

  ```r
  results <- list(
    drugs = <data.frame>,          # drug-level scores, p/q, etc.
    signature_clean = <data.frame> # cleaned per-gene signature
  )
  ```
* `*_random_scores_logFC_<cutoff>.RData` — saved null ensemble
* `*_hits_q<…>.csv` — filtered, annotated hits (if metadata available)
* `img/` with plots:

  * `hist_revsc.jpeg` — score distribution
  * `cmap_score.jpg` — per-run score plot
  * `heatmap_cmap_hits.jpg` — drug–disease reversal heatmap

**Cross-run analysis folder**

* `hits_overlap_heatmap.jpg`, `hits_overlap_atleast2_heatmap.jpg`
* `upset.jpg`
* Per-run `*_hits.csv` and `*_drug_dz_signature_all_hits.csv`

---

## 12. Troubleshooting

* **“No columns starting with …”**
  Check `params.logfc_cols_pref` matches your fold-change column prefix.

* **“No overlap between signature genes and library genes”**
  Ensure your gene namespace (`gene_key`) matches the CMap gene universe; map IDs if needed.

* **No result files found (analysis)**
  Confirm `scripts/results/` has `*_results.RData` and your `analysis.pattern` is correct.

* **Plotting fails on headless servers**
  Install plotting suggests (`pheatmap`, `UpSetR`, `gplots`) or run with `make_plots = FALSE`.

* **Config not found**
  Ensure `scripts/config.yml` exists, or set `DRPIPE_CONFIG=/path/to/config.yml`.

---

## 13. Methodology (What the pipeline does)

1. **Disease Signature Prep**
   Load DE results → average FC columns → filter by absolute logFC → map to reference gene universe.

2. **Connectivity Scoring**
   Compare disease up/down sets to CMap profiles → compute reversal scores.

3. **Statistics**
   Generate null distributions by random up/down sampling → empirical p-values → q-values (FDR).

4. **Validation & Annotation**
   Join with CMap experiment metadata → filter to valid instances → summarize per-drug → visualize.

---

## 14. Citation, Authors, License

**Citation**
*(Add when available.)*

**Authors**

* Xinyu Tang — *Author* — [Xinyu.Tang@ucsf.edu](mailto:Xinyu.Tang@ucsf.edu)
* Enock Niyonkuru — *Author, Maintainer* — [enock.niyonkuru@ucsf.edu](mailto:enock.niyonkuru@ucsf.edu)
* Marina Sirota — *Author* — [Marina.Sirota@ucsf.edu](mailto:Marina.Sirota@ucsf.edu)

**License**
MIT — see [`DRpipe/LICENSE`](DRpipe/LICENSE).

---

## 15. Appendix: Run Everything from R

```r
library(DRpipe)
cfg <- load_dr_config("default", "scripts/config.yml")

# Single run
run_dr(
  signatures_rdata = cfg$paths$signatures,
  disease_path     = cfg$paths$disease_file,
  out_dir          = cfg$paths$out_dir,
  make_plots       = TRUE
)

# Cross-run
analyze_runs(
  results_dir          = cfg$analysis$results_dir,
  analysis_dir         = cfg$analysis$analysis_dir,
  cmap_meta_path       = cfg$paths$cmap_meta,
  cmap_valid_path      = cfg$paths$cmap_valid,
  cmap_signatures_path = cfg$paths$signatures,
  q_thresh             = cfg$params$q_thresh,
  reversal_only        = isTRUE(cfg$params$reversal_only),
  verbose              = TRUE
)
```

---

> If you’d like, I can also generate a shorter “User Install vs Developer Install” box and a minimal “Hello World” run using the example CSV in `scripts/data/`.
