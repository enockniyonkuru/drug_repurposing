## Block 1 Charts 3 & 4: Understanding Signature Quality and Stability

### The Context: Why These Charts Matter

Before drug repurposing pipelines can predict candidate drugs, they must first process and validate experimental data—drug signatures that represent how each drug alters gene expression. Charts 3 and 4 examine the **quality and reliability of the underlying experimental signatures** that power TAHOE and CMAP. A pipeline is only as good as its input data; weak or unstable signatures will lead to poor predictions.

---

## Chart 3: Signature Strength Distribution

### What Does It Really Mean?

This chart shows **how strong the biological signal is in each drug signature**—i.e., how dramatically does each experiment perturb the transcriptome?

**Strength is calculated as:** Mean Absolute Fold Change per experiment
- For each drug signature, compute the absolute value of log fold change for all genes
- Take the mean across all genes in that signature
- Result: A single "strength" score (0–1) per drug experiment

Example: 
- A strong signature where genes shift by 2–5 fold on average → strength ~0.7–0.9
- A weak signature where genes shift by 1.1–1.5 fold on average → strength ~0.2–0.4

### What Insights Does It Tell?

**Distribution shape reveals data quality:**
- **CMap** shows a bimodal distribution (two peaks): one at ~0.42 (weak) and one at ~0.78 (strong). This means CMap contains both high-quality and lower-quality experiments
- **TAHOE** shows a stronger, more concentrated distribution shifted right toward ~0.58–0.82. TAHOE's signatures are generally stronger on average

**What this means clinically:**
- Stronger signatures = clearer drug effects = more reliable connectivity scores
- TAHOE's stronger average signature strength suggests it may detect subtle drug-disease connections more reliably
- CMap's broader distribution means some CMap experiments are very strong, but others are noisier

### How Is It Connected to the Whole Story?

This is the **foundation** of the story. If TAHOE achieves better precision and recall (Figure 6, Block 4), one candidate explanation is: "TAHOE just has stronger input data." This chart directly tests that hypothesis. The answer: Yes, TAHOE's signatures are on average stronger, but both datasets show a range of qualities. This validates that TAHOE's superior performance isn't solely due to filtering out weak experiments—it reflects better methodology downstream.

---

## Chart 4: Signature Stability Across Conditions (TAHOE only)

### What Does It Really Mean?

This chart examines **reproducibility and robustness of TAHOE signatures across different experimental conditions**. It asks: "If we measure the same drug multiple times under different conditions, do we get consistent results?"

**Stability is measured via Pearson correlation:**
- **Dose Consistency:** For each drug, measure the signature at multiple doses (e.g., 0.1 µM, 1 µM, 10 µM). Compute pairwise correlations between these signatures
- **Cell Line Consistency:** For each drug, measure the signature in multiple cell lines. Compute pairwise correlations

Example:
- High dose consistency (r = 0.80): Measuring the drug at different doses produces very similar gene expression profiles
- Low dose consistency (r = 0.30): Different doses produce different profiles, suggesting unstable effects

### What Insights Does It Tell?

**Two peaks in the distribution reveal:**
- **Main peak (~0.60–0.70):** The majority of drugs show good stability (dose consistency: median ~0.70; cell line consistency: median ~0.60). Drug signatures are reproducible across conditions
- **Small tail (~0.28–0.32):** Some drugs show low stability (~5–10% of drugs). These are condition-sensitive: their signatures change dramatically with dose or cell line

**Why this matters:**
- **High stability (0.7+):** You can trust TAHOE's connectivity score for that drug across diverse patient populations and treatment contexts
- **Low stability (0.3):** The drug's signature is context-dependent; its predicted connections might not generalize

### How Is It Connected to the Whole Story?

This chart demonstrates **robustness and generalizability.** Even if TAHOE has stronger signatures on average (Chart 3), those signatures must also be *consistent* to be clinically useful. A drug that works differently at different doses is unreliable for predicting disease connections.

**In the big picture:** 
- Chart 3 proves TAHOE has better **signal amplitude**
- Chart 4 proves TAHOE has good **signal stability**
- Together, they show TAHOE's predictions rest on solid experimental foundations, not artifacts

The fact that dose consistency (0.70) exceeds cell line consistency (0.60) makes biological sense: the same drug at different doses should show dose-response consistency (more stable), while different cell lines have inherent transcriptomic variation (less consistent but still good).

---

## Why We Chose These Charts

**Block 1 establishes data provenance and quality:**
1. Charts 1–2: *How many* experiments do we have? (quantity)
2. Charts 3–4: *How good* are those experiments? (quality)

Users need to trust that TAHOE and CMAP aren't just making lucky guesses. These charts prove the underlying signatures are:
- Strong (Chart 3): Clear, detectable drug effects
- Stable (Chart 4): Reproducible across contexts

This is the "pre-requisite check" before moving to Blocks 2–4, which evaluate *downstream* performance (diseases, drugs, success metrics).

---

## Summary: What the User Should Take Away

- **Signature Strength (Chart 3):** TAHOE experiments hit harder on average than CMAP, meaning TAHOE detects drug effects more clearly. This is a technical advantage built into the data.
- **Signature Stability (Chart 4):** TAHOE's signals are reproducible when the same drug is measured across different doses and cell lines, ensuring predictions will generalize to real patients.
- **Together:** TAHOE's superior downstream performance (better recall, enrichment, etc.) is grounded in superior experimental quality, not methodology magic.
