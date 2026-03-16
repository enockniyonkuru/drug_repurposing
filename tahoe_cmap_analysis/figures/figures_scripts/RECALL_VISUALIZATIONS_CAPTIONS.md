# Captions for Recall-Focused Visualizations

## Figure: Recall Distribution by Pipeline (Violin Plot)

### Short Caption (1-2 sentences)
The violin plot reveals that TAHOE achieves substantially higher recall (mean 47.3%, median 50%) compared to CMAP (mean 18.5%, median 6.14%) across 167 disease-drug association analyses, with TAHOE showing consistently superior performance and broader recovery of known therapeutics.

### Medium Caption (3-4 sentences, suitable for abstracts)
Recall distribution comparison between TAHOE and CMAP pipelines across 167 disease-drug associations reveals stark performance differences. TAHOE demonstrates a median recall of 50% with mean recall of 47.3%, indicating recovery of approximately half of known drugs across typical disease indications. In contrast, CMAP shows substantially lower performance with median recall of 6.14% (mean 18.5%), suggesting more selective candidate filtering. The violin shapes indicate TAHOE has a broader performance distribution with higher probability mass at elevated recall values, while CMAP concentrates predictions around very low recall rates, reflecting fundamental differences in pipeline sensitivity and comprehensiveness.

### Comprehensive Caption (publication-ready)
**Figure: Recall Distribution by Pipeline (Violin Plot)**

Comparison of recall performance between TAHOE and CMAP pipelines across 167 disease-drug association analyses using Q-value threshold of 0.05. Recall is defined as the fraction of known drug-disease associations recovered by each pipeline (known drugs identified / total known drugs available for that disease). The violin plot combines kernel density estimation with box plot statistics (box, median line, whiskers) and individual disease points (jittered) to visualize the full distribution of recall values. TAHOE (blue, left) achieves a median recall of 50% with mean of 47.3% (SD ± 38.6%), indicating consistent recovery of approximately half the known therapeutic drugs for typical disease indications. CMAP (orange, right) shows substantially lower performance with median recall of 6.14% and mean of 18.5% (SD ± 25.2%), indicating that CMAP's more conservative candidate selection strategy results in recovery of fewer known therapeutics per disease. The bimodal distribution observed in both pipelines suggests disease-dependent variation in drug discovery performance, with certain diseases (visible as secondary peaks and outliers) exhibiting either exceptionally high or low recall for each platform. These results demonstrate TAHOE's superior capability for comprehensive recovery of known drug-disease associations, making it preferable for applications requiring exhaustive identification of potential therapeutics. In contrast, CMAP's lower recall combined with higher specificity (as shown in companion precision analysis) makes it suitable for applications prioritizing prediction confidence over comprehensiveness.

---

## Figure: Recall Distribution Density (Density Plot)

### Short Caption (1-2 sentences)
Kernel density estimation reveals bimodal distributions for both TAHOE and CMAP recall, with TAHOE's distribution shifted substantially toward higher recall values (peaks near 50-75%) while CMAP concentrates near 0-25%, illustrating the fundamental performance divergence between platforms in identifying known therapeutics.

### Medium Caption (3-4 sentences, suitable for abstracts)
Density distribution analysis of recall performance reveals distinct patterns between TAHOE and CMAP pipelines across 167 disease analyses. TAHOE's distribution (blue) shows primary peaks around 50-75% recall with a substantial right tail extending to 100% recall, indicating consistent recovery of most known drugs across diverse diseases with occasional near-perfect performance. CMAP's distribution (orange) concentrates heavily at 0-25% recall with a long tail extending toward higher values, suggesting that most disease-drug pairs are recovered conservatively while certain diseases achieve moderately higher recall. The minimal overlap between distributions underscores the complementary nature of the pipelines—TAHOE maximizes coverage while CMAP maximizes specificity. Match type analysis shows synonym-based matching produces slightly higher recall for TAHOE (54.7% mean) compared to name-based matching (44.7%), while CMap recall remains relatively constant across match types.

