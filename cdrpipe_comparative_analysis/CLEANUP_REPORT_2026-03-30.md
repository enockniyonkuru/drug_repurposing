# Cleanup Report

Date: 2026-03-30

Directory cleaned: `cdrpipe_comparative_analysis/`

## Purpose

This cleanup pass was done to convert `cdrpipe_comparative_analysis/` from a personal experimentation playground into a more publication-ready analysis directory. The goal was to remove stale or redundant material, keep the strongest and latest scripts, preserve manuscript-critical outputs, and document the resulting structure for future maintenance.

## Scope Rules Used During Cleanup

- Only `cdrpipe_comparative_analysis/` was cleaned.
- `cdrpipe_comparative_analysis/visuals/` was intentionally left untouched.
- Experiment 8 results were explicitly preserved.
- Anything clearly tied to Experiment 8 manuscript analysis was kept.
- Old test scripts, duplicate scripts, one-off helpers, and stale path-dependent scripts were removed where they were not part of the retained workflow.

## High-Level Outcome

- The directory was reduced to a cleaner publication-facing structure.
- Core manuscript and comparative analysis workflows were retained.
- Active scripts were updated to use the cleaned directory layout instead of legacy `tahoe_cmap_analysis/...` references.
- A lightweight documentation layer was added to make the kept workflow easier to follow.
- The raw Experiment 8 results were restored and preserved after cleanup.

## Explicitly Preserved

- `visuals/` was not edited.
- `creeds_diseases/results/creed_manual_standardised_results_OG_exp_8/` was preserved.
- Experiment 8 workbook and related manuscript visualization scripts were preserved.
- Core case-study and manuscript analysis material was retained where it still mapped to the public-facing story.

## Large-Artifact Cleanup Decisions

The cleanup removed or excluded heavy non-essential local artifacts that were making the directory harder to maintain and copy. This included:

- local virtual environment content
- large non-Experiment-8 result directories
- oversized intermediate drug-signature artifacts not needed in the curated public-facing directory
- stale derived outputs from earlier testing passes

Note: the Experiment 8 raw results were later restored into the cleaned directory to honor the preservation requirement.

## Scripts Removed

The following scripts were removed because they were duplicates, outdated comparisons, debugging leftovers, old testing utilities, or superseded helpers.

### Analysis

- `scripts/analysis/analyze_phase4_concordance.R`
- `scripts/analysis/compare_databases.R`
- `scripts/analysis/compare_endometriosis.R`
- `scripts/analysis/compare_ese_final.R`
- `scripts/analysis/compare_ese_hits_comparison.py`
- `scripts/analysis/compare_final.R`
- `scripts/analysis/compare_top20.py`
- `scripts/analysis/compare_top50_database_presence.R`
- `scripts/analysis/compile_drug_hits.py`
- `scripts/analysis/extract_filter_results_to_shared_drugs.py`
- `scripts/analysis/extract_selected_disease_info.py`
- `scripts/analysis/overlap_analysis.py`

### Visualization

- `scripts/visualization/create_gene_overlaps.R`
- `scripts/visualization/create_gene_profiles_v2.R`
- `scripts/visualization/create_heatmaps_cmap_tahoe.R`
- `scripts/visualization/create_heatmaps_cmap_tahoe_top50.R`
- `scripts/visualization/create_heatmaps_tomiko.R`
- `scripts/visualization/create_tahoe_hits_visualization.R`
- `scripts/visualization/create_tahoe_unique_drug_hits.R`
- `scripts/visualization/generate_block1_CORRECTED.R`
- `scripts/visualization/generate_block2_CORRECTED.R`
- `scripts/visualization/generate_block3_CORRECTED.R`
- `scripts/visualization/plot_compare_tahoe_cmap_qvalues.py`
- `scripts/visualization/visualize_random_scores.py`

### Preprocessing and Extraction

- `scripts/preprocessing/filter_shared_drugs_cmap_tahoe.py`
- `scripts/extraction/extract_case_study_complete.R`
- `scripts/extraction/extract_case_study_all_steps.R`
- `scripts/extraction/` directory was removed after it became empty

### Case-Study and One-Off Helpers

- `case_study_endomentriosis/run_all_6_endo.R`
- `case_study_endomentriosis/run_all_6_endo_tahoe.R`
- `case_study_endomentriosis/run_all_endometriosis.sh`
- `case_study_endomentriosis/check_aggregation.R`
- `case_study_endomentriosis/disease_signatures/endo_disease_signatures/create_endo_signatures_json.py`
- `case_study_endomentriosis/disease_signatures/endo_disease_signatures/the_6_tomiko_study_v3/create_upset_plots.py`

### Earlier Removed During This Cleanup Pass

- `scripts/analysis/compare_cmap_tahoe_random_scores.py`
- `scripts/analysis/compare_heatmap_drugs.R`

## File and Path Fixes

The retained scripts were adjusted so they align with the cleaned repository layout.

### Updated Documentation and Repo Guidance

- `README.md`
- `.gitignore`
- `data/drug_signatures/README.md`
- `scripts/README.md`
- `scripts/execution/README_BATCH_CONFIG.md`

