# Drug Repurposing Shiny App

Interactive web application for the DRpipe drug repurposing analysis pipeline. This app provides a user-friendly graphical interface to run drug repurposing analyses without writing code.

## Table of Contents

1. [Overview](#overview)
2. [Three Usage Options](#three-usage-options)
3. [Features](#features)
4. [Running the App](#running-the-app)
5. [Data Requirements](#data-requirements)
6. [Configuration and Analysis](#configuration-and-analysis)
7. [Results Visualization](#results-visualization)
8. [Upload Results Feature](#upload-results-feature)
9. [Technical Specifications](#technical-specifications)
10. [Dependencies](#dependencies)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The Shiny app offers an interactive way to run the DRpipe pipeline through a web interface using disease gene expression signatures and drug signature databases (CMap and TAHOE). Instead of editing configuration files and running R scripts, you can:

- Upload disease gene expression data through a web form
- Configure analysis parameters using interactive controls
- Select drug signature databases (CMap, TAHOE, or both)
- Run analyses with a single button click
- View and download results directly in your browser
- Generate visualizations interactively
- Upload pre-computed results from terminal pipeline for instant visualization

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

---

## Three Usage Options

### Option 1: Browser-Based Analysis

**When to use**: For quick exploration with single profiles

**Time**: 7-30 minutes per analysis
- CMAP: 8-15 minutes
- TAHOE: 30-50 minutes

**Requirements**: Must keep browser open during entire analysis

**Workflow**:
1. Choose Analysis Type
2. Upload Disease Data
3. Configure Parameters
4. Run Analysis (wait for completion)
5. View Results and Visualizations

**Advantages**:
- Easy graphical interface
- Automatic visualization
- No terminal knowledge required
- Results available immediately

**Disadvantages**:
- Long wait time
- Browser must remain open
- Results not persistent (lost if browser closes)

**Warning**: A prominent warning box appears on the Run Analysis page reminding users of time requirements and the need to keep the browser open.

---

### Option 2: Terminal Pipeline (Recommended for Production)

**When to use**: For batch processing or if you need to step away

**Time**: 7-30 minutes computation, but you don't need to wait

**Workflow**:
1. Edit configuration: `vim scripts/config.yml`
2. Run pipeline: `Rscript scripts/runall.R`
3. Results saved to: `scripts/results/[analysis_name]_[timestamp]/`
4. Upload CSV results to Shiny app for visualization (see Option 3)

**Output**:
- CSV file: `*_hits_logFC_[CUTOFF]_q<[THRESHOLD].csv`
- Location: `scripts/results/[analysis_name]/`

**Advantages**:
- Run in background, walk away
- Multiple profiles can run sequentially
- Results saved to disk (persistent)
- Reproducible
- Easy to share results
- Can run on remote servers/HPC

**Disadvantages**:
- Requires editing YAML configuration
- Terminal knowledge helpful
- Separate step to visualize results

---

### Option 3: Upload Pre-computed Results

**When to use**: When you already have results from terminal pipeline or a colleague shared results

**Time**: Instant visualization

**Workflow**:
1. Click "Upload Results" tab
2. Select CSV file (`*_hits_logFC_*.csv`)
3. Click "Load Results"
4. Explore visualizations instantly

**Compatible Sources**:
- Results from Option 2 (terminal pipeline)
- Results from colleague or collaborator
- Previous analyses saved as CSV

**Advantages**:
- Zero computation time
- No browser wait time
- Shareable across colleagues
- Archival of results
- Repeatable visualization

**Disadvantages**:
- Requires pre-computed results

---

## Decision Tree

Choose the best option for your workflow:

```
START: I want to run drug repurposing analysis
|
+-- Do I have 7-30 minutes RIGHT NOW to wait?
|   |
|   +-- YES --> Use OPTION 1: Browser Method
|   |           (Keep browser open, analysis runs, see results)
|   |
|   +-- NO --> Continue to next question
|
+-- Do I want to run MULTIPLE analyses in SEQUENCE?
|   |
|   +-- YES --> Use OPTION 2: Terminal Method
|   |           (Run overnight, then upload results)
|   |           Then use OPTION 3 to visualize
|   |
|   +-- NO --> Continue to next question
|
+-- Do I already HAVE a CSV results file?
    |
    +-- YES --> Use OPTION 3: Upload Results
    |           (Instant visualization, no computation)
    |
    +-- NO --> Choose OPTION 1 or 2 above
```

---

## Feature Comparison

| Feature | Option 1 (Browser) | Option 2 (Terminal) | Option 3 (Upload) |
|---------|-------------------|-------------------|-------------------|
| Browser Required | Yes | No | No |
| Setup Time | Minimal | Minimal | Minimal |
| Computation Time | 7-30 min | 7-30 min | Instant |
| Can Walk Away | No | Yes | Yes |
| Batch Processing | No | Yes | Yes |
| Results Persistent | Temporary | Saved to Disk | CSV File |
| Shareable | Hard | Easy (CSV) | Easy (CSV) |
| Reproducible | Manual | Automatic | Automatic |
| Configuration UI | Interactive | YAML Config | N/A |
| Network Intensive | Yes | No | Minimal |
| Best For | Quick Tests | Production Runs | Results Sharing |

---

## Visual Workflow Comparison

### OPTION 1: Browser-Based Analysis

**Time**: 7-30 minutes per analysis
- 1 profile per run
- Results in memory (lost if browser closes)
- Automatic visualization
- Browser must stay open

**Typical Use Case**: Quick exploration, single profile testing

### OPTION 2: Terminal Pipeline

**Time**: 7-30 minutes computation + upload step
- Multiple profiles can run sequentially
- Results saved to disk (persistent)
- Visualization on-demand via Option 3
- Browser not needed during pipeline

**Typical Use Case**: Batch processing, overnight runs, reproducibility

### OPTION 3: Upload Existing Results

**Time**: Instant (no computation)
- CSV must exist
- Full visualization available
- Repeatable
- Shareable

**Typical Use Case**: Results archival, sharing, existing CSV files

---

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

### Standard Workflow

1. **Choose Analysis Type** - Select Single or Comparative analysis
2. **Upload Data** - Upload disease gene expression CSV or load examples
3. **Configure** - Create custom profiles or select existing ones
4. **Run Analysis** - Execute pipeline with real-time progress tracking
5. **View Results** - Explore drug candidates with interactive tables
6. **Visualizations** - Analyze results with dynamic plots

---

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

---

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

### Example Data

Two example datasets are included to test the application:

1. **Fibroid Example** - Core fibroid signature across datasets
2. **Endothelial Example** - Endothelial cell DEG data

Load these from the Upload Data tab without providing your own file.

---

## Configuration and Analysis

### Single Analysis Configuration

Create custom profiles with:
- Gene column selection
- Log2FC cutoff and prefix
- P-value filtering (optional)
- Q-value threshold
- Analysis mode (single cutoff or sweep)
- Sweep parameters (when sweep mode selected)
- Random seed

### Comparative Analysis Configuration

- Select 2+ existing profiles from config.yml
- Create custom profiles with full sweep parameter control
- Compare results across different parameter combinations
- Identify drugs that appear consistently across profiles

### Terminal Configuration

For batch processing via command line:

1. **Edit the configuration**:
   ```bash
   vim scripts/config.yml
   ```

2. **Run the pipeline**:
   ```bash
   cd scripts
   Rscript runall.R
   ```

3. **Locate the results file**:
   - Path: `scripts/results/[analysis_name]_[timestamp]/`
   - Look for: `*_hits_logFC_*.csv` files
   - Example: `acne_CMAP_20251121-195547/file8b3e7a972293_hits_logFC_0.00_q<0.50.csv`

---

## Results Visualization

### Single Analysis Plots

- **Top Drugs**: Bar chart of highest-scoring drug candidates
- **Score Distribution**: Histogram of CMap scores
- **Volcano Plot**: Score vs significance scatter plot

### Comparative Analysis Plots

- **Profile Overlap**: Heatmap showing drug overlap between profiles
- **Score Distribution by Profile**: Box plots comparing score distributions

### Upload Results Visualizations

When uploading pre-computed CSV results, three visualization tabs are available:

#### Score Distribution Histogram
- Shows distribution of CMap scores across all drugs
- Helps identify clustering of drug effects
- Data: All cmap_score values
- Bins: 30 (auto-calculated)
- X-axis: CMap Score (-1 to 1)
- Y-axis: Frequency (count)

#### Top Drugs Bar Chart
- Displays top 15 drug candidates
- Sorted by CMap score (most negative = strongest reversal)
- Color-coded by score intensity
- Data: Top 15 drugs by lowest cmap_score
- X-axis: CMap Score
- Y-axis: Drug Name

#### Drug Details Table
- Comprehensive table of all drugs with metadata
- Sortable and searchable by any column
- Shows 50 rows by default (paginated for large files)
- Columns: name, cmap_score, q, cell_line, concentration, duration, vehicle, DrugBank.ID
- Export to CSV available

---

## Upload Results Feature

### Step-by-Step Guide

#### Step 1: Access the Feature
- Click "Upload Results" in the sidebar menu

#### Step 2: Select Your CSV File
- Click "Choose CSV File" button
- Select the `*_hits_logFC_*.csv` file from your terminal pipeline results

#### Step 3: Load the Results
- Click the "Load Results" button
- The app will display:
  - Number of drugs loaded
  - Average CMap score
  - Median Q-value

#### Step 4: Explore Visualizations
- Use the three visualization tabs to explore results
- Sort and search the drug details table
- Hover over charts for additional information

#### Step 5: Download Results
- Click "Download Results" to save a copy of the uploaded data

### Example Workflows

#### Quick Analysis in Browser
```
Home >> Choose Type (Single) >> Upload Data >> Configure >> Run (wait 8-15 min)
```

#### Batch Processing with Terminal
```bash
# Terminal
Rscript scripts/runall.R  # Wait for completion

# Browser
Open App >> Upload Results >> Select CSV >> Visualize
```

#### Collaborative Analysis
```
1. Colleague runs: Rscript scripts/runall.R
2. Colleague shares: results/analysis_folder/*_hits_logFC_*.csv
3. You upload the CSV via "Upload Results" tab
4. Both explore same visualizations
```

---

## Technical Specifications

### Required CSV Columns for Upload

These columns are **mandatory** for successful upload:

#### 1. exp_id
- **Type**: Numeric (integer)
- **Description**: Unique experiment identifier in CMap/TAHOE database
- **Example**: `923`, `1337`, `5962`
- **Used for**: Linking to drug metadata

#### 2. name
- **Type**: Text (string)
- **Description**: Common drug name
- **Example**: `acetazolamide`, `aspirin`, `ibuprofen`
- **Used for**: Display in charts and tables

#### 3. cmap_score
- **Type**: Numeric (float)
- **Range**: -1.0 to 1.0 (typically -1 to 0 for reversions)
- **Description**: CMap reversal score
  - Negative = good reversal (desired)
  - Positive = drugs that mimic disease
- **Example**: `-0.293466757513548`, `-0.419922979527664`
- **Used for**: Ranking and visualization

#### 4. q
- **Type**: Numeric (float)
- **Range**: 0 to 1
- **Description**: Adjusted p-value (q-value) for statistical significance
- **Example**: `0.0120684844641725`, `0.000234615384615385`
- **Used for**: Filtering significance (typically threshold = 0.05)

### Recommended Optional Columns

These columns enhance visualization and are automatically displayed if present:

- **cell_line**: Cell line used in experiment (e.g., MCF7, A375)
- **concentration**: Drug concentration (e.g., 1.8e-05)
- **duration**: Treatment duration in hours (e.g., 6, 24)
- **vehicle**: Vehicle control used (e.g., DMSO, H2O)
- **array_platform**: Microarray platform (e.g., HT_HG-U133A)
- **DrugBank.ID**: DrugBank identifier (e.g., DB00819)
- **drug_name**: Alternative/formal drug name

### Additional Preserved Columns

The following columns are generated by the pipeline and preserved in uploads (not required):
- p.x, subset_comparison_id, analysis_id, vendor, vendor_catalog_id, vendor_catalog_name, drug_concept_id, cas_number, drug_name_alt, r, p.y, num_peers, valid

### Example CSV Structure

```csv
exp_id,cmap_score,p.x,q,subset_comparison_id,analysis_id,name,concentration,duration,cell_line,array_platform,vehicle,DrugBank.ID,drug_name,r
923,-0.293466757513548,0.00312,0.0120684844641725,"file_logFC_0","CMAP","acetazolamide",1.8e-05,6,"MCF7","HT_HG-U133A","DMSO","DB00819","acetazolamide",0.162
1315,-0.419922979527664,9.99990000099999e-06,0.000234615384615385,"file_logFC_0","CMAP","acetylsalicylic acid",1e-04,6,"MCF7","HT_HG-U133A","DMSO","DB00945","acetylsalicylic acid",0.442
```

### File Specifications

**File Source**:
- Generated by: `Rscript scripts/runall.R`
- Location: `scripts/results/[analysis_name]_[timestamp]/`

**File Type**:
- Format: CSV (Comma-Separated Values)
- Naming: `*_hits_logFC_[CUTOFF]_q<[THRESHOLD].csv`
- Encoding: UTF-8
- Row Count: Typically 20-200 drugs per analysis
- File Size: Usually <100 KB

### Validation and Processing

**Validation Rules Applied During Upload**:
1. **Column Check**: Verifies all 4 required columns exist
2. **Data Type Conversion**: Coerces data to correct types
3. **Sorting**: Default sort by cmap_score (ascending = most negative first)
4. **Display Limits**: Tables show 50 rows by default (paginated)

**Processing Pipeline**:
1. User selects CSV file
2. Read CSV into memory
3. Validate columns (error if missing: exp_id, name, cmap_score, q)
4. Calculate statistics (n_drugs, avg_score, median_q)
5. Generate visualizations automatically
6. Enable UI elements for exploration

**Performance Metrics**:

| Operation | Performance |
|-----------|-------------|
| Load CSV (1000 rows) | <100ms |
| Histogram render | <500ms |
| Bar chart render | <500ms |
| Table render | <1000ms |
| Sort table | <500ms |
| Search filter | <200ms |
| Download CSV | <500ms |

### Quality Assurance

**What's Checked**:
- CSV can be parsed
- Required columns exist
- Data can be coerced to correct types
- Visualizations render without error

**What's NOT Checked**:
- Values are in expected ranges
- Duplicate exp_ids
- Missing values in cells
- Gene names are valid

**Best Practices**:
1. Use CSVs directly from pipeline (not manually edited)
2. Don't modify column names
3. Don't delete rows (keep original for reproducibility)
4. Store original input + CSV together

---

## Dependencies

### Required R Packages

Core functionality:
- shiny
- shinydashboard
- DT
- plotly
- tidyverse
- yaml
- shinyjs
- pheatmap
- UpSetR
- DRpipe (custom package)

### Installation

Install all required packages:

```r
# Install CRAN packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "tidyverse",
  "yaml",
  "shinyjs",
  "pheatmap",
  "UpSetR"
))

# Install DRpipe (custom package)
# Navigate to the DRpipe directory and install
install.packages("path/to/DRpipe", repos = NULL, type = "source")
```

### Version Compatibility

- **Shiny**: 1.7.0+
- **R**: 4.0.0+
- **Browser**: Any modern browser (Chrome, Firefox, Safari, Edge)
- **CSV Spec**: RFC 4180 (standard CSV format)

### File Structure

```
shiny_app/
  app.R                 # Main application
  run.R                 # Helper script to launch app
  README.md             # This comprehensive documentation
  .Rhistory            # R session history
```

---

## Troubleshooting

### General Analysis Issues

#### "Gene column not found"
**Solution**: Verify the gene_key parameter matches your CSV column name exactly (case-sensitive)

#### "No genes matched"
**Solutions**:
- Check that gene identifiers are in the correct format
- Ensure log2FC column prefix matches your data
- Review the configuration carefully

#### "No significant hits"
**Solutions**:
- Try adjusting the log2FC cutoff (lower = more lenient)
- Increase the q-value threshold
- Check that your disease signature has sufficient genes

### Upload Results Issues

#### Missing Required Columns Error
**Check**: Does your CSV have these exact column names?
- `exp_id`
- `name`
- `cmap_score`
- `q`

**Fix**: Rename columns if they differ (case-sensitive!)

#### File Won't Load
**Possible Causes**:
- File is Excel format (.xlsx not .csv)
- Encoding is not UTF-8
- File is corrupted
- File is empty

**Solutions**:
- Save as CSV from Excel
- Convert encoding: `iconv -f UTF-16 -t UTF-8 file.csv > file_utf8.csv`
- Check file size: `wc -l file.csv`

#### Visualizations Don't Appear
**Causes**:
- cmap_score contains NAs
- q contains NAs
- name contains blanks

**Solutions**:
- Remove rows with missing values: `df[!is.na(df$cmap_score), ]`
- Trim whitespace: `df$name <- trimws(df$name)`
- Refresh the page (F5)

#### Browser Tab Unresponsive (Option 1)
**Solutions**:
- Refresh the page (F5)
- Close browser console (F12) if open
- Check browser memory usage
- Use Option 2 (terminal) or Option 3 (upload) instead

### Browser Memory and Performance Notes

- **Browser Memory**: Works well for analyses with up to 10,000+ drugs
- **Visualization Speed**: Charts render in <1 second typically
- **Export Speed**: CSV download is instant
- **Slow Internet**: Use Option 2 (terminal) or 3 (upload) instead
- **Network Stability**: Terminal method recommended for unstable connections

---

## Tips and Best Practices

1. **For Multiple Profiles**: Use terminal method (Option 2) and batch your runs
2. **For Sharing Results**: Export the CSV files - they're small and portable
3. **For Reproducibility**: Save both the input disease signature and output hits CSV
4. **Parameter Configuration**: Sweep mode parameters provide robust results across thresholds
5. **Time Management**: Use terminal (Option 2) for overnight runs, keeping your browser free
6. **Collaboration**: Share CSV results files easily with colleagues, they can visualize instantly with Option 3
7. **HPC Usage**: Terminal method works great on remote servers and HPC clusters

---

## Quick Reference: Which Option?

| Scenario | Use... |
|----------|--------|
| Have time right now | Option 1 (Browser) |
| No time right now | Option 2 (Terminal) |
| Have CSV file already | Option 3 (Upload) |
| Multiple profiles to run | Option 2 (Terminal) |
| Results to share | Option 2 + 3 (Terminal + Upload) |
| Results from months ago | Option 3 (Upload) |
| Slow internet | Option 2 (Terminal) |
| Unstable internet | Option 2 (Terminal) |
| HPC/cluster access | Option 2 (Terminal) |
| Want reproducibility | Option 2 (Terminal) |
| Want ease of use | Option 1 (Browser) |
| Instant visualization | Option 3 (Upload) |

---

## Summary

Your drug repurposing pipeline now offers **three complementary paths**:

1. **Browser** - Quick, visual, no terminal knowledge needed
2. **Terminal** - Batch processing, background run, reproducible
3. **Upload** - Instant visualization of existing results

Choose the one that fits your workflow best!
