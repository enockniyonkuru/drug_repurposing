#!/usr/bin/env python3
"""
Script to explore and generate a report about the known_drugs and disease parquet files.
"""


import pandas as pd
from datetime import datetime

# Define file paths
DATA_DIR = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/data/known_drugs"
KNOWN_DRUGS_FILE = f"{DATA_DIR}/known_drug_info_data.parquet"
DISEASE_FILE = f"{DATA_DIR}/disease.parquet"
REPORT_FILE = "data_exploration_report.md"

def analyze_dataframe(df, name):
    """Generate analysis summary for a dataframe."""
    report = []
    report.append(f"## {name}\n")
    report.append(f"### Basic Information\n")
    report.append(f"- **Shape**: {df.shape[0]} rows × {df.shape[1]} columns\n")
    report.append(f"- **Memory Usage**: {df.memory_usage(deep=True).sum() / 1024:.2f} KB\n")
    
    report.append(f"\n### Column Information\n")
    report.append("| Column | Data Type | Non-Null Count | Null Count | Unique Values |\n")
    report.append("|--------|-----------|----------------|------------|---------------|\n")
    
    for col in df.columns:
        dtype = str(df[col].dtype)
        non_null = df[col].notna().sum()
        null_count = df[col].isna().sum()
        try:
            unique = df[col].nunique()
        except TypeError:
            unique = "N/A (complex type)"
        report.append(f"| {col} | {dtype} | {non_null} | {null_count} | {unique} |\n")
    
    report.append(f"\n### First 10 Rows\n")
    report.append("```\n")
    report.append(df.head(10).to_string())
    report.append("\n```\n")
    
    report.append(f"\n### Statistical Summary (Numeric Columns)\n")
    numeric_cols = df.select_dtypes(include=['number']).columns
    if len(numeric_cols) > 0:
        report.append("```\n")
        report.append(df[numeric_cols].describe().to_string())
        report.append("\n```\n")
    else:
        report.append("*No numeric columns found.*\n")
    
    report.append(f"\n### Sample Values for Each Column\n")
    for col in df.columns:
        try:
            sample_vals = df[col].dropna().unique()[:5]
            report.append(f"- **{col}**: {list(sample_vals)}\n")
        except TypeError:
            # Handle unhashable types (arrays, lists, etc.)
            sample_vals = df[col].dropna().head(3).tolist()
            report.append(f"- **{col}**: {sample_vals} (complex type)\n")
    
    return "".join(report)

def main():
    print("Loading data files...")
    
    # Load datasets
    try:
        known_drugs = pd.read_parquet(KNOWN_DRUGS_FILE)
        print(f"✓ Loaded known_drug_info_data.parquet: {known_drugs.shape}")
    except Exception as e:
        print(f"✗ Error loading known_drug_info_data.parquet: {e}")
        known_drugs = None
    
    try:
        disease = pd.read_parquet(DISEASE_FILE)
        print(f"✓ Loaded disease.parquet: {disease.shape}")
    except Exception as e:
        print(f"✗ Error loading disease.parquet: {e}")
        disease = None
    
    # Generate report
    report = []
    report.append(f"# Data Exploration Report\n")
    report.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
    report.append("---\n\n")
    
    if known_drugs is not None:
        report.append(analyze_dataframe(known_drugs, "Known Drugs Info Data"))
        report.append("\n---\n\n")
    
    if disease is not None:
        report.append(analyze_dataframe(disease, "Disease Data"))
    
    # Save report
    with open(REPORT_FILE, 'w') as f:
        f.write("".join(report))
    
    print(f"\n✓ Report saved to: {REPORT_FILE}")
    
    # Print summary to console
    print("\n" + "="*60)
    print("QUICK SUMMARY")
    print("="*60)
    
    if known_drugs is not None:
        print(f"\nKnown Drugs Info Data:")
        print(f"  - Rows: {known_drugs.shape[0]}")
        print(f"  - Columns: {list(known_drugs.columns)}")
    
    if disease is not None:
        print(f"\nDisease Data:")
        print(f"  - Rows: {disease.shape[0]}")
        print(f"  - Columns: {list(disease.columns)}")

if __name__ == "__main__":
    main()
