# Drug Clustering Options Comparison: CMAP vs Tahoe

## Overview

This document compares three different clustering approaches for drugs in CMAP and Tahoe databases.

| Dataset | Total Drugs | Overlap |
|---------|-------------|---------|
| **Tahoe** | 170 | 43 shared |
| **CMAP** | 457 | 43 shared |
| **Combined (Union)** | 584 unique | - |

---

## Option 1: Drug Type

### Description
Classification based on molecular structure/modality of the drug.

### Tahoe (170 drugs)

| Drug Type | Count | Percentage |
|-----------|-------|------------|
| Small molecule | 169 | 99.4% |
| Protein | 1 | 0.6% |

### CMAP (457 drugs)

| Drug Type | Count | Percentage |
|-----------|-------|------------|
| Small molecule | 455 | 99.6% |
| Protein | 1 | 0.2% |
| Unknown | 1 | 0.2% |

### Combined (584 drugs)

| Drug Type | Count | Percentage |
|-----------|-------|------------|
| Small molecule | 582 | 99.7% |
| Protein | 1 | 0.2% |
| Unknown | 1 | 0.2% |

### Assessment

| Criteria | Rating | Notes |
|----------|--------|-------|
| **Number of clusters** | ⭐ (1-3) | Almost no differentiation |
| **Cluster balance** | ❌ Poor | 99%+ in one category |
| **Biological meaning** | ⚠️ Limited | Only separates modality, not mechanism |
| **Usefulness for repurposing** | ❌ Not useful | All drugs in same cluster |

**Verdict: NOT RECOMMENDED** - No differentiation for CMAP/Tahoe drugs (99% small molecules)

---

## Option 2: Drug Target Class

### Description
Classification based on the biological target type the drug acts upon (from Open Targets).

### Tahoe (170 drugs)

| Target Class | Count | Percentage |
|--------------|-------|------------|
| Enzyme | 92 | 54.1% |
| Transcription factor | 24 | 14.1% |
| Membrane receptor | 22 | 12.9% |
| Unclassified protein | 13 | 7.6% |
| Transporter | 6 | 3.5% |
| Ion channel | 4 | 2.4% |
| Structural protein | 3 | 1.8% |
| Other nuclear protein | 3 | 1.8% |
| Epigenetic regulator | 2 | 1.2% |
| Auxiliary transport protein | 1 | 0.6% |

**Total clusters: 10**

### CMAP (457 drugs)

| Target Class | Count | Percentage |
|--------------|-------|------------|
| Membrane receptor | 158 | 34.6% |
| Enzyme | 112 | 24.5% |
| Transcription factor | 60 | 13.1% |
| Ion channel | 58 | 12.7% |
| Transporter | 49 | 10.7% |
| Unclassified protein | 8 | 1.8% |
| Auxiliary transport protein | 4 | 0.9% |
| Epigenetic regulator | 3 | 0.7% |
| Structural protein | 3 | 0.7% |
| Secreted protein | 1 | 0.2% |
| Other cytosolic protein | 1 | 0.2% |

**Total clusters: 11**

### Combined (584 drugs)

| Target Class | Count | Percentage |
|--------------|-------|------------|
| Enzyme | 187 | 32.0% |
| Membrane receptor | 175 | 30.0% |
| Transcription factor | 71 | 12.2% |
| Ion channel | 61 | 10.4% |
| Transporter | 51 | 8.7% |
| Unclassified protein | 21 | 3.6% |
| Structural protein | 5 | 0.9% |
| Epigenetic regulator | 4 | 0.7% |
| Auxiliary transport protein | 4 | 0.7% |
| Other nuclear protein | 3 | 0.5% |
| Secreted protein | 1 | 0.2% |
| Other cytosolic protein | 1 | 0.2% |

**Total clusters: 12**

### Consolidated Version (6 clusters)

Combining small categories into "Other protein targets":

| Cluster | Tahoe | CMAP | Combined |
|---------|-------|------|----------|
| Enzyme | 92 (54.1%) | 112 (24.5%) | 187 (32.0%) |
| Membrane receptor | 22 (12.9%) | 158 (34.6%) | 175 (30.0%) |
| Transcription factor | 24 (14.1%) | 60 (13.1%) | 71 (12.2%) |
| Ion channel | 4 (2.4%) | 58 (12.7%) | 61 (10.4%) |
| Transporter | 6 (3.5%) | 49 (10.7%) | 51 (8.7%) |
| Other protein targets | 22 (12.9%) | 20 (4.4%) | 39 (6.7%) |

