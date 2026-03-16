## Block 4: Success Metrics - A Comprehensive Guide

### The Main Story
Precision and recall alone don't tell the complete story of pipeline performance. Block 4 introduces four complementary metrics that assess *how well each pipeline succeeds at the fundamental goal: recovering known drugs*. These metrics are designed to be fair comparisons that account for different pipeline characteristics.

---

## Chart 11: Enrichment Factor Distribution

### What Is It Calculated?
**Formula:** Enrichment Factor = Observed Precision / Expected Precision

Where:
- **Observed Precision** = actual fraction of predictions that are known drugs
- **Expected Precision** = (total known drugs in universe) / (total candidate drugs returned)

Example: If TAHOE returns 400 candidates and 6 are known drugs (precision = 1.5%), but we'd expect only 2% of random candidates to be known drugs, the enrichment is 1.5% / 2% = 0.75x (below random).

### Why This Metric?
This measures **specificity efficiency**. It asks: "Are we doing better or worse than random selection would predict?" An enrichment factor > 1 means the pipeline is selecting candidates better than random; < 1 means worse.

### Why Is It Fair?
Enrichment normalizes for baseline expectations. A small dataset might have naturally high precision, but low enrichment reveals it's not much better than random. Conversely, a large dataset with moderate precision but high enrichment shows genuine signal.

### What It Tells End Users
If enrichment is high (e.g., 2.5x), the pipeline has genuine predictive power. If enrichment is low (< 1.5x), most hits are close to random luck.

---

## Chart 12: Success at Top N Depth Curves

### What Does It Mean?
This measures: **"At what ranking depth does each pipeline recover a known drug?"**

The curve shows, for each disease, the fraction that has at least one known drug in the top X candidates, where X ranges from 1 to 200.

Example: If 60% of diseases have a known drug in the top 50 hits, the curve passes through (50, 0.6).

### Why Did We Do It?
Because the ranking order matters. A pipeline might find all known drugs eventually, but only deep in the list (low recall early). This metric reveals **how quickly** each pipeline succeeds.

### Why Is It Important?
In practice, researchers don't screen 1000 candidates—they might only review the top 50-100. This metric directly answers: "Will I find a known drug in my screening batch?"

### How Is It Fair?
Both pipelines are evaluated on the same ranking depths (1-200). The metric is purely about ranking quality, not about total candidates returned. CMAP can't claim an advantage from returning fewer candidates; only ranking quality matters.

---

## Chart 13: Normalized Success per Disease

### What Does It Mean?
**Formula:** Normalized Recall = (Known drugs recovered) / (Total known drugs available for the disease)

This is disease-specific recall, ranging from 0 to 1.

Example: If a disease has 5 known drugs and TAHOE finds 3, normalized recall = 3/5 = 0.6.

### Why Did We Do It?
Different diseases have different numbers of known drugs (1 drug vs. 20 drugs). Without normalization, recovering 5 drugs from a disease with 5 known drugs (100%) looks the same as recovering 5 from a disease with 50 known drugs (10%). This metric normalizes for disease heterogeneity.

### Why Is It Important?
It answers: "For each disease, what fraction of the complete drug arsenal did we recover?" This is clinically meaningful—100% recovery is ideal; 20% recovery might miss important options.

### How Is It Fair?
Every disease is scored on the same scale (0–1), regardless of how many known drugs it has. A small-drug disease and a large-drug disease are comparable.

---

## Chart 14: Jaccard Similarity per Disease

### What Does It Mean?
**Formula:** Jaccard Similarity = |Intersection| / |Union|

Where intersection = drugs found by both TAHOE and CMAP, and union = all drugs found by either.

Example: If TAHOE finds {A, B, C}, CMAP finds {B, C, D}, then:
- Intersection = {B, C} (size 2)
- Union = {A, B, C, D} (size 4)
- Jaccard = 2/4 = 0.5

### Why Did We Do It?
To measure **complementarity**. How much do the two pipelines agree? Are they finding the same drugs (high Jaccard ≈ 1.0) or entirely different ones (low Jaccard ≈ 0)?

### Why Is It Important?
- **High Jaccard (0.7–1.0):** Pipelines agree; using both is redundant
- **Low Jaccard (0–0.3):** Pipelines are complementary; using both finds more drugs
- **Mid Jaccard (0.4–0.6):** Partial overlap; some synergy but some redundancy

### How Is It Fair?
Both pipelines are evaluated on the same disease-by-disease basis. Neither gets penalized for returning more or fewer candidates; only the overlap structure matters.

---

## Tying It All Together: The Main Story

**The Journey:**
1. **Precision & Recall (Fig 6):** TAHOE outperforms CMAP on basic metrics
2. **Enrichment Factor (Chart 11):** But is this real signal or just luck? Enrichment shows TAHOE's advantage is genuine, not random
3. **Top N Curves (Chart 12):** How quickly can researchers find drugs? TAHOE succeeds faster
4. **Normalized Success (Chart 13):** Disease-by-disease, TAHOE recovers a higher fraction of known options
5. **Jaccard Similarity (Chart 14):** The pipelines are complementary but overlap significantly—TAHOE is more complete

**The Conclusion:** TAHOE is not just different from CMAP; it's demonstrably more effective across multiple fair, normalized metrics. Its advantage holds when controlling for pool size, expected precision, ranking depth, and disease-specific drug counts.
