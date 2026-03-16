import pandas as pd
import glob
import os

print("\n" + "="*100)
print("VALIDATION: ESE DISCRETE P-VALUE METHOD vs ORIGINAL")
print("="*100 + "\n")

# Load original reference (discrete method)
ref_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/endo_tomiko_code/replication/end_to_end_ESE/drug_instances_ESE_from_raw.csv"
ref_df = pd.read_csv(ref_path)

# Load new DRpipe results (discrete method)
ese_dir = glob.glob("/Users/enockniyonkuru/Desktop/drug_repurposing/scripts/results/*/CMAP_Endometriosis_ESE_Strict_*")[0]
drpipe_hits = glob.glob(os.path.join(ese_dir, "*_q<0.*.csv"))[0]
drpipe_df = pd.read_csv(drpipe_hits)

# Get drug names
ref_drugs = set(ref_df['name'].str.lower())
drpipe_drugs = set(drpipe_df['name'].str.lower())

overlap = ref_drugs & drpipe_drugs
only_ref = ref_drugs - drpipe_drugs
only_drpipe = drpipe_drugs - ref_drugs

print(f"Reference (Original Discrete Method):  {len(ref_df)} drugs")
print(f"DRpipe (Discrete Method):              {len(drpipe_df)} drugs")
print(f"\nOverlap:                               {len(overlap)} drugs ({len(overlap)/len(ref_df)*100:.1f}%)")
print(f"Only in Reference:                     {len(only_ref)} drugs")
print(f"Only in DRpipe:                        {len(only_drpipe)} drugs\n")

print("="*100)
print("CONCLUSION:")
print("="*100 + "\n")

if len(overlap) / len(ref_df) > 0.50:
    print(f"✅ SUCCESS: {len(overlap)/len(ref_df)*100:.1f}% of reference drugs found by DRpipe")
    print(f"   Discrete p-value method IS the correct implementation!")
else:
    print(f"⚠️  Only {len(overlap)/len(ref_df)*100:.1f}% of reference drugs found")
    print(f"   Further investigation needed")

print("\nTop 10 overlapping drugs (in both):")
print("-" * 100)
overlapping = drpipe_df[drpipe_df['name'].str.lower().isin(overlap)].nsmallest(10, 'cmap_score')[['name', 'cmap_score', 'p', 'q']]
for idx, row in overlapping.iterrows():
    print(f"  {row['name']:<30} | Score: {row['cmap_score']:7.4f} | p: {row['p']:.8f} | q: {row['q']:.8f}")

if len(only_ref) > 0:
    print(f"\nMissing from DRpipe (n={len(only_ref)}):")
    print("-" * 100)
    ref_only = ref_df[ref_df['name'].str.lower().isin(only_ref)].nsmallest(5, 'cmap_score')[['name', 'cmap_score', 'p', 'q']]
    for idx, row in ref_only.iterrows():
        print(f"  {row['name']:<30} | Score: {row['cmap_score']:7.4f} | p: {row['p']:.8f} | q: {row['q']:.8f}")

print("\n" + "="*100 + "\n")
