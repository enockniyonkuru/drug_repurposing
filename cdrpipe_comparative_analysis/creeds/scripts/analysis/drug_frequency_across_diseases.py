#!/usr/bin/env python3
"""
Analyze how frequently specific drug candidates appear across diseases.
Also computes top-N most frequent drugs across all diseases.

Requested by Jess/Tomiko — drugs of interest:
  LY-294002, sirolimus, wortmannin, SB-203580, naringenin, gossypol
"""

import csv
import ast
import re
from collections import defaultdict, Counter
from pathlib import Path

# ---------- config ----------
DATA_DIR = Path(__file__).resolve().parents[2]  # creeds/
Q_FILE = DATA_DIR / "analysis" / "manual_standardized_all_diseases_analysis" / "analysis_drug_lists_creeds_manual_all_diseases_q0.05.csv"
OUT_DIR = DATA_DIR / "results" / "drug_frequency_analysis"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Jess's drugs of interest (normalised for matching)
DRUGS_OF_INTEREST = {
    "ly294002": "LY-294002",
    "sirolimus": "sirolimus",
    "rapamycin": "sirolimus",     # alias
    "wortmannin": "wortmannin",
    "sb203580": "SB-203580",
    "sb202190": "SB-203580",      # closely related p38 inhibitor sometimes confused
    "naringenin": "naringenin",
    "naringin": "naringenin",     # glycoside form
    "gossypol": "gossypol",
}

TOP_N = 20  # threshold for "top N" analysis

def normalise(name):
    """Lowercase, strip punctuation/spaces for fuzzy matching."""
    return re.sub(r"[^a-z0-9]", "", name.lower())

def parse_drug_list(raw):
    """Parse a Python-style list string from CSV."""
    if not raw or raw == "[]":
        return []
    try:
        return [str(d).strip() for d in ast.literal_eval(raw)]
    except Exception:
        return []

