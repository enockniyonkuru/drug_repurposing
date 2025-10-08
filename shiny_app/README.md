# Drug Repurposing Shiny App

Interactive web interface for the DRpipe drug repurposing analysis pipeline with full sweep mode support.

## Features

- ✅ Upload disease gene expression data or load examples
- ✅ Configure analysis parameters with intuitive UI
- ✅ **Full sweep mode customization** - control all sweep parameters
- ✅ Fixed navigation buttons for smooth workflow
- ✅ Run drug repurposing analysis with progress tracking
- ✅ View and download results
- ✅ Interactive visualizations

## What's New

### Version 2.0 (Current)
- ✅ **Sweep Mode Customization**: Full control over all sweep parameters
  - Auto-grid generation
  - Step size control
  - Min fraction/genes thresholds
  - Robust drug rules (all vs k_of_n)
  - Score aggregation methods
- ✅ **Fixed Navigation**: All buttons now work correctly
- ✅ **Streamlined Workflow**: Simplified 4-step process
- ✅ **Better UX**: Conditional UI, real-time summaries, auto-navigation

## Running the App

From R:

```r
# Install required packages if needed
install.packages(c("shiny", "shinydashboard", "DT", "plotly", "tidyverse", "yaml", "shinyjs"))

# Run the app
shiny::runApp("shiny_app")
```

Or use the provided run script:

```r
source("shiny_app/run.R")
```

## Quick Start

1. **Upload Data**: Load CSV or click "Load Fibroid Example"
2. **Configure**: 
   - Set basic parameters (gene column, log2FC cutoff, etc.)
   - Choose "Single Cutoff" or "Sweep Mode"
   - Customize sweep parameters if using sweep mode
3. **Run Analysis**: Click "Run Analysis" and monitor progress
4. **View Results**: Explore drug candidates, download results

## Sweep Mode Guide

### What is Sweep Mode?

Sweep mode tests multiple log2FC thresholds to identify robust drug candidates that appear consistently across different cutoff values. This reduces sensitivity to arbitrary threshold selection.

### Key Parameters

#### sweep_auto_grid
- **TRUE**: Automatically generate thresholds from data distribution
- **FALSE**: Use manually specified cutoffs

#### sweep_step
- Controls spacing between thresholds
- Example: 0.1 creates 0.5, 0.6, 0.7, 0.8...
- Smaller = more thresholds tested

#### sweep_min_frac
- Minimum fraction of genes required at each threshold
- Example: 0.20 = at least 20% of genes must remain

#### sweep_min_genes
- Absolute minimum number of genes required
- Example: 200 = at least 200 genes

#### sweep_stop_on_small
- **TRUE**: Stop if signature becomes too small
- **FALSE**: Continue testing all thresholds (recommended)

#### combine_log2fc
- **average**: Mean of multiple log2FC columns
- **median**: Median (robust to outliers)
- **first**: Use only first column

#### robust_rule
- **all**: Drug must be significant at ALL thresholds
- **k_of_n**: Drug must be significant in at least k thresholds

#### robust_k
- Only used when robust_rule = "k_of_n"
- Example: k=2 means drug must appear in ≥2 thresholds

#### aggregate
- **mean**: Average scores across thresholds
- **median**: Median score (robust to outliers)

## Example Workflow

### Single Mode Analysis
```r
1. Load Fibroid Example
2. Configure:
   - Gene Column: SYMBOL
   - Log2FC Cutoff: 1.0
   - Mode: Single Cutoff
3. Run Analysis
4. View 38 drug hits
```

### Sweep Mode Analysis
```r
1. Load Fibroid Example
2. Configure:
   - Gene Column: SYMBOL
   - Mode: Sweep Mode
   - Auto-grid: TRUE
   - Step size: 0.1
   - Min fraction: 0.20
   - Min genes: 200
   - Robust rule: k_of_n
   - Robust k: 2
   - Aggregation: median
3. Run Analysis
4. View robust drug candidates
```

## Troubleshooting

### Navigation not working
- Ensure you're using the latest version of app.R
- Check that shinyjs is loaded

### Sweep mode options not showing
- Verify "Sweep Mode" is selected in Mode dropdown
- Refresh the page if needed

### Analysis fails
- Check that gene_key matches your data column name
- Verify log2FC columns exist with specified prefix
- Ensure data file is properly formatted CSV

## Requirements

- R >= 4.0
- DRpipe package installed
- Required R packages: shiny, shinydashboard, DT, plotly, tidyverse, yaml, shinyjs

## Files

- `app.R` - Main Shiny application (updated v2.0)
- `run.R` - Helper script to launch app
- `README.md` - This file
- `README_v2.md` - Detailed v2.0 documentation
- `app_backup.R` - Backup of original app (v1.0)
- `app_v2.R` - Source for v2.0 (now merged into app.R)

## Support

For issues or questions:
1. Check the Help tab in the app
2. Review README_v2.md for detailed documentation
3. Verify your data format matches requirements
4. Check R console for error messages
