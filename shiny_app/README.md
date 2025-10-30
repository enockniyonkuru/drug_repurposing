# Drug Repurposing Shiny App

Interactive web application for the DRpipe drug repurposing analysis pipeline. This app provides a user-friendly graphical interface to run drug repurposing analyses without writing code.

## Overview

The Shiny app offers an alternative way to run the DRpipe pipeline through an interactive web interface. Instead of editing configuration files and running R scripts, you can:

- Upload disease gene expression data through a web form
- Configure analysis parameters using interactive controls
- Run analyses with a single button click
- View and download results directly in your browser
- Generate visualizations interactively

**When to use the Shiny app:**
- You prefer a graphical interface over command-line tools
- You want to quickly test different parameters
- You're new to R or the DRpipe pipeline
- You need to demonstrate results to collaborators

**When to use the command-line pipeline:**
- You need to process many datasets in batch
- You want to integrate the pipeline into automated workflows
- You need fine-grained control over all parameters
- You're running analyses on a remote server

## Features

### Analysis Types

1. **Single Analysis**
   - Run analysis with one configuration profile
   - Full sweep mode parameter customization
   - Ideal for initial exploration and parameter testing

2. **Comparative Analysis**
   - Compare results across multiple configuration profiles
   - Identify robust drug candidates that appear consistently
   - Side-by-side comparison visualizations

### Sweep Mode Support

Both analysis types support full sweep mode customization:
- **Auto-grid**: Automatically generate threshold grid from data
- **Step size**: Control spacing between thresholds
- **Min fraction/genes**: Set minimum signature size requirements
- **Robust rule**: Choose between "all cutoffs" or "k of n cutoffs"
- **Aggregation**: Select mean or median for score combination
- **Combine log2FC**: Choose how to combine multiple log2FC columns

### Workflow

1. **Choose Analysis Type** - Select Single or Comparative analysis
2. **Upload Data** - Upload disease gene expression CSV or load examples
3. **Configure** - Create custom profiles or select existing ones
4. **Run Analysis** - Execute pipeline with real-time progress tracking
5. **View Results** - Explore drug candidates with interactive tables
6. **Visualizations** - Analyze results with dynamic plots

## Running the App

### From R Console

```r
# Navigate to the shiny_app directory
setwd("path/to/drug_repurposing/shiny_app")

# Run the app
shiny::runApp()
```

### Using the Helper Script

```r
source("run.R")
```

### From Command Line

```bash
cd shiny_app
R -e "shiny::runApp()"
```

## Data Requirements

### Input CSV Format

Your disease gene expression file should contain:

**Required columns:**
- Gene identifier (e.g., SYMBOL, ENSEMBL, ENTREZ)
- Log2 fold-change values (e.g., log2FC, log2FC_1, log2FC_2)

**Optional columns:**
- P-values or adjusted p-values (e.g., p_val_adj, FDR, pvalue)

### Example Format

```csv
SYMBOL,log2FC_1,log2FC_2,p_val_adj
TP53,2.5,2.3,0.001
BRCA1,-1.8,-2.1,0.005
MYC,3.2,3.0,0.0001
```

## Configuration Profiles

### Single Analysis

Create custom profiles with:
- Gene column selection
- Log2FC cutoff and prefix
- P-value filtering (optional)
- Q-value threshold
- Analysis mode (single cutoff or sweep)
- Sweep parameters (when sweep mode selected)
- Random seed

### Comparative Analysis

- Select 2+ existing profiles from config.yml
- Create custom profiles with full sweep parameter control
- Compare results across different parameter combinations
- Identify drugs that appear consistently

## Visualizations

### Single Analysis Plots

- **Top Drugs**: Bar chart of highest-scoring drug candidates
- **Score Distribution**: Histogram of CMap scores
- **Volcano Plot**: Score vs significance scatter plot

### Comparative Analysis Plots

- **Profile Overlap**: Heatmap showing drug overlap between profiles
- **Score Distribution by Profile**: Box plots comparing score distributions

## Example Data

Two example datasets are included:

1. **Fibroid Example** - Core fibroid signature across datasets
2. **Endothelial Example** - Endothelial cell DEG data

Load these from the Upload Data tab to test the application.

## Dependencies

Required R packages:
- shiny
- shinydashboard
- DT
- plotly
- tidyverse
- yaml
- shinyjs
- DRpipe (custom package)

## File Structure

```
shiny_app/
├── app.R              # Main application (merged version)
├── app_backup.R       # Original backup (comparative analysis)
├── run.R              # Helper script to launch app
├── README.md          # This file
└── MERGE_PLAN.md      # Documentation of merge process
```

## Troubleshooting

### Common Issues

**"Gene column not found"**
- Verify the gene_key parameter matches your CSV column name exactly

**"No genes matched"**
- Check that gene identifiers are in the correct format
- Ensure log2FC column prefix matches your data

**"No significant hits"**
- Try adjusting the log2FC cutoff (lower = more lenient)
- Increase the q-value threshold
- Check that your disease signature has sufficient genes