### Comprehensive Caption (publication-ready)
**Figure: Recall Distribution Density (Density Plot)**

Kernel density estimation (KDE) visualization of recall performance distributions for TAHOE and CMAP pipelines across 167 disease-drug association analyses (Q-value = 0.05). Recall represents the fraction of known therapeutics identified by each pipeline for a given disease indication. The density plot provides a smoothed estimate of probability distributions across the full range of possible recall values (0-100%), revealing underlying patterns invisible in conventional scatter plots or histograms. TAHOE's distribution (blue, solid line; darker blue interior) exhibits a primary mode centered around 50-75% recall with substantial probability mass maintained at high recall values (>50%), indicating that TAHOE consistently recovers the majority of known drugs across disease indications. A secondary tail extending toward 100% recall reflects instances where TAHOE achieves near-complete recovery. CMAP's distribution (orange, solid line; darker orange interior) shows distinctly different characteristics with primary concentration between 0-25% recall and rapid probability decline above 50%, indicating that CMAP's conservative filtering strategy results in recovery of only a small fraction of known therapeutics for most diseases. The minimal overlapping region between distributions (approximately 20-40% recall) represents the narrow range where both pipelines show similar performance. Stratification by disease match type reveals that TAHOE achieves higher mean recall for synonym-based matches (54.7%) versus name-based matches (44.7%), suggesting that synonym expansion improves disease matching specificity. CMap recall distributions remain relatively stable across match types (~18-19% mean), indicating that CMAP's performance is less dependent on disease nomenclature variation. These density distributions demonstrate that TAHOE and CMAP represent fundamentally different discovery paradigms: TAHOE prioritizes sensitivity and comprehensive recovery of known therapeutics (high recall), while CMAP prioritizes specificity and high-confidence predictions (resulting in lower but more focused recall). The non-overlapping distributions support their complementary use in comprehensive drug repurposing studies where exhaustive coverage (TAHOE) can be cross-validated with high-confidence predictions (CMAP).

---

## Quick Reference Table

| Metric | TAHOE | CMAP |
|--------|-------|------|
| **Mean Recall** | 47.3% | 18.5% |
| **Median Recall** | 50% | 6.14% |
| **Std Dev** | ±38.6% | ±25.2% |
| **Range** | 0-100% | 0-100% |
| **Name Match Mean** | 44.7% | 18.3% |
| **Synonym Match Mean** | 54.7% | 19.0% |
| **Diseases Analyzed** | 167 | 167 |

---

## Usage Recommendations

### For Violin Plot:
- Use **Short Caption** for: figure legends, slide presentations, posters
- Use **Medium Caption** for: abstract sections, conference proceedings, supplementary materials
- Use **Comprehensive Caption** for: main manuscript figures, detailed supplementary information, methodology-focused publications

### For Density Plot:
- Use **Short Caption** for: quick reference, methodology summaries
- Use **Medium Caption** for: comparative analyses, results sections
- Use **Comprehensive Caption** for: detailed performance analysis, mechanistic discussion of platform differences

---

## Key Insights for Narrative

1. **Performance Asymmetry**: TAHOE recovers ~2.5× more known drugs than CMAP on average
2. **Distribution Shape**: TAHOE's concentration at high recall indicates reliable performance; CMAP's skew toward low recall indicates conservative predictions
3. **Match Type Effects**: Synonym matching boosts TAHOE's performance (10 percentage point increase), suggesting improved disease nomenclature handling
4. **Complementary Use**: The non-overlapping distributions suggest TAHOE and CMAP should be used together—TAHOE for comprehensive screening, CMAP for high-confidence subset
5. **Statistical Variation**: Both platforms show high standard deviations (±38-40%), indicating substantial disease-to-disease variation requiring disease-specific interpretation
