#!/usr/bin/env python3
"""
Populate autoimmune disease recovery metrics with separate CMAP and TAHOE columns
"""

import pandas as pd
import os

# Read Table1 from the validation folder
table1_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/Table1_Disease_Summary.csv"
output_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback/autoimmune_diseases_recovery_metrics.csv"

print("Populating autoimmune disease recovery metrics with CMAP/TAHOE separation...")
print("=" * 80)

# Read the existing table
df_table1 = pd.read_csv(table1_path)
print(f"\nLoaded Table1 with {len(df_table1)} diseases")

# Create the output dataframe
output_data = []

for idx, row in df_table1.iterrows():
    disease_name = row['Disease']
    
    # U: Known Drugs (DB) - all known disease-drug pairs from DrugBank
    U = int(row['Known Drugs (DB)'])
    
    # CMAP metrics
    cmap_available = int(row['Available (CMAP)'])
    cmap_hits = int(row['Hits (CMAP)'])
    cmap_recovered = int(row['Recovered (CMAP)'])
    cmap_recovery_rate = row['Recovery Rate (CMAP)']
    
    # TAHOE metrics
    tahoe_available = int(row['Available (TAHOE)'])
    tahoe_hits = int(row['Hits (TAHOE)'])
    tahoe_recovered = int(row['Recovered (TAHOE)'])
    tahoe_recovery_rate = row['Recovery Rate (TAHOE)']
    
    # Total metrics
    total_available = cmap_available + tahoe_available
    total_hits = cmap_hits + tahoe_hits
    total_recovered = int(row['Total Recovered'])
    overall_recovery = row['Overall Recovery Rate']
    
    output_data.append({
        'Disease Name': disease_name,
        'All Known Drug-Disease Pairs [U]': U,
        'Known Drugs CMAP [P_cmap]': cmap_available,
        'DRpipe Predictions CMAP [I_cmap]': cmap_hits,
        'Successfully Recovered CMAP [S_cmap]': cmap_recovered,
        'Recovery Rate CMAP [S/P_cmap]': cmap_recovery_rate,
        'Known Drugs TAHOE [P_tahoe]': tahoe_available,
        'DRpipe Predictions TAHOE [I_tahoe]': tahoe_hits,
        'Successfully Recovered TAHOE [S_tahoe]': tahoe_recovered,
        'Recovery Rate TAHOE [S/P_tahoe]': tahoe_recovery_rate,
        'Total Known Drugs [P]': total_available,
        'Total DRpipe Predictions [I]': total_hits,
        'Total Successfully Recovered [S]': total_recovered,
        'Overall Recovery Rate [S/P]': overall_recovery
    })

# Create dataframe and save
df_output = pd.DataFrame(output_data)
df_output.to_csv(output_path, index=False)

print(f"\n✓ Populated {len(df_output)} diseases")
print(f"✓ Saved to: {output_path}")

print("\n" + "=" * 80)
print("Column Structure:")
print("\n1. Disease Identification:")
print("   - Disease Name: Disease being analyzed")
print("   - All Known Drug-Disease Pairs [U]: All known drugs in DrugBank")
print("\n2. CMAP-Specific Metrics:")
print("   - Known Drugs CMAP [P_cmap]: Known drugs available in CMAP")
print("   - DRpipe Predictions CMAP [I_cmap]: Predicted candidates in CMAP")
print("   - Successfully Recovered CMAP [S_cmap]: Predictions matching known drugs")
print("   - Recovery Rate CMAP [S/P_cmap]: % of known drugs recovered in CMAP")
print("\n3. TAHOE-Specific Metrics:")
print("   - Known Drugs TAHOE [P_tahoe]: Known drugs available in TAHOE")
print("   - DRpipe Predictions TAHOE [I_tahoe]: Predicted candidates in TAHOE")
print("   - Successfully Recovered TAHOE [S_tahoe]: Predictions matching known drugs")
print("   - Recovery Rate TAHOE [S/P_tahoe]: % of known drugs recovered in TAHOE")
print("\n4. Combined Metrics:")
print("   - Total Known Drugs [P]: All known drugs in either database")
print("   - Total DRpipe Predictions [I]: All predictions from both databases")
print("   - Total Successfully Recovered [S]: All successful recoveries")
print("   - Overall Recovery Rate [S/P]: Overall recovery percentage")
