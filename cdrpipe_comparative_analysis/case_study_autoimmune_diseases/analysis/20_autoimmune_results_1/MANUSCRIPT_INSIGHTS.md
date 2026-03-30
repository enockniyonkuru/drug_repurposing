# Manuscript Results Section: Autoimmune Disease Drug Repurposing Study

## Executive Summary

This analysis compares two computational drug repurposing approaches (CMAP and TAHOE) across **20 autoimmune diseases**, evaluating their ability to recover known therapeutic drugs.

---

## Key Findings & Story Lines for Your Manuscript

### 1. **TAHOE Dramatically Outperforms CMAP** (Primary Finding)

**Story:** TAHOE demonstrates significantly superior performance in recovering known therapeutic drugs across autoimmune diseases.

| Metric | CMAP | TAHOE | p-value |
|--------|------|-------|---------|
| Mean Recovery Rate | 17.8% | 76.6% | **< 0.001** |
| Median Recovery Rate | 12.5% | 89.5% | - |
| Cohen's d Effect Size | - | **2.35** (Large) | - |

**Key Statistics:**
- TAHOE outperformed CMAP in **18 out of 20 diseases (90%)**
- CMAP only performed better in 2 diseases (type 1 diabetes mellitus, arthritis)
- Wilcoxon signed-rank test: **p = 0.0002** (highly significant)
- Effect size: Cohen's d = 2.35 (considered "large effect")

**Manuscript Text Suggestion:**
> "TAHOE significantly outperformed CMAP in recovering known therapeutic drugs across 20 autoimmune diseases (mean recovery rate: 76.6% vs 17.8%, Wilcoxon signed-rank test p < 0.001, Cohen's d = 2.35), demonstrating superior ability to identify established therapies from transcriptomic signatures."

---

### 2. **Perfect Recovery in Nearly Half of Diseases** (TAHOE Strength)

**Story:** TAHOE achieved 100% recovery rate in 9 out of 20 autoimmune diseases.

| Disease | Known Drugs Available | Recovered |
|---------|----------------------|-----------|
| Sjogren's syndrome | 4 | 4 (100%) |
| Autoimmune thrombocytopenic purpura | 11 | 11 (100%) |
| Psoriasis vulgaris | 7 | 7 (100%) |
| Psoriatic arthritis | 6 | 6 (100%) |
| Scleroderma | 1 | 1 (100%) |
| Childhood type dermatomyositis | 2 | 2 (100%) |
| Discoid lupus erythematosus | 2 | 2 (100%) |
| Inclusion body myositis | 1 | 1 (100%) |
| Colitis | 1 | 1 (100%) |

**Manuscript Text Suggestion:**
> "Notably, TAHOE achieved complete recovery (100%) of all available known drugs in 9 of 20 autoimmune diseases (45%), including Sjogren's syndrome, autoimmune thrombocytopenic purpura, and psoriatic arthritis, whereas CMAP achieved 0% recovery in several of these conditions."

---

### 3. **Methods Are Complementary, Not Redundant** (Critical Insight)

**Story:** Despite TAHOE's superior performance, combining both methods recovers more drugs than either alone.

| Source | Drugs Recovered | Percentage |
|--------|-----------------|------------|
| CMAP Only | 54 | 31.8% |
| TAHOE Only | 110 | 64.7% |
| Both Methods | 6 | 3.5% |
| **Total Unique** | **170** | 100% |

**Key Insight:** Only 3.5% overlap means the methods capture different drug-disease relationships!

**Manuscript Text Suggestion:**
> "Importantly, despite TAHOE's superior overall performance, the two methods demonstrated high complementarity with only 3.5% overlap in recovered drugs. CMAP uniquely identified 54 known drugs (31.8%) that TAHOE missed, while TAHOE uniquely recovered 110 drugs (64.7%). This suggests that integrating both approaches maximizes drug discovery potential."

---

### 4. **Disease-Specific Performance Patterns** (Nuanced Finding)

**Story:** Performance varies by disease, revealing where each method excels.

#### Diseases Where CMAP Outperformed TAHOE:
1. **Type 1 diabetes mellitus:** CMAP 25.8% vs TAHOE 16.7%
2. **Arthritis:** CMAP 33.3% vs TAHOE 0%

