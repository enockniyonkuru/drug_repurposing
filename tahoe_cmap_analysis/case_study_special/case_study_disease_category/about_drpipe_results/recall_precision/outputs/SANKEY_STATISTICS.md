# Sankey Diagram: CMAP vs TAHOE Drug Repurposing Pipeline Analysis

## Overview
This document contains the updated statistics for the drug repurposing pipeline comparison between CMAP and TAHOE, visualized as a Sankey flow diagram.

---

## Key Statistics

### Drug Predictions & Recovery

**CMAP Pipeline:**
- Total predictions: **4,717**
- Total recovered: **305**
- Recovery rate: **6.5%**
- Unique drugs in discoveries: **408**
- Unique diseases analyzed: **155**

**TAHOE Pipeline:**
- Total predictions: **7,647**
- Total recovered: **849**
- Recovery rate: **11.1%** ✓ (1.7× higher than CMAP)
- Unique drugs in discoveries: **221**
- Unique diseases analyzed: **171**

---

## Drug Overlap

- **Available in Both Pipelines:** 44 drugs
- **CMAP Only:** 364 drugs
- **TAHOE Only:** 177 drugs
- **Total Unique Drugs:** 585

---

## Recovery Outcomes

| Metric | CMAP | TAHOE |
|--------|------|-------|
| Recovered | 305 (6.5%) | 849 (11.1%) |
| Not Recovered | 4,412 (93.5%) | 6,798 (88.9%) |
| Improvement | — | +544 drugs (+178%) |

---

## Disease Coverage & Performance

### Per-Disease Metrics

| Platform | Diseases | Mean Precision | Mean Recall |
|----------|----------|-----------------|-------------|
| CMAP | 101 | 5.5% | 60.7% |
| TAHOE | 112 | 9.9% ✓ | 58.0% |

**Key Findings:**
- TAHOE achieves **1.8× higher mean precision** (9.9% vs 5.5%)
- Both platforms achieve comparable recall (~60%)
- TAHOE shows better selectivity with fewer false positives

---

## Sankey Flow Breakdown

```
Total Predictions:
├── CMAP: 4,717
└── TAHOE: 7,647

↓

Drug Availability:
├── Both: 44 drugs
├── CMAP Only: 364 drugs
└── TAHOE Only: 177 drugs

↓

Recovery Outcomes:
├── Recovered CMAP: 305 (6.5%)
├── Recovered TAHOE: 849 (11.1%)
├── Not Recovered (CMAP): 4,412
└── Not Recovered (TAHOE): 6,798
```

---

## Summary

- **TAHOE recovers 71% more drugs** than CMAP (849 vs 305) despite having fewer unique drugs
- **TAHOE is 1.8× more selective** in its predictions (higher precision)
- Both platforms achieve ~60% recall, indicating comprehensive coverage
- The overlap of 44 drugs between pipelines represents high-confidence predictions

---

*Generated: January 7, 2026*
*Analysis: Precision & Recall Validation of Drug Repurposing Pipelines*
