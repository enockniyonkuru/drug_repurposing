#!/usr/bin/env python3
"""
Script to analyze known_drugs and disease datasets.
Generates a comprehensive report about the data.
"""

import pandas as pd
import os
from datetime import datetime

# Data paths
data_dir = "../../data/known_drugs/"
known_drugs_path = os.path.join(data_dir, "known_drug_info_data.parquet")
disease_path = os.path.join(data_dir, "disease.parquet")

# Output report path
output_dir = "./"
report_path = os.path.join(output_dir, "data_analysis_report.txt")

def generate_report():
    """Generate comprehensive data analysis report."""
    
    # Load datasets
    print("Loading datasets...")
    known_drugs_data = pd.read_parquet(known_drugs_path)
    disease_data = pd.read_parquet(disease_path)
    
    # Start report
    report_lines = []
    report_lines.append("=" * 80)
    report_lines.append("DATA ANALYSIS REPORT")
    report_lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report_lines.append("=" * 80)
    report_lines.append("")
    
    # === KNOWN DRUGS DATA ===
    report_lines.append("KNOWN DRUGS DATA ANALYSIS")
    report_lines.append("-" * 80)
    report_lines.append("")
    
    report_lines.append("Dataset Shape:")
    report_lines.append(f"  Rows: {known_drugs_data.shape[0]}")
    report_lines.append(f"  Columns: {known_drugs_data.shape[1]}")
    report_lines.append("")
    
    report_lines.append("Column Names and Data Types:")
    for col, dtype in known_drugs_data.dtypes.items():
        report_lines.append(f"  - {col}: {dtype}")
    report_lines.append("")
    
    report_lines.append("First 5 Rows:")
    report_lines.append(known_drugs_data.head().to_string())
    report_lines.append("")
    
    report_lines.append("Data Summary Statistics:")
    report_lines.append(known_drugs_data.describe(include='all').to_string())
    report_lines.append("")
    
    report_lines.append("Missing Values:")
    missing = known_drugs_data.isnull().sum()
    for col, count in missing.items():
        if count > 0:
            report_lines.append(f"  - {col}: {count} ({count/len(known_drugs_data)*100:.2f}%)")
    if missing.sum() == 0:
        report_lines.append("  No missing values found")
    report_lines.append("")
    
    report_lines.append("Unique Values per Column:")
    for col in known_drugs_data.columns:
        unique_count = known_drugs_data[col].nunique()
        report_lines.append(f"  - {col}: {unique_count} unique values")
    report_lines.append("")
    
    # === DISEASE DATA ===
    report_lines.append("=" * 80)
    report_lines.append("DISEASE DATA ANALYSIS")
    report_lines.append("-" * 80)
    report_lines.append("")
    
    report_lines.append("Dataset Shape:")
    report_lines.append(f"  Rows: {disease_data.shape[0]}")
    report_lines.append(f"  Columns: {disease_data.shape[1]}")
    report_lines.append("")
    
    report_lines.append("Column Names and Data Types:")
    for col, dtype in disease_data.dtypes.items():
        report_lines.append(f"  - {col}: {dtype}")
    report_lines.append("")
    
    report_lines.append("First 5 Rows:")
    report_lines.append(disease_data.head().to_string())
    report_lines.append("")
    
    report_lines.append("Data Summary Statistics:")
    report_lines.append(disease_data.describe(include='all').to_string())
    report_lines.append("")
    
    report_lines.append("Missing Values:")
    missing = disease_data.isnull().sum()
    for col, count in missing.items():
        if count > 0:
            report_lines.append(f"  - {col}: {count} ({count/len(disease_data)*100:.2f}%)")
    if missing.sum() == 0:
        report_lines.append("  No missing values found")
    report_lines.append("")
    
    report_lines.append("Unique Values per Column:")
    for col in disease_data.columns:
        unique_count = disease_data[col].nunique()
        report_lines.append(f"  - {col}: {unique_count} unique values")
    report_lines.append("")
    
    # === COMPARISON ===
    report_lines.append("=" * 80)
    report_lines.append("DATA COMPARISON")
    report_lines.append("-" * 80)
    report_lines.append(f"Known Drugs Dataset Size: {known_drugs_data.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    report_lines.append(f"Disease Dataset Size: {disease_data.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    report_lines.append("")
    
    # Write report
    report_text = "\n".join(report_lines)
    
    # Print to console
    print(report_text)
    
    # Save to file
    with open(report_path, 'w') as f:
        f.write(report_text)
    
    print(f"\n{'=' * 80}")
    print(f"Report saved to: {report_path}")
    print(f"{'=' * 80}")

if __name__ == "__main__":
    generate_report()
