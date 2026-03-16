import pandas as pd
import glob
import os

profiles = ["ESE", "INII", "IIINIV", "MSE", "PE", "Unstratified"]

# Read Tomiko's results
tomiko = {}
for p in profiles:
    fname_map = {"IIINIV": "IIInIV", "INII": "InII"}
    fname = fname_map.get(p, p)
    path = f"tomiko_cdrpipe_comparison/old_tomiko_drug_hits_comparison/drug_instances_{fname}.csv"
    df = pd.read_csv(path)
    tomiko[p] = set(df['name'].unique())

# Read DRpipe results
drpipe = {}
for p in profiles:
    d = glob.glob(f"scripts/results/CMAP_Endometriosis_{p}_Strict_*")[0] if glob.glob(f"scripts/results/CMAP_Endometriosis_{p}_Strict_*") else None
    if d:
        f = glob.glob(os.path.join(d, "*_q<0.*.csv"))[0] if glob.glob(os.path.join(d, "*_q<0.*.csv")) else None
        if f:
            df = pd.read_csv(f)
            drpipe[p] = set(df['name'].unique())
        else:
            drpipe[p] = set()
    else:
        drpipe[p] = set()

print("\nENDOMETRIOSIS COMPARISON: Tomiko vs DRpipe")
print("=" * 70)
print(f"{'Profile':<20} {'Tomiko':<10} {'DRpipe':<10} {'Overlap':<10} {'%':<8}")
print("=" * 70)

for p in profiles:
    t_count = len(tomiko[p])
    d_count = len(drpipe[p])
    overlap = len(tomiko[p] & drpipe[p])
    pct = round(overlap / t_count * 100, 1) if t_count > 0 else 0
    print(f"{p:<20} {t_count:<10} {d_count:<10} {overlap:<10} {pct:<8}%")

print("\n" + "=" * 70)
print("DETAILED ANALYSIS")
print("=" * 70)

for p in profiles:
    overlap = tomiko[p] & drpipe[p]
    only_tomiko = tomiko[p] - drpipe[p]
    only_drpipe = drpipe[p] - tomiko[p]
    
    print(f"\n{p}:")
    print(f"  Common ({len(overlap)}): {', '.join(sorted(overlap)[:5])}...")
    if only_tomiko:
        print(f"  Only Tomiko ({len(only_tomiko)}): {', '.join(sorted(only_tomiko)[:5])}...")
    if only_drpipe:
        print(f"  Only DRpipe ({len(only_drpipe)}): {', '.join(sorted(only_drpipe)[:5])}...")
