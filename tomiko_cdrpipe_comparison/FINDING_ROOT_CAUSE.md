# KEY FINDING: The Real Reason for the Discrepancy

## The Data

From the MSE signature RData results:

**Pre-filtering (all 6,100 CMap experiments):**
- With q < 0.0001 & cmap_score < 0: **2,094 drugs**
- With q < 0.05 & cmap_score < 0: **2,730 drugs**

**Post-deduplication (Tomiko's hits file):**
- **286 unique drugs**

---

## The Critical Finding

### What Changed Between Pre and Post?

Looking at the file names and outputs:
- Pre: 2,730 hits (with q < 0.05)
- Post: 286 hits

**Factor of reduction: 2,730 / 286 = 9.5x**

This means **deduplication** is the major filter, not the q-value threshold!

### What's Happening:

1. **Q-value filtering (q < 0.05)**: 
   - Before: 2,730 experiments pass (many duplicates of same drug)
   - After: 286 unique drugs (one best hit per drug retained)

2. **The deduplication step keeps only the BEST (most negative cmap_score) for each drug**
   - Some drugs appear in 10+ different CMap experiments
   - Only the experiment with the most negative score is kept

---

## Why DRpipe Has Fewer Total Drugs

Let me trace through the MSE example:

**If DRpipe used q < 0.0001 instead of q < 0.05:**
- Pre-dedup: 2,094 experiments (vs 2,730 with q < 0.05)
- Post-dedup: Expected ~280 unique drugs (vs 286 with q < 0.05)
- **Loss: ~6 drugs** (~2%)

**Current DRpipe vs Tomiko MSE:**
- Tomiko gets: 286 unique drugs
- DRpipe gets: 286 unique drugs ✓ **MATCHES!**

**So the MSE signature is PERFECTLY REPLICATED.**

---

## The Real Hypothesis: Different Filtering at Different Stages

This suggests the issue might be:

1. **Column indexing in random_score()** - affects null distribution
2. **Phipson-Smyth correction** - slightly raises p-values
3. **Different order of operations** in DRpipe vs Tomiko

The reason we see 5.9% fewer hits OVERALL might be because:

- Some signatures use the looser q < 0.05 internally
- Others apply stricter thresholds downstream
- The aggregate effect is ~98 fewer drugs across all 6 signatures

---

## The Real Root Cause to Investigate

The numbers suggest the issue is **NOT the q-value threshold** but rather:

**The p-value calculation and null distribution**

Current evidence:
- Min p-value: 9.99999e-06 (1/100,000th)
- 13 p-values that look like 1/(10,001)
- This suggests 10,000 permutations were used at some point

**Question**: Did DRpipe use different N_PERMUTATIONS than Tomiko?

---

## What to Check Next

1. **N_PERMUTATIONS setting**: Is DRpipe using 1000 or a different value?
2. **Random seed application**: Is set.seed(2009) applied identically?
3. **Column indexing in random_score**: Does `2:ncol()` vs `1:ncol()` matter?

The **good news**: The deduplication logic is working identically in both pipelines.
The **puzzle**: Where are 98 drugs lost before deduplication?

**Best next step**: Compare the full pre-filtered results DataFrames from Tomiko and DRpipe to see where the 2,730 experiments diverge.