### Assessment

| Criteria | Rating | Notes |
|----------|--------|-------|
| **Number of clusters** | ⭐⭐⭐ (6-12) | Good granularity |
| **Cluster balance** | ✅ Good | Top 5 classes cover 93%+ |
| **Biological meaning** | ✅ High | Direct link to disease mechanisms |
| **Usefulness for repurposing** | ✅ Excellent | Maps to disease therapeutic areas |

**Verdict: RECOMMENDED** - Best balance of granularity and biological relevance

---

## Option 3: Mechanism of Action (MoA)

### Description
Classification based on the specific pharmacological action of the drug.

### Tahoe (170 drugs)

**Total unique MoAs: 116**

| Top MoAs | Count |
|----------|-------|
| Glucocorticoid receptor agonist | 6 |
| Cyclooxygenase inhibitor | 5 |
| Epidermal growth factor receptor erbB1 inhibitor | 4 |
| Androgen Receptor antagonist | 4 |
| DNA polymerase (alpha/delta/epsilon) inhibitor | 3 |
| Tubulin inhibitor | 3 |
| FK506-binding protein 1A inhibitor | 3 |
| Serine/threonine-protein kinase AKT inhibitor | 3 |
| Histamine H1 receptor antagonist | 3 |
| Progesterone receptor agonist | 3 |
| Receptor protein-tyrosine kinase erbB-2 inhibitor | 3 |
| Fibroblast growth factor receptor inhibitor | 3 |
| Cyclooxygenase-2 inhibitor | 3 |
| Serine/threonine-protein kinase B-raf inhibitor | 3 |
| Neurotrophic tyrosine kinase receptor inhibitor | 3 |
| *(+101 more with 1-2 drugs each)* | ... |

### CMAP (457 drugs)

**Total unique MoAs: 164**

| Top MoAs | Count |
|----------|-------|
| Histamine H1 receptor antagonist | 26 |
| Cyclooxygenase inhibitor | 24 |
| Glucocorticoid receptor agonist | 22 |
| Sodium channel alpha subunit blocker | 19 |
| Dopamine D2 receptor antagonist | 15 |
| Norepinephrine transporter inhibitor | 11 |
| Beta-1 adrenergic receptor antagonist | 10 |
| Voltage-gated L-type calcium channel blocker | 9 |
| Sulfonylurea receptor 1, Kir6.2 blocker | 9 |
| Thiazide-sensitive sodium-chloride cotransporter inhibitor | 8 |
| Muscarinic acetylcholine receptor M3 antagonist | 8 |
| Muscarinic acetylcholine receptor M1 antagonist | 8 |
| Beta-2 adrenergic receptor agonist | 7 |
| Progesterone receptor agonist | 6 |
| Cyclooxygenase-2 inhibitor | 6 |
| *(+149 more with 1-5 drugs each)* | ... |

### Combined (584 drugs)

**Total unique MoAs: 235**

| Top MoAs | Count |
|----------|-------|
| Histamine H1 receptor antagonist | 26 |
| Glucocorticoid receptor agonist | 24 |
| Cyclooxygenase inhibitor | 24 |
| Sodium channel alpha subunit blocker | 19 |
| Dopamine D2 receptor antagonist | 15 |
| Norepinephrine transporter inhibitor | 11 |
| Beta-1 adrenergic receptor antagonist | 10 |
| Voltage-gated L-type calcium channel blocker | 9 |
| Sulfonylurea receptor 1, Kir6.2 blocker | 9 |
| Progesterone receptor agonist | 8 |
| *(+225 more)* | ... |

### Assessment (Raw MoA)

| Criteria | Rating | Notes |
|----------|--------|-------|
| **Number of clusters** | ❌ Too many (116-235) | Too granular |
| **Cluster balance** | ❌ Poor | Many clusters with 1-2 drugs |
| **Biological meaning** | ✅ Very high | Very specific mechanism |
| **Usefulness for repurposing** | ⚠️ Limited | Too specific for clustering |

