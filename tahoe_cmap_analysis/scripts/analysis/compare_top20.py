import pandas as pd
import glob
import os

profiles = ["ESE", "INII", "IIINIV", "MSE", "PE", "Unstratified"]

print("\nTOP 20 DRUGS COMPARISON: Tomiko vs DRpipe")
print("=" * 100)

for p in profiles:
    # Read Tomiko's results (top 20)
    fname_map = {"IIINIV": "IIInIV", "INII": "InII"}
    fname = fname_map.get(p, p)
    tomiko_path = f"tomiko_cdrpipe_comparison/old_tomiko_drug_hits_comparison/drug_instances_{fname}.csv"
    tomiko_df = pd.read_csv(tomiko_path)
    # Sort by cmap_score (most negative = strongest reversal)
    tomiko_top20 = tomiko_df.nsmallest(20, 'cmap_score')[['name', 'cmap_score', 'q']].reset_index(drop=True)
    tomiko_top20_names = set(tomiko_top20['name'])
    
    # Read DRpipe's results (top 20)
    d = glob.glob(f"scripts/results/CMAP_Endometriosis_{p}_Strict_*")[0] if glob.glob(f"scripts/results/CMAP_Endometriosis_{p}_Strict_*") else None
    if d:
        f = glob.glob(os.path.join(d, "*_q<0.*.csv"))[0] if glob.glob(os.path.join(d, "*_q<0.*.csv")) else None
        if f:
            drpipe_df = pd.read_csv(f)
            # Sort by cmap_score (most negative = strongest reversal)
            drpipe_top20 = drpipe_df.nsmallest(20, 'cmap_score')[['name', 'cmap_score', 'q']].reset_index(drop=True)
            drpipe_top20_names = set(drpipe_top20['name'])
            
            # Calculate overlap
            overlap_top20 = tomiko_top20_names & drpipe_top20_names
            only_tomiko_top20 = tomiko_top20_names - drpipe_top20_names
            only_drpipe_top20 = drpipe_top20_names - tomiko_top20_names
            
            print(f"\n{p.upper()}")
            print("-" * 100)
            print(f"Overlap in top 20: {len(overlap_top20)}/20 ({len(overlap_top20)*5}%)")
            print(f"Only in Tomiko's top 20: {len(only_tomiko_top20)}")
            print(f"Only in DRpipe's top 20: {len(only_drpipe_top20)}")
            
            print(f"\nCommon top 20 drugs:")
            for i, drug in enumerate(sorted(overlap_top20), 1):
                tomiko_row = tomiko_top20[tomiko_top20['name'] == drug].iloc[0]
                drpipe_row = drpipe_top20[drpipe_top20['name'] == drug].iloc[0]
                print(f"  {i:2d}. {drug:<30} | Tomiko: score={tomiko_row['cmap_score']:7.3f} q={tomiko_row['q']:.2e} | DRpipe: score={drpipe_row['cmap_score']:7.3f} q={drpipe_row['q']:.2e}")
            
            if only_tomiko_top20:
                print(f"\nOnly in Tomiko's top 20:")
                for drug in sorted(only_tomiko_top20):
                    row = tomiko_top20[tomiko_top20['name'] == drug].iloc[0]
                    print(f"  • {drug:<30} score={row['cmap_score']:7.3f} q={row['q']:.2e}")
            
            if only_drpipe_top20:
                print(f"\nOnly in DRpipe's top 20:")
                for drug in sorted(only_drpipe_top20):
                    row = drpipe_top20[drpipe_top20['name'] == drug].iloc[0]
                    print(f"  • {drug:<30} score={row['cmap_score']:7.3f} q={row['q']:.2e}")

print("\n" + "=" * 100)