#### High-Burden Diseases with Strong TAHOE Performance:
| Disease | TAHOE Recovery | CMAP Recovery | Drug Candidates |
|---------|---------------|---------------|-----------------|
| Rheumatoid arthritis | 64.0% | 17.8% | 859 |
| Multiple sclerosis | 43.8% | 27.9% | 774 |
| Systemic lupus erythematosus | 60.0% | 40.0% | 894 |
| Crohn's disease | 75.0% | 7.4% | 476 |
| Psoriasis | 93.3% | 4.2% | 685 |

**Manuscript Text Suggestion:**
> "Disease-specific analysis revealed that TAHOE particularly excelled in inflammatory conditions such as Crohn's disease (75% vs 7.4%), psoriasis (93.3% vs 4.2%), and rheumatoid arthritis (64% vs 17.8%). However, CMAP showed superior performance for type 1 diabetes mellitus and arthritis, suggesting disease-specific mechanisms may favor different computational approaches."

---

### 5. **Drug Repurposing Opportunity Assessment** (Translational Value)

**Story:** The analysis identifies diseases with the most drug repurposing candidates.

| Rank | Disease | Unique Drug Candidates | Known Recoveries |
|------|---------|------------------------|------------------|
| 1 | Sjogren's syndrome | 1,086 | 8 |
| 2 | Relapsing-remitting MS | 1,065 | 12 |
| 3 | Psoriasis vulgaris | 1,005 | 7 |
| 4 | Scleroderma | 978 | 3 |
| 5 | Systemic lupus erythematosus | 894 | 16 |

**Manuscript Text Suggestion:**
> "Our analysis identified over 13,000 unique drug candidates across 20 autoimmune diseases. Sjogren's syndrome (1,086 candidates), relapsing-remitting multiple sclerosis (1,065 candidates), and psoriasis vulgaris (1,005 candidates) represent diseases with the highest potential for drug repurposing discovery, warranting further experimental validation."

---

### 6. **Total Drug Hits Analysis**

| Method | Total Hits | Known Drug Recoveries | "Precision" |
|--------|------------|----------------------|-------------|
| CMAP | 3,284 | 60 | 1.8% |
| TAHOE | 5,665 | 116 | 2.0% |
| Common (both) | 115 | 6 | 5.2% |

**Insight:** Drugs predicted by both methods have higher precision (~5.2%), suggesting high-confidence candidates.

**Manuscript Text Suggestion:**
> "While both methods identified thousands of drug candidates, drugs predicted by both CMAP and TAHOE showed 2.6-fold higher precision (5.2%) compared to single-method predictions (1.8-2.0%), suggesting that consensus predictions may represent higher-confidence repurposing candidates."

---

## Recommended Figures for Manuscript

### Figure 1: Comprehensive Analysis Overview
**File:** `figure1_comprehensive_analysis.png/pdf`
- Panel A: Grouped bar chart comparing recovery rates across all 20 diseases
- Panel B: Paired slope chart showing method comparison per disease
- Panel C: Complementarity analysis (stacked bar)
- Panel D: Box plot distribution comparison
- Panel E: Hits vs Recovery scatter plot
- Panel F: Top diseases by candidate count

### Figure 2: Recovery Rate Heatmap
**File:** `figure2_heatmap.png/pdf`
- Color-coded heatmap showing CMAP vs TAHOE recovery rates
- Easy visual comparison across diseases
- Sorted by TAHOE performance

### Figure 3: Publication Summary (Recommended Main Figure)
**File:** `figure3_publication_summary.png/pdf`
- Panel A: Statistical comparison with significance
- Panel B: Complementarity visualization
- Panel C: Perfect recovery diseases
- Panel D: Summary statistics table

### Figure 4: Disease-Specific Radar Charts
**File:** `figure4_radar_diseases.png/pdf`
- Detailed profiles for 6 key diseases
- Useful for supplementary materials

---

## Statistical Summary for Methods Section

