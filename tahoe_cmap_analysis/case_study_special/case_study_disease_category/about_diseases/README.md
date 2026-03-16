# Disease Clustering Summary for Drug Repurposing

## Overview

This document summarizes the clustering of CREEDS diseases for drug repurposing analysis, using a **multi-membership approach** where diseases belong to all their therapeutic areas.

---

## Data Pipeline

```
CREEDS Disease Signatures (233 diseases)
    ↓
Matched to Open Targets (203 matched, 30 unmatched)
    ↓
Filtered to diseases with known drugs (180 diseases)
    ↓
Clustered by Therapeutic Area (20 clusters, multi-membership)
```

---

## Final Numbers

| Stage | Count | Percentage |
|-------|-------|------------|
| Original CREEDS diseases | 233 | 100% |
| Matched to Open Targets | 203 | 87.1% |
| With known drug associations | 180 | 77.3% |

---

## Multi-Membership: Why It Matters

### The Challenge: Diseases Have Multiple Therapeutic Areas

| Category | Count | Percentage |
|----------|-------|------------|
| Diseases with 1 area | 44 | 24.4% |
| Diseases with 2+ areas | 136 | **75.6%** |

**Distribution:**
- 1 area: 44 diseases
- 2 areas: 78 diseases
- 3 areas: 37 diseases
- 4 areas: 14 diseases
- 5 areas: 6 diseases
- 6 areas: 1 disease

**Average: 2.24 therapeutic areas per disease**

### Examples of Multi-Area Diseases

| Disease | Therapeutic Areas |
|---------|-------------------|
| Duchenne muscular dystrophy | Genetic/Congenital, Nervous System, Musculoskeletal |
| Crohn's disease | Genetic/Congenital, Immune System, Gastrointestinal |
| HIV encephalitis | Nervous System, Psychiatric, Infectious Disease |
| Diabetic Nephropathy | Metabolic, Urinary System |
| Alzheimer's disease | Nervous System, Psychiatric |

### Our Recommendation: Multi-Membership Clustering

For drug repurposing, we assign diseases to **ALL their therapeutic areas** rather than just the primary one.

**Rationale:**
1. **Captures disease complexity**: Duchenne affects muscles, nerves, AND has genetic basis
2. **Better drug matching**: Drugs targeting any relevant area could be candidates
3. **No information loss**: Primary-only discards 75% of disease classification info
4. **Consistent with drug approach**: Same logic as drug target class multi-membership

---

## Therapeutic Area Distribution

### Multi-Membership Counts (All Areas)

**180 diseases → 403 total assignments** across 20 therapeutic areas:

| Rank | Therapeutic Area | Count | % of Diseases |
|------|------------------|-------|---------------|
| 1 | Cancer/Tumor | 59 | 32.8% |
| 2 | Genetic/Congenital | 47 | 26.1% |
| 3 | Immune System | 38 | 21.1% |
| 4 | Nervous System | 33 | 18.3% |
| 5 | Musculoskeletal | 31 | 17.2% |
| 6 | Gastrointestinal | 28 | 15.6% |
| 7 | Respiratory | 21 | 11.7% |
| 8 | Endocrine System | 19 | 10.6% |
| 9 | Hematologic | 17 | 9.4% |
| 10 | Skin/Integumentary | 16 | 8.9% |
| 11 | Reproductive/Breast | 16 | 8.9% |
| 12 | Psychiatric | 15 | 8.3% |
| 13 | Cardiovascular | 12 | 6.7% |
| 14 | Infectious Disease | 12 | 6.7% |
| 15 | Metabolic | 11 | 6.1% |
| 16 | Urinary System | 9 | 5.0% |
| 17 | Phenotype | 6 | 3.3% |
| 18 | Visual System | 5 | 2.8% |
| 19 | Pancreas | 5 | 2.8% |
| 20 | Pregnancy/Perinatal | 2 | 1.1% |

### Primary-Only Counts (For Reference)

Using only the first-listed therapeutic area:

| Rank | Cluster | Count | % |
|------|---------|-------|---|
| 1 | Cancer/Tumor | 27 | 15.0% |
| 2 | Genetic/Congenital | 20 | 11.1% |
| 3 | Nervous System | 18 | 10.0% |
| 4 | Immune System | 13 | 7.2% |
| 5 | Gastrointestinal | 11 | 6.1% |
| 6 | Musculoskeletal | 11 | 6.1% |
| 7-20 | Others | 80 | 44.5% |

---

## Comparison: Primary vs Multi-Membership

| Therapeutic Area | Primary Only | Multi-Membership | Difference |
|------------------|--------------|------------------|------------|
| Cancer/Tumor | 27 | 59 | +32 (+119%) |
| Genetic/Congenital | 20 | 47 | +27 (+135%) |
| Immune System | 13 | 38 | +25 (+192%) |
| Nervous System | 18 | 33 | +15 (+83%) |
| Endocrine System | 6 | 19 | +13 (+217%) |

**Key Insight**: Multi-membership reveals that Immune System diseases are significantly underrepresented when using primary-only (192% increase with multi-membership).

---

## Cluster Size Categories (Multi-Membership)

| Category | Clusters | Example Areas |
|----------|----------|---------------|
| **Large** (≥25 diseases) | 6 | Cancer, Genetic, Immune, Nervous, Musculoskeletal, Gastrointestinal |
| **Medium** (10-24 diseases) | 7 | Respiratory, Endocrine, Hematologic, Skin, Reproductive, Psychiatric, Cardiovascular |
| **Small** (<10 diseases) | 7 | Infectious, Metabolic, Urinary, Phenotype, Visual, Pancreas, Pregnancy |

---

## Implementation

Each disease has:
- `therapeutic_areas`: All therapeutic areas (pipe-separated)
- `primary_therapeutic_area`: First-listed area (for simple counts)

**For drug repurposing matching**: Use `therapeutic_areas` (all) to find candidate drugs targeting any relevant area.

---

## Files in This Folder

| File | Description |
|------|-------------|
| `creeds_diseases_info.csv` | All 233 CREEDS diseases with Open Targets matching |
| `creeds_diseases_with_known_drugs.csv` | 180 diseases with all therapeutic areas |
| `therapeutic_area_cluster_summary.csv` | Primary cluster statistics (for reference) |
| `open_target_unique_diseases.csv` | Reference: Open Targets diseases with drugs |
| `disease_clustering_by_therapeutic_area.md` | Detailed disease lists by cluster |

---

## Recommendations for Drug Repurposing Analysis

1. **Use multi-membership for matching**: Match drugs to diseases using ALL therapeutic areas
2. **Focus on large clusters** (≥25 diseases multi-membership) for statistical power
3. **Consider disease overlap**: Many diseases appear in multiple clusters - this is a feature, not a bug
4. **Validate predictions** using the 180 diseases with known drug associations
5. **Explore novelty** in diseases that appear in unexpected therapeutic areas