**Verdict: NOT RECOMMENDED (raw)** - Too granular, requires grouping

---

## Option 3B: MoA Super-Categories (Grouped)

### Description
Mechanism of Action grouped into ~13 pharmacological super-categories.

### Tahoe (170 drugs)

| Super-Category | Count |
|----------------|-------|
| Other inhibitor | 43 |
| Receptor agonist | 42 |
| Kinase inhibitor | 39 |
| Receptor inhibitor | 14 |
| COX inhibitor | 8 |
| DNA/RNA modulator | 5 |
| Epigenetic modulator | 4 |
| Channel blocker | 4 |
| Transporter inhibitor | 4 |
| Proteasome inhibitor | 3 |
| Modulator | 3 |
| Other agonist | 1 |

**Total super-categories: 12**

### CMAP (457 drugs)

| Super-Category | Count |
|----------------|-------|
| Receptor agonist | 219 |
| Other inhibitor | 87 |
| Channel blocker | 50 |
| COX inhibitor | 31 |
| Transporter inhibitor | 31 |
| Modulator | 12 |
| Other | 10 |
| Receptor inhibitor | 6 |
| DNA/RNA modulator | 5 |
| Epigenetic modulator | 4 |
| Kinase inhibitor | 1 |
| Other agonist | 1 |

**Total super-categories: 12**

### Combined (584 drugs)

| Super-Category | Count |
|----------------|-------|
| Receptor agonist | 243 |
| Other inhibitor | 121 |
| Channel blocker | 51 |
| Kinase inhibitor | 40 |
| Transporter inhibitor | 33 |
| COX inhibitor | 32 |
| Receptor inhibitor | 19 |
| Modulator | 14 |
| Other | 10 |
| DNA/RNA modulator | 9 |
| Epigenetic modulator | 7 |
| Proteasome inhibitor | 3 |
| Other agonist | 2 |

**Total super-categories: 13**

### Assessment (MoA Super-Categories)

| Criteria | Rating | Notes |
|----------|--------|-------|
| **Number of clusters** | ⭐⭐⭐ (12-13) | Good granularity |
| **Cluster balance** | ⚠️ Moderate | Top 2 categories dominate |
| **Biological meaning** | ✅ High | Captures action type (inhibitor/agonist) |
| **Usefulness for repurposing** | ✅ Good | Pharmacologically meaningful |

**Verdict: RECOMMENDED (as secondary)** - Good complement to Target Class

---

## Summary Comparison

| Option | # Clusters | Balance | Biological Meaning | Recommendation |
|--------|------------|---------|-------------------|----------------|
| **Drug Type** | 1-3 | ❌ Poor | ⚠️ Limited | ❌ Not useful |
| **Target Class** | 6-12 | ✅ Good | ✅ High | ✅ **PRIMARY** |
| **MoA (raw)** | 116-235 | ❌ Poor | ✅ Very high | ❌ Too granular |
| **MoA Super-Categories** | 12-13 | ⚠️ Moderate | ✅ High | ✅ **SECONDARY** |

---

## Key Differences: Tahoe vs CMAP

| Aspect | Tahoe | CMAP |
|--------|-------|------|
| **Dominant Target Class** | Enzyme (54%) | Membrane receptor (35%) |
| **Dominant MoA Category** | Other inhibitor + Kinase inhibitors | Receptor agonists (48%) |
| **Focus** | Oncology drugs (kinase inhibitors) | CNS/Cardiovascular drugs (receptor modulators) |
| **Diversity** | Less diverse | More diverse |

---

## Recommendation

### For Drug Repurposing Pipeline:

**Primary Clustering: Drug Target Class (6 consolidated clusters)**
- Enzyme
- Membrane receptor
- Transcription factor
- Ion channel
- Transporter
- Other protein targets

**Secondary Layer (optional): MoA Super-Categories**
- Use for validation or sub-clustering within target classes
- Captures inhibitor/agonist/antagonist distinction

### Rationale:
1. **Target Class aligns with disease therapeutic areas** - enables disease-drug matching
2. **Balanced clusters** - all clusters have meaningful sample sizes
3. **MoA super-categories capture pharmacological action** - useful for mechanism validation

---

*Generated: January 6, 2026*