### Updated Batch and Execution Files

- `scripts/execution/run_batch_from_config.R`
- `scripts/execution/batch_configs/19_endo_standardized.yml`
- `scripts/execution/batch_configs/6_tomiko_endo_v3.yml`
- `scripts/execution/batch_configs/90_selected_diseases.yml`
- `scripts/execution/batch_configs/case_study_v2.yml`
- `scripts/execution/batch_configs/creeds_manual_config_all_avg.yml`
- `scripts/execution/batch_configs/endomentriosis_tomiko_config_v4.yml`
- `scripts/execution/batch_configs/sirota_lab_config_all_avg.yml`

### Updated Active Analysis and Preprocessing Scripts

- `scripts/analysis/compare_tahoe_cmap.py`
- `scripts/analysis/extract_pipeline_results_analysis.py`
- `scripts/preprocessing/convert_filtered_tahoe_to_rdata.R`
- `scripts/preprocessing/filter_cmap_data.py`
- `scripts/preprocessing/filter_tahoe_by_shared_genes.R`
- `scripts/preprocessing/generate_valid_instances.py`
- `scripts/preprocessing/process_creeds_signatures.py`
- `scripts/preprocessing/process_sirota_lab_signatures.py`
- `scripts/preprocessing/processing_known_drugs_data.py`
- `scripts/execution/convert_signatures_to_rds.R`

### Updated Manuscript and Figure Scripts

- `scripts/analysis/analyze_manuscript_data.R`
- `scripts/visualization/create_combined_visualizations.R`
- `scripts/visualization/create_figure3_from_raw_data.R`
- `scripts/visualization/create_moa_visualization_chart5.R`
- `scripts/visualization/create_normalized_fig6.R`
- `scripts/visualization/create_normalized_visualizations.R`
- `scripts/visualization/create_precision_recall_beautiful.R`
- `scripts/visualization/create_recall_focused_visualizations.R`
- `scripts/visualization/create_recall_graph.R`
- `scripts/visualization/create_venn_full_datasets.R`
- `scripts/visualization/create_venn_platform_coverage.R`
- `scripts/visualization/generate_disease_analysis_known_drugs_only.R`
- `scripts/visualization/generate_disease_specific_analysis.R`
- `scripts/visualization/generate_extended_manuscript_figures.R`
- `scripts/visualization/generate_manuscript_figures.R`

### Updated Case-Study Helpers

- `case_study_endomentriosis/disease_signatures/endo_disease_signatures/calculate_genes_retained.R`
- `case_study_autoimmune_diseases/analysis/20_autoimmune_results_1/show_drug_details.py`

### Naming / Typo Cleanup

- Renamed:
  - `case_study_endomentriosis/endo_disease_signatures/endomentriosis_unstratified_disease_signature.csv.csv`
  - to `case_study_endomentriosis/endo_disease_signatures/endomentriosis_unstratified_disease_signature.csv`

## Validation Performed

Syntax and parse checks were run on the key edited scripts.

### Python compile checks passed

- `scripts/analysis/compare_tahoe_cmap.py`
- `scripts/analysis/extract_pipeline_results_analysis.py`
- `scripts/preprocessing/filter_cmap_data.py`
- `scripts/preprocessing/generate_valid_instances.py`
- `scripts/preprocessing/process_creeds_signatures.py`
- `scripts/preprocessing/process_sirota_lab_signatures.py`
- `scripts/preprocessing/processing_known_drugs_data.py`
- `scripts/visualization/plot_disease_signature_info.py`
- `case_study_autoimmune_diseases/analysis/20_autoimmune_results_1/show_drug_details.py`

### R parse checks passed

- `scripts/analysis/analyze_manuscript_data.R`
- `scripts/preprocessing/filter_tahoe_by_shared_genes.R`
- `scripts/visualization/generate_manuscript_figures.R`
- `scripts/visualization/generate_extended_manuscript_figures.R`
- `scripts/visualization/create_figure3_from_raw_data.R`
- `case_study_endomentriosis/disease_signatures/endo_disease_signatures/calculate_genes_retained.R`

## Current Size Snapshot After Cleanup

At the time this report was written:

- `cdrpipe_comparative_analysis/` was approximately `2.7G`
- `creeds_diseases/results/creed_manual_standardised_results_OG_exp_8/` was approximately `2.6G`

This means the preserved Experiment 8 results now account for almost all remaining disk usage in the cleaned directory.

## Remaining Caveats

- Some historical `.txt`, `.md`, and report artifacts still contain old absolute paths or `tahoe_cmap_analysis` references.
- Those legacy references are mostly in archival notes and generated reports, not in the active retained workflow.
- `visuals/` was intentionally not reviewed or edited as part of this cleanup.
- This report documents the cleanup decisions and main changed files; it should be treated as the human-readable trace of the curation pass.

## Recommended Next Step

If a stricter public-release polish is needed, the next pass should focus only on historical documentation and generated text reports that still mention legacy paths. The computational workflow itself has already been curated into a much cleaner state.