```
Study Design:
- 20 autoimmune diseases analyzed
- Two computational methods compared: CMAP and TAHOE
- Validation against known therapeutic drugs from clinical databases

Statistical Tests Used:
- Wilcoxon signed-rank test (paired non-parametric comparison)
- Cohen's d (effect size calculation)
- Pearson correlation (relationship between variables)

Key Results:
- Wilcoxon test: W-statistic, p = 0.0002
- Effect size: Cohen's d = 2.35 (large effect)
- TAHOE superior in 18/20 diseases (90%)
```

---

## Potential Limitations to Address

1. **Database Coverage:** Recovery rates depend on drug availability in each method's database
2. **Disease Heterogeneity:** Autoimmune diseases have varied mechanisms
3. **Signature Quality:** Results depend on input disease signature quality
4. **Validation Scope:** Known drugs only reflect currently approved therapies

---

## 7. **Drug-Level Recovery Analysis for Six Key Autoimmune Diseases** (New Findings)

We performed detailed drug-level analysis for six representative autoimmune diseases to identify specific therapeutics recovered by CMAP, TAHOE, or both methods.

### Summary Statistics

| Disease | Known Drugs | CMAP Only | TAHOE Only | Both | Total Recovered (%) |
|---------|-------------|-----------|------------|------|---------------------|
| Sjögren's Syndrome | 39 | 3 | 3 | 0 | 6 (15.4%) |
| Crohn's Disease | 104 | 3 | 8 | 0 | 11 (10.6%) |
| Multiple Sclerosis | 182 | 22 | 2 | 2 | 26 (14.3%) |
| Rheumatoid Arthritis | 240 | 19 | 10 | 4 | 33 (13.8%) |
| Type 1 Diabetes Mellitus | 138 | 11 | 2 | 1 | 14 (10.1%) |
| Systemic Lupus Erythematosus | 118 | 9 | 5 | 1 | 15 (12.7%) |
| **Total** | **821** | **67** | **30** | **8** | **105 (12.8%)** |

### Consensus Drugs: High-Confidence Candidates

**Only 8 drugs (7.6%) were recovered by both methods**, representing the highest-confidence repurposing candidates:

| Disease | Consensus Drug | Clinical Phase | Drug Class |
|---------|---------------|----------------|------------|
| Multiple Sclerosis | **Dexamethasone** | Phase 4 | Corticosteroid |
| Multiple Sclerosis | **Diphenhydramine** | Phase 3 | Antihistamine |
| Rheumatoid Arthritis | **Celecoxib** | Phase 4 | COX-2 Inhibitor |
| Rheumatoid Arthritis | **Dexamethasone** | Phase 4 | Corticosteroid |
| Rheumatoid Arthritis | **Methotrexate** | Phase 4 | DMARD |
| Rheumatoid Arthritis | **Naproxen** | Phase 4 | NSAID |
| Type 1 Diabetes | **Verapamil** | Phase 3 | Calcium Channel Blocker |
| Systemic Lupus Erythematosus | **Dexamethasone** | Phase 4 | Corticosteroid |

**Key Insight:** Dexamethasone was recovered by both methods across 3 different diseases (MS, RA, SLE), validating both pipelines' ability to identify pan-autoimmune therapeutics.

### Platform-Specific Drug Discovery Patterns

