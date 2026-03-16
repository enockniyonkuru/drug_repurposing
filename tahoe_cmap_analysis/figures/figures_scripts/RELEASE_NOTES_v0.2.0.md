# DRpipe Release Notes - v0.2.0

**Release Date:** December 2025  
**Previous Version:** v0.1.0

---

## Overview

DRpipe v0.2.0 introduces comprehensive TAHOE (Therapeutics Hub and Occupancy Exploration) integration alongside existing Connectivity Map (CMap) support. This release enables researchers to validate drug repurposing candidates across multiple independent drug signature databases, significantly enhancing the robustness and confidence of therapeutic predictions.

---

## Major Features

### 1. **TAHOE Database Integration** ✨
- Full support for TAHOE drug signature database alongside CMap
- Dual-database analysis for improved drug candidate validation
- Shared drug identification across TAHOE and CMap databases
- Enable evidence-based comparison of therapeutic candidates

### 2. **Enhanced Analysis Capabilities**
- **Comparative database analysis**: Compare drug repurposing results between TAHOE and CMap
- **Cross-database drug validation**: Identify drugs that appear as hits in both databases
- **Unified scoring framework**: Consistent methodology across both drug signature sources
- **Gene ID standardization**: Robust gene mapping across both database formats

### 3. **Expanded Preprocessing Pipeline**
- `extract_OG_tahoe_part_1.py` - Extract TAHOE raw data
- `extract_OG_tahoe_part_2_rank_and_save_parquet.py` - Rank and prepare TAHOE drug profiles
- `extract_OG_tahoe_part_3_convert_to_rdata.R` - Convert to R-compatible format
- `process_creeds_signatures.py` - Enhanced CREEDS disease signature processing
- `process_sirota_lab_signatures.py` - Support for additional disease datasets
- `generate_valid_instances.py` - Curated instance filtering for data quality
- `processing_known_drugs_data.py` - Known drug database integration

### 4. **Batch Processing Framework**
- New batch execution system for high-throughput analysis
- `run_batch_from_config.R` - Execute multiple configurations from YAML
- `run_drpipe_batch.R` - Comprehensive batch job orchestration
- Configuration templates for:
  - CREEDS-based analysis (`creeds_manual_config_all_avg.yml`)
  - Sirota Lab signatures (`sirota_lab_config_all_avg.yml`)
  - Custom test configurations (`test_config.yml`)

### 5. **Enhanced Visualization & Reporting**
- `plot_compare_tahoe_cmap_qvalues.py` - Side-by-side database comparison plots
- `plot_disease_signature_info.py` - Disease signature quality metrics
- `visualize_random_scores.py` - Distribution analysis of permutation scores
- `compare_cmap_tahoe_random_scores.py` - Statistical comparison between databases
- Improved Shiny app with TAHOE support

### 6. **Improved Shiny Application**
- Native TAHOE database selection
- Dual-database comparison interface
- Enhanced interactive visualizations
- Support for batch configuration uploads
- Better documentation and user guidance

---

## Key Improvements

### Pipeline Enhancements
- More robust gene ID conversion using comprehensive mapping tables
- Better handling of gene nomenclature differences between databases
- Improved permutation testing (100,000 permutations for better statistics)
- Enhanced p-value filtering with multiple correction methods

### Data Management
- Structured `drug_signatures/` subdirectories for CMap and TAHOE
- `disease_signatures/` folder for organized disease data management
- `known_drugs/` integration for validation against approved medications
- Standardized data formats and directory organization

### Documentation
- Comprehensive batch processing configuration guide (`README_BATCH_CONFIG.md`)
- TAHOE integration documentation
- Enhanced inline code documentation
- Improved README structure for both package and Shiny app

### Configuration
- Expanded `config.yml` with TAHOE-specific parameters
- Support for multiple disease signature sources
- Flexible parameter sweeping across both databases
- Template configurations for common workflows

---

## Technical Details

