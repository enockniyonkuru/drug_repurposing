#!/usr/bin/env python3
"""
Extract statistics for Sankey diagram
"""

import pandas as pd
from pathlib import Path

print("=" * 80)
print("EXTRACTING STATISTICS FOR SANKEY DIAGRAM")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "intermediate_data"
about_dir = base_dir.parent

# Load data
print("\n✓ Loading data...")
cmap_results = pd.read_csv(output_dir / "cmap_precision_recall_per_disease.csv")
tahoe_results = pd.read_csv(output_dir / "tahoe_precision_recall_per_disease.csv")
all_cmap = pd.read_csv(about_dir / "all_discoveries_cmap.csv")
all_tahoe = pd.read_csv(about_dir / "all_discoveries_tahoe.csv")

# Calculate totals
print("\n" + "=" * 80)
print("SANKEY DIAGRAM STATISTICS")
print("=" * 80)

# Total predictions (I = Predictions)
total_cmap_predictions = cmap_results['I'].sum()
total_tahoe_predictions = tahoe_results['I'].sum()

# Total recovered (S = Recovered)
total_cmap_recovered = cmap_results['S'].sum()
total_tahoe_recovered = tahoe_results['S'].sum()

# Total possible (P = Maximum possible in universe)
total_cmap_possible = cmap_results['P'].sum()
total_tahoe_possible = tahoe_results['P'].sum()

# Unique drugs in each discovery
unique_cmap_drugs = all_cmap['drug_common_name'].nunique()
unique_tahoe_drugs = all_tahoe['drug_common_name'].nunique()

# Unique drugs in both
cmap_drugs_set = set(all_cmap['drug_common_name'].unique())
tahoe_drugs_set = set(all_tahoe['drug_common_name'].unique())
shared_drugs = cmap_drugs_set.intersection(tahoe_drugs_set)
cmap_only_drugs = cmap_drugs_set - tahoe_drugs_set
tahoe_only_drugs = tahoe_drugs_set - cmap_drugs_set

# Unique diseases
unique_cmap_diseases = all_cmap['disease_name'].nunique()
unique_tahoe_diseases = all_tahoe['disease_name'].nunique()

print("\n📊 DRUG PREDICTIONS & RECOVERY")
print(f"\nCMAP:")
print(f"  • Total predictions: {total_cmap_predictions:,}")
print(f"  • Total recovered: {total_cmap_recovered:,}")
print(f"  • Recovery rate: {(total_cmap_recovered/total_cmap_predictions)*100:.1f}%")
print(f"  • Unique drugs in discoveries: {unique_cmap_drugs:,}")
print(f"  • Unique diseases: {unique_cmap_diseases:,}")

print(f"\nTAHOE:")
print(f"  • Total predictions: {total_tahoe_predictions:,}")
print(f"  • Total recovered: {total_tahoe_recovered:,}")
print(f"  • Recovery rate: {(total_tahoe_recovered/total_tahoe_predictions)*100:.1f}%")
print(f"  • Unique drugs in discoveries: {unique_tahoe_drugs:,}")
print(f"  • Unique diseases: {unique_tahoe_diseases:,}")

print(f"\n🔄 DRUG OVERLAP")
print(f"  • Drugs in both CMAP & TAHOE: {len(shared_drugs):,}")
print(f"  • CMAP only: {len(cmap_only_drugs):,}")
print(f"  • TAHOE only: {len(tahoe_only_drugs):,}")
print(f"  • Total unique drugs across both: {len(cmap_drugs_set | tahoe_drugs_set):,}")

print(f"\n📈 RECOVERY COMPARISON")
print(f"  • CMAP recovery: {(total_cmap_recovered/total_cmap_predictions)*100:.1f}%")
print(f"  • TAHOE recovery: {(total_tahoe_recovered/total_tahoe_predictions)*100:.1f}%")
print(f"  • Not recovered (CMAP): {total_cmap_predictions - total_cmap_recovered:,}")
print(f"  • Not recovered (TAHOE): {total_tahoe_predictions - total_tahoe_recovered:,}")

# Calculate co-recovery (both platforms recovered same drug-disease pair)
print(f"\n💾 DISEASE STATISTICS")
print(f"  • CMAP diseases: {len(cmap_results)}")
print(f"  • TAHOE diseases: {len(tahoe_results)}")
print(f"  • Mean precision CMAP: {cmap_results['Precision_%'].mean():.1f}%")
print(f"  • Mean precision TAHOE: {tahoe_results['Precision_%'].mean():.1f}%")
print(f"  • Mean recall CMAP: {cmap_results['Recall_%'].mean():.1f}%")
print(f"  • Mean recall TAHOE: {tahoe_results['Recall_%'].mean():.1f}%")

print("\n" + "=" * 80)
print("SUGGESTED SANKEY UPDATES")
print("=" * 80)

print(f"""
Update your Sankey diagram with these numbers:

LEFT SIDE (Total Predictions):
├── CMAP Predictions: {total_cmap_predictions:,}
└── TAHOE Predictions: {total_tahoe_predictions:,}

MIDDLE (Drug Overlap):
├── Available in Both: {len(shared_drugs):,}
├── CMAP Only: {len(cmap_only_drugs):,}
└── TAHOE Only: {len(tahoe_only_drugs):,}

RIGHT SIDE (Recovery):
├── Recovered CMAP: {total_cmap_recovered:,} ({(total_cmap_recovered/total_cmap_predictions)*100:.1f}%)
├── Recovered TAHOE: {total_tahoe_recovered:,} ({(total_tahoe_recovered/total_tahoe_predictions)*100:.1f}%)
├── Not Recovered (CMAP): {total_cmap_predictions - total_cmap_recovered:,}
└── Not Recovered (TAHOE): {total_tahoe_predictions - total_tahoe_recovered:,}

DISEASE COVERAGE:
├── CMAP diseases analyzed: {len(cmap_results)}
└── TAHOE diseases analyzed: {len(tahoe_results)}
""")

print("=" * 80)
