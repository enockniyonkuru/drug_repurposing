# Drug Repurposing Pipeline: Comprehensive Study Report

**Date**: October 27, 2025  

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Study Overview](#study-overview)
3. [Part 1: Data Preparation](#part-1-data-preparation)
4. [Part 2: Pipeline Execution](#part-2-pipeline-execution)
5. [Part 3: Results Analysis](#part-3-results-analysis)
6. [Part 4: Detailed Insights](#part-4-detailed-insights)
7. [Part 5: Method Comparison](#part-5-method-comparison)

---

## Executive Summary

This comprehensive drug repurposing study systematically compared two computational methods—**CMAP** (Connectivity Map) and **TAHOE**—across 58 disease signatures to identify potential therapeutic candidates. The analysis leveraged gene expression signatures from CREEDS and Sirota Lab, benchmarked against Open Targets evidence.

### Key Achievements:
- **6,161 total drug-disease associations** identified across 43 diseases
- **33 high-confidence drugs** validated by both methods (100% evidence support)
- **~60% novel predictions** representing unexplored therapeutic opportunities
- **Complementary method strengths** demonstrated through comparative analysis

---

## Study Overview

### Objectives
1. Systematically evaluate CMAP and TAHOE drug signature databases
2. Identify high-confidence drug repurposing candidates
3. Benchmark predictions against existing clinical evidence
4. Compare method performance and complementarity
5. Discover novel drug-disease associations

### Approach
- **Disease Signatures**: 58 curated from CREEDS (56) + Sirota Lab (2)
- **Drug Signatures**: CMAP (1,309 drugs) and TAHOE (379 drugs)
- **Shared Drug Analysis**: 61 drugs common to both databases
- **Evidence Validation**: Open Targets Platform + Drug Repurposing Hub (not yet integrated)
- **Total Pipeline Runs**: 116 (58 diseases × 2 methods)

---

## Part 1: Data Preparation

### 1.1 Disease Signatures

#### Source: CREEDS Database (Crowd Extracted Expression of Differential Signatures)
- **Reference**: [Wang et al., Nature Communications 2016](https://www.nature.com/articles/ncomms12846) at Mt Sinai
- **Content**: 
  - 1,081 disease signatures covering 450 diseases from 748 studies
  - 1,238 drug perturbation submissions (343 drugs from 443 studies)
  - Diseased vs normal tissues/cells from mammalian species (human, mouse, rat)
  - Data extracted from GEO (Gene Expression Omnibus), manually curated for quality control.

#### Gene Selection Methodology: Characteristic Direction (CD) Algorithm
The CD algorithm was chosen over traditional methods (logFC, t-test) due to superior performance:
- **Computation**: Direction vector in high-dimensional gene-expression space
- **Output**: Weight per gene (positive = upregulated; negative = downregulated)
- **Magnitude**: Analogous to logFC but more stable
- **Export Format**: log2 fold-change–like values (ranked continuous scores)
- **Typical Output**: Top/bottom 250 genes (250 up / 250 down)

#### Curation Process [Started with subset only manually curated]
1. **Initial Dataset**: 330 disease names
2. **DOID Mapping**: 235 unique Disease Ontology IDs
3. **Sample Selection**: 95 diseases evaluated
4. **Filtering Criteria**: Human origin + matchable DOID/disease name
5. **Final Dataset**: 58 disease signatures
   - 56 from CREEDS
   - 2 from Sirota Lab (CoreFibroidSignature, EndothelialSignature)

#### Gene Signature Structure
Each signature contains:
- `gene_symbol`: Gene identifier
- `logfc_experimentIDs`: Experiment-specific log fold changes
- `mean_logfc`: Average across experiments
- `median_logfc`: Median across experiments
- `common_experiment`: Logfc of the experiment that has more genes 

### 1.2 Drug Signatures

#### Shared Drug Analysis
- **61 unique drugs** present in both CMAP and TAHOE
- **12,544 shared genes** used as common input space

#### CMAP Signature Database
- **Total Drugs**: 1,309 unique compounds
- **Experiments**: 6,100 total
- **Analysis Subset**: 434 experiments × 12,527 genes
  - 17 genes missing (not present in CMAP data)
- **Coverage**: Broad but variable depth per drug

#### TAHOE Signature Database
- **Total Drugs**: 379 unique compounds
- **Experiments**: 56,827 total (much deeper per-drug coverage)
- **Analysis Subset**: 13,500 experiments × 12,544 genes
- **Processing**: Ranked by descending Logfc (most upregulated first)
- **Format**: CMap-compatible using Entrez IDs

### 1.3 Drug Evidence Sources

#### Primary Sources
1. **Drug Repurposing Hub** (Broad Institute) - haven't used it yet
   - URL: clue.io/repurposing
   - Comprehensive drug annotation database

2. **Open Targets Platform** (currently using this only)
   - URL: platform.opentargets.org
   - Evidence-based drug-disease associations
   - Clinical trial data and approval status

#### Evidence Data Structure
**Key Columns**:
- `drugId`: Unique drug identifier
- `targetId`: Molecular target
- `diseaseId`: Disease ontology ID
- `phase`: Clinical trial phase (0-4)
- `status`: Approval/trial status
- `urls`: Supporting evidence links
- `label`: Drug name
- `approvedSymbol`: Target gene symbol
- `targetClass`: Target classification
- `mechanismOfAction`: MOA description
- `prefName`: Preferred drug name
- `synonyms`: Alternative names
- `drugType`: Small molecule/biologic/etc.
- `targetName`: Target protein name

---

## Part 2: Pipeline Execution

### 2.1 Pipeline Configuration

**Analysis Parameters**:
- **Disease Signatures Tested**: 58
- **Drug Signature Sources**: CMAP and TAHOE
- **Total Runs**: 116 (58 × 2 methods)
- **logFC Threshold**: 0.00 (no filtering applied)
- **logFC Column Used**: `common_experiment`
- **P-value Filter**: None (disabled for comprehensive analysis)

### 2.2 Computational Approach

**Method**: GSEA-Inspired Kolmogorov-Smirnov (KS)-Like Connectivity Scoring

The pipeline uses a custom implementation inspired by Gene Set Enrichment Analysis (GSEA) methodology, but **not the standard GSEA algorithm**. The approach is specifically tailored for drug repurposing by computing bidirectional connectivity scores.

#### Core Algorithm: `cmap_score()` Function

**Mathematical Approach**:
- Computes a **Kolmogorov-Smirnov (KS)-like statistic** for gene set enrichment
- Evaluates disease signature genes (up-regulated and down-regulated sets separately)
- Compares against ranked drug perturbation profiles
- Generates a signed connectivity score indicating reversal or mimicry

**Scoring Process**:
1. **Input Preparation**:
   - Disease signature: Up-regulated genes (GeneID list)
   - Disease signature: Down-regulated genes (GeneID list)
   - Drug signature: Ranked gene expression profile (Entrez IDs with ranks)

2. **KS-Like Statistic Calculation**:
   - Compute `ks_up`: Enrichment statistic for up-regulated disease genes
   - Compute `ks_down`: Enrichment statistic for down-regulated disease genes
   - Each statistic measures whether disease genes are enriched at the top or bottom of the drug's ranked gene list

3. **Connectivity Score Combination**:
   ```
   connectivity_score = ks_up - ks_down
   ```
   - **Negative scores**: Drug reverses disease signature (therapeutic potential)
   - **Positive scores**: Drug mimics disease signature (contraindicated)
   - **Zero/neutral**: No significant relationship

4. **Statistical Validation**:
   - **Null Distribution**: Generated via `random_score()` function
   - **Method**: Permutation testing (default: 100,000 iterations)
   - **Process**: Random gene sets sampled to create empirical null distribution
   - **P-values**: Computed as frequency of null scores ≥ observed score
   - **Q-values**: FDR correction applied using Storey's q-value method


#### Implementation Details

**Functions Used**:
- `clean_table()`: Preprocesses disease signatures, maps to Entrez IDs, filters by logFC/p-value
- `cmap_score()`: Computes KS-like connectivity score for one drug-disease pair
- `query_score()`: Applies cmap_score across all drug experiments for a disease
- `random_score()`: Generates null distribution via permutation testing
- `query()`: Assembles results with p-values and q-values

**Gene Universe**:
- Analysis restricted to genes present in both disease signature and drug database
- CMAP: 12,527 genes (17 missing from shared set)
- TAHOE: 12,544 genes (complete shared set)

**Output Structure**:
- Per-disease results directories
- Ranked drug lists with connectivity scores
- Statistical significance metrics (p-values, q-values)
- Visualization plots (heatmaps, histograms, upset plots)

**Note:** This is the traditioanl way the Drug Repurposing package usually runs, didn't change anything

---

## Part 3: Results Analysis

### 3.1 Understanding the Two Analysis Approaches

This study employed **two complementary analytical strategies**:

#### Strategy 1: Full Dataset Analysis
- **Scope**: All drug hits from CMAP and TAHOE independently
- **Purpose**: Maximize discovery potential using each method's complete drug library
- **Advantage**: Captures method-specific strengths and unique drug candidates

#### Strategy 2: Shared Drug Subset Analysis
- **Scope**: Only the 61 drugs present in BOTH databases
- **Purpose**: Direct method-to-method comparison on identical compounds
- **Advantage**: Eliminates confounding factors from different drug libraries
- **Use Case**: Validates method reliability and identifies consensus predictions

### 3.2 Full Dataset Results (All Drugs)

#### Overall Statistics
- **Diseases Analyzed**: 58 (later filtered to 43 with sufficient hits)
- **Total CMAP Hits**: 3,524 drug-disease associations
- **Total TAHOE Hits**: 2,637 drug-disease associations
- **Total Unique Associations**: 6,161
- **Common Drugs** (found by both methods): 33 high-confidence candidates

#### Evidence Validation Rates
| Method | Total Hits | With Evidence | Evidence Rate | Novel Hits | Novel Rate |
|--------|-----------|---------------|---------------|------------|------------|
| CMAP | 3,524 | 1,363 | 38.7% | 2,161 | 61.3% |
| TAHOE | 2,637 | 1,131 | 42.9% | 1,506 | 57.1% |
| **Combined** | **6,161** | **2,494** | **40.5%** | **3,667** | **59.5%** |

#### Key Observations
1. **TAHOE shows higher specificity**: 42.9% evidence rate vs CMAP's 38.7%
2. **CMAP shows higher sensitivity**: 3,524 total hits vs TAHOE's 2,637
3. **Substantial novel discovery**: ~60% of predictions lack prior evidence
4. **Complementary coverage**: Different drugs identified by each method

#### Helpful Resources for Full Dataset Analysis 

* Summary of counts per disease: [``full_summary_with_total_row.csv``](https://drive.google.com/file/d/1wXMe07uWuG1CAa4m4f7LuQoM0KVAxB1a/view?usp=sharing)
* Actual list of drugs per disease: [``full_summary_drug_sets_by_disease.csv``](https://drive.google.com/file/d/1C7vkZfOnbZ2ZCEZ6nVXmaWNDeOYmyhgS/view?usp=sharing)
* Json file of disease-drug-evidence (dictonary like): [``drug_disease_combined.json``](https://drive.google.com/file/d/19eDDJ1rKXZDU6LXAPJqRGFMA2U2MKrVm/view?usp=sharing)

### 3.3 Shared Drug Subset Results (61 Common Drugs)

#### Shared Drug Predictions Analysis
When analyzing drug predictions per disease per method using the **61 drugs common to both CMAP and TAHOE databases**:

| Metric | CMAP | TAHOE | Shared |
|--------|------|-------|--------|
| **Total Hits from Shared Drugs** | 299 | 290 | 33 |
| **Diseases Covered** | 43 | 43 | 21 |
| **Hits with Evidence** | 249 (83.3%) | 145 (50.0%) | 33 (100%) |
| **Novel Hits** | 50 (16.7%) | 145 (50.0%) | 0 (0%) |

**Important Note**: This analysis focused on the **subset of 61 drugs present in both databases**, not the full drug libraries. The "Shared" column represents drugs that appeared in **both methods' predictions** for the same disease, demonstrating consensus between CMAP and TAHOE on these specific compounds from the shared drug experiments.

#### Critical Finding: 100% Validation Rate for Shared Drugs
**All 33 drugs that appeared in BOTH methods' predictions (from the 61-drug subset) have existing evidence support.**

**Implications**:
- **Extremely high confidence**: Consensus predictions are highly reliable
- **Reduced false positives**: Independent validation filters spurious associations
- **Method validation**: Confirms both algorithms capture genuine signals when analyzing the same drug set

#### Evidence Enrichment in Shared Drug Analysis
Comparing full dataset vs shared drug subset:
- **CMAP**: 38.7% → 83.3% evidence rate (2.2× enrichment)
- **TAHOE**: 42.9% → 50.0% evidence rate (1.2× enrichment)

**Interpretation**: 
- Predictions from the shared drug subset are strongly enriched for known associations
- Validates the ranking algorithms of both methods
- Lower-ranked hits may still contain valuable novel candidates

#### Helpful Resources for Shared Dataset Analysis 

* Summary of counts per disease: [``shared_summary_with_total_row.csv``](https://drive.google.com/file/d/18YRJx8q4j2Kq3IMtzbpV2ZH1E0TughBe/view?usp=sharing)
* Actual list of drugs per disease: [``shared_summary_drug_sets_by_disease.csv`` ](https://drive.google.com/file/d/1Qq4CFGKyv8YkhG1ChFxC5FSrat6xD9RR/view?usp=sharing)
* Json file of disease-drug-evidence (dictonary like):  [``drug_disease_combined_shared.json``](https://drive.google.com/file/d/14dVzxRA40pdR-0BoqZGmhkYyASn2ru1_/view?usp=sharing)

---

## Part 4: Detailed Insights

### 4.1 Method Complementarity

**Key Finding**: CMAP and TAHOE show limited overlap (only 33 common drugs identified by both methods across all diseases from the shared drug experiments), suggesting they capture different aspects of drug-disease relationships.

#### CMAP Characteristics
- **Drug Library**: 1,309 compounds (larger)
- **Experiments**: 6,100 (moderate depth)
- **Coverage**: 25/43 diseases (58.1%)
- **Total Hits**: 3,524 (higher sensitivity)
- **Evidence Rate**: 38.7% (lower specificity)
- **Strength**: Broad discovery, good for hypothesis generation
- **Limitation**: More false positives, requires validation

#### TAHOE Characteristics
- **Drug Library**: 379 compounds (smaller but curated)
- **Experiments**: 56,827 (much deeper per drug)
- **Coverage**: 24/43 diseases (55.8%)
- **Total Hits**: 2,637 (higher specificity)
- **Evidence Rate**: 42.9% (better precision)
- **Strength**: Evidence-enriched, reliable predictions
- **Limitation**: May miss some valid candidates

#### Synergistic Use
**Recommendation**: Use both methods together
- CMAP for broad discovery and sensitivity
- TAHOE for validation and specificity
- Shared predictions for highest confidence
- Method-specific hits for unique opportunities

### 4.2 Disease Coverage Patterns

#### CMAP-Only Diseases (22 diseases)
Diseases where only CMAP produced results:
- Alzheimer's disease
- Asthma
- Atherosclerosis
- CoreFibroidSignature (Sirota Lab)
- Crohn's disease
- Dermatomyositis
- Duchenne muscular dystrophy
- Epithelial proliferation
- Hypercholesterolemia
- Hypoxia
- Lupus
- Pancreatic cancer
- Type 2 diabetes
- Ulcerative colitis
- *[8 additional diseases]*

**Possible Reasons**:
- Disease signatures better match CMAP's drug library
- TAHOE's stricter filtering criteria
- Different gene coverage or normalization

#### TAHOE-Only Diseases (18 diseases)
Diseases where only TAHOE produced results:
- Astrocytoma
- Autism spectrum disorder
- Breast cancer
- Hepatitis C
- HIV/AIDS
- Melanoma
- Meningococcal infection
- Prostate cancer
- Pulmonary fibrosis
- Schizophrenia
- Tuberculosis
- *[7 additional diseases]*

**Possible Reasons**:
- Disease signatures better match TAHOE's drug library
- TAHOE's deeper per-drug profiling captures subtle signals
- Different experimental conditions or cell types

#### Both Methods (21 diseases)
Diseases with results from both CMAP and TAHOE:
- Bipolar disorder
- Chronic granulomatous disease
- COPD (Chronic obstructive pulmonary disease)
- Colorectal cancer
- Eczema
- Endometrial cancer
- Glioblastoma
- Leukemia
- Lymphoma
- Obesity
- Oligodendroglioma
- Ovarian cancer
- Parkinson's disease
- Psoriasis
- Rheumatoid arthritis
- Stroke
- Type 1 diabetes
- *[4 additional diseases]*

**Significance**:
- These diseases have the most robust predictions
- Highest confidence for drug repurposing
- Enable direct method comparison
- Best candidates for clinical investigation

### 4.3 Top Performing Diseases

#### By Total Hits (Full Dataset)
1. **Endometrial cancer**: 216 hits (125 CMAP + 91 TAHOE)
2. **Glioblastoma**: 214 hits (123 CMAP + 91 TAHOE)
3. **Hypercholesterolemia**: 121 hits (CMAP only)
4. **Dermatomyositis**: 119 hits (CMAP only)
5. **Ulcerative colitis**: 118 hits (CMAP only)
6. **Chronic granulomatous disease**: 208 hits (117 CMAP + 91 TAHOE)
7. **Colorectal cancer**: 207 hits (116 CMAP + 91 TAHOE)
8. **Eczema**: 208 hits (117 CMAP + 91 TAHOE)
9. **Oligodendroglioma**: 207 hits (116 CMAP + 91 TAHOE)
10. **Ovarian cancer**: 208 hits (117 CMAP + 91 TAHOE)

**Interpretation**:
- Diseases with high hit counts likely have:
  - More distinctive gene expression signatures
  - Better characterized molecular pathways
  - Greater therapeutic opportunities
- TAHOE shows consistent output (~91 hits per disease)
- CMAP shows more variable output (8-125 hits)

#### By Shared Drugs (Consensus Analysis)
**Diseases with 2 shared drugs** (highest confidence):
- Bipolar disorder
- Chronic granulomatous disease
- COPD
- Colorectal cancer
- Eczema
- Endometrial cancer
- Glioblastoma
- Leukemia
- Lymphoma
- Obesity
- Oligodendroglioma
- Ovarian cancer
- Psoriasis
- Rheumatoid arthritis
- Stroke
- Type 1 diabetes

**Disease with 1 shared drug**:
- Parkinson's disease 

---

## Part 5: Method Comparison

### 5.1 Quantitative Comparison

#### Full Dataset Analysis (All Drugs)

| Aspect | CMAP | TAHOE | Winner |
|--------|------|-------|--------|
| **Drug Library Size** | 1,309 | 379 | CMAP |
| **Experiment Depth** | 6,100 | 56,827 | TAHOE |
| **Total Hits** | 3,524 | 2,637 | CMAP |
| **Evidence Rate** | 38.7% | 42.9% | TAHOE |
| **Novel Rate** | 61.3% | 57.1% | CMAP |
| **Disease Coverage** | 25 | 24 | CMAP |
| **Consistency** | Variable | Uniform | TAHOE |

#### Shared Drug Subset Analysis (61 Common Drugs)

| Aspect | CMAP | TAHOE | Shared (Consensus) |
|--------|------|-------|-------------------|
| **Total Hits from Shared Drugs** | 299 | 290 | 33 |
| **Diseases Covered** | 43 | 43 | 21 |
| **Evidence Rate** | 83.3% | 50.0% | 100% |
| **Novel Rate** | 16.7% | 50.0% | 0% |
| **Average Hits per Disease** | 7.0 | 6.7 | 1.6 |
| **Winner** | CMAP (higher evidence rate) | TAHOE (consistent) | Both (perfect validation) |

**Key Insights from Shared Drug Analysis**:
- **CMAP shows dramatic evidence enrichment**: 38.7% → 83.3% (2.2× improvement)
- **TAHOE maintains moderate enrichment**: 42.9% → 50.0% (1.2× improvement)
- **Consensus predictions are 100% validated**: All 33 shared drugs have evidence
- **CMAP's ranking algorithm is highly effective**: Top predictions strongly enriched for known associations

### 5.2 Qualitative Comparison

#### CMAP Advantages
1. **Broader drug coverage**: 3.5× more compounds
2. **Higher sensitivity**: More total discoveries
3. **Better ranking**: Top predictions highly enriched for evidence
4. **Flexibility**: Works across more disease types

#### TAHOE Advantages
1. **Deeper profiling**: 9.3× more experiments
2. **Higher baseline specificity**: Better evidence rate
3. **More consistent**: Uniform output across diseases
4. **Quality over quantity**: More reliable predictions

#### When to Use Each Method

**Use CMAP when**:
- Exploring new disease areas
- Generating hypotheses
- Seeking broad coverage
- Prioritizing sensitivity over specificity

**Use TAHOE when**:
- Validating specific hypotheses
- Seeking high-confidence predictions
- Prioritizing specificity over sensitivity
- Working with well-characterized diseases

**Use Both when**:
- Maximum confidence needed
- Comprehensive coverage desired
- Resources available for validation
- Clinical investigation planned

