#!/usr/bin/env python3
"""
Top-N drug frequency analysis across diseases.

For each disease, rank drug hits by cmap_score (most negative = best),
take the top N, then count how often each drug of interest appears in
the top N across all diseases.

Requested by Jess/Tomiko.
"""

import csv
import re
import os
from collections import defaultdict, Counter
from pathlib import Path
from glob import glob

# ---------- config ----------
RESULTS_DIR = Path(__file__).resolve().parents[2] / "results" / "manual_standardized_all_diseases_results"
OUT_DIR = Path(__file__).resolve().parents[2] / "results" / "drug_frequency_analysis"
OUT_DIR.mkdir(parents=True, exist_ok=True)

TOP_N_VALUES = [20, 50, 100]  # analyze multiple thresholds

# Jess's drugs of interest (normalised keys -> display name)
DRUGS_OF_INTEREST = {
    "ly294002": "LY-294002",
    "sirolimus": "sirolimus",
    "rapamycin": "sirolimus",
    "wortmannin": "wortmannin",
    "sb203580": "SB-203580",
    "sb202190": "SB-203580",
    "naringenin": "naringenin",
    "naringin": "naringenin",
    "gossypol": "gossypol",
}

CANONICAL_ORDER = ["LY-294002", "sirolimus", "wortmannin", "SB-203580", "naringenin", "gossypol"]


