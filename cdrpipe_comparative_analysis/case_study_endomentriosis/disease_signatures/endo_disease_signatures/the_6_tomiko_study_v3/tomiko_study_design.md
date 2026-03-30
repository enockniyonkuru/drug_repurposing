## Corrected and complete interpretation

### Step 1 Data processing and disease signature construction

For **each of the six disease signatures**:

**Select columns**

* gene_symbol
* adj.P.Val
* LogFC Control slash Disease

Rename:

* LogFC Control slash Disease → logfc_dz

**Apply disease level filters**

* adj.P.Val < 0.05
* absolute value of logfc_dz > 1.1

At this point you have a **filtered disease signature**.

Important clarification

* These filters are applied **before** any drug scoring happens
* Only genes passing both thresholds are used downstream

---

### Step 2 Disease signature ranking and CMap query

This step is implicit but critical and was missing from your list.

* Rank the filtered genes by logfc_dz
* Keep the full ranked list with direction preserved
* Use this ranked disease signature to query CMap
* Compute connectivity scores using a rank based Kolmogorov Smirnov statistic

This produces a **reversal score per drug per disease signature**.

---

### Step 3 Reversal direction filter

Now apply the directionality constraint:

* Reversal score < 0

This ensures the drug **opposes** the disease transcriptional state.

Important clarification

* This filter is applied **after** connectivity scoring
* It is not applied to disease genes directly

---

### Step 4 Statistical significance cutoff

Apply the final significance threshold:

* q value < 0.0001

This removes weak or unstable drug disease associations.

---

## Final simplified pipeline in correct order

1. Filter disease genes using adj.P.Val and logfc_dz
2. Rank disease genes by logfc_dz
3. Compute drug connectivity scores
4. Keep drugs with negative reversal scores
5. Keep drugs with q value < 0.0001