### New Dependencies
- Enhanced Python preprocessing scripts with improved data handling
- Additional data validation and quality control checks
- Support for Parquet format for efficient large-scale data processing
- Gene mapping improvements using comprehensive ID conversion tables

### Data Files
- `gene_id_conversion_table.tsv` (114MB) - Comprehensive gene nomenclature mapping
- TAHOE valid instances: `tahoe_valid_instances_OG_035.csv` (56,828 unique drug-induced profiles)
- CMap valid instances: `cmap_valid_instances_OG_015.csv` (6,100 unique drug-induced profiles)
- Known drugs database in Parquet format for efficient querying

### Code Organization
```
tahoe_cmap_analysis/scripts/
├── preprocessing/    # Data preparation and quality control
├── analysis/         # Comparative and statistical analysis
├── execution/        # Batch processing orchestration
├── visualization/    # Plotting and reporting
└── singularity/      # Container definitions for HPC
```

---

## Performance Improvements

- Optimized database comparisons for faster execution
- Improved memory efficiency with Parquet format usage
- Parallel processing support for batch operations
- Reduced preprocessing time with streamlined workflows

---

## Bug Fixes & Refinements

- Fixed p-value filtering issues from v0.1.0
- Improved handling of edge cases in gene signature matching
- Better error messages and validation
- Cleaner repository organization (removed temporary files)

---

## Compatibility

- **R Version**: ≥ 4.2
- **Python Version**: 3.8+
- **Database Formats**: 
  - CMap: v2020 and later
  - TAHOE: OG (Open Grants) datasets
- **Backward Compatible**: All v0.1.0 analyses remain valid with CMap

---

## Migration Guide from v0.1.0

### For R Package Users
```r
# Update package
devtools::load_all("DRpipe")

# Use TAHOE with existing analysis code
results <- DRP(
  disease_file = "disease_signature.csv",
  drug_db = "tahoe",  # NEW: specify database
  config_file = "config.yml"
)
```

### For Shiny App Users
- Simply restart the app - TAHOE database is now available in the UI
- No configuration changes needed
- Existing analyses with CMap remain unchanged

### For Batch Processing
- New batch execution system available in `tahoe_cmap_analysis/scripts/execution/`
- See `README_BATCH_CONFIG.md` for detailed setup instructions
- Template configurations provided for quick setup

---

## Known Limitations & Future Work

### Current Release
- TAHOE preprocessing requires significant computational resources (Singularity recommended)
- Full preprocessing pipeline pre-computed; users can start with preprocessed data

### Future Enhancements
- Additional drug signature databases (DrugBank integration)
- Machine learning-based drug candidate prioritization
- Real-time result caching for Shiny app
- Automated Azure/cloud deployment templates

---

## Contributors

- Xinyu Tang (Author)
- Enock Niyonkuru (Maintainer)
- Marina Sirota (Author)

---

## Support & Documentation

- **Main Documentation**: See [README.md](./README.md)
- **Shiny App Guide**: See [shiny_app/README.md](./shiny_app/README.md)
- **DRpipe Package**: See [DRpipe/README.md](./DRpipe/README.md)
- **Batch Processing**: See [tahoe_cmap_analysis/scripts/execution/README_BATCH_CONFIG.md](./tahoe_cmap_analysis/scripts/execution/README_BATCH_CONFIG.md)
- **Issues & Questions**: [GitHub Issues](https://github.com/enockniyonkuru/drug_repurposing/issues)

---

## Citation

If you use DRpipe v0.2.0 in your research, please cite:

```bibtex
@software{drpipe_v0.2.0,
  title={DRpipe: Drug Repurposing Analysis Pipeline},
  author={Tang, Xinyu and Niyonkuru, Enock and Sirota, Marina},
  year={2025},
  version={0.2.0},
  url={https://github.com/enockniyonkuru/drug_repurposing}
}
```

---

## License

MIT License - See [LICENSE](./DRpipe/LICENSE) for details
