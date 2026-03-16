# Drug Clustering Options for Drug Repurposing Pipeline

## Overview

This document outlines clustering strategies for the **4,274 unique drugs** from Open Targets, specifically for use in a drug repurposing pipeline against disease therapeutic areas.

---

## Available Data Dimensions

| Dimension | Unique Values | Coverage | Best For |
|-----------|---------------|----------|----------|
| **Drug Type** | 10 types | 100% | Broad categorization |
| **Target Class** | 15 classes | 99.6% | Biological target-based clustering |
| **Mechanism of Action (MoA)** | 1,238 unique | 100% | Fine-grained pharmacological grouping |
| **Target Gene** | ~1,084 targets | High | Pathway-based analysis |

---

## Drug Type Distribution (All 4,274 drugs)

| Drug Type | Count | Percentage |
|-----------|-------|------------|
| Small molecule | 3,136 | 73.4% |
| Antibody | 542 | 12.7% |
| Protein | 308 | 7.2% |
| Unknown | 115 | 2.7% |
| Oligonucleotide | 64 | 1.5% |
| Antibody drug conjugate | 60 | 1.4% |
| Oligosaccharide | 18 | 0.4% |
| Gene | 17 | 0.4% |
| Enzyme | 10 | 0.2% |
| Cell | 4 | 0.1% |

---

## Drug Target Class Distribution (All 4,274 drugs)

| Target Class | Count | Description |
|--------------|-------|-------------|
| Enzyme | 1,450 | Catalytic proteins (kinases, proteases, etc.) |
| Membrane receptor | 1,345 | Cell surface receptors (GPCRs, RTKs, etc.) |
| Ion channel | 419 | Voltage/ligand-gated channels |
| Unclassified protein | 400 | Proteins without specific classification |
| Transcription factor | 304 | Nuclear receptors, DNA-binding proteins |
| Secreted protein | 268 | Cytokines, growth factors |
| Transporter | 216 | Membrane transport proteins |
| Other cytosolic protein | 93 | Intracellular signaling proteins |
| Surface antigen | 72 | Cell surface markers |
| Structural protein | 66 | Cytoskeletal proteins |
| Epigenetic regulator | 60 | Histone modifiers, chromatin remodelers |
| Adhesion | 43 | Cell adhesion molecules |
| Auxiliary transport protein | 35 | Transport regulators |
| Other nuclear protein | 23 | Nuclear proteins |
| Other membrane protein | 9 | Other membrane-associated proteins |

---

## Clustering Strategy Options

### Option 1: Drug Target Class (Recommended)

**15 well-defined categories from Open Targets**

**Advantages:**
- ✅ Directly links to disease mechanisms
- ✅ Balanced cluster sizes
- ✅ Best match with disease therapeutic areas
- ✅ Interpretable biological meaning

**Use case:** Map Enzyme-targeting drugs to Metabolic diseases, Membrane receptor drugs to Neurological/Immune diseases, etc.

---

### Option 2: Drug Type (Simplest)

**10 categories based on molecular structure**

**Advantages:**
- ✅ Quick and clean separation
- ✅ Simple to implement

**Disadvantages:**
- ⚠️ Dominated by small molecules (73%)
- ⚠️ Less biologically informative for repurposing

---

### Option 3: Hierarchical MoA Super-Categories

Group the 1,238 unique MoAs into ~20-30 higher-level categories:

| Super-Category | Examples |
|----------------|----------|
| **Kinase Inhibitors** | EGFR inhibitor, BRAF inhibitor, JAK inhibitor |
| **Receptor Agonists** | Glucocorticoid agonist, Beta-2 agonist |
| **Receptor Antagonists** | Histamine H1 antagonist, Dopamine D2 antagonist |
| **Channel Blockers** | Sodium channel blocker, Calcium channel blocker |
| **Enzyme Inhibitors** | Cyclooxygenase inhibitor, ACE inhibitor |
| **Transporter Inhibitors** | Serotonin transporter inhibitor, SGLT2 inhibitor |
| **DNA/RNA Modulators** | DNA topoisomerase inhibitor, DNA polymerase inhibitor |
| **Epigenetic Modulators** | HDAC inhibitor, DNMT inhibitor |
| **Proteasome Inhibitors** | 26S proteasome inhibitor |
| **Apoptosis Modulators** | Bcl-2 inhibitor |

**Advantages:**
- ✅ Pharmacologically meaningful
- ✅ Captures drug action directionality (inhibitor vs agonist)

**Disadvantages:**
- ⚠️ Requires manual curation of groupings

---

### Option 4: Hybrid Target Class + Drug Type

Cross-tabulate to create ~50-70 meaningful combinations:
- `Enzyme-SmallMolecule`
- `MembraneReceptor-Antibody`
- `Transcription factor-SmallMolecule`
- etc.

**Advantages:**
- ✅ More granular while remaining interpretable
- ✅ Captures both target biology and drug modality

---

## CMAP and Tahoe Drug Subsets

### Tahoe Drugs (170 drugs)

| Characteristic | Value |
|----------------|-------|
| Drug types | 99% Small molecule, 1% Protein |
| Top target classes | Enzyme (104), Transcription factor (24), Unclassified (24), Membrane receptor (23) |
| Unique MoAs | 116 |

**Top MoAs in Tahoe:**
- Glucocorticoid receptor agonist (6)
- Cyclooxygenase inhibitor (5)
- EGFR inhibitor (4)
- Androgen receptor antagonist (4)

### CMAP Drugs (457 drugs)

| Characteristic | Value |
|----------------|-------|
| Drug types | 99% Small molecule |
| Top target classes | Membrane receptor (166), Enzyme (116), Ion channel (66), Transcription factor (61) |

---

## Recommendation for Drug Repurposing

### Primary Clustering: Drug Target Class

For matching drugs to diseases by therapeutic area, **Drug Target Class** provides the best alignment:

| Drug Target Class | Related Disease Therapeutic Areas |
|-------------------|-----------------------------------|
| Enzyme | Metabolic diseases, Cancer |
| Membrane receptor | Nervous system, Immune system |
| Ion channel | Nervous system, Cardiovascular |
| Transcription factor | Cancer, Endocrine disorders |
| Secreted protein | Immune system, Inflammatory |
| Transporter | Metabolic, Nervous system |
| Epigenetic regulator | Cancer, Genetic disorders |

### Secondary Layer: MoA Super-Categories

For validation and hypothesis generation, group MoAs into pharmacological super-categories (~20-30 groups) based on:
1. Target type (receptor, enzyme, channel)
2. Action type (inhibitor, agonist, antagonist, modulator)
3. Therapeutic class (anti-inflammatory, antineoplastic, etc.)

---

## Files in This Directory

| File | Description |
|------|-------------|
| `open_target_unique_drugs.csv` | All 4,274 unique drugs with target class, MoA, type |
| `open_target_drugs_in_cmap.csv` | 457 drugs matching CMAP database |
| `open_target_drugs_in_tahoe.csv` | 170 drugs matching Tahoe database |
| `drug_clustering_options.md` | This document |

---

## Next Steps

1. **Create drug clusters by target class** - Generate 15 drug clusters
2. **Build MoA super-categories** - Group 1,238 MoAs into ~20-30 categories
3. **Create drug-disease matching matrix** - Cross-reference drug target classes with disease therapeutic areas
4. **Validate with known drug-disease associations** - Use Open Targets known_drug_info data

---

*Generated: January 6, 2026*