#### CMAP Strengths: Established Therapeutics
CMAP uniquely identified **67 drugs (63.8%)**, particularly:
- **NSAIDs:** Diclofenac, etodolac, oxaprozin, sulindac (Rheumatoid Arthritis)
- **Corticosteroids:** Methylprednisolone, prednisolone, prednisone
- **Symptomatic Treatments:** Baclofen, memantine, amantadine (Multiple Sclerosis)
- **ACE Inhibitors:** Captopril, enalapril, ramipril (Type 1 Diabetes)
- **Immunosuppressants:** Azathioprine, methotrexate, sirolimus, thalidomide (SLE)
- **Approved Therapies:** Pilocarpine for dry mouth (Sjögren's)

#### TAHOE Strengths: Emerging Targeted Therapies
TAHOE uniquely identified **30 drugs (28.6%)**, particularly:
- **JAK Inhibitors:** Tofacitinib, filgotinib (across 4 diseases)
- **BTK Inhibitors:** Tirabrutinib (Sjögren's, Rheumatoid Arthritis)
- **Novel Immunomodulators:** Dimethyl fumarate, temsirolimus
- **SGLT2 Inhibitors:** Canagliflozin, dapagliflozin (Type 1 Diabetes)
- **Emerging Anti-inflammatory:** Clobetasol propionate, meloxicam

### JAK Inhibitors: A Recurring TAHOE Discovery

TAHOE consistently recovered JAK inhibitors across multiple autoimmune diseases:

| Disease | JAK Inhibitors Recovered |
|---------|-------------------------|
| Sjögren's Syndrome | Tofacitinib, Filgotinib |
| Crohn's Disease | Tofacitinib, Filgotinib |
| Rheumatoid Arthritis | Filgotinib |
| Systemic Lupus Erythematosus | Tofacitinib, Filgotinib |

**Manuscript Text Suggestion:**
> "TAHOE uniquely identified JAK inhibitors (tofacitinib, filgotinib) across four of six autoimmune diseases analyzed, suggesting this emerging therapeutic class may be particularly well-captured by TAHOE's experimental conditions, potentially due to immune-relevant cell line coverage."

### Disease-Specific Highlights

#### Rheumatoid Arthritis (Strongest Consensus)
- **4 consensus drugs** represent cornerstone RA therapies
- All are Phase 4 approved medications
- Validates both methods' ability to recover clinically relevant drugs

#### Type 1 Diabetes (Verapamil Consensus)
- **Verapamil** was the sole consensus drug
- Recent clinical trials show verapamil preserves beta-cell function in newly diagnosed T1D
- TAHOE uniquely identified SGLT2 inhibitors (canagliflozin, dapagliflozin), reflecting emerging T1D management strategies

#### Systemic Lupus Erythematosus
- **Dexamethasone** consensus validates its established role in SLE flares
- CMAP: Traditional immunosuppressants (azathioprine, methotrexate, sirolimus)
- TAHOE: Novel JAK inhibitors (tofacitinib, filgotinib) now in clinical trials for SLE

#### Sjögren's Syndrome (Complete Non-Overlap)
- **No consensus drugs** between methods
- CMAP: Pilocarpine (approved treatment for dry mouth)
- TAHOE: JAK/BTK inhibitors in clinical development

### Manuscript Text Suggestion (Drug-Level Results Paragraph)

> "Drug-level analysis of six representative autoimmune diseases revealed that only 7.6% of recovered drugs were identified by both CMAP and TAHOE, reinforcing the complementary nature of these platforms. Consensus drugs included cornerstone rheumatoid arthritis therapies (methotrexate, celecoxib, naproxen, dexamethasone—all Phase 4 approved), verapamil for type 1 diabetes (notable given recent clinical evidence for beta-cell preservation), and dexamethasone for multiple sclerosis and systemic lupus erythematosus. Platform-specific patterns emerged: CMAP excelled at recovering established medications including NSAIDs, corticosteroids, and traditional immunosuppressants, while TAHOE uniquely identified emerging targeted therapies including JAK inhibitors (tofacitinib, filgotinib) across four diseases, BTK inhibitors (tirabrutinib), and SGLT2 inhibitors for diabetes. These findings support a multi-platform approach to maximize drug discovery, as each method captures distinct therapeutic signals."

---

## Suggested Results Section Structure

1. **Overall Performance Comparison** (Main finding)
2. **Disease-Specific Patterns** (Nuanced analysis)
3. **Complementarity Analysis** (Added value of combining methods)
4. **Drug Repurposing Candidates** (Translational potential)
5. **High-Confidence Predictions** (Consensus approach)

---

## Files Generated

| File | Description |
|------|-------------|
| `figure1_comprehensive_analysis.png/pdf` | 6-panel comprehensive analysis |
| `figure2_heatmap.png/pdf` | Recovery rate heatmap |
| `figure3_publication_summary.png/pdf` | Publication-ready 4-panel summary |
| `figure4_radar_diseases.png/pdf` | Disease-specific radar charts |
| `MANUSCRIPT_INSIGHTS.md` | This analysis document |

---

*Generated on: December 19, 2025*