def normalise(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def match_drug(drug_name):
    """Return canonical name if drug matches one of interest, else None."""
    norm = normalise(drug_name)
    for pattern, canonical in DRUGS_OF_INTEREST.items():
        if pattern in norm or norm in pattern:
            return canonical
    return None


def parse_disease_dir(dirname):
    """Extract disease name and platform from directory name like 'acne_cmap_20251121-195547'."""
    # Remove timestamp suffix
    parts = dirname.rsplit("_", 1)
    if len(parts) == 2 and len(parts[1]) == 15:  # YYYYMMDD-HHMMSS
        base = parts[0]
    else:
        base = dirname
    # Last segment before timestamp is platform
    if base.endswith("_cmap"):
        return base[:-5].replace("_", " "), "CMAP"
    elif base.endswith("_tahoe"):
        return base[:-6].replace("_", " "), "TAHOE"
    else:
        return base.replace("_", " "), "unknown"


def load_hits(csv_path):
    """Load drug hits from a results CSV, return list of (drug_name, cmap_score)."""
    hits = []
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            drug = row.get("drug_name") or row.get("name", "")
            score_str = row.get("cmap_score", "")
            try:
                score = float(score_str)
            except (ValueError, TypeError):
                continue
            if drug:
                hits.append((drug.strip(), score))
    return hits


# ---------- load all disease results ----------
print("Loading disease results...")
disease_results = []  # list of dicts: {disease, platform, hits: [(drug, score)]}

result_dirs = sorted(glob(str(RESULTS_DIR / "*")))
for dpath in result_dirs:
    if not os.path.isdir(dpath):
        continue
    dirname = os.path.basename(dpath)
    disease, platform = parse_disease_dir(dirname)

    # Find the hits CSV
    csvs = glob(os.path.join(dpath, "*_hits_*.csv"))
    if not csvs:
        continue
    hits = load_hits(csvs[0])
    if hits:
        disease_results.append({
            "disease": disease,
            "platform": platform,
            "hits": hits,
        })

print(f"Loaded {len(disease_results)} disease-platform results\n")

# ---------- For each top-N, compute frequency ----------
for top_n in TOP_N_VALUES:
    print("=" * 80)
    print(f"TOP {top_n} ANALYSIS: For each disease, take the {top_n} best-scoring drugs")
    print("=" * 80)

    # Count appearances of each drug in top-N across diseases
    drug_topn_counter = Counter()        # all platforms combined
    drug_topn_tahoe = Counter()
    drug_topn_cmap = Counter()
    n_diseases_tahoe = 0
    n_diseases_cmap = 0

    # Track which diseases Jess's drugs appear in top-N
    jess_topn = defaultdict(lambda: {"TAHOE": [], "CMAP": []})

    for dr in disease_results:
        # Sort by cmap_score ascending (most negative first = best reversal)
        ranked = sorted(dr["hits"], key=lambda x: x[1])

        # Deduplicate by drug name (keep best score)
        seen = set()
        unique_ranked = []
        for drug, score in ranked:
            if drug.lower() not in seen:
                seen.add(drug.lower())
                unique_ranked.append((drug, score))

        top_drugs = unique_ranked[:top_n]

        if dr["platform"] == "TAHOE":
            n_diseases_tahoe += 1
        else:
            n_diseases_cmap += 1

        for drug, score in top_drugs:
            drug_topn_counter[drug] += 1
            if dr["platform"] == "TAHOE":
                drug_topn_tahoe[drug] += 1
            else:
                drug_topn_cmap[drug] += 1

            canonical = match_drug(drug)
            if canonical:
                jess_topn[canonical][dr["platform"]].append(dr["disease"])

    total_disease_runs = len(disease_results)
    print(f"\nTotal disease-platform runs: {total_disease_runs} "
          f"({n_diseases_tahoe} TAHOE, {n_diseases_cmap} CMAP)\n")

    # --- Jess's drugs ---
    print(f"Jess's drugs — appearances in top {top_n} across diseases:")
    print(f"{'Drug':<20}{'TAHOE':<12}{'CMAP':<12}{'Total':<12}{'% of diseases':<15}")
    print("-" * 71)
    for canonical in CANONICAL_ORDER:
        info = jess_topn[canonical]
        t = len(set(info["TAHOE"]))
        c = len(set(info["CMAP"]))
        total = t + c
        pct = 100 * total / total_disease_runs if total_disease_runs else 0
        print(f"{canonical:<20}{t:<12}{c:<12}{total:<12}{pct:.1f}%")

    # --- Overall top 20 most frequent in top-N ---
    print(f"\nMost frequent drugs appearing in top {top_n} across diseases:")
    print(f"{'Rank':<6}{'Drug':<45}{'# Runs':<10}{'% Runs':<10}{'TAHOE':<8}{'CMAP':<8}")
    print("-" * 87)
    for rank, (drug, count) in enumerate(drug_topn_counter.most_common(30), 1):
        t = drug_topn_tahoe.get(drug, 0)
        c = drug_topn_cmap.get(drug, 0)
        pct = 100 * count / total_disease_runs
        print(f"{rank:<6}{drug:<45}{count:<10}{pct:.1f}%     {t:<8}{c:<8}")

    # --- Where do Jess's drugs actually rank among all? ---
    all_sorted = drug_topn_counter.most_common()
    rank_map = {drug: (r, c) for r, (drug, c) in enumerate(all_sorted, 1)}
    total_unique = len(all_sorted)

    print(f"\nJess's drugs — global rank among all {total_unique} drugs appearing in top {top_n}:")
    print(f"{'Drug':<20}{'Matched as':<35}{'Rank':<10}{'# Runs':<10}{'Percentile':<12}")
    print("-" * 87)
    for canonical in CANONICAL_ORDER:
        found = False
        for drug_name, (rank, count) in rank_map.items():
            if match_drug(drug_name) == canonical:
                pctl = 100 * (1 - rank / total_unique)
                print(f"{canonical:<20}{drug_name:<35}{rank:<10}{count:<10}{pctl:.1f}%")
                found = True
        if not found:
            print(f"{canonical:<20}{'(not in top-N of any disease)':<35}{'N/A':<10}{'0':<10}{'N/A'}")
    print()

    # --- Save CSV ---
    out_file = OUT_DIR / f"top{top_n}_drug_frequency_across_diseases.csv"
    with open(out_file, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["rank", "drug", "n_disease_runs", "pct_disease_runs",
                     "n_tahoe", "n_cmap"])
        for rank, (drug, count) in enumerate(all_sorted, 1):
            t = drug_topn_tahoe.get(drug, 0)
            c = drug_topn_cmap.get(drug, 0)
            pct = 100 * count / total_disease_runs
            w.writerow([rank, drug, count, f"{pct:.1f}", t, c])
    print(f"  Saved: {out_file.name}")

    # Save Jess detail
    out_jess = OUT_DIR / f"top{top_n}_jess_drugs_detail.csv"
    with open(out_jess, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["drug", "platform", "disease", "top_n"])
        for canonical in CANONICAL_ORDER:
            info = jess_topn[canonical]
            for dis in sorted(set(info["TAHOE"])):
                w.writerow([canonical, "TAHOE", dis, top_n])
            for dis in sorted(set(info["CMAP"])):
                w.writerow([canonical, "CMAP", dis, top_n])
            if not info["TAHOE"] and not info["CMAP"]:
                w.writerow([canonical, "none", "none", top_n])
    print(f"  Saved: {out_jess.name}")

print(f"\nAll results in: {OUT_DIR}/")
