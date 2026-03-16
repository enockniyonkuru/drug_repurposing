import pandas as pd
import glob
import os

profiles = ["ESE", "INII", "IIINIV", "MSE", "PE", "Unstratified"]

print("\nWHY THE MISMATCH? Q-VALUE THRESHOLD ANALYSIS")
print("=" * 100)

for p in profiles:
    # Read Tomiko's results
    fname_map = {"IIINIV": "IIInIV", "INII": "InII"}
    fname = fname_map.get(p, p)
    tomiko_path = f"tomiko_cdrpipe_comparison/old_tomiko_drug_hits_comparison/drug_instances_{fname}.csv"
    tomiko_df = pd.read_csv(tomiko_path)
    tomiko_drugs = set(tomiko_df['name'].unique())
    
    # Read DRpipe's results
    d = glob.glob(f"scripts/results/CMAP_Endometriosis_{p}_Strict_*")[0] if glob.glob(f"scripts/results/CMAP_Endometriosis_{p}_Strict_*") else None
    if d:
        f = glob.glob(os.path.join(d, "*_q<0.*.csv"))[0] if glob.glob(os.path.join(d, "*_q<0.*.csv")) else None
        if f:
            drpipe_df = pd.read_csv(f)
            drpipe_drugs = set(drpipe_df['name'].unique())
            
            # Get mismatches
            only_tomiko = tomiko_drugs - drpipe_drugs
            only_drpipe = drpipe_drugs - tomiko_drugs
            
            print(f"\n{p.upper()}")
            print("-" * 100)
            print(f"Total Tomiko: {len(tomiko_drugs)} | Total DRpipe: {len(drpipe_drugs)}")
            print(f"Only Tomiko: {len(only_tomiko)} | Only DRpipe: {len(only_drpipe)}")
            
            # Analyze score distributions at boundary
            if len(only_tomiko) > 0:
                tomiko_boundary = tomiko_df[tomiko_df['name'].isin(only_tomiko)]['cmap_score']
                print(f"\nDrugs ONLY in Tomiko (n={len(only_tomiko)}):")
                print(f"  Score range: {tomiko_boundary.min():.3f} to {tomiko_boundary.max():.3f}")
                print(f"  Mean score: {tomiko_boundary.mean():.3f}")
                print(f"  Top 5 by score: {', '.join(tomiko_df[tomiko_df['name'].isin(only_tomiko)].nsmallest(5, 'cmap_score')['name'].tolist())}")
                print(f"  Bottom 5 by score: {', '.join(tomiko_df[tomiko_df['name'].isin(only_tomiko)].nlargest(5, 'cmap_score')['name'].tolist())}")
            
            if len(only_drpipe) > 0:
                drpipe_boundary = drpipe_df[drpipe_df['name'].isin(only_drpipe)]['cmap_score']
                print(f"\nDrugs ONLY in DRpipe (n={len(only_drpipe)}):")
                print(f"  Score range: {drpipe_boundary.min():.3f} to {drpipe_boundary.max():.3f}")
                print(f"  Mean score: {drpipe_boundary.mean():.3f}")
                print(f"  Top 5 by score: {', '.join(drpipe_df[drpipe_df['name'].isin(only_drpipe)].nsmallest(5, 'cmap_score')['name'].tolist())}")
                print(f"  Bottom 5 by score: {', '.join(drpipe_df[drpipe_df['name'].isin(only_drpipe)].nlargest(5, 'cmap_score')['name'].tolist())}")
            
            # Check overlapping drugs near threshold
            overlap = tomiko_drugs & drpipe_drugs
            if len(overlap) > 0:
                print(f"\nScore comparison for overlapping drugs:")
                # Get score ranges
                tomiko_overlap_scores = tomiko_df[tomiko_df['name'].isin(overlap)]['cmap_score']
                drpipe_overlap_scores = drpipe_df[drpipe_df['name'].isin(overlap)]['cmap_score']
                print(f"  Tomiko score range: {tomiko_overlap_scores.min():.3f} to {tomiko_overlap_scores.max():.3f}")
                print(f"  DRpipe score range: {drpipe_overlap_scores.min():.3f} to {drpipe_overlap_scores.max():.3f}")
                
                # Compare a few drugs
                sample_drugs = overlap.pop() if len(overlap) == 1 else list(overlap)[:3]
                if not isinstance(sample_drugs, list):
                    sample_drugs = [sample_drugs]
                
                print(f"\n  Sample drug score comparisons:")
                for drug in sample_drugs[:5]:
                    t_score = tomiko_df[tomiko_df['name'] == drug]['cmap_score'].values
                    d_score = drpipe_df[drpipe_df['name'] == drug]['cmap_score'].values
                    if len(t_score) > 0 and len(d_score) > 0:
                        diff = abs(t_score[0] - d_score[0])
                        print(f"    {drug:<30} Tomiko: {t_score[0]:7.3f} | DRpipe: {d_score[0]:7.3f} | Diff: {diff:6.3f}")

print("\n" + "=" * 100)
print("HYPOTHESIS: Mismatches likely occur at the threshold boundary where small score")
print("variations (from permutation randomness or p-value calculation method) cause")
print("drugs to cross the q-value threshold (q < 0.0001).")
print("=" * 100)
