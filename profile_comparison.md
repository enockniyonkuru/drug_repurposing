# Drug Repurposing Pipeline: Profile Comparison

## Configuration Differences

| Parameter | Default Profile | Strict Profile |
|-----------|----------------|----------------|
| logfc_cutoff | 1.0 | 1.5 |
| q_thresh | 0.05 | 0.01 |

## Results Summary

### Default Profile (logfc_cutoff=1.0, q_thresh=0.05)
- **Input genes**: 2,247 → 661 genes with CMAP data
- **Signature genes**: 414 up + 247 down = 661 total
- **Significant hits**: 37 drugs (q < 0.05)

### Strict Profile (logfc_cutoff=1.5, q_thresh=0.01)
- **Input genes**: 2,247 → 364 genes with CMAP data
- **Signature genes**: 269 up + 95 down = 364 total
- **Significant hits**: 16 drugs (q < 0.01)

## Impact of Stricter Thresholds

### Gene Selection Impact (logfc_cutoff: 1.0 → 1.5)
- **45% reduction** in genes used (661 → 364)
- More stringent fold-change requirement filters out moderately dysregulated genes
- Focuses on the most dramatically altered genes

### Statistical Significance Impact (q_thresh: 0.05 → 0.01)
- **57% reduction** in significant hits (37 → 16)
- Only the most statistically robust drug candidates remain

## Top Drug Candidates Comparison

### Default Profile Top 5 (q < 0.05):
1. **chlorpromazine**: -0.289 (q = 0)
2. **puromycin**: -0.272 (q = 0)
3. **thioridazine**: -0.264 (q = 0)
4. **perhexiline**: -0.254 (q = 0)
5. **niclosamide**: -0.252 (q = 0)

### Strict Profile Top 5 (q < 0.01):
1. **anisomycin**: -0.428 (q = 0) ⭐ *New top candidate*
2. **chlorpromazine**: -0.352 (q = 0) ⬆️ *Stronger score*
3. **thioridazine**: -0.327 (q = 0) ⬆️ *Stronger score*
4. **perhexiline**: -0.314 (q = 0) ⬆️ *Stronger score*
5. **vorinostat**: -0.306 (q = 0.004) ⭐ *New candidate*

## Key Observations

### 1. **Stronger CMAP Scores in Strict Profile**
- All drugs show more negative (stronger) CMAP scores
- This suggests that using more dramatically dysregulated genes leads to stronger drug-disease signature reversals

### 2. **New Top Candidate: Anisomycin**
- Emerges as #1 candidate with -0.428 score (vs -0.202 in default)
- Shows the most dramatic reversal effect under strict criteria

### 3. **Consistent High-Confidence Drugs**
- **chlorpromazine**, **thioridazine**, **perhexiline** appear in both top lists
- These represent the most robust drug repurposing candidates

### 4. **New Discovery: Vorinostat**
- HDAC inhibitor that appears only in strict analysis
- Known cancer therapeutic with strong mechanistic rationale

## Recommendations

### For Discovery:
- Use **default profile** for broader screening and hypothesis generation
- Captures more potential candidates for further investigation

### For Validation:
- Use **strict profile** for high-confidence candidates
- Focuses on drugs with strongest evidence for therapeutic potential
- Better for prioritizing expensive experimental validation

### Robust Candidates (appear in both):
1. **chlorpromazine** - Antipsychotic with anti-cancer properties
2. **thioridazine** - Antipsychotic with documented anti-cancer effects  
3. **perhexiline** - Cardiovascular drug with metabolic effects
4. **niclosamide** - Anthelmintic with broad anti-cancer activity

These four drugs represent the highest-confidence repurposing opportunities for CoreFibroid treatment.
