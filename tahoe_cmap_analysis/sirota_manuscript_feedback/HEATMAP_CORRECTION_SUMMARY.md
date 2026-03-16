# Heatmap Data Verification and Correction

## Issue Identified

The initially generated heatmaps (`heatmap_recovery_source_innovative.pdf` and related files) were based on recovered drugs data from Open Targets, which resulted in **inconsistent drug counts** compared to the official source data in `20_autoimmune.xlsx`.

### Data Discrepancy Example
**Multiple Sclerosis:**
- Excel (official): 18 total unique drugs recovered
- Generated from CSV: 26 total unique drugs

This discrepancy was found across most diseases.

## Root Cause

The `show_drug_details.py` script generated recovered drug CSV files using Open Targets disease-drug mappings, which included MORE drugs than the original analysis that created the Excel file.

## Resolution: Option A Selected

**Use Excel data directly** as the source of truth to maintain consistency with existing visualizations (figure2_heatmap.png).

## Correct Data (from 20_autoimmune.xlsx)

**Total recovered drugs across all 20 autoimmune diseases:**
- CMAP Only: **54 drugs**
- TAHOE Only: **110 drugs**
- Both Methods: **6 drugs**
- **Total Unique: 170 drugs**

This matches the official counts in the Excel file.

## New Correct Visualizations Generated

All files are created from `20_autoimmune.xlsx` directly:

### 1. **heatmap_recovery_source_from_excel.png/pdf**
- Color-coded heatmap showing recovery source (CMAP Only, Both, TAHOE Only)
- All 20 diseases with correct drug counts
- Sorted by disease for easy comparison

### 2. **heatmap_recovery_rates_from_excel.png/pdf**
- CMAP vs TAHOE recovery rates (%)
- Shows performance comparison across all 20 diseases
- Matches figure2_heatmap.png data exactly

### 3. **heatmap_recovery_statistics_from_excel.png/pdf**
- Left panel: Distribution of recovery sources (pie chart)
- Right panel: Top 15 diseases by total drug recovery

### 4. **recovery_comparison_table_from_excel.png/pdf**
- Complete recovery data table for all 20 diseases
- Columns: Disease, CMAP Rate %, TAHOE Rate %, CMAP Only, Both, TAHOE Only, Total
- Reference for all recovery metrics

## Which Files to Use

✅ **USE THESE (Correct - from Excel):**
- `heatmap_recovery_source_from_excel.*`
- `heatmap_recovery_rates_from_excel.*`
- `heatmap_recovery_statistics_from_excel.*`
- `recovery_comparison_table_from_excel.*`

❌ **DO NOT USE (Incorrect - from Open Targets CSV):**
- `heatmap_recovery_source_innovative.*`
- `heatmap_CMAP_recovered_drugs.*`
- `heatmap_TAHOE_recovered_drugs.*`
- `heatmap_top100_drugs_heatmap.*`
- `heatmap_known_drugs_recovery.*`

## Verification

✓ All new Excel-based heatmaps match `20_autoimmune.xlsx` exactly
✓ Data is consistent with `figure2_heatmap.png`
✓ All 20 autoimmune diseases represented with correct recovery counts
✓ Recovery rate percentages match official analysis

## Files Modified

- Created: `create_recovery_heatmaps_from_excel.py` - Script to generate correct heatmaps from Excel
- Modified: `show_drug_details.py` - Expanded from 6 to 20 diseases (note: data doesn't match Excel)

## Recommendation

For manuscript and analysis purposes, use the new Excel-based heatmaps to ensure consistency with the official recovery analysis in `20_autoimmune.xlsx`.
