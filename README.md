# Drug Repurposing Analysis Project

This repository contains a comprehensive drug repurposing analysis pipeline using disease gene expression signatures and the Connectivity Map (CMap) to identify potential therapeutic compounds.

## Project Overview

The project aims to identify existing drugs that could be repurposed for new therapeutic applications by analyzing their ability to reverse disease-associated gene expression patterns. The analysis uses the Connectivity Map database to find compounds that produce transcriptional signatures opposite to those observed in disease states.

## Repository Structure

```
drug_repurposing/
├── DRpipe/                    # R package for drug repurposing analysis
│   ├── R/                     # Core package functions
│   ├── man/                   # Package documentation
│   ├── DESCRIPTION            # Package metadata
│   ├── NAMESPACE              # Package exports
│   └── README.md              # Package-specific documentation
├── scripts/                   # Analysis scripts and workflows
│   ├── DR_processing.R        # Data processing workflow
│   ├── DR_analysis.R          # Analysis and visualization workflow
│   ├── data/                  # Input data files
│   │   ├── cmap_signatures.RData
│   │   ├── cmap_drug_experiments_new.csv
│   │   ├── cmap_valid_instances.csv
│   │   └── CoreFibroidSignature_All_Datasets.csv
│   └── results/               # Analysis outputs
│       ├── analysis/          # Final results and visualizations
│       └── *.RData           # Intermediate results
└── README.md                  # This file
```

## Key Components

### DRpipe R Package
A comprehensive R package that provides:
- **Data Processing**: Clean and filter differential expression data
- **Scoring**: Compute connectivity scores between disease signatures and drug profiles
- **Statistical Analysis**: Generate null distributions and calculate significance
- **Visualization**: Create heatmaps, histograms, and overlap plots
- **Export**: Save results in multiple formats (CSV, Excel)

### Analysis Scripts
Ready-to-use scripts that demonstrate the complete workflow:
- `DR_processing.R`: Preprocessing of disease signatures and CMap data
- `DR_analysis.R`: Statistical analysis and visualization of results

## Quick Start

### Prerequisites
- R (≥ 4.1)
- Required R packages (see DRpipe/README.md for full list)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/enockniyonkuru/drug_repurposing.git
cd drug_repurposing
```

2. Install the DRpipe package:
```r
# Install devtools if needed
install.packages("devtools")

# Install DRpipe
devtools::install("DRpipe")
```

3. Install required dependencies:
```r
install.packages(c("dplyr","tidyr","tibble","gprofiler2","pbapply","qvalue",
                   "pheatmap","UpSetR","grid","gplots","reshape2","xlsx"))
```

### Running the Analysis

1. **Data Processing**:
```r
source("scripts/DR_processing.R")
```

2. **Analysis and Visualization**:
```r
source("scripts/DR_analysis.R")
```

## Methodology

The drug repurposing pipeline follows these key steps:

1. **Disease Signature Preparation**
   - Load differential expression data from disease studies
   - Filter genes based on fold-change and significance thresholds
   - Map gene symbols to standardized identifiers

2. **Connectivity Scoring**
   - Compare disease signatures against CMap drug profiles
   - Calculate connectivity scores measuring signature reversal
   - Generate null distributions using random gene sets

3. **Statistical Analysis**
   - Compute p-values and q-values for connectivity scores
   - Filter results based on statistical significance
   - Validate hits using CMap experimental metadata

4. **Visualization and Export**
   - Generate heatmaps showing drug-disease relationships
   - Create overlap plots across multiple datasets
   - Export results in publication-ready formats

## Data Sources

- **Connectivity Map (CMap)**: Gene expression profiles of cells treated with bioactive compounds
- **Disease Signatures**: Differential expression data from disease vs. control comparisons
- **Drug Metadata**: Information about CMap experiments and compound annotations

## Results

The analysis generates several types of outputs:

- **Statistical Results**: Tables with connectivity scores, p-values, and q-values
- **Visualizations**: Heatmaps, histograms, and overlap plots
- **Candidate Lists**: Ranked lists of potential repurposing candidates
- **Quality Control**: Validation metrics and filtering statistics

## Example Use Case: Fibroid Analysis

The repository includes a complete analysis of uterine fibroid gene expression signatures, demonstrating:
- Processing of fibroid-specific differential expression data
- Identification of compounds that reverse fibroid-associated gene expression
- Statistical validation and visualization of results

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-analysis`)
3. Commit your changes (`git commit -am 'Add new analysis method'`)
4. Push to the branch (`git push origin feature/new-analysis`)
5. Create a Pull Request

## Citation

If you use this pipeline in your research, please cite:

```
[Citation information to be added]
```

## License

This project is licensed under the [LICENSE](LICENSE) file in the repository.

## Contact

For questions or support, please contact:
- [Your contact information]

## Acknowledgments

- The Broad Institute for the Connectivity Map database
- Contributors to the R packages used in this pipeline
- [Other acknowledgments]
