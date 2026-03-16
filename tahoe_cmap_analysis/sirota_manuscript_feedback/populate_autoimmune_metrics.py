#!/usr/bin/env python3
"""
Populate autoimmune disease recovery metrics from Table1_Disease_Summary.csv
"""

import pandas as pd
import os

# Read Table1 from the validation folder
table1_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/validation/20_autoimmune_results_1/Table1_Disease_Summary.csv"
output_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/sirota_manuscript_feedback/autoimmune_diseases_recovery_metrics.csv"

print("Populating autoimmune disease recovery metrics...")
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
    
    # P: Available in CMAP or TAHOE (maximum recoverable)
    available_cmap = int(row['Available (CMAP)'])
    available_tahoe = int(row['Available (TAHOE)'])
    P = available_cmap + available_tahoe  # Total known drugs in at least one database
    
    # I: Total Candidates from DRpipe predictions
    I = int(row['Total Candidates'])
    
    # S: Total Recovered - intersection of predicted with known drugs in databases
    S = int(row['Total Recovered'])
    
    # S/P: Recovery rate (already calculated in table)
    if P > 0:
        S_P_rate = (S / P) * 100
    else:
        S_P_rate = 0.0
    S_P = f"{S_P_rate:.2f}%"
    
    # S/I: Precision rate (fraction of predicted that are actually known)
    if I > 0:
        S_I_rate = (S / I) * 100
    else:
        S_I_rate = 0.0
    S_I = f"{S_I_rate:.2f}%"
    
    output_data.append({
        'disease_name': disease_name,
        'U': U,
        'P': P,
        'I': I,
        'S': S,
        'S/P': S_P,
        'S/I': S_I
    })

# Create dataframe and save
df_output = pd.DataFrame(output_data)
df_output.to_csv(output_path, index=False)

print(f"\n✓ Populated {len(df_output)} diseases")
print(f"✓ Saved to: {output_path}")

print("\n" + "=" * 80)
print("Summary Statistics:")
print(df_output.to_string(index=False))

print("\n" + "=" * 80)
print("Column Descriptions:")
print("  U   = All known disease-drug pairs in DrugBank (Known Drugs)")
print("  P   = Known drugs available in CMAP or TAHOE databases")
print("  I   = Drugs predicted as repurposing candidates by DRpipe")
print("  S   = Successfully recovered drugs (intersection of I and P)")
print("  S/P = Recovery rate (%): Percentage of known drugs that were predicted")
print("  S/I = Precision rate (%): Percentage of predictions that are known drugs")
