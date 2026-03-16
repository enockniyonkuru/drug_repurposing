import pandas as pd
import glob
import os

print("\n" + "="*100)
print("COMPARISON: ESE RESULTS (drug_hits_comparison)")
print("="*100 + "\n")

# Load reference from drug_hits_comparison
ref_path = "/Users/enockniyonkuru/Desktop/drug_repurposing/endo_tomiko_code/replication/drug_hits_comparison/drug_instances_ESE.csv"
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

print(f"Reference (drug_hits_comparison):      {len(ref_df)} drugs")
print(f"DRpipe (discrete method):              {len(drpipe_df)} drugs")
print(f"\nOverlap:                               {len(overlap)} drugs ({len(overlap)/len(ref_df)*100:.1f}%)")
print(f"Only in Reference:                     {len(only_ref)} drugs")
print(f"Only in DRpipe:                        {len(only_drpipe)} drugs\n")

print("="*100)
print("TOP 10 OVERLAPPING DRUGS:")
print("="*100 + "\n")
overlapping = drpipe_df[drpipe_df['name'].str.lower().isin(overlap)].nsmallest(10, 'cmap_score')[['name', 'cmap_score', 'p', 'q']]
for idx, row in overlapping.iterrows():
    print(f"  {row['name']:<30} | Score: {row['cmap_score']:7.4f} | p: {row['p']:.8f} | q: {row['q']:.8f}")

if len(only_ref) > 0:
    print(f"\n\nMISSING FROM DRPIPE (n={len(only_ref)}):")
    print("="*100 + "\n")
    ref_only = ref_df[ref_df['name'].str.lower().isin(only_ref)].nsmallest(10, 'cmap_score')[['name', 'cmap_score', 'p', 'q']]
    for idx, row in ref_only.iterrows():
        print(f"  {row['name']:<30} | Score: {row['cmap_score']:7.4f} | p: {row['p']:.8f} | q: {row['q']:.8f}")

if len(only_drpipe) > 0:
    print(f"\n\nONLY IN DRPIPE (n={len(only_drpipe)}):")
    print("="*100 + "\n")
    drpipe_only = drpipe_df[drpipe_df['name'].str.lower().isin(only_drpipe)].nsmallest(10, 'cmap_score')[['name', 'cmap_score', 'p', 'q']]
    for idx, row in drpipe_only.iterrows():
        print(f"  {row['name']:<30} | Score: {row['cmap_score']:7.4f} | p: {row['p']:.8f} | q: {row['q']:.8f}")

print("\n" + "="*100 + "\n")