# ---------- load data ----------
diseases = []
with open(Q_FILE, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        disease = row["disease_name"]
        tahoe_hits = parse_drug_list(row["tahoe_hits_list"])
        cmap_hits = parse_drug_list(row["cmap_hits_list"])
        diseases.append({
            "name": disease,
            "tahoe": tahoe_hits,
            "cmap": cmap_hits,
            "all": tahoe_hits + cmap_hits,
        })

print(f"Loaded {len(diseases)} diseases from q<0.05 analysis\n")

# ---------- 1. Jess's drugs across diseases ----------
print("=" * 70)
print("PART 1: Jess's drugs of interest — frequency across diseases")
print("=" * 70)

# Build a lookup: for each drug of interest, which diseases contain it
drug_disease_map = defaultdict(lambda: {"tahoe": [], "cmap": []})

for d in diseases:
    for hit in d["tahoe"]:
        norm = normalise(hit)
        for pattern, canonical in DRUGS_OF_INTEREST.items():
            if pattern in norm or norm in pattern:
                drug_disease_map[canonical]["tahoe"].append(d["name"])
    for hit in d["cmap"]:
        norm = normalise(hit)
        for pattern, canonical in DRUGS_OF_INTEREST.items():
            if pattern in norm or norm in pattern:
                drug_disease_map[canonical]["cmap"].append(d["name"])

# Unique canonical names requested
canonical_drugs = ["LY-294002", "sirolimus", "wortmannin", "SB-203580", "naringenin", "gossypol"]

for drug in canonical_drugs:
    info = drug_disease_map[drug]
    tahoe_diseases = sorted(set(info["tahoe"]))
    cmap_diseases = sorted(set(info["cmap"]))
    all_diseases = sorted(set(tahoe_diseases + cmap_diseases))
    print(f"\n--- {drug} ---")
    print(f"  Total diseases where it appears: {len(all_diseases)}")
    print(f"  TAHOE ({len(tahoe_diseases)}): {', '.join(tahoe_diseases) if tahoe_diseases else 'none'}")
    print(f"  CMAP  ({len(cmap_diseases)}): {', '.join(cmap_diseases) if cmap_diseases else 'none'}")

# ---------- 2. Top-N most frequent drugs across all diseases ----------
print("\n" + "=" * 70)
print(f"PART 2: Most frequently appearing drugs across all {len(diseases)} diseases")
print("=" * 70)

# Count how many diseases each drug appears in (either platform)
drug_counter_all = Counter()
drug_counter_tahoe = Counter()
drug_counter_cmap = Counter()

for d in diseases:
    # deduplicate within same disease
    for hit in set(d["tahoe"]):
        norm = normalise(hit)
        drug_counter_tahoe[hit] += 1
        drug_counter_all[hit] += 1
    for hit in set(d["cmap"]):
        norm = normalise(hit)
        drug_counter_cmap[hit] += 1
        if hit not in d["tahoe"]:  # avoid double-counting if in both
            drug_counter_all[hit] += 1

print(f"\nTop {TOP_N} drugs by number of diseases (combined TAHOE + CMAP):")
print(f"{'Rank':<6}{'Drug':<45}{'# Diseases':<12}{'TAHOE':<8}{'CMAP':<8}")
print("-" * 79)
for rank, (drug, count) in enumerate(drug_counter_all.most_common(TOP_N), 1):
    t = drug_counter_tahoe.get(drug, 0)
    c = drug_counter_cmap.get(drug, 0)
    print(f"{rank:<6}{drug:<45}{count:<12}{t:<8}{c:<8}")

# Also show top 20 for TAHOE and CMAP separately
for platform, counter in [("TAHOE", drug_counter_tahoe), ("CMAP", drug_counter_cmap)]:
    print(f"\nTop {TOP_N} drugs by number of diseases ({platform} only):")
    print(f"{'Rank':<6}{'Drug':<45}{'# Diseases':<12}")
    print("-" * 63)
    for rank, (drug, count) in enumerate(counter.most_common(TOP_N), 1):
        print(f"{rank:<6}{drug:<45}{count:<12}")

# ---------- 3. Where do Jess's drugs rank? ----------
print("\n" + "=" * 70)
print("PART 3: Ranking of Jess's drugs among all candidates")
print("=" * 70)

# Build sorted ranking
all_ranked = drug_counter_all.most_common()
rank_map = {}
for rank, (drug, count) in enumerate(all_ranked, 1):
    rank_map[drug] = (rank, count)

total_drugs = len(all_ranked)
print(f"\nTotal unique drugs across all diseases: {total_drugs}")
print(f"{'Drug':<45}{'Rank':<10}{'# Diseases':<12}{'Percentile':<12}")
print("-" * 79)

for canonical in canonical_drugs:
    # find matching entries
    matches = []
    for drug_name, (rank, count) in rank_map.items():
        norm = normalise(drug_name)
        for pattern in DRUGS_OF_INTEREST:
            if DRUGS_OF_INTEREST[pattern] == canonical and (pattern in norm or norm in pattern):
                matches.append((drug_name, rank, count))
                break
    if matches:
        for drug_name, rank, count in sorted(matches, key=lambda x: x[1]):
            pctl = 100 * (1 - rank / total_drugs)
            print(f"{drug_name:<45}{rank:<10}{count:<12}{pctl:.1f}%")
    else:
        print(f"{canonical:<45}{'N/A':<10}{'0':<12}{'N/A':<12}")

# ---------- 4. Save results to CSV ----------
# Save Jess's drugs detail
with open(OUT_DIR / "jess_drugs_across_diseases.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["drug", "platform", "disease", "total_diseases"])
    for drug in canonical_drugs:
        info = drug_disease_map[drug]
        all_d = sorted(set(info["tahoe"] + info["cmap"]))
        total = len(all_d)
        for dis in info["tahoe"]:
            w.writerow([drug, "TAHOE", dis, total])
        for dis in info["cmap"]:
            w.writerow([drug, "CMAP", dis, total])
        if not all_d:
            w.writerow([drug, "none", "none", 0])

# Save top-N
with open(OUT_DIR / "top_drugs_by_disease_frequency.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["rank", "drug", "n_diseases_combined", "n_diseases_tahoe", "n_diseases_cmap"])
    for rank, (drug, count) in enumerate(drug_counter_all.most_common(50), 1):
        t = drug_counter_tahoe.get(drug, 0)
        c = drug_counter_cmap.get(drug, 0)
        w.writerow([rank, drug, count, t, c])

print(f"\n\nResults saved to: {OUT_DIR}/")
print(f"  - jess_drugs_across_diseases.csv")
print(f"  - top_drugs_by_disease_frequency.csv")
