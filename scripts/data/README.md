# Data Directory

This directory contains the input data files required for the drug repurposing pipeline.

## Files Included in Repository

The following small data files are included in the GitHub repository:

1. **cmap_drug_experiments_new.csv** (831 KB)
   - CMap experiment metadata
   - Contains drug names, cell lines, and experimental conditions

2. **cmap_valid_instances.csv** (41 KB)
   - Curated list of valid CMap instances
   - Includes DrugBank IDs and validation flags

3. **CoreFibroidSignature_All_Datasets.csv** (270 KB)
   - Example disease signature for fibroid analysis
   - Contains gene symbols and log2 fold-change values

## Files NOT Included (Too Large for GitHub)

The following files are required but excluded from the repository due to size:

1. **cmap_signatures.RData** (232 MB)
   - CMap reference signatures database
   - **Required for pipeline execution**
   - Download instructions below

2. **gene_id_conversion_table.tsv** (4.5 MB)
   - Gene identifier conversion table
   - Optional but recommended for gene mapping

## How to Obtain Large Files

### Option 1: Download from External Source

If these files are hosted elsewhere (e.g., Zenodo, institutional repository):

```bash
# Download cmap_signatures.RData
wget [URL_TO_CMAP_SIGNATURES] -O scripts/data/cmap_signatures.RData

# Download gene conversion table
wget [URL_TO_GENE_TABLE] -O scripts/data/gene_id_conversion_table.tsv
```

### Option 2: Contact Repository Maintainers

Contact the maintainers to obtain access to the large data files:
- Enock Niyonkuru: enock.niyonkuru@ucsf.edu
- Xinyu Tang: Xinyu.Tang@ucsf.edu

### Option 3: Use Your Own CMap Data

If you have your own CMap signatures:

1. Place your `cmap_signatures.RData` file in this directory
2. Ensure it contains the required gene universe information
3. Update `scripts/config.yml` if using different file names

## File Format Requirements

### Disease Signature CSV
- Must contain gene identifier column (default: `SYMBOL`)
- Must contain one or more log2FC columns (default prefix: `log2FC`)
- Optional: p-value or adjusted p-value columns

### CMap Signatures RData
- Must be loadable with `load()` function
- Should contain gene identifiers (column `V1`, `gene`, or as values)
- Used as reference for connectivity scoring

## Verifying Data Files

After obtaining the large files, verify they're in place:

```bash
ls -lh scripts/data/
```

You should see:
- ✓ cmap_drug_experiments_new.csv
- ✓ cmap_valid_instances.csv
- ✓ CoreFibroidSignature_All_Datasets.csv
- ✓ cmap_signatures.RData (after download)
- ✓ gene_id_conversion_table.tsv (optional)

## Using Your Own Disease Data

To use your own disease signature:

1. Place your CSV file in this directory
2. Update `scripts/config.yml`:
   ```yaml
   paths:
     disease_file: "data/your_disease_signature.csv"
   ```
3. Ensure your file follows the required format (see main README)
