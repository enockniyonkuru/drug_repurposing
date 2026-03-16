# Drug Clustering Analysis for Drug Repurposing

## Overview

This folder contains drug data from Open Targets matched to CMAP and Tahoe databases, along with clustering analysis for drug repurposing pipelines.

## Data Summary

| Dataset | Total Drugs | Overlap |
|---------|-------------|---------|
| **Open Targets (all)** | 4,274 | - |
| **CMAP-matched** | 457 | 43 shared |
| **Tahoe-matched** | 170 | 43 shared |
| **Combined (CMAP ∪ Tahoe)** | 584 unique | - |

---

## Why We Chose Drug Target Class for Clustering

We evaluated three clustering options:

| Option | Clusters | Usefulness |
|--------|----------|------------|
| **Drug Type** | 1-3 | ❌ Not useful (99% small molecules) |
| **Drug Target Class** | 6-12 | ✅ **Chosen** |
| **Mechanism of Action** | 116-235 | ❌ Too granular |

### Why Not Drug Type?

Drug type (Small molecule, Antibody, Protein, etc.) provides **no differentiation** for CMAP and Tahoe:

| Dataset | Small Molecule | Other |
|---------|----------------|-------|
| Tahoe | 169 (99.4%) | 1 (0.6%) |
| CMAP | 455 (99.6%) | 2 (0.4%) |

Since nearly all drugs in both databases are small molecules, drug type cannot distinguish between them.

### Why Drug Target Class?

Drug Target Class provides:
- **Biological relevance**: Directly links to disease mechanisms
- **Balanced clusters**: 5 major classes cover 93%+ of drugs
- **Disease alignment**: Maps to therapeutic areas for repurposing
- **Manageable granularity**: 6 consolidated clusters vs 235 MoAs

---

## Distribution: CMAP vs Tahoe

### Key Finding: CMAP and Tahoe Have Different Drug Profiles

| Target Class | Tahoe (170) | CMAP (457) | Difference |
|--------------|-------------|------------|------------|
| **Enzyme** | 92 (54.1%) | 112 (24.5%) | Tahoe +30% |
| **Membrane receptor** | 22 (12.9%) | 158 (34.6%) | CMAP +22% |
| **Transcription factor** | 24 (14.1%) | 60 (13.1%) | Similar |
| **Ion channel** | 4 (2.4%) | 58 (12.7%) | CMAP +10% |
| **Transporter** | 6 (3.5%) | 49 (10.7%) | CMAP +7% |
| **Other** | 22 (12.9%) | 20 (4.4%) | Tahoe +8% |

### Interpretation

**Tahoe** is dominated by **Enzyme inhibitors (54%)**, reflecting:
- Oncology focus (kinase inhibitors)
- Newer targeted therapies
- Research-oriented drug selection

**CMAP** is dominated by **Membrane receptor modulators (35%)**, reflecting:
- CNS drugs (dopamine, serotonin receptors)
- Cardiovascular drugs (adrenergic receptors)
- Broader clinical drug coverage

### Why This Matters for Drug Repurposing

1. **Complementary coverage**: Using both databases together provides broader target class coverage
2. **Disease-specific selection**: 
   - For neurological diseases → CMAP may have more candidates
   - For cancer → Tahoe may have more candidates
3. **Validation potential**: 43 overlapping drugs allow cross-database validation

---

## Clustering Recommendation: Multi-Membership Approach

### The Challenge: Drugs Can Have Multiple Target Classes

| Dataset | Single Class | Multiple Classes |
|---------|--------------|------------------|
| Tahoe | 132 (77.6%) | 38 (22.4%) |
| CMAP | 423 (92.6%) | 34 (7.4%) |

Examples:
- **THALIDOMIDE**: 8 target classes
- **SIROLIMUS**: Enzyme + Ion channel
- **PALBOCICLIB**: 3 target classes

### Our Recommendation: Use All Classes

For drug repurposing, we recommend assigning drugs to **all their target classes** (multi-membership) rather than just the primary class.

**Rationale:**

1. **Captures polypharmacology**: Many effective drugs work through multiple mechanisms
2. **Better repurposing matches**: A drug targeting both Enzyme and Ion channel could treat diseases associated with either target class
3. **No information loss**: Primary-only approach discards 22% of Tahoe drug target information
4. **Modest impact**: Only 7-22% of drugs are affected, so cluster sizes remain interpretable

### Recommended 6-Cluster Schema

| Cluster | Description | Disease Alignment |
|---------|-------------|-------------------|
| **Enzyme** | Kinases, proteases, metabolic enzymes | Cancer, Metabolic disorders |
| **Membrane receptor** | GPCRs, receptor tyrosine kinases | Nervous system, Immune, Cardiovascular |
| **Transcription factor** | Nuclear receptors, DNA-binding proteins | Cancer, Endocrine, Reproductive |
| **Ion channel** | Voltage/ligand-gated channels | Nervous system, Cardiovascular, Pain |
| **Transporter** | Membrane transport proteins | Metabolic, Nervous system |
| **Other protein targets** | Unclassified, structural, epigenetic | Various |

### Implementation

Each drug has:
- `primary_cluster`: First-listed target class (for simple counts)
- `all_clusters`: All target classes (for repurposing matching)

---

## Files in This Directory

| File | Description |
|------|-------------|
| `open_target_unique_drugs.csv` | All 4,274 unique drugs from Open Targets |
| `open_target_drugs_in_cmap.csv` | 457 drugs matched to CMAP database |
| `open_target_drugs_in_tahoe.csv` | 170 drugs matched to Tahoe database |
| `drug_clustering_options.md` | Detailed clustering strategy analysis |
| `drug_clustering_comparison.md` | Full comparison of 3 clustering options |
| `README.md` | This file |

---

## Summary

1. **Drug Target Class** is the best clustering attribute (not drug type or raw MoA)
2. **CMAP and Tahoe have different profiles**: CMAP = receptor-heavy, Tahoe = enzyme-heavy
3. **Use multi-membership clustering**: Assign drugs to all their target classes for drug repurposing
4. **6 consolidated clusters** provide the best balance of granularity and interpretability

---

*Generated: January 6, 2026*


