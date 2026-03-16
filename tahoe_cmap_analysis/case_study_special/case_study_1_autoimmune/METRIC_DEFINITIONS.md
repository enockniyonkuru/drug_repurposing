# Metric Definitions Guide

## Original Excel Column Names → Presentation-Friendly Names

| Original Column Name | Presentation Name | What It Means | Example Value |
|---|---|---|---|
| **Total Tahoe Hits by DRPipe** | Drug Candidates (TAHOE) | Total number of drugs identified by TAHOE method | 374 (Eczema) |
| **Total CMAP Hits by DRPipe** | Drug Candidates (CMAP) | Total number of drugs identified by CMAP method | 204 (Eczema) |
| **Total Common Hits by DRPipe with TAHOE and CMAP** | Agreement Between Methods | How many drugs both TAHOE and CMAP identified | 10 (Eczema) |
| **Total Disease-Drug Pairs in Open Target for this disease** | Total Literature References | Total drug-disease pairs documented in OpenTarget | 34 (Eczema) |
| **Total Disease-Drug Pairs in Open Target and also in CMAP for this disease** | Known Literature Pairs (CMAP) | Literature-validated pairs relevant to CMAP | 24 (Eczema) |
| **Total Disease-Drug Pairs in Open Target and also in Tahoe for this disease** | Known Literature Pairs (TAHOE) | Literature-validated pairs relevant to TAHOE | 10 (Eczema) |
| **Total Disease-Drug Pairs in Open Targets and also in TAHOE that were found by DRPipe** | TAHOE Predictions Validated | How many TAHOE candidates matched literature | 10 (Eczema) |
| **Total Disease-Drug Pairs in Open Targets and also in CMAP that were found by DRPipe** | CMAP Predictions Validated | How many CMAP candidates matched literature | 2 (Eczema) |
| **Total Disease-Drug Pairs in Open Target found by DRPipe** | Total Validated Candidates | Total candidates from both methods in literature | 12 (Eczema) |
| **TAHOE Recall** | TAHOE Success Rate | % of known pairs that TAHOE method recovered | 100% (Eczema) |
| **CMAP Recall** | CMAP Success Rate | % of known pairs that CMAP method recovered | 8.3% (Eczema) |

---

## Quick Reference for Presentations

### Three Key Categories:

**1. Discovery (How many candidates found)**
- Drug Candidates (TAHOE): 374
- Drug Candidates (CMAP): 204
- Agreement Between Methods: 10

**2. Literature Validation (What's known)**
- Total Literature References: 34
- Known Pairs (TAHOE-relevant): 10
- Known Pairs (CMAP-relevant): 24

**3. Performance (How well methods work)**
- TAHOE Predictions Validated: 10/10 (100%)
- CMAP Predictions Validated: 2/24 (8.3%)

---

## Simplified Slide Language

| If You Want to Say... | Use This Metric |
|---|---|
| "How many drugs did each method find?" | Drug Candidates (TAHOE/CMAP) |
| "Which drugs do both methods agree on?" | Agreement Between Methods |
| "How many literature sources support this?" | Total Literature References |
| "How many candidates actually exist in literature?" | Known Literature Pairs |
| "Did the method's predictions match literature?" | Predictions Validated |
| "Which method is more reliable?" | Success Rate (Recall %) |

